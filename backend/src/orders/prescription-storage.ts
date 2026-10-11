import {
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PRESCRIPTION_BUCKET } from '../common/field-limits';

/**
 * Sube y lee la fórmula en un bucket privado.
 * La app no recibe una URL pública: el despachador la pide por la API.
 */
@Injectable()
export class PrescriptionStorage {
  constructor(private readonly config: ConfigService) {}

  async upload(
    orderId: string,
    content: Buffer,
    mime: string,
  ): Promise<string> {
    const objectKey = prescriptionObjectKey(orderId, mime);
    const response = await fetch(this.objectUrl(objectKey), {
      method: 'POST',
      headers: {
        ...this.authHeaders(),
        'Content-Type': mime,
        'x-upsert': 'false',
      },
      body: new Uint8Array(content),
    });
    if (!response.ok) {
      throw new ServiceUnavailableException('No se pudo guardar la fórmula.');
    }
    return objectKey;
  }

  async download(objectKey: string): Promise<Buffer> {
    const response = await fetch(this.objectUrl(objectKey), {
      headers: this.authHeaders(),
    });
    if (response.status === 404) {
      throw new NotFoundException('El pedido no existe.');
    }
    if (!response.ok) {
      throw new ServiceUnavailableException('No se pudo leer la fórmula.');
    }
    return Buffer.from(await response.arrayBuffer());
  }

  private objectUrl(objectKey: string): string {
    const base = this.required('SUPABASE_URL').replace(/\/$/, '');
    return `${base}/storage/v1/object/${PRESCRIPTION_BUCKET}/${objectKey}`;
  }

  private authHeaders(): Record<string, string> {
    const key = this.required('SUPABASE_SERVICE_ROLE_KEY');
    return {
      Authorization: `Bearer ${key}`,
      apikey: key,
    };
  }

  private required(name: string): string {
    const value = this.config.get<string>(name)?.trim();
    if (!value) {
      throw new ServiceUnavailableException(
        'El almacenamiento de la fórmula no está configurado.',
      );
    }
    return value;
  }
}

export function prescriptionObjectKey(orderId: string, mime: string): string {
  const extension = mime === 'image/png' ? 'png' : 'jpg';
  return `${orderId}.${extension}`;
}
