import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SaleForm extends StatefulWidget {
  final String seasonId;
  const SaleForm({super.key, required this.seasonId});

  @override
  State<SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<SaleForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedUnit;
  List<String> _units = ["kg", "ton", "dozen"];

  // Products
  List<String> _products = [];
  String? _selectedProduct;

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  /// ✅ Fetch Products from Inventory API
  Future<void> _fetchProducts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      var url = Uri.parse(
        "https://mandimatebackend.vercel.app/inventory?seasonId=${widget.seasonId}",
      );
      var response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        var resData = jsonDecode(response.body);
        List items = resData["data"];

        setState(() {
          _products =
              items.map((e) => e["productName"].toString()).toSet().toList();
        });
      } else {
        print("Failed to load products: ${response.body}");
      }
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  /// ✅ Submit Sale API
  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      var url = Uri.parse("https://mandimatebackend.vercel.app/sale/add");

      var body = {
        "productName": _selectedProduct,
        "quantity": int.parse(_quantityController.text.trim()),
        "unit": _selectedUnit,
        "unitPrice": int.parse(_unitPriceController.text.trim()),
        "customerName": _customerNameController.text.trim(),
        "saleDate": DateFormat("dd-MM-yyyy").format(_selectedDate),
        "seasonId": widget.seasonId,
      };

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var resData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resData["message"] ?? "Sale added successfully"),
          ),
        );
        Navigator.pop(context, true); // Go back to inventory screen
      } else {
        print("Failed: ${response.body}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to add sale")));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error submitting sale")));
    }

    setState(() => _isLoading = false);
  }

  /// ✅ Date Picker
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Sale")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// 🔽 Product Dropdown
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedProduct,
                          hint: const Text("Select Product"),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.shopping_cart,
                              color: Colors.green,
                            ),
                          ),
                          items:
                              _products.map((String product) {
                                return DropdownMenuItem(
                                  value: product,
                                  child: Text(product),
                                );
                              }).toList(),
                          onChanged:
                              (val) => setState(() => _selectedProduct = val),
                          validator:
                              (value) =>
                                  value == null
                                      ? "Please select product"
                                      : null,
                        ),
                      ),

                      /// Quantity
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Quantity",
                          prefixIcon: Icon(Icons.scale, color: Colors.green),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? "Enter quantity"
                                    : null,
                      ),

                      /// Unit Dropdown
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          hint: const Text("Select Unit"),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.balance,
                              color: Colors.green,
                            ),
                          ),
                          items:
                              _units.map((String unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                          onChanged:
                              (val) => setState(() => _selectedUnit = val),
                          validator:
                              (value) =>
                                  value == null ? "Please select unit" : null,
                        ),
                      ),

                      /// Unit Price
                      TextFormField(
                        controller: _unitPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Unit Price",
                          prefixIcon: Icon(
                            Icons.monetization_on,
                            color: Colors.green,
                          ),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? "Enter unit price"
                                    : null,
                      ),

                      /// Customer Name
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: "Customer Name",
                          prefixIcon: Icon(Icons.person, color: Colors.green),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? "Enter customer name"
                                    : null,
                      ),

                      /// Sale Date
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat("dd MMM yyyy").format(_selectedDate),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Submit Button
                      ElevatedButton.icon(
                        onPressed: _submitSale,
                        icon: const Icon(Icons.save),
                        label: const Text("Save Sale"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
