import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/dynamic_l10n.dart';

/// Full-screen blocking overlay for critical async actions (purchase, signup, login...).
///
/// - Blocks taps using a [ModalBarrier]
/// - Blocks back navigation using [WillPopScope]
/// - Shows a spinner + localized status message
/// - After [timeout], can optionally show Retry/Back actions
class CriticalActionOverlay extends StatefulWidget {
  final bool visible;
  final String title;
  final String message;
  final Duration timeout;

  /// Optional override text shown after [timeout].
  final String? timeoutMessage;

  /// Optional override button labels (defaults come from l10n).
  final String? retryLabel;
  final String? cancelLabel;

  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  /// When true, shows Retry/Back actions immediately (if provided),
  /// instead of only after the timeout.
  final bool showActionsWhileProcessing;

  const CriticalActionOverlay({
    super.key,
    required this.visible,
    required this.title,
    required this.message,
    this.timeout = const Duration(seconds: 60),
    this.timeoutMessage,
    this.retryLabel,
    this.cancelLabel,
    this.onRetry,
    this.onCancel,
    this.showActionsWhileProcessing = false,
  });

  @override
  State<CriticalActionOverlay> createState() => _CriticalActionOverlayState();
}

class _CriticalActionOverlayState extends State<CriticalActionOverlay> {
  Timer? _timer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(CriticalActionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible ||
        oldWidget.timeout != widget.timeout) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    _timedOut = false;

    if (!widget.visible) {
      if (mounted) setState(() {});
      return;
    }

    _timer = Timer(widget.timeout, () {
      if (!mounted) return;
      setState(() => _timedOut = true);
    });

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final s = S.of(context)!;

    final hasActions = widget.onRetry != null || widget.onCancel != null;
    final showActions = hasActions && (widget.showActionsWhileProcessing || _timedOut);

    return WillPopScope(
      onWillPop: () async => false,
      child: Positioned.fill(
        child: Stack(
          children: [
            const ModalBarrier(dismissible: false, color: Colors.black54),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_timedOut) ...[
                          const SizedBox(height: 10),
                          Text(
                            (widget.timeoutMessage ?? '').trim().isNotEmpty
                                ? widget.timeoutMessage!.trim()
                                : s.processingTakingLongerMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (showActions) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (widget.onCancel != null)
                                OutlinedButton(
                                  onPressed: widget.onCancel,
                                  child: Text(
                                    (widget.cancelLabel ?? '').trim().isNotEmpty
                                        ? widget.cancelLabel!.trim()
                                        : s.back,
                                  ),
                                ),
                              if (widget.onRetry != null)
                                ElevatedButton(
                                  onPressed: widget.onRetry,
                                  child: Text(
                                    (widget.retryLabel ?? '').trim().isNotEmpty
                                        ? widget.retryLabel!.trim()
                                        : s.retry,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


