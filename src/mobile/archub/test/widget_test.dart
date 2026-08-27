import 'package:archub/core/services/location_service.dart';
import 'package:archub/features/clocking/presentation/bloc/clocking_bloc.dart';
import 'package:archub/features/clocking/presentation/bloc/clocking_state.dart';
import 'package:archub/features/clocking/presentation/pages/punch_screen.dart';
import 'package:archub/features/clocking/presentation/pages/widgets/action_punch_button.dart';
import 'package:archub/features/clocking/presentation/pages/widgets/gps_badge.dart';
import 'package:archub/features/clocking/presentation/pages/widgets/live_shift_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockClockingBloc extends Mock implements ClockingBloc {}

void main() {
  late MockClockingBloc mockClockingBloc;

  setUp(() {
    mockClockingBloc = MockClockingBloc();
    when(() => mockClockingBloc.state).thenReturn(
      const ClockingState(
        status: ClockingStatus.idle,
        pendingCount: 2,
        currentLocation: LocationData(
          latitude: 45.4642,
          longitude: 9.1900,
          accuracy: 4.5,
        ),
      ),
    );
    when(() => mockClockingBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('PunchScreen renders title, shift timer, GPS badge, and large action buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ClockingBloc>.value(
          value: mockClockingBloc,
          child: const PunchScreen(),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Presenze & Timbrature'), findsOneWidget);

    // Verify LiveShiftTimer widget
    expect(find.byType(LiveShiftTimer), findsOneWidget);

    // Verify GPS Badge
    expect(find.byType(GpsBadge), findsOneWidget);
    expect(find.text('Posizione GPS'), findsOneWidget);

    // Verify Action Buttons (Entrata, Pausa, Uscita)
    expect(find.text('Entrata'), findsOneWidget);
    expect(find.text('Pausa'), findsOneWidget);
    expect(find.text('Uscita'), findsOneWidget);
    expect(find.byType(ActionPunchButton), findsNWidgets(3));

    // Verify Pending Sync Banner
    expect(find.text('2 marcature salvate offline'), findsOneWidget);
  });
}
