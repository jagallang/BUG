import 'package:flutter/material.dart';

class MissionListView extends StatefulWidget {
  const MissionListView({super.key});

  @override
  State<MissionListView> createState() => _MissionListViewState();
}

class _MissionListViewState extends State<MissionListView> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Mission List View - To be implemented'),
      ),
    );
  }
}