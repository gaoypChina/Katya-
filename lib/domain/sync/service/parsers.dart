import 'package:katya/domain/events/messages/model.dart';
import 'package:katya/domain/rooms/room/model.dart';
import 'package:katya/domain/user/selectors.dart';

const String INVALID = '';

String parseMessageNotification({
  required Room room,
  required Message message,
  required String currentUserId,
  required Map<String, String> roomNames,
}) {
  final String? messageSender = message.sender;
  final String formattedSender = trimAlias(messageSender);

  if (formattedSender.isEmpty || messageSender == currentUserId) {
    return INVALID;
  }

  if (room.direct) {
    return '$formattedSender sent a new message';
  }

  if (room.invite) {
    return '$formattedSender invited you to chat';
  }

  String roomName = INVALID;

  if (roomName.isEmpty) {
    roomName = roomNames[room.id] ?? INVALID;
  }

  if (roomName.isEmpty) {
    return '$formattedSender sent a new message';
  }

  return '$formattedSender sent a new message in $roomName';
}

String parseMessageTitle({
  required Room room,
  required Message message,
  required String currentUserId,
  required Map<String, String> roomNames,
}) {
  final String? messageSender = message.sender;
  final String formattedSender = trimAlias(messageSender);

  if (formattedSender.isEmpty || message.sender == currentUserId) {
    return INVALID;
  }

  if (room.direct) {
    return 'New Message';
  }

  if (room.invite) {
    return 'New Invite';
  }

  String roomName = INVALID;

  if (roomName.isEmpty) {
    roomName = roomNames[room.id] ?? INVALID;
  }

  if (roomName.isEmpty) {
    return 'New Message';
  }

  return roomName;
}
