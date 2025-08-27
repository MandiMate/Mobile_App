import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/widgets/drawer.dart';

class LandlordPage extends StatefulWidget {
  const LandlordPage({super.key});

  @override
  State<LandlordPage> createState() => _LandlordPageState();
}

class _LandlordPageState extends State<LandlordPage> {
  List landlords = [];
  bool isLoading = false;

  final String apiUrl = "https://mandimatebackend.vercel.app/landlord/";
  final String createUrl =
      "https://mandimatebackend.vercel.app/landlord/create";

  @override
  void initState() {
    super.initState();
    fetchLandlords();
  }

  /// Fetch landlords from API
  Future<void> fetchLandlords() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          landlords = data["data"];
        });
      }
    } catch (e) {
      debugPrint("Error fetching landlords: $e");
    }
    setState(() => isLoading = false);
  }

  /// Add new landlord
  Future<void> addLandlord(String name, String phone, String address) async {
    try {
      final response = await http.post(
        Uri.parse(createUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": name,
          "phone": phone,
          "address": address,
          // TODO: Add agentId here if backend requires it
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchLandlords(); // Refresh list
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Landlord added successfully")),
        );
      } else {
        debugPrint("Response: ${response.body}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to add landlord")));
      }
    } catch (e) {
      debugPrint("Error adding landlord: $e");
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
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone"),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Address"),
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
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      phoneController.text.isNotEmpty &&
                      addressController.text.isNotEmpty) {
                    addLandlord(
                      nameController.text,
                      phoneController.text,
                      addressController.text,
                    );
                  }
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
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
      drawer: const CustomDrawer(), // ✅ your drawer widget

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade200,
                          child: const Icon(Icons.person, color: Colors.black),
                        ),
                        title: Text(
                          landlord["name"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          "${landlord["phone"]}\n${landlord["address"]}",
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddLandlordDialog,
        label: const Text(
          "Add Landlord",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),

        backgroundColor: Colors.green,
      ),
    );
  }
}
