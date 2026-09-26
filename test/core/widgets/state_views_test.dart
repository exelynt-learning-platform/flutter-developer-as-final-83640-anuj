import 'package:exelynt_learning/core/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('LoadingView shows a spinner', (tester) async {
    await tester.pumpWidget(wrap(const LoadingView()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('EmptyView shows its message and an icon', (tester) async {
    await tester.pumpWidget(wrap(const EmptyView(message: 'No employees found')));

    expect(find.text('No employees found'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('ErrorView shows its message and no retry button by default', (tester) async {
    await tester.pumpWidget(wrap(const ErrorView(message: 'Something went wrong')));

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('ErrorView calls onRetry when the Retry button is tapped', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      wrap(ErrorView(message: 'Failed to load', onRetry: () => retried = true)),
    );

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
