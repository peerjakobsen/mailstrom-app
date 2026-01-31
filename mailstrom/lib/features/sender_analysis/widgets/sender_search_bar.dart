import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sender_providers.dart';

class SenderSearchBar extends ConsumerStatefulWidget {
  const SenderSearchBar({super.key});

  @override
  ConsumerState<SenderSearchBar> createState() => _SenderSearchBarState();
}

class _SenderSearchBarState extends ConsumerState<SenderSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sort = ref.watch(senderSortProvider);
    final filter = ref.watch(senderFilterProvider);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search senders...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _controller.clear();
                              ref
                                  .read(senderSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      ref.read(senderSearchQueryProvider.notifier).state =
                          value;
                    });
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<SenderSort>(
                icon: const Icon(Icons.sort, size: 20),
                tooltip: 'Sort by',
                initialValue: sort,
                onSelected: (value) {
                  ref.read(senderSortProvider.notifier).state = value;
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: SenderSort.byCount,
                    child: Text('By count'),
                  ),
                  PopupMenuItem(
                    value: SenderSort.byName,
                    child: Text('By name'),
                  ),
                  PopupMenuItem(
                    value: SenderSort.byRecent,
                    child: Text('By most recent'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  ref,
                  label: 'All',
                  value: SenderFilter.all,
                  current: filter,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  ref,
                  label: 'Unsubscribed',
                  value: SenderFilter.unsubscribed,
                  current: filter,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  ref,
                  label: 'Not unsubscribed',
                  value: SenderFilter.notUnsubscribed,
                  current: filter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref, {
    required String label,
    required SenderFilter value,
    required SenderFilter current,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: current == value,
      onSelected: (_) {
        ref.read(senderFilterProvider.notifier).state = value;
      },
      visualDensity: VisualDensity.compact,
    );
  }
}
