import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taw_app/main.dart';

void main() {
  testWidgets('shows the TutorsAtWork login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TawApp()));

    expect(find.text('TutorsAtWork'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
