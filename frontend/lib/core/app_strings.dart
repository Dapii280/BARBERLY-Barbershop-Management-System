import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';

/// Kamus terjemahan Indonesia (indeks 0) dan English (indeks 1).
class AppStrings {
  AppStrings._();

  static const Map<String, List<String>> _values = {
    'app_name': ['Barberly', 'Barberly'],
    'tagline': ['Sistem Manajemen Barbershop', 'Barbershop Management System'],
    'save': ['Simpan', 'Save'],
    'save_changes': ['Simpan Perubahan', 'Save Changes'],
    'cancel': ['Batal', 'Cancel'],
    'delete': ['Hapus', 'Delete'],
    'edit': ['Ubah', 'Edit'],
    'add': ['Tambah', 'Add'],
    'close': ['Tutup', 'Close'],
    'confirm': ['Konfirmasi', 'Confirm'],
    'back': ['Kembali', 'Back'],
    'retry': ['Coba Lagi', 'Try Again'],
    'loading': ['Memuat...', 'Loading...'],
    'saving': ['Menyimpan...', 'Saving...'],
    'processing': ['Memproses...', 'Processing...'],
    'all': ['Semua', 'All'],
    'optional': ['Opsional', 'Optional'],
    'logout': ['Keluar', 'Log Out'],
    'profile': ['Profil', 'Profile'],
    'language': ['Bahasa', 'Language'],
    'indonesia': ['Indonesia', 'Indonesian'],
    'english': ['English', 'English'],
    'today': ['Hari Ini', 'Today'],
    'no_data': ['Belum ada data', 'No data yet'],
    'minutes': ['menit', 'minutes'],
    'view_all': ['Lihat Semua', 'View All'],
    'not_selected': ['Belum dipilih', 'Not selected'],
    'actions': ['Aksi', 'Actions'],
    'total': ['Total', 'Total'],
    'status': ['Status', 'Status'],
    'notes': ['Catatan', 'Notes'],
    'required': ['wajib diisi', 'is required'],
    'success': ['Berhasil', 'Success'],
    'failed': ['Gagal', 'Failed'],
    'yes': ['Ya', 'Yes'],
    'no': ['Tidak', 'No'],
    'photo': ['Foto', 'Photo'],

    'login': ['Masuk', 'Sign In'],
    'login_title': ['Masuk ke akun Anda', 'Sign in to your account'],
    'login_subtitle': [
      'Kelola jadwal potong rambut Anda dengan mudah',
      'Manage your haircut appointments easily',
    ],
    'email': ['Email', 'Email'],
    'password': ['Password', 'Password'],
    'register': ['Daftar', 'Sign Up'],
    'register_title': ['Buat akun baru', 'Create a new account'],
    'register_subtitle': [
      'Daftar sebagai pelanggan Barberly',
      'Sign up as a Barberly customer',
    ],
    'full_name': ['Nama Lengkap', 'Full Name'],
    'phone': ['Nomor HP', 'Phone Number'],
    'confirm_password': ['Konfirmasi Password', 'Confirm Password'],
    'have_account': ['Sudah punya akun?', 'Already have an account?'],
    'no_account': ['Belum punya akun?', "Don't have an account?"],
    'create_account': ['Daftar Sekarang', 'Create Account'],
    'login_success': ['Login berhasil', 'Signed in successfully'],
    'register_success': [
      'Registrasi berhasil, silakan masuk',
      'Registration successful, please sign in',
    ],
    'password_not_match': ['Konfirmasi password tidak sama', 'Passwords do not match'],
    'password_min_length': [
      'Password minimal 8 karakter',
      'Password must be at least 8 characters',
    ],
    'invalid_email': ['Format email tidak valid', 'Invalid email format'],
    'required_field': ['Wajib diisi', 'Required'],
    'demo_accounts': ['Akun demo', 'Demo accounts'],
    'demo_accounts_hint': [
      'Ketuk untuk mengisi form otomatis',
      'Tap to fill the form automatically',
    ],
    'demo_fill': ['Isi', 'Fill'],

    'nav_home': ['Beranda', 'Home'],
    'nav_services': ['Layanan', 'Services'],
    'nav_history': ['Riwayat', 'History'],
    'nav_profile': ['Profil', 'Profile'],
    'nav_schedule': ['Jadwal', 'Schedule'],
    'nav_dashboard': ['Dashboard', 'Dashboard'],
    'nav_bookings': ['Booking', 'Bookings'],
    'nav_transactions': ['Transaksi', 'Transactions'],

    'role_admin': ['Admin', 'Admin'],
    'role_barber': ['Barber', 'Barber'],
    'role_customer': ['Pelanggan', 'Customer'],
    'active': ['Aktif', 'Active'],
    'inactive': ['Nonaktif', 'Inactive'],

    'status_pending': ['Menunggu', 'Pending'],
    'status_confirmed': ['Dikonfirmasi', 'Confirmed'],
    'status_completed': ['Selesai', 'Completed'],
    'status_cancelled': ['Dibatalkan', 'Cancelled'],
    'payment_status_waiting': ['Menunggu Verifikasi', 'Waiting for Review'],
    'payment_status_paid': ['Lunas', 'Paid'],
    'payment_status_rejected': ['Ditolak', 'Rejected'],

    'home_greeting': ['Halo', 'Hello'],
    'home_title': ['Siap tampil rapi hari ini?', 'Ready to look sharp today?'],
    'home_subtitle': [
      'Pilih layanan, barber, dan jadwal favoritmu.',
      'Choose your service, barber, and favorite time.',
    ],
    'promo_title': ['Booking tanpa antre', 'Book without the queue'],
    'promo_desc': [
      'Pilih jadwal, bayar, lalu datang tepat waktu.',
      'Pick a time, pay, and arrive right on time.',
    ],
    'promo_button': ['Booking Sekarang', 'Book Now'],
    'popular_services': ['Layanan Populer', 'Popular Services'],
    'our_barbers': ['Barber Kami', 'Our Barbers'],
    'quick_access': ['Akses Cepat', 'Quick Access'],
    'services_count': ['layanan tersedia', 'services available'],
    'barbers_count': ['barber siap melayani', 'barbers ready to serve'],

    'services_title': ['Layanan', 'Services'],
    'services_subtitle': [
      'Pilih layanan yang kamu butuhkan.',
      'Choose the service you need.',
    ],
    'service_detail': ['Detail Layanan', 'Service Detail'],
    'duration': ['Durasi', 'Duration'],
    'price': ['Harga', 'Price'],
    'book_now': ['Booking Sekarang', 'Book Now'],
    'no_services': ['Belum ada layanan tersedia', 'No services available yet'],
    'service_inactive': ['Nonaktif', 'Inactive'],
    'service_active': ['Aktif', 'Active'],
    'per_service': ['per layanan', 'per service'],

    'barbers_title': ['Barber', 'Barbers'],
    'barbers_subtitle': [
      'Pilih barber yang paling cocok untukmu.',
      'Choose the barber that suits you best.',
    ],
    'specialty': ['Spesialisasi', 'Specialty'],
    'work_hours': ['Jam Kerja', 'Working Hours'],
    'no_barbers': ['Belum ada barber tersedia', 'No barbers available yet'],
    'choose_barber': ['Pilih Barber', 'Choose Barber'],
    'choose_barber_hint': ['Tentukan barber terlebih dahulu', 'Select a barber first'],
    'available_slots': ['Jam Tersedia', 'Available Times'],
    'no_slots': [
      'Tidak ada slot kosong pada tanggal ini',
      'No available slots on this date',
    ],
    'slots_hint': [
      'Pilih layanan, barber, dan tanggal untuk melihat jam kosong',
      'Select services, a barber, and a date to see available times',
    ],
    'barber_profile': ['Profil Barber', 'Barber Profile'],

    'booking_title': ['Booking', 'Booking'],
    'booking_form_title': ['Buat Booking', 'Create Booking'],
    'create_booking': ['Buat Booking', 'Create Booking'],
    'select_services': ['Pilih Layanan', 'Select Services'],
    'select_date': ['Pilih Tanggal', 'Select Date'],
    'select_time': ['Pilih Jam', 'Select Time'],
    'notes_hint': [
      'Contoh: potongan pendek, jangan terlalu tipis di samping',
      'Example: short cut, not too thin on the sides',
    ],
    'bill_detail': ['Rincian Biaya', 'Bill Details'],
    'subtotal': ['Subtotal', 'Subtotal'],
    'ppn': ['PPN', 'VAT'],
    'tax_deduction': ['Potongan', 'Deduction'],
    'total_payment': ['Total Bayar', 'Total Payment'],
    'booking_created': ['Booking berhasil dibuat', 'Booking created successfully'],
    'booking_history': ['Riwayat Booking', 'Booking History'],
    'booking_history_subtitle': [
      'Pantau status dan pembayaran booking Anda.',
      'Track your booking and payment status.',
    ],
    'no_bookings': ['Belum ada booking', 'No bookings yet'],
    'cancel_booking': ['Batalkan Booking', 'Cancel Booking'],
    'cancel_booking_title': ['Batalkan booking?', 'Cancel this booking?'],
    'cancel_booking_message': [
      'Jadwal yang dibatalkan tidak dapat dikembalikan.',
      'A cancelled booking cannot be restored.',
    ],
    'booking_cancelled': ['Booking berhasil dibatalkan', 'Booking cancelled'],
    'pay_now': ['Bayar Sekarang', 'Pay Now'],
    'booking_detail': ['Detail Booking', 'Booking Detail'],
    'customer': ['Pelanggan', 'Customer'],
    'barber': ['Barber', 'Barber'],
    'services': ['Layanan', 'Services'],
    'date': ['Tanggal', 'Date'],
    'time': ['Jam', 'Time'],
    'transaction_status': ['Status Pembayaran', 'Payment Status'],
    'waiting_payment': ['Menunggu pembayaran', 'Waiting for payment'],
    'details': ['Detail', 'Details'],
    'service_count': ['layanan', 'services'],
    'no_service_selected': ['Pilih minimal satu layanan', 'Select at least one service'],
    'select_services_hint': ['Ketuk layanan untuk memilih', 'Tap a service to select'],
    'booking_not_paid': ['Booking belum dibayar', 'Booking is not paid yet'],

    'payment_title': ['Pembayaran', 'Payment'],
    'payment_subtitle': [
      'Unggah bukti transfer agar booking dikonfirmasi admin.',
      'Upload your transfer proof so the admin can confirm your booking.',
    ],
    'payment_method': ['Metode Pembayaran', 'Payment Method'],
    'method_transfer': ['Transfer Bank', 'Bank Transfer'],
    'method_ewallet': ['E-Wallet', 'E-Wallet'],
    'method_cash': ['Tunai', 'Cash'],
    'upload_proof': ['Bukti Pembayaran', 'Payment Proof'],
    'proof_hint': [
      'Ketuk untuk memilih foto bukti transfer',
      'Tap to choose a transfer proof photo',
    ],
    'change_photo': ['Ganti Foto', 'Change Photo'],
    'send_proof': ['Kirim Bukti Bayar', 'Send Payment Proof'],
    'proof_required': ['Bukti pembayaran wajib dipilih', 'Payment proof is required'],
    'proof_sent': ['Bukti pembayaran terkirim', 'Payment proof submitted'],
    'payment_info': [
      'Admin akan memverifikasi pembayaran Anda.',
      'The admin will verify your payment.',
    ],
    'payment_for': ['Pembayaran untuk', 'Payment for'],
    'select_payment_method': ['Pilih metode pembayaran', 'Choose a payment method'],

    'schedule_title': ['Jadwal Barber', 'Barber Schedule'],
    'schedule_subtitle': [
      'Konfirmasi atau selesaikan booking pelanggan.',
      'Confirm or complete customer bookings.',
    ],
    'no_schedule': ['Tidak ada jadwal pada tanggal ini', 'No schedule on this date'],
    'confirm_booking': ['Konfirmasi', 'Confirm'],
    'complete_booking': ['Selesai', 'Complete'],
    'confirm_booking_message': ['Konfirmasi booking ini?', 'Confirm this booking?'],
    'complete_booking_message': [
      'Tandai booking ini sebagai selesai?',
      'Mark this booking as completed?',
    ],

    'dashboard_title': ['Dashboard', 'Dashboard'],
    'dashboard_subtitle': [
      'Ringkasan operasional barbershop hari ini.',
      "Today's barbershop operations summary.",
    ],
    'today_bookings': ['Booking Hari Ini', "Today's Bookings"],
    'total_bookings': ['Total Booking', 'Total Bookings'],
    'total_revenue': ['Total Pendapatan', 'Total Revenue'],
    'today_revenue': ['Pendapatan Hari Ini', "Today's Revenue"],
    'pending_transactions': ['Menunggu Verifikasi', 'Awaiting Review'],
    'total_customers': ['Total Pelanggan', 'Total Customers'],
    'total_barbers': ['Total Barber', 'Total Barbers'],
    'top_services': ['Layanan Terlaris', 'Best-Selling Services'],
    'no_top_services': [
      'Belum ada data layanan terlaris',
      'No best-selling service data yet',
    ],
    'quick_menu': ['Menu Cepat', 'Quick Menu'],
    'manage_barbers': ['Kelola Barber', 'Manage Barbers'],
    'manage_users': ['Kelola Pengguna', 'Manage Users'],
    'verify_transactions': ['Verifikasi Pembayaran', 'Verify Payments'],
    'manage_services': ['Kelola Layanan', 'Manage Services'],
    'welcome_admin': ['Selamat datang', 'Welcome'],
    'booking_status_summary': ['Ringkasan Status Booking', 'Booking Status Summary'],
    'booked_times': ['kali dipesan', 'times booked'],
    'pending_count': ['menunggu', 'waiting'],

    'manage_services_title': ['Kelola Layanan', 'Manage Services'],
    'manage_services_subtitle': [
      'Tambah, ubah, atau nonaktifkan layanan.',
      'Add, edit, or deactivate services.',
    ],
    'add_service': ['Tambah Layanan', 'Add Service'],
    'edit_service': ['Ubah Layanan', 'Edit Service'],
    'service_form_hint': [
      'Lengkapi data layanan di bawah ini.',
      'Complete the service details below.',
    ],
    'service_name': ['Nama Layanan', 'Service Name'],
    'service_description': ['Deskripsi', 'Description'],
    'service_price': ['Harga (Rp)', 'Price (IDR)'],
    'service_duration': ['Durasi (menit)', 'Duration (minutes)'],
    'service_image': ['Foto Layanan', 'Service Photo'],
    'service_status': ['Status Layanan', 'Service Status'],
    'delete_service': ['Hapus Layanan', 'Delete Service'],
    'delete_service_message': [
      'Layanan akan dihapus permanen. Lanjutkan?',
      'The service will be permanently deleted. Continue?',
    ],
    'service_saved': ['Layanan berhasil disimpan', 'Service saved'],
    'service_deleted': ['Layanan berhasil dihapus', 'Service deleted'],
    'invalid_price': [
      'Harga harus berupa angka lebih dari 0',
      'Price must be a number greater than 0',
    ],
    'invalid_duration': [
      'Durasi harus berupa angka lebih dari 0',
      'Duration must be a number greater than 0',
    ],

    'manage_barbers_title': ['Kelola Barber', 'Manage Barbers'],
    'manage_barbers_subtitle': [
      'Kelola akun, foto, dan jam kerja barber.',
      'Manage barber accounts, photos, and working hours.',
    ],
    'add_barber': ['Tambah Barber', 'Add Barber'],
    'edit_barber': ['Ubah Barber', 'Edit Barber'],
    'barber_form_hint': [
      'Data akun dan profil barber.',
      'Barber account and profile details.',
    ],
    'barber_account': ['Akun Barber', 'Barber Account'],
    'barber_password_hint': ['Minimal 8 karakter', 'At least 8 characters'],
    'barber_specialty': ['Spesialisasi', 'Specialty'],
    'barber_bio': ['Bio', 'Bio'],
    'work_start': ['Jam Mulai', 'Start Time'],
    'work_end': ['Jam Selesai', 'End Time'],
    'barber_photo': ['Foto Barber', 'Barber Photo'],
    'barber_status': ['Status Barber', 'Barber Status'],
    'delete_barber': ['Hapus Barber', 'Delete Barber'],
    'delete_barber_message': [
      'Akun dan profil barber akan dihapus. Lanjutkan?',
      'The barber account and profile will be deleted. Continue?',
    ],
    'barber_saved': ['Data barber berhasil disimpan', 'Barber saved'],
    'barber_deleted': ['Barber berhasil dihapus', 'Barber deleted'],
    'invalid_work_hours': [
      'Jam selesai harus setelah jam mulai',
      'End time must be after start time',
    ],
    'password_keep_hint': [
      'Kosongkan jika tidak ingin mengubah password',
      'Leave blank to keep the current password',
    ],
    'barber_email_hint': [
      'Email dipakai untuk login barber',
      'This email is used for barber login',
    ],

    'manage_bookings_title': ['Kelola Booking', 'Manage Bookings'],
    'manage_bookings_subtitle': [
      'Filter dan perbarui status seluruh booking.',
      'Filter and update all booking statuses.',
    ],
    'filter_date': ['Filter Tanggal', 'Filter Date'],
    'filter_barber': ['Filter Barber', 'Filter Barber'],
    'filter_status': ['Filter Status', 'Filter Status'],
    'reset_filter': ['Reset Filter', 'Reset Filters'],
    'record_cash': ['Bayar Tunai', 'Record Cash'],
    'record_cash_confirm': [
      'Catat pembayaran tunai untuk booking ini?',
      'Record a cash payment for this booking?',
    ],
    'cash_recorded': ['Pembayaran tunai dicatat', 'Cash payment recorded'],
    'change_status': ['Ubah Status', 'Change Status'],
    'complete': ['Selesaikan', 'Complete'],
    'approve': ['Setujui', 'Approve'],
    'reject': ['Tolak', 'Reject'],
    'action': ['Aksi', 'Action'],
    'filter_active': ['Filter aktif', 'Filters active'],
    'all_barbers': ['Semua Barber', 'All Barbers'],
    'all_statuses': ['Semua Status', 'All Statuses'],

    'verify_title': ['Verifikasi Pembayaran', 'Verify Payments'],
    'verify_subtitle': [
      'Periksa bukti bayar lalu setujui atau tolak.',
      'Review payment proofs and approve or reject them.',
    ],
    'filter_waiting': ['Menunggu', 'Waiting'],
    'filter_paid': ['Lunas', 'Paid'],
    'filter_rejected': ['Ditolak', 'Rejected'],
    'no_transactions': ['Tidak ada transaksi', 'No transactions'],
    'approve_transaction': ['Setujui pembayaran?', 'Approve this payment?'],
    'approve_transaction_message': [
      'Booking akan otomatis berstatus dikonfirmasi.',
      'The booking will be set to confirmed automatically.',
    ],
    'reject_transaction': ['Tolak pembayaran', 'Reject Payment'],
    'reject_transaction_message': [
      'Tuliskan alasan agar pelanggan dapat memperbaiki bukti bayar.',
      'Write a reason so the customer can correct the payment proof.',
    ],
    'rejection_note': ['Alasan Penolakan', 'Rejection Reason'],
    'rejection_note_hint': [
      'Contoh: nominal transfer tidak sesuai',
      'Example: transfer amount does not match',
    ],
    'note_required': ['Alasan penolakan wajib diisi', 'Rejection reason is required'],
    'transaction_approved': ['Pembayaran disetujui', 'Payment approved'],
    'transaction_rejected': ['Pembayaran ditolak', 'Payment rejected'],
    'proof_of_payment': ['Bukti Pembayaran', 'Payment Proof'],
    'paid_at': ['Dibayar Pada', 'Paid At'],
    'amount': ['Nominal', 'Amount'],
    'view_proof': ['Lihat Bukti', 'View Proof'],
    'customer_booking': ['Booking Pelanggan', 'Customer Booking'],
    'admin_note': ['Catatan Admin', 'Admin Note'],

    'manage_users_title': ['Kelola Pengguna', 'Manage Users'],
    'manage_users_subtitle': [
      'Atur role dan status aktif akun.',
      'Manage account roles and active status.',
    ],
    'user_role': ['Role Pengguna', 'User Role'],
    'account_status': ['Status Akun', 'Account Status'],
    'role_updated': ['Role pengguna diperbarui', 'User role updated'],
    'user_updated': ['Data pengguna diperbarui', 'User updated'],
    'cannot_edit_self': ['Tidak dapat mengubah akun sendiri', 'You cannot edit your own account'],

    'profile_title': ['Profil Saya', 'My Profile'],
    'edit_profile': ['Edit Profil', 'Edit Profile'],
    'edit_profile_hint': [
      'Perbarui nama dan nomor HP Anda.',
      'Update your name and phone number.',
    ],
    'change_password': ['Ubah Password', 'Change Password'],
    'current_password': ['Password Saat Ini', 'Current Password'],
    'new_password': ['Password Baru', 'New Password'],
    'confirm_new_password': ['Konfirmasi Password Baru', 'Confirm New Password'],
    'profile_updated': ['Profil berhasil diperbarui', 'Profile updated'],
    'password_updated': ['Password berhasil diperbarui', 'Password updated'],
    'photo_updated': ['Foto profil berhasil diperbarui', 'Profile photo updated'],
    'language_setting': ['Bahasa Antarmuka', 'Interface Language'],
    'language_hint': [
      'Perubahan bahasa berlaku langsung.',
      'The language changes immediately.',
    ],
    'logout_confirm_title': ['Keluar dari akun?', 'Log out?'],
    'logout_confirm_message': [
      'Anda perlu masuk kembali untuk memakai aplikasi.',
      'You will need to sign in again to use the app.',
    ],
    'member_since': ['Bergabung sejak', 'Joined since'],
    'upload_photo': ['Unggah Foto', 'Upload Photo'],
    'account_info': ['Informasi Akun', 'Account Information'],

    'err_network': [
      'Tidak dapat terhubung ke server. Pastikan backend berjalan.',
      'Cannot reach the server. Make sure the backend is running.',
    ],
    'err_generic': [
      'Terjadi kesalahan. Silakan coba lagi.',
      'Something went wrong. Please try again.',
    ],
    'err_session_expired': [
      'Sesi berakhir, silakan masuk kembali.',
      'Session expired, please sign in again.',
    ],
    'picker_gallery': ['Pilih dari Galeri', 'Choose from Gallery'],
    'image_hint': ['Ketuk untuk memilih gambar', 'Tap to choose an image'],
  };

  static String of(String languageCode, String key) {
    final entry = _values[key];
    if (entry == null) return key;
    return languageCode == 'en' ? entry[1] : entry[0];
  }
}

extension TranslateContext on BuildContext {
  /// Terjemahan reaktif (dipakai di dalam build).
  String tr(String key) {
    final languageCode = watch<LocaleProvider>().languageCode;
    return AppStrings.of(languageCode, key);
  }

  /// Terjemahan non-reaktif (dipakai di callback / setelah await).
  String trNow(String key) {
    final languageCode = read<LocaleProvider>().languageCode;
    return AppStrings.of(languageCode, key);
  }
}
