import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/widgets/drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmerScreen extends StatefulWidget {
  const FarmerScreen({super.key});

  @override
  State<FarmerScreen> createState() => _FarmerScreenState();
}

class _FarmerScreenState extends State<FarmerScreen> {
  List farmers = [];
  List landlords = [];
  String? selectedLandlordId;
  bool isLoading = false;

  // Fetch token from SharedPreferences
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Fetch Farmers
  Future<void> fetchFarmers() async {
    setState(() => isLoading = true);
    final token = await getToken();

    final response = await http.get(
      Uri.parse("https://mandimatebackend.vercel.app/farmer/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        farmers = data["data"];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // Fetch Landlords for dropdown
  Future<void> fetchLandlords() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse("https://mandimatebackend.vercel.app/landlord/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        landlords = data["data"];
      });
    }
  }

  // Add Farmer
  Future<void> addFarmer(String name, String phone, String address) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("https://mandimatebackend.vercel.app/farmer/create"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "name": name,
        "phone": phone,
        "address": address,
        "landlordId": selectedLandlordId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context);
      fetchFarmers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Farmer added successfully")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add farmer")));
    }
  }

  // Update Farmer
  Future<void> updateFarmer(
    String id,
    String name,
    String phone,
    String address,
  ) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse("https://mandimatebackend.vercel.app/farmer/update/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "name": name,
        "phone": phone,
        "address": address,
        "landlordId": selectedLandlordId,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      fetchFarmers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Farmer updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update farmer")));
    }
  }

  // Delete Farmer
  Future<void> deleteFarmer(String id) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse("https://mandimatebackend.vercel.app/farmer/delete/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      fetchFarmers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Farmer deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete farmer")));
    }
  }

  // Show Add/Edit Farmer Dialog
  void showFarmerDialog({
    String? id,
    String? name,
    String? phone,
    String? address,
  }) {
    final nameController = TextEditingController(text: name ?? "");
    final phoneController = TextEditingController(text: phone ?? "");
    final addressController = TextEditingController(text: address ?? "");

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(id == null ? "Add Farmer" : "Edit Farmer"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Farmer Name"),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedLandlordId,
                  hint: const Text("Select Landlord"),
                  items:
                      landlords.map<DropdownMenuItem<String>>((landlord) {
                        return DropdownMenuItem<String>(
                          value: landlord["_id"],
                          child: Text(landlord["name"]),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedLandlordId = value;
                    });
                  },
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
                    addressController.text.isNotEmpty &&
                    selectedLandlordId != null) {
                  if (id == null) {
                    addFarmer(
                      nameController.text,
                      phoneController.text,
                      addressController.text,
                    );
                  } else {
                    updateFarmer(
                      id,
                      nameController.text,
                      phoneController.text,
                      addressController.text,
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                }
              },
              child: Text(id == null ? "Add" : "Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchFarmers();
    fetchLandlords();
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
      drawer: const CustomDrawer(),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : farmers.isEmpty
              ? const Center(child: Text("No Farmers Found"))
              : ListView.builder(
                itemCount: farmers.length,
                itemBuilder: (context, index) {
                  final farmer = farmers[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(farmer["name"]),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phone: ${farmer["phone"]}"),
                          Text("Address: ${farmer["address"]}"),
                          Text("Landlord ID: ${farmer["landlordId"]}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              showFarmerDialog(
                                id: farmer["_id"],
                                name: farmer["name"],
                                phone: farmer["phone"],
                                address: farmer["address"],
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteFarmer(farmer["_id"]);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showFarmerDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Farmer", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }
}
