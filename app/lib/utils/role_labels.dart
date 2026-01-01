/// UI-only role label mapping.
///
/// Important: this does NOT change any underlying auth roles or security logic.
/// Roles remain `freeUser` / `paidUser` etc. This is just nicer wording for users.
String roleLabel(String role) {
  final r = role.trim();
  switch (r) {
    case 'freeuser':
    case 'freeUser':
      return 'Learner';
    case 'paiduser':
    case 'paidUser':
    case 'premium':
      return 'Premium';
    case 'admin':
      return 'Admin';
    case 'editor':
      return 'Editor';
    default:
      // Generic fallback: handle camelCase / snake_case / lowercase
      final normalized = r.replaceAll('_', ' ').trim();
      final spaced = normalized.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (m) => '${m[1]} ${m[2]}',
      );
      return spaced
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .map((p) => p[0].toUpperCase() + p.substring(1))
          .join(' ');
  }
}


