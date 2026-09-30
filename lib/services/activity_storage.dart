import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_models.dart';

class ActivityStorage {
  static const _ticketsKey = 'oshilife_tickets_v1';
  static const _chekiSourcesKey = 'oshilife_cheki_sources_v1';
  static const _chekiPurchasesKey = 'oshilife_cheki_purchases_v1';
  static const _chekisKey = 'oshilife_chekis_v1';
  static const _talksKey = 'oshilife_talks_v1';
  static const _transactionsKey = 'oshilife_transactions_v1';
  static const _recurringTransactionsKey = 'oshilife_recurring_transactions_v1';

  static Future<List<TicketRecord>> loadTickets() async =>
      _loadList(_ticketsKey, TicketRecord.fromJson);

  static Future<List<ChekiSourcePhoto>> loadChekiSources() async =>
      _loadList(_chekiSourcesKey, ChekiSourcePhoto.fromJson);

  static Future<List<ChekiPurchase>> loadChekiPurchases() async =>
      _loadList(_chekiPurchasesKey, ChekiPurchase.fromJson);

  static Future<List<ChekiRecord>> loadChekis() async =>
      _loadList(_chekisKey, ChekiRecord.fromJson);

  static Future<List<TalkLog>> loadTalks() async =>
      _loadList(_talksKey, TalkLog.fromJson);

  static Future<List<OshiTransaction>> loadTransactions() async =>
      _loadList(_transactionsKey, OshiTransaction.fromJson);

  static Future<List<RecurringTransaction>> loadRecurringTransactions() async =>
      _loadList(_recurringTransactionsKey, RecurringTransaction.fromJson);

  static Future<void> saveTicket(TicketRecord ticket) async {
    final tickets = await loadTickets();
    _upsert(tickets, ticket, (value) => value.id);
    ticket.updatedAt = DateTime.now();
    await _saveList(_ticketsKey, tickets.map((e) => e.toJson()).toList());
    await _syncTicketTransaction(ticket);
  }

  static Future<void> deleteTicket(String ticketId) async {
    final tickets = await loadTickets();
    tickets.removeWhere((value) => value.id == ticketId);
    await _saveList(_ticketsKey, tickets.map((e) => e.toJson()).toList());

    final transactions = await loadTransactions();
    transactions.removeWhere(
      (value) => value.sourceType == 'ticket' && value.sourceId == ticketId,
    );
    await _saveList(
      _transactionsKey,
      transactions.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> saveChekiSource(ChekiSourcePhoto source) async {
    final values = await loadChekiSources();
    _upsert(values, source, (value) => value.id);
    await _saveList(_chekiSourcesKey, values.map((e) => e.toJson()).toList());
  }

  static Future<void> saveChekiPurchase(ChekiPurchase purchase) async {
    final values = await loadChekiPurchases();
    purchase.updatedAt = DateTime.now();
    _upsert(values, purchase, (value) => value.id);
    await _saveList(_chekiPurchasesKey, values.map((e) => e.toJson()).toList());
    await _syncChekiPurchaseTransaction(purchase);
  }

  static Future<void> deleteChekiPurchase(String purchaseId) async {
    final purchases = await loadChekiPurchases();
    purchases.removeWhere((value) => value.id == purchaseId);
    await _saveList(
      _chekiPurchasesKey,
      purchases.map((e) => e.toJson()).toList(),
    );

    final chekis = await loadChekis();
    chekis.removeWhere((value) => value.purchaseId == purchaseId);
    await _saveList(_chekisKey, chekis.map((e) => e.toJson()).toList());

    final transactions = await loadTransactions();
    transactions.removeWhere(
      (value) =>
          value.sourceType == 'cheki_purchase' && value.sourceId == purchaseId,
    );
    await _saveList(
      _transactionsKey,
      transactions.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> saveCheki(ChekiRecord cheki) async {
    final values = await loadChekis();
    cheki.updatedAt = DateTime.now();
    _upsert(values, cheki, (value) => value.id);
    await _saveList(_chekisKey, values.map((e) => e.toJson()).toList());
  }

  static Future<void> saveChekiBatch(List<ChekiRecord> records) async {
    final values = await loadChekis();
    for (final record in records) {
      _upsert(values, record, (value) => value.id);
    }
    await _saveList(_chekisKey, values.map((e) => e.toJson()).toList());
  }

  static Future<void> deleteChekiBatch(Set<String> ids) async {
    final values = await loadChekis();
    values.removeWhere((value) => ids.contains(value.id));
    await _saveList(_chekisKey, values.map((e) => e.toJson()).toList());
  }

  static Future<void> deleteCheki(String chekiId) async {
    final chekis = await loadChekis();
    chekis.removeWhere((value) => value.id == chekiId);
    await _saveList(_chekisKey, chekis.map((e) => e.toJson()).toList());

    final talks = await loadTalks();
    for (final talk in talks) {
      talk.chekiIds.removeWhere((id) => id == chekiId);
    }
    await _saveList(_talksKey, talks.map((e) => e.toJson()).toList());
  }

  static Future<void> saveTalk(TalkLog talk) async {
    final values = await loadTalks();
    talk.updatedAt = DateTime.now();
    _upsert(values, talk, (value) => value.id);
    await _saveList(_talksKey, values.map((e) => e.toJson()).toList());

    final chekis = await loadChekis();
    for (final cheki in chekis) {
      final shouldLink = talk.chekiIds.contains(cheki.id);
      final linked = cheki.talkLogIds.contains(talk.id);
      if (shouldLink && !linked) cheki.talkLogIds.add(talk.id);
      if (!shouldLink && linked) cheki.talkLogIds.remove(talk.id);
    }
    await _saveList(_chekisKey, chekis.map((e) => e.toJson()).toList());
  }

  static Future<void> deleteTalk(String talkId) async {
    final talks = await loadTalks();
    talks.removeWhere((value) => value.id == talkId);
    await _saveList(_talksKey, talks.map((e) => e.toJson()).toList());

    final chekis = await loadChekis();
    for (final cheki in chekis) {
      cheki.talkLogIds.removeWhere((id) => id == talkId);
    }
    await _saveList(_chekisKey, chekis.map((e) => e.toJson()).toList());
  }

  static Future<void> saveTransaction(OshiTransaction transaction) async {
    final values = await loadTransactions();
    transaction.updatedAt = DateTime.now();
    _upsert(values, transaction, (value) => value.id);
    await _saveList(_transactionsKey, values.map((e) => e.toJson()).toList());
  }

  static Future<void> deleteTransaction(String transactionId) async {
    final values = await loadTransactions();
    values.removeWhere((value) => value.id == transactionId);
    await _saveList(_transactionsKey, values.map((e) => e.toJson()).toList());
  }

  static Future<void> saveRecurringTransaction(
    RecurringTransaction recurring,
  ) async {
    final values = await loadRecurringTransactions();
    recurring.updatedAt = DateTime.now();
    _upsert(values, recurring, (value) => value.id);
    await _saveList(
      _recurringTransactionsKey,
      values.map((e) => e.toJson()).toList(),
    );
    await materializeRecurringTransactions();
  }

  static Future<void> deleteRecurringTransaction(String recurringId) async {
    final values = await loadRecurringTransactions();
    values.removeWhere((value) => value.id == recurringId);
    await _saveList(
      _recurringTransactionsKey,
      values.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> materializeRecurringTransactions({
    DateTime? through,
  }) async {
    final now = through ?? DateTime.now();
    final recurringValues = await loadRecurringTransactions();
    if (recurringValues.isEmpty) return;

    final transactions = await loadTransactions();
    final existingSourceIds = transactions
        .where((value) => value.sourceType == 'recurring')
        .map((value) => value.sourceId)
        .whereType<String>()
        .toSet();

    var changed = false;
    for (final recurring in recurringValues.where((value) => value.enabled)) {
      for (final occurrence in _recurringOccurrences(recurring, now)) {
        final sourceId =
            '${recurring.id}:${occurrence.year.toString().padLeft(4, '0')}-${occurrence.month.toString().padLeft(2, '0')}-${occurrence.day.toString().padLeft(2, '0')}';
        if (existingSourceIds.contains(sourceId)) continue;

        transactions.add(
          OshiTransaction(
            type: recurring.type,
            amount: recurring.amount,
            date: occurrence,
            category: recurring.category,
            memberNames: List<String>.from(recurring.memberNames),
            memo: recurring.memo.trim().isEmpty
                ? recurring.name
                : '${recurring.name}・${recurring.memo.trim()}',
            sourceType: 'recurring',
            sourceId: sourceId,
          ),
        );
        existingSourceIds.add(sourceId);
        changed = true;
      }
    }

    if (changed) {
      await _saveList(
        _transactionsKey,
        transactions.map((e) => e.toJson()).toList(),
      );
    }
  }

  static Iterable<DateTime> _recurringOccurrences(
    RecurringTransaction recurring,
    DateTime through,
  ) sync* {
    final start = DateTime(
      recurring.startDate.year,
      recurring.startDate.month,
      recurring.startDate.day,
    );
    final end = recurring.endDate == null
        ? DateTime(through.year, through.month, through.day)
        : DateTime(
            recurring.endDate!.year,
            recurring.endDate!.month,
            recurring.endDate!.day,
          ).isBefore(DateTime(through.year, through.month, through.day))
        ? DateTime(
            recurring.endDate!.year,
            recurring.endDate!.month,
            recurring.endDate!.day,
          )
        : DateTime(through.year, through.month, through.day);

    if (end.isBefore(start)) return;

    if (recurring.frequency == RecurringFrequency.yearly) {
      for (var year = start.year; year <= end.year; year++) {
        final month = recurring.monthOfYear ?? start.month;
        final occurrence = _safeDate(year, month, recurring.dayOfMonth);
        if (occurrence.isBefore(start) || occurrence.isAfter(end)) continue;
        yield occurrence;
      }
      return;
    }

    var year = start.year;
    var month = start.month;
    var guard = 0;
    while (guard < 240) {
      final occurrence = _safeDate(year, month, recurring.dayOfMonth);
      if (occurrence.isAfter(end)) break;
      if (!occurrence.isBefore(start)) yield occurrence;
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      guard++;
    }
  }

  static DateTime _safeDate(int year, int month, int requestedDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = requestedDay < 1
        ? 1
        : requestedDay > lastDay
        ? lastDay
        : requestedDay;
    return DateTime(year, month, day);
  }

  static Future<void> deleteEventData(String eventId) async {
    final tickets = await loadTickets();
    tickets.removeWhere((value) => value.eventId == eventId);
    await _saveList(_ticketsKey, tickets.map((e) => e.toJson()).toList());

    final sources = await loadChekiSources();
    sources.removeWhere((value) => value.eventId == eventId);
    await _saveList(_chekiSourcesKey, sources.map((e) => e.toJson()).toList());

    final purchases = await loadChekiPurchases();
    purchases.removeWhere((value) => value.eventId == eventId);
    await _saveList(
      _chekiPurchasesKey,
      purchases.map((e) => e.toJson()).toList(),
    );

    final chekis = await loadChekis();
    chekis.removeWhere((value) => value.eventId == eventId);
    await _saveList(_chekisKey, chekis.map((e) => e.toJson()).toList());

    final talks = await loadTalks();
    talks.removeWhere((value) => value.eventId == eventId);
    await _saveList(_talksKey, talks.map((e) => e.toJson()).toList());

    final transactions = await loadTransactions();
    for (final transaction in transactions) {
      transaction.eventAllocations.removeWhere(
        (allocation) => allocation.eventId == eventId,
      );
      if (transaction.eventId == eventId) {
        transaction.eventId = null;
      }
    }
    await _saveList(
      _transactionsKey,
      transactions.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> _syncTicketTransaction(TicketRecord ticket) async {
    final values = await loadTransactions();
    final expenseIndex = values.indexWhere(
      (value) =>
          value.sourceType == 'ticket' &&
          value.sourceId == ticket.id &&
          value.type == TransactionType.expense,
    );
    final refundIndex = values.indexWhere(
      (value) =>
          value.sourceType == 'ticket_refund' && value.sourceId == ticket.id,
    );

    if ((ticket.status == TicketStatus.paid ||
            ticket.status == TicketStatus.refunded) &&
        (ticket.amount ?? 0) > 0) {
      final expense = OshiTransaction(
        id: expenseIndex >= 0 ? values[expenseIndex].id : null,
        type: TransactionType.expense,
        amount: ticket.amount!,
        date: DateTime.now(),
        category: TransactionCategory.ticket,
        eventId: ticket.eventId,
        memo: ticket.serialNumber.trim().isEmpty
            ? 'チケット'
            : 'チケット ${ticket.serialNumber.trim()}',
        sourceType: 'ticket',
        sourceId: ticket.id,
        createdAt: expenseIndex >= 0
            ? values[expenseIndex].createdAt
            : DateTime.now(),
      );
      if (expenseIndex >= 0) {
        values[expenseIndex] = expense;
      } else {
        values.add(expense);
      }
    } else if (expenseIndex >= 0) {
      values.removeAt(expenseIndex);
    }

    final currentRefundIndex = values.indexWhere(
      (value) =>
          value.sourceType == 'ticket_refund' && value.sourceId == ticket.id,
    );
    if (ticket.status == TicketStatus.refunded && (ticket.amount ?? 0) > 0) {
      final refund = OshiTransaction(
        id: currentRefundIndex >= 0 ? values[currentRefundIndex].id : null,
        type: TransactionType.refund,
        amount: ticket.amount!,
        date: DateTime.now(),
        category: TransactionCategory.ticket,
        eventId: ticket.eventId,
        memo: 'チケット払戻',
        sourceType: 'ticket_refund',
        sourceId: ticket.id,
        createdAt: currentRefundIndex >= 0
            ? values[currentRefundIndex].createdAt
            : DateTime.now(),
      );
      if (currentRefundIndex >= 0) {
        values[currentRefundIndex] = refund;
      } else {
        values.add(refund);
      }
    } else if (refundIndex >= 0) {
      final idx = values.indexWhere(
        (value) =>
            value.sourceType == 'ticket_refund' && value.sourceId == ticket.id,
      );
      if (idx >= 0) values.removeAt(idx);
    }

    await _saveList(_transactionsKey, values.map((e) => e.toJson()).toList());
  }

  static Future<void> _syncChekiPurchaseTransaction(
    ChekiPurchase purchase,
  ) async {
    final values = await loadTransactions();
    final index = values.indexWhere(
      (value) =>
          value.sourceType == 'cheki_purchase' && value.sourceId == purchase.id,
    );

    if ((purchase.totalAmount ?? 0) <= 0) {
      if (index >= 0) values.removeAt(index);
    } else {
      final transaction = OshiTransaction(
        id: index >= 0 ? values[index].id : null,
        type: TransactionType.expense,
        amount: purchase.totalAmount!,
        date: purchase.purchasedAt ?? DateTime.now(),
        category: TransactionCategory.cheki,
        eventId: purchase.eventId,
        memo: 'チェキ ${purchase.quantity}枚',
        sourceType: 'cheki_purchase',
        sourceId: purchase.id,
        createdAt: index >= 0 ? values[index].createdAt : DateTime.now(),
      );
      if (index >= 0) {
        values[index] = transaction;
      } else {
        values.add(transaction);
      }
    }

    await _saveList(_transactionsKey, values.map((e) => e.toJson()).toList());
  }

  static Future<List<T>> _loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <T>[];
      return decoded
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  static Future<void> _saveList(
    String key,
    List<Map<String, dynamic>> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(key, jsonEncode(values));
    if (!saved) throw StateError('ローカル保存に失敗しました: $key');
  }

  static void _upsert<T>(
    List<T> values,
    T item,
    String Function(T value) idOf,
  ) {
    final index = values.indexWhere((value) => idOf(value) == idOf(item));
    if (index >= 0) {
      values[index] = item;
    } else {
      values.add(item);
    }
  }
}
