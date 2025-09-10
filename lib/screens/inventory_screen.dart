import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List inventory = [];
  bool isLoading = false;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<String?> getSeasonId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("seasonId"); // active season id stored on start
  }

  // Fetch inventory
  Future<void> fetchInventory() async {
    setState(() => isLoading = true);

    final token = await getToken();
    final seasonId = await getSeasonId();

    final response = await http.get(
      Uri.parse(
        "https://mandimatebackend.vercel.app/inventory?seasonId=$seasonId",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        inventory = data["data"];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // Add Sale
  Future<void> addSale(Map<String, dynamic> saleData) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("https://mandimatebackend.vercel.app/sale/add"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode(saleData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context); // close dialog
      fetchInventory(); // refresh inventory
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sale added successfully")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Failed to add sale")));
    }
  }

  // Sale Form Dialog
  void showAddSaleDialog() {
    final productController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController();
    final priceController = TextEditingController();
    final customerController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Sale"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: productController,
                  decoration: const InputDecoration(labelText: "Product Name"),
                ),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Quantity"),
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: "Unit (e.g., kg)",
                  ),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Unit Price"),
                ),
                TextField(
                  controller: customerController,
                  decoration: const InputDecoration(labelText: "Customer Name"),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: "Sale Date (dd-mm-yyyy)",
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
              onPressed: () async {
                final seasonId = await getSeasonId();

                if (productController.text.isNotEmpty &&
                    qtyController.text.isNotEmpty &&
                    unitController.text.isNotEmpty &&
                    priceController.text.isNotEmpty &&
                    customerController.text.isNotEmpty &&
                    dateController.text.isNotEmpty) {
                  final saleData = {
                    "productName": productController.text,
                    "quantity": int.parse(qtyController.text),
                    "unit": unitController.text,
                    "unitPrice": int.parse(priceController.text),
                    "customerName": customerController.text,
                    "saleDate": dateController.text,
                    "seasonId": seasonId,
                  };

                  addSale(saleData);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠ Please fill all fields")),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchInventory();
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : inventory.isEmpty
              ? const Center(child: Text("No Inventory Found"))
              : ListView.builder(
                itemCount: inventory.length,
                itemBuilder: (context, index) {
                  final item = inventory[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 3,
                    child: ListTile(
                      title: Text(
                        item["productName"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Purchased: ${item["totalPurchasedQty"]} ${item["baseUnit"]}",
                          ),
                          Text(
                            "Sold: ${item["totalSoldQty"]} ${item["baseUnit"]}",
                          ),
                          Text(
                            "Available: ${item["currentQty"]} ${item["baseUnit"]}",
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddSaleDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Sale", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }
}
