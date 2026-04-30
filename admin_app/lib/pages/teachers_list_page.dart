import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import '../dependency_injection.dart';
import '../models/teacher.dart';

class TeachersListPage extends StatefulWidget {
  const TeachersListPage({super.key});

  @override
  State<TeachersListPage> createState() => _TeachersListPageState();
}

class _TeachersListPageState extends State<TeachersListPage> {
  final DashboardController controller = sl<DashboardController>();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Faculty Directory",
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
              onRefresh: () async => controller.fetchTeachers(),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredTeachers = controller.teachers.where((t) {
                    return t.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        t.email.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        );
                  }).toList();

                  if (filteredTeachers.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTeachers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final teacher = filteredTeachers[index];
                      return _buildTeacherCard(teacher);
                    },
                  );
                },
              ),
            ),
          ),
        ],
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
          hintText: "Search name or department...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherCard(Teacher teacher) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Hero(
          tag: teacher.id,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.orange[50],
            backgroundImage: teacher.avatar != null
                ? NetworkImage(teacher.avatar!)
                : null,
            child: teacher.avatar == null
                ? Icon(Icons.person, color: Colors.orange[700])
                : null,
          ),
        ),
        title: Text(
          teacher.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 4),
            // // Department Tag
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            //   decoration: BoxDecoration(
            //     color: Colors.blueGrey[50],
            //     borderRadius: BorderRadius.circular(6),
            //   ),
            //   child: Text(
            //     teacher.id.toUpperCase(),
            //     style: TextStyle(
            //       fontSize: 10,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.blueGrey[700],
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 4),
            Text(
              teacher.email,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            // Navigate to detailed teacher profile/edit
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No teachers matched your search"),
        ],
      ),
    );
  }
}
