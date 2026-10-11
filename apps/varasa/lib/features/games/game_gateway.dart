import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GameAvailability {
  const GameAvailability(this.available, this.message);
  final bool available;
  final String message;
}

abstract class GameGateway {
  Future<GameAvailability> availability();
  Future<void> launch();
}

/// Contract for a future Unity-as-a-Library host. No second APK or install intents.
/// The shipped Flutter hosts do not implement this channel yet.
class ChallasAathGateway implements GameGateway {
  static const _channel = MethodChannel('varasa/games/v1');
  @override
  Future<GameAvailability> availability() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return const GameAvailability(
        false,
        'The original game will return in the mobile app. You can explore its story here.',
      );
    }
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable', {
        'gameId': 'challas_aath',
        'protocolVersion': 1,
      });
      return GameAvailability(
        result == true,
        result == true
            ? 'Ready to play on this device.'
            : 'The game is not included in this build yet.',
      );
    } on MissingPluginException {
      return const GameAvailability(
        false,
        'The original Unity game has not been connected to this build yet.',
      );
    } on PlatformException {
      return const GameAvailability(
        false,
        'The game could not be loaded. Please try again later.',
      );
    }
  }

  @override
  Future<void> launch() async {
    final state = await availability();
    if (!state.available) throw StateError(state.message);
    await _channel.invokeMethod<void>('launch', {
      'gameId': 'challas_aath',
      'protocolVersion': 1,
    });
  }
}
