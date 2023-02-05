import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:katya/global/libs/matrix/index.dart';
import 'package:katya/global/print.dart';
import 'package:katya/global/values.dart';
import 'package:katya/store/index.dart';
import 'package:katya/store/settings/actions.dart';

/// Fetch Remote Push Notification Service Rules
ThunkAction<AppState> fetchNotifications() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      final data = await MatrixApi.fetchNotifications(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      log.error('[fetchNotificationPushers] $error');
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}

/// Fetch Remote Push Notification Services
ThunkAction<AppState> fetchNotificationPushers() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      final data = await MatrixApi.fetchNotificationPushers(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      log.error('[fetchNotificationPushers] $error');
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}

/// Fetch Remote Push Notification Service Rules
ThunkAction<AppState> fetchNotificationPusherRules() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      final data = {'errcode': 'Not Implemented'};

      if (data['errcode'] != null) {
        throw data['error']!;
      }
    } catch (error) {
      log.error('[fetchNotificationPusherRules] $error');
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}

/// Set Pusher Device Token
///
/// NOTE: used to set iOS APNS token
///
/// Either the Apple Push Notification Service token for
/// this device or an email address for "email" notifications
ThunkAction<AppState> setPusherDeviceToken(String token) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));
      store.dispatch(SetPusherToken(token: token));
    } catch (error) {
      log.error('[setPusherDeviceToken] $error');
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}

/// Fetch Remote Push Notification Service
ThunkAction<AppState> saveNotificationPusher({
  String kind = 'http', // can be 'email' with token as email
  bool erase = false,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      final deviceId = store.state.authStore.user.deviceId;
      final devices = store.state.settingsStore.devices;
      final pusherKey = store.state.settingsStore.pusherToken;

      final currentDevice = devices.firstWhere(
        (device) => device.deviceId == deviceId,
      );

      final data = await MatrixApi.saveNotificationPusher(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        kind: erase ? null : kind,
        pushKey: pusherKey,
        appDisplayName: Values.appNameLong,
        appId: Values.appId,
        deviceDisplayName: currentDevice.displayName,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      log.error('[saveNotificationPusher] $error');
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}
