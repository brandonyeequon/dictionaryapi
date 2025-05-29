class MetaData {
  final int status;

  MetaData({
    required this.status,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      status: json['status'] ?? 200,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
    };
  }
}