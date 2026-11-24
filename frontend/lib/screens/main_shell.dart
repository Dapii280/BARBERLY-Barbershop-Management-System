import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/manage_bookings_screen.dart';
import 'admin/manage_services_screen.dart';
import 'admin/verify_transactions_screen.dart';
import 'barber/barber_schedule_screen.dart';
import 'customer/booking_history_screen.dart';
import 'customer/customer_home_screen.dart';
import 'customer/service_list_screen.dart';
import 'shared/profile_screen.dart';

/// Pembungkus navigasi bottom bar sesuai role pengguna.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role ?? 'customer';

    final pages = <Widget>[];
    final items = <BottomNavigationBarItem>[];

    switch (role) {
      case 'admin':
        pages.addAll([
          const AdminDashboardScreen(),
          const ManageBookingsScreen(),
          const ManageServicesScreen(),
          const VerifyTransactionsScreen(),
          const ProfileScreen(),
        ]);
        items.addAll([
          _item(Icons.grid_view_outlined, Icons.grid_view_rounded, 'nav_dashboard'),
          _item(Icons.calendar_month_outlined, Icons.calendar_month, 'nav_bookings'),
          _item(Icons.content_cut_outlined, Icons.content_cut, 'nav_services'),
          _item(Icons.receipt_long_outlined, Icons.receipt_long, 'nav_transactions'),
          _item(Icons.person_outline, Icons.person, 'nav_profile'),
        ]);
        break;
      case 'barber':
        pages.addAll([
          const BarberScheduleScreen(),
          const ProfileScreen(),
        ]);
        items.addAll([
          _item(Icons.event_note_outlined, Icons.event_note, 'nav_schedule'),
          _item(Icons.person_outline, Icons.person, 'nav_profile'),
        ]);
        break;
      default:
        pages.addAll([
          const CustomerHomeScreen(),
          const ServiceListScreen(),
          const BookingHistoryScreen(),
          const ProfileScreen(),
        ]);
        items.addAll([
          _item(Icons.home_outlined, Icons.home_rounded, 'nav_home'),
          _item(Icons.content_cut_outlined, Icons.content_cut, 'nav_services'),
          _item(Icons.history, Icons.history, 'nav_history'),
          _item(Icons.person_outline, Icons.person, 'nav_profile'),
        ]);
    }

    final index = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (value) => setState(() => _selectedIndex = value),
          items: items,
        ),
      ),
    );
  }

  BottomNavigationBarItem _item(IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 22),
      activeIcon: Icon(activeIcon, size: 22),
      label: context.tr(label),
    );
  }
}
