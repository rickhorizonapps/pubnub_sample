import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub_sample/pubnub_manager.dart';

class ChatList extends StatefulWidget {
  const ChatList({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final List<ChatMessage> _messages = <ChatMessage>[];

  late Channel _channel;
  late StreamSubscription<Envelope> _channelStreamSubs;

  DateTime _startDate = DateTime.now();
  late DateTime _endDate;

  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();

    _endDate = _startDate.subtract(const Duration(days: 14));
    _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);

    _setupPubNub();
  }

  @override
  void dispose() {
    _channelStreamSubs.cancel();
    super.dispose();
  }

  void _setupPubNub() {
    final PubNubManager pubNubManager = PubNubManager();

    _channel = pubNubManager.getChannel(
        'dir_1e99add0-41de-400b-8b11-b262c5ad387b_4821b2d3-e59f-498d-97da-775be04802a9');
    _channelStreamSubs = pubNubManager.subscribeToChannel(
      'dir_1e99add0-41de-400b-8b11-b262c5ad387b_4821b2d3-e59f-498d-97da-775be04802a9',
      (Envelope envelope) {
        final dynamic content = envelope.content;
        print('>>>>>>>>>> content = $content');

        if (content is! Map<String, dynamic>) {
          return;
        } else if (content['type'] != 'text') {
          return;
        }

        setState(
          () => _messages.add(
            ChatMessage(
              sender: envelope.uuid.value,
              sentDate: envelope.publishedAt.toDateTime(),
              message: content['text'] as String,
            ),
          ),
        );
      },
    );

    _loadMore();
  }

  Future<void> _loadMore() async {
    final List<BatchHistoryResultEntry>? history =
        await PubNubManager().getChannelBatchHistory(
      channel: _channel,
      start: _startDate,
      end: _endDate,
    );

    if (history == null || history.isEmpty) {
      setState(() => _isFirstLoad = false);
      return;
    }

    _startDate = _endDate;
    _endDate = _startDate.subtract(const Duration(days: 14));
    _isFirstLoad = false;

    setState(
      () => _messages.addAll(
        history
            .map(
              (BatchHistoryResultEntry element) => ChatMessage(
                sender: element.uuid!,
                sentDate: element.timetoken.toDateTime(),
                message:
                    (element.message as Map<String, dynamic>)['text'] as String,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (_isFirstLoad)
          const CircularProgressIndicator()
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 150),
            reverse: true,
            itemCount: _messages.length,
            itemBuilder: (_, int i) {
              final ChatMessage message = _messages[_messages.length - 1 - i];

              return Padding(
                padding: EdgeInsets.only(
                  top: i == _messages.length - 1 ? 0 : 30,
                ),
                child: ChatListTile(
                  message: ChatMessage(
                    sender: message.sender,
                    sentDate: message.sentDate,
                    message: message.message,
                  ),
                ),
              );
            },
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _ChatFieldSection(
            onSend: (String message) => _channel.publish(<String, String>{
              'text': message,
              'type': 'text',
            }),
          ),
        ),
      ],
    );
  }
}

//------------------------------------------------------------------------------
class ChatListTile extends StatelessWidget {
  const ChatListTile({
    required this.message,
    super.key,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message.sender,
                style: textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                message.sentDate.toString(),
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                // This color is needed so that emojis won't flicker if it's the
                // last item in the list.
                color: Colors.transparent,
                child: Text(
                  message.message,
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//---------------------------------------------------------------------------
class _ChatFieldSection extends StatefulWidget {
  const _ChatFieldSection({
    required this.onSend,
    super.key,
  });

  final ValueChanged<String> onSend;

  @override
  State<StatefulWidget> createState() => __ChatFieldSectionState();
}

class __ChatFieldSectionState extends State<_ChatFieldSection> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late bool _isFocused = _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_isFocused != _focusNode.hasFocus) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: _isFocused
            ? const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              )
            : null,
        boxShadow: _isFocused
            ? <BoxShadow>[
                BoxShadow(
                  color: colorScheme.onBackground.withOpacity(0.24),
                  spreadRadius: 0,
                  blurRadius: 40,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        onSubmitted: (String message) {
          message = message.trim();

          if (message.isEmpty) {
            return;
          }

          widget.onSend(message);
          _controller.clear();
        },
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.send,
        minLines: 1,
        maxLines: 3,
        maxLength: 275,
      ),
    );
  }
}

//------------------------------------------------------------------------------
class ChatMessage {
  const ChatMessage({
    required this.sender,
    required this.sentDate,
    required this.message,
  });

  final String sender;
  final DateTime sentDate;
  final String message;
}
