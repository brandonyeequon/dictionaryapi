class Attribution {
  final bool jmdict;
  final bool jmnedict;
  final dynamic dbpedia;

  Attribution({
    required this.jmdict,
    required this.jmnedict,
    this.dbpedia,
  });

  factory Attribution.fromJson(Map<String, dynamic> json) {
    return Attribution(
      jmdict: json['jmdict'] ?? false,
      jmnedict: json['jmnedict'] ?? false,
      dbpedia: json['dbpedia'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jmdict': jmdict,
      'jmnedict': jmnedict,
      'dbpedia': dbpedia,
    };
  }
}