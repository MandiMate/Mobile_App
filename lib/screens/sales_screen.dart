import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/widgets/SaleReceiptDialog.dart';
import 'package:mandimate_mobile_app/widgets/receipt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mandimate_mobile_app/widgets/drawer.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  bool showForm = true;

  final TextEditingController productController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController customerController = TextEditingController();

  List<Map<String, dynamic>> sales = [];

  void addSale() {
    final String product = productController.text.trim();
    final int quantity = int.tryParse(quantityController.text) ?? 0;
    final String unit = unitController.text.trim();
    final int unitPrice = int.tryParse(priceController.text) ?? 0;
    final String customer = customerController.text.trim();

    if (product.isEmpty || quantity <= 0 || unit.isEmpty || unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final int total = quantity * unitPrice;

    setState(() {
      sales.add({
        "product": product,
        "quantity": quantity,
        "unit": unit,
        "unitPrice": unitPrice,
        "customer": customer,
        "total": total,
      });
      showForm = false;

      productController.clear();
      quantityController.clear();
      unitController.clear();
      priceController.clear();
      customerController.clear();
    });
  }

  void editSale(int index) {
    final sale = sales[index];
    productController.text = sale["product"];
    quantityController.text = sale["quantity"].toString();
    unitController.text = sale["unit"];
    priceController.text = sale["unitPrice"].toString();
    customerController.text = sale["customer"];
    setState(() {
      showForm = true;
      sales.removeAt(index);
    });
  }

  void deleteSale(int index) {
    setState(() {
      sales.removeAt(index);
    });
  }

  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   iconTheme: const IconThemeData(color: Colors.black),
      //   elevation: 0,
      //   title: Container(
      //     height: 40,
      //     decoration: BoxDecoration(
      //       color: Colors.grey[200],
      //       borderRadius: BorderRadius.circular(20),
      //     ),
      //     child: const TextField(
      //       decoration: InputDecoration(
      //         hintText: 'Search',
      //         prefixIcon: Icon(Icons.search, color: Colors.grey),
      //         border: InputBorder.none,
      //       ),
      //     ),
      //   ),
      // ),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // Green shades
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
        actions: [
          IconButton(
            onPressed: () {
              // Future: Add quick sale or go to report page
            },
            icon: const Icon(Icons.insert_chart, color: Colors.white),
            tooltip: "Sales Report",
          ),
        ],
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
                                              label: "Date (Not Sent)",
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
                                        label: "Date (Not Sent)",
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
          ],
        ),
      ),
    );
  }
}
