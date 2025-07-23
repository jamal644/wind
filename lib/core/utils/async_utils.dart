/// A collection of utility functions for working with asynchronous code.
library async_utils;

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Runs a future without awaiting it, useful for fire-and-forget operations.
/// This helps avoid the 'unawaited_futures' lint warning.
void unawaitedFuture(Future<void> future) {
  // Intentionally not awaiting the future
  future.onError((error, stackTrace) {
    // Log any errors that occur in the unawaited future
    if (kDebugMode) {
      print('Error in unawaited future: $error');
      print('Stack trace: $stackTrace');
    }
  });
}

/// A simple wrapper for running a function with error handling.
Future<void> runWithErrorHandling(
  Future<void> Function() action, {
  String? errorMessage,
}) async {
  try {
    await action();
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print(errorMessage ?? 'Error in async operation: $e');
      print('Stack trace: $stackTrace');
    }
    rethrow;
  }
}

/// Signature for callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();

/// Debounces a function call
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
