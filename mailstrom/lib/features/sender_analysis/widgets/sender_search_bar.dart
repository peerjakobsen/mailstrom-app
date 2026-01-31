import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/email_category.dart';
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
    final categoryFilter = ref.watch(senderCategoryFilterProvider);
    final unsubscribeReady = ref.watch(unsubscribeReadyModeProvider);
    final searchFocus = ref.watch(searchFocusProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
                  focusNode: searchFocus,
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
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<EmailCategory?>(
              initialValue: categoryFilter,
              onSelected: (value) {
                ref.read(senderCategoryFilterProvider.notifier).state = value;
              },
              itemBuilder: (context) => [
                const PopupMenuItem<EmailCategory?>(
                  value: null,
                  child: Text('All categories'),
                ),
                ...EmailCategory.values
                    .where((c) => c != EmailCategory.unknown)
                    .map(
                      (c) => PopupMenuItem<EmailCategory?>(
                        value: c,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c.displayName),
                          ],
                        ),
                      ),
                    ),
              ],
              child: Chip(
                avatar: categoryFilter != null
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: categoryFilter.color,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoryFilter?.displayName ?? 'All categories',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              avatar: Icon(
                Icons.unsubscribe_outlined,
                size: 16,
                color: unsubscribeReady
                    ? colorScheme.onError
                    : colorScheme.onSurfaceVariant,
              ),
              label: Text(
                'Unsubscribe Ready',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: unsubscribeReady ? FontWeight.w600 : null,
                  color: unsubscribeReady ? colorScheme.onError : null,
                ),
              ),
              selected: unsubscribeReady,
              selectedColor: colorScheme.error,
              onSelected: (_) {
                ref.read(unsubscribeReadyModeProvider.notifier).state = !unsubscribeReady;
              },
              visualDensity: VisualDensity.compact,
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
