import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:katya/context/types.dart';
import 'package:katya/global/print.dart';
import 'package:katya/global/values.dart';
import 'package:katya/storage/constants.dart';
import 'package:katya/storage/database.dart';
import 'package:katya/store/auth/storage.dart';
import 'package:katya/store/crypto/sessions/storage.dart';
import 'package:katya/store/crypto/storage.dart';
import 'package:katya/store/events/messages/actions.dart';
import 'package:katya/store/events/messages/model.dart';
import 'package:katya/store/events/messages/storage.dart';
import 'package:katya/store/events/reactions/actions.dart';
import 'package:katya/store/events/reactions/model.dart';
import 'package:katya/store/events/reactions/storage.dart';
import 'package:katya/store/events/receipts/actions.dart';
import 'package:katya/store/events/receipts/model.dart';
import 'package:katya/store/events/receipts/storage.dart';
import 'package:katya/store/index.dart';
import 'package:katya/store/media/actions.dart';
import 'package:katya/store/media/storage.dart';
import 'package:katya/store/rooms/room/model.dart';
import 'package:katya/store/rooms/storage.dart';
import 'package:katya/store/settings/storage.dart';
import 'package:katya/store/user/storage.dart';

class Storage {
  // cache key identifiers
  static const keyLocation = '${Values.appLabel}@storageKey';

  // storage identifiers
  static const sqliteLocation = '${Values.appLabel}-cold-storage.db';

  // cold storage references
  static StorageDatabase? database;
}

Future initStorage({AppContext context = const AppContext(), String pin = ''}) async {
  final database = openDatabaseThreaded(context, pin: pin);
  Storage.database = database;
  return database;
}

Future closeStorage(StorageDatabase? storage) async {
  if (storage != null) {
    storage.close();
  }
}

Future deleteStorage({AppContext context = const AppContext()}) async {
  try {
    final contextId = context.id;
    var storageLocation = Storage.sqliteLocation;

    if (contextId.isNotEmpty) {
      storageLocation = '$contextId-$storageLocation';
    }

    storageLocation = DEBUG_MODE ? 'debug-$storageLocation' : storageLocation;

    final appDir = await getApplicationSupportDirectory();
    final file = File(path.join(appDir.path, storageLocation));
    await file.delete();
  } catch (error) {
    log.error('[deleteColdStorage] ${error.toString()}');
  }
}

///
/// Load Storage
///
/// bulk loads cold storage objects to RAM, this can
/// be much more specific and performant
///
/// for example, only load users that are known to be
/// involved in stored messages/events
///
Future<Map<String, dynamic>> loadStorage(StorageDatabase storage) async {
  try {
    final userIds = <String>[];
    final messages = <String, List<Message>>{};
    final decrypted = <String, List<Message>>{};
    final reactions = <String, List<Reaction>>{};

    final auth = await loadAuth(storage: storage);
    final crypto = await loadCrypto(storage: storage);
    final settings = await loadSettings(storage: storage);
    final rooms = await loadRooms(storage: storage);

    for (final Room room in rooms.values) {
      messages[room.id] = await loadMessagesRoom(
        room.id,
        storage: storage,
      );

      decrypted[room.id] = await loadDecryptedRoom(
        room.id,
        storage: storage,
      );

      final currentUserIds =
          (messages[room.id] ?? []).map((message) => message.sender ?? '').toList();

      userIds.addAll(currentUserIds);
    }

    final users = await loadUsers(storage: storage, ids: userIds);

    final media = await loadMediaRelative(
      storage: storage,
      users: users.values.toList(),
      rooms: rooms.values.toList(),
    );

    final messageSessions = await loadMessageSessionsInbound(
      roomIds: rooms.keys.toList(),
      storage: storage,
    );

    return {
      StorageKeys.AUTH: auth,
      StorageKeys.CRYPTO: crypto,
      StorageKeys.SETTINGS: settings,
      StorageKeys.ROOMS: rooms,
      StorageKeys.USERS: users,
      StorageKeys.MEDIA: media,
      StorageKeys.MESSAGES: messages,
      StorageKeys.REACTIONS: reactions,
      StorageKeys.DECRYPTED: decrypted,
      StorageKeys.MESSAGE_SESSIONS: messageSessions,
    };
  } catch (error) {
    log.error('[loadStorage] ${error.toString()}');
    return {};
  }
}

//
// Load Storage (Async)
//
// finishes loading cold storage objects to RAM, this can
// be much more specific and performant
//
loadStorageAsync(StorageDatabase storage, Store<AppState> store) {
  try {
    final rooms = store.state.roomStore.roomList;
    final messages = store.state.eventStore.messages;
    final decrypted = store.state.eventStore.messagesDecrypted;

    final medias = <String, Uint8List>{};
    final reactions = <String, List<Reaction>>{};
    final receipts = <String, Map<String, Receipt>>{};

    loadAsync() async {
      for (final Room room in rooms) {
        final currentMessages = messages[room.id] ?? [];
        final currentDecrypted = decrypted[room.id] ?? [];
        final currentMessagesIds = currentMessages.map((e) => e.id ?? '').toList();

        reactions.addAll(await loadReactionsMapped(
          roomId: room.id,
          eventIds: currentMessagesIds,
          storage: storage,
        ));

        receipts[room.id] = await loadReceipts(
          currentMessagesIds,
          storage: storage,
        );

        medias.addAll(await loadMediaRelative(
          messages: currentMessages + currentDecrypted,
          storage: storage,
        ));
      }

      store.dispatch(LoadMedia(mediaMap: medias));
      store.dispatch(LoadReceipts(receiptsMap: receipts));
      store.dispatch(LoadReactions(reactionsMap: reactions));

      // mutate messages
      store.dispatch(mutateMessagesAll());
    }

    loadAsync();
  } catch (error) {
    log.error('[loadStorageAsync] ${error.toString()}');
  }
}
