import { NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  PrescriptionStorage,
  prescriptionObjectKey,
} from './prescription-storage';

const ORDER_ID = '11111111-1111-4111-8111-111111111111';

function storage(values: Record<string, string> = {}) {
  const config = {
    get: (key: string) => values[key],
  } as ConfigService;
  return new PrescriptionStorage(config);
}

describe('PrescriptionStorage', () => {
  const fetchMock = jest.spyOn(global, 'fetch');

  afterEach(() => {
    fetchMock.mockReset();
  });

  afterAll(() => {
    fetchMock.mockRestore();
  });

  it('names the object after the order', () => {
    expect(prescriptionObjectKey(ORDER_ID, 'image/jpeg')).toBe(
      `${ORDER_ID}.jpg`,
    );
    expect(prescriptionObjectKey(ORDER_ID, 'image/png')).toBe(
      `${ORDER_ID}.png`,
    );
  });

  it('refuses to upload when the bucket credentials are missing', async () => {
    await expect(
      storage().upload(ORDER_ID, Buffer.from('formula'), 'image/jpeg'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('uploads into the private bucket with the service role', async () => {
    fetchMock.mockResolvedValue({ ok: true } as Response);
    const key = await storage({
      SUPABASE_URL: 'https://example.supabase.co/',
      SUPABASE_SERVICE_ROLE_KEY: 'service-role',
    }).upload(ORDER_ID, Buffer.from('formula'), 'image/jpeg');

    expect(key).toBe(`${ORDER_ID}.jpg`);
    expect(fetchMock).toHaveBeenCalledWith(
      `https://example.supabase.co/storage/v1/object/prescriptions/${ORDER_ID}.jpg`,
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          Authorization: 'Bearer service-role',
          apikey: 'service-role',
          'Content-Type': 'image/jpeg',
          'x-upsert': 'false',
        }) as unknown,
      }),
    );
  });

  it('hides a missing object as a missing order', async () => {
    fetchMock.mockResolvedValue({ ok: false, status: 404 } as Response);
    await expect(
      storage({
        SUPABASE_URL: 'https://example.supabase.co',
        SUPABASE_SERVICE_ROLE_KEY: 'service-role',
      }).download(`${ORDER_ID}.jpg`),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
