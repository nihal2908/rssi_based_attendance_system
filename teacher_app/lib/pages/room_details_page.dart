import 'package:flutter/material.dart';

class RoomDetailsPage extends StatefulWidget {
  final String roomId;
  const RoomDetailsPage({required this.roomId, super.key});

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Details')),
      body: Center(child: Text('Room details will be shown here.')),
    );
  }
}
