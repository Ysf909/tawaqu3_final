class SignupModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  const SignupModel({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.password = '',
  });

  SignupModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
  }) {
    return SignupModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}
