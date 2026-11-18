import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AirspaceService } from './airspace.service';

@ApiTags('Espacio aéreo')
@ApiBearerAuth()
@Controller('airspace')
@UseGuards(JwtAuthGuard)
export class AirspaceController {
  constructor(private readonly airspace: AirspaceService) {}

  /** RF-43: las zonas legales, para dibujarlas en cualquier mapa. */
  @Get('zones')
  zones() {
    return this.airspace.view();
  }
}
