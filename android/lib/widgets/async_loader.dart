import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loadingText,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String? loadingText;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (loadingText != null) ...[
              const SizedBox(height: 12),
              Text(loadingText!),
            ],
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$error', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
