import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/home/home_view_model.dart';
import 'package:neurostack/core/utils/l10n/translate_extension.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel = HomeViewModel(
    notifyService: locator<NotifyService>(),
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MVVM Counter')),
      body: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: _viewModel.counter,
          builder: (context, count, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.translate.counter,
                  textAlign: TextAlign.center,
                  style: context.textStyles.standard,
                ),
                Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: context.textStyles.xxxl,
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _viewModel.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
