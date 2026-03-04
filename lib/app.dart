import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medlens_mobile/config/router.dart';
import 'package:medlens_mobile/config/theme.dart';
import 'package:medlens_mobile/features/history/bloc/history_bloc.dart';
import 'package:medlens_mobile/features/session/bloc/session_bloc.dart';
import 'package:medlens_mobile/features/summary/bloc/summary_bloc.dart';
import 'package:medlens_mobile/services/local_storage_service.dart';

/// Root application widget.
///
/// Wraps the app in [MultiBlocProvider] and configures
/// [MaterialApp.router] with MedLens theme and GoRouter.
class App extends StatelessWidget {
  const App({super.key, required this.storageService});

  final LocalStorageService storageService;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>(
          create: (_) => SessionBloc(),
        ),
        BlocProvider<SummaryBloc>(
          create: (_) => SummaryBloc(),
        ),
        BlocProvider<HistoryBloc>(
          create: (_) => HistoryBloc(storageService: storageService),
        ),
      ],
      child: MaterialApp.router(
        title: 'MedLens AI',
        debugShowCheckedModeBanner: false,
        theme: MedLensTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
