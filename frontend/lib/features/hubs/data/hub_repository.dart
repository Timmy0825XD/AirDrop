import 'hub_models.dart';

abstract class HubRepository {
  Future<HubSummary?> mine();
}
