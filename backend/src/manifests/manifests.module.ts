import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { CargoManifest } from './cargo-manifest.entity';
import { ManifestsController } from './manifests.controller';
import { ManifestsService } from './manifests.service';

@Module({
  imports: [TypeOrmModule.forFeature([CargoManifest]), AuthModule],
  controllers: [ManifestsController],
  providers: [ManifestsService],
  exports: [ManifestsService],
})
export class ManifestsModule {}
