// The fake centre's numbers come from one record per farmer, so the farmers
// list (G06), farmer detail (G07) and payment sheet (G09/G10) always agree.
import 'package:farm_tap/sectors/cattle/collection_centre/data/fake/fake_centre_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_deps.dart';

void main() {
  test('period litres, owed, statement and payment line agree', () async {
    final repo = FakeCentreRepository(FixedClock());
    final farmers = (await repo.farmers()).data!;
    final lines = (await repo.payments()).data!.lines;
    final robert = farmers.firstWhere((f) => f.name == 'Muhwezi Robert');
    expect(robert.periodLitres, 512);
    for (final f in farmers) {
      final st = (await repo.statement(f.id)).data!;
      expect(st.litres, f.periodLitres, reason: f.name);
      expect(st.net, f.owed, reason: f.name);
      for (final line in lines.where((l) => l.farmer.id == f.id)) {
        expect(line.litres, f.periodLitres, reason: f.name);
        expect(line.net, f.owed, reason: f.name);
      }
    }
  });
}
