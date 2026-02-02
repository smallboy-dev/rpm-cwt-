import 'kyc_model.dart';

enum UserRole { developer, client, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? bio;
  final List<String>? skills;
  final String? githubLink;
  final String? industry;
  final double walletBalance;
  final bool isVerified;
  final List<String> verifiedSkills;
  final KYCStatus kycStatus;

  final String? agencyId;
  final String? agencyRole;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.bio,
    this.skills,
    this.githubLink,
    this.industry,
    this.walletBalance = 0.0,
    this.isVerified = false,
    this.verifiedSkills = const [],
    this.kycStatus = KYCStatus.pending,
    this.agencyId,
    this.agencyRole,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? bio,
    List<String>? skills,
    String? githubLink,
    String? industry,
    double? walletBalance,
    bool? isVerified,
    List<String>? verifiedSkills,
    KYCStatus? kycStatus,
    String? agencyId,
    String? agencyRole,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      githubLink: githubLink ?? this.githubLink,
      industry: industry ?? this.industry,
      walletBalance: walletBalance ?? this.walletBalance,
      isVerified: isVerified ?? this.isVerified,
      verifiedSkills: verifiedSkills ?? this.verifiedSkills,
      kycStatus: kycStatus ?? this.kycStatus,
      agencyId: agencyId ?? this.agencyId,
      agencyRole: agencyRole ?? this.agencyRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'bio': bio,
      'skills': skills,
      'github_link': githubLink,
      'industry': industry,
      'wallet_balance': walletBalance,
      'is_verified': isVerified,
      'verified_skills': verifiedSkills,
      'kyc_status': kycStatus.name,
      'agency_id': agencyId,
      'agency_role': agencyRole,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Anonymous',
        email: json['email'] ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == (json['role'] ?? 'client'),
          orElse: () => UserRole.client,
        ),
        bio: json['bio'],
        skills: json['skills'] != null
            ? List<String>.from(json['skills'])
            : null,
        githubLink: json['github_link'] ?? json['githubLink'],
        industry: json['industry'],
        walletBalance:
            ((json['wallet_balance'] ?? json['walletBalance'] ?? 0.0) as num)
                .toDouble(),
        isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
        verifiedSkills: json['verified_skills'] != null
            ? List<String>.from(json['verified_skills'])
            : (json['verifiedSkills'] != null
                  ? List<String>.from(json['verifiedSkills'])
                  : const []),
        kycStatus: json['kyc_status'] != null
            ? KYCStatus.values.firstWhere(
                (e) => e.name == json['kyc_status'],
                orElse: () => KYCStatus.pending,
              )
            : KYCStatus.pending,
        agencyId: json['agency_id'] ?? json['agencyId'],
        agencyRole: json['agency_role'] ?? json['agencyRole'],
      );
    } catch (e, stack) {
      print('UserModel.fromJson Error: $e');
      print('JSON data: $json');
      print('Stacktrace: $stack');
      rethrow;
    }
  }
}
