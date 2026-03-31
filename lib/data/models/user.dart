class User {
  final String id;
  final String username;
  final String? email;
  final String firstName;
  final String lastName;
  final String? schoolName;
  final String? country;
  final String languagePreference;
  final bool emailVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.firstName,
    required this.lastName,
    this.schoolName,
    this.country,
    required this.languagePreference,
    this.emailVerified = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      schoolName: json['school_name'],
      country: json['country'],
      languagePreference: json['language_preference'] ?? 'en',
      emailVerified: json['email_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'school_name': schoolName,
      'country': country,
      'language_preference': languagePreference,
      'email_verified': emailVerified,
    };
  }

  String get fullName => '$firstName $lastName';
}
