import '../models/monitoring_models.dart';
import 'app_state.dart';

class MonitoringService {
  /// Column headers for the "Sensor logs" tab on the History Logs screen.
  static const List<String> sensorLogColumns = [
    'Time',
    'Parameter',
    'Recorded Value',
    'Status',
    'Action Taken',
  ];

  /// Column headers for the "Calibration logs" tab. Different shape from
  /// Sensor logs — a calibration event records what was adjusted and who
  /// performed it, not a raw reading.
  static const List<String> calibrationLogColumns = [
    'Time',
    'Parameter',
    'Calibration Type',
    'Adjustment',
    'Performed By',
    'Status',
  ];
  /// Powers the "Parameter Status" cards (pH / EC / Temperature).
  Future<List<ParameterStatus>> getParameterStatuses() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // TODO: replace with a real Supabase query against your readings table
    return [
      ParameterStatus(
        label: 'pH Level',
        currentValue: '5.8',
        unit: '',
        idealRange: '5.5 - 6.5',
        lastUpdated: '8:00AM',
      ),
      ParameterStatus(
        label: 'EC Level',
        currentValue: '5.8',
        unit: 'mS/cm',
        idealRange: '5.5 - 6.5',
        lastUpdated: '8:00AM',
      ),
      ParameterStatus(
        label: 'Temperature',
        currentValue: '5.8',
        unit: '°C',
        idealRange: '5.5 - 6.5',
        lastUpdated: '8:00AM',
      ),
    ];
  }

  /// Powers the "Latest Insight" card.
  Future<LatestInsight> getLatestInsight() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: replace with real prediction/insight data (e.g. from an ML
    // model output stored in Supabase, or computed server-side)
    return LatestInsight(
      warningTitle: 'pH Drift Warning',
      warningDetail: 'pH will drop below 5.5',
      expectedIn: 'Expected in 45 min',
      humidity: '78%',
      ecStatus: 'Stable',
    );
  }

  /// Powers the "pH Forecast Overview" / "EC Forecast Overview" charts on
  /// the dashboard, AND the bigger chart on the Forecasting screen —
  /// same method, same data, so both screens can never drift out of sync
  /// with each other.
  /// `parameter` is 'ph' or 'ec'.
  Future<List<ForecastPoint>> getForecastData(String parameter) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // TODO: replace with real historical + predicted data, e.g.:
    //   final past = await supabase.from('readings')...
    //   final predicted = await supabase.from('ml_predictions')...
    if (parameter == 'ph') {
      return [
        ForecastPoint(hour: -12, value: 7.2, isPredicted: false),
        ForecastPoint(hour: -8, value: 7.2, isPredicted: false),
        ForecastPoint(hour: -4, value: 6.9, isPredicted: false),
        ForecastPoint(hour: 0, value: 6.9, isPredicted: false),
        ForecastPoint(hour: 4, value: 6.9, isPredicted: true),
        ForecastPoint(hour: 8, value: 6.5, isPredicted: true),
        ForecastPoint(hour: 12, value: 6.5, isPredicted: true),
      ];
    }

    return [
      ForecastPoint(hour: -12, value: 6.0, isPredicted: false),
      ForecastPoint(hour: -8, value: 6.0, isPredicted: false),
      ForecastPoint(hour: -4, value: 5.7, isPredicted: false),
      ForecastPoint(hour: 0, value: 5.7, isPredicted: false),
      ForecastPoint(hour: 4, value: 5.7, isPredicted: true),
      ForecastPoint(hour: 8, value: 5.4, isPredicted: true),
      ForecastPoint(hour: 12, value: 5.4, isPredicted: true),
    ];
  }

  /// Powers the "Prediction Insights" panel on the Forecasting screen.
  /// `parameter` is 'ph' or 'ec'.
  Future<PredictionInsightDetail> getPredictionInsight(String parameter) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: replace with a real ML/prediction query, e.g.:
    //   final response = await supabase.from('ml_predictions')...
    if (parameter == 'ph') {
      return PredictionInsightDetail(
        statusLabel: 'pH Level',
        statusBadge: 'Warning',
        warningText: 'pH is expected to rise above safe levels in 45 minutes.',
        airHumidity: '75%',
        ecLevel: '5.8 mS/cm',
        calloutText:
            'High humidity is slowing evaporation, letting dissolved solids build up and push pH higher.',
        currentPh: 6.9,
        targetPh: 6.5,
        suggestedFixes: [
          '4.5 ml of pH down solution',
          '0.5 ml of A and B nutrient concentrate',
        ],
      );
    }

    return PredictionInsightDetail(
      statusLabel: 'EC Level',
      statusBadge: 'Normal',
      warningText: 'EC levels are stable and within the ideal range.',
      airHumidity: '75%',
      ecLevel: '5.8 mS/cm',
      calloutText: 'Nutrient concentration has remained steady over the last 12 hours.',
      currentPh: 5.8,
      targetPh: 6.0,
      suggestedFixes: ['No action needed right now.'],
    );
  }

  /// Powers the "Sensor logs" tab on the History Logs screen.
  Future<List<HistoryLogEntry>> getSensorLogs() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // TODO: replace with a real Supabase query against your readings
    // table, e.g.:
    //   final response = await supabase
    //       .from('sensor_readings')
    //       .select()
    //       .order('created_at', ascending: false)
    //       .limit(50);
    return [
      const HistoryLogEntry(['8:00 AM', 'pH', '6.5', 'Stable', 'Add pH up solution']),
      const HistoryLogEntry(['7:45 AM', 'EC', '5.8 mS/cm', 'Stable', 'None']),
      HistoryLogEntry(['7:30 AM', 'Temperature', formatTemperature(24.6), 'Stable', 'None']),
      const HistoryLogEntry(['7:15 AM', 'pH', '6.3', 'Warning', 'Monitor closely']),
      const HistoryLogEntry(['7:00 AM', 'EC', '5.9 mS/cm', 'Stable', 'None']),
      HistoryLogEntry(['6:45 AM', 'Temperature', formatTemperature(26.8), 'Critical', 'Alert sent to admin']),
      const HistoryLogEntry(['6:30 AM', 'pH', '6.6', 'Stable', 'None']),
      const HistoryLogEntry(['6:15 AM', 'EC', '5.7 mS/cm', 'Stable', 'None']),
    ];
  }

  /// Powers the "Calibration logs" tab on the History Logs screen.
  Future<List<HistoryLogEntry>> getCalibrationLogs() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // TODO: replace with a real Supabase query against your calibration
    // events table.
    return [
      const HistoryLogEntry(
          ['8:00 AM', 'pH', '2-Point Calibration', '+0.2', 'Auto-system', 'Success']),
      const HistoryLogEntry(
          ['Yesterday, 6:00 PM', 'EC', '1-Point Calibration', '-0.1 mS/cm', 'Alveus', 'Success']),
        HistoryLogEntry(
          ['2 days ago, 8:00 AM', 'Temperature', 'Sensor Reset', formatTemperature(0.0), 'Auto-system', 'Success']),
      const HistoryLogEntry(
          ['3 days ago, 8:00 AM', 'pH', '2-Point Calibration', '+0.1', 'Auto-system', 'Failed']),
    ];
  }
}
