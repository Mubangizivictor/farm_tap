import 'package:farm_tap/core/settings/presentation/pages/help_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('Help opens WhatsApp, call and SMS to the support line', (tester) async {
    final opened = <Uri>[];
    await pumpFarmTap(
      tester,
      Scaffold(
        body: HelpPage(
          open: (uri) async {
            opened.add(uri);
            return uri.scheme != 'sms';
          },
        ),
      ),
    );
    await tester.tap(find.text('Chat on WhatsApp'));
    await tester.tap(find.text('Call us'));
    await tester.tap(find.text('Send an SMS'));
    await tester.pump();
    expect(opened.map((u) => '$u'), ['https://wa.me/256793128137', 'tel:+256793128137', 'sms:+256793128137']);
    expect(find.text('Could not open that on this phone.'), findsOneWidget);
    expect(find.text('+256 793 128 137'), findsNWidgets(2));
  });
}
