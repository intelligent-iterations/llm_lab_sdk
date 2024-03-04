import 'package:equatable/equatable.dart';

class Agent extends Equatable {
  const Agent({
    required this.id,
    required this.name,
    required this.prompt,
    required this.preferedModel,
    required this.projectId,
  });

  final String? id;
  final String? name;
  final String? prompt;
  final LLmModel? preferedModel;
  final String? projectId;

  @override
  List<Object?> get props => [
        id,
        name,
        prompt,
        preferedModel,
        projectId,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'prompt': prompt,
      'preferedModel': preferedModel?.toJson(),
      'projectId': projectId,
    };
  }

  factory Agent.fromJson(Map<String, dynamic> map) {
    return Agent(
      id: map['id'],
      name: map['name'],
      prompt: map['prompt'],
      preferedModel: LLmModel.fromJson(map['preferedModel'] ?? {}),
      projectId: map['projectId'],
    );
  }

  static Map<String, dynamic> exampleJson() {
    return {
      'id': "",
      'name': "",
      'prompt': "",
      'longTermMemoryIds': List<String>.from([]),
      'preferedModel': LLmModel.exampleJson(),
      'projectId': "",
    };
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

  static Agent example() => Agent.fromJson(Agent.exampleJson());

  Agent copyWith({
    String? id,
    String? name,
    String? prompt,
    LLmModel? preferedModel,
    String? projectId,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      preferedModel: preferedModel ?? this.preferedModel,
      projectId: projectId ?? this.projectId,
    );
  }
}

class LLmModel extends Equatable {
  const LLmModel(
      {required this.id, required this.companyName, required this.modelName});

  final String? id;
  final String? companyName;
  final String? modelName;

  @override
  List<Object?> get props => [id, companyName, modelName];

  Map<String, dynamic> toJson() {
    return {'id': id, 'companyName': companyName, 'modelName': modelName};
  }

  factory LLmModel.fromJson(Map<String, dynamic> map) {
    return LLmModel(
        id: map['id'],
        companyName: map['companyName'],
        modelName: map['modelName'] ?? 'gpt-3.5-turbo');
  }

  LLmModel copyWith({String? id, String? companyName, String? modelName}) {
    return LLmModel(
        id: id ?? this.id,
        companyName: companyName ?? this.companyName,
        modelName: modelName ?? this.modelName);
  }

  static Map<String, dynamic> exampleJson() {
    return {'id': "", 'companyName': "", 'modelName': ""};
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

  static LLmModel example() => LLmModel.fromJson(LLmModel.exampleJson());
}
