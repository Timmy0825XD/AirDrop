import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, IsNull, Repository } from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import { UserRole } from '../common/enums/user-role.enum';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { Order } from '../orders/order.entity';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { CargoManifest } from './cargo-manifest.entity';
import {
  AUTO_DISPATCHER_NAME,
  MANIFEST_FORBIDDEN,
  MANIFEST_NOT_FOUND,
  MANIFEST_REPLACED,
  manifestCold,
  manifestItems,
  manifestNumber,
  manifestYear,
} from './manifest.rules';

/** Un solo consecutivo para toda la red: dos cargas no sacan el mismo número. */
const SEQUENCE_LOCK = 'cargo_manifest_sequence';

/**
 * RF-47: emite el manifiesto dentro de la misma transacción que confirma la
 * carga (sin manifiesto no hay despegue) y lo muestra a quien debe verlo.
 */
@Injectable()
export class ManifestsService {
  constructor(
    @InjectRepository(CargoManifest)
    private readonly manifests: Repository<CargoManifest>,
  ) {}

  async issue(
    manager: EntityManager,
    order: Order,
    confirmedBy: User | null,
  ): Promise<CargoManifest> {
    const drone = await manager.findOneOrFail(Drone, {
      where: { id: order.droneId as string },
      relations: { droneModel: true },
    });
    const origin = await manager.findOneOrFail(Hub, {
      where: { id: order.originHubId as string },
    });
    const issuedAt = simClock.now();
    // La carga cambió (otro dron tras un incidente): el anterior se anula.
    await manager.update(
      CargoManifest,
      { orderId: order.id, voidedAt: IsNull() },
      { voidedAt: issuedAt, voidReason: MANIFEST_REPLACED },
    );
    await manager.query('SELECT pg_advisory_xact_lock(hashtext($1))', [
      SEQUENCE_LOCK,
    ]);
    const year = manifestYear(issuedAt);
    const [{ last }] = await manager.query<Array<{ last: number | null }>>(
      'SELECT MAX(sequence) AS last FROM cargo_manifests WHERE year = $1',
      [year],
    );
    const sequence = Number(last ?? 0) + 1;
    return manager.save(
      manager.create(CargoManifest, {
        number: manifestNumber(year, sequence),
        year,
        sequence,
        orderId: order.id,
        droneId: drone.id,
        droneIdentifier: drone.identifier,
        droneKind: drone.droneModel.kind,
        originHubId: origin.id,
        originName: origin.name,
        destinationName: await this.destinationName(manager, order),
        items: manifestItems(order),
        payloadKg: order.payloadKg ?? 0,
        ...manifestCold(order, drone.coldCompartment),
        authorizedByUserId: confirmedBy?.id ?? null,
        authorizedByName: confirmedBy?.fullName ?? AUTO_DISPATCHER_NAME,
        issuedAt,
        voidedAt: null,
        voidReason: null,
      }),
    );
  }

  /** RF-48: el número del manifiesto vigente del pedido, para la identificación. */
  async activeNumber(orderId: string): Promise<string | null> {
    const row = await this.manifests.findOne({
      where: { orderId, voidedAt: IsNull() },
      order: { issuedAt: 'DESC' },
    });
    return row?.number ?? null;
  }

  /** El vigente o, si no hay, el último emitido. */
  async latest(orderId: string): Promise<CargoManifest | null> {
    const rows = await this.manifests.find({
      where: { orderId },
      order: { issuedAt: 'DESC' },
    });
    return rows.find((row) => row.voidedAt == null) ?? rows[0] ?? null;
  }

  /**
   * RF-47: lo ven el despachador de origen y el de destino, el operador de
   * la central del dron y el administrador. El solicitante no.
   */
  async forOrder(user: User, orderId: string) {
    const order = await this.manifests.manager.findOne(Order, {
      where: { id: orderId },
    });
    if (!order || !this.canSee(user, order)) {
      throw new ForbiddenException(MANIFEST_FORBIDDEN);
    }
    const rows = await this.manifests.find({
      where: { orderId },
      order: { issuedAt: 'DESC' },
    });
    if (!rows.length) {
      throw new NotFoundException(MANIFEST_NOT_FOUND);
    }
    const [current, ...previous] = rows;
    return { ...present(current), previous: previous.map(present) };
  }

  private canSee(user: User, order: Order): boolean {
    if (user.role === UserRole.ADMIN) {
      return true;
    }
    const hubs = assignedHubIds(user);
    if (user.role === UserRole.FLEET_OPERATOR) {
      return order.originHubId != null && hubs.includes(order.originHubId);
    }
    if (user.role === UserRole.DISPATCHER) {
      return [order.originHubId, order.destinationHubId].some(
        (id) => id != null && hubs.includes(id),
      );
    }
    return false;
  }

  private async destinationName(
    manager: EntityManager,
    order: Order,
  ): Promise<string> {
    if (order.destinationHubId) {
      const hub = await manager.findOne(Hub, {
        where: { id: order.destinationHubId },
      });
      if (hub) {
        return hub.name;
      }
    }
    return order.address.slice(0, 80);
  }
}

export function present(manifest: CargoManifest) {
  return {
    id: manifest.id,
    number: manifest.number,
    orderId: manifest.orderId,
    issuedAt: manifest.issuedAt,
    drone: {
      id: manifest.droneId,
      identifier: manifest.droneIdentifier,
      kind: manifest.droneKind,
    },
    origin: { hubId: manifest.originHubId, name: manifest.originName },
    destination: manifest.destinationName,
    items: manifest.items,
    payloadKg: manifest.payloadKg,
    coldCompartmentKg: manifest.coldCompartmentKg,
    coldRange: manifest.coldRange,
    authorizedBy: {
      userId: manifest.authorizedByUserId,
      name: manifest.authorizedByName,
    },
    voidedAt: manifest.voidedAt,
    voidReason: manifest.voidReason,
  };
}
