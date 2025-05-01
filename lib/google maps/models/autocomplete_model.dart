class AutocompleteModel {
  final String? description;
  final List<MatchedSubstrings> matchedSubstrings;
  final String? placeId;
  final String? reference;
  final StructuredFormatting? structuredFormatting;
  final List<Terms> terms;
  final List<dynamic> types;

  AutocompleteModel({
    this.description,
    this.matchedSubstrings = const [],
    this.placeId,
    this.reference,
    this.structuredFormatting,
    this.terms = const [],
    this.types = const [],
  });

  factory AutocompleteModel.fromJson(Map<String, dynamic> json) => AutocompleteModel(
    description: json['description'],
    matchedSubstrings: json['matched_substrings'] != null
        ? List<MatchedSubstrings>.from(
        json['matched_substrings'].map((e) => MatchedSubstrings.fromJson(e)))
        : [],
    placeId: json['place_id'],
    reference: json['reference'],
    structuredFormatting: json['structured_formatting'] != null
        ? StructuredFormatting.fromJson(json['structured_formatting'])
        : null,
    terms: json['terms'] != null
        ? List<Terms>.from(json['terms'].map((e) => Terms.fromJson(e)))
        : [],
    types: json['types'] != null ? List<dynamic>.from(json['types']) : [],
  );

  Map<String, dynamic> toJson() => {
    'description': description,
    'matched_substrings': matchedSubstrings.map((e) => e.toJson()).toList(),
    'place_id': placeId,
    'reference': reference,
    'structured_formatting': structuredFormatting?.toJson(),
    'terms': terms.map((e) => e.toJson()).toList(),
    'types': types,
  };
}

class Terms {
  final int offset;
  final String value;

  Terms({required this.offset, required this.value});

  factory Terms.fromJson(Map<String, dynamic> json) => Terms(
    offset: json['offset'],
    value: json['value'],
  );

  Map<String, dynamic> toJson() => {'offset': offset, 'value': value};
}

class StructuredFormatting {
  final String? mainText;
  final List<MainTextMatchedSubstrings> mainTextMatchedSubstrings;
  final String? secondaryText;

  StructuredFormatting({
    this.mainText,
    this.mainTextMatchedSubstrings = const [],
    this.secondaryText,
  });

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) => StructuredFormatting(
    mainText: json['main_text'],
    mainTextMatchedSubstrings: json['main_text_matched_substrings'] != null
        ? List<MainTextMatchedSubstrings>.from(
        json['main_text_matched_substrings']
            .map((e) => MainTextMatchedSubstrings.fromJson(e)))
        : [],
    secondaryText: json['secondary_text'],
  );

  Map<String, dynamic> toJson() => {
    'main_text': mainText,
    'main_text_matched_substrings': mainTextMatchedSubstrings.map((e) => e.toJson()).toList(),
    'secondary_text': secondaryText,
  };
}

class MainTextMatchedSubstrings {
  final int length;
  final int offset;

  MainTextMatchedSubstrings({required this.length, required this.offset});

  factory MainTextMatchedSubstrings.fromJson(Map<String, dynamic> json) => MainTextMatchedSubstrings(
    length: json['length'],
    offset: json['offset'],
  );

  Map<String, dynamic> toJson() => {'length': length, 'offset': offset};
}

class MatchedSubstrings {
  final int length;
  final int offset;

  MatchedSubstrings({required this.length, required this.offset});

  factory MatchedSubstrings.fromJson(Map<String, dynamic> json) => MatchedSubstrings(
    length: json['length'],
    offset: json['offset'],
  );

  Map<String, dynamic> toJson() => {'length': length, 'offset': offset};
}
