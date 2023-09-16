import 'dart:io';
import 'package:discord_rpc/discord_rpc.dart' show DiscordRPC;
export 'package:discord_rpc/discord_rpc.dart';

final bool isPhone = !Platform.isAndroid && !Platform.isIOS;
bool init = true;

DiscordRPC? startRpc() {
  if (isPhone) {
    if (init) {
      DiscordRPC.initialize();
      init = !init;
    }
    return DiscordRPC(applicationId: '1142579045075255306')
      ..start(
        autoRegister: true,
      );
  }
  return null;
}
