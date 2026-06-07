import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/suggestion_api_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/app_logger.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/neumorphic_container.dart';
import '../auth/login_screen.dart';
import 'ios_sms_setup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _tag = 'SettingsScreen';

  bool _isSyncing = false;
  bool _isRestoring = false;
  DateTime? _lastSyncTime;
  String? _statusMessage;
  bool _statusIsError = false;

  bool _gmailConnected = false;
  bool _isConnectingGmail = false;
  bool _isSyncingGmail = false;

  @override
  void initState() {
    super.initState();
    AppLogger.d(_tag, 'SettingsScreen initialized');
    _loadLastSyncTime();
    _checkGmailStatus();
  }

  Future<void> _checkGmailStatus() async {
    final connected = await SuggestionApiService.getGmailStatus();
    if (mounted) setState(() => _gmailConnected = connected);
  }

  Future<void> _connectGmail() async {
    AppLogger.i(_tag, 'Connect Gmail tapped');
    setState(() => _isConnectingGmail = true);
    try {
      final url = await SuggestionApiService.getGmailAuthUrl();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.w(_tag, 'Cannot launch Gmail auth URL');
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Connect Gmail error', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Gmail authorization. Are you logged in?')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnectingGmail = false);
    }
  }

  Future<void> _syncGmail() async {
    AppLogger.i(_tag, 'Sync Gmail tapped');
    setState(() => _isSyncingGmail = true);
    try {
      final count = await SuggestionApiService.triggerGmailSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Queued $count message(s) for analysis')),
        );
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Gmail sync error', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gmail sync failed. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingGmail = false);
    }
  }

  Future<void> _disconnectGmail() async {
    AppLogger.i(_tag, 'Disconnect Gmail tapped');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Gmail'),
        content: const Text('Gmail will no longer be scanned for transactions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect', style: TextStyle(color: AppColors.expenseRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SuggestionApiService.disconnectGmail();
      if (mounted) setState(() => _gmailConnected = false);
    }
  }

  void _openSmsSetting() {
    if (Platform.isIOS) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const IosSmsSetupScreen()),
      );
    } else {
      // Android: request SMS permission (handled by SmsService)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS permission is requested automatically when needed on Android.'),
        ),
      );
    }
  }

  Future<void> _loadLastSyncTime() async {
    final t = await SyncService.getLastSyncTime();
    AppLogger.d(_tag, 'Last sync time loaded: $t');
    if (mounted) setState(() => _lastSyncTime = t);
  }

  // ── Sync to cloud ──────────────────────────────────────────────────────────

  Future<void> _syncToCloud() async {
    AppLogger.i(_tag, 'Sync to cloud tapped');
    setState(() {
      _isSyncing = true;
      _statusMessage = null;
    });

    try {
      final result = await SyncService.syncToCloud();
      AppLogger.i(_tag, 'Sync complete: ${result.summary}');
      setState(() {
        _lastSyncTime = DateTime.now();
        _statusMessage = result.hasChanges
            ? '✓ ${result.summary}'
            : '✓ Everything is already up to date.';
        _statusIsError = result.hasErrors;
      });
      if (result.hasErrors) _showErrorDetails(result.errors);
    } on ApiException catch (e) {
      AppLogger.w(_tag, 'Sync ApiException: ${e.message}');
      setState(() {
        _statusMessage = e.message;
        _statusIsError = true;
      });
    } catch (e, st) {
      AppLogger.e(_tag, 'Sync unexpected error', e, st);
      setState(() {
        _statusMessage = 'An unexpected error occurred.';
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // ── Restore from cloud ─────────────────────────────────────────────────────

  Future<void> _restoreFromCloud() async {
    AppLogger.i(_tag, 'Restore from cloud tapped');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Cloud'),
        content: const Text(
          'This will replace ALL local data with your cloud backup.\n\n'
          'Any transactions not previously synced will be lost.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore', style: TextStyle(color: AppColors.expenseRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      AppLogger.d(_tag, 'Restore cancelled by user');
      return;
    }

    setState(() {
      _isRestoring = true;
      _statusMessage = null;
    });

    try {
      final result = await SyncService.restoreFromCloud();
      AppLogger.i(_tag, 'Restore complete: ${result.summary}');
      setState(() {
        _lastSyncTime = DateTime.now();
        _statusMessage = result.downloaded > 0
            ? '✓ Restored ${result.downloaded} transaction(s) from cloud.'
            : '✓ No transactions found in cloud.';
        _statusIsError = result.hasErrors;
      });
      if (result.hasErrors) _showErrorDetails(result.errors);
    } on ApiException catch (e) {
      AppLogger.w(_tag, 'Restore ApiException: ${e.message}');
      setState(() {
        _statusMessage = e.message;
        _statusIsError = true;
      });
    } catch (e, st) {
      AppLogger.e(_tag, 'Restore unexpected error', e, st);
      setState(() {
        _statusMessage = 'An unexpected error occurred.';
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────

  Future<void> _signOut() async {
    AppLogger.i(_tag, 'Sign out tapped');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Your local data will remain on this device. '
          'You can sync it again after signing back in.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.expenseRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      AppLogger.i(_tag, 'Signing out');
      await AuthApiService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } else {
      AppLogger.d(_tag, 'Sign out cancelled');
    }
  }

  void _showErrorDetails(List<String> errors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync Errors'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: errors
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $e', style: const TextStyle(fontSize: AppConstants.fontS)),
                    ))
                .toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = DatabaseService.getCurrentUser();
    final unsynced = DatabaseService.getUnsyncedTransactions().length;
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spaceL),
              _buildAppBar(context),
              const SizedBox(height: AppConstants.spaceXL),

              // User card
              if (user != null) _buildUserCard(user.firstName, user.username, user.email ?? ''),
              const SizedBox(height: AppConstants.spaceXL),

              // AI Suggestions section
              _sectionTitle(context, 'AI Suggestions'),
              const SizedBox(height: AppConstants.spaceM),
              _buildAiSuggestionsCard(context),
              const SizedBox(height: AppConstants.spaceXL),

              // Cloud sync section
              _sectionTitle(context, 'Cloud Backup & Sync'),
              const SizedBox(height: AppConstants.spaceM),
              _buildSyncCard(context, unsynced),
              const SizedBox(height: AppConstants.spaceXL),

              // Appearance section
              _sectionTitle(context, 'Appearance'),
              const SizedBox(height: AppConstants.spaceM),
              _buildThemeRow(context, isDark),
              const SizedBox(height: AppConstants.spaceXL),

              // Account section
              _sectionTitle(context, 'Account'),
              const SizedBox(height: AppConstants.spaceM),
              _buildSignOutButton(),
              const SizedBox(height: AppConstants.spaceXXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const NeumorphicContainer(
            width: 45, height: 45,
            shape: BoxShape.circle,
            child: Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        const SizedBox(width: AppConstants.spaceL),
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.primaryGreen,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildUserCard(String firstName, String username, String email) {
    return NeumorphicContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceL),
      child: Row(
        children: [
          const NeumorphicContainer(
            width: 56, height: 56,
            shape: BoxShape.circle,
            child: Center(child: Text('☽', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: AppConstants.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isNotEmpty ? firstName : username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppConstants.fontL),
                ),
                Text('@$username', style: const TextStyle(color: AppColors.primaryGreen, fontSize: AppConstants.fontS)),
                if (email.isNotEmpty)
                  Text(email, style: const TextStyle(fontSize: AppConstants.fontXS, color: AppColors.lightTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestionsCard(BuildContext context) {
    return NeumorphicContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gmail row
          _SyncActionRow(
            icon: Icons.email_outlined,
            title: _gmailConnected ? 'Gmail Connected' : 'Connect Gmail',
            subtitle: _gmailConnected
                ? 'Tap "Sync" to fetch recent financial emails'
                : 'Auto-detect transactions from Gmail',
            isLoading: _isConnectingGmail,
            onTap: (_isConnectingGmail || _isSyncingGmail)
                ? null
                : (_gmailConnected ? null : _connectGmail),
          ),

          if (_gmailConnected) ...[
            const SizedBox(height: AppConstants.spaceS),
            Row(
              children: [
                const SizedBox(width: 58), // Align with text above
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSyncingGmail ? null : _syncGmail,
                          icon: _isSyncingGmail
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync, size: 14),
                          label: const Text('Sync inbox', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side: const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spaceS),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _disconnectGmail,
                          icon: const Icon(Icons.link_off, size: 14),
                          label: const Text('Disconnect', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.expenseRed,
                            side: const BorderSide(color: AppColors.expenseRed),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppConstants.spaceM),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.spaceM),

          // SMS row
          _SyncActionRow(
            icon: Icons.sms_outlined,
            title: 'Set up SMS Notifications',
            subtitle: Platform.isIOS
                ? 'Use iOS Shortcuts to forward financial SMS'
                : 'Auto-read financial SMS on this device',
            isLoading: false,
            onTap: _openSmsSetting,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context, int unsyncedCount) {
    final syncFmt = DateFormat('d MMM yyyy, h:mm a');

    return NeumorphicContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              Icon(
                _lastSyncTime != null ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: _lastSyncTime != null ? AppColors.primaryGreen : AppColors.lightTextSecondary,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spaceS),
              Expanded(
                child: Text(
                  _lastSyncTime != null
                      ? 'Last synced: ${syncFmt.format(_lastSyncTime!)}'
                      : 'Never synced',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),

          if (unsyncedCount > 0) ...[
            const SizedBox(height: AppConstants.spaceS),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceM, vertical: AppConstants.spaceXS),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                '$unsyncedCount transaction(s) waiting to sync',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: AppConstants.fontXS,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Status message
          if (_statusMessage != null) ...[
            const SizedBox(height: AppConstants.spaceM),
            Container(
              padding: const EdgeInsets.all(AppConstants.spaceM),
              decoration: BoxDecoration(
                color: (_statusIsError ? AppColors.expenseRed : AppColors.primaryGreen)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  fontSize: AppConstants.fontS,
                  color: _statusIsError ? AppColors.expenseRed : AppColors.primaryGreen,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spaceL),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.spaceL),

          // Sync button
          _SyncActionRow(
            icon: Icons.cloud_upload_outlined,
            title: 'Sync to Cloud',
            subtitle: unsyncedCount > 0
                ? 'Upload $unsyncedCount unsynced transaction(s)'
                : 'Upload any new transactions',
            isLoading: _isSyncing,
            onTap: (_isSyncing || _isRestoring) ? null : _syncToCloud,
          ),

          const SizedBox(height: AppConstants.spaceM),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.spaceM),

          // Restore button
          _SyncActionRow(
            icon: Icons.cloud_download_outlined,
            title: 'Restore from Cloud',
            subtitle: 'Replace local data with your cloud backup',
            isLoading: _isRestoring,
            isDestructive: true,
            onTap: (_isSyncing || _isRestoring) ? null : _restoreFromCloud,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeRow(BuildContext context, bool isDark) {
    return NeumorphicContainer(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceL,
        vertical: AppConstants.spaceM,
      ),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: AppColors.primaryGreen,
            size: 22,
          ),
          const SizedBox(width: AppConstants.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  isDark ? 'Dark mode' : 'Light mode',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              AppLogger.d(_tag, 'Theme toggle tapped');
              ref.read(themeNotifierProvider.notifier).toggleTheme();
            },
            child: NeumorphicContainer(
              isInset: isDark,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceL,
                vertical: AppConstants.spaceS,
              ),
              child: Text(
                isDark ? 'Switch to Light' : 'Switch to Dark',
                style: const TextStyle(
                  fontSize: AppConstants.fontS,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return NeumorphicButton(
      onPressed: _signOut,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.logout_outlined, color: AppColors.expenseRed, size: 18),
          SizedBox(width: AppConstants.spaceS),
          Text(
            'Sign Out',
            style: TextStyle(
              color: AppColors.expenseRed,
              fontWeight: FontWeight.bold,
              fontSize: AppConstants.fontM,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sync action row widget ─────────────────────────────────────────────────────

class _SyncActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SyncActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.expenseRed : AppColors.primaryGreen;
    final isDisabled = onTap == null;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(color: color, strokeWidth: 2),
                    )
                  : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppConstants.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? (isDestructive ? 'Restoring…' : 'Syncing…') : title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? AppColors.expenseRed : null,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
