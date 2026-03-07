import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

/// Reusable feedback helper — provides "Report a Bug" and "Leave a Comment"
/// options, collects text, and sends an email to the support address.
class FeedbackHelper {
  static const String _recipientEmail = 'mssri89@gmail.com';

  /// Shows a popup menu anchored to the given button with two options.
  static void showFeedbackMenu(BuildContext context, String screenName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.bug_report, color: Colors.redAccent),
                  title: const Text('Report a Bug',
                      style: TextStyle(color: ColossusTheme.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showFeedbackDialog(context, screenName, isBug: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.comment,
                      color: ColossusTheme.primaryColor),
                  title: const Text('Leave a Comment',
                      style: TextStyle(color: ColossusTheme.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showFeedbackDialog(context, screenName, isBug: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showFeedbackDialog(BuildContext context, String screenName,
      {required bool isBug}) {
    final controller = TextEditingController();
    final title = isBug ? 'Report a Bug' : 'Leave a Comment';
    final hintText = isBug ? 'Describe the bug...' : 'Write your comment...';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColossusTheme.surfaceColor,
        title: Text(title,
            style: const TextStyle(color: ColossusTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen name (read-only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.screen_share,
                      size: 16, color: ColossusTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    screenName,
                    style: const TextStyle(
                      color: ColossusTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input text box
            TextField(
              controller: controller,
              maxLines: 5,
              style: const TextStyle(color: ColossusTheme.textPrimary),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: ColossusTheme.textSecondary),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: ColossusTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: ColossusTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              await _sendEmail(
                screenName: screenName,
                body: text,
                isBug: isBug,
                context: context,
              );
            },
            child: const Text('SUBMIT',
                style: TextStyle(color: ColossusTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  static Future<void> _sendEmail({
    required String screenName,
    required String body,
    required bool isBug,
    required BuildContext context,
  }) async {
    final prefix = isBug ? 'Bug' : 'Feedback';
    final subject = '$prefix: $screenName';
    final uri = Uri(
      scheme: 'mailto',
      path: _recipientEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: Colors.redAccent),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isBug ? 'Bug report sent!' : 'Feedback sent!'),
              backgroundColor: const Color(0xFF10BB82)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
