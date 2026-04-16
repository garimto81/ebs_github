enum PermissionAction { read, write, delete_ }

class Permission {
  static const int read = 1;
  static const int write = 2;
  static const int delete_ = 4;

  Permission._();

  static bool hasPermission(int? perm, PermissionAction action) {
    if (perm == null) return false;
    final mask = switch (action) {
      PermissionAction.read => read,
      PermissionAction.write => write,
      PermissionAction.delete_ => delete_,
    };
    return (perm & mask) == mask;
  }

  static bool checkResource(
    Map<String, int>? perms,
    String resource,
    PermissionAction action,
  ) {
    if (perms == null) return false;
    return hasPermission(perms[resource], action);
  }
}
