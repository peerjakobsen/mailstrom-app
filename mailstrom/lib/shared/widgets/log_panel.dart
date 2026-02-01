import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/log_service.dart';

class LogPanel extends ConsumerStatefulWidget {
  const LogPanel({super.key});

  @override
  ConsumerState<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends ConsumerState<LogPanel> {
  double _height = 200;
  static const _minHeight = 100.0;
  static const _maxHeight = 400.0;

  final _scrollController = ScrollController();
  int _lastLogCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Auto-scroll when new entries arrive
    if (logs.length > _lastLogCount) {
      _lastLogCount = logs.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        MouseRegion(
          cursor: SystemMouseCursors.resizeRow,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              setState(() {
                _height = (_height - details.delta.dy)
                    .clamp(_minHeight, _maxHeight);
              });
            },
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Header
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              Text(
                'Logs (${logs.length})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              _HeaderButton(
                icon: Icons.delete_sweep_outlined,
                tooltip: 'Clear logs',
                onPressed: () {
                  ref.read(logNotifierProvider.notifier).clear();
                  _lastLogCount = 0;
                },
              ),
              _HeaderButton(
                icon: Icons.close,
                tooltip: 'Close logs',
                onPressed: () {
                  ref.read(logPanelVisibleProvider.notifier).state = false;
                },
              ),
            ],
          ),
        ),
        // Log list
        SizedBox(
          height: _height - 40, // subtract header + drag handle
          child: ColoredBox(
            color: colorScheme.surfaceContainerLow,
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'No log entries yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: logs.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemBuilder: (context, index) {
                      final entry = logs[index];
                      return _LogEntryRow(entry: entry);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        icon: Icon(icon, size: 16),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _LogEntryRow extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time = entry.timestamp;
    final timeStr = '${_pad(time.hour)}:${_pad(time.minute)}:'
        '${_pad(time.second)}.${_pad3(time.millisecond)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          // Level badge
          _LevelBadge(level: entry.level),
          const SizedBox(width: 8),
          // Source tag
          if (entry.source != null) ...[
            Text(
              '[${entry.source}]',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
          ],
          // Message
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: entry.level == LogLevel.error
                    ? colorScheme.error
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String _pad3(int n) => n.toString().padLeft(3, '0');
}

class _LevelBadge extends StatelessWidget {
  final LogLevel level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      LogLevel.info => ('INF', Colors.blue),
      LogLevel.warning => ('WRN', Colors.orange),
      LogLevel.error => ('ERR', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          color: color,
        ),
      ),
    );
  }
}
