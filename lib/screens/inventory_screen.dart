import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List inventory = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    try {
      setState(() => isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final seasonId = prefs.getString('seasonId');

      if (token == null || seasonId == null) {
        _showErrorDialog("Session expired. Please login again.");
        return;
      }

      final response = await http.get(
        Uri.parse(
          "https://mandimatebackend.vercel.app/inventory?seasonId=$seasonId",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          inventory = decoded['data'];
        });
      } else {
        _showErrorDialog("Failed to fetch inventory");
      }
    } catch (e) {
      _showErrorDialog("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openSaleForm(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (ctx) => SaleFormDialog(product: product),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInventory,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              "Add Sale",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              _openSaleForm({});
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.inventory,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Refresh",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: _fetchInventory,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          inventory.isEmpty
                              ? const Center(child: Text("No inventory found"))
                              : ListView.builder(
                                itemCount: inventory.length,
                                itemBuilder: (ctx, i) {
                                  final item = inventory[i];
                                  return _inventoryCard(item);
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _inventoryCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.local_florist, color: Colors.green),
            title: Text(
              item['productName'] ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Unit: ${item['baseUnit']}"),
            trailing: IconButton(
              icon: const Icon(Icons.point_of_sale, color: Colors.green),
              onPressed: () => _openSaleForm(item),
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _detailRow("Total Purchased", "${item['totalPurchasedQty']}"),
                _detailRow("Total Sold", "${item['totalSoldQty']}"),
                _detailRow("Current Qty", "${item['currentQty']}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class SaleFormDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  const SaleFormDialog({super.key, required this.product});

  @override
  State<SaleFormDialog> createState() => _SaleFormDialogState();
}

class _SaleFormDialogState extends State<SaleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _unitPriceCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Add Sale"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(widget.product['productName'] ?? "Select product"),
              const SizedBox(height: 10),
              TextFormField(
                controller: _quantityCtrl,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  prefixIcon: Icon(Icons.scale),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _unitPriceCtrl,
                decoration: const InputDecoration(
                  labelText: "Unit Price",
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _customerCtrl,
                decoration: const InputDecoration(
                  labelText: "Customer Name",
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? "Select Sale Date"
                          : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context); // Abhi sirf band hoga
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sale form submitted (demo)")),
              );
            }
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
