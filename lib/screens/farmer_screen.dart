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

  // Add Farmer - Fixed version
  Future<void> addFarmer(
    String name,
    String phone,
    String address,
    String landlordId,
  ) async {
    final token = await getToken();

    print("=== ADD FARMER DEBUG ===");
    print("Name: $name");
    print("Phone: $phone");
    print("Address: $address");
    print("Landlord ID: $landlordId");

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
        "landlordId": landlordId, // Pass landlordId directly
      }),
    );

    print("Add Response Status: ${response.statusCode}");
    print("Add Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context);
      fetchFarmers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Farmer added successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add farmer: ${response.body}")),
      );
    }
  }

  // Update Farmer - Fixed version
  Future<void> updateFarmer(
    String id,
    String name,
    String phone,
    String address,
    String landlordId,
  ) async {
    final token = await getToken();

    print("=== UPDATE FARMER DEBUG ===");
    print("ID: $id");
    print("Name: $name");
    print("Phone: $phone");
    print("Address: $address");
    print("Landlord ID: $landlordId");

    final response = await http.patch(
      Uri.parse("https://mandimatebackend.vercel.app/farmer/update/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "name": name,
        "phone": phone,
        "address": address,
        "landlordId": landlordId, // Pass landlordId directly
      }),
    );

    print("Update Response Status: ${response.statusCode}");
    print("Update Response Body: ${response.body}");

    if (response.statusCode == 200) {
      Navigator.pop(context);
      fetchFarmers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Farmer updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update farmer: ${response.body}")),
      );
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

  // Helper function to get landlord name by ID
  String getLandlordName(String landlordId) {
    final landlord = landlords.firstWhere(
      (l) => l["_id"] == landlordId,
      orElse: () => {"name": "Unknown Landlord"},
    );
    return landlord["name"];
  }

  // Helper function to get landlord name from populated data
  String getLandlordNameFromPopulated(dynamic landlordData) {
    if (landlordData is Map && landlordData.containsKey("name")) {
      return landlordData["name"];
    } else if (landlordData is String) {
      return getLandlordName(landlordData);
    }
    return "Unknown Landlord";
  }

  // Fixed Dialog - separate landlordId for dialog state
  void showFarmerDialog({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? existingLandlordId,
  }) {
    final nameController = TextEditingController(text: name ?? "");
    final phoneController = TextEditingController(text: phone ?? "");
    final addressController = TextEditingController(text: address ?? "");

    // Use local variable instead of global selectedLandlordId
    String? dialogLandlordId = existingLandlordId;

    print("=== DIALOG OPEN DEBUG ===");
    print("Edit Mode: ${id != null}");
    print("Initial Landlord ID: $dialogLandlordId");

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(id == null ? "Add Farmer" : "Edit Farmer"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Farmer Name",
                      ),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                      ),
                    ),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: dialogLandlordId,
                      hint: const Text("Select Landlord"),
                      items:
                          landlords.map<DropdownMenuItem<String>>((landlord) {
                            return DropdownMenuItem<String>(
                              value: landlord["_id"],
                              child: Text(landlord["name"]),
                            );
                          }).toList(),
                      onChanged: (value) {
                        print("Dropdown changed to: $value");
                        setDialogState(() {
                          dialogLandlordId = value;
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
                    print("=== FORM SUBMIT DEBUG ===");
                    print("Name: '${nameController.text}'");
                    print("Phone: '${phoneController.text}'");
                    print("Address: '${addressController.text}'");
                    print("Dialog Landlord ID: '$dialogLandlordId'");

                    if (nameController.text.isNotEmpty &&
                        phoneController.text.isNotEmpty &&
                        addressController.text.isNotEmpty &&
                        dialogLandlordId != null) {
                      if (id == null) {
                        // ADD: Pass landlordId as parameter
                        addFarmer(
                          nameController.text,
                          phoneController.text,
                          addressController.text,
                          dialogLandlordId!, // Pass landlordId directly
                        );
                      } else {
                        // UPDATE: Pass landlordId as parameter
                        updateFarmer(
                          id,
                          nameController.text,
                          phoneController.text,
                          addressController.text,
                          dialogLandlordId!, // Pass landlordId directly
                        );
                      }
                    } else {
                      print("Validation failed - missing fields");
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

                  // Extract landlordId properly (map or string)
                  String? landlordId;
                  if (farmer["landlordId"] is Map) {
                    landlordId = farmer["landlordId"]["_id"];
                  } else {
                    landlordId = farmer["landlordId"];
                  }

                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          farmer["name"].toString().isNotEmpty
                              ? farmer["name"][0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        farmer["name"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${farmer["phone"]}"),
                          Text("${farmer["address"]}"),
                          Text(
                            "Landlord: ${getLandlordNameFromPopulated(farmer["landlordId"])}",
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
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
                                existingLandlordId: landlordId,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteFarmer(farmer["_id"]),
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
