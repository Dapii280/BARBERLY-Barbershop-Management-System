import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/dashboard_summary.dart';

class DashboardRepository {
  Future<DashboardSummary> fetchSummary() async {
    final data = await ApiClient.instance.get('/dashboard/summary');
    return DashboardSummary.fromJson(asMap(data));
  }
}
