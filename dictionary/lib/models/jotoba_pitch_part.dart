/// Represents a single part (mora) of a pitch accent pattern
class JotobaPitchPart {
  final String part;
  final bool high;

  const JotobaPitchPart({
    required this.part,
    required this.high,
  });

  factory JotobaPitchPart.fromJson(Map<String, dynamic> json) {
    return JotobaPitchPart(
      part: json['part'] ?? '',
      high: json['high'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part': part,
      'high': high,
    };
  }

  @override
  String toString() => '$part(${high ? 'H' : 'L'})';
}