import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_demo_debug/raycaster_page.dart';
import 'package:flutter_demo_debug/rotation_ring_page.dart';
import 'package:flutter_demo_debug/webgl_camera_array.dart';
import 'package:flutter_demo_debug/webgl_geometries.dart';

import 'games_fps.dart';
import 'lz_crc.dart';
import 'lz_data_utils.dart';
import 'webgl_loader_obj.dart';
import 'webgl_loader_obj_mtl.dart';

void main() {
  runApp(const MyApp());
  final result = compute(fibonacci, 20);
  result.then((value) {
    print('Fibonacci: $value');
  });
}

int fibonacci(int n) {
  if (n == 0 || n == 1) {
    return n;
  }
  return fibonacci(n - 1) + fibonacci(n - 2);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<int> bytes = [];

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  void initState() {
    loadDatFile();
    // var intList1 = (decimalNumber: 100000, isEndianBig: false);
    // print('十进制 转 List<int> ========:$intList1');
    // var intList2 = tenToUnit8List(decimalNumber: 100000, isEndianBig: true);
    // print('十进制 转 List<int> ========:$intList2');

    // unit8ListToTen(intList: [160, 134, 1, 0], isEndianBig: true);
    // unit8ListToTen(intList: [0, 1, 134, 160], isEndianBig: false);
    sendListData(
        [36, 20, 0, 0, 161, 34, 223, 85, 136, 15, 229, 117, 30, 67, 96, 235]);
    int end = 0;
    // do {
    //   i++;
    //   print('$i========');
    // } while (i <= 50000);
    for (int i = 0; i < 500; i++) {
      for (int j = 0; j < 100; j++) {
        end = i;
      }
    }
    print('$end========');
    super.initState();
  }

  /// 十进制 转 List<int>
  List<int> tenToUnit8List(
      {required int decimalNumber, bool isEndianBig = false}) {
    ///isEndianBig 数组第一位存数据最高位，后面依次储存 true
    // int decimalNumber = 100000;
    List<int> intList = [];
    intList.add((decimalNumber & 0xFF000000) >> 24);
    intList.add((decimalNumber & 0x00FF0000) >> 16);
    intList.add((decimalNumber & 0x0000FF00) >> 8);
    intList.add(decimalNumber & 0x000000FF);

    print('十进制 转 List<int> ========:$intList'); // 输出 [0, 1, 134, 160]
    return isEndianBig ? intList.reversed.toList() : intList;
  }

  ///List<int> 转 十进制
  int unit8ListToTen({required List<int> intList, bool isEndianBig = true}) {
    // List<int> intList = [160, 134, 1, 0];

    int decimalNumber = 0;
    if (isEndianBig) {
      decimalNumber = (intList[3] << 24) +
          (intList[2] << 16) +
          (intList[1] << 8) +
          intList[0];
    } else {
      decimalNumber = (intList[0] << 24) +
          (intList[1] << 16) +
          (intList[2] << 8) +
          intList[3];
    }

    print(decimalNumber); // 输出 100000

    print('List<int> 转 十进制 ========:$decimalNumber'); // 输出 100000
    return decimalNumber;
  }

//14.蓝牙发送的数据， CRC 32 校验，生成数组
  Future<List<int>> sendListData(List dataList) async {
    //CRC 32 校验
    int crc32 = LZCrcUtil().checkSum(dataList, 16);

    print('0x16 CRC 校验 strList  =============================== $crc32');

    //字符串按 2 位分割为数组
    List<int> resultList =
        tenToUnit8List(decimalNumber: crc32, isEndianBig: true);

    print('0x16 CRC 校验 strList  =============================== $resultList');

    return resultList;
  }

  Future<void> loadDatFile() async {
    String longString =
        "This is a string containing v11.1,version numbers like 1.2 , 2.22.0,and v33.0.9, some other text.";

    RegExp versionRegex = RegExp(r'\bv?\d+\.\d+(\.\d+)?\b');
    bool containsVersion = versionRegex.hasMatch(longString);
    Iterable<Match> matches = versionRegex.allMatches(longString);
    print('Found version number $containsVersion');
    for (Match match in matches) {
      print('Found version number: ${match.group(0)}');
    }
    // ByteData data =
    //     await rootBundle.load('assets/obj/male02/UPD1618FEV111.dat');
    // bytes = data.buffer.asUint8List();
  }

  ///开启线程持续发送
  void _n32SendDataIsolate(Map<String, dynamic> value) async {
    var stream =
        await compute<Map<String, dynamic>, Stream>(_n32SendDataLoop, value);
    stream.listen((event) {
      print('回调过来的数据====$event');
    });
    // print('回调过来的数据====$resJson');

    // var model = DatSendModel.fromJson(resJson);
    // print('回调过来的数据====${model.isCompleted} === ${model.progress} === ${model.datNum} === ${model.index}');
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      // body: const WebGlLoaderObj(
      //   fileName: 'webgl_loader_obj',
      // ),
      body: Column(
        children: [
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WebGlLoaderObj(
                              fileName: 'webgl_loader_obj',
                            )));
              },
              child: Text('obj')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WebGlLoaderObjLtl(
                              fileName: 'webgl_loader_obj_ltl',
                            )));
              },
              child: Text('obj + mtl')),
          ElevatedButton(
              onPressed: () {
                print(
                    '解析bin文件:==========${bytes.length} \n ${bytes.sublist(bytes.length - 17, bytes.length)}');
              },
              child: Text('解析bin文件')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GamesFpsPage(
                              fileName: 'GamesFpsPage',
                            )));
              },
              child: Text('GamesFpsPage')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WebglGeometries(
                              fileName: 'webgl_geometries',
                            )));
              },
              child: Text('webgl_geometries')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RaycasterPage(
                              fileName: 'RaycasterPage',
                            )));
              },
              child: Text('RaycasterPage')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RotationRingPage(
                              fileName: 'RotationRingPage',
                            )));
              },
              child: Text('RotationRingPage')),
        ],
      ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void showEmoji() {
    String inputText = '输入[smile:]以显示微笑表情';
    RegExp pattern = RegExp(r'\[(\w+):\]'); // 自定义规则：匹配以[开头，以]结尾，中间包含一个或多个字母或数字

    var matches = pattern.allMatches(inputText);

    for (RegExpMatch match in matches) {
      String command = match.group(0) ?? '';
      if (command == 'smile') {
        print('显示微笑表情');
      }
    }
  }
}

class UnityWidgetPage extends StatelessWidget {
  const UnityWidgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
        // child: UnityWidget(onUnityCreated: onUnityCreated),

        );
  }

  void onUnityCreated(controller) {
    // 加载.blend格式的模型文件
    controller.postMessage(
        'YourScript', 'LoadModel', 'assets/html/Challenger.blend');
  }
}

int index = 0;
int datNum = 0;

Stream<Map<String, dynamic>> _n32SendDataLoop(Map<String, dynamic> value) {
  var controller = StreamController<Map<String, dynamic>>();

  List<int> list = value['list'];

  sendData(list, controller);

  return controller.stream;
}

Future<void> sendData(
    List<int> list, StreamController<Map<String, dynamic>> controller) async {
  num currentProgress = (index / (list.length / 10)) * 100;

  bool isCompleted = false;
  if (datNum == list.length) {
    print('===发送结束===');
    isCompleted = true;
    controller.add({
      "progress": currentProgress,
      "isCompleted": isCompleted,
      "index": index,
      "datNum": datNum
    });
    controller.close();
    return;
  }

  List<int> tmpList = list.sublist(datNum, datNum + 10);

  print('===发送=== $tmpList');
  datNum = datNum + 10;
  index = index + 1;

  controller.add({
    "progress": currentProgress,
    "isCompleted": isCompleted,
    "index": index,
    "dataIndex": datNum
  });

  sendData(list, controller);
}
