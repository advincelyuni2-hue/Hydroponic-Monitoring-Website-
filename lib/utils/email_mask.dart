/// joreluri.8142004@gmail.com -> j***************@gmail.com
String maskEmail(String email) {
  final value = email.trim();
  final at = value.indexOf('@');
  if (at <= 0) return value; // not an email, show as-is

  final name = value.substring(0, at);
  final domain = value.substring(at);

  if (name.length == 1) return '*$domain';
  return '${name[0]}${'*' * (name.length - 1)}$domain';
}