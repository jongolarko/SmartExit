import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import 'admin_order_details_screen.dart';

class UserDetailsScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailsScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersAdminProvider.notifier).fetchUserDetails(widget.userId);
      ref.read(usersAdminProvider.notifier).fetchUserOrders(widget.userId);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(usersAdminProvider.notifier)
          .fetchUserOrders(widget.userId, loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    ref.read(usersAdminProvider.notifier).clearSelectedUser();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersAdminProvider);
    final details = state.selectedUserDetails;

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(state, details),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.screenAll,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.pure,
                borderRadius: AppSpacing.borderRadiusMd,
                boxShadow: AppShadows.sm,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.voidBlack,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Details',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.voidBlack,
                  ),
                ),
                Text(
                  'View and manage user',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(UsersAdminState state, UserDetails? details) {
    if (state.isLoading && details == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.admin),
      );
    }

    if (state.error != null && details == null) {
      return _buildErrorState(state.error!);
    }

    if (details == null) {
      return _buildErrorState('User not found');
    }

    final user = details.user;
    final stats = details.stats;
    final roleColor = _getRoleColor(user.role);
    final roleBgColor = _getRoleBgColor(user.role);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(usersAdminProvider.notifier).fetchUserDetails(widget.userId);
        await ref.read(usersAdminProvider.notifier).fetchUserOrders(widget.userId);
      },
      color: AppColors.admin,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            _buildProfileCard(user, roleColor, roleBgColor),
            const SizedBox(height: AppSpacing.lg),

            // Stats Cards
            _buildStatsCards(stats),
            const SizedBox(height: AppSpacing.lg),

            // Role Management
            _buildSectionTitle('Role Management'),
            const SizedBox(height: AppSpacing.sm),
            _buildRoleSelector(user, state.isProcessing),
            const SizedBox(height: AppSpacing.lg),

            // Recent Orders
            _buildSectionTitle('Recent Orders'),
            const SizedBox(height: AppSpacing.sm),
            _buildOrdersList(state),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(AdminUser user, Color roleColor, Color roleBgColor) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: roleBgColor,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Center(
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.voidBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: roleBgColor,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        _formatRole(user.role),
                        style: AppTypography.labelMedium.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: AppColors.mist.withOpacity(0.5), height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.steel,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Member since ${_formatDate(user.createdAt)}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(UserStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Total Orders',
            value: stats.totalOrders.toString(),
            icon: Icons.receipt_long_outlined,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            label: 'Total Spent',
            value: '\u20B9${stats.totalSpent.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.admin,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.voidBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoleSelector(AdminUser user, bool isProcessing) {
    final roles = [
      {'role': 'customer', 'label': 'Customer', 'icon': Icons.person_outline},
      {'role': 'security', 'label': 'Security', 'icon': Icons.security_outlined},
      {'role': 'admin', 'label': 'Admin', 'icon': Icons.admin_panel_settings_outlined},
    ];

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Role: ${_formatRole(user.role)}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ...roles.map((roleData) {
            final role = roleData['role'] as String;
            final label = roleData['label'] as String;
            final icon = roleData['icon'] as IconData;
            final isSelected = user.role == role;
            final roleColor = _getRoleColor(role);
            final roleBgColor = _getRoleBgColor(role);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                onTap: isSelected || isProcessing
                    ? null
                    : () => _showRoleChangeConfirmation(user, role, label),
                child: Container(
                  padding: AppSpacing.cardSm,
                  decoration: BoxDecoration(
                    color: isSelected ? roleBgColor : AppColors.cloud,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: isSelected ? roleColor : AppColors.mist,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? roleColor : AppColors.steel,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          label,
                          style: AppTypography.labelLarge.copyWith(
                            color: isSelected ? roleColor : AppColors.steel,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: roleColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          if (isProcessing) ...[
            const SizedBox(height: AppSpacing.sm),
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.admin,
                strokeWidth: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrdersList(UsersAdminState state) {
    final orders = state.selectedUserOrders ?? [];

    if (orders.isEmpty && !state.isLoading) {
      return Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppShadows.sm,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.mist,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No orders yet',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...orders.asMap().entries.map((entry) {
          final order = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildOrderCard(order),
          );
        }).toList(),
        if (state.hasMoreUserOrders && !state.isLoading)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.admin,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderCard(UserOrder order) {
    final statusColor = _getStatusColor(order.status);
    final statusBgColor = _getStatusBgColor(order.status);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminOrderDetailsScreen(orderId: order.id),
          ),
        );
      },
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Center(
                child: Icon(
                  Icons.receipt_outlined,
                  color: statusColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\u20B9${order.totalAmount.toStringAsFixed(2)}',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          _formatStatus(order.status),
                          style: AppTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(order.createdAt),
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.silver,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleChangeConfirmation(AdminUser user, String newRole, String roleLabel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        title: Text(
          'Change User Role',
          style: AppTypography.headlineMedium,
        ),
        content: Text(
          'Change ${user.name}\'s role to $roleLabel? The user will need to log in again.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.steel,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(usersAdminProvider.notifier).updateUserRole(
                userId: user.id,
                role: newRole,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User role updated to $roleLabel'),
                    backgroundColor: AppColors.accent,
                  ),
                );
              } else if (mounted) {
                final error = ref.read(usersAdminProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Failed to update role'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.admin,
              foregroundColor: AppColors.pure,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load user',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(usersAdminProvider.notifier).fetchUserDetails(widget.userId),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.admin,
                foregroundColor: AppColors.pure,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'customer':
        return AppColors.customer;
      case 'security':
        return AppColors.security;
      case 'admin':
        return AppColors.admin;
      default:
        return AppColors.steel;
    }
  }

  Color _getRoleBgColor(String role) {
    switch (role) {
      case 'customer':
        return AppColors.accentLight;
      case 'security':
        return AppColors.securityLight;
      case 'admin':
        return AppColors.adminLight;
      default:
        return AppColors.cloud;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.accent;
      case 'refunded':
        return AppColors.security;
      case 'cancelled':
        return AppColors.error;
      case 'created':
        return AppColors.warning;
      default:
        return AppColors.steel;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.accentLight;
      case 'refunded':
        return AppColors.securityLight;
      case 'cancelled':
        return AppColors.errorLight;
      case 'created':
        return AppColors.warningLight;
      default:
        return AppColors.cloud;
    }
  }

  String _formatRole(String role) {
    return role[0].toUpperCase() + role.substring(1);
  }

  String _formatStatus(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
