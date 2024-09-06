import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SecondPage extends StatefulWidget {
  SecondPage({this.payload, this.path, super.key});
  String? payload;
  String? path;

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("payload ${widget.payload!}"),
      ),
      body: Container(
        child: Center(child: Text("path ${widget.path}")),
      ),
    );
  }
}
