import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/screens/addPurchase.dart';
import 'package:mandimate_mobile_app/widgets/drawer.dart';
import 'package:mandimate_mobile_app/widgets/receipt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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

  Future<void> _endSeasonWithConfirmation() async {
    print('DEBUG: End season button clicked');

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[600],
            size: 48,
          ),
          title: const Text(
            'End Current Season?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to end the current season?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'End Season',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _endSeason();
    }
  }

  Future<void> _endSeason() async {
    print('DEBUG: _endSeason START');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Ending Season...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      // Get token and seasonId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final seasonId = prefs.getString('seasonId');

      print('DEBUG: token exists: ${token != null}');
      print('DEBUG: seasonId: $seasonId');

      if (token == null || token.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        _showSnack('Auth token missing. Please login again.');
        print('DEBUG: token missing -> return');
        return;
      }

      if (seasonId == null || seasonId.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        _showSnack('Season ID not found. Please refresh and try again.');
        print('DEBUG: seasonId missing -> return');
        return;
      }

      // Make API call to close season
      final uri = Uri.parse(
        'https://mandimatebackend.vercel.app/season/close/$seasonId',
      );

      print('DEBUG: Making PATCH request to: $uri');

      final response = await http
          .patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('DEBUG: Season ended successfully');

        // Show success message
        _showSnack('Season ended successfully!');

        // Clear seasonId from SharedPreferences
        await prefs.remove('seasonId');

        // Call bootstrap to refresh the app state
        print('DEBUG: Calling _bootstrap() to refresh app state');
        await _bootstrap();

        print('DEBUG: _endSeason completed successfully');
      } else {
        // Handle error response
        String errorMessage = 'Failed to end season (${response.statusCode})';

        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (_) {
          // Use default error message if JSON parsing fails
        }

        _showSnack(errorMessage);
        print('DEBUG: End season failed: $errorMessage');
      }
    } on TimeoutException {
      Navigator.of(context).pop(); // Close loading dialog
      _showSnack('Request timed out. Please try again.');
      print('DEBUG: End season timeout');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showSnack('Network error: $e');
      print('DEBUG: End season network error: $e');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              keyboardType:
                  isNumber
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
              inputFormatters:
                  isNumber
                      ? <TextInputFormatter>[
                        // allows digits and dot (simple). For integer-only use FilteringTextInputFormatter.digitsOnly
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ]
                      : null,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _openEditPurchaseModal(String purchaseId) async {
    print('DEBUG: _openEditPurchaseModal START for $purchaseId');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showSnack('Auth token missing. Please login again.');
      print('DEBUG: token missing -> returning false');
      return false;
    }

    Map<String, dynamic>? purchase;
    try {
      final resp = await http
          .get(
            Uri.parse(
              'https://mandimatebackend.vercel.app/purchase/purchase-detail/$purchaseId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('DEBUG: fetch detail status ${resp.statusCode}');
      if (resp.statusCode != 200) {
        _showSnack('Failed to fetch purchase details (${resp.statusCode}).');
        print('DEBUG: fetch failed -> returning false');
        return false;
      }

      final decoded = json.decode(resp.body) as Map<String, dynamic>;
      purchase = decoded['data'] as Map<String, dynamic>?;
      if (purchase == null) {
        _showSnack('Purchase data missing in response.');
        print('DEBUG: purchase null -> returning false');
        return false;
      }
    } catch (e) {
      _showSnack('Network error: $e');
      print('DEBUG: network error $e -> returning false');
      return false;
    }

    if (!mounted) {
      print('DEBUG: not mounted -> returning false');
      return false;
    }

    // controllers
    final productCtrl = TextEditingController(
      text: purchase['productName']?.toString() ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: purchase['quantity']?.toString() ?? '',
    );
    final unitCtrl = TextEditingController(
      text: purchase['unit']?.toString() ?? '',
    );
    final unitPriceCtrl = TextEditingController(
      text: purchase['unitPrice']?.toString() ?? '',
    );
    final expenseCtrl = TextEditingController(
      text: purchase['expense']?.toString() ?? '',
    );
    final advanceCtrl = TextEditingController(
      text: purchase['advance']?.toString() ?? '',
    );
    final paidCtrl = TextEditingController(
      text: purchase['paidToFarmer']?.toString() ?? '',
    );
    final landlordCtrl = TextEditingController(
      text: purchase['landlordId']?['name']?.toString() ?? '',
    );
    final farmerCtrl = TextEditingController(
      text: purchase['farmerId']?['name']?.toString() ?? '',
    );

    // Use a Completer to properly handle the result
    final Completer<bool> completer = Completer<bool>();

    // Change the return type to bool only
    final bool? dialogResult = await showGeneralDialog<bool>(
      context: context, // Use original context directly
      barrierDismissible: false,
      barrierLabel: 'Edit Purchase',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, a1, a2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Center(
            child: StatefulBuilder(
              builder: (dialogCtx, setInnerState) {
                bool isSaving = false;

                void stopSaving() {
                  if (mounted) {
                    try {
                      setInnerState(() => isSaving = false);
                    } catch (_) {}
                  }
                }

                return Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(dialogCtx).size.width * 0.92,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Edit Purchase',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  print(
                                    'DEBUG: close icon pressed -> pop(false)',
                                  );
                                  Navigator.of(dialogCtx).pop(false);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          _buildField('Product Name', productCtrl),
                          _buildField('Landlord', landlordCtrl, readOnly: true),
                          _buildField('Farmer', farmerCtrl, readOnly: true),
                          _buildField('Quantity', qtyCtrl, isNumber: true),
                          _buildField('Unit', unitCtrl),
                          _buildField(
                            'Unit Price',
                            unitPriceCtrl,
                            isNumber: true,
                          ),
                          _buildField('Expense', expenseCtrl, isNumber: true),
                          _buildField('Advance', advanceCtrl, isNumber: true),
                          _buildField(
                            'Paid to Farmer',
                            paidCtrl,
                            isNumber: true,
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    print(
                                      'DEBUG: Cancel pressed -> pop(false)',
                                    );
                                    Navigator.of(dialogCtx).pop(false);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      isSaving
                                          ? null
                                          : () async {
                                            print(
                                              'DEBUG: Update pressed -> starting save',
                                            );
                                            setInnerState(
                                              () => isSaving = true,
                                            );

                                            final body = {
                                              'productName':
                                                  productCtrl.text.trim(),
                                              'quantity':
                                                  int.tryParse(
                                                    qtyCtrl.text.trim(),
                                                  ) ??
                                                  0,
                                              'unit': unitCtrl.text.trim(),
                                              'unitPrice':
                                                  double.tryParse(
                                                    unitPriceCtrl.text.trim(),
                                                  ) ??
                                                  0.0,
                                              'expense':
                                                  double.tryParse(
                                                    expenseCtrl.text.trim(),
                                                  ) ??
                                                  0.0,
                                              'advance':
                                                  double.tryParse(
                                                    advanceCtrl.text.trim(),
                                                  ) ??
                                                  0.0,
                                              'paidToFarmer':
                                                  double.tryParse(
                                                    paidCtrl.text.trim(),
                                                  ) ??
                                                  0.0,
                                            };

                                            try {
                                              final prefs2 =
                                                  await SharedPreferences.getInstance();
                                              final token2 = prefs2.getString(
                                                'token',
                                              );
                                              if (token2 == null ||
                                                  token2.isEmpty) {
                                                stopSaving();
                                                _showSnack(
                                                  'Auth token missing. Please login again.',
                                                );
                                                print(
                                                  'DEBUG: token2 missing -> return',
                                                );
                                                return;
                                              }

                                              final uri = Uri.parse(
                                                'https://mandimatebackend.vercel.app/purchase/update/$purchaseId',
                                              );

                                              final updateResp = await http
                                                  .put(
                                                    uri,
                                                    headers: {
                                                      'Content-Type':
                                                          'application/json',
                                                      'Authorization':
                                                          'Bearer $token2',
                                                    },
                                                    body: json.encode(body),
                                                  )
                                                  .timeout(
                                                    const Duration(seconds: 20),
                                                  );

                                              print(
                                                'DEBUG: updateResp status ${updateResp.statusCode}, body: ${updateResp.body}',
                                              );

                                              if (updateResp.statusCode ==
                                                      200 ||
                                                  updateResp.statusCode ==
                                                      201) {
                                                print(
                                                  'DEBUG: update success -> closing dialog with true',
                                                );

                                                // Stop loading state first
                                                stopSaving();

                                                // Add a small delay to ensure UI updates
                                                await Future.delayed(
                                                  const Duration(
                                                    milliseconds: 100,
                                                  ),
                                                );

                                                // Close dialog with success result
                                                if (Navigator.of(
                                                  dialogCtx,
                                                ).canPop()) {
                                                  Navigator.of(
                                                    dialogCtx,
                                                  ).pop(true);
                                                }
                                              } else {
                                                stopSaving();
                                                String msg =
                                                    'Failed to update (${updateResp.statusCode})';
                                                try {
                                                  final err = json.decode(
                                                    updateResp.body,
                                                  );
                                                  if (err is Map &&
                                                      err['message'] != null) {
                                                    msg =
                                                        err['message']
                                                            .toString();
                                                  }
                                                } catch (_) {}
                                                _showSnack(msg);
                                                print(
                                                  'DEBUG: update failed -> $msg',
                                                );
                                              }
                                            } on TimeoutException {
                                              stopSaving();
                                              _showSnack(
                                                'Request timed out. Try again.',
                                              );
                                              print('DEBUG: update timeout');
                                            } catch (e) {
                                              stopSaving();
                                              _showSnack('Network error: $e');
                                              print(
                                                'DEBUG: update network error $e',
                                              );
                                            }
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  child:
                                      isSaving
                                          ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text('Update'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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

    // dispose controllers
    productCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    unitPriceCtrl.dispose();
    expenseCtrl.dispose();
    advanceCtrl.dispose();
    paidCtrl.dispose();
    landlordCtrl.dispose();
    farmerCtrl.dispose();

    print('DEBUG: dialogResult = $dialogResult');

    // Return the boolean result directly
    return dialogResult == true;
  }

  Future<void> _deletePurchase(String purchaseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // outside click se band na ho
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red[600],
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                const Text(
                  "Delete Purchase?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // Description
                const Text(
                  "Are you sure you want to delete this purchase?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text("Delete"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse(
          "https://mandimatebackend.vercel.app/purchase/delete/$purchaseId",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _toast("Purchase deleted successfully");
        setState(() {
          _purchases.removeWhere((p) => p["_id"] == purchaseId);
        });
      } else {
        _toast("Failed to delete purchase");
      }
    } catch (e) {
      _toast("Error: $e");
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
    print('DEBUG: _fetchPurchasesForActiveSeason START');

    if (!mounted) {
      print('DEBUG: Widget not mounted, returning');
      return;
    }

    setState(() {
      _loadingPurchases = true;
      print('DEBUG: Loading state set to true');
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('DEBUG: Token null, returning');
        if (mounted) setState(() => _loadingPurchases = false);
        return;
      }

      print('DEBUG: Making API call with timeout');

      final response = await http
          .get(
            Uri.parse(
              "https://mandimatebackend.vercel.app/purchase/active-season",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(
            Duration(seconds: 8), // Shorter timeout
            onTimeout: () {
              print('DEBUG: API call timed out');
              throw TimeoutException('Request timed out', Duration(seconds: 8));
            },
          );

      print('DEBUG: API response received, status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data["data"] as List<dynamic>? ?? [];

        if (mounted) {
          setState(() {
            _purchases =
                list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            print('DEBUG: Purchases updated, count: ${_purchases.length}');
          });
        }
      } else {
        print('DEBUG: API error status: ${response.statusCode}');
        final err = json.decode(response.body);
        if (mounted) _showSnack(err["message"] ?? "Failed to fetch purchases");
      }
    } on TimeoutException {
      print('DEBUG: Timeout exception caught');
      if (mounted) _showSnack("Request timed out. Please try again.");
    } catch (e) {
      print('DEBUG: Exception in _fetchPurchasesForActiveSeason: $e');
      if (mounted) _showSnack("Error fetching purchases: $e");
    } finally {
      print('DEBUG: Setting loading to false');
      if (mounted) {
        setState(() => _loadingPurchases = false);
      }
      print('DEBUG: _fetchPurchasesForActiveSeason END');
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
                'Season Purchases',
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
                onPressed: _hasActiveSeason ? _endSeasonWithConfirmation : null,
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
            onEdit: () async {
              print('DEBUG: Edit button pressed for $originalId');

              final updated = await _openEditPurchaseModal(originalId);

              if (updated == true) {
                print('DEBUG: Update successful, refreshing single item...');

                _showSnack('Purchase updated successfully!');

                // Option 1: Full refresh (recommended for data consistency)
                await _fetchPurchasesForActiveSeason();
              }
            },
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
      final token = prefs.getString(
        'token',
      ); // yahan tumhara token key ka naam wahi hona chahiye jo save karte ho

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
