class Validators {
  const Validators._();

  static String? requiredEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!email.contains('@')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? requiredPassword(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Password is required';
    }
    return null;
  }
}
