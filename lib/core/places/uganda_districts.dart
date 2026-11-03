/// Every district of Uganda (plus Kampala), A to Z, for the district picker.
/// A district that is missing can still be typed in.
const List<String> ugandaDistricts = [
  // Central
  'Buikwe', 'Bukomansimbi', 'Butambala', 'Buvuma', 'Gomba', 'Kalangala', 'Kalungu', 'Kampala', 'Kassanda',
  'Kayunga', 'Kiboga', 'Kyankwanzi', 'Kyotera', 'Luweero', 'Lwengo', 'Lyantonde', 'Masaka', 'Mityana', 'Mpigi',
  'Mubende', 'Mukono', 'Nakaseke', 'Nakasongola', 'Rakai', 'Sembabule', 'Wakiso',
  // Eastern
  'Amuria', 'Budaka', 'Bududa', 'Bugiri', 'Bugweri', 'Bukedea', 'Bukwo', 'Bulambuli', 'Busia', 'Butaleja',
  'Butebo', 'Buyende', 'Iganga', 'Jinja', 'Kaberamaido', 'Kalaki', 'Kaliro', 'Kamuli', 'Kapchorwa',
  'Kapelebyong', 'Katakwi', 'Kibuku', 'Kumi', 'Kween', 'Luuka', 'Manafwa', 'Mayuge', 'Mbale', 'Namayingo',
  'Namisindwa', 'Namutumba', 'Ngora', 'Pallisa', 'Serere', 'Sironko', 'Soroti', 'Tororo',
  // Northern
  'Abim', 'Adjumani', 'Agago', 'Alebtong', 'Amolatar', 'Amudat', 'Amuru', 'Apac', 'Arua', 'Dokolo', 'Gulu',
  'Kaabong', 'Karenga', 'Kitgum', 'Koboko', 'Kole', 'Kotido', 'Kwania', 'Lamwo', 'Lira', 'Madi-Okollo',
  'Maracha', 'Moroto', 'Moyo', 'Nabilatuk', 'Nakapiripirit', 'Napak', 'Nebbi', 'Nwoya', 'Obongi', 'Omoro',
  'Otuke', 'Oyam', 'Pader', 'Pakwach', 'Terego', 'Yumbe', 'Zombo',
  // Western
  'Buhweju', 'Buliisa', 'Bundibugyo', 'Bunyangabu', 'Bushenyi', 'Hoima', 'Ibanda', 'Isingiro', 'Kabale',
  'Kabarole', 'Kagadi', 'Kakumiro', 'Kamwenge', 'Kanungu', 'Kasese', 'Kazo', 'Kibaale', 'Kikuube', 'Kiruhura',
  'Kiryandongo', 'Kisoro', 'Kitagwenda', 'Kyegegwa', 'Kyenjojo', 'Masindi', 'Mbarara', 'Mitooma', 'Ntoroko',
  'Ntungamo', 'Rubanda', 'Rubirizi', 'Rukiga', 'Rukungiri', 'Rwampara', 'Sheema',
];

/// The list sorted A to Z.
final List<String> ugandaDistrictsSorted = [...ugandaDistricts]..sort();

/// The district a place name (from the phone's location) belongs to, e.g.
/// "Mbarara District" or "Mbarara City" -> "Mbarara". Null when none match.
String? matchDistrict(Iterable<String?> names) {
  for (final raw in names) {
    final n = (raw ?? '').toLowerCase().replaceAll(RegExp(r'\b(district|city|municipality|county)\b'), '').trim();
    if (n.isEmpty) continue;
    for (final d in ugandaDistricts) {
      if (n == d.toLowerCase()) return d;
    }
    for (final d in ugandaDistricts) {
      if (n.contains(d.toLowerCase())) return d;
    }
  }
  return null;
}
