import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/widgets/drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List inventory = [];
  bool isLoading = false;

  Future<void> fetchInventory() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final seasonId = prefs.getString("seasonId");
      final token = prefs.getString("token");

      if (seasonId == null || token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Season or token missing!")),
        );
        return;
      }

      final url =
          "https://mandimatebackend.vercel.app/inventory?seasonId=$seasonId";

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          inventory = data["data"];
        });
      } else {
        debugPrint("❌ Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Exception: $e");
    }
    setState(() => isLoading = false);
  }

  Color _getStockColor(int qty) {
    if (qty == 0) return Colors.red;
    if (qty < 50) return Colors.orange;
    return Colors.green;
  }

  String _getStockStatus(int qty) {
    if (qty == 0) return "Out of Stock";
    if (qty < 50) return "Low Stock";
    return "In Stock";
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
        centerTitle: false,
      ),
      drawer: const CustomDrawer(),

      body: RefreshIndicator(
        onRefresh: fetchInventory,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : inventory.isEmpty
                ? const Center(child: Text("No inventory found"))
                : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Heading
                      // Heading Row without buttons
                      // Heading Row
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2,
                            color: Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Inventory",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Inventory Grid
                      Expanded(
                        child: GridView.builder(
                          itemCount: inventory.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemBuilder: (context, index) {
                            final item = inventory[index];
                            final currentQty = item["currentQty"] ?? 0;

                            return Card(
                              color: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item["productName"],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),

                                    // Stock Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStockColor(
                                          currentQty,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStockColor(currentQty),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getStockStatus(currentQty),
                                        style: TextStyle(
                                          color: _getStockColor(currentQty),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Details
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Purchased:",
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          "${item["totalPurchasedQty"]} ${item["baseUnit"]}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Sold:",
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          "${item["totalSoldQty"]} ${item["baseUnit"]}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Available:",
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          "$currentQty ${item["baseUnit"]}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _getStockColor(currentQty),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Spacer(),

                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        "Updated: ${item["updatedAt"].toString().substring(0, 10)}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
