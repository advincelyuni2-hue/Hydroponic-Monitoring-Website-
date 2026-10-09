import 'dart:async';

import 'package:flutter/material.dart';
import '../services/calibration_service.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
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
      if (mounted) setState(() => _error = 'Live readings unavailable: $error');
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
          'Enter the measured solution temperature (24–26 °C) before observing. The DHT22 measures air only.');
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
            'The TDS standard must be at 24–26 °C. Enter a measured solution temperature; the DHT22 measures air only.');
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
        _armedAfterId = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not capture point: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;
    final returnedToReservoir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Return probe to reservoir'),
        content: const Text(
          'Rinse the probe and place it back in the reservoir before resuming monitoring. Calibration-solution readings must never become reservoir history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Probe returned'),
          ),
        ],
      ),
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
        } catch (_) {
          // The session is already saved; an acknowledgement read failure is
          // reported as pending, not as a failed calibration.
        }
        if (!applied) await Future.delayed(const Duration(seconds: 2));
      }
      if (mounted && !applied) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Saved; awaiting ESP32'),
            content: const Text(
              'The calibration points and coefficients were saved. The ESP32 has not reported applying the new version yet. Keep it online and check the Calibration log for Completed status.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
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
    final returnedToReservoir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel calibration?'),
        content: const Text(
          'Rinse and return the probe to the reservoir first. Monitoring will resume after the settling delay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Probe returned; cancel'),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final ownSession = session?.createdBy == _service.currentUserId;
    final canCancel = ownSession || (appProfile.value?.isAdmin ?? false);
    final label = _nextPoint;
    final latest = _samples.isEmpty ? null : _samples.last;
    return Scaffold(
      appBar: AppBar(title: const Text('Guided sensor calibration')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!,
                        style: TextStyle(color: Colors.red.shade800)),
                  ),
                ),
              if (session == null) ...[
                const Text(
                    'Select a probe to calibrate. The ESP32 will pause all normal five-minute uploads until this session ends.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : () => _begin('ph'),
                  child: const Text('Calibrate pH (7.00 then 4.00)'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _busy ? null : () => _begin('tds'),
                  child: const Text('Calibrate Gravity TDS (1413 µS/cm)'),
                ),
                const SizedBox(height: 16),
                const Text(
                    'The 84 µS/cm solution is an optional check, not a coefficient-setting point until the exact Gravity module is confirmed.'),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Operator: ${session.operatorName}',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                            'Device: hydroponic-esp32 • ${session.parameter == 'ph' ? 'pH probe' : 'Gravity TDS probe'}'),
                        if (!ownSession)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                                'Another operator started this session. Only they can capture or finish points; an admin can cancel an abandoned session.'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (label != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              label == '84 µS/cm'
                                  ? 'Optional verification: $label'
                                  : 'Next standard: $label',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 10),
                          Text(_points.isEmpty
                              ? 'Rinse the probe, place it in a fresh portion of the labelled solution, and gently stir. Then start observing.'
                              : 'Rinse between solutions. Ignore readings in rinse water and while moving the probe. Place it in the new standard, then start observing.'),
                          if (session.parameter == 'tds') ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _solutionTemp,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText:
                                      'Measured solution temperature (°C)',
                                  helperText:
                                      'DHT22 air temperature cannot be used'),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(latest == null
                              ? 'Waiting for ESP32 calibration samples…'
                              : 'Latest raw voltage: ${latest.voltage.toStringAsFixed(4)} V'),
                          const SizedBox(height: 6),
                          Text(
                              _armedAfterId == null
                                  ? 'Not observing this point yet'
                                  : '${_stability.reason} Stable readings are captured automatically.',
                              style: TextStyle(
                                  color: _stability.stable
                                      ? AppColors.primaryButton
                                      : Colors.orange.shade800)),
                          const SizedBox(height: 14),
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            OutlinedButton(
                              onPressed: !ownSession || _busy || latest == null
                                  ? null
                                  : () => _armObservation(latest.id),
                              child: const Text(
                                  'Probe in solution — start observing'),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                if (_points.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Captured points',
                              style: Theme.of(context).textTheme.titleMedium),
                          for (final point in _points.entries)
                            Text(
                                '${point.key}: ${(point.value['voltage'] as num).toStringAsFixed(4)} V'),
                          if (_tdsVerification != null) Text(_tdsVerification!),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  ElevatedButton(
                    onPressed: !ownSession || _busy || !_requiredPointsCaptured
                        ? null
                        : _finish,
                    child: Text(
                        session.parameter == 'tds' && label == '84 µS/cm'
                            ? 'Finish (skip optional 84 check)'
                            : 'Finish calibration'),
                  ),
                  TextButton(
                    onPressed: !canCancel || _busy ? null : _cancel,
                    child: const Text('Cancel calibration'),
                  ),
                ]),
                const SizedBox(height: 14),
                const Text(
                    'Before finishing, rinse and return the probe to the reservoir. Monitoring resumes after a settling delay and fresh samples.'),
                const SizedBox(height: 8),
                const Text(
                    'Leaving this page does not end the session. Reopen it to resume or cancel calibration.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
