import 'dart:convert';

import 'package:katya/cache/index.dart';
import 'package:katya/context/types.dart';
import 'package:katya/global/libs/storage/secure-storage.dart';
import 'package:katya/global/print.dart';
import 'package:katya/global/values.dart';
import 'package:katya/storage/index.dart';

const ALL_APP_CONTEXT_KEY = '${Values.appLabel}@app-context-all';
const CURRENT_APP_CONTEXT_KEY = '${Values.appLabel}@app-context-current';

Future<AppContext> findContext(String contextId) async {
  final all = await loadContextsAll();

  return all.firstWhere((e) => e.id == contextId, orElse: () => AppContext());
}

Future saveContextCurrent(AppContext? current) async {
  if (current == null) return;

  SecureStorage().write(key: CURRENT_APP_CONTEXT_KEY, value: json.encode(current));
}

Future saveContextsAll(List<AppContext>? all) async {
  if (all == null) return;

  await SecureStorage().write(key: ALL_APP_CONTEXT_KEY, value: json.encode(all));
}

Future saveContext(AppContext? current) async {
  if (current == null) return;

  final allContexts = await loadContextsAll();
  final position = allContexts.indexWhere((c) => c.id == current.id);

  // both saves new or effectively updates existing
  if (position == -1) {
    allContexts.add(current);
  } else {
    allContexts.removeAt(position);
    allContexts.insert(0, current);
  }

  // TODO: handle setting current context external to saveContext
  await saveContextCurrent(current);

  return saveContextsAll(allContexts);
}

Future<AppContext> loadContextCurrent() async {
  try {
    final contextJson = await SecureStorage().read(key: CURRENT_APP_CONTEXT_KEY);
    final currentContext = AppContext.fromJson(await json.decode(contextJson!));

    return currentContext;
  } catch (error) {
    log.error('[loadCurrentContext] ERROR LOADING CURRENT CONTEXT ${error.toString()}');

    try {
      final fallback = await loadContextNext();

      saveContextCurrent(fallback);

      return fallback;
    } catch (error) {
      log.error('[loadNextContext] ERROR LOADING NEXT CONTEXT - RESETTING CONTEXT');
      resetContextsAll();
      return AppContext();
    }
  }
}

Future<AppContext> loadContextNext() async {
  try {
    final allContexts = await loadContextsAll();
    return allContexts.isNotEmpty ? allContexts[0] : AppContext();
  } catch (error) {
    log.error('[loadNextContext] ERROR LOADING NEXT CONTEXT ${error.toString()}');

    return AppContext();
  }
}

Future<List<AppContext>> loadContextsAll() async {
  try {
    final contextJson = await SecureStorage().read(key: ALL_APP_CONTEXT_KEY) ?? '[]';
    return List.from(await json.decode(contextJson)).map((c) => AppContext.fromJson(c)).toList();
  } catch (error) {
    log.error('[loadAllContexts] ERROR LOADING ALL CONTEXTS ${error.toString()}');

    resetContextsAll();

    return [AppContext()];
  }
}

Future deleteContext(AppContext? current) async {
  if (current == null) return;

  final allContexts = await loadContextsAll();

  final updatedContexts = allContexts.where((e) => e.id != current.id).toList();

  if (allContexts.isNotEmpty) {
    saveContextCurrent(allContexts.first);
  } else {
    saveContextCurrent(AppContext());
  }

  return saveContextsAll(updatedContexts);
}

resetContextsAll() async {
  try {
    final allContexts = await loadContextsAll();

    await Future.forEach(
      allContexts,
      (AppContext context) async {
        await deleteCache(context: context);
        await deleteStorage(context: context);
      },
    );

    await SecureStorage().write(key: ALL_APP_CONTEXT_KEY, value: json.encode([]));
    await SecureStorage().write(key: CURRENT_APP_CONTEXT_KEY, value: json.encode(AppContext()));
  } catch (error) {
    log.error('[resetAllContexts] ERROR RESETTING CONTEXT STORAGE ${error.toString()}');
  }
}
