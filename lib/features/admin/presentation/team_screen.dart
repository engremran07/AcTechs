import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  String _search = '';
  final Set<String> _selectedIds = {};
  bool _selectMode = false;

  List<UserModel> _filter(List<UserModel> techs) {
    if (_search.isEmpty) return techs;
    final q = _search.toLowerCase();
    return techs
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              t.email.toLowerCase().contains(q),
        )
        .toList();
  }

  void _toggleSelect(String uid) {
    setState(() {
      if (_selectedIds.contains(uid)) {
        _selectedIds.remove(uid);
        if (_selectedIds.isEmpty) _selectMode = false;
      } else {
        _selectedIds.add(uid);
        _selectMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectMode = false;
    });
  }

  Future<void> _bulkActivate(bool activate) async {
    if (_selectedIds.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref
          .read(userRepositoryProvider)
          .bulkToggleActive(_selectedIds.toList(), activate);
      if (!mounted) return;
      _clearSelection();
      AppFeedback.success(
        context,
        message: activate ? l.usersActivated : l.usersDeactivated,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _showAddTechnicianDialog() async {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addTechnician),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                textInputAction: TextInputAction.next,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.name,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.required;
                  if (!v.contains('@')) return l.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return l.minChars(6);
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (!mounted) return;

    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref
          .read(userRepositoryProvider)
          .createTechnician(
            name: nameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            password: passCtrl.text,
          );
      if (!mounted) return;
      AppFeedback.success(
        context,
        message: AppLocalizations.of(context)?.userCreated ?? 'User created!',
      );
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _showEditDialog(UserModel user) async {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editTechnician),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                textInputAction: TextInputAction.next,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.name,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.required;
                  if (!v.contains('@')) return l.invalidEmail;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (!mounted) return;

    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref
          .read(userRepositoryProvider)
          .updateUser(
            uid: user.uid,
            name: nameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
          );
      if (!mounted) return;
      AppFeedback.success(
        context,
        message: AppLocalizations.of(context)?.userUpdated ?? 'User updated!',
      );
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _handlePasswordReset(UserModel user) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref.read(userRepositoryProvider).sendPasswordReset(user.email);
      if (!mounted) return;
      AppFeedback.success(context, message: l.passwordResetSent(user.email));
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _handleDeleteUser(UserModel user) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTechnician),
        content: Text(l.confirmDeleteUser(user.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ArcticTheme.arcticError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref.read(userRepositoryProvider).deleteUser(user.uid);
      if (!mounted) return;
      AppFeedback.success(context, message: l.userDeleted);
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  @override
  Widget build(BuildContext context) {
    final technicians = ref.watch(allTechniciansProvider);
    final l = AppLocalizations.of(context)!;

    return AppShortcuts(
      onRefresh: () => ref.invalidate(allTechniciansProvider),
      child: Scaffold(
        appBar: AppBar(
          title: _selectMode
              ? Text(l.selectedCount(_selectedIds.length))
              : Text(l.team),
          leading: _selectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : null,
          actions: [
            if (_selectMode) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: l.bulkActivate,
                onPressed: () => _bulkActivate(true),
              ),
              IconButton(
                icon: const Icon(Icons.person_off_rounded),
                tooltip: l.bulkDeactivate,
                onPressed: () => _bulkActivate(false),
              ),
            ],
          ],
        ),
        floatingActionButton: _selectMode
            ? null
            : FloatingActionButton.extended(
                    onPressed: _showAddTechnicianDialog,
                    backgroundColor: ArcticTheme.arcticBlue,
                    foregroundColor: ArcticTheme.arcticDarkBg,
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(l.addTechnician),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
        body: SafeArea(
          child: technicians.when(
            data: (techs) {
              final filtered = _filter(techs);
              final active = filtered.where((t) => t.isActive).toList();
              final inactive = filtered.where((t) => !t.isActive).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: ArcticSearchBar(
                      hint: l.searchByNameOrEmail,
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  // Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ArcticCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _CountBadge(
                            count: techs.length,
                            label: l.total,
                            color: ArcticTheme.arcticBlue,
                          ),
                          _CountBadge(
                            count: techs.where((t) => t.isActive).length,
                            label: l.active,
                            color: ArcticTheme.arcticSuccess,
                          ),
                          _CountBadge(
                            count: techs.where((t) => !t.isActive).length,
                            label: l.inactive,
                            color: ArcticTheme.arcticTextSecondary,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              _search.isNotEmpty
                                  ? l.noMatchingMembers
                                  : l.noTeamMembers,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        : ArcticRefreshIndicator(
                            onRefresh: () async =>
                                ref.invalidate(allTechniciansProvider),
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              children: [
                                if (active.isNotEmpty) ...[
                                  Text(
                                    l.active,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ).animate().fadeIn(delay: 100.ms),
                                  const SizedBox(height: 12),
                                  ...active
                                      .map((tech) => _buildTechItem(tech))
                                      .toList()
                                      .animate(interval: 80.ms)
                                      .fadeIn()
                                      .slideX(begin: 0.03),
                                ],
                                if (inactive.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    l.inactive,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ).animate().fadeIn(delay: 200.ms),
                                  const SizedBox(height: 12),
                                  ...inactive
                                      .map((tech) => _buildTechItem(tech))
                                      .toList()
                                      .animate(interval: 80.ms)
                                      .fadeIn()
                                      .slideX(begin: 0.03),
                                ],
                                // Space for FAB
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: ArcticShimmer(count: 5),
            ),
            error: (error, _) => error is AppException
                ? Center(child: ErrorCard(exception: error))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildTechItem(UserModel tech) {
    final isSelected = _selectedIds.contains(tech.uid);
    final l = AppLocalizations.of(context)!;
    return ContextMenuRegion(
      menuItems: [
        ContextMenuItem(
          id: 'edit',
          label: l.editTechnician,
          icon: Icons.edit_rounded,
          color: ArcticTheme.arcticBlue,
        ),
        ContextMenuItem(
          id: 'resetPassword',
          label: l.resetPassword,
          icon: Icons.lock_reset_rounded,
          color: ArcticTheme.arcticWarning,
        ),
        ContextMenuItem(
          id: 'toggle',
          label: tech.isActive ? l.deactivate : l.activate,
          icon: tech.isActive
              ? Icons.person_off_rounded
              : Icons.person_add_rounded,
          color: tech.isActive
              ? ArcticTheme.arcticError
              : ArcticTheme.arcticSuccess,
        ),
        ContextMenuItem(
          id: 'delete',
          label: l.deleteTechnician,
          icon: Icons.delete_outline_rounded,
          color: ArcticTheme.arcticError,
        ),
      ],
      onSelected: (action) {
        if (action == 'toggle') {
          ref
              .read(userRepositoryProvider)
              .toggleUserActive(tech.uid, !tech.isActive);
        } else if (action == 'edit') {
          _showEditDialog(tech);
        } else if (action == 'resetPassword') {
          _handlePasswordReset(tech);
        } else if (action == 'delete') {
          _handleDeleteUser(tech);
        }
      },
      child: GestureDetector(
        onLongPress: () => _toggleSelect(tech.uid),
        onTap: _selectMode ? () => _toggleSelect(tech.uid) : null,
        child: _TechCard(
          user: tech,
          selected: isSelected,
          onEdit: () => _showEditDialog(tech),
          onResetPassword: () => _handlePasswordReset(tech),
          onDelete: () => _handleDeleteUser(tech),
        ),
      ),
    );
  }
}

class _TechCard extends ConsumerWidget {
  const _TechCard({
    required this.user,
    this.selected = false,
    this.onEdit,
    this.onResetPassword,
    this.onDelete,
  });

  final UserModel user;
  final bool selected;
  final VoidCallback? onEdit;
  final VoidCallback? onResetPassword;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ArcticCard(
      child: DecoratedBox(
        decoration: selected
            ? BoxDecoration(
                border: Border.all(color: ArcticTheme.arcticBlue, width: 2),
                borderRadius: BorderRadius.circular(12),
              )
            : const BoxDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: user.isActive
                    ? ArcticTheme.arcticBlue.withValues(alpha: 0.15)
                    : ArcticTheme.arcticTextSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'T',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: user.isActive
                        ? ArcticTheme.arcticBlue
                        : ArcticTheme.arcticTextSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.editTechnician,
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: ArcticTheme.arcticBlue,
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.resetPassword,
              icon: const Icon(Icons.lock_reset_rounded, size: 20),
              color: ArcticTheme.arcticWarning,
              onPressed: onResetPassword,
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.deleteTechnician,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: ArcticTheme.arcticError,
              onPressed: onDelete,
            ),
            Switch(
              value: user.isActive,
              activeTrackColor: ArcticTheme.arcticSuccess,
              onChanged: (value) {
                ref
                    .read(userRepositoryProvider)
                    .toggleUserActive(user.uid, value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
