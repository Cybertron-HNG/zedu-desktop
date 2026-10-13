class RolePermission {
  const RolePermission({
    required this.role,
    required this.description,
    required this.permissions,
  });

  final String role;
  final String description;
  final List<String> permissions;
}
