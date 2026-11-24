class AppConstants {
  AppConstants._();

  // Emulator Android memakai 10.0.2.2 untuk mengakses localhost laptop.
  // Untuk produksi, ganti dengan URL backend Vercel, contoh:
  // https://barberly-api.vercel.app/api/v1
  static const String baseUrl = 'http://localhost:5000/api/v1';

  static const String appName = 'Barberly';

  // Harus sama dengan PPN_RATE dan TAX_DEDUCTION_RATE di backend/.env
  static const double ppnRate = 0.11;
  static const double taxDeductionRate = 0.02;

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Mengarahkan URL gambar lokal (localhost) ke host API yang sedang dipakai.
String resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (!url.startsWith('http')) return url;

  final imageUri = Uri.tryParse(url);
  if (imageUri == null) return url;

  final isLocalHost = imageUri.host == 'localhost' || imageUri.host == '127.0.0.1';
  if (!isLocalHost) return url;

  final baseUri = Uri.parse(AppConstants.baseUrl);
  return Uri(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.hasPort ? baseUri.port : null,
    path: imageUri.path,
  ).toString();
}
