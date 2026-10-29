import 'analytics_models.dart';
import 'analytics_repository.dart';

/// Métricas para `DataSource.local`: unos pocos KPI de cada grupo, una
/// semana de demanda y dos centrales.
class LocalAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<KpiReport> kpis(AnalyticsQuery query) async => const KpiReport(
    groups: [
      KpiGroup(
        key: 'results',
        label: 'Resultados',
        kpis: [
          Kpi(
            key: 'successRate',
            label: 'Entregas exitosas',
            unit: '%',
            status: KpiStatus.green,
            value: 92.5,
            target: KpiTarget(kind: 'min', green: 90, amber: 75),
            previous: 88,
            delta: 4.5,
          ),
          Kpi(
            key: 'missions',
            label: 'Misiones',
            unit: '',
            status: KpiStatus.none,
            value: 44,
            previous: 39,
            delta: 5,
          ),
        ],
      ),
      KpiGroup(
        key: 'failures',
        label: 'Fallas',
        kpis: [
          Kpi(
            key: 'coldChainAlerts',
            label: 'Alertas de frío',
            unit: '',
            status: KpiStatus.amber,
            value: 2,
            target: KpiTarget(kind: 'max', green: 0, amber: 2),
          ),
          Kpi(
            key: 'returnRate',
            label: 'Retornos',
            unit: '%',
            status: KpiStatus.none,
          ),
        ],
      ),
    ],
  );

  @override
  Future<DemandReport> demand(AnalyticsQuery query) async => const DemandReport(
    topMedications: [
      MedicationDemand('Acetaminofén 500 mg', 18, 22, 1),
      MedicationDemand('Insulina glargina 100 UI/ml', 9, 9, 0),
    ],
    byDestinationHub: [(name: 'Clínica Norte', orders: 4)],
    cells: [ZoneCell(10.4635, -73.2535, 6), ZoneCell(10.4775, -73.2445, 3)],
    hiddenOrders: 2,
    byDay: [
      DayDemand('2026-10-23', 2, 3),
      DayDemand('2026-10-24', 1, 4),
      DayDemand('2026-10-25', 3, 2),
      DayDemand('2026-10-26', 0, 5),
      DayDemand('2026-10-27', 4, 3),
      DayDemand('2026-10-28', 2, 6),
      DayDemand('2026-10-29', 3, 4),
    ],
  );

  @override
  Future<List<HubRanking>> hubs(AnalyticsQuery query) async => const [
    HubRanking(
      hubId: 'local-hub',
      name: 'Hospital Rosario Pumarejo',
      missions: 30,
      availableDrones: 2,
      totalDrones: 3,
      successRate: 93.3,
      returnRate: 3.3,
      emergencyDeliveryMinutes: 14.2,
      coldChainAlerts: 1,
      fleetUtilization: 41,
    ),
    HubRanking(
      hubId: 'local-other-hub',
      name: 'Clínica Norte',
      missions: 14,
      availableDrones: 0,
      totalDrones: 1,
      successRate: 85.7,
      fleetUtilization: 63,
    ),
  ];
}
