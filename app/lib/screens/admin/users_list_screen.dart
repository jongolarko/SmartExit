import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import 'user_details_screen.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;

  final List<Map<String, dynamic>> _roleFilters = [
    {'label': 'All', 'role': null},
    {'label': 'Customers', 'role': 'customer'},
    {'label': 'Security', 'role': 'security'},
    {'label': 'Admins', 'role': 'admin'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersAdminProvider.notifier).fetchUsers();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(usersAdminProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildRoleFilters(state),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(usersAdminProvider.notifier).refresh(),
                color: AppColors.admin,
                child: _buildContent(state),
              ),
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
                  'Users',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.voidBlack,
                  ),
                ),
                Text(
                  'Manage user accounts',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchController.text == value) {
                ref.read(usersAdminProvider.notifier).search(value);
              }
            });
          },
          decoration: InputDecoration(
            hintText: 'Search by name or phone',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.silver,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.steel,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppColors.steel),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(usersAdminProvider.notifier).clearSearch();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: AppSpacing.input,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleFilters(UsersAdminState state) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
      ),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _roleFilters.length,
        itemBuilder: (context, index) {
          final filter = _roleFilters[index];
          final role = filter['role'] as String?;
          final isSelected = state.roleFilter == role;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedRole = role);
                ref.read(usersAdminProvider.notifier).setRoleFilter(role);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.adminLight : AppColors.pure,
                  borderRadius: AppSpacing.borderRadiusFull,
                  border: Border.all(
                    color: isSelected ? AppColors.admin : AppColors.mist,
                  ),
                  boxShadow: isSelected ? AppShadows.sm : null,
                ),
                child: Text(
                  filter['label'] as String,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.admin : AppColors.steel,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(UsersAdminState state) {
    if (state.isLoading && state.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.admin),
      );
    }

    if (state.error != null && state.users.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.users.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: state.users.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.users.length) {
          return const Center(
            child: Padding(
              padding: AppSpacing.allMd,
              child: CircularProgressIndicator(color: AppColors.admin),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildUserCard(state.users[index]),
        );
      },
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final roleColor = _getRoleColor(user.role);
    final roleBgColor = _getRoleBgColor(user.role);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailsScreen(userId: user.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pure,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            // Role indicator bar
            Container(
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusXl),
                  bottomLeft: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: AppSpacing.card,
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: roleBgColor,
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Center(
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: roleBgColor,
                                  borderRadius: AppSpacing.borderRadiusFull,
                                ),
                                child: Text(
                                  _formatRole(user.role),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: roleColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.phone,
                            style: AppTypography.bodySmall,
                          ),
                          if (user.orderCount != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${user.orderCount} orders',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.silver,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: AppColors.mist,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No users found',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try adjusting your search or filters',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
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
              'Failed to load users',
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
              onPressed: () => ref.read(usersAdminProvider.notifier).refresh(),
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

  String _formatRole(String role) {
    return role[0].toUpperCase() + role.substring(1);
  }
}
