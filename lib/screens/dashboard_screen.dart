// dashboard_screen_with_summary.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/screens/addPurchase.dart';
import 'package:mandimate_mobile_app/screens/seasonOverview_screen.dart';
import 'package:mandimate_mobile_app/widgets/activeSeason.dart';
import 'package:mandimate_mobile_app/widgets/drawer.dart';
import 'package:mandimate_mobile_app/widgets/nonActiveSeason.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "";
  bool _loading = true;
  bool _hasActiveSeason = false;
  Map<String, dynamic>? _season;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadUserData().then((_) {
      _checkActiveSeason();
    });
  }

  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("user");
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        if (mounted) {
          setState(() {
            userName = userMap["userName"] ?? "";
          });
        } else {
          userName = userMap["userName"] ?? "";
        }
      }
    } catch (e) {
      debugPrint('DEBUG: loadUserData error: $e');
    }
  }

  Future<void> _checkActiveSeason() async {
    debugPrint('DEBUG: _checkActiveSeason START - mounted=${mounted}');
    _errorMessage = null;
    _loading = true;
    if (mounted) setState(() {});

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      debugPrint('DEBUG: token present? ${token != null && token.isNotEmpty}');

      if (token == null || token.isEmpty) {
        _errorMessage = 'Auth token missing. Please login again.';
        debugPrint(
          'DEBUG: token missing in _checkActiveSeason -> $_errorMessage',
        );
        return;
      }

      final uri = Uri.parse(
        'https://mandimatebackend.vercel.app/season/active',
      );
      final resp = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('DEBUG: HTTP status: ${resp.statusCode}');
      debugPrint('DEBUG: HTTP body: ${resp.body}');

      dynamic decoded;
      try {
        decoded = json.decode(resp.body);
        debugPrint('DEBUG: decoded type: ${decoded.runtimeType}');
      } catch (e) {
        debugPrint('DEBUG: json.decode failed: $e');
        decoded = null;
      }

      if (resp.statusCode == 200) {
        if (decoded is Map && decoded['season'] != null) {
          _season = Map<String, dynamic>.from(decoded['season'] as Map);
          _hasActiveSeason = true;
          debugPrint('DEBUG: active season found -> ${_season?['_id']}');
        } else {
          _hasActiveSeason = false;
          _season = null;
          debugPrint('DEBUG: 200 but no season object -> decoded=$decoded');
        }
      } else if (resp.statusCode == 404 ||
          (decoded is Map &&
              decoded['message'] != null &&
              decoded['message'].toString().contains('No active season'))) {
        _hasActiveSeason = false;
        _season = null;
        debugPrint('DEBUG: backend reports no active season (404 or message).');
      } else {
        _errorMessage =
            (decoded is Map && decoded['message'] != null)
                ? decoded['message'].toString()
                : 'Failed to check active season (${resp.statusCode})';
        _hasActiveSeason = false;
        _season = null;
        debugPrint('DEBUG: server error -> $_errorMessage');
      }
    } catch (e, st) {
      _errorMessage = 'Network error: $e';
      _hasActiveSeason = false;
      _season = null;
      debugPrint('DEBUG: _checkActiveSeason exception -> $e\n$st');
    } finally {
      _loading = false;
      debugPrint(
        'DEBUG: _checkActiveSeason FINALLY - mounted=${mounted}, loading=$_loading',
      );
      if (mounted) setState(() {});
    }
  }

  String _formatDateString(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final d = DateTime.parse(raw);
      return "${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}";
    } catch (_) {
      return raw;
    }
  }

  String _monthName(int m) {
    const names = [
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
    return names[(m - 1).clamp(0, 11)];
  }

  Future<void> refreshActiveSeason() async {
    await _checkActiveSeason();
  }

  // ----------------------------
  // NEW: Open Summary Report Modal
  // ----------------------------
  Future<void> _openSummaryReport() async {
    if (!mounted) return;

    // show a full-screen modal bottom sheet with the report widget
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return SummaryReportSheet(
              season: _season,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage ?? 'Unknown error'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _checkActiveSeason,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_hasActiveSeason && _season != null) {
      final name = _season!['name']?.toString() ?? 'Active Season';
      final startRaw = _season!['startDate']?.toString();
      final startDateFormatted = _formatDateString(startRaw);
      final status = (_season!['isActive'] == true) ? 'Ongoing' : 'Ended';

      content = ActiveSeasonWidget(
        userName: userName,
        seasonName: name,
        startDate: startDateFormatted,
        status: status,
        onAddPurchase: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPurchaseScreen()),
          );
        },
        onViewLandlords: () {},
        onViewFarmers: () {},
        // Hook our new Summary Report open action here:
        onViewReports: () => _openSummaryReport(),
      );
    } else {
      content = NoActiveSeasonWidget(
        userName: userName,
        onStartSeason: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SeasonOverviewScreen(),
            ),
          );
        },
        onViewLandlords: () {},
        onViewFarmers: () {},
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
        actions: [
          // Quick access to Summary Report from appbar as well
          IconButton(
            onPressed: _openSummaryReport,
            icon: const Icon(Icons.bar_chart, color: Colors.black54),
            tooltip: 'Summary Report',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: refreshActiveSeason,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - kToolbarHeight,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// SummaryReportSheet: full screen modal sheet that fetches inventory & purchases,
/// computes KPIs and displays an attractive, responsive report UI.
class SummaryReportSheet extends StatefulWidget {
  final Map<String, dynamic>? season;
  final ScrollController scrollController;

  const SummaryReportSheet({
    super.key,
    required this.season,
    required this.scrollController,
  });

  @override
  State<SummaryReportSheet> createState() => _SummaryReportSheetState();
}

class _SummaryReportSheetState extends State<SummaryReportSheet> {
  bool _loading = true;
  String? _error;
  List<dynamic> _inventory = [];
  List<dynamic> _purchases = [];
  DateTimeRange?
  _range; // optional date range filter (not used for backend here)

  // KPIs
  int _totalProducts = 0;
  num _totalPurchasedQty = 0;
  num _totalSoldQty = 0;
  num _totalCurrentQty = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> _getSeasonId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('seasonId');
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      final seasonId = widget.season?['_id'] ?? await _getSeasonId();

      if (token == null || seasonId == null) {
        setState(() {
          _error = 'Missing authentication or active season.';
          _loading = false;
        });
        return;
      }

      // 1) Inventory
      final invResp = await http.get(
        Uri.parse(
          'https://mandimatebackend.vercel.app/inventory?seasonId=$seasonId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (invResp.statusCode == 200) {
        final decoded = json.decode(invResp.body);
        _inventory = List<dynamic>.from(decoded['data'] ?? []);
      } else {
        debugPrint('Inventory fetch failed: ${invResp.body}');
        _inventory = [];
      }

      // 2) Purchases (active season purchases)
      final purResp = await http.get(
        Uri.parse('https://mandimatebackend.vercel.app/purchase/active-season'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (purResp.statusCode == 200) {
        final decoded = json.decode(purResp.body);
        _purchases = List<dynamic>.from(decoded['data'] ?? []);
      } else {
        debugPrint('Purchase fetch failed: ${purResp.body}');
        _purchases = [];
      }

      // compute KPIs
      _computeKPIs();
      setState(() {
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Summary fetch error: $e\n$st');
      setState(() {
        _loading = false;
        _error = 'Network error: $e';
      });
    }
  }

  void _computeKPIs() {
    _totalProducts = _inventory.length;
    num purchased = 0, sold = 0, current = 0;

    for (final it in _inventory) {
      purchased += (it['totalPurchasedQty'] ?? 0) as num;
      sold += (it['totalSoldQty'] ?? 0) as num;
      current += (it['currentQty'] ?? 0) as num;
    }

    // Purchases also contain additional quantities (optional summary)
    for (final p in _purchases) {
      // if purchase object has 'quantity'
      purchased += (p['quantity'] ?? 0) as num;
    }

    _totalPurchasedQty = purchased;
    _totalSoldQty = sold;
    _totalCurrentQty = current;
  }

  // Top products sorted by currentQty
  List<Map<String, dynamic>> get _topProducts {
    final list =
        _inventory
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
    list.sort((a, b) => (b['currentQty'] ?? 0).compareTo(a['currentQty'] ?? 0));
    return list.take(6).toList();
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context) {
    final tops = _topProducts;
    if (tops.isEmpty) {
      return const Center(child: Text("No products in inventory."));
    }

    // find max for percent bars
    final maxQty = tops
        .map((e) => (e['currentQty'] ?? 0) as num)
        .fold<num>(0, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Top Products",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...tops.map((p) {
          final qty = (p['currentQty'] ?? 0) as num;
          final pct = maxQty > 0 ? (qty / maxQty).clamp(0.0, 1.0) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['productName'] ?? p['product'] ?? 'Unnamed',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: pct, minHeight: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${qty.toString()} ${p['baseUnit'] ?? ''}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPurchasesList() {
    if (_purchases.isEmpty) {
      return const Center(child: Text("No purchases found for this season."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Purchases",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ..._purchases.take(6).map((p) {
          final product = p['productName'] ?? 'Unknown';
          final qty = p['quantity'] ?? p['total'] ?? 0;
          final unit = p['unit'] ?? '';
          final date = p['purchaseDate'] ?? p['createdAt'] ?? '';
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.shopping_bag, color: Colors.green),
            ),
            title: Text(
              product,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text("$qty $unit • ${date.toString().split('T').first}"),
            trailing: Text(
              "${(p['unitPrice'] ?? 0)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ],
    );
  }

  // header widget
  Widget _header() {
    final seasonName = widget.season?['name']?.toString() ?? 'Active Season';
    final startDate = widget.season?['startDate']?.toString() ?? '';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seasonName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                startDate.isNotEmpty
                    ? "Started: ${_formatDateShort(startDate)}"
                    : "Season info unavailable",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black54),
          onPressed: _fetchAll,
          tooltip: "Refresh report",
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          itemBuilder:
              (c) => [
                const PopupMenuItem(value: '7', child: Text('Last 7 days')),
                const PopupMenuItem(value: '30', child: Text('Last 30 days')),
                const PopupMenuItem(value: 'all', child: Text('All time')),
              ],
          onSelected: (v) {
            // currently just stores a simple range; could be used by backend filters later
            setState(() {
              if (v == '7') {
                _range = DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 7)),
                  end: DateTime.now(),
                );
              } else if (v == '30') {
                _range = DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                );
              } else {
                _range = null;
              }
            });
          },
          icon: const Icon(Icons.filter_list),
        ),
      ],
    );
  }

  String _formatDateShort(String raw) {
    try {
      final d = DateTime.parse(raw);
      return "${d.day}/${d.month}/${d.year}";
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final twoCol = width > 720;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            children: [
              // drag handle
              Container(
                height: 4,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),

              // header + meta
              _header(),
              const SizedBox(height: 12),

              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? Center(child: Text(_error!))
                        : RefreshIndicator(
                          onRefresh: _fetchAll,
                          child: SingleChildScrollView(
                            controller: widget.scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // KPI Grid
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 720;
                                    return GridView(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: isWide ? 4 : 2,
                                            mainAxisExtent: 96,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                          ),
                                      children: [
                                        _kpiCard(
                                          "Products",
                                          _totalProducts.toString(),
                                          Icons.inventory_2,
                                          Colors.teal,
                                        ),
                                        _kpiCard(
                                          "Purchased Qty",
                                          _totalPurchasedQty.toString(),
                                          Icons.add_shopping_cart,
                                          Colors.blue,
                                        ),
                                        _kpiCard(
                                          "Sold Qty",
                                          _totalSoldQty.toString(),
                                          Icons.sell,
                                          Colors.orange,
                                        ),
                                        _kpiCard(
                                          "Current Stock",
                                          _totalCurrentQty.toString(),
                                          Icons.storage,
                                          Colors.green,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Two column area: left = top products, right = purchases list (on wide screens)
                                twoCol
                                    ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildTopProducts(context),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(child: _buildPurchasesList()),
                                      ],
                                    )
                                    : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildTopProducts(context),
                                        const SizedBox(height: 12),
                                        _buildPurchasesList(),
                                      ],
                                    ),
                                const SizedBox(height: 24),

                                // CTA row
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // navigate to purchases screen (AddPurchase)
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      const AddPurchaseScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.receipt_long),
                                        label: const Text("Add Purchase"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          // view inventory screen maybe
                                          Navigator.of(
                                            context,
                                          ).pop(); // close sheet
                                          // Optionally navigate to Inventory page
                                        },
                                        icon: const Icon(
                                          Icons.inventory_2_outlined,
                                        ),
                                        label: const Text("View Inventory"),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
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
