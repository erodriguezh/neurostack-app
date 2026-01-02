import 'package:neurostack/startup/startup_view_model.dart';

class AppLifecycleService {
  StartupViewModel? _startupViewModel;

  void attachStartupViewModel(StartupViewModel viewModel) {
    _startupViewModel = viewModel;
  }

  Future<void> restartApp() async {
    await _startupViewModel?.retryInitialization();
  }
}
