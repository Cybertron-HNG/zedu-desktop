class RolePermission {
  const RolePermission({
    this.id = '',
    required this.role,
    required this.description,
    required this.permissions,
  });

  /// Id of the role on the organisation.
  final String id;

  /// Display name of the role, for example "Administrator".
  final String role;

  final String description;

  /// Keys of the permissions granted to the role.
  final List<String> permissions;
}
