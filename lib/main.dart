import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/app_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler — catches unhandled platform-layer errors.
  // In production this is where a Crashlytics / Sentry hook would live.
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'Unhandled platform error: $error',
      name: 'global_error',
      error: error,
      stackTrace: stack,
    );
    // Return true to mark the error as handled and suppress Flutter's default
    // red-screen overlay in release builds.
    return true;
  };

  // Catch synchronous Flutter framework errors (widget build failures, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log(
      'Flutter framework error: ${details.exceptionAsString()}',
      name: 'flutter_error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runApp(const ProviderScope(child: AppBootstrap()));
}
