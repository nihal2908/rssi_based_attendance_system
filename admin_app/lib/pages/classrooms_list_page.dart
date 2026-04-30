import 'package:admin_app/models/classroom.dart';
import 'package:admin_app/pages/add_classroom_page.dart';
import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import '../dependency_injection.dart';
import 'classroom_details_page.dart';

class ClassroomsListPage extends StatefulWidget {
  const ClassroomsListPage({super.key});

  @override
  State<ClassroomsListPage> createState() => _ClassroomsListPageState();
}

class _ClassroomsListPageState extends State<ClassroomsListPage> {
  final DashboardController controller = sl<DashboardController>();
  String searchQuery = "";

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchClassrooms();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Classroom Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => controller.fetchClassrooms(),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filter logic: Match name or location
                  final filteredRooms = controller.classrooms.where((room) {
                    final nameMatch = room.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    );
                    final locationMatch = room.location.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    );
                    return nameMatch || locationMatch;
                  }).toList();

                  if (filteredRooms.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.classrooms.length,
                    itemBuilder: (context, index) {
                      final room = controller.classrooms[index];
                      return _buildRoomCard(room);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClassroomPage()),
          );
        },
        backgroundColor: Colors.purple[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Room", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildRoomCard(Classroom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassroomDetailsPage(classroomId: room.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Cap: ${room.capacity}",
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Location: ${room.location}",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              const Text(
                "Available Tech:",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (room.devices as List)
                    .map(
                      (device) => Chip(
                        label: Text(
                          device,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Colors.grey[100],
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        onChanged: (val) => setState(() => searchQuery = val),
        decoration: InputDecoration(
          hintText: "Search room name or location...",
          prefixIcon: const Icon(Icons.search, color: Colors.purple),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No rooms found matching '$searchQuery'",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
