// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_sheriff/skia_autoroll.dart';
import 'package:flutter/material.dart';
import 'roll.dart';
import 'providers.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: '🤠 Engine Sheriff'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Future<bool> _isLuciTreeGreen(String url, int expectedCount) async {
  var response = await http.get(url);
  if (response.statusCode == 200) {
    final RegExp exp = new RegExp(r"console-Success");
    final Iterable<RegExpMatch> matches = exp.allMatches(response.body);
    final int count = matches.toList().length;
    return count == expectedCount;
  } else {
    throw HttpException('Request failed with status: ${response.statusCode}.');
  }
}

class _LuciRefreshingWidget extends StatefulWidget {
  final String url;
  final int expectedCount;
  final String name;

  _LuciRefreshingWidget(this.name, this.url, this.expectedCount);

  @override
  State<StatefulWidget> createState() {
    return _LuciRefreshingState(this.name, this.url, this.expectedCount);
  }
}

enum TreeStatus {
  UNKNOWN,
  GREEN,
  RED,
}

class _LuciRefreshingState extends State<_LuciRefreshingWidget> {
  final String url;
  final int expectedCount;
  final String name;
  Timer _timer;
  TreeStatus _status = TreeStatus.UNKNOWN;

  _LuciRefreshingState(this.name, this.url, this.expectedCount) {
    _timer = Timer.periodic(Duration(minutes: 5), _tick);
    _tick(null);
  }

  void _tick(Timer timer) async {
    bool isGreen = await _isLuciTreeGreen(url, expectedCount);
    setState(() {
      _status = isGreen ? TreeStatus.GREEN : TreeStatus.RED;
    });
  }

  void cancel() {
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color backgroundColor;
    switch (_status) {
      case TreeStatus.UNKNOWN:
        icon = Icons.report_problem;
        backgroundColor = Colors.grey;
        break;
      case TreeStatus.GREEN:
        icon = Icons.check;
        backgroundColor = Colors.green;
        break;
      case TreeStatus.RED:
        icon = Icons.error;
        backgroundColor = Colors.redAccent;
        break;
    }
    return ListTile(
        title: Text(name),
        leading: CircleAvatar(
          child: Icon(icon),
          backgroundColor: backgroundColor,
        ),
        subtitle: Text(''),
        isThreeLine: true,
        onTap: () => launch(url));
  }
}

class _RefreshingAutoRollWidget extends StatelessWidget {
  final String statusUrl;
  final String infoUrl;
  final String name;

  const _RefreshingAutoRollWidget(this.name, infoUrl)
      : statusUrl = '$infoUrl/json/status',
        infoUrl = infoUrl;

  @override
  Widget build(BuildContext context) {
    return ModelBinding<SkiaAutoRoll>(
      initialModel: SkiaAutoRoll(),
      child: RefreshAutoRoll(
        url: statusUrl,
        child: AutoRollWidget(
          name: name,
          url: infoUrl,
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _LuciRefreshingWidget('Engine LUCI',
                'https://ci.chromium.org/p/flutter/g/engine/console', 12),
            const _RefreshingAutoRollWidget('Engine → Framework',
                'https://autoroll.skia.org/r/flutter-engine-flutter-autoroll'),
            const _RefreshingAutoRollWidget('Dart → Engine',
                'https://autoroll.skia.org/r/dart-sdk-flutter-engine'),
            const _RefreshingAutoRollWidget('Skia → Engine',
                'https://autoroll.skia.org/r/skia-flutter-autoroll'),
          ],
        ),
      ),
    );
  }
}
