import 'package:flutter/material.dart';
import 'package:mandimate_mobile_app/widgets/drawer.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> inventory = [
    {
      "productName": "Potato",
      "quantity": 50,
      "unit": "kg",
      "purchasePrice": 2000,
      "salePrice": 2500,
      "lastUpdated": "12-09-2025",
      "status": "In Stock",
    },
    {
      "productName": "Onion",
      "quantity": 10,
      "unit": "kg",
      "purchasePrice": 1000,
      "salePrice": 1200,
      "lastUpdated": "11-09-2025",
      "status": "Low Stock",
    },
    {
      "productName": "Tomato",
      "quantity": 0,
      "unit": "kg",
      "purchasePrice": 1500,
      "salePrice": 1800,
      "lastUpdated": "10-09-2025",
      "status": "Out of Stock",
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case "In Stock":
        return Colors.green;
      case "Low Stock":
        return Colors.orange;
      case "Out of Stock":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Ye function data ko refresh karega (abhi demo ke liye shuffle kar rahe hain)
  Future<void> _refreshInventory() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      inventory.shuffle(); // API call hoti to yahan se new data laate
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Inventory"),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshInventory,
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshInventory,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            itemCount: inventory.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = inventory[index];
              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        size: 40,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item["productName"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text("📦 Quantity: ${item["quantity"]} ${item["unit"]}"),
                      Text("💰 Purchase: ${item["purchasePrice"]}"),
                      Text("💵 Sale: ${item["salePrice"]}"),
                      Text("📅 ${item["lastUpdated"]}"),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            item["status"],
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(item["status"]),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: _getStatusColor(item["status"]),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item["status"],
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(item["status"]),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
