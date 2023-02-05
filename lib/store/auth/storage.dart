import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:katya/global/print.dart';
import 'package:katya/storage/constants.dart';
import 'package:katya/storage/database.dart';
import 'package:katya/store/auth/state.dart';

///
/// Auth Quesies - unencrypted (Cold Storage)
///
/// In storage, messages are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension AuthQueries on StorageDatabase {
  Future<int> insertAuthStore(AuthStore store) async {
    final storeJson = json.decode(json.encode(store));

    // HACK: temporary to account for sqlite versions without UPSERT
    if (Platform.isLinux) {
      return into(auths).insert(
        AuthsCompanion(
          id: Value(StorageKeys.AUTH),
          store: Value(storeJson),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }

    return into(auths).insertOnConflictUpdate(AuthsCompanion(
      id: Value(StorageKeys.AUTH),
      store: Value(storeJson),
    ));
  }

  Future<AuthStore?> selectAuthStore() async {
    final row = await (select(auths)..where((tbl) => tbl.id.isNotNull()))
        .getSingleOrNull();

    if (row == null) {
      return null;
    }

    return AuthStore.fromJson(row.store ?? {});
  }
}

Future<int> saveAuth(
  AuthStore authStore, {
  required StorageDatabase storage,
}) async {
  return storage.insertAuthStore(authStore);
}

///
/// Load Auth Store (Cold Storage)
///
Future<AuthStore?> loadAuth({required StorageDatabase storage}) async {
  try {
    return storage.selectAuthStore();
  } catch (error) {
    log.error(error.toString(), title: 'loadAuth');
    return null;
  }
}
