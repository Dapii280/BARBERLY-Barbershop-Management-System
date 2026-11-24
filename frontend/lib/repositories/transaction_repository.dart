import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/transaction.dart';

class TransactionRepository {
  Future<List<TransactionModel>> fetchTransactions({String? paymentStatus}) async {
    final data = await ApiClient.instance.get(
      '/transactions',
      query: paymentStatus == null || paymentStatus.isEmpty
          ? null
          : {'payment_status': paymentStatus},
    );

    return asList(data)
        .whereType<Map>()
        .map((item) => TransactionModel.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<TransactionModel> verify({
    required int id,
    required String paymentStatus,
    String? note,
  }) async {
    final data = await ApiClient.instance.patch(
      '/transactions/$id/verify',
      body: {
        'payment_status': paymentStatus,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return TransactionModel.fromJson(asMap(data));
  }
}
