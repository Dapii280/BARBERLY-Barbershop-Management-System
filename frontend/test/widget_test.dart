import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/app_strings.dart';
import 'package:frontend/core/theme.dart';

void main() {
  testWidgets('AppTheme dan AppStrings dapat dimuat', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: Text(AppStrings.of('id', 'app_name')),
          ),
        ),
      ),
    );

    expect(find.text('Barberly'), findsOneWidget);
  });
}
