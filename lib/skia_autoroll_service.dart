// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'skia_autoroll.dart';

DateTime _getLastSuccess(Map<String, dynamic> fetchedStatus) {
  final List<dynamic> recent = fetchedStatus['recent_rolls'];
  assert(recent != null);
  DateTime result = DateTime.fromMillisecondsSinceEpoch(0);
  for (Map<String, dynamic> item in recent) {
    result = DateTime.parse(item['modified']);
    if (item['result'] == 'SUCCESS') {
      return result;
    }
  }
  return result;
}

/// See https://autoroll.skia.org/r/flutter-engine-flutter-autoroll
///     https://autoroll.skia.org/r/skia-flutter-autoroll
Future<SkiaAutoRoll> fetchSkiaAutoRollModeStatus(String skiaName,
    {http.Client client}) async {
  client ??= http.Client();
  final Map<String, dynamic> fetchedStatus = await _getStatusBody(skiaName, client);
  assert(fetchedStatus != null);
  final Map<String, dynamic> status = fetchedStatus['status'];
  final Map<String, dynamic> mode = status['mode'];
  assert(mode != null);
  Map<String, dynamic> lastRoll;
  final Map<String, dynamic> currentRoll = status['current_roll'];
  if (currentRoll != null) {
    if (currentRoll.containsKey('result')) {
      lastRoll = currentRoll;
    }
  }
  if (lastRoll == null) {
    lastRoll = status['last_roll'];
  }
  assert(lastRoll != null);
  final DateTime created = DateTime.parse(lastRoll['modified']);
  return SkiaAutoRoll(
      // TODO(aaclarke): find real mode.
      mode: 'running', // mode['mode'],
      lastRollResult: lastRoll['result'],
      created: created,
      lastSuccess: _getLastSuccess(status));
}

// curl -d '{"roller_id": "skia-flutter-autoroll"}' -H 'Content-Type: application/json' https://autoroll.skia.org/twirp/autoroll.rpc.AutoRollService/GetStatus
Future<dynamic> _getStatusBody(String skiaName, http.Client client) async {
  final String postUrl = 'https://autoroll.skia.org/twirp/autoroll.rpc.AutoRollService/GetStatus';
  final Map<String, dynamic> postData = <String, dynamic>{'roller_id': skiaName};
  final String postJson = jsonEncode(postData);
  final http.Response response = await client.post(postUrl, headers: <String, String>{'Content-Type': 'application/json'}, body: postJson);
  if (response.statusCode != 200) {
    throw HttpException('http status:${response.statusCode}');
  }
  final String body = response?.body;
  return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
}
