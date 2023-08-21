import 'dart:async';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:katya/domain/index.dart';
import 'package:katya/domain/rooms/room/model.dart';
import 'package:katya/domain/search/actions.dart';
import 'package:katya/domain/settings/storage.dart';
import 'package:katya/domain/settings/theme-settings/model.dart';
import 'package:katya/domain/sync/actions.dart';
import 'package:katya/global/libraries/redux/hooks.dart';
import 'package:katya/global/strings.dart';
import 'package:katya/views/home/HomeAppBar.dart';
import 'package:katya/views/home/HomeAppBarOptions.dart';
import 'package:katya/views/home/HomeChatList.dart';
import 'package:katya/views/home/chat/ChatScreen.dart';
import 'package:katya/views/navigation.dart';
import 'package:katya/views/widgets/appbars/appbar-search.dart';
import 'package:katya/views/widgets/containers/fabs/fab-bar-expanding.dart';
import 'package:katya/views/widgets/containers/fabs/fab-ring.dart';
import 'package:katya/views/widgets/loader/index.dart';

class HomeScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dispatch = useDispatch<AppState>();

    final lastSince = useSelectorUnsafe<AppState, String?>(
      (state) => state.syncStore.lastSince,
    );

    final searchLoading = useSelectorUnsafe<AppState, bool>(
          (state) => state.searchStore.loading,
        ) ??
        false;

    final roomIdsAll = useSelectorUnsafe<AppState, Iterable<String>>(
          (state) => state.roomStore.rooms.keys,
        ) ??
        [];

    final fabType =
        useSelectorUnsafe<AppState, MainFabType>((state) => state.settingsStore.themeSettings.mainFabType) ??
            MainFabType.Ring;

    final fabLabels = useSelectorUnsafe<AppState, MainFabLabel>(
            (state) => state.settingsStore.themeSettings.mainFabLabel) ??
        MainFabLabel.Off;

    final fabLocation = useSelectorUnsafe<AppState, MainFabLocation>(
            (state) => state.settingsStore.themeSettings.mainFabLocation) ??
        MainFabLocation.Right;

    final fabKeyRing = useState(GlobalKey<FabCircularMenuState>());

    final onboardingState = useState(false);

    final searchModeState = useState(false);
    final searchTextState = useState('');
    final selectedChatsState = useState<List<String>>([]);

    final onboarding = onboardingState.value;
    final searchMode = searchModeState.value;
    final searchText = searchTextState.value;
    final selectedChats = selectedChatsState.value;

    final searchFocusNode = useFocusNode();

    useEffect(() {
      checkTermsTimestamp() async {
        final firstLoginMillis = await loadTermsAgreement();
        final firstLoginTimestamp = DateTime.fromMillisecondsSinceEpoch(firstLoginMillis);
        if (DateTime.now().difference(firstLoginTimestamp).inDays < 1) {
          onboardingState.value = true;
        }
      }

      checkTermsTimestamp();
      return null;
    }, []);

    onToggleSearch() {
      searchModeState.value = !searchModeState.value;
      searchTextState.value = '';
    }

    onFetchSync() async {
      await dispatch(fetchSync(since: lastSince));
    }

    onToggleChatOptions({required Room room}) {
      if (searchMode) {
        onToggleSearch();
      }

      if (!selectedChats.contains(room.id)) {
        selectedChatsState.value = List.from(selectedChats..addAll([room.id]));
      } else {
        selectedChatsState.value = List.from(selectedChats..remove(room.id));
      }
    }

    onSearch(String text) {
      searchTextState.value = text;

      if (text.isEmpty) {
        return dispatch(clearSearchResults());
      }

      dispatch(searchMessages(text));
    }

    onDismissChatOptions() {
      selectedChatsState.value = [];
    }

    onSelectChat(Room room, String chatName) {
      if (selectedChats.isNotEmpty) {
        return onToggleChatOptions(room: room);
      }

      Navigator.pushNamed(
        context,
        Routes.chat,
        arguments: ChatScreenArguments(roomId: room.id, title: chatName),
      );

      Timer(const Duration(milliseconds: 500), () {
        searchModeState.value = false;
        onDismissChatOptions();
        dispatch(clearSearchResults());
      });
    }

    onSelectAll() {
      if (selectedChats.toSet().containsAll(roomIdsAll)) {
        onDismissChatOptions();
      } else {
        selectedChatsState.value = selectedChats
          ..addAll(roomIdsAll)
          ..toList();
      }
    }

    selectActionAlignment() {
      if (fabLocation == MainFabLocation.Left) {
        return Alignment.bottomLeft;
      }

      return Alignment.bottomRight;
    }

    buildActionFab() {
      if (fabType == MainFabType.Bar) {
        return FabBarExpanding(
          showLabels: onboarding || fabLabels == MainFabLabel.On,
          alignment: selectActionAlignment(),
        );
      }

      return FabRing(
        fabKey: fabKeyRing.value,
        showLabels: onboarding || fabLabels == MainFabLabel.On,
        alignment: selectActionAlignment(),
      );
    }

    selectActionLocation() {
      if (fabLocation == MainFabLocation.Left) {
        return FloatingActionButtonLocation.startFloat;
      }

      return FloatingActionButtonLocation.endFloat;
    }

    Widget currentAppBar = AppBarHome(
      onToggleSearch: () => onToggleSearch(),
    );

    if (searchMode) {
      currentAppBar = AppBarSearch(
        title: Strings.titleSearchUnencrypted,
        label: Strings.labelSearchUnencrypted,
        tooltip: Strings.tooltipSearchUnencrypted,
        forceFocus: true,
        navigate: false,
        startFocused: true,
        focusNode: searchFocusNode,
        onBack: () => onToggleSearch(),
        onToggleSearch: () => onToggleSearch(),
        onSearch: (String text) => onSearch(text),
      );
    }

    if (selectedChats.isNotEmpty) {
      currentAppBar = AppBarHomeOptions(
        selectedChatsIds: selectedChats,
        onSelectAll: () => onSelectAll(),
        onToggleChatOptions: (room) => onToggleChatOptions(room: room),
        onDismissChatOptions: () => onDismissChatOptions(),
      );
    }

    return Scaffold(
      appBar: currentAppBar as PreferredSizeWidget?,
      floatingActionButton: buildActionFab(),
      floatingActionButtonLocation: selectActionLocation(),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => onFetchSync(),
                child: Stack(
                  children: [
                    Positioned(
                      child: Loader(
                        loading: searchLoading,
                      ),
                    ),
                    GestureDetector(
                      onTap: onDismissChatOptions,
                      child: HomeChatList(
                        searching: searchMode,
                        searchText: searchText,
                        selectedChats: selectedChats,
                        onSelectChat: onSelectChat,
                        onToggleChatOptions: onToggleChatOptions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
