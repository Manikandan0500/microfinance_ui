import '../models/password_policy_model.dart';

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> unmetRequirements;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.unmetRequirements,
  });
}

class PasswordValidator {
  static List<String> getPolicyRequirements(PasswordPolicy policy) {
    List<String> reqs = [];
    reqs.add('At least ${policy.minLength} characters');
    if (policy.requireUppercase) reqs.add('At least one uppercase letter');
    if (policy.requireLowercase) reqs.add('At least one lowercase letter');
    if (policy.requireNumber) reqs.add('At least one number');
    if (policy.requireSpecialChar) reqs.add('At least one special character');
    return reqs;
  }

  static bool requirementMet(String password, String req, PasswordPolicy policy) {
    if (req.startsWith('At least ') && req.endsWith(' characters')) {
      return password.length >= policy.minLength;
    }
    if (req == 'At least one uppercase letter') {
      return password.contains(RegExp(r'[A-Z]'));
    }
    if (req == 'At least one lowercase letter') {
      return password.contains(RegExp(r'[a-z]'));
    }
    if (req == 'At least one number') {
      return password.contains(RegExp(r'[0-9]'));
    }
    if (req == 'At least one special character') {
      return password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    }
    return false;
  }

  static ValidationResult validate(String password, PasswordPolicy policy) {
    List<String> unmet = [];
    if (password.length < policy.minLength) {
      unmet.add('Minimum length not met');
    }
    if (policy.requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      unmet.add('Uppercase letter missing');
    }
    if (policy.requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      unmet.add('Lowercase letter missing');
    }
    if (policy.requireNumber && !password.contains(RegExp(r'[0-9]'))) {
      unmet.add('Number missing');
    }
    return ValidationResult(
      isValid: unmet.isEmpty,
      errorMessage: unmet.isEmpty ? null : unmet.join(', '),
      unmetRequirements: unmet,
    );
  }
}
