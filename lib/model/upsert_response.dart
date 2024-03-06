import 'package:equatable/equatable.dart';

class UpsertResponse extends Equatable {
  const UpsertResponse({required this.statusCode, required this.warning});

  final String? statusCode;
  final String? warning;

  @override
  List<Object?> get props => [statusCode, warning];

  Map<String, dynamic> toJson() {
    return {'statusCode': statusCode, 'warning': warning};
  }

  factory UpsertResponse.fromJson(Map<String, dynamic> map) {
    return UpsertResponse(
        statusCode: map['statusCode'], warning: map['warning']);
  }

  UpsertResponse copyWith({String? statusCode, String? warning}) {
    return UpsertResponse(
        statusCode: statusCode ?? this.statusCode,
        warning: warning ?? this.warning);
  }

  static Map<String, dynamic> exampleJson() {
    return {'statusCode': "", 'warning': ""};
  }

  bool match(Map map) {
    final model = toJson();
    final keys = model.keys.toList();

    for (final query in map.entries) {
      try {
        final trueValue = model[query.key];
        final exists = trueValue == query.value;
        if (exists) {
          return true;
        }
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  static UpsertResponse example() =>
      UpsertResponse.fromJson(UpsertResponse.exampleJson());
}
