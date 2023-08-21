import 'package:redux/redux.dart';
import 'package:katya/domain/auth/actions.dart';
import 'package:katya/domain/auth/context/actions.dart';
import 'package:katya/domain/crypto/actions.dart';
import 'package:katya/domain/crypto/keys/actions.dart';
import 'package:katya/domain/crypto/sessions/actions.dart';
import 'package:katya/domain/events/actions.dart';
import 'package:katya/domain/index.dart';
import 'package:katya/domain/rooms/actions.dart';
import 'package:katya/domain/sync/actions.dart';
import 'package:katya/global/print.dart';

///
/// Cache Middleware
///
/// Saves store data to cold storage based
/// on which redux actions are fired.
///
bool cacheMiddleware(Store<AppState> store, dynamic action) {
  switch (action.runtimeType) {
    case AddAvailableUser:
    case RemoveAvailableUser:
    case UpdateRoom:
    case SetRoom:
    case RemoveRoom:
    case DeleteMessage:
    case DeleteOutboxMessage:
    case SetOlmAccountBackup:
    case SetDeviceKeysOwned:
    case AddKeySession:
    case AddMessageSessionInbound:
    case AddMessageSessionOutbound:
    case SetUser:
    case ResetCrypto:
    case ResetUser:
      console.info('[initStore] persistor saving from ${action.runtimeType}');
      return true;
    case SetSynced:
      return ((action as SetSynced).synced ?? false) && !store.state.syncStore.synced;
    default:
      return false;
  }
}
