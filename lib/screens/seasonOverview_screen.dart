import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Branding bar (logo + title)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 34,
                    child: Image.asset("assets/Group.png", fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Mandi Mate",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.dashboard, color: Colors.green[700]),
                    title: const Text("Dashboard"),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.timeline, color: Colors.green[700]),
                    title: const Text("Season Overview"),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.people_alt, color: Colors.green[700]),
                    title: const Text("Landlords"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.agriculture, color: Colors.green[700]),
                    title: const Text("Farmers"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.green[700]),
                    title: const Text("Settings"),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Fixed Logout
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Logout
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
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
                          // TODO: open Add Purchase form
                        }
                        : null,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Add Purchase'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.green.shade200;
                    }
                    return Colors.green.shade600;
                  }),
                  foregroundColor: const MaterialStatePropertyAll<Color>(
                    Colors.white,
                  ),
                  padding: const MaterialStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                  shape: MaterialStatePropertyAll(
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
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.red.shade200;
                    }
                    return Colors.redAccent;
                  }),
                  foregroundColor: const MaterialStatePropertyAll<Color>(
                    Colors.white,
                  ),
                  padding: const MaterialStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                  shape: MaterialStatePropertyAll(
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
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFEFF7EE),
                child: Icon(Icons.eco, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _prettySeasonLine(_season!),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: open filter sheet
                },
                icon: const Icon(Icons.tune),
                label: const Text('Filter'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static String _prettySeasonLine(Map<String, dynamic> s) {
    final name = s['name']?.toString() ?? '—';
    final start = DateTime.tryParse(s['startDate']?.toString() ?? '');
    final end =
        s['endDate'] == null
            ? null
            : DateTime.tryParse(s['endDate'].toString());
    final startStr = start == null ? '—' : _formatDate(start);
    final endStr = end == null ? 'Present' : _formatDate(end);
    return '$name  ($startStr — $endStr)';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text(
                'Start New Season',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
              // Date is for UI only; not sent to backend
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _startDateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Start Date (UI only)',
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
                    child: ElevatedButton(
                      onPressed: _onCreateSeasonPressed,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Create Season'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      drawer: _buildDrawer(),
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

                      if (_hasActiveSeason) _buildActiveSeasonPlaceholderList(),
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

  // Placeholder list (we’ll replace with backend-driven purchases next step)
  Widget _buildActiveSeasonPlaceholderList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _purchaseCardSkeleton(
          id: '00001',
          product: 'Wheat',
          qty: '32 TON',
          rate: '24,000 / TON',
          date: _season?['startDate']?.toString() ?? '',
          farmer: 'Christine Brooks',
          status: 'Completed',
          statusColor: Colors.green[400]!,
        ),
        _purchaseCardSkeleton(
          id: '00002',
          product: 'Wheat',
          qty: '32 TON',
          rate: '24,000 / TON',
          date: _season?['startDate']?.toString() ?? '',
          farmer: 'Christine Brooks',
          status: 'Processing',
          statusColor: Colors.purple[300]!,
        ),
      ],
    );
  }

  Widget _purchaseCardSkeleton({
    required String id,
    required String product,
    required String qty,
    required String rate,
    required String date,
    required String farmer,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_box_outline_blank,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'ID  $id',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.redAccent,
                ),
                onPressed: () {},
              ),
            ],
          ),
          const Divider(height: 20),
          _kv('Product Name', product),
          _kv('Quantity', qty),
          _kv('Rate', rate),
          _kv('Date', _formatDate(DateTime.now())),
          _kv('Farmer Name', farmer),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _seasonNameCtrl.dispose();
    _startDateCtrl.dispose();
    super.dispose();
  }
}
