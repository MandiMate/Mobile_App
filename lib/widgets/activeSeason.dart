import 'package:flutter/material.dart';

class ActiveSeasonWidget extends StatelessWidget {
  final String userName;
  final String seasonName;
  final String startDate;
  final String status;
  final VoidCallback onAddPurchase;
  final VoidCallback onViewLandlords;
  final VoidCallback onViewFarmers;
  final VoidCallback onViewReports;

  const ActiveSeasonWidget({
    super.key,
    required this.userName,
    required this.seasonName,
    required this.startDate,
    required this.status,
    required this.onAddPurchase,
    required this.onViewLandlords,
    required this.onViewFarmers,
    required this.onViewReports,
  });

  Widget buildStatCard(
    BuildContext context,
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
    MaterialColor color,
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
                  color: color[800],
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
                  seasonName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Start Date: $startDate",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      status,
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                context,
                "Total Purchases",
                "0",
                Icons.shopping_bag,
                Colors.blue,
              ),
              buildStatCard(
                context,
                "Total Inventory",
                "0",
                Icons.inventory_2,
                Colors.teal,
              ),
              buildStatCard(
                context,
                "Total Pending",
                "0",
                Icons.access_time,
                Colors.orange,
              ),
              buildStatCard(
                context,
                "Total Expenses",
                "0",
                Icons.money_off,
                Colors.red,
              ),
            ],
          ),

          // Season Info
          buildSeasonInfoBox(),

          // Quick Actions
          buildActionButton(
            "Add Purchase",
            Icons.add_circle,
            Colors.green,
            onAddPurchase,
          ),
          buildActionButton(
            "Summary Report",
            Icons.bar_chart,
            Colors.purple,
            onViewReports,
          ),
        ],
      ),
    );
  }
}
