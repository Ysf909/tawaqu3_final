class AppUser {
  final String id;       // users.id (uuid)
  final String fname;
  final String lname;
  final String email;
  final String? privilege;

  AppUser({
    required this.id,
    required this.fname,
    required this.lname,
    required this.email,
    this.privilege,
  });

  String get fullName => '$fname $lname';

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fname: map['fname'] as String,
      lname: map['lname'] as String,
      email: map['email'] as String,
      privilege: map['privilege'] as String?,
    );
  }
}
