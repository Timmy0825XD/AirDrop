/** `ManifestsService` para las pruebas que confirman cargas o vuelan. */
export function manifestsStub(number = 'MAN-2026-000001') {
  return {
    issue: jest.fn().mockResolvedValue({ number }),
    activeNumber: jest.fn().mockResolvedValue(number),
    latest: jest.fn().mockResolvedValue(null),
  };
}
