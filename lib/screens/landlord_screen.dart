import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/widgets/drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandlordPage extends StatefulWidget {
  const LandlordPage({super.key});

  @override
  State<LandlordPage> createState() => _LandlordPageState();
}

class _LandlordPageState extends State<LandlordPage> {
  List landlords = [];
  bool isLoading = false;
  final String baseUrl = 'https://mandimatebackend.vercel.app';

  @override
  void initState() {
    super.initState();
    fetchLandlords();
  }

  /// Fetch landlords from API
  Future<void> fetchLandlords() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Auth token missing. Please login again."),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/landlord/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          landlords = jsonData['data'] ?? [];
        });
      } else {
        debugPrint("Failed to fetch landlords: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to fetch landlords: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fetching landlords: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error occurred while fetching landlords"),
        ),
      );
    }
    setState(() => isLoading = false);
  }

  /// Add new landlord
  Future<void> addLandlord(String name, String phone, String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Auth token missing. Please login again."),
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/landlord/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name, 'phone': phone, 'address': address}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonData['message'] ?? "Landlord added successfully"),
          ),
        );
        fetchLandlords(); // Refresh list
      } else {
        debugPrint("Failed to add landlord: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add landlord: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error adding landlord: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred while adding landlord")),
      );
    }
  }

  /// Show form dialog
  void showAddLandlordDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Add Landlord"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Name",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: "Phone",
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: "Address",
                      prefixIcon: const Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      phoneController.text.isNotEmpty &&
                      addressController.text.isNotEmpty) {
                    addLandlord(
                      nameController.text,
                      phoneController.text,
                      addressController.text,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                  }
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  /// Confirm Delete Dialog
  void confirmDelete(String landlordId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Delete Landlord",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Are you sure you want to delete this landlord? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog before deleting
                  deleteLandlord(landlordId);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  /// Delete Landlord API
  Future<void> deleteLandlord(String landlordId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Auth token missing. Please login again."),
          ),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/landlord/delete/$landlordId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonData['message'] ?? "Landlord deleted successfully",
            ),
          ),
        );
        fetchLandlords(); // Refresh list to update UI
      } else {
        debugPrint("Failed to delete landlord: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete landlord: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting landlord: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred while deleting landlord")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      drawer: const CustomDrawer(), // your drawer widget

      body: RefreshIndicator(
        onRefresh: fetchLandlords,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : landlords.isEmpty
                ? const Center(child: Text("No landlords found."))
                : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: landlords.length,
                  itemBuilder: (context, index) {
                    final landlord = landlords[index];
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.person, color: Colors.black),
                        ),
                        title: Text(
                          landlord["name"] ?? "Unknown",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(landlord["phone"] ?? "No phone"),
                            Text(landlord["address"] ?? "No address"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed:
                              () => confirmDelete(
                                landlord["_id"],
                              ), // confirm dialog
                        ),
                      ),
                    );
                  },
                ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddLandlordDialog,
        label: const Text("Add Landlord"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
