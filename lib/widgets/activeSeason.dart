import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mandimate_mobile_app/widgets/LandlordFarmersScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ActiveSeasonWidget extends StatefulWidget {
  final String userName;
  final String seasonName;
  final String startDate;
  final String status;

  const ActiveSeasonWidget({
    super.key,
    required this.userName,
    required this.seasonName,
    required this.startDate,
    required this.status,
  });

  @override
  State<ActiveSeasonWidget> createState() => _ActiveSeasonWidgetState();
}

class _ActiveSeasonWidgetState extends State<ActiveSeasonWidget> {
  bool isLoading = true;
  Map<String, dynamic> totals = {};
  List landlords = [];

  @override
  void initState() {
    super.initState();
    fetchSeasonSummary();
  }

  Future<void> fetchSeasonSummary() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? seasonId = prefs.getString('seasonId');

      if (token == null || seasonId == null) {
        throw Exception("Token or SeasonId not found!");
      }

      final url =
          "https://mandimatebackend.vercel.app/summary/season-summary/$seasonId";

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          totals = data["totals"];
          landlords = data["landlords"];
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch summary");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> fetchLastPurchase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse("https://mandimatebackend.vercel.app/purchase/active-season"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final purchases = data["data"] as List;
      if (purchases.isNotEmpty) {
        return purchases.first;
      }
    }
    return null;
  }

  String capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  Widget buildStatCard(String title, int value, IconData icon, Color color) {
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
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        duration: const Duration(seconds: 1),
        builder: (context, val, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 26),
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
                val.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildSeasonInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event, color: Colors.green, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capitalize(widget.seasonName),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Start Date: ${widget.startDate}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      widget.status,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLandlordCard(Map landlord) {
    return InkWell(
      onTap: () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString("token");
          final seasonId = prefs.getString("seasonId");

          if (token == null || seasonId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Session expired, please login again"),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => LandlordFarmersScreen(
                    landlordName: landlord["landlordName"], // ✅ sahi key
                    landlordId: landlord["landlordId"], // ✅ sahi key
                    seasonId: seasonId,
                    token: token,
                  ),
            ),
          );
        } catch (e) {
          debugPrint("Error navigating to landlord farmers: $e");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green.withOpacity(0.15),
              child: const Icon(Icons.person, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    landlord["landlordName"], // ✅ sahi key
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Purchases: ${landlord['totalPurchases']}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    "Paid: ${landlord['totalPaid']}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              "Pending: ${landlord['pendingBalance']}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    (landlord["pendingBalance"] > 0)
                        ? Colors.red
                        : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
                      text: widget.userName,
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
                    totals["totalPurchases"] ?? 0,
                    Icons.shopping_bag,
                    Colors.blue,
                  ),
                  buildStatCard(
                    "Total Paid",
                    totals["totalPaid"] ?? 0,
                    Icons.check_circle,
                    Colors.teal,
                  ),
                  buildStatCard(
                    "Total Pending",
                    totals["totalPending"] ?? 0,
                    Icons.access_time,
                    Colors.orange,
                  ),
                  buildStatCard(
                    "Total Sales",
                    totals["totalSales"] ?? 0,
                    Icons.attach_money,
                    Colors.purple,
                  ),
                ],
              ),

              // Season Info
              buildSeasonInfoBox(),

              const SizedBox(height: 12),
              const Text(
                "Landlords",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Landlord List
              // Landlord List
              Column(
                children: landlords.map((l) => buildLandlordCard(l)).toList(),
              ),

              // 🔽 Ye naya section add karo yahin
              const SizedBox(height: 20),
              const Text(
                "Last Purchase",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              FutureBuilder(
                future: fetchLastPurchase(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text("No purchases yet."),
                    );
                  }

                  final purchase = snapshot.data!;
                  // parse date
                  final dt = DateTime.parse(
                    purchase["purchaseDate"].toString(),
                  );

                  // month names (place near the top of the file or inside builder)
                  const monthNames = [
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

                  // formatted string
                  final formattedDate =
                      "${dt.day.toString().padLeft(2, '0')} ${monthNames[dt.month - 1]} ${dt.year}";

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ).copyWith(bottom: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                purchase["productName"],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text(
                            "${purchase["quantity"]} ${purchase["unit"]} | Rs.${purchase["unitPrice"]}",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Amount + Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total: Rs. ${purchase["totalAmount"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      purchase["status"] == "settled"
                                          ? Colors.green.withOpacity(0.15)
                                          : Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  purchase["status"].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        purchase["status"] == "settled"
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              const Icon(
                                Icons.account_circle,
                                size: 16,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Landlord: ${purchase["landlordId"]["name"]}",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.agriculture,
                                size: 16,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Farmer: ${purchase["farmerId"]["name"]}",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
  }
}
