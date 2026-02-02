// No imports needed for now

enum AgencyRole { admin, member }

class TeamMemberModel {
  final String userId;
  final String userName;
  final AgencyRole role;
  final DateTime joinedAt;

  TeamMemberModel({
    required this.userId,
    required this.userName,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'role': role.name,
    'created_at': joinedAt.toIso8601String(),
  };

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) =>
      TeamMemberModel(
        userId: json['user_id'] ?? json['userId'],
        userName: json['user_name'] ?? json['userName'] ?? 'Unknown Member',
        role: AgencyRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => AgencyRole.member,
        ),
        joinedAt: DateTime.parse(json['created_at'] ?? json['joinedAt']),
      );
}

class AgencyModel {
  final String id;
  final String name;
  final String ownerId;
  final List<TeamMemberModel> members;
  final double walletBalance;
  final DateTime createdAt;

  AgencyModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    this.walletBalance = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner_id': ownerId,
    'members': members.map((e) => e.toJson()).toList(),
    'wallet_balance': walletBalance,
    'created_at': createdAt.toIso8601String(),
  };

  factory AgencyModel.fromJson(Map<String, dynamic> json) => AgencyModel(
    id: json['id'],
    name: json['name'],
    ownerId: json['owner_id'] ?? json['ownerId'],
    members: (json['agency_members'] ?? json['members'] ?? [])
        .map<TeamMemberModel>((e) => TeamMemberModel.fromJson(e))
        .toList(),
    walletBalance:
        ((json['wallet_balance'] ?? json['walletBalance'] ?? 0.0) as num)
            .toDouble(),
    createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
  );

  AgencyModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<TeamMemberModel>? members,
    double? walletBalance,
    DateTime? createdAt,
  }) {
    return AgencyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      walletBalance: walletBalance ?? this.walletBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
