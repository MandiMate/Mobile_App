import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/widgets/SaleReceiptDialog.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mandimate_mobile_app/widgets/drawer.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  bool showForm = false;
  bool isLoading = true;

  // Controllers
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  // Form state
  String? selectedProduct;
  String? selectedUnit;
  DateTime? selectedDate;

  // Data
  List<dynamic> sales = [];

  final List<String> productList = const [
    'Tomato (Tamatar)',
    'Onion (Pyaz)',
    'Potato (Aloo)',
    'Cabbage (Band Gobi)',
    'Carrot (Gajar)',
    'Peas (Matar)',
    'Spinach (Palak)',
    'Garlic (Lahsan)',
    'Ginger (Adrak)',
    'Cucumber (Kheera)',
    'Chili (Mirch)',
    'Brinjal (Baigan)',
    'Cauliflower (Phool Gobi)',
    'Okra (Bhindi)',
    'Bitter Gourd (Karela)',
    'Bottle Gourd (Lauki)',
    'Ridge Gourd (Tori)',
    'Pumpkin (Kaddu)',
    'Radish (Mooli)',
    'Turnip (Shaljam)',
    'Beetroot (Chukandar)',
    'Lady Finger',
    'Capsicum (Shimla Mirch)',
    'Lettuce (Salad Patta)',
    'Mint (Pudina)',
    'Coriander (Dhaniya)',
    'Mustard Greens (Sarson ka Saag)',
    'Leek (Gandana)',
    'Spring Onion',
    'Sweet Potato (Shakarkand)',
    'Tinda',
  ];

  final List<String> unitList = const ["kg", "bag", "quintal", "ton"];

  @override
  void initState() {
    super.initState();
    fetchSales();
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    customerController.dispose();
    dateController.dispose();
    super.dispose();
  }

  // --------------------------
  // Network: Fetch sales
  // --------------------------
  Future<void> fetchSales() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final resp = await http.get(
        Uri.parse("https://mandimatebackend.vercel.app/sale/active"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(resp.body);
        setState(() {
          sales = jsonData["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        debugPrint("fetchSales failed: ${resp.statusCode} ${resp.body}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to fetch sales")));
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("fetchSales error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error fetching sales")));
    }
  }

  // --------------------------
  // Network: Add sale
  // --------------------------
  Future<void> addSale() async {
    // basic validation
    if (selectedProduct == null ||
        selectedUnit == null ||
        quantityController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final seasonId = prefs.getString("seasonId");

      if (token == null || seasonId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Missing token or seasonId")),
        );
        return;
      }

      final body = {
        "productName": selectedProduct!,
        "quantity": int.parse(quantityController.text.trim()),
        "unit": selectedUnit!,
        "unitPrice": int.parse(priceController.text.trim()),
        "customerName": customerController.text.trim(),
        "seasonId": seasonId,
        // NOTE: dateController/selectedDate is NOT sent to backend per your request
      };

      final resp = await http.post(
        Uri.parse("https://mandimatebackend.vercel.app/sale/add"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode(body),
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sale added successfully")),
        );

        // reset form and go back to list
        setState(() {
          showForm = false;
          selectedProduct = null;
          selectedUnit = null;
          selectedDate = null;
          dateController.clear();
          quantityController.clear();
          priceController.clear();
          customerController.clear();
        });

        await fetchSales();
      } else {
        debugPrint("addSale failed: ${resp.statusCode} ${resp.body}");
        String message = "Failed to add sale";
        try {
          final m = json.decode(resp.body);
          if (m is Map && m["message"] != null) message = m["message"];
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$message (${resp.statusCode})")),
        );
      }
    } catch (e) {
      debugPrint("addSale error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error adding sale")));
    }
  }

  // --------------------------
  // Network: Delete sale
  // --------------------------
  Future<void> deleteSale(String saleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) return;

      final resp = await http.delete(
        Uri.parse("https://mandimatebackend.vercel.app/sale/delete/$saleId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sale deleted successfully")),
        );
        await fetchSales();
      } else {
        debugPrint("deleteSale failed: ${resp.statusCode} ${resp.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete sale: ${resp.body}")),
        );
      }
    } catch (e) {
      debugPrint("deleteSale error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error deleting sale")));
    }
  }

  Future<void> fetchSingleSaleAndShowReceipt(String saleId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = "https://mandimatebackend.vercel.app/sale/singleSale/$saleId";
    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token', // agar token required hai
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      showDialog(
        context: context,
        builder:
            (_) =>
                SaleReceiptDialog(body: body), // 👈 yahan naya dialog use karo
      );
    } else {
      // error handle
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching sale receipt")));
    }
  }

  // --------------------------
  // Date picker (sets both DateTime and controller text)
  // --------------------------
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        // display in dd-MM-yyyy (UI only)
        dateController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  // --------------------------
  // Helpers
  // --------------------------
  String formatApiDate(dynamic d) {
    if (d == null) return '-';
    try {
      final s = d.toString();
      if (s.contains('T')) return s.split('T')[0];
      return s;
    } catch (_) {
      return d.toString();
    }
  }

  int toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // --------------------------
  // UI helpers
  // --------------------------
  Widget buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    String? selectedValue,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true, // 👈 force dropdown to take full width
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          filled: true,
          fillColor: Colors.green.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 10,
          ),
        ),
        items:
            items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      maxLines: 1, // 👈 single line
                      overflow:
                          TextOverflow.ellipsis, // 👈 dots (...) lag jayenge
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
    bool readOnly = false,
    void Function()? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.green.shade50,
        ),
      ),
    );
  }

  // --------------------------
  // Build
  // --------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Sales Overview",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // FORM
              // FORM
              if (showForm)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 6,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child:
                              isWide
                                  ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Col 1: Product, Unit
                                      Flexible(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            buildDropdown(
                                              label: "Product Name",
                                              icon: Icons.shopping_bag,
                                              items: productList,
                                              selectedValue: selectedProduct,
                                              onChanged:
                                                  (val) => setState(
                                                    () => selectedProduct = val,
                                                  ),
                                            ),
                                            buildDropdown(
                                              label: "Unit",
                                              icon: Icons.scale,
                                              items: unitList,
                                              selectedValue: selectedUnit,
                                              onChanged:
                                                  (val) => setState(
                                                    () => selectedUnit = val,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Col 2: Quantity, Unit Price
                                      Flexible(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            buildTextField(
                                              label: "Quantity",
                                              icon: Icons.format_list_numbered,
                                              controller: quantityController,
                                              keyboard: TextInputType.number,
                                            ),
                                            buildTextField(
                                              label: "Unit Price",
                                              icon: Icons.attach_money,
                                              controller: priceController,
                                              keyboard: TextInputType.number,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Col 3: Customer, Date (UI only)
                                      Flexible(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            buildTextField(
                                              label: "Customer Name",
                                              icon: Icons.person,
                                              controller: customerController,
                                            ),
                                            buildTextField(
                                              label: "Date",
                                              icon: Icons.date_range,
                                              controller: dateController,
                                              readOnly: true,
                                              onTap: pickDate,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                  : Column(
                                    children: [
                                      buildDropdown(
                                        label: "Product Name",
                                        icon: Icons.shopping_bag,
                                        items: productList,
                                        selectedValue: selectedProduct,
                                        onChanged:
                                            (val) => setState(
                                              () => selectedProduct = val,
                                            ),
                                      ),
                                      buildTextField(
                                        label: "Quantity",
                                        icon: Icons.format_list_numbered,
                                        controller: quantityController,
                                        keyboard: TextInputType.number,
                                      ),
                                      buildDropdown(
                                        label: "Unit",
                                        icon: Icons.scale,
                                        items: unitList,
                                        selectedValue: selectedUnit,
                                        onChanged:
                                            (val) => setState(
                                              () => selectedUnit = val,
                                            ),
                                      ),
                                      buildTextField(
                                        label: "Unit Price",
                                        icon: Icons.attach_money,
                                        controller: priceController,
                                        keyboard: TextInputType.number,
                                      ),
                                      buildTextField(
                                        label: "Customer Name",
                                        icon: Icons.person,
                                        controller: customerController,
                                      ),
                                      buildTextField(
                                        label: "Date",
                                        icon: Icons.date_range,
                                        controller: dateController,
                                        readOnly: true,
                                        onTap: pickDate,
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Save Button (only when form visible)
              if (showForm) const SizedBox(height: 12),
              if (showForm)
                ElevatedButton(
                  onPressed: addSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save Sale",
                    style: TextStyle(fontSize: 16),
                  ),
                ),

              // Add Sale button when list visible
              // Add Sale button when list visible
              if (!showForm) ...[
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // 👈 Button right side par
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => showForm = true);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Sale"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // SALES LIST
              if (!showForm)
                isLoading
                    ? const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchSales,
                        child: ListView.builder(
                          itemCount: sales.length,
                          itemBuilder: (context, index) {
                            final sale = sales[index];

                            final total =
                                toInt(sale['totalAmount']) != 0
                                    ? toInt(sale['totalAmount'])
                                    : (toInt(sale['quantity']) *
                                        toInt(sale['unitPrice']));

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final id = sale['_id']?.toString() ?? '';
                                if (id.isNotEmpty) {
                                  fetchSingleSaleAndShowReceipt(id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Sale id missing"),
                                    ),
                                  );
                                }
                              },
                              child: Card(
                                color: Colors.white,
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sale['productName']?.toString() ??
                                                  '-',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Edit not implemented yet",
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () async {
                                                  final confirmed = await showDialog<
                                                    bool
                                                  >(
                                                    context: context,
                                                    builder:
                                                        (ctx) => AlertDialog(
                                                          title: const Text(
                                                            "Confirm delete",
                                                          ),
                                                          content: const Text(
                                                            "Are you sure you want to delete this sale?",
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        ctx,
                                                                        false,
                                                                      ),
                                                              child: const Text(
                                                                "Cancel",
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        ctx,
                                                                        true,
                                                                      ),
                                                              child: const Text(
                                                                "Delete",
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                  if (confirmed == true) {
                                                    final id =
                                                        sale['_id']
                                                            ?.toString() ??
                                                        '';
                                                    if (id.isNotEmpty)
                                                      deleteSale(id);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Rs ${total.toString()}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Customer: ${sale['customerName']?.toString() ?? '-'}",
                                      ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Quantity: ${sale['quantity']?.toString() ?? '-'} ${sale['unit']?.toString() ?? '-'}",
                                          ),
                                          Text(
                                            "Unit Price: Rs ${sale['unitPrice']?.toString() ?? '-'}",
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Date: ${formatApiDate(sale['saleDate']?.toString() ?? '')}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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
