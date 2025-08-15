import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/screens/addPurchase.dart';
import 'package:mandimate_mobile_app/widgets/drawer.dart';
import 'package:mandimate_mobile_app/widgets/receipt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeasonOverviewScreen extends StatefulWidget {
  const SeasonOverviewScreen({super.key});

  @override
  State<SeasonOverviewScreen> createState() => _SeasonOverviewScreenState();
}

class _SeasonOverviewScreenState extends State<SeasonOverviewScreen> {
  // --- UI/State ---
  bool _loading = true;
  bool _hasActiveSeason = false;
  Map<String, dynamic>? _season; // active season object
  bool _createModalShownOnce = false;
  List<Map<String, dynamic>> _purchases = [];
  bool _loadingPurchases = false;

  // --- Form controllers for Create Season modal (name required; date just for UI) ---
  final TextEditingController _seasonNameCtrl = TextEditingController();
  final TextEditingController _startDateCtrl = TextEditingController();
  DateTime? _startDate;

  static const String _activeSeasonUrl =
      'https://mandimatebackend.vercel.app/season/active';
  static const String _startSeasonUrl =
      'https://mandimatebackend.vercel.app/season/start';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _checkActiveSeason();
    // If not active, open create modal (only once)
    if (mounted && !_hasActiveSeason && !_createModalShownOnce) {
      _createModalShownOnce = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openCreateSeasonModal(),
      );
    }
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Try dedicated "token" key first
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) return token;

    // Fallback: inside saved "user" json
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        if (map['token'] is String) return map['token'];
        if (map['accessToken'] is String) return map['accessToken'];
      } catch (_) {}
    }
    return null;
  }

  Future<void> _checkActiveSeason() async {
    setState(() => _loading = true);
    try {
      final token = await _getAuthToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _hasActiveSeason = false;
            _season = null;
          });
        }
        _showSnack('Auth token not found. Please login again.');
        return;
      }

      final resp = await http.get(
        Uri.parse(_activeSeasonUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final season = data['season'] as Map<String, dynamic>?;
        final active = (season?['isActive'] ?? false) == true;

        if (mounted) {
          setState(() {
            _season = season;
            _hasActiveSeason = active;
            _loading = false;
          });
          await _fetchPurchasesForActiveSeason();
        }

        // Save seasonId locally if present
        if (season != null && season['_id'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('seasonId', season['_id'].toString());
        }
      } else if (resp.statusCode == 404) {
        // No active season
        if (mounted) {
          setState(() {
            _season = null;
            _hasActiveSeason = false;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
        _showSnack('Failed to check season (${resp.statusCode}).');
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _showSnack('Network error: $e');
    }
  }

  Future<void> _fetchPurchasesForActiveSeason() async {
    setState(() => _loadingPurchases = true);

    try {
      final token = await _getAuthToken(); // yeh already aapke code me hai
      if (token == null) return;

      final response = await http.get(
        Uri.parse("https://mandimatebackend.vercel.app/purchase/active-season"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data["data"] as List<dynamic>? ?? [];
        setState(() {
          _purchases =
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      } else {
        final err = json.decode(response.body);
        _showSnack(err["message"] ?? "Failed to fetch purchases");
      }
    } catch (e) {
      _showSnack("Error fetching purchases: $e");
    } finally {
      setState(() => _loadingPurchases = false);
    }
  }

  Future<bool> _createSeasonAPI({required String name}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        _showSnack('Auth token not found. Please login again.');
        return false;
      }

      final resp = await http.post(
        Uri.parse(_startSeasonUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name, // only name required by backend
        }),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final created = data['season'] as Map<String, dynamic>?;

        if (created != null) {
          // Save seasonId
          final prefs = await SharedPreferences.getInstance();
          if (created['_id'] != null) {
            await prefs.setString('seasonId', created['_id'].toString());
          }

          if (mounted) {
            setState(() {
              _season = created;
              _hasActiveSeason = true;
            });
          }
          _showSnack('Season started successfully.');
          return true;
        } else {
          _showSnack('Unexpected response from server.');
          return false;
        }
      } else {
        // Try to parse error message
        try {
          final err = jsonDecode(resp.body);
          _showSnack(err['message']?.toString() ?? 'Failed to start season.');
        } catch (_) {
          _showSnack('Failed to start season (${resp.statusCode}).');
        }
        return false;
      }
    } catch (e) {
      _showSnack('Network error: $e');
      return false;
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // -------------------------------------------
  // UI Pieces
  // -------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  // Top heading + actions
  Widget _buildTopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row + actions (buttons)
        Row(
          children: [
            const Expanded(
              child: Text(
                'Season Overview',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _hasActiveSeason
                        ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPurchaseScreen(),
                            ),
                          );
                        }
                        : null,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Add Purchase'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return Colors.green.shade200;
                    }
                    return Colors.green.shade600;
                  }),
                  foregroundColor: const WidgetStatePropertyAll<Color>(
                    Colors.white,
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _hasActiveSeason
                        ? () {
                          // TODO: end season confirmation + API
                        }
                        : null,
                icon: const Icon(Icons.flag_circle),
                label: const Text('End Season'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return Colors.red.shade200;
                    }
                    return Colors.redAccent;
                  }),
                  foregroundColor: const WidgetStatePropertyAll<Color>(
                    Colors.white,
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Season small info row (icon + name + date + filter)
        if (_hasActiveSeason && _season != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEFF7EE),
                  child: Icon(Icons.eco, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _season?['name']?.toString() ?? '—',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _season?['startDate'] != null
                                ? _formatDate(
                                  DateTime.parse(
                                    _season!['startDate'].toString(),
                                  ),
                                )
                                : 'No Start Date',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // Create Season Modal (opens when no active season)

  void _openCreateSeasonModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Season Modal',
      barrierColor: Colors.black.withOpacity(
        0.4,
      ), // Semi-transparent background
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // Background blur
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(ctx).size.width * 0.85,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🌿 Start New Season',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _seasonNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Season Name',
                        hintText: 'e.g. Winter 2025',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _startDateCtrl,
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            hintText: 'Select date',
                            suffixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _onCreateSeasonPressed,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text(
                              'Create',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: _startDate ?? now,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateCtrl.text = _formatDate(picked);
      });
    }
  }

  Future<void> _onCreateSeasonPressed() async {
    final name = _seasonNameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter season name.');
      return;
    }

    // Call Create Season API
    final ok = await _createSeasonAPI(name: name);

    if (!mounted) return;

    // Close modal and refresh state if success
    if (ok) {
      Navigator.pop(context);
      await _checkActiveSeason();
    }
  }

  // -------------------------------------------
  // Build
  // -------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: const CustomDrawer(),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _checkActiveSeason,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopHeader(),
                      const SizedBox(height: 16),

                      if (!_hasActiveSeason) _buildNoActiveSeasonBanner(),

                      if (_hasActiveSeason) _buildActiveSeasonPurchases(),
                    ],
                  ),
                ),
              ),
    );
  }

  // Banner shown when no active season (gentle prompt)
  Widget _buildNoActiveSeasonBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.grey),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No active season found. Create a new season to begin tracking.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: _openCreateSeasonModal,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSeasonPurchases() {
    if (_loadingPurchases) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_purchases.isEmpty) {
      return const Text("No purchases found for this season");
    }

    return Column(
      children: List.generate(_purchases.length, (index) {
        final p = _purchases[index];
        final String displayId = "000${index + 1}";
        final String originalId = p["_id"];

        return GestureDetector(
          onTap: () async {
            await _fetchPurchaseDetailAndOpenReceipt(originalId);
          },
          child: _purchaseCardExactUI(
            id: displayId, // sirf display ke liye
            productName: p["productName"] ?? '',
            quantity: "${p["quantity"]} ${p["unit"]}",
            rate: "${p["unitPrice"]} / ${p["unit"]}",
            date: _formatDate(DateTime.parse(p["purchaseDate"])),
            farmer: p["farmerId"]?["name"] ?? '',
            landlord: p["landlordId"]?["name"] ?? '',
            status: p["status"] ?? '',
            onEdit: () => _editPurchase(originalId),
            onDelete: () => _deletePurchase(originalId),
          ),
        );
      }),
    );
  }

  // yeh function backend call karega

Future<void> _fetchPurchaseDetailAndOpenReceipt(String purchaseId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // yahan tumhara token key ka naam wahi hona chahiye jo save karte ho

    if (token == null) {
      _showErrorDialog("Authentication token missing. Please log in again.");
      return;
    }

    final response = await http.get(
      Uri.parse(
        "https://mandimatebackend.vercel.app/purchase/purchase-detail/$purchaseId",
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final decodedResponse = json.decode(response.body);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(body: decodedResponse),
    );
  } catch (e) {
    _showErrorDialog("Error: $e");
    print(e);
  }
}



  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Widget _purchaseCardExactUI({
    required String id, // dummy ya real ID
    required String productName,
    required String quantity,
    required String rate,
    required String date,
    required String farmer,
    required String landlord,
    required String status,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case "completed":
        statusColor = Colors.green;
        break;
      case "processing":
        statusColor = Colors.purple;
        break;
      case "pending":
        statusColor = Colors.orange;
        break;
      case "cancelled":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Capitalize first letter of status
    String displayStatus =
        status.isNotEmpty
            ? "${status[0].toUpperCase()}${status.substring(1).toLowerCase()}"
            : status;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: ID + Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: Colors.grey[600],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEdit,
                ),
                const SizedBox(width: 2), // kam spacing
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[400],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),

          // Details Rows
          _detailRow("Product Name", productName),
          _detailRow("Quantity", quantity),
          _detailRow("Rate", rate),
          _detailRow("Date", date),
          _detailRow("Farmer Name", farmer),
          _detailRow("Landlord Name", landlord),

          // Status Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Payment Status",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[300]),
      ],
    );
  }

  @override
  void dispose() {
    _seasonNameCtrl.dispose();
    _startDateCtrl.dispose();
    super.dispose();
  }
}

void _editPurchase(String purchaseId) {
  print("Edit purchase $purchaseId");
  // yahan tum edit screen open kar sakte ho
}

void _deletePurchase(String purchaseId) {
  print("Delete purchase $purchaseId");
  // yahan backend delete API call kar sakte ho
}
