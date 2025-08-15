import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("user");
    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      setState(() {
        userName = userMap["userName"] ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

      body: ActiveSeasonWidget(
        userName: userName,
        seasonName: "Summer 2025",
        startDate: "01 June 2025",
        status: "Ongoing",
        onAddPurchase: () {
          // Navigate to Add Purchase
        },
        onViewLandlords: () {
          // Navigate to Landlords
        },
        onViewFarmers: () {
          // Navigate to Farmers
        },
        onViewReports: () {
          // Navigate to Reports
        },
      ),

      // body: NoActiveSeasonWidget(
      //   userName: userName,
      //   onStartSeason: () {
      //     // Navigate to Start New Season Page
      //   },
      //   onViewLandlords: () {
      //     // Navigate to Landlords Page
      //   },
      //   onViewFarmers: () {
      //     // Navigate to Farmers Page
      //   },
      // ),
    );
  }
}
