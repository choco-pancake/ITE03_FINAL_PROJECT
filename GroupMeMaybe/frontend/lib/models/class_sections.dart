class ClassSections {
  static const Map<String, List<String>> byYear = {
    '1st Year': [
      '11-ITEM-01',
      '11-ITEM-02',
      '11-ITEN-01',
      '11-ITEN-02',
      '11-ITEN-03',
      '11-ITEW-01',
      '11-ITEW-02',
      '11-ITEW-03',
      '11-CSE-01',
      '11-CSE-02',
    ],
    '2nd Year': [
      '21-ITEM-01',
      '21-ITEM-02',
      '21-ITEN-01',
      '21-ITEN-02',
      '21-ITEN-03',
      '21-ITEW-01',
      '21-ITEW-02',
      '21-ITEW-03',
      '21-ITEW-04',
      '21-CSE-01',
    ],
    '3rd Year': [
      '31-ITE-01',
      '31-ITE-02',
      '31-ITE-03',
      '31-ITE-04',
      '31-ITE-05',
      '31-ITE-06',
      '31-ITE-07',
      '31-ITE-08',
      '31-ITE-09',
      '31-CSE-01',
    ],
    '4th Year': [
      '41-ITE-01',
      '41-ITE-02',
      '41-ITE-03',
      '41-ITE-04',
      '41-ITE-05',
      '41-CSE-01',
    ],
  };

  static String? yearFor(String block) {
    for (final entry in byYear.entries) {
      if (entry.value.contains(block)) return entry.key;
    }
    final legacyYear = RegExp(r'[1-4]').firstMatch(block)?.group(0);
    if (legacyYear == null) return null;
    return byYear.keys.elementAt(int.parse(legacyYear) - 1);
  }
}
