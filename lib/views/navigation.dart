import 'package:flutter/material.dart';
import 'package:katya/global/values.dart';
import 'package:katya/views/home/HomeScreen.dart';
import 'package:katya/views/home/chat/ChatScreen.dart';
import 'package:katya/views/home/chat/chat-detail-all-users-screen.dart';
import 'package:katya/views/home/chat/chat-detail-message-screen.dart';
import 'package:katya/views/home/chat/chat-detail-screen.dart';
import 'package:katya/views/home/chat/media-preview-screen.dart';
import 'package:katya/views/home/groups/group-create-public-screen.dart';
import 'package:katya/views/home/groups/group-create-screen.dart';
import 'package:katya/views/home/groups/invite-users-screen.dart';
import 'package:katya/views/home/profile/ProfileScreen.dart';
import 'package:katya/views/home/profile/ProfileUserScreen.dart';
import 'package:katya/views/home/search/search-chats-screen.dart';
import 'package:katya/views/home/search/search-groups-screen.dart';
import 'package:katya/views/home/search/search-users-screen.dart';
import 'package:katya/views/home/settings/advanced-settings-screen.dart';
import 'package:katya/views/home/settings/blocked-screen.dart';
import 'package:katya/views/home/settings/password/password-update-screen.dart';
import 'package:katya/views/home/settings/settings-chats-screen.dart';
import 'package:katya/views/home/settings/settings-devices-screen.dart';
import 'package:katya/views/home/settings/settings-languages-screen.dart';
import 'package:katya/views/home/settings/settings-notifications-screen.dart';
import 'package:katya/views/home/settings/settings-privacy-screen.dart';
import 'package:katya/views/home/settings/settings-screen.dart';
import 'package:katya/views/home/settings/settings-theme-screen.dart';
import 'package:katya/views/intro/IntroScreen.dart';
import 'package:katya/views/intro/login/LoginScreen.dart';
import 'package:katya/views/intro/login/forgot/password-forgot-screen.dart';
import 'package:katya/views/intro/login/forgot/password-reset-screen.dart';
import 'package:katya/views/intro/search/search-homeserver-screen.dart';
import 'package:katya/views/intro/signup/LoadingScreen.dart';
import 'package:katya/views/intro/signup/SignupScreen.dart';
import 'package:katya/views/intro/signup/verification-screen.dart';

import 'home/settings/settings-intro-screen.dart';

// helper hook for extracting navigation params
T useScreenArguments<T>(BuildContext context, T fallback) {
  return (ModalRoute.of(context)?.settings.arguments ?? fallback) as T;
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String? currentRoute() {
    String? currentPath;
    navigatorKey.currentState?.popUntil((route) {
      currentPath = route.settings.name;
      return true;
    });

    return currentPath;
  }

  static Future navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  static Future<bool> goBack() {
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }

  static Future clearTo(String routeName, BuildContext context) {
    final navigator = navigatorKey.currentState;

    if (navigator == null) return Future.value();

    return navigator.pushNamedAndRemoveUntil(routeName, (_) => false);
  }
}

class Routes {
  // Onboarding
  static const loading = '/loading';
  static const intro = '/intro';
  static const login = '/login';
  static const signup = '/signup';
  static const forgot = '/forgot';
  static const reset = '/reset';
  static const verification = '/verification';
  static const searchHomeservers = '/search/homeservers';

  // Main (Authed)
  static const root = '/';
  static const home = '/home';

  // Search
  static const searchAll = '/home/search';
  static const searchChats = '/home/search/chats';
  static const searchUsers = '/home/search/users';
  static const searchGroups = '/home/search/groups';

  // Users
  static const userInvite = '/home/user/invite';
  static const userDetails = '/home/user/details';

  // Groups
  static const groupCreate = '/home/groups/create';
  static const groupCreatePublic = '/home/groups/create/public';

  // Chats and Messages
  static const chat = '/home/chat';
  static const chatUsers = '/home/chat/users';
  static const chatSettings = '/home/chat/details';
  static const chatMediaPreview = '/home/chat/media';
  static const messageDetails = '/home/message/details';

  // Settings
  static const settings = '/home/settings';
  static const settingsChat = '/home/settings/chat';
  static const settingsProfile = '/home/settings/profile';
  static const settingsPrivacy = '/home/settings/privacy';
  static const settingsDevices = '/home/settings/devices';
  static const settingsBlocked = '/home/settings/blocked';
  static const settingsPassword = '/home/settings/password';
  static const settingsAdvanced = '/home/settings/advanced';
  static const settingsProxy = '/home/settings/proxy';
  static const settingsNotifications = '/home/settings/notifications';
  static const settingsLanguages = '/settings/languages';

  // Settings (Global)
  static const settingsTheme = '/settings/theming';

  // Misc
  static const licenses = '/licenses';
}

class NavigationProvider {
  static Map<String, Widget Function(BuildContext)> getRoutes() => <String, WidgetBuilder>{
        Routes.intro: (BuildContext context) => const IntroScreen(),
        Routes.login: (BuildContext context) => const LoginScreen(),
        Routes.signup: (BuildContext context) => SignupScreen(),
        Routes.forgot: (BuildContext context) => const ForgotPasswordScreen(),
        Routes.reset: (BuildContext context) => const ResetPasswordScreen(),
        Routes.searchHomeservers: (BuildContext context) => const SearchHomeserverScreen(),
        Routes.verification: (BuildContext context) => const VerificationScreen(),
        Routes.home: (BuildContext context) => HomeScreen(),
        Routes.chat: (BuildContext context) => const ChatScreen(),
        Routes.chatSettings: (BuildContext context) => const ChatSettingsScreen(),
        Routes.chatMediaPreview: (BuildContext context) => const MediaPreviewScreen(),
        Routes.messageDetails: (BuildContext context) => const MessageDetailsScreen(),
        Routes.chatUsers: (BuildContext context) => const ChatUsersDetailScreen(),
        Routes.searchUsers: (BuildContext context) => const SearchUserScreen(),
        Routes.userDetails: (BuildContext context) => UserProfileScreen(),
        Routes.userInvite: (BuildContext context) => const InviteUsersScreen(),
        Routes.searchChats: (BuildContext context) => const ChatSearchScreen(),
        Routes.searchGroups: (BuildContext context) => const GroupSearchScreen(),
        Routes.groupCreate: (BuildContext context) => const CreateGroupScreen(),
        Routes.groupCreatePublic: (BuildContext context) => const CreatePublicGroupScreen(),
        Routes.settingsProfile: (BuildContext context) => const ProfileScreen(),
        Routes.settingsNotifications: (BuildContext context) => const NotificationSettingsScreen(),
        Routes.settingsLanguages: (BuildContext context) => const LanguageSettingsScreen(),
        Routes.settingsAdvanced: (BuildContext context) => const AdvancedSettingsScreen(),
        Routes.settingsProxy: (BuildContext context) => const IntroSettingsScreen(),
        Routes.settingsPassword: (BuildContext context) => const PasswordUpdateScreen(),
        Routes.licenses: (BuildContext context) => const LicensePage(applicationName: Values.appName),
        Routes.settingsPrivacy: (BuildContext context) => const PrivacySettingsScreen(),
        Routes.settingsChat: (BuildContext context) => const SettingsChatsScreen(),
        Routes.settingsTheme: (BuildContext context) => const ThemeSettingsScreen(),
        Routes.settingsDevices: (BuildContext context) => DevicesScreen(),
        Routes.settings: (BuildContext context) => const SettingsScreen(),
        Routes.settingsBlocked: (BuildContext context) => const BlockedScreen(),
        Routes.loading: (BuildContext context) => const LoadingScreen(),
      };
}
