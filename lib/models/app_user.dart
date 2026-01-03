class AppUser {
  final String id; // users.id (uuid)
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
    required num profit,
  });

  String get fullName => '$fname $lname';

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id: (m['id'] ?? '').toString(),
    fname: (m['fname'] ?? '').toString(),
    lname: (m['lname'] ?? '').toString(),
    email: (m['email'] ?? '').toString(),
    profit: (m['profit'] as num?) ?? 0,
  );
}
