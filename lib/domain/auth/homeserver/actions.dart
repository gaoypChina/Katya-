import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:katya/domain/alerts/actions.dart';
import 'package:katya/domain/auth/actions.dart';
import 'package:katya/domain/auth/homeserver/model.dart';
import 'package:katya/domain/index.dart';
import 'package:katya/domain/search/actions.dart';
import 'package:katya/global/assets.dart';
import 'package:katya/global/https.dart';
import 'package:katya/global/libraries/matrix/index.dart';
import 'package:katya/global/print.dart';

ThunkAction<AppState> fetchKnownServers() {
  return (Store<AppState> store) async {
    store.dispatch(setAuthLoading(loading: true));

    try {
      final jsonData = await rootBundle.loadString(Assets.homeserversJSON);
      final homeserversJson = await json.decode(jsonData);

      // parse homeserver data
      final homserversList = List<Homeserver>.from(homeserversJson.map((data) {
        final hostname = data['hostname'].toString().split('.');
        final hostnameBase = hostname.length > 1
            ? '${hostname[hostname.length - 2]}.${hostname[hostname.length - 1]}'
            : hostname[0];

        return Homeserver(
          hostname: hostnameBase,
          location: data['location'] ?? '',
          description: data['description'] ?? '',
          usersActive: data['users_active']?.toString() ?? '',
          roomsTotal: data['total_room_count_estimate']?.toString() ?? '',
          founded: data['online_since']?.toString() ?? '',
        );
      }));

      // set homeservers without cached photo url
      await store.dispatch(SetHomeservers(
        homeservers: homserversList,
      ));

      // find favicons for all the homeservers
      final homeserversWithAvatars = await Future.wait(
        homserversList.map((homeserver) async {
          final url = await fetchFavicon(url: homeserver.hostname);
          try {
            final uri = Uri.parse(url!);
            final response = await httpClient.get(uri);

            if (response.statusCode == 200) {
              return homeserver.copyWith(photoUrl: url);
            }
          } catch (error) {/* noop */}

          return homeserver;
        }),
      );

      // set the homeservers and finish loading
      await store.dispatch(SetHomeservers(homeservers: homeserversWithAvatars));
    } catch (error) {
      store.dispatch(addAlert(origin: 'fetchHomeservers', error: error));
    }
    store.dispatch(setAuthLoading(loading: false));
  };
}

// fetch homeserver well-known
ThunkAction<AppState> fetchBaseUrl({required Homeserver homeserver}) {
  return (Store<AppState> store) async {
    try {
      final response = await MatrixApi.checkHomeserver(
            protocol: store.state.authStore.protocol,
            homeserver: homeserver.hostname!,
          ) ??
          {};

      var identityUrl = response['m.identity_server'];
      var baseUrl = (response['m.homeserver']['base_url'] as String).replaceAll('https://', '');

      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.replaceRange(baseUrl.length - 1, null, '');
      }

      if (identityUrl != null) {
        identityUrl = (response['m.identity_server']['base_url'] as String).replaceAll('https://', '');
      }

      return homeserver.copyWith(
        valid: true,
        baseUrl: baseUrl,
        identityUrl: identityUrl,
      );
    } catch (error) {
      console.error('[fetchBaseUrl] failed .well-known client query');

      try {
        final response = await MatrixApi.checkHomeserverAlt(
              protocol: store.state.authStore.protocol,
              homeserver: homeserver.hostname!,
            ) ??
            {};

        final baseUrl = (response['m.server'] as String).split(':')[0];

        return homeserver.copyWith(
          valid: true,
          baseUrl: baseUrl,
          identityUrl: baseUrl,
        );
      } catch (error) {
        console.error(
          '[fetchBaseUrl] failed alternative .well-known server query',
        );
      }
    }

    return homeserver.copyWith(
      valid: false,
    );
  };
}

ThunkAction<AppState> fetchServerVersion({required Homeserver homeserver}) {
  return (Store<AppState> store) async {
    // fetch homeserver well-known
    try {
      final response = await MatrixApi.checkVersion(
            protocol: store.state.authStore.protocol,
            homeserver: homeserver.hostname,
          ) ??
          {};

      final versionExists = response['versions'] != null;

      return homeserver.copyWith(valid: versionExists);
    } catch (error) {
      return homeserver.copyWith(valid: false);
    }
  };
}
