import 'meta_data.dart';
import 'word_entry.dart';

class JishoResponse {
  final MetaData meta;
  final List<WordEntry> data;

  JishoResponse({
    required this.meta,
    required this.data,
  });

  factory JishoResponse.fromJson(Map<String, dynamic> json) {
    return JishoResponse(
      meta: MetaData.fromJson(json['meta'] ?? {}),
      data: (json['data'] as List<dynamic>? ?? [])
          .map((entry) => WordEntry.fromJson(entry))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meta': meta.toJson(),
      'data': data.map((entry) => entry.toJson()).toList(),
    };
  }

  bool get isSuccessful => meta.status == 200;
  bool get hasResults => data.isNotEmpty;
  int get resultCount => data.length;
}