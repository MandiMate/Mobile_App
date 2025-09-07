import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandimate_mobile_app/widgets/drawer.dart';
import 'package:mandimate_mobile_app/widgets/receipt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isSaving = false;
  bool loadingLandlords = false;
  bool loadingFarmers = false;

  String? selectedProduct;
  String? selectedLandlord;
  String? selectedFarmer;
  String unit = 'kg';
  DateTime purchaseDate = DateTime.now();

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController advanceController = TextEditingController();
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController paidController = TextEditingController();

  final List<String> productList = const [
    // Common Vegetables (Sabzian)
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

  List<Map<String, dynamic>> landlordList = [];
  List<Map<String, dynamic>> farmerList = [];

  String? seasonId;
  String? token;

  static const Color kPrimary = Color(0xFF2D6A4F);
  static const Color kAccent = Color(0xFF95D5B2);
  static const Color kBg = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
    advanceController.dispose();
    expenseController.dispose();
    paidController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    seasonId = prefs.getString('seasonId');
    token = prefs.getString('token');

    if (token != null) {
      await fetchLandlords();
    }
  }

  Future<void> fetchLandlords() async {
    setState(() => loadingLandlords = true);
    try {
      final response = await http.get(
        Uri.parse('https://mandimatebackend.vercel.app/landlord/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          landlordList = List<Map<String, dynamic>>.from(data);
        });
      } else {
        _toast('Failed to load landlords');
      }
    } catch (e) {
      _toast('Network error');
    } finally {
      setState(() => loadingLandlords = false);
    }
  }

  Future<void> fetchFarmers(String landlordId) async {
    setState(() => loadingFarmers = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://mandimatebackend.vercel.app/farmer/by-landlord/$landlordId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'];
        setState(() {
          farmerList = List<Map<String, dynamic>>.from(data);
        });
      } else {
        _toast('Failed to load farmers');
      }
    } catch (e) {
      _toast('Network error');
    } finally {
      setState(() => loadingFarmers = false);
    }
  }

  double get _qty => double.tryParse(quantityController.text.trim()) ?? 0;
  double get _rate => double.tryParse(unitPriceController.text.trim()) ?? 0;

  Future<void> savePurchase() async {
    print("🟢 savePurchase() called");

    if (!(_formKey.currentState?.validate() ?? false)) {
      _toast('Please fill required fields');
      return;
    }

    if (seasonId == null || token == null) {
      _toast('Missing season or token');
      return;
    }

    setState(() => isSaving = true);

    final body = {
      'productName': selectedProduct,
      'quantity': _qty.toInt(),
      'unit': unit,
      'unitPrice': _rate,
      'advance': double.tryParse(advanceController.text.trim()) ?? 0,
      'expense': double.tryParse(expenseController.text.trim()) ?? 0,
      'paidToFarmer': double.tryParse(paidController.text.trim()) ?? 0,
      'purchaseDate': DateFormat('yyyy-MM-dd').format(purchaseDate),
      'seasonId': seasonId,
      'landlordId': selectedLandlord,
      'farmerId': selectedFarmer,
    };

    try {
      final response = await http.post(
        Uri.parse('https://mandimatebackend.vercel.app/purchase/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      final decodedResponse = json.decode(response.body);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => ReceiptDialog(body: decodedResponse),
      );
    } catch (e) {
      _toast('Network error');
      print(e);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      drawer: const CustomDrawer(),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool wide = constraints.maxWidth > 800;
                  final EdgeInsets pad = EdgeInsets.symmetric(
                    horizontal: wide ? 40 : 16,
                    vertical: 16,
                  );

                  return SingleChildScrollView(
                    padding: pad,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: _buildFormCard(wide: wide),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required bool wide}) {
    final fieldGap = SizedBox(height: wide ? 18 : 14);

    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(wide ? 24 : 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_bag, color: kPrimary),
                  const SizedBox(width: 8),
                  const Text(
                    'Purchase Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (isSaving) const CircularProgressIndicator(strokeWidth: 2),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Wrap(
                runSpacing: 14,
                spacing: 14,
                children: [
                  _wrapItem(wide, _buildProductDropdown()),
                  _wrapItem(wide, _buildLandlordDropdown()),
                  _wrapItem(wide, _buildFarmerDropdown()),
                  _wrapItem(
                    wide,
                    _numberField(
                      controller: quantityController,
                      label: 'Quantity',
                      prefixIcon: Icons.scale,
                      validator: _requiredPositive,
                    ),
                  ),
                  _wrapItem(wide, _unitDropdown()),
                  _wrapItem(
                    wide,
                    _numberField(
                      controller: unitPriceController,
                      label: 'Unit Price',
                      prefixIcon: Icons.monetization_on,
                      validator: _requiredPositive,
                    ),
                  ),
                  _wrapItem(
                    wide,
                    _numberField(
                      controller: advanceController,
                      label: 'Advance',
                      prefixIcon: Icons.payments_outlined,
                    ),
                  ),
                  _wrapItem(
                    wide,
                    _numberField(
                      controller: expenseController,
                      label: 'Expense',
                      prefixIcon: Icons.local_shipping_outlined,
                    ),
                  ),
                  _wrapItem(
                    wide,
                    _numberField(
                      controller: paidController,
                      label: 'Paid to Farmer',
                      prefixIcon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  _wrapItem(wide, _datePickerField()),
                ],
              ),

              fieldGap,

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : savePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon:
                      isSaving
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                  label: Text(
                    isSaving ? 'Saving...' : 'Save Purchase',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wrapItem(bool wide, Widget child) {
    return SizedBox(width: wide ? 420 : double.infinity, child: child);
  }

  Widget _buildProductDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedProduct,
      decoration: _inputDecoration(
        label: 'Product',
        icon: Icons.local_grocery_store,
      ),
      isExpanded: true, // Important for long text
      menuMaxHeight: 300, // Maximum height for dropdown menu
      items:
          productList
              .map(
                (p) => DropdownMenuItem<String>(
                  value: p,
                  child: Text(
                    p,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis, // Handle long text
                  ),
                ),
              )
              .toList(),
      onChanged: (val) => setState(() => selectedProduct = val),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildLandlordDropdown() {
    if (loadingLandlords) {
      return _loadingField(label: 'Loading landlords...');
    }
    return DropdownButtonFormField<String>(
      value: selectedLandlord,
      decoration: _inputDecoration(
        label: 'Landlord',
        icon: Icons.house_siding_outlined,
      ),
      items:
          landlordList
              .map<DropdownMenuItem<String>>(
                (l) => DropdownMenuItem<String>(
                  value: l['_id'].toString(),
                  child: Text(l['name'].toString()),
                ),
              )
              .toList(),
      onChanged: (val) {
        setState(() {
          selectedLandlord = val;
          selectedFarmer = null;
          farmerList.clear();
        });
        if (val != null) fetchFarmers(val);
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildFarmerDropdown() {
    if (loadingFarmers) {
      return _loadingField(label: 'Loading farmers...');
    }
    final hasFarmers = farmerList.isNotEmpty;
    return DropdownButtonFormField<String>(
      value: selectedFarmer,
      decoration: _inputDecoration(
        label: 'Farmer',
        icon: Icons.agriculture_outlined,
      ),
      items:
          farmerList
              .map<DropdownMenuItem<String>>(
                (f) => DropdownMenuItem<String>(
                  value: f['_id'].toString(),
                  child: Text(f['name'].toString()),
                ),
              )
              .toList(),
      onChanged:
          hasFarmers ? (val) => setState(() => selectedFarmer = val) : null,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _unitDropdown() {
    return DropdownButtonFormField<String>(
      value: unit,
      decoration: _inputDecoration(label: 'Unit', icon: Icons.straighten),
      items:
          const ['kg', 'ton', 'crate']
              .map((u) => DropdownMenuItem<String>(value: u, child: Text(u)))
              .toList(),
      onChanged: (val) => setState(() => unit = val ?? 'kg'),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label: label, icon: prefixIcon),
      validator: validator,
    );
  }

  String? _requiredPositive(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null || n <= 0) return 'Enter a valid number';
    return null;
  }

  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: kPrimary) : null,
      filled: true,
      fillColor: const Color(0xFFFDFDFD),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _datePickerField() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: purchaseDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: 'Select purchase date',
          confirmText: 'OK',
          cancelText: 'CANCEL',
        );
        if (picked != null) setState(() => purchaseDate = picked);
      },
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Purchase Date',
          icon: Icons.event_available_outlined,
        ),
        child: Text(DateFormat('dd MMM yyyy').format(purchaseDate)),
      ),
    );
  }

  Widget _loadingField({required String label}) {
    return InputDecorator(
      decoration: _inputDecoration(label: label, icon: Icons.hourglass_top),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
