import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/unsubscribe_parser.dart';
import '../providers/email_providers.dart';

class EmailDetailView extends ConsumerWidget {
  final String emailId;
  final VoidCallback onBack;

  const EmailDetailView({
    super.key,
    required this.emailId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailAsync = ref.watch(fullEmailProvider(emailId));
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to list',
                onPressed: onBack,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: emailAsync.when(
            data: (email) {
              if (email == null) {
                return const Center(child: Text('Email not found'));
              }

              final unsubscribeLink = UnsubscribeParser.extract(
                header: email.unsubscribeLink,
                bodyText: email.bodyText,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject
                    Text(
                      email.subject,
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 12),
                    // From & date
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            email.from,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        Text(
                          _formatDate(email.date),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Unsubscribe banner
                    if (unsubscribeLink != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.tertiaryContainer,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.unsubscribe,
                              size: 20,
                              color: colorScheme.tertiary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Unsubscribe link found'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final uri = Uri.parse(unsubscribeLink);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              child: const Text('Open'),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Body
                    if (email.bodyHtml != null)
                      HtmlWidget(
                        email.bodyHtml!,
                        textStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                ),
                        customWidgetBuilder: (element) {
                          if (element.localName == 'img') {
                            return const SizedBox.shrink();
                          }
                          return null;
                        },
                        onTapUrl: (url) {
                          launchUrl(Uri.parse(url));
                          return true;
                        },
                      )
                    else
                      SelectableText(
                        email.bodyText,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                ),
                      ),
                  ],
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Error loading email: $error')),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inHours < 24) {
      return timeago.format(date);
    }
    return DateFormat.yMMMd().format(date);
  }
}
