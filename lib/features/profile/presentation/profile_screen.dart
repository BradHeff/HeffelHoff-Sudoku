import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/profile_repository.dart';
import '../../auth/presentation/account_sheet.dart';
import '../../monetization/data/rewarded_economy_service.dart';
import '../../sudoku/domain/difficulty.dart';
import '../data/best_iq_repository.dart';

/// Full-screen profile route. Surfaces account type (email / Google /
/// Apple / guest), membership state (Free / Pro), best-IQ stats, and
/// top-rank tiers. Guest users see a sign-in CTA instead of the editor.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    Text('Profile', style: text.headlineSmall),
                    const Spacer(),
                    Icon(Icons.person_outline, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
              Expanded(
                child: auth.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorView(message: '$e'),
                  data: (user) => user == null
                      ? const _SignedOutView()
                      : _SignedInBody(user: user),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Not signed in', style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Sign in to track your IQ across devices and climb the leaderboard.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showAccountSheet(context),
              icon: const Icon(Icons.login),
              label: const Text('Sign in or create account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInBody extends ConsumerWidget {
  const _SignedInBody({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final bestIqAsync = ref.watch(userBestIqProvider);
    final topRanks = ref.watch(userTopRanksProvider).asData?.value ??
        const TopRankInfo(tiers: []);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _AvatarHeader(user: user, profileAsync: profileAsync),
        const SizedBox(height: 24),
        _AccountSection(user: user, profileAsync: profileAsync),
        const SizedBox(height: 16),
        const _RewardsSection(),
        const SizedBox(height: 16),
        _StatsSection(bestIqAsync: bestIqAsync, topRanks: topRanks),
        const SizedBox(height: 24),
        _DangerZone(user: user),
      ],
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.user, required this.profileAsync});

  final User user;
  final AsyncValue<Profile?> profileAsync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isAnonymous = user.isAnonymous == true;

    return Column(
      children: [
        profileAsync.when(
          loading: () => const SizedBox(
            height: 96,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(height: 96),
          data: (profile) => Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.45),
                  blurRadius: 24,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: isAnonymous
                ? Icon(Icons.person, color: scheme.onPrimaryContainer, size: 44)
                : Text(
                    _initialFor(profile?.displayName),
                    style: text.displaySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ).animate().scaleXY(begin: 0.8, end: 1, duration: 320.ms, curve: Curves.easeOutBack).fadeIn(),
        const SizedBox(height: 16),
        profileAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text(
            'Could not load profile.',
            style: text.bodySmall?.copyWith(color: scheme.error),
          ),
          data: (profile) => _UsernameLine(user: user, profile: profile),
        ),
      ],
    );
  }

  static String _initialFor(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '?';
    return displayName.trim()[0].toUpperCase();
  }
}

class _UsernameLine extends ConsumerStatefulWidget {
  const _UsernameLine({required this.user, required this.profile});

  final User user;
  final Profile? profile;

  @override
  ConsumerState<_UsernameLine> createState() => _UsernameLineState();
}

class _UsernameLineState extends ConsumerState<_UsernameLine> {
  late final TextEditingController _controller;
  bool _editing = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.profile?.displayName ?? '');
    if (widget.profile?.isPlaceholderName ?? false) {
      _editing = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    final err = ProfileRepository.validateUsername(name);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateDisplayName(
            userId: widget.user.id,
            name: name,
          );
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final profile = widget.profile;
    final placeholder = profile?.isPlaceholderName ?? false;

    if (!_editing) {
      return Column(
        children: [
          Text(
            profile?.displayName ?? '—',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          TextButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(placeholder ? 'Set a username' : 'Edit username'),
            style: TextButton.styleFrom(
              foregroundColor: placeholder ? scheme.primary : scheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLength: 24,
          textInputAction: TextInputAction.done,
          onSubmitted: _busy ? null : (_) => _save(),
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: 'Username',
            border: const OutlineInputBorder(),
            counterText: '',
            errorText: _error,
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => setState(() => _editing = false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.child,
    this.accent,
  });

  final String label;
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stroke = accent ?? scheme.outlineVariant;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stroke.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: iqDisplayStyle(context, size: 11, color: scheme.onSurfaceVariant)
                .copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.user, required this.profileAsync});

  final User user;
  final AsyncValue<Profile?> profileAsync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isAnonymous = user.isAnonymous == true;
    final providerKey = (user.appMetadata['provider'] as String?) ?? '';
    final email = user.email ?? '';
    final providerInfo = _providerLabel(providerKey, isAnonymous);

    return _SectionCard(
      label: 'ACCOUNT',
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: providerInfo.tint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(providerInfo.icon, color: providerInfo.tint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  providerInfo.label,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  isAnonymous
                      ? 'Scores are saved on this device only.'
                      : (email.isNotEmpty ? email : 'Signed in'),
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (isAnonymous)
            FilledButton.tonal(
              onPressed: () => showAccountSheet(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  static ({String label, IconData icon, Color tint}) _providerLabel(
    String key,
    bool isAnonymous,
  ) {
    if (isAnonymous) {
      return (label: 'Guest account', icon: Icons.person_outline, tint: const Color(0xFF9E9E9E));
    }
    switch (key.toLowerCase()) {
      case 'google':
        return (label: 'Google account', icon: Icons.g_mobiledata, tint: const Color(0xFFEA4335));
      case 'apple':
        return (label: 'Apple account', icon: Icons.apple, tint: const Color(0xFFE4EDFC));
      case 'email':
        return (label: 'Email account', icon: Icons.email_outlined, tint: const Color(0xFF36A8FA));
      default:
        return (label: 'Signed in', icon: Icons.verified_user_outlined, tint: const Color(0xFF36A8FA));
    }
  }
}

class _RewardsSection extends ConsumerWidget {
  const _RewardsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final text = Theme.of(context).textTheme;
    final econ = ref.watch(rewardedEconomyProvider);

    final adsToNext = econ.adsToNextMilestone;
    final progress = ((10 - adsToNext) / 10).clamp(0.0, 1.0);
    final hasPool = econ.bonusLivesPool > 0;

    return _SectionCard(
      label: 'REWARDS',
      accent: hasPool ? palette.iqGenius.first : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Badge(
                icon: econ.evilUnlocked
                    ? Icons.local_fire_department
                    : Icons.lock_outline,
                label: econ.evilUnlocked ? 'EVIL UNLOCKED' : 'EVIL LOCKED',
                tint: econ.evilUnlocked
                    ? const Color(0xFFE91E63)
                    : scheme.onSurfaceVariant,
                filled: econ.evilUnlocked,
              ),
              const Spacer(),
              if (hasPool)
                _Badge(
                  icon: Icons.favorite,
                  label: '${econ.bonusLivesPool} bonus lives',
                  tint: palette.lifeRed,
                  filled: true,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.play_circle_outline,
                  size: 22, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Loyalty progress',
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(palette.iqGenius.first),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adsToNext == 0
                          ? 'Reward ready!'
                          : '$adsToNext ad${adsToNext == 1 ? '' : 's'} to next +5 lives',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${econ.rewardedAdCount}',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.iqGenius.first,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.tint,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? tint.withValues(alpha: 0.18) : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled ? tint.withValues(alpha: 0.5) : scheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: filled ? tint : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.bestIqAsync, required this.topRanks});

  final AsyncValue<BestIqEntry?> bestIqAsync;
  final TopRankInfo topRanks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;

    final entry = bestIqAsync.asData?.value;
    final hasIq = entry != null;
    final hasTopRank = topRanks.hasAny;

    return _SectionCard(
      label: 'STATS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatRow(
            icon: Icons.psychology_outlined,
            label: 'Best IQ',
            value: hasIq ? '${entry.iq}' : '—',
            sub: hasIq ? 'on ${entry.tier.label}' : 'No puzzles solved yet',
            valueColor: hasIq && entry.iq >= 160 ? palette.iqGenius.first : scheme.primary,
          ),
          const Divider(height: 22),
          _StatRow(
            icon: Icons.emoji_events_outlined,
            label: 'Top rankings',
            value: hasTopRank ? '${topRanks.tiers.length}' : '0',
            sub: hasTopRank
                ? '#1 on ${_tiersLabel(topRanks.tiers)}'
                : 'Hold a tier to claim a crown',
            valueColor: hasTopRank ? palette.goldFrame.first : scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  static String _tiersLabel(List<Difficulty> tiers) {
    if (tiers.length == 1) return tiers.first.label;
    if (tiers.length == 2) return '${tiers[0].label} & ${tiers[1].label}';
    return tiers.map((t) => t.label).join(', ');
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: scheme.onSurfaceVariant, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: text.bodyMedium),
              Text(
                sub,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: text.headlineSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return OutlinedButton.icon(
      onPressed: () async {
        final repo = ref.read(authRepositoryProvider);
        await repo.signOut();
        if (context.mounted) context.go('/');
      },
      icon: const Icon(Icons.logout),
      label: const Text('Sign out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.lifeRed,
        side: BorderSide(color: palette.lifeRed.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 36),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
