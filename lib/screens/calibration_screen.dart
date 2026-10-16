import 'dart:async';
import 'package:flutter/material.dart';
import '../services/calibration_service.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_confirm_dialog.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => CalibrationScreenState();
}

class CalibrationScreenState extends State<CalibrationScreen> {
  final CalibrationService _service = CalibrationService();
  final TextEditingController _solutionTemp = TextEditingController();
  Timer? _poller;
  CalibrationSession? _session;
  List<CalibrationSample> _samples = const [];
  Map<String, Map<String, dynamic>> _points = const {};
  int? _armedAfterId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  @override
  void dispose() {
    _poller?.cancel();
    _solutionTemp.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOGIC (unchanged)
  // ---------------------------------------------------------------------------

  Future<void> _loadActive() async {
    try {
      final session = await _service.activeSession();
      if (!mounted) return;
      if (session != null) {
        final points = await _service.points(session.id);
        if (!mounted) return;
        setState(() {
          _session = session;
          _points = points;
        });
        _startPolling();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Calibration setup unavailable: $error');
      }
    }
  }

  Future<void> _begin(String parameter) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await _service.start(parameter);
      if (!mounted) return;
      setState(() {
        _session = session;
        _points = {};
        _samples = [];
        _armedAfterId = null;
      });
      _startPolling();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not start calibration: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poll();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    final session = _session;
    if (session == null) return;
    try {
      final samples = await _service.latestSamples(session.id);
      if (mounted && _session?.id == session.id) {
        setState(() => _samples = samples);
        if (!_busy &&
            _armedAfterId != null &&
            session.createdBy == _service.currentUserId &&
            _nextPoint != null &&
            _stability.stable &&
            (session.parameter != 'tds' || _validSolutionTemperature)) {
          unawaited(_capture());
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Live readings unavailable: $error');
      }
    }
  }

  String? get _nextPoint {
    final session = _session;
    if (session == null) return null;
    final labels = session.parameter == 'ph'
        ? const ['pH 7.00', 'pH 4.00']
        : const ['1413 µS/cm', '84 µS/cm'];
    for (final label in labels) {
      if (!_points.containsKey(label)) return label;
    }
    return null;
  }

  bool get _requiredPointsCaptured {
    final session = _session;
    if (session == null) return false;
    return session.parameter == 'ph'
        ? _points.containsKey('pH 7.00') && _points.containsKey('pH 4.00')
        : _points.containsKey('1413 µS/cm');
  }

  String? get _tdsVerification {
    final reference = (_points['1413 µS/cm']?['voltage'] as num?)?.toDouble();
    final check = (_points['84 µS/cm']?['voltage'] as num?)?.toDouble();
    if (reference == null || check == null) return null;

    double basePpm(double voltage) =>
        (133.42 * voltage * voltage * voltage -
            255.86 * voltage * voltage +
            857.39 * voltage) *
        0.5;

    final referencePpm = basePpm(reference);
    if (referencePpm <= 0) return null;

    final estimatedMicrosiemens = basePpm(check) * 707 / referencePpm * 2;
    return '84 µS/cm check: approximately ${estimatedMicrosiemens.toStringAsFixed(0)} µS/cm. Informational only; it does not adjust the coefficient.';
  }

  List<CalibrationSample> get _armedSamples => _armedAfterId == null
      ? const []
      : _samples.where((sample) => sample.id > _armedAfterId!).toList();

  CalibrationStability get _stability => CalibrationStability.evaluate(
        _armedSamples,
        parameter: _session?.parameter ?? 'ph',
      );

  bool get _validSolutionTemperature {
    final temperature = double.tryParse(_solutionTemp.text.trim());
    return temperature != null && temperature >= 24 && temperature <= 26;
  }

  void _armObservation(int sampleId) {
    if (_session?.parameter == 'tds' && !_validSolutionTemperature) {
      setState(() => _error =
          'Enter the measured solution temperature (24-26 °C) before observing. The DHT22 measures air only.');
      return;
    }
    setState(() {
      _armedAfterId = sampleId;
      _error = null;
    });
  }

  Future<void> _capture() async {
    final session = _session;
    final label = _nextPoint;
    if (session == null || label == null) return;

    double? temperature;
    if (session.parameter == 'tds') {
      temperature = double.tryParse(_solutionTemp.text.trim());
      if (temperature == null || temperature < 24 || temperature > 26) {
        setState(() => _error =
            'The TDS standard must be at 24-26 °C. Enter a measured solution temperature; the DHT22 measures air only.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _service.capture(
        session: session,
        label: label,
        expectedValue: label.startsWith('pH')
            ? (label == 'pH 7.00' ? 7 : 4)
            : (label == '1413 µS/cm' ? 1413 : 84),
        expectedUnit: session.parameter == 'ph' ? 'pH' : 'µS/cm',
        stability: _stability,
        solutionTemperatureC: temperature,
      );
      final points = await _service.points(session.id);
      if (!mounted) return;
      setState(() {
        _points = points;
      });
      _armedAfterId = null;
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not capture point: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;

    final returnedToReservoir = await AppConfirmDialog.show(
      context,
      title: 'Return probe to reservoir',
      message:
          'Rinse the probe and place it back in the reservoir before resuming monitoring. Calibration-solution readings must never become reservoir history.',
      cancelLabel: 'Not yet',
      confirmLabel: 'Probe returned',
    );

    if (returnedToReservoir != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _service.finish(session.id);
      _poller?.cancel();
      var applied = false;
      for (var attempt = 0; attempt < 5 && !applied; attempt++) {
        try {
          applied = await _service.latestCoefficientApplied();
        } catch (_) {}
        if (!applied) await Future.delayed(const Duration(seconds: 2));
      }

      if (mounted && !applied) {
        await AppConfirmDialog.show(
          context,
          title: 'Saved; awaiting ESP32',
          message:
              'The calibration points and coefficients were saved. The ESP32 has not reported applying the new version yet. Keep it online and check the Calibration log for Completed status.',
          confirmLabel: 'OK',
          cancelLabel: null,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not finish calibration: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final session = _session;
    if (session == null) return;

    final returnedToReservoir = await AppConfirmDialog.show(
      context,
      title: 'Cancel calibration?',
      message:
          'Rinse and return the probe to the reservoir first. Monitoring will resume after the settling delay.',
      cancelLabel: 'Not yet',
      confirmLabel: 'Probe returned; cancel',
    );

    if (returnedToReservoir != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.cancel(session.id);
      _poller?.cancel();
      if (mounted) Navigator.pop(context, false);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not cancel calibration: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Shown when the user tries to leave while a session is still running.
  Future<void> _confirmLeave() async {
    final leave = await AppConfirmDialog.show(
      context,
      title: 'Leave this page?',
      message:
          'Leaving this page does not end the session. Reopen it to resume or cancel calibration.',
      cancelLabel: 'Stay',
      confirmLabel: 'Leave',
    );

    if (leave == true && mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // UI-ONLY HELPERS
  // ---------------------------------------------------------------------------

  /// Display order of the points for the step tracker (UI only).
  List<String> get _stepLabels => _session?.parameter == 'tds'
      ? const ['1413 µS/cm', '84 µS/cm']
      : const ['pH 7.00', 'pH 4.00'];

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: 'Back',
          child: Material(
            color: AppColors.iconCircle,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              // maybePop respects PopScope, so this triggers _confirmLeave
              // when a session is active.
              onTap: () => Navigator.maybePop(context),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Guided sensor calibration',
            style: AppTextStyles.pageHeading,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: child,
    );
  }

    Widget _cardDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(height: 1, color: AppColors.cardBorder),
      );

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alertBorder),
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(color: AppColors.alertText),
      ),
    );
  }

  Widget _pickerButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentGreen,
          side: BorderSide(color: AppColors.accentGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: AppTextStyles.button.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Small pill used for operator / device / probe info under the header.
  Widget _chip(String label, String value, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.statusCardGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: highlighted ? null : Border.all(color: AppColors.cardBorder),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (label.isNotEmpty)
              TextSpan(text: '$label ', style: AppTextStyles.cardMeta),
            TextSpan(
              text: value,
              style: AppTextStyles.bodyBold.copyWith(
                fontSize: 12.5,
                color: highlighted
                    ? AppColors.primaryButton
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCircle({
    required int number,
    required bool done,
    required bool current,
  }) {
    if (done) {
      return Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: AppColors.primaryButton,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
      );
    }
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: current ? Colors.white : AppColors.calloutBackground,
        shape: BoxShape.circle,
        border: current
            ? Border.all(color: AppColors.primaryButton, width: 2)
            : null,
      ),
      child: Text(
        '$number',
        style: AppTextStyles.bodyBold.copyWith(
          fontSize: 14,
          color: current ? AppColors.primaryButton : AppColors.textSecondary,
        ),
      ),
    );
  }

  /// "1 pH 7.00 ——— 2 pH 4.00" progress row. Captured steps show their voltage.
  Widget _stepTracker() {
    final labels = _stepLabels;
    final current = _nextPoint;
    final isTds = _session?.parameter == 'tds';

    Widget item(int i) {
      final name = labels[i];
      final point = _points[name];
      final done = point != null;
      final isCurrent = !done && name == current;
      final optional = isTds && i == 1;

      final String sub;
      if (done) {
        sub = '${(point['voltage'] as num).toStringAsFixed(4)} V';
      } else if (isCurrent) {
        sub = optional ? 'Optional check' : 'Current step';
      } else {
        sub = optional ? 'Optional' : 'Up next';
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepCircle(number: i + 1, done: done, current: isCurrent),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 13.5,
                    color: (done || isCurrent)
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  sub,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardMeta.copyWith(
                    fontSize: 11.5,
                    color: done
                        ? AppColors.primaryButton
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final firstDone = _points.containsKey(labels[0]);

    return Row(
      children: [
        Flexible(child: item(0)),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: firstDone ? AppColors.primaryButton : AppColors.cardBorder,
          ),
        ),
        Flexible(child: item(1)),
      ],
    );
  }

  /// Big live voltage with a status badge (idle / observing / stable).
  Widget _readingTile(CalibrationSample? latest) {
    final armed = _armedAfterId != null;
    final stable = armed && _stability.stable;

    final Color background = !armed
        ? AppColors.calloutBackground
        : stable
            ? AppColors.statusCardGreen
            : AppColors.statusCardYellow;
    final String badge = !armed
        ? 'Not observing this point yet'
        : stable
            ? 'Stable, capturing'
            : 'Observing';
    final Color badgeColor =
        stable ? AppColors.primaryButton : Colors.orange.shade800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Latest raw voltage', style: AppTextStyles.cardMeta),
              const SizedBox(height: 2),
              if (latest == null)
                Text(
                  'Waiting for ESP32 calibration samples...',
                  style: AppTextStyles.body,
                )
              else
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: latest.voltage.toStringAsFixed(4),
                        style: AppTextStyles.pageHeading
                            .copyWith(fontSize: 26),
                      ),
                      TextSpan(text: ' V', style: AppTextStyles.cardMeta),
                    ],
                  ),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: AppTextStyles.cardMeta.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Finish + Cancel, grouped at the bottom of the main card.
  Widget _actionRow({
    required CalibrationSession session,
    required String? label,
    required bool ownSession,
    required bool canCancel,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        ElevatedButton(
          onPressed: !ownSession || _busy || !_requiredPointsCaptured
              ? null
              : _finish,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            session.parameter == 'tds' && label == '84 µS/cm'
                ? 'Finish (skip optional 84 check)'
                : 'Finish calibration',
            style: AppTextStyles.button.copyWith(fontSize: 13),
          ),
        ),
        OutlinedButton(
          onPressed: !canCancel || _busy ? null : _cancel,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primaryButton),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'Cancel calibration',
            style: AppTextStyles.button.copyWith(
              fontSize: 13,
              color: AppColors.primaryButton,
            ),
          ),
        ),
      ],
    );
  }

  /// One gray note replacing the two footnotes that used to sit at the bottom.
  Widget _infoNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.calloutBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Before finishing, rinse and return the probe to the reservoir. Monitoring resumes after a settling delay and fresh samples. Leaving this page does not end the session. Reopen it to resume or cancel.',
              style: AppTextStyles.bodySmall.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final ownSession = session?.createdBy == _service.currentUserId;
    final canCancel = ownSession || (appProfile.value?.isAdmin ?? false);
    final label = _nextPoint;
    final latest = _samples.isEmpty ? null : _samples.last;
    final armed = _armedAfterId != null;

    // Same enable rule as before: own session, not busy, a sample available.
    final VoidCallback? onStartObserving =
        (!ownSession || _busy || latest == null)
            ? null
            : () => _armObservation(latest.id);

    return PopScope(
      // With no active session there is nothing to warn about, so leave freely.
      canPop: session == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _header(context),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    _errorBanner(_error!),
                    const SizedBox(height: 12),
                  ],

                  // ---------------- No session yet: probe picker ----------------
                  if (session == null)
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a probe to calibrate',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The ESP32 will pause all normal five-minute uploads until this session ends.',
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: 20),
                          _pickerButton(
                            icon: Icons.science_rounded,
                            label: 'Calibrate pH (7.00 then 4.00)',
                            onPressed: _busy ? null : () => _begin('ph'),
                          ),
                          const SizedBox(height: 12),
                          _pickerButton(
                            icon: Icons.water_drop_rounded,
                            label: 'Calibrate Gravity TDS (1413 µS/cm)',
                            onPressed: _busy ? null : () => _begin('tds'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'The 84 µS/cm solution is an optional check, not a coefficient-setting point until the exact Gravity module is confirmed.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    )

                  // ---------------- Active session ----------------
                  else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('Operator', session.operatorName),
                        _chip('Device', 'hydroponic-esp32'),
                        _chip(
                          '',
                          session.parameter == 'ph'
                              ? 'pH probe'
                              : 'Gravity TDS probe',
                          highlighted: true,
                        ),
                      ],
                    ),
                    if (!ownSession) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusCardYellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Another operator started this session. Only they can capture or finish points; an admin can cancel an abandoned session.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepTracker(),
                          if (_tdsVerification != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _tdsVerification!,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                          _cardDivider(),

                          if (label != null) ...[
                            Text(
                              label == '84 µS/cm'
                                  ? 'Optional verification: $label'
                                  : 'Next standard: $label',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _points.isEmpty
                                  ? 'Rinse the probe, place it in a fresh portion of the labelled solution, and gently stir. Then start observing.'
                                  : 'Rinse between solutions. Ignore readings in rinse water and while moving the probe. Place it in the new standard, then start observing.',
                              style: AppTextStyles.body.copyWith(height: 1.45),
                            ),
                            if (session.parameter == 'tds') ...[
                              const SizedBox(height: 14),
                              TextField(
                                controller: _solutionTemp,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  labelText:
                                      'Measured solution temperature (°C)',
                                  helperText:
                                      'DHT22 air temperature cannot be used',
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _readingTile(latest),
                            if (armed) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${_stability.reason} Stable readings are captured automatically.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _stability.stable
                                      ? AppColors.primaryButton
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: armed
                                  ? OutlinedButton(
                                      onPressed: onStartObserving,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: AppColors.primaryButton,
                                            width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: Text(
                                        'Restart observing',
                                        style: AppTextStyles.button.copyWith(
                                          color: AppColors.primaryButton,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: onStartObserving,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryButton,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: Text(
                                        'Probe in solution — start observing',
                                        style: AppTextStyles.button
                                            .copyWith(fontSize: 14),
                                      ),
                                    ),
                            ),
                          ] else ...[
                            // Every point (including the optional one) captured.
                            Text(
                              'All points captured',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rinse the probe and place it back in the reservoir, then finish the calibration.',
                              style: AppTextStyles.body.copyWith(height: 1.45),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.statusCardGreen,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Ready to finish',
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 18,
                                  color: AppColors.primaryButton,
                                ),
                              ),
                            ),
                          ],

                          _cardDivider(),
                          _actionRow(
                            session: session,
                            label: label,
                            ownSession: ownSession,
                            canCancel: canCancel,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoNote(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}