class ReferenceItem {
  final String id;
  final int number;
  final String label;
  final String arabic;
  final int verseCount;
  final String subject;
  final Map<String, dynamic> raw;

  const ReferenceItem({
    required this.id,
    required this.number,
    required this.label,
    required this.arabic,
    required this.verseCount,
    required this.subject,
    required this.raw,
  });

  String get displayLabel {
    final parts = <String>[];
    if (number > 0) parts.add('$number');
    if (arabic.trim().isNotEmpty) parts.add(arabic.trim());
    if (label.trim().isNotEmpty && label.trim() != arabic.trim()) parts.add(label.trim());
    return parts.isEmpty ? id : parts.join(' — ');
  }

  factory ReferenceItem.fromJson(Map<String, dynamic> json, {int fallbackNumber = 0}) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
      }
      return '';
    }

    int pickInt(List<String> keys, [int fallback = 0]) {
      for (final key in keys) {
        final value = json[key];
        final parsed = int.tryParse((value ?? '').toString());
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    final number = pickInt(['number', 'num', 'surahNumber', 'hizbNumber', 'juzNumber', 'lessonNumber'], fallbackNumber);
    final id = pick(['id', 'key', 'lessonId', 'code']);
    return ReferenceItem(
      id: id.isEmpty ? (number > 0 ? '$number' : pick(['name', 'label'])) : id,
      number: number,
      label: pick(['label', 'name', 'latin', 'french', 'transliteration', 'title']),
      arabic: pick(['arabic', 'arabicName', 'nameArabic', 'arabicLabel']),
      verseCount: pickInt(['verseCount', 'verses', 'ayahCount', 'ayatCount']),
      subject: pick(['subject', 'matiere', 'category']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

class ReferenceCatalog {
  final List<ReferenceItem> surahs;
  final List<ReferenceItem> hizbs;
  final List<ReferenceItem> juzs;
  final List<ReferenceItem> lessons;
  final List<String> incidentTypes;
  final bool receivedFromPrincipal;
  final Map<String, dynamic> raw;

  const ReferenceCatalog({
    required this.surahs,
    required this.hizbs,
    required this.juzs,
    required this.lessons,
    required this.incidentTypes,
    required this.receivedFromPrincipal,
    required this.raw,
  });

  static const empty = ReferenceCatalog(
    surahs: [],
    hizbs: [],
    juzs: [],
    lessons: [],
    incidentTypes: [],
    receivedFromPrincipal: false,
    raw: {},
  );

  static dynamic _findValue(dynamic node, Set<String> aliases, [int depth = 0]) {
    if (depth > 5) return null;
    if (node is Map) {
      final map = Map<String, dynamic>.from(node);
      for (final entry in map.entries) {
        if (aliases.contains(entry.key.toLowerCase())) return entry.value;
      }
      const preferredContainers = {
        'referencedata', 'references', 'catalogs', 'catalogue', 'quran', 'quranreference',
        'qurancatalog', 'schooldata', 'metadata', 'lists', 'listes',
      };
      for (final entry in map.entries) {
        if (preferredContainers.contains(entry.key.toLowerCase())) {
          final value = _findValue(entry.value, aliases, depth + 1);
          if (value != null) return value;
        }
      }
      for (final value in map.values) {
        if (value is Map) {
          final found = _findValue(value, aliases, depth + 1);
          if (found != null) return found;
        }
      }
    }
    return null;
  }

  static List<ReferenceItem> _items(dynamic value) {
    if (value is! List) return const [];
    final result = <ReferenceItem>[];
    for (var i = 0; i < value.length; i++) {
      final raw = value[i];
      if (raw is Map) {
        result.add(ReferenceItem.fromJson(Map<String, dynamic>.from(raw), fallbackNumber: i + 1));
      } else if (raw != null && raw.toString().trim().isNotEmpty) {
        result.add(ReferenceItem(
          id: '${i + 1}', number: i + 1, label: raw.toString().trim(), arabic: '', verseCount: 0, subject: '', raw: {'name': raw.toString()},
        ));
      }
    }
    result.sort((a, b) {
      if (a.number == 0 && b.number == 0) return a.label.compareTo(b.label);
      if (a.number == 0) return 1;
      if (b.number == 0) return -1;
      return a.number.compareTo(b.number);
    });
    return result;
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        return (m['label'] ?? m['name'] ?? m['nature'] ?? m['type'] ?? '').toString().trim();
      }
      return e?.toString().trim() ?? '';
    }).where((e) => e.isNotEmpty).toSet().toList();
  }

  factory ReferenceCatalog.fromRoot(Map<String, dynamic> root) {
    final surahsRaw = _findValue(root, {'surahs', 'surah', 'sourates', 'quransurahs', 'surahitems'});
    final hizbsRaw = _findValue(root, {'hizbs', 'ahzab', 'quranhizbs', 'hizbitems'});
    final juzsRaw = _findValue(root, {'juzs', 'ajza', 'quranjuzs', 'juzitems'});
    final lessonsRaw = _findValue(root, {'lessons', 'schoollessons', 'lecons', 'lessonitems'});
    final incidentsRaw = _findValue(root, {'incidenttypes', 'incidentnatures', 'natureincidents', 'disciplinetypes'});

    final surahs = _items(surahsRaw);
    final hizbs = _items(hizbsRaw);
    final juzs = _items(juzsRaw);
    final lessons = _items(lessonsRaw);
    final incidentTypes = _strings(incidentsRaw);
    final received = surahs.isNotEmpty || hizbs.isNotEmpty || juzs.isNotEmpty || lessons.isNotEmpty || incidentTypes.isNotEmpty;

    return ReferenceCatalog(
      surahs: surahs,
      hizbs: hizbs,
      juzs: juzs,
      lessons: lessons,
      incidentTypes: incidentTypes,
      receivedFromPrincipal: received,
      raw: root,
    );
  }

  List<ReferenceItem> lessonsFor({String? subject}) {
    if (subject == null || subject.trim().isEmpty) return lessons;
    final key = subject.trim().toLowerCase();
    final filtered = lessons.where((e) => e.subject.toLowerCase() == key).toList();
    return filtered.isEmpty ? lessons : filtered;
  }
}
