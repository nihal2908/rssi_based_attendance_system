import 'package:flutter/material.dart';
import 'package:student_app/controllers/face_id_controller.dart';

import '../dependency_injection.dart';

class ConfigureFaceIdPage extends StatefulWidget {
  const ConfigureFaceIdPage({super.key});

  @override
  State<ConfigureFaceIdPage> createState() => _ConfigureFaceIdPageState();
}

class _ConfigureFaceIdPageState extends State<ConfigureFaceIdPage> {
  final FaceIdController controller = sl<FaceIdController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure Face ID')),
      body: Center(
        child: FutureBuilder(
          future: controller.checkRequestStatus(),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error.toString()}');
            }
            final data = snapshot.data as Map<String, dynamic>;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Request status: ${data['request_status'] ?? 'N/A'}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    controller.initiateFaceIdSetup();
                  },
                  child: const Text('Initiate Face ID Setup'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
