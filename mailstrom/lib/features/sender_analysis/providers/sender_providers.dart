import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/models/email_category.dart';
import '../models/sender_group.dart';

enum SenderSort { byCount, byName, byRecent }

enum SenderFilter { all, unsubscribed, notUnsubscribed }

final senderFilterProvider = StateProvider<SenderFilter>((ref) => SenderFilter.all);

final senderCategoryFilterProvider = StateProvider<EmailCategory?>((ref) => null);

final unsubscribeReadyModeProvider = StateProvider<bool>((ref) => false);

final senderListProvider = StreamProvider<List<SenderTableData>>((ref) {
  return ref.watch(senderDaoProvider).watchAllSenders();
});

final selectedSenderProvider = StateProvider<String?>((ref) => null);

final senderSearchQueryProvider = StateProvider<String>((ref) => '');

final senderSortProvider = StateProvider<SenderSort>((ref) => SenderSort.byCount);

final searchFocusProvider = Provider<FocusNode>((ref) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
});

final senderSelectionProvider =
    StateNotifierProvider<SenderSelectionNotifier, Set<String>>(
  (ref) => SenderSelectionNotifier(),
);

class SenderSelectionNotifier extends StateNotifier<Set<String>> {
  SenderSelectionNotifier() : super({});

  void toggle(String email) {
    if (state.contains(email)) {
      state = {...state}..remove(email);
    } else {
      state = {...state, email};
    }
  }

  void selectAll(List<String> emails) {
    state = {...state, ...emails};
  }

  void selectByYear(List<SenderGroup> groups, int year) {
    final emails = groups
        .where((g) => g.mostRecentDate?.year == year)
        .expand((g) => g.senders.map((s) => s.email))
        .toList();
    state = {...state, ...emails};
  }

  void deselectAll(List<String> emails) {
    state = {...state}..removeAll(emails);
  }

  void clear() {
    state = {};
  }

  bool isSelected(String email) => state.contains(email);
}

final availableYearsProvider = Provider<AsyncValue<List<int>>>((ref) {
  final groupsAsync = ref.watch(filteredSenderListProvider);
  return groupsAsync.whenData((groups) {
    final years = <int>{};
    for (final group in groups) {
      if (group.mostRecentDate != null) {
        years.add(group.mostRecentDate!.year);
      }
    }
    return (years.toList()..sort()).reversed.toList();
  });
});

final filteredSenderListProvider =
    Provider<AsyncValue<List<SenderGroup>>>((ref) {
  final sendersAsync = ref.watch(senderListProvider);
  final query = ref.watch(senderSearchQueryProvider).toLowerCase();
  final sort = ref.watch(senderSortProvider);
  final filter = ref.watch(senderFilterProvider);
  final categoryFilter = ref.watch(senderCategoryFilterProvider);
  final unsubscribeReady = ref.watch(unsubscribeReadyModeProvider);

  return sendersAsync.whenData((senders) {
    var filtered = senders.where((s) {
      if (query.isEmpty) return true;
      return s.email.toLowerCase().contains(query) ||
          (s.displayName?.toLowerCase().contains(query) ?? false) ||
          s.domain.toLowerCase().contains(query);
    }).toList();

    // Apply unsubscribe filter
    switch (filter) {
      case SenderFilter.all:
        break;
      case SenderFilter.unsubscribed:
        filtered = filtered.where((s) => s.isUnsubscribed).toList();
      case SenderFilter.notUnsubscribed:
        filtered = filtered
            .where((s) => !s.isUnsubscribed && s.unsubscribeLink != null)
            .toList();
    }

    // Apply category filter
    if (categoryFilter != null) {
      filtered = filtered
          .where((s) => s.category == categoryFilter.name)
          .toList();
    }

    // Unsubscribe Ready: only newsletters with clickable unsubscribe links
    if (unsubscribeReady) {
      filtered = filtered
          .where((s) =>
              s.category == 'newsletter' &&
              s.unsubscribeLink != null &&
              !s.unsubscribeLink!.startsWith('mailto:'))
          .toList();
    }

    switch (sort) {
      case SenderSort.byCount:
        filtered.sort((a, b) => b.emailCount.compareTo(a.emailCount));
      case SenderSort.byName:
        filtered.sort((a, b) {
          final aName = a.displayName ?? a.email;
          final bName = b.displayName ?? b.email;
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
      case SenderSort.byRecent:
        filtered.sort((a, b) => b.mostRecent.compareTo(a.mostRecent));
    }

    // Group by domain
    final domainMap = <String, List<SenderTableData>>{};
    for (final sender in filtered) {
      domainMap.putIfAbsent(sender.domain, () => []).add(sender);
    }

    final groups = domainMap.entries
        .map((e) => SenderGroup(domain: e.key, senders: e.value))
        .toList();

    // Sort groups by total email count
    groups.sort((a, b) => b.totalEmails.compareTo(a.totalEmails));

    return groups;
  });
});
