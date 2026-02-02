import 'milestone_model.dart';

enum ProjectStatus { open, inProgress, completed, cancelled }

class ProjectModel {
  final String id;
  final String clientId;
  String? developerId;
  final String title;
  final String description;
  final List<String> requiredSkills;
  final String timeline;
  final double totalBudget;
  double escrowBalance;
  List<MilestoneModel> milestones;
  ProjectStatus status;
  double? developerRating;
  double? clientRating;
  final String? category;
  final DateTime createdAt;

  String get duration => timeline;

  ProjectModel({
    required this.id,
    required this.clientId,
    this.developerId,
    required this.title,
    required this.description,
    required this.requiredSkills,
    required this.timeline,
    required this.totalBudget,
    this.escrowBalance = 0.0,
    required this.milestones,
    this.status = ProjectStatus.open,
    this.developerRating,
    this.clientRating,
    this.category,
    required this.createdAt,
  });

  ProjectModel copyWith({
    String? id,
    String? clientId,
    String? developerId,
    String? title,
    String? description,
    List<String>? requiredSkills,
    String? timeline,
    double? totalBudget,
    double? escrowBalance,
    List<MilestoneModel>? milestones,
    ProjectStatus? status,
    double? developerRating,
    double? clientRating,
    String? category,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      developerId: developerId ?? this.developerId,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      timeline: timeline ?? this.timeline,
      totalBudget: totalBudget ?? this.totalBudget,
      escrowBalance: escrowBalance ?? this.escrowBalance,
      milestones: milestones ?? this.milestones,
      status: status ?? this.status,
      developerRating: developerRating ?? this.developerRating,
      clientRating: clientRating ?? this.clientRating,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'developer_id': developerId,
    'title': title,
    'description': description,
    'skills_required': requiredSkills,
    'timeline': timeline,
    'total_budget': totalBudget,
    'escrow_balance': escrowBalance,
    'milestones': milestones.map((e) => e.toJson()).toList(),
    'status': status.name,
    'developer_rating': developerRating,
    'client_rating': clientRating,
    'category': category,
    'created_at': createdAt.toIso8601String(),
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProjectModel(
        id: json['id']?.toString() ?? '',
        clientId: (json['client_id'] ?? json['clientId'] ?? '').toString(),
        developerId:
            json['developer_id']?.toString() ?? json['developerId']?.toString(),
        title: json['title'] ?? 'Untitled Project',
        description: json['description'] ?? 'No description provided.',
        requiredSkills: json['skills_required'] != null
            ? List<String>.from(json['skills_required'])
            : (json['requiredSkills'] != null
                  ? List<String>.from(json['requiredSkills'])
                  : []),
        timeline: json['timeline'] ?? '',
        totalBudget:
            double.tryParse(
              (json['total_budget'] ?? json['totalBudget'] ?? 0.0).toString(),
            ) ??
            0.0,
        escrowBalance:
            double.tryParse(
              (json['escrow_balance'] ?? json['escrowBalance'] ?? 0.0)
                  .toString(),
            ) ??
            0.0,
        milestones: json['milestones'] != null
            ? (json['milestones'] as List)
                  .map((e) => MilestoneModel.fromJson(e))
                  .toList()
            : [],
        status: ProjectStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ProjectStatus.open,
        ),
        developerRating:
            double.tryParse(
              (json['developer_rating'] ?? json['developerRating'] ?? 0.0)
                  .toString(),
            ) ??
            0.0,
        clientRating:
            double.tryParse(
              (json['client_rating'] ?? json['clientRating'] ?? 0.0).toString(),
            ) ??
            0.0,
        category: json['category'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : (json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : DateTime.now()),
      );
    } catch (e, stack) {
      print('FATAL ERROR parsing ProjectModel: $e');
      print('JSON data: $json');
      print('Stack trace: $stack');
      rethrow;
    }
  }
}
