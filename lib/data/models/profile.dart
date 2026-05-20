class Profile {
  final String id;
  final String organizationId;
  final String email;
  final String? fullName;
  final Map<String, dynamic> notificationPrefs;

  const Profile({
    required this.id,
    required this.organizationId,
    required this.email,
    this.fullName,
    this.notificationPrefs = const {},
  });

  bool get pushEnabled => notificationPrefs['push'] == true;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        email: json['email'] as String? ?? '',
        fullName: json['full_name'] as String?,
        notificationPrefs:
            (json['notification_prefs'] as Map?)?.cast<String, dynamic>() ??
                const {},
      );
}

class Organization {
  final String id;
  final String name;
  final String? subscriptionStatus;

  const Organization({
    required this.id,
    required this.name,
    this.subscriptionStatus,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        subscriptionStatus: json['subscription_status'] as String?,
      );
}
