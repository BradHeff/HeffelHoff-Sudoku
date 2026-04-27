import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../data/auth_repository.dart';
import '../data/profile_repository.dart';

/// Modal bottom sheet for sign-in / sign-up / guest / sign-out.
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const _AccountSheetBody(),
    ),
  );
}

class _AccountSheetBody extends ConsumerWidget {
  const _AccountSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: auth.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _ErrorView(message: '$e'),
          data: (user) => user == null
              ? const _SignInForm()
              : _SignedInView(user: user),
        ),
      ),
    );
  }
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      final usernameErr = ProfileRepository.validateUsername(username);
      if (usernameErr != null) {
        setState(() => _error = usernameErr);
        return;
      }
    }
    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'Enter an email and a password (≥6 chars).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_isSignUp) {
        final response = await auth.signUpWithEmail(email: email, password: password);
        final user = response.user;
        if (user != null) {
          try {
            await ref.read(profileRepositoryProvider).updateDisplayName(
                  userId: user.id,
                  name: username,
                );
          } catch (_) {
            // RLS may block the write before email confirmation; the
            // user can finish setting their username from the account
            // sheet once signed in.
          }
          ref.invalidate(currentProfileProvider);
        }
      } else {
        await auth.signInWithEmail(email: email, password: password);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _error = _humaniseAuthError(e.message));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _humaniseAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('email not confirmed')) {
      return 'Email not confirmed yet. While iterating, ask your '
          "admin to disable Authentication → Providers → Email → "
          '"Confirm email" in the Supabase dashboard, or use '
          '"Continue as guest" below.';
    }
    if (lower.contains('anonymous') && lower.contains('disabled')) {
      return 'Anonymous sign-in is disabled. Enable it at '
          'Authentication → Providers → Anonymous Sign-Ins in the '
          'Supabase dashboard.';
    }
    return raw;
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signInAnonymously();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _error = _humaniseAuthError(e.message));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isSignUp ? 'Create an account' : 'Sign in',
          style: text.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp
              ? 'Pick a username — it\'s what others see on the '
                  'leaderboard. Your email stays private.'
              : 'Save your IQ across devices and climb the leaderboard.',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_isSignUp) ...[
          TextField(
            controller: _usernameController,
            maxLength: 24,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'How others will know you',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
              counterText: '',
            ),
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
          enabled: !_busy,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outlined),
          ),
          enabled: !_busy,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: text.bodyMedium?.copyWith(color: scheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isSignUp ? 'Sign up' : 'Sign in'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _isSignUp = !_isSignUp),
          child: Text(
            _isSignUp
                ? 'Have an account? Sign in'
                : "New here? Create an account",
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Divider(color: scheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: text.labelSmall),
            ),
            Expanded(child: Divider(color: scheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _continueAsGuest,
          icon: const Icon(Icons.person_outline),
          label: const Text('Continue as guest'),
        ),
      ],
    );
  }
}

class _SignedInView extends ConsumerWidget {
  const _SignedInView({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final text = Theme.of(context).textTheme;
    final isAnonymous = user.isAnonymous == true;
    final profileAsync = ref.watch(currentProfileProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        profileAsync.when(
          loading: () => const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(height: 72),
          data: (profile) => Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.4),
                    blurRadius: 18,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: isAnonymous
                  ? Icon(Icons.person, color: scheme.onPrimaryContainer, size: 32)
                  : Text(
                      _initialFor(profile?.displayName),
                      style: text.headlineMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        profileAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text(
            'Could not load profile: $e',
            style: text.bodySmall?.copyWith(color: scheme.error),
            textAlign: TextAlign.center,
          ),
          data: (profile) => _UsernameEditor(
            user: user,
            profile: profile,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isAnonymous
              ? 'Your scores are local. Sign up to save them across devices.'
              : 'Your username is what others see on the leaderboard. '
                  'Your email stays private.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (isAnonymous)
          FilledButton.icon(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) Navigator.of(context).pop();
              if (context.mounted) showAccountSheet(context);
            },
            icon: const Icon(Icons.upgrade),
            label: const Text('Upgrade to a real account'),
          ),
        if (isAnonymous) const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final repo = ref.read(authRepositoryProvider);
            await repo.signOut();
            if (context.mounted) Navigator.of(context).pop();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.lifeRed,
            side: BorderSide(color: palette.lifeRed.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }

  static String _initialFor(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '?';
    return displayName.trim()[0].toUpperCase();
  }
}

/// Inline username editor. Auto-opens in edit mode on placeholder names.
class _UsernameEditor extends ConsumerStatefulWidget {
  const _UsernameEditor({required this.user, required this.profile});

  final User user;
  final Profile? profile;

  @override
  ConsumerState<_UsernameEditor> createState() => _UsernameEditorState();
}

class _UsernameEditorState extends ConsumerState<_UsernameEditor> {
  late final TextEditingController _controller;
  bool _editing = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final name = widget.profile?.displayName ?? '';
    _controller = TextEditingController(text: name);
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(placeholder ? 'Set a username' : 'Edit username'),
            style: TextButton.styleFrom(
              foregroundColor: placeholder ? scheme.primary : scheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
            hintText: 'How others will know you',
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
