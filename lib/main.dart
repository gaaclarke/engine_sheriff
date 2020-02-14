// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_sheriff/skia_autoroll.dart';
import 'package:flutter/material.dart';
import 'roll.dart';
import 'providers.dart';

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
