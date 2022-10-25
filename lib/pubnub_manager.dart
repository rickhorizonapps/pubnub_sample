import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pubnub/logging.dart';
import 'package:pubnub/pubnub.dart';

class PubNubManager {
  factory PubNubManager() => _instance;

  PubNubManager._();

  static final PubNubManager _instance = PubNubManager._();

  PubNub? _pubnub;

  UserId? get userId => _userId;
  UserId? _userId;

  bool _isInit = false;

  String get groupName => 'cg_${_userId?.value}';

  /// Initialize [PubNub] and [userId] based from the currently logged-in user.
  ///
  /// This should only be called after login.
  Future<void> init() async {
    if (_isInit) {
      return;
    }

    try {
      _userId = const UserId('4821b2d3-e59f-498d-97da-775be04802a9');
      final Keyset keyset = Keyset(
        subscribeKey: 'sub-c-97e5bf6c-bd2f-4fd3-8d56-654c1c03fd0f',
        publishKey: 'pub-c-58fb5e8c-fa67-407c-b63d-3f5f755d636a',
        secretKey: 'sec-c-ZjlhODc5NzItMjhjYS00YTM0LTk1MGQtOGJmOWE3ZDQ0YzQy',
        userId: _userId,
      );
      _pubnub = PubNub(
        defaultKeyset: keyset,
      );

      await _pubnub!.channelGroups.addChannels(groupName, <String>{'me'});

      final logger = StreamLogger.root('myApp', logLevel: Level.all);

      logger.stream.listen((record) {
        print(
            '>>>>>>>>>> [${record.time}] ${Level.getName(record.level)}: ${record.message}');
      });

      _isInit = true;
    } catch (e) {
      // Do nothing.
    }
  }

  void _initCheck() {
    assert(_isInit, 'Not yet initialized. Please call [init] first.');
  }

  /// Get list of channels from user's group.
  Future<ChannelGroupListChannelsResult> get channelsOfGroup async {
    _initCheck();
    return _pubnub!.channelGroups.listChannels(groupName);
  }

  Channel getChannel(String channelId) => _pubnub!.channel(channelId);

  /// Subscribe to channel group.
  StreamSubscription<Envelope> subscribeToGroup(
    ValueChanged<Envelope> onMessage,
  ) {
    _initCheck();
    return _pubnub!
        .subscribe(
          channelGroups: <String>{
            groupName,
          },
        )
        .messages
        .listen(onMessage);
  }

  /// Subscribe to channel group.
  StreamSubscription<Envelope> subscribeToChannel(
    String channelId,
    ValueChanged<Envelope> onMessage,
  ) {
    _initCheck();
    _pubnub!.signals.networkIsDown.listen((event) {
      print('>>>>>>>>>> networkIsDown');
    });
    return _pubnub!
        .subscribe(
          channels: <String>{
            channelId,
          },
        )
        .messages
        .listen(onMessage, onError: (Object e) {
          print('>>>>>>>>>> onError = $e');
        }, onDone: () {
          print('>>>>>>>>>> onDone');
        });
  }

  /// Get [channel]'s message history.
  PaginatedChannelHistory getChannelHistory(Channel channel) {
    _initCheck();
    return channel.history();
  }

  /// Get [channel]'s message history from [start] to [end].
  Future<List<BatchHistoryResultEntry>?> getChannelBatchHistory({
    required Channel channel,
    required DateTime start,
    DateTime? end,
  }) async {
    _initCheck();

    DateTime finalEnd;

    if (end == null) {
      finalEnd = start.subtract(const Duration(days: 7));
      finalEnd = DateTime(finalEnd.year, finalEnd.month, finalEnd.day);
    } else {
      finalEnd = end;
    }

    final BatchHistoryResult res = await _pubnub!.batch.fetchMessages(
      <String>{
        channel.name,
      },
      start: Timetoken.fromDateTime(start),
      end: Timetoken.fromDateTime(finalEnd),
    );

    return res.channels[channel.name];
  }

  /// Reset [PubNub]. You need to call [init] again after calling this.
  void reset() {
    _pubnub = null;
    _userId = null;
    _isInit = false;
  }
}
