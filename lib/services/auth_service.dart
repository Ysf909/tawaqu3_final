// Stubbed auth service (replace with Firebase later)
class AuthService {
  String? _userId;

  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _userId = 'demoUser';
    return true;
  }

  Future<bool> signUp(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _userId = 'demoUser';
    return true;
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _userId = null;
  }

  bool get isLoggedIn => _userId != null;
}

