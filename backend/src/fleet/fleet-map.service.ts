import { ForbiddenException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { GeofencesService } from '../geofences/geofences.service';
import { Hub } from '../hubs/hub.entity';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { Drone } from './drone.entity';
import { FleetFlightsService } from './fleet-flights.service';
import { presentMapHub } from './fleet-map.rules';

/**
 * El mapa del operador al abrirlo: sus centrales con la flota, las geovallas
 * y los vuelos en curso. Lo que se mueve después llega por la sala de la
 * central en el socket (`hub-telemetry`, `hub-flight-status`,
 * `hub-flight-ended`).
 */
@Injectable()
export class FleetMapService {
  constructor(
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
    private readonly geofences: GeofencesService,
    private readonly flights: FleetFlightsService,
  ) {}

  async map(user: User, hubId?: string) {
    const assigned = assignedHubIds(user);
    if (hubId && !assigned.includes(hubId)) {
      throw new ForbiddenException('Esa central no está asignada a tu cuenta.');
    }
    const hubIds = hubId ? [hubId] : assigned;
    const [hubs, drones, geofences, flights] = await Promise.all([
      this.hubs.find({ where: { id: In(hubIds) }, order: { name: 'ASC' } }),
      this.drones.find({
        where: { hubId: In(hubIds) },
        select: { id: true, hubId: true, status: true },
      }),
      this.geofences.list(),
      this.flights.listFlights(user, hubId),
    ]);
    return {
      hubs: hubs.map((hub) => presentMapHub(hub, drones)),
      geofences: geofences.map((fence) => ({
        id: fence.id,
        name: fence.name,
        reason: fence.reason,
        polygon: fence.polygon,
      })),
      flights,
    };
  }
}
