import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../widgets/neumorphic_container.dart';

/// Step-by-step guide for iOS users to set up an iOS Shortcut that
/// automatically forwards financial SMS messages to the Yenom backend.
class IosSmsSetupScreen extends StatefulWidget {
  const IosSmsSetupScreen({super.key});

  @override
  State<IosSmsSetupScreen> createState() => _IosSmsSetupScreenState();
}

class _IosSmsSetupScreenState extends State<IosSmsSetupScreen> {
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await ApiService.getToken();
    if (mounted) setState(() => _jwtToken = token);
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = 'http://your-api-host:8080';
    final webhookUrl = '$baseUrl/api/suggestions/sms';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spaceL),
              _buildHeader(context),
              const SizedBox(height: AppConstants.spaceXL),
              _buildIntro(context),
              const SizedBox(height: AppConstants.spaceXL),
              _buildStep(
                context,
                step: 1,
                title: 'Open Shortcuts App',
                description:
                    'Open the Shortcuts app on your iPhone. Tap "Automation" at the bottom, then tap "+ New Automation".',
              ),
              _buildStep(
                context,
                step: 2,
                title: 'Set Trigger: Message Received',
                description:
                    'Select "Message" → "Message Received". Choose "From" and add your bank contacts (or leave empty for all messages). Enable "Run Immediately" and tap Next.',
              ),
              _buildStep(
                context,
                step: 3,
                title: 'Add "Get Text from Input"',
                description:
                    'Tap "New blank automation". Search for "Get Text from Shortcut Input" and add it.',
              ),
              _buildStep(
                context,
                step: 4,
                title: 'Add URL Request',
                description:
                    'Search for "Get contents of URL". Tap it to expand. Set Method to POST. Set URL to:',
                extra: _buildCopyBox(context, webhookUrl),
              ),
              _buildStep(
                context,
                step: 5,
                title: 'Set Request Body',
                description:
                    'In the URL action, tap "Show More". Set Request Body to JSON. Add a key "text" with value: the "Text" magic variable from the previous step.',
              ),
              _buildStep(
                context,
                step: 6,
                title: 'Add Authorization Header',
                description:
                    'Still in the URL action, add a header: Key = "Authorization", Value = your token below (tap to copy):',
                extra: _jwtToken != null
                    ? _buildCopyBox(context, 'Bearer $_jwtToken')
                    : const Text('Loading token…'),
              ),
              _buildStep(
                context,
                step: 7,
                title: 'Tap Done',
                description:
                    'Tap Done to save the automation. Now whenever you receive a message matching the trigger, Yenom will automatically analyze it and suggest a transaction.',
              ),
              const SizedBox(height: AppConstants.spaceXL),
              _buildTestTip(context),
              const SizedBox(height: AppConstants.spaceXXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SMS Setup (iOS)', style: Theme.of(context).textTheme.headlineSmall),
              Text(
                'iOS Shortcuts automation guide',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntro(BuildContext context) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
              SizedBox(width: AppConstants.spaceS),
              Text('How this works', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: AppConstants.spaceS),
          Text(
            'iOS does not allow apps to read your SMS directly. Instead, you create a one-time '
            'iOS Shortcuts automation that fires whenever a message arrives and forwards the '
            'text to Yenom\'s backend. Claude then analyzes it and surfaces a transaction '
            'suggestion for you to review.',
            style: TextStyle(fontSize: AppConstants.fontS),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int step,
    required String title,
    required String description,
    Widget? extra,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: AppConstants.fontS,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: AppConstants.fontS)),
                if (extra != null) ...[
                  const SizedBox(height: AppConstants.spaceS),
                  extra,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyBox(BuildContext context, String value) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spaceS),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppConstants.radiusXS),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: AppConstants.fontXS,
                ),
              ),
            ),
            const Icon(Icons.copy_outlined, size: 14, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildTestTip(BuildContext context) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
              SizedBox(width: AppConstants.spaceS),
              Text('Test it', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: AppConstants.spaceS),
          Text(
            'Ask a friend to send you "Your account was debited \$50.00 at Starbucks." '
            'Then open Yenom Suggestions to see the auto-detected transaction.',
            style: TextStyle(fontSize: AppConstants.fontS),
          ),
        ],
      ),
    );
  }
}
