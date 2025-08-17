import 'dart:convert';
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
      // ignore parse errors, keep userName empty
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
      // always clear the backing field
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

  // Optionally call this when user pulls-to-refresh or after editing a purchase
  Future<void> refreshActiveSeason() async {
    await _checkActiveSeason();
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
      // Prepare props for ActiveSeasonWidget
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
        onViewLandlords: () {
          // Navigator.of(context).pushNamed('/landlords');
        },
        onViewFarmers: () {
          // Navigator.of(context).pushNamed('/farmers');
        },
        onViewReports: () {
          // Navigator.of(context).pushNamed('/reports');
        },
      );
    } else {
      // No active season -> show non-active widget
      content = NoActiveSeasonWidget(
        userName: userName,
        onStartSeason: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SeasonOverviewScreen(),
            ),
          );
        },
        onViewLandlords: () {
          // Navigator.of(context).pushNamed('/landlords');
        },
        onViewFarmers: () {
          // Navigator.of(context).pushNamed('/farmers');
        },
      );
    }

    // Wrap in RefreshIndicator so user can pull to re-check
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
