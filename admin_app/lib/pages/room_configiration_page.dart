import 'package:flutter/material.dart';

import '../controllers/room_controller.dart';
import '../dependency_injection.dart';
import 'data_collection_page.dart';

class RoomConfigurationPage extends StatefulWidget {
  final String roomId;
  const RoomConfigurationPage({super.key, required this.roomId});

  @override
  State<RoomConfigurationPage> createState() => _RoomConfigurationPageState();
}

class _RoomConfigurationPageState extends State<RoomConfigurationPage> {
  final RoomsController controller = sl<RoomsController>();

  final List<TextEditingController> macControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Configuration')),
      body: Column(
        children: [
          Text('Enter the MAC address / BSSID of the transmitors'),
          Form(
            child: Column(
              children: [
                ...macControllers.map(
                  (controller) => TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'MAC Address / BSSID',
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DataCollectionPage(
                          transmitors: macControllers
                              .map((c) => c.text.trim())
                              .where((t) => t.isNotEmpty)
                              .toList(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Start Collecting Data'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
