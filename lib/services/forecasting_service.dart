import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecasting_models.dart';
import 'supabase_client.dart';

class ForecastingService {
  static const String backendApiUrl =
      'http://127.0.0.1:8000/api/predict/forecast';

  Future<List<ForecastingChartPoint>> getForecastChartData(
    String parameter, {
    required int selectedHours,
    double currentPh = 6.5,
    double currentEc = 1.5,
    double currentTemp = 24.0,
  }) async {
    try {
      final String table = parameter == 'ph' ? 'ph_readings' : 'ec_readings';
      final response = await supabase
          .from(table)
          .select('value, recorded_at')
          .order('recorded_at', ascending: false)
          .limit(12);

      List<ForecastingChartPoint> chartPoints = [];

      if (response.isNotEmpty) {
        final rows =
            List<Map<String, dynamic>>.from(response).reversed.toList();
        for (int i = 0; i < rows.length; i++) {
          double hoursAgo = (i - (rows.length - 1)).toDouble();
          chartPoints.add(
            ForecastingChartPoint(
              hour: hoursAgo,
              value: (rows[i]['value'] as num).toDouble(),
              isPredicted: false,
            ),
          );
        }
      }

      final double baselineVal = parameter == 'ph' ? currentPh : currentEc;

      final uri = Uri.parse(backendApiUrl).replace(queryParameters: {
        'parameter': parameter.toLowerCase(),
        'ph': currentPh.toString(),
        'ec': currentEc.toString(),
        'temp': currentTemp.toString(),
        'horizon': selectedHours.toString(),
      });

      final apiResponse = await http.get(uri);

      if (apiResponse.statusCode == 200) {
        final data = json.decode(apiResponse.body);
        final List predictions = data['predictions'];

        for (var pred in predictions) {
          chartPoints.add(
            ForecastingChartPoint(
              hour: (pred['hour'] as num).toDouble(),
              value: (pred['value'] as num).toDouble(),
              isPredicted: true,
            ),
          );
        }
        return chartPoints;
      } else {
        return _getFallbackChartData(parameter, selectedHours, baselineVal);
      }
    } catch (e) {
      final double baselineVal = parameter == 'ph' ? currentPh : currentEc;
      return _getFallbackChartData(parameter, selectedHours, baselineVal);
    }
  }

  Future<PredictionInsightDetail> getPredictionInsight(
    String parameter, {
    double currentPh = 6.5,
    double currentEc = 1.5,
    double currentTemp = 24.0,
    double? predictedPh,
    double? predictedEc,
  }) async {
    final insight = runFlutterDSS(
      parameter: parameter,
      currentPh: currentPh,
      currentEc: currentEc,
      currentTemp: currentTemp,
      predictedPh: predictedPh ?? currentPh,
      predictedEc: predictedEc ?? currentEc,
    );

    await saveForecastToSupabase(insight, parameter);
    return insight;
  }

  PredictionInsightDetail runFlutterDSS({
    required String parameter,
    required double currentPh,
    required double currentEc,
    required double currentTemp,
    required double predictedPh,
    required double predictedEc,
  }) {
    bool isPh = parameter == 'ph';

    bool isPhHigh = predictedPh > 6.5;
    bool isPhLow = predictedPh < 5.5;
    bool isEcHigh = predictedEc > 1.8;
    bool isEcLow = predictedEc < 1.2;

    double targetPh = 6.5;
    double targetEc = 1.5;

    String statusBadge = 'Normal';
    String warningText = '';
    List<String> fixes = [];

    if (isPhHigh && isEcHigh) {
      statusBadge = 'Critical';
      warningText =
          'pH and EC levels are both predicted to exceed optimal bounds.';
      fixes = [
        'Verify sensor readings and correct pH condition first.',
        'Reassess EC level before performing additional nutrient adjustments.'
      ];
    } else if (isPhLow && isEcHigh) {
      statusBadge = 'Critical';
      warningText = 'pH is predicted low while EC is predicted high.';
      fixes = [
        'Verify solution condition and adjust pH gradually.',
        'Evaluate whether water dilution is required to normalize EC.'
      ];
    } else if (isPhHigh && isEcLow) {
      statusBadge = 'Warning';
      warningText = 'pH is predicted high while EC is predicted low.';
      fixes = [
        'Correct pH condition using an appropriate pH-down solution.',
        'Review nutrient concentration before nutrient replenishment.'
      ];
    } else if (isPhLow && isEcLow) {
      statusBadge = 'Warning';
      warningText = 'Both pH and EC are predicted below optimal bounds.';
      fixes = [
        'Correct pH condition using an appropriate pH-up solution.',
        'Evaluate nutrient solution concentration and replenish as needed.'
      ];
    } else if (isPh && isPhHigh) {
      statusBadge = 'Warning';
      warningText = 'pH is expected to rise above safe levels within horizon.';
      double phDiff = (predictedPh - targetPh).abs();
      double suggestedMl = (phDiff * 10).clamp(1.0, 15.0);
      fixes = [
        '${suggestedMl.toStringAsFixed(1)} mL of pH down solution gradually.',
        'Verify with sensor measurement after application.'
      ];
    } else if (isPh && isPhLow) {
      statusBadge = 'Warning';
      warningText = 'pH is expected to drop below optimal bounds.';
      fixes = [
        'Gradual pH increase using an appropriate pH-up solution.',
        'Verify through sensor measurement.'
      ];
    } else if (!isPh && isEcHigh) {
      statusBadge = 'Warning';
      warningText = 'EC level is predicted above ideal concentration.';
      fixes = [
        'Gradual pH adjustment using an appropriate solution.',
        'Verify EC through sensor measurement.'
      ];
    } else if (!isPh && isEcLow) {
      statusBadge = 'Warning';
      warningText = 'EC level is expected to drop below ideal concentration.';
      fixes = [
        'Inspect nutrient solution strength.',
        'Replenish nutrients according to standard procedure.'
      ];
    } else {
      statusBadge = 'Normal';
      warningText = isPh
          ? 'pH levels are predicted to remain stable.'
          : 'EC levels are stable and within safe parameters.';
      fixes = ['No recommendation for now'];
    }

    String calloutText = '';
    if (currentTemp > 25.0 && isPhHigh) {
      calloutText =
          'High temperature (${currentTemp.toStringAsFixed(1)} °C) is accelerating chemical drift, pushing pH higher.';
    } else if (currentTemp > 25.0 && isEcHigh) {
      calloutText =
          'High temperature (${currentTemp.toStringAsFixed(1)} °C) is increasing evaporation rates, raising EC concentration.';
    } else if (isEcLow) {
      calloutText =
          'Active root uptake of mineral salts has depleted EC below optimal levels.';
    } else {
      calloutText =
          'Parameters are operating within balanced environmental thresholds.';
    }

    return PredictionInsightDetail(
      statusLabel: isPh ? 'pH Level' : 'EC Level',
      statusBadge: statusBadge,
      warningText: warningText,
      temperature: '${currentTemp.toStringAsFixed(1)} °C',
      ecLevel: isPh
          ? '${currentEc.toStringAsFixed(1)} mS/cm'
          : '${currentPh.toStringAsFixed(1)} pH',
      calloutText: calloutText,
      currentPh: isPh ? currentPh : currentEc,
      targetPh: isPh ? targetPh : targetEc,
      suggestedFixes: fixes,
    );
  }

  /// Saves applied fix to action_logs
  Future<void> saveActionLog({
    required String parameter,
    required String forecastCondition,
    required int horizonHours,
    required double currentPh,
    required double currentEc,
    required double currentTemp,
    required List<String> suggestedFixes,
  }) async {
    try {
      await supabase.from('action_logs').insert({
        'parameter': parameter,
        'forecast_condition': forecastCondition,
        'horizon_hours': horizonHours,
        'current_ph': currentPh,
        'current_ec': currentEc,
        'current_temp': currentTemp,
        'suggested_fixes': suggestedFixes,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to save action log: $e');
    }
  }

  /// Saves dismissed fix to dismissed_action_logs
  Future<void> saveDismissedActionLog({
    required String parameter,
    required String forecastCondition,
    required int horizonHours,
    required double currentPh,
    required double currentEc,
    required double currentTemp,
    required List<String> suggestedFixes,
  }) async {
    try {
      await supabase.from('dismissed_action_logs').insert({
        'parameter': parameter,
        'forecast_condition': forecastCondition,
        'horizon_hours': horizonHours,
        'current_ph': currentPh,
        'current_ec': currentEc,
        'current_temp': currentTemp,
        'suggested_fixes': suggestedFixes,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to save dismissed action log: $e');
    }
  }

  Future<void> saveForecastToSupabase(
    PredictionInsightDetail insight,
    String parameter,
  ) async {
    try {
      await supabase.from('forecast_logs').insert({
        'parameter': parameter,
        'status_badge': insight.statusBadge,
        'warning_text': insight.warningText,
        'temperature': insight.temperature,
        'ec_level': insight.ecLevel,
        'callout_text': insight.calloutText,
        'current_val': insight.currentPh,
        'target_val': insight.targetPh,
        'suggested_fixes': insight.suggestedFixes,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  List<ForecastingChartPoint> _getFallbackChartData(
      String parameter, int hours, double baselineVal) {
    double base = baselineVal;
    double step = hours / 3.0;
    return [
      ForecastingChartPoint(
          hour: -hours.toDouble(), value: base, isPredicted: false),
      ForecastingChartPoint(hour: 0, value: base, isPredicted: false),
      ForecastingChartPoint(hour: step, value: base + 0.1, isPredicted: true),
      ForecastingChartPoint(
          hour: step * 2, value: base + 0.2, isPredicted: true),
      ForecastingChartPoint(
          hour: hours.toDouble(), value: base + 0.3, isPredicted: true),
    ];
  }
}