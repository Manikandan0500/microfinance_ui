String? orgnamevalid(String input) {
  // Allow all characters (alphabets, numbers, special characters, spaces)
  return null;
}

String? orgncodevalid(String input) {
  if (RegExp(r'^[0-9]+$').hasMatch(input)) {
    return null;
  }
  return 'Invalid characters. Use numbers and - only.';
}

String? pincodevalid(String input) {
  if (RegExp(r'^[0-9\-]+$').hasMatch(input)) {
    return null;
  }
  return 'Invalid characters. Use numbers and - only.';
}

String? mobilenumbervalid(String input) {
  if (!RegExp(r'^[\+]?[0-9]+$').hasMatch(input)) {
    return 'Only Numbers and + are accepted';
  }
  
  final digits = input.replaceAll('+', '');
  
  if (RegExp(r'^(\d)\1+$').hasMatch(digits)) {
    return 'Invalid mobile number (repeating digits)';
  }
  
  const seq1 = '01234567890123456789';
  const seq2 = '98765432109876543210';
  if (digits.length >= 4 && (seq1.contains(digits) || seq2.contains(digits))) {
    return 'Invalid mobile number (sequential digits)';
  }
  
  return null;
}

String? emailvalid(String input) {
  if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(input)) {
    return null;
  }
  return 'Invalid email format';
}

