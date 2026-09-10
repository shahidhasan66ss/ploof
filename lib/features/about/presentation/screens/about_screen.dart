import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/brand_mark.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: <Widget>[
              const Center(child: BrandMark()),
              const SizedBox(height: 16),
              Text(AppConstants.appTagline, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 28),
              _InfoCard(
                icon: Icons.theater_comedy_outlined,
                title: 'Keep it fictional',
                body: AppConstants.responsibleUseNotice,
              ),
              const SizedBox(height: 14),
              _InfoCard(
                icon: Icons.lock_outline_rounded,
                title: 'Privacy',
                body: 'ChatPop works without accounts or a backend. Your projects, images and exports remain on your device unless you choose to share them through your device’s share sheet.',
              ),
              const SizedBox(height: 14),
              _InfoCard(
                icon: Icons.gavel_outlined,
                title: 'Terms of use',
                body: 'Use ChatPop for harmless creative entertainment. Do not use content made here to deceive others, impersonate people, harass someone, or fabricate evidence. You are responsible for what you create and share.',
              ),
              const SizedBox(height: 14),
              _InfoCard(
                icon: Icons.offline_bolt_outlined,
                title: 'Offline by design',
                body: 'Built-in templates, stickers, reactions and chat styles are included in the app. No internet connection is needed to make a chat.',
              ),
            ],
          ),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
