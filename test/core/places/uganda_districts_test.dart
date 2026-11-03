import 'package:farm_tap/core/places/uganda_districts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every district once, Kampala and the newer districts included', () {
    expect(ugandaDistricts.toSet(), hasLength(ugandaDistricts.length));
    expect(ugandaDistricts, containsAll(['Kampala', 'Mbarara', 'Kazo', 'Rwampara', 'Terego', 'Kalaki', 'Obongi']));
    expect(ugandaDistricts.length, greaterThanOrEqualTo(135));
  });

  test('a place name from the phone finds its district', () {
    expect(matchDistrict(['Mbarara District']), 'Mbarara');
    expect(matchDistrict([null, 'Western Region', 'Kiruhura']), 'Kiruhura');
    expect(matchDistrict(['Mbarara City']), 'Mbarara');
    expect(matchDistrict(['Nairobi']), isNull);
  });
}
