// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'skia_autoroll.dart';

DateTime _getLastSuccess(Map<String, dynamic> fetchedStatus) {
  final Map<String, dynamic> lastRoll = fetchedStatus['lastRoll'];
  assert(lastRoll != null);
  final List<dynamic> recent = fetchedStatus['recent'];
  assert(recent != null);
  DateTime result = DateTime.fromMillisecondsSinceEpoch(0);
  for (Map<String, dynamic> item in recent) {
    result = DateTime.parse(item['created']);
    if (item['result'] == 'succeeded') {
      return result;
    }
  }
  return result;
}

/// See https://autoroll.skia.org/r/flutter-engine-flutter-autoroll
///     https://autoroll.skia.org/r/skia-flutter-autoroll
Future<SkiaAutoRoll> fetchSkiaAutoRollModeStatus(String url,
    {http.Client client}) async {
  client ??= http.Client();
  final Map<String, dynamic> fetchedStatus = await _getStatusBody(url, client);
  assert(fetchedStatus != null);
  final Map<String, dynamic> mode = fetchedStatus['mode'];
  assert(mode != null);
  final Map<String, dynamic> lastRoll = fetchedStatus['lastRoll'];
  assert(lastRoll != null);
  final DateTime created = DateTime.parse(lastRoll['created']);
  return SkiaAutoRoll(
      mode: mode['mode'],
      lastRollResult: lastRoll['result'],
      created: created,
      lastSuccess: _getLastSuccess(fetchedStatus));
}

Future<dynamic> _getStatusBody(String url, http.Client client) async {
  final http.Response response = await client.get(url);
  if (response.statusCode != 200) {
    throw HttpException('http status:${response.statusCode}');
  }
  final String body = response?.body;
  return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
}
