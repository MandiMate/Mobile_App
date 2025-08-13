import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mandimate_mobile_app/screens/seasonOverview_screen.dart';
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

  Widget buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton(
    String text,
    IconData icon,
    MaterialColor color, // Changed from Color to MaterialColor
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: color[800], // Safe shade access
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: color[600]),
          ],
        ),
      ),
    );
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
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Logo Section
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
                    // Smaller Logo
                    SizedBox(
                      height: 40, // smaller height
                      child: Image.asset(
                        "assets/Group.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Bigger App Name
                    const Text(
                      "Mandi Mate",
                      style: TextStyle(
                        fontSize: 26, // bigger
                        fontWeight: FontWeight.w900, // extra bold
                        color: Colors.black87,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Menu
              Expanded(
                child: ListTileTheme(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  iconColor: Colors.green[700],
                  textColor: Colors.black87,
                  horizontalTitleGap: 16,
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dashboard),
                        title: const Text(
                          "Dashboard",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {},
                      ),
                      // Drawer me Season Overview option
                      ListTile(
                        leading: Icon(Icons.timeline, color: Colors.green[700]),
                        title: const Text("Season Overview"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeasonOverviewScreen(),
                            ),
                          );
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.people_alt),
                        title: const Text(
                          "Landlord",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.agriculture),
                        title: const Text(
                          "Farmer",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: Icon(Icons.settings, color: Colors.green[700]),
                        title: const Text("Setting"),
                        onTap: () {
                          // TODO: Navigate to settings
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Logout Button - Theme Green
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Logout Logic
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Logout",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700], // theme green
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
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
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome text
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: "Welcome, ",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: userName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF48A94B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary Cards
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                buildStatCard(
                  "Total Purchases",
                  "0",
                  Icons.shopping_bag,
                  Colors.blue,
                ),
                buildStatCard(
                  "Total Paid",
                  "0",
                  Icons.check_circle,
                  Colors.green,
                ),
                buildStatCard(
                  "Total Pending",
                  "0",
                  Icons.access_time,
                  Colors.orange,
                ),
                buildStatCard(
                  "Total Expenses",
                  "0",
                  Icons.money_off,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // No Active Season Section
            // No Active Season Section
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "No Active Season Found",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Start a new season to begin tracking.",
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  buildActionButton(
                    "Start New Season",
                    Icons.add_circle,
                    Colors.green,
                    () {
                      // TODO: Navigate to Start New Season Page
                    },
                  ),
                  const SizedBox(height: 8),
                  buildActionButton(
                    "View Landlords",
                    Icons.people_alt,
                    Colors.blue,
                    () {
                      // TODO: Navigate to Landlords Page
                    },
                  ),
                  const SizedBox(height: 8),
                  buildActionButton(
                    "View Farmers",
                    Icons.agriculture,
                    Colors.orange,
                    () {
                      // TODO: Navigate to Farmers Page
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Drawer Menu Item Widget - Modern Style
Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ),
  );
}
