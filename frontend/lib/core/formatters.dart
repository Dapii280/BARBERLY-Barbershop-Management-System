import 'package:intl/intl.dart';

/// Format Rupiah tanpa desimal, contoh: Rp 87.200
String formatRupiah(num value) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);

/// Mengubah "2026-12-01" menjadi "Selasa, 1 Desember 2026" / "Tuesday, 1 December 2026".
String formatDateLong(String date, String languageCode) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return date;

  return DateFormat(
    'EEEE, d MMMM yyyy',
    languageCode == 'en' ? 'en_US' : 'id_ID',
  ).format(parsed);
}

String formatDateShort(String date, String languageCode) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return date;

  return DateFormat(
    'd MMM yyyy',
    languageCode == 'en' ? 'en_US' : 'id_ID',
  ).format(parsed);
}

/// "09:00:00" -> "09:00"
String formatTime(String time) {
  if (time.length >= 5) return time.substring(0, 5);
  return time;
}

String formatTimeRange(String startTime, String endTime) =>
    '${formatTime(startTime)} - ${formatTime(endTime)}';

String formatDateTime(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value.replaceFirst(' ', 'T'));
  if (parsed == null) return value;

  return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(parsed);
}

String formatIsoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime todayDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
