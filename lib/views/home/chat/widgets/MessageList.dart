import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:katya/domain/events/actions.dart';
import 'package:katya/domain/events/messages/actions.dart';
import 'package:katya/domain/events/messages/model.dart';
import 'package:katya/domain/events/messages/selectors.dart';
import 'package:katya/domain/events/reactions/actions.dart';
import 'package:katya/domain/events/selectors.dart';
import 'package:katya/domain/index.dart';
import 'package:katya/domain/rooms/room/model.dart';
import 'package:katya/domain/rooms/selectors.dart';
import 'package:katya/domain/settings/chat-settings/selectors.dart';
import 'package:katya/domain/settings/models.dart';
import 'package:katya/domain/settings/theme-settings/model.dart';
import 'package:katya/domain/settings/theme-settings/selectors.dart';
import 'package:katya/domain/user/model.dart';
import 'package:katya/domain/user/selectors.dart';
import 'package:katya/global/colors.dart';
import 'package:katya/global/diff.dart';
import 'package:katya/global/dimensions.dart';
import 'package:katya/global/libraries/redux/hooks.dart';
import 'package:katya/global/print.dart';
import 'package:katya/views/widgets/messages/message.dart';
import 'package:katya/views/widgets/messages/typing-indicator.dart';

class MessageList extends HookWidget {
  const MessageList({
    super.key,
    required this.roomId,
    required this.scrollController,
    required this.editorController,
    this.showAvatars = true,
    this.editing = false,
    this.selectedMessage,
    this.onSendEdit,
    this.onSelectReply,
    this.onViewUserDetails,
    this.onToggleSelectedMessage,
  });

  final String roomId;
  final ScrollController scrollController;
  final TextEditingController editorController;

  final bool editing;
  final bool showAvatars;
  final Message? selectedMessage;

  final Function? onSendEdit;
  final Function? onSelectReply;
  final void Function({Message? message, User? user, String? userId})? onViewUserDetails;
  final void Function(Message?)? onToggleSelectedMessage;

  @override
  Widget build(BuildContext context) {
    // global actions
    final store = useStore<AppState>();
    final dispatch = useDispatch<AppState>();
    final Size(:height) = useDimensions(context);

    // global state
    final room = useSelector<AppState, Room>(
      (state) => selectRoom(id: roomId, state: state),
      Room(id: roomId),
    );

    final currentUser = useSelector<AppState, User>(
      (state) => state.authStore.currentUser,
      const User(userId: ''),
    );

    final users = useSelector<AppState, Map<String, User>>(
      (state) => messageUsers(roomId: roomId, state: state),
      <String, User>{},
    );

    final messagesRaw = useSelector<AppState, Map<String, Message>>(
      (state) => roomMessagesMap(state, roomId),
      <String, Message>{},
    );

    // used to identify if messages have updated
    final messagesKey = shasum(messagesRaw.keys.expand<int>((e) => e.codeUnits).toList());

    console.info('[messagesKey] $messagesKey');

    // the key above denotes uniquness
    final messages = useMemoized(
      () => latestMessages(filterMessages(
        combineOutbox(
          outbox: roomOutbox(store.state, roomId),
          messages: messagesRaw.values.toList(),
        ),
        store.state,
      )),
      [messagesKey],
    );

    final themeType = useSelector<AppState, ThemeType>(
      (state) => state.settingsStore.themeSettings.themeType,
      ThemeType.Light,
    );

    final timeFormat = useSelector<AppState, TimeFormat>(
      (state) => state.settingsStore.timeFormat24Enabled ? TimeFormat.hr24 : TimeFormat.hr12,
      TimeFormat.hr12,
    );

    final messageSize = useSelector<AppState, MessageSize>(
      (state) => state.settingsStore.themeSettings.messageSize,
      MessageSize.Default,
    );

    final chatColorPrimary = useSelectorUnsafe<AppState, Color?>(
      (state) => selectBubbleColor(state, roomId),
      equality: (a, b) => a == b,
    );

    // local hooks
    final colorMap = useRef(<String, Color>{});
    final luminanceMap = useRef(<String, double>{});

    final editorController = useTextEditingController();

    useEffect(() {
      for (final message in messages) {
        final userColor = AppColors.hashedColor(message.sender);
        colorMap.value[message.sender ?? ''] = userColor;
        luminanceMap.value[message.sender ?? ''] = userColor.computeLuminance();
      }
      return null;
    }, [messages.length]);

    onSelectReply(Message? message) {
      try {
        dispatch(selectReply(roomId: roomId, message: message));
      } catch (error) {
        console.error(error.toString());
      }
    }

    onResendMessage(Message message) {
      try {
        dispatch(sendMessageExisting(roomId: roomId, message: message));
      } catch (error) {
        console.error(error.toString());
      }
    }

    onToggleReaction({Message? message, String? emoji}) {
      dispatch(toggleReaction(room: room, message: message, emoji: emoji));
    }

    onInputReaction({Message? message}) async {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: height / 2.2,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: EmojiPicker(
              config: Config(
                columns: 9,
                emojiSizeMax: 24,
                indicatorColor: Theme.of(context).colorScheme.secondary,
                bgColor: Theme.of(context).scaffoldBackgroundColor,
                categoryIcons: const CategoryIcons(
                  smileyIcon: Icons.tag_faces_rounded,
                  objectIcon: Icons.lightbulb,
                  travelIcon: Icons.flight,
                  activityIcon: Icons.sports_soccer,
                  symbolIcon: Icons.tag,
                ),
              ),
              onEmojiSelected: (category, emoji) {
                onToggleReaction(emoji: emoji.emoji, message: message);

                Navigator.pop(context, false);
                onToggleSelectedMessage?.call(null);
              }),
        ),
      );
    }

    final lockScrolling = selectedMessage != null && !editing;

    return GestureDetector(
      onTap: () => onToggleSelectedMessage!(null),
      child: ListView(
        reverse: true,
        padding: const EdgeInsets.only(bottom: 16),
        physics: lockScrolling ? const NeverScrollableScrollPhysics() : null,
        controller: scrollController,
        children: [
          TypingIndicator(
            roomUsers: users,
            typing: room.userTyping,
            usersTyping: room.usersTyping,
            selectedMessageId: selectedMessage != null ? selectedMessage!.id : null,
          ),
          ListView.builder(
            reverse: true,
            shrinkWrap: true,
            // TODO: add padding based on widget height to allow
            // TODO: user to always pull down to load regardless of list size
            padding: EdgeInsets.only(bottom: 0, top: messages.length < 10 ? 200 : 0),
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: true,
            itemCount: messages.length,
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final message = messages[index];
              final lastMessage = index != 0 ? messages[index - 1] : null;
              final nextMessage = index + 1 < messages.length ? messages[index + 1] : null;

              // was sent at least 2 minutes after the previous message
              final isNewContext = ((lastMessage?.timestamp ?? 0) - message.timestamp) > 120000;

              final isLastSender = lastMessage != null && lastMessage.sender == message.sender;
              final isNextSender = nextMessage != null && nextMessage.sender == message.sender;
              final isUserSent = currentUser.userId == message.sender;

              final selectedMessageId = selectedMessage != null ? selectedMessage!.id : null;

              final user = users[message.sender];
              final avatarUri = user?.avatarUri;
              final displayName = user?.displayName;
              final color = colorMap.value[message.sender];
              final luminance = luminanceMap.value[message.sender];

              return MessageWidget(
                key: Key(message.id ?? ''),
                message: message,
                editorController: editorController,
                isEditing: editing,
                isUserSent: isUserSent,
                isLastSender: isLastSender,
                isNextSender: isNextSender,
                isNewContext: isNewContext,
                messageOnly: !isUserSent && !showAvatars,
                lastRead: room.lastRead,
                selectedMessageId: selectedMessageId,
                avatarUri: avatarUri,
                displayName: displayName,
                currentName: currentUser.userId,
                themeType: themeType,
                messageSize: selectMessageSizeDouble(messageSize),
                color: chatColorPrimary ?? color,
                luminance: luminance,
                timeFormat: timeFormat,
                onSendEdit: onSendEdit,
                onSwipe: onSelectReply,
                onResend: onResendMessage,
                onPressAvatar: () => onViewUserDetails!(
                  message: message,
                  user: user,
                  userId: message.sender,
                ),
                onLongPress: (msg) => onToggleSelectedMessage!(msg),
                onInputReaction: () => onInputReaction(message: message),
                onToggleReaction: (emoji) => onToggleReaction(message: message, emoji: emoji),
              );
            },
          ),
        ],
      ),
    );
  }
}
