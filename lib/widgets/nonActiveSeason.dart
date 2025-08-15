import 'package:flutter/material.dart';

class NoActiveSeasonWidget extends StatelessWidget {
  final String userName;
  final VoidCallback onStartSeason;
  final VoidCallback onViewLandlords;
  final VoidCallback onViewFarmers;

  const NoActiveSeasonWidget({
    super.key,
    required this.userName,
    required this.onStartSeason,
    required this.onViewLandlords,
    required this.onViewFarmers,
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
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.25)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCompactActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
          const SizedBox(height: 30),

          // No Active Season Section
          Center(
            child: Column(
              children: [
                Icon(Icons.calendar_today, color: Colors.black87, size: 24),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildActionButton(
                      "Start New Season",
                      Icons.add_circle,
                      Colors.green,
                      onStartSeason,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: buildCompactActionButton(
                            "Add Landlord",
                            Icons.people_alt,
                            Colors.blue,
                            onViewLandlords,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildCompactActionButton(
                            "Add Farmer",
                            Icons.agriculture,
                            Colors.orange,
                            onViewFarmers,
                          ),
                        ),
                      ],
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
}
