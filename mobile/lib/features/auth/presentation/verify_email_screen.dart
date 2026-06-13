import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const int _cooldownSeconds = 30;

  bool _isChecking = false;
  bool _isResending = false;
  String? _message;

  /// Seconds remaining in the resend cooldown (0 = button enabled).
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = _cooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          _resendCooldown = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (mounted) {
        setState(() => _message = 'Verification email sent. Check your inbox.');
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _message = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _iHaveVerified() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.reloadUser();
      final verified = repo.currentUser?.emailVerified ?? false;
      if (verified) {
        // authStateChanges does not re-fire on verification; invalidating the
        // provider re-subscribes and replays the refreshed user, which fires
        // the router's refreshListenable and re-runs the gate -> /home.
        ref.invalidate(authStateChangesProvider);
      } else if (mounted) {
        setState(() =>
            _message = 'Not verified yet. Tap the link in your email, then try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _message = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(authRepositoryProvider).currentUser?.email ?? '';
    final resendEnabled = !_isResending && _resendCooldown == 0;
    final resendLabel = _isResending
        ? 'Sending…'
        : _resendCooldown > 0
            ? 'Resend (${_resendCooldown}s)'
            : 'Resend email';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 72,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verify your email',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15151C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                email.isEmpty
                    ? 'We sent you a verification link. Open it, then come back here.'
                    : 'We sent a verification link to $email. Open it, then come back here.',
                style: const TextStyle(fontSize: 15, color: Color(0xFF5A5A66)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_message != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message!,
                    style: const TextStyle(
                      color: Color(0xFF15151C),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isChecking ? null : _iHaveVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "I've verified",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: resendEnabled ? _resend : null,
                child: Text(
                  resendLabel,
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: _signOut,
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: Color(0xFF5A5A66)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
