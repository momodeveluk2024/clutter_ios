import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapplication/theme.dart';
import 'package:myapplication/widgets.dart';

void main() {
  testWidgets('UserAvatar falls back to initials and shows edit affordance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NVTheme.light(),
        home: const Scaffold(
          body: UserAvatar(
            displayName: 'Ahmed Hassan',
            avatarUrl: '',
            editable: true,
          ),
        ),
      ),
    );

    expect(find.text('AH'), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
  });
}
