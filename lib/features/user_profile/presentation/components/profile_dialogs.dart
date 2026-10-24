import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Shows a confirmation dialog and calls [onConfirm] if user agrees.
Future<void> showProfileConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function() onConfirm,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(message, style: context.textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: confirmLabel,
          expand: false,
          height: 40,
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? const Color(0xFFEF4444) : null,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  if (confirmed == true) await onConfirm();
}

/// Dialog for editing account information.
Future<void> showEditAccountDialog(
  BuildContext context,
  ProfileAccount account,
  ValueChanged<ProfileAccount> onSave,
) async {
  final nameCtrl = TextEditingController(text: account.name);
  final emailCtrl = TextEditingController(text: account.email);
  final timezoneCtrl = TextEditingController(text: account.timezone);
  final formKey = GlobalKey<FormState>();

  await _showDialogOwningControllers(
    context,
    controllers: [nameCtrl, emailCtrl, timezoneCtrl],
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Edit Account',
        style: ctx.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Name',
                controller: nameCtrl,
                hint: 'Enter your full name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email Address',
                controller: emailCtrl,
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Timezone',
                controller: timezoneCtrl,
                hint: 'e.g. Africa/Lagos',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save changes',
          expand: false,
          height: 40,
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              onSave(
                account.copyWith(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  timezone: timezoneCtrl.text.trim(),
                ),
              );
              Navigator.pop(ctx);
            }
          },
        ),
      ],
    ),
  );
}

/// Dialog for changing password.
Future<void> showChangePasswordDialog(
  BuildContext context,
  Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onSave,
) async {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await _showDialogOwningControllers(
    context,
    controllers: [currentCtrl, newCtrl, confirmCtrl],
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Change password',
        style: ctx.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Current Password',
                controller: currentCtrl,
                hint: 'Enter current password',
                isPassword: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'New Password',
                controller: newCtrl,
                hint: 'Enter new password',
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirm New Password',
                controller: confirmCtrl,
                hint: 'Re-enter new password',
                isPassword: true,
                validator: (v) =>
                    v != newCtrl.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Update Password',
          expand: false,
          height: 40,
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(ctx);
              await onSave(
                currentPassword: currentCtrl.text,
                newPassword: newCtrl.text,
              );
            }
          },
        ),
      ],
    ),
  );
}

/// Dialog for editing organization information.
Future<void> showEditOrganizationDialog(
  BuildContext context,
  OrganizationProfile organization,
  ValueChanged<OrganizationProfile> onSave,
) async {
  final nameCtrl = TextEditingController(text: organization.name);
  final businessCtrl = TextEditingController(
    text: organization.natureOfBusiness,
  );
  final countryCtrl = TextEditingController(text: organization.country);
  final formKey = GlobalKey<FormState>();

  await _showDialogOwningControllers(
    context,
    controllers: [nameCtrl, businessCtrl, countryCtrl],
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Edit Organization',
        style: ctx.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Organization Name',
                controller: nameCtrl,
                hint: 'Enter organization name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nature of Business',
                controller: businessCtrl,
                hint: 'e.g. Design agency',
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Country',
                controller: countryCtrl,
                hint: 'e.g. Nigeria',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save changes',
          expand: false,
          height: 40,
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              onSave(
                organization.copyWith(
                  name: nameCtrl.text.trim(),
                  natureOfBusiness: businessCtrl.text.trim(),
                  country: countryCtrl.text.trim(),
                ),
              );
              Navigator.pop(ctx);
            }
          },
        ),
      ],
    ),
  );
}

/// Dialog for inviting a team member.
Future<void> showInviteMemberDialog(
  BuildContext context,
  Future<void> Function({required String email, required String role}) onInvite,
) async {
  final emailCtrl = TextEditingController();
  String role = 'User';
  final formKey = GlobalKey<FormState>();

  await _showDialogOwningControllers(
    context,
    controllers: [emailCtrl],
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Invite Team Member',
          style: ctx.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Email Address',
                  controller: emailCtrl,
                  hint: 'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ProfileFieldLabel('Role'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Administrator',
                      child: Text('Administrator'),
                    ),
                    DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'User', child: Text('User')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v ?? 'User'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Send Invite',
            expand: false,
            height: 40,
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx);
                await onInvite(email: emailCtrl.text.trim(), role: role);
              }
            },
          ),
        ],
      ),
    ),
  );
}

/// Dialog for editing a team member's role.
Future<void> showEditMemberDialog(
  BuildContext context,
  TeamMember member,
  ValueChanged<TeamMember> onUpdate,
) async {
  String role = member.role;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Edit Team Member',
          style: ctx.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.email,
                style: ctx.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ProfileFieldLabel('Role'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Administrator',
                    child: Text('Administrator'),
                  ),
                  DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'User', child: Text('User')),
                ],
                onChanged: (v) => setDialogState(() => role = v ?? member.role),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Save changes',
            expand: false,
            height: 40,
            onPressed: () {
              onUpdate(member.copyWith(role: role));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );
}

/// Shows a dialog whose [controllers] are disposed when the dialog route is
/// removed, i.e. after its exit animation. Disposing right after
/// `await showDialog` is too early: that future completes on pop, while the
/// text fields are still rebuilt by the close animation.
Future<void> _showDialogOwningControllers(
  BuildContext context, {
  required List<TextEditingController> controllers,
  required WidgetBuilder builder,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) =>
        _ControllerOwner(controllers: controllers, child: builder(ctx)),
  );
}

class _ControllerOwner extends StatefulWidget {
  const _ControllerOwner({required this.controllers, required this.child});

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<_ControllerOwner> createState() => _ControllerOwnerState();
}

class _ControllerOwnerState extends State<_ControllerOwner> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
