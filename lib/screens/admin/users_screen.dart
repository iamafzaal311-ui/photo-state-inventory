import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _users = AuthService.getAllUsers());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Management', style: Theme.of(context).textTheme.headlineLarge),
                    Text('Manage staff accounts and access', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
                const Spacer(),
                _GradBtn(
                  icon: Icons.person_add,
                  label: 'Add User',
                  gradient: AppColors.primaryGradient,
                  onTap: () => _showCreateDialog(context),
                ),
              ],
            ).animate().fadeIn().slideY(begin: -0.1),
            const SizedBox(height: 32),
            // Stats
            Row(
              children: [
                _UserStat(label: 'Total Users', value: _users.length.toString(), color: AppColors.primaryLight),
                const SizedBox(width: 16),
                _UserStat(label: 'Active', value: _users.where((u) => u.isActive).length.toString(), color: AppColors.accentGreen),
                const SizedBox(width: 16),
                _UserStat(label: 'Admins', value: _users.where((u) => u.role == 'admin').length.toString(), color: AppColors.accentOrange),
                const SizedBox(width: 16),
                _UserStat(label: 'Staff', value: _users.where((u) => u.role == 'user').length.toString(), color: AppColors.accent),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            // My Account card
            Builder(builder: (context) {
              final currentUser = ref.watch(authProvider).currentUser;
              if (currentUser == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.accent.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        currentUser.username[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(currentUser.username,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Admin', style: TextStyle(color: AppColors.accentOrange, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        const Text('Logged in as — My Account', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.lock_reset, size: 16),
                      label: const Text('Change My Password'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      onPressed: () => _showResetPasswordDialog(context, currentUser),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 80.ms);
            }),
            const SizedBox(height: 16),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 40),
                  Expanded(flex: 3, child: Text('Username', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Role', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                  Expanded(flex: 3, child: Text('Created', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Status', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                  SizedBox(width: 120, child: Text('Actions', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            Expanded(
              child: _users.isEmpty
                  ? const Center(child: Text('No users found', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (ctx, i) {
                        final user = _users[i];
                        final currentUser = ref.read(authProvider).currentUser;
                        return _UserRow(
                          user: user,
                          isSelf: user.id == currentUser?.id,
                          onToggle: () async {
                            await AuthService.toggleUserStatus(user.id);
                            _load();
                          },
                          onDelete: () => _confirmDelete(context, user),
                          onResetPassword: () => _showResetPasswordDialog(context, user),
                        ).animate().fadeIn(delay: Duration(milliseconds: 50 * i));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateUserDialog(onCreated: _load),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    final current = ref.read(authProvider).currentUser;
    if (user.id == current?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't delete your own account!")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "${user.username}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await AuthService.deleteUser(user.id);
              if (context.mounted) Navigator.pop(context);
              _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, UserModel user) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reset Password: ${user.username}'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.length >= 4) {
                await AuthService.updatePassword(user.id, ctrl.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password updated for ${user.username}')),
                  );
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _UserStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _UserStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}

class _UserRow extends StatefulWidget {
  final UserModel user;
  final bool isSelf;
  final VoidCallback onToggle, onDelete, onResetPassword;
  const _UserRow({required this.user, required this.isSelf, required this.onToggle, required this.onDelete, required this.onResetPassword});

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceVariant : AppColors.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderColor.withValues(alpha: _hovered ? 1.0 : 0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: (u.role == 'admin' ? AppColors.accentOrange : AppColors.primary).withValues(alpha: 0.2),
              child: Text(
                u.username[0].toUpperCase(),
                style: TextStyle(
                  color: u.role == 'admin' ? AppColors.accentOrange : AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: Row(children: [
              Text(u.username, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              if (widget.isSelf) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('You', style: TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ])),
            Expanded(flex: 2, child: Container(
              width: 70,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (u.role == 'admin' ? AppColors.accentOrange : AppColors.accent).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(u.role == 'admin' ? 'Admin' : 'Staff',
                style: TextStyle(
                  color: u.role == 'admin' ? AppColors.accentOrange : AppColors.accent,
                  fontSize: 12, fontWeight: FontWeight.w600,
                )),
            )),
            Expanded(flex: 3, child: Text(
              DateFormat('dd MMM yyyy').format(u.createdAt),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )),
            Expanded(flex: 2, child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (u.isActive ? AppColors.accentGreen : AppColors.accentRed).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(u.isActive ? '● Active' : '● Inactive',
                style: TextStyle(
                  color: u.isActive ? AppColors.accentGreen : AppColors.accentRed,
                  fontSize: 12, fontWeight: FontWeight.w600,
                )),
            )),
            SizedBox(
              width: 120,
              child: Row(children: [
                _ActionIcon(icon: Icons.lock_reset, color: AppColors.accent, tooltip: 'Reset Password', onTap: widget.onResetPassword),
                const SizedBox(width: 4),
                _ActionIcon(
                  icon: u.isActive ? Icons.person_off : Icons.person,
                  color: u.isActive ? AppColors.accentOrange : AppColors.accentGreen,
                  tooltip: u.isActive ? 'Deactivate' : 'Activate',
                  onTap: widget.isSelf ? null : widget.onToggle,
                ),
                const SizedBox(width: 4),
                _ActionIcon(
                  icon: Icons.delete_outline,
                  color: AppColors.accentRed,
                  tooltip: 'Delete',
                  onTap: widget.isSelf ? null : widget.onDelete,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;
  const _ActionIcon({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: onTap == null ? AppColors.textMuted : color),
        ),
      ),
    );
  }
}

class _GradBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _GradBtn({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateUserDialog({required this.onCreated});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New User', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username *', prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => v!.length < 4 ? 'Min 4 characters' : null,
              ),
              const SizedBox(height: 16),
              // Role is always Staff when created from this screen.
              // Admins are created only via the initial setup (Register screen).
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Role: Staff', style: TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Staff can access POS, Inventory & History',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Staff', style: TextStyle(
                        color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.accentRed, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _create,
                    child: const Text('Create User'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final username = _usernameCtrl.text.trim();
    if (AuthService.usernameExists(username)) {
      setState(() => _error = 'Username already exists');
      return;
    }
    // Staff users are always created with role 'user'. Admins only via Register.
    await AuthService.createUser(username: username, password: _passwordCtrl.text, role: 'user');
    widget.onCreated();
    Navigator.pop(context);
  }
}
