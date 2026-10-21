import 'app_confirm_dialog.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_client.dart';

class IdleSessionGuard extends StatefulWidget {
  const IdleSessionGuard({
    super.key,
    required this.child,
    required this.onTimeout,
  });

  final Widget child;
  final Future<void> Function() onTimeout;

  static const Duration idleTimeout = Duration(minutes: 10);
  static const Duration warningLeadTime = Duration(minutes: 1);

  @override
  State<IdleSessionGuard> createState() => _IdleSessionGuardState();
}

class _IdleSessionGuardState extends State<IdleSessionGuard> {
  StreamSubscription? _authSubscription;
  Timer? _warningTimer;
  Timer? _countdownTimer;
  DateTime? _warningDeadline;

  bool _isAuthenticated = false;
  bool _showWarning = false;
  bool _loggingOut = false;
  int _secondsRemaining = IdleSessionGuard.warningLeadTime.inSeconds;

  @override
  void initState() {
    super.initState();

    _isAuthenticated = supabaseClient?.auth.currentSession != null;

    _authSubscription = supabaseClient?.auth.onAuthStateChange.listen((_) {
      _syncAuthenticationState();
    });

    if (_isAuthenticated) {
      _armIdleTimer();
    }
  }

  void _syncAuthenticationState() {
    if (!mounted) return;

    final authenticated = supabaseClient?.auth.currentSession != null;
    if (authenticated == _isAuthenticated) return;

    setState(() {
      _isAuthenticated = authenticated;
      _showWarning = false;
    });

    if (authenticated) {
      _armIdleTimer();
    } else {
      _cancelTimers();
    }
  }

  void _recordActivity() {
    if (!_isAuthenticated || _showWarning || _loggingOut) return;
    _armIdleTimer();
  }

  void _armIdleTimer() {
    _cancelTimers();
    _warningDeadline = null;
    _loggingOut = false;

    if (!_isAuthenticated) return;

    final warningDelay =
        IdleSessionGuard.idleTimeout - IdleSessionGuard.warningLeadTime;

    _warningTimer = Timer(warningDelay, _showIdleWarning);
  }

  void _showIdleWarning() {
    if (!mounted || !_isAuthenticated) return;

    _warningDeadline = DateTime.now().add(IdleSessionGuard.warningLeadTime);

    setState(() {
      _showWarning = true;
      _secondsRemaining = IdleSessionGuard.warningLeadTime.inSeconds;
    });

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );

    _updateCountdown();
  }

  void _updateCountdown() {
    if (!mounted || !_showWarning || _warningDeadline == null) return;

    final remainingMs =
        _warningDeadline!.difference(DateTime.now()).inMilliseconds;

    if (remainingMs <= 0) {
      _countdownTimer?.cancel();
      unawaited(_expireSession());
      return;
    }

    setState(() {
      _secondsRemaining = (remainingMs + 999) ~/ 1000;
    });
  }

  void _staySignedIn() {
    if (!mounted) return;

    setState(() {
      _showWarning = false;
    });

    _armIdleTimer();
  }

  Future<void> _expireSession() async {
    if (_loggingOut) return;

    _loggingOut = true;
    _cancelTimers();

    try {
      await widget.onTimeout();
    } catch (_) {
      // The timeout callback still navigates to Login if sign-out errors.
    }

    if (!mounted) return;

    setState(() {
      _isAuthenticated = false;
      _showWarning = false;
      _loggingOut = false;
    });
  }

  void _cancelTimers() {
    _warningTimer?.cancel();
    _warningTimer = null;

    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _recordActivity();
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _cancelTimers();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _recordActivity(),
      onPointerMove: (_) => _recordActivity(),
      onPointerSignal: (_) => _recordActivity(),
      child: Focus(
        onKeyEvent: _onKeyEvent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_showWarning)
              Positioned.fill(
                child: Material(
                  color: Colors.black54,
                  child: Center(
                    child: AppConfirmDialog(
                      title: 'Still there?',
                      message: 'You will be signed out due to inactivity in '
                          '$_secondsRemaining seconds.',
                      confirmLabel: 'Stay signed in',
                      cancelLabel: null,
                      onConfirm: _staySignedIn,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
