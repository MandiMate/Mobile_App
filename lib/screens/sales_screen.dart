import 'package:flutter/material.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (showForm)
              Card(
                elevation: 6,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      buildTextField(
                        label: "Product Name",
                        icon: Icons.shopping_bag,
                        controller: productController,
                      ),
                      buildTextField(
                        label: "Quantity",
                        icon: Icons.format_list_numbered,
                        controller: quantityController,
                        keyboard: TextInputType.number,
                      ),
                      buildTextField(
                        label: "Unit (kg, ton etc.)",
                        icon: Icons.scale,
                        controller: unitController,
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
                      const SizedBox(height: 12),
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
                    ],
                  ),
                ),
              ),
            if (!showForm) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    showForm = true;
                  });
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
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sale["product"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "Rs ${sale['total']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("Customer: ${sale['customer']}"),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Quantity: ${sale['quantity']} ${sale['unit']}",
                                ),
                                Text("Unit Price: Rs ${sale['unitPrice']}"),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => editSale(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deleteSale(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.download,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Download feature coming soon!",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
