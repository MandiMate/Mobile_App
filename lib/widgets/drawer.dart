import 'package:flutter/material.dart';
import 'package:mandimate_mobile_app/screens/dashboard_screen.dart';
import 'package:mandimate_mobile_app/screens/seasonOverview_screen.dart';
import 'package:mandimate_mobile_app/screens/login_screen.dart'; 
import 'package:shared_preferences/shared_preferences.dart';   

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                  SizedBox(
                    height: 40,
                    child: Image.asset("assets/Group.png", fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Mandi Mate",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
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
                      title: const Text("Dashboard"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.timeline, color: Colors.green[700]),
                      title: const Text("Season Overview"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SeasonOverviewScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.inventory_2), // Inventory icon
                      title: const Text("Inventory"),
                      onTap: () {
                        // TODO: Navigate to Inventory Page
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people_alt),
                      title: const Text("Landlord"),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.agriculture),
                      title: const Text("Farmer"),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.settings, color: Colors.green[700]),
                      title: const Text("Setting"),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Logout Button
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
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear(); //  local storage clear

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false, //  all screens clear
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
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
    );
  }
}
