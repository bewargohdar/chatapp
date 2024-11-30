import 'package:flutter/material.dart';

AppBar mainAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text(title),
    centerTitle: false,
    actions: actions,
  );
}
