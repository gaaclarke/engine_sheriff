// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'dart:html';

import 'package:flutter/material.dart';
import 'providers.dart';
import 'skia_autoroll.dart';

import 'package:url_launcher/url_launcher.dart';

class AutoRollWidget extends StatelessWidget {
  const AutoRollWidget({@required this.name, @required this.url});

  final String name;
  final String url;

  String _padLeft(int number) {
    return number.toString().padLeft(2, '0');
  }

  String _formatDate(DateTime dateTime) {
    if (dateTime == null) {
      return '???';
    }
    DateTime local = dateTime.toLocal();
    return '${_padLeft(local.hour)}:${_padLeft(local.minute)} ${local.month}/${local.day}/${local.year}';
  }

  int _calcHoursSinceLastSuccess(DateTime lastSuccess) {
    if (lastSuccess == null) {
      return -1;
    }
    int delta = DateTime.now().millisecondsSinceEpoch -
        lastSuccess.millisecondsSinceEpoch;
    const int millisecondsPerHour = 3600000;
    int hours = (delta / millisecondsPerHour).floor();
    return hours;
  }

  @override
  Widget build(BuildContext context) {
    final SkiaAutoRoll autoRoll = ModelBinding.of<SkiaAutoRoll>(context);
    IconData icon;
    Color backgroundColor;
    int hoursSinceLastSuccess =
        _calcHoursSinceLastSuccess(autoRoll.lastSuccess);
    if (autoRoll.mode == 'running') {
      if (autoRoll.lastRollResult == 'succeeded') {
        icon = Icons.check;
        backgroundColor = Colors.green;
      } else if (autoRoll.lastRollResult == 'failed') {
        icon = Icons.error;
        if (hoursSinceLastSuccess < 24) {
          backgroundColor = Colors.orangeAccent;
        } else {
          backgroundColor = Colors.redAccent;
        }
      }
    } else if (autoRoll.mode == 'stopped') {
      icon = Icons.pause_circle_filled;
      backgroundColor = Colors.amberAccent;
    }
    if (icon == null || backgroundColor == null) {
      icon = Icons.report_problem;
      backgroundColor = Colors.grey;
    }
    return ListTile(
        title: Text(name),
        leading: CircleAvatar(
          child: Icon(icon),
          backgroundColor: backgroundColor,
        ),
        subtitle: Text(
            '''Last roll ${autoRoll.lastRollResult} at: ${_formatDate(autoRoll.created)}
Time since last success: $hoursSinceLastSuccess hrs'''),
        isThreeLine: true,
        onTap: () => launch(url)); // window.open(url, '_blank'));
  }
}
