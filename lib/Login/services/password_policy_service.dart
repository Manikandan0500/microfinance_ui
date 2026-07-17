import '../models/password_policy_model.dart';

class PasswordPolicyService {
  static Future<PasswordPolicy> getPolicyByOrgCode() async {
    return PasswordPolicy(
      minLength: 6,
      maxLength: 12,
      requireUppercase: true,
      requireLowercase: true,
      requireNumber: true,
      requireSpecialChar: false,
    );
  }
}
