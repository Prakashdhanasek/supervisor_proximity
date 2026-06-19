import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supervisor_proximity/controllers/fleet_controller.dart';
import 'package:supervisor_proximity/views/scorecards_view.dart';
import 'package:supervisor_proximity/views/incidents_view.dart';
import 'package:supervisor_proximity/views/theme/app_theme.dart';

void main() {
  group('FleetController Tests', () {
    test('Adding a driver increases the scorecards list and updates oversight count', () {
      final controller = FleetController();
      final initialCount = controller.driversOverseen;

      controller.addDriver(
        name: 'Test Driver',
        vehicleReg: 'KL 01 XY 9999',
        safetyScore: 95,
      );

      expect(controller.driversOverseen, initialCount + 1);
      expect(controller.scorecards.last.name, 'Test Driver');
      expect(controller.scorecards.last.vehicleReg, 'KL 01 XY 9999');
      expect(controller.scorecards.last.safetyScore, 95);

      controller.dispose();
    });
  });

  group('ScorecardsView Widget Tests', () {
    testWidgets('ScorecardsView renders list and shows add driver dialog', (WidgetTester tester) async {
      final controller = FleetController();

      await tester.pumpWidget(
        ChangeNotifierProvider<FleetController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ScorecardsView(),
          ),
        ),
      );

      // Verify page title is present
      expect(find.text('Driver Scorecards'), findsOneWidget);

      // Verify the Add Driver FAB exists
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      expect(find.text('Add Driver'), findsOneWidget);

      // Tap the FAB to open the dialog
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify the dialog is displayed
      expect(find.text('Add New Driver'), findsOneWidget);
      expect(find.text('Driver Name'), findsOneWidget);
      expect(find.text('Vehicle Registration'), findsOneWidget);
      expect(find.text('Initial Safety Score'), findsOneWidget);

      // Verify we can see the cancel and add buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      // Tap cancel to close dialog and clean up
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      controller.dispose();
    });
  });

  group('IncidentsView Filtering Tests', () {
    testWidgets('Tapping advanced filter button toggles the advanced filters panel and filters incidents', (WidgetTester tester) async {
      final controller = FleetController();

      await tester.pumpWidget(
        ChangeNotifierProvider<FleetController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const IncidentsView(),
          ),
        ),
      );

      // Verify page title is present
      expect(find.text('Incidents'), findsOneWidget);

      // Advanced filters panel should NOT be visible initially
      expect(find.text('Driver Name'), findsNothing);
      expect(find.text('Vehicle Reg'), findsNothing);

      // Tap advanced filter button (IconButton with tune icon)
      final tuneIconFinder = find.byIcon(Icons.tune_outlined);
      expect(tuneIconFinder, findsOneWidget);
      await tester.tap(tuneIconFinder);
      await tester.pumpAndSettle();

      // Advanced filters panel should now be visible
      expect(find.text('Driver Name'), findsOneWidget);
      expect(find.text('Vehicle Reg'), findsOneWidget);

      // Enter driver name to search
      await tester.enterText(find.widgetWithText(TextField, 'Driver Name'), 'Joel');
      await tester.pumpAndSettle();

      // Verify list is filtered (only showing Joel Thomas's incident)
      expect(find.text('Joel Thomas'), findsWidgets);
      expect(find.text('Priya Nair'), findsNothing);

      controller.dispose();
    });
  });
}
