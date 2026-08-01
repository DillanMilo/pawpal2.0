import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/theme.dart';
import '../../widgets/brand_mark.dart';

const _supportEmail = 'creativecurrentsx@gmail.com';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Privacy Policy',
      updated: 'Effective July 28, 2026',
      sections: [
        _LegalSection(
          title: 'What PawPal collects',
          body:
              'PawPal collects the account information you provide, including '
              'your name and email address. The app stores pet profiles, care '
              'records, reminders, activity history, photos, and documents you '
              'choose to add. When you request nearby pet services, PawPal may '
              'use your device location with your permission.',
        ),
        _LegalSection(
          title: 'How information is used',
          body:
              'We use this information to provide and secure PawPal, synchronize '
              'your records, deliver local reminders, support account export and '
              'deletion, find nearby services, and respond to support requests. '
              'PawPal does not sell personal information and does not use your '
              'pet-care data for advertising.',
        ),
        _LegalSection(
          title: 'Service providers',
          body:
              'PawPal uses Supabase for authentication, database, and file '
              'storage; Vercel for the web application; Google Places for nearby '
              'service results; and Apple, Google Play, or RevenueCat only when '
              'store purchases are offered. These providers process information '
              'under their own terms and privacy policies.',
        ),
        _LegalSection(
          title: 'Retention and control',
          body:
              'Your records are retained while your account is active and for '
              'limited operational backup periods. From Profile, you can export '
              'your account data or permanently delete your account. Deletion '
              'removes active account data subject to short-lived backups and '
              'legal or security obligations.',
        ),
        _LegalSection(
          title: 'Children and security',
          body:
              'PawPal is not directed to children under 13. We use access '
              'controls, encrypted connections, and restricted service '
              'credentials, but no internet service can guarantee absolute '
              'security.',
        ),
        _LegalSection(
          title: 'Questions and requests',
          body:
              'For privacy questions, correction requests, or other assistance, '
              'contact Creative Currents at $_supportEmail.',
        ),
      ],
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Terms of Service',
      updated: 'Effective July 28, 2026',
      sections: [
        _LegalSection(
          title: 'Using PawPal',
          body:
              'PawPal helps you organize pet-care information, activities, '
              'reminders, and nearby service results. You must provide accurate '
              'account information, protect your login, and use the service only '
              'for lawful personal pet-care purposes.',
        ),
        _LegalSection(
          title: 'Not veterinary advice',
          body:
              'PawPal is an organization tool and does not provide veterinary '
              'diagnosis, treatment, or emergency advice. Always consult a '
              'qualified veterinarian and contact an emergency clinic when your '
              'pet may need urgent care.',
        ),
        _LegalSection(
          title: 'Your content',
          body:
              'You retain ownership of the information and files you add. You '
              'grant PawPal permission to process that content only as needed to '
              'operate, secure, back up, export, and improve the service.',
        ),
        _LegalSection(
          title: 'Purchases',
          body:
              'If paid features are offered, prices and billing terms shown by '
              'Apple, Google Play, or the applicable checkout provider control. '
              'Manage cancellation and refund requests through the store or '
              'provider that processed the purchase.',
        ),
        _LegalSection(
          title: 'Availability and termination',
          body:
              'We may change or discontinue features and may restrict accounts '
              'that abuse the service or create security risks. You may stop '
              'using PawPal or delete your account at any time.',
        ),
        _LegalSection(
          title: 'Contact',
          body:
              'Questions about these terms can be sent to Creative Currents at '
              '$_supportEmail.',
        ),
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _emailSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'PawPal support request'},
    );
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email $_supportEmail for support.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LegalDocumentScreen(
      title: 'PawPal Support',
      updated: 'We are here to help',
      sections: const [
        _LegalSection(
          title: 'Account and data',
          body:
              'Use Profile to export your account data, update your details, '
              'change your password, or permanently delete your account.',
        ),
        _LegalSection(
          title: 'Reminders and location',
          body:
              'If reminders do not arrive, confirm notification permission and '
              'battery settings for PawPal. Nearby service search requires '
              'location permission or a ZIP code.',
        ),
        _LegalSection(
          title: 'Response',
          body:
              'Include the device type, app version, and a short description of '
              'what happened. Do not email passwords, payment information, or '
              'private veterinary documents.',
        ),
      ],
      action: (context) => FilledButton.icon(
        onPressed: () => _emailSupport(context),
        icon: const Icon(Icons.email_outlined),
        label: const Text('Email support'),
      ),
    );
  }
}

class _LegalDocumentScreen extends StatelessWidget {
  const _LegalDocumentScreen({
    required this.title,
    required this.updated,
    required this.sections,
    this.action,
  });

  final String title;
  final String updated;
  final List<_LegalSection> sections;
  final Widget Function(BuildContext context)? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: BrandMark(size: 64)),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    updated,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final section in sections) ...[
                    Semantics(
                      header: true,
                      child: Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (action != null) ...[
                    action!(context),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.pets_outlined),
                    label: const Text('Return to PawPal'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PawPal is a Creative Currents product.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}
