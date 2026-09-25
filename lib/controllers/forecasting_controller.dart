import 'package:flutter/material.dart';
import '../models/monitoring_models.dart';
import '../services/monitoring_service.dart';
import '../services/user_service.dart';
import '../services/app_state.dart';
import '../services/supabase_client.dart';

class ForecastingController extends ChangeNotifier {
  final MonitoringService _monitoringService = MonitoringService();
  final UserService _userService = UserService();

  bool isLoading = true;
  String? errorMessage;

  UserProfile? profile;

  String selectedTab = 'pH Forecast';
  int selectedHours = 12; // 6, 12, or 24

  List<ForecastPoint> chartPoints = [];
  PredictionInsightDetail? insightDetail;

  ForecastingController() {
    loadData();
  }

  String get _parameterKey => selectedTab.startsWith('pH') ? 'ph' : 'ec';

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _userService.getProfile(
          supabaseClient?.auth.currentUser?.id ??
              appProfile.value?.id ??
              'mock-user-id',
        ),
        _monitoringService.getForecastData(_parameterKey),
        _monitoringService.getPredictionInsight(_parameterKey),
      ]);

      profile = results[0] as UserProfile;
      chartPoints = results[1] as List<ForecastPoint>;
      insightDetail = results[2] as PredictionInsightDetail;
    } catch (e) {
      errorMessage = 'Failed to load forecasting data';
    }

    isLoading = false;
    notifyListeners();
  }

  void selectTab(String tab) {
    if (selectedTab == tab) return;
    selectedTab = tab;
    loadData();
  }

  void selectHours(int hours) {
    selectedHours = hours;
    notifyListeners();
  }
}
