import 'package:redux/redux.dart';
import 'package:katya/global/print.dart';
import 'package:katya/storage/database.dart';
import 'package:katya/store/index.dart';
import 'package:katya/store/user/actions.dart';
import 'package:katya/store/user/storage.dart';

///
/// Load Storage Middleware
///
/// Loads storage data from cold storage
/// based  on which redux actions are fired.
///
loadStorageMiddleware(StorageDatabase? storage) {
  return (
    Store<AppState> store,
    dynamic action,
    NextDispatcher next,
  ) async {
    try {
      if (storage == null) {
        log.warn(
          'storage is null, skipping saving cold storage data!!!',
          title: 'storageMiddleware',
        );
        return;
      }

      switch (action.runtimeType) {
        case LoadUsers:
          final _action = action as LoadUsers;
          _loadUserAsync() async {
            final loadedUsers = await loadUsers(storage: storage, ids: _action.userIds ?? []);

            store.dispatch(SetUsers(users: loadedUsers));
          }

          _loadUserAsync();
          break;
        default:
          break;
      }
    } catch (error) {
      log.error('[loadStorageMiddleware] ${error.toString()}');
    }

    next(action);
  };
}
