import 'package:flutter/material.dart';
import 'package:pubnub/logging.dart';
import 'package:pubnub_sample/chat_list.dart';
import 'package:pubnub_sample/pubnub_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final StreamLogger logger = StreamLogger.root('myApp', logLevel: Level.all);

  logger.stream.listen((record) {
    print(
        '>>>>>>>>>> [${record.time}] ${Level.getName(record.level)}: ${record.message}');
  });

  await PubNubManager().init();

  provideLogger(logger, () async {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const ChatList(),
    );
  }
}
