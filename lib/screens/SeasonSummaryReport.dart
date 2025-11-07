import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandimate_mobile_app/widgets/drawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SeasonSummaryReportPage extends StatefulWidget {
  const SeasonSummaryReportPage({Key? key}) : super(key: key);

  @override
  State<SeasonSummaryReportPage> createState() =>
      _SeasonSummaryReportPageState();
}

class _SeasonSummaryReportPageState extends State<SeasonSummaryReportPage> {
  List<dynamic> reports = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAllReports();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchAllReports() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await getToken();
      if (token == null) throw Exception('Token not found');

      final response = await http.get(
        Uri.parse('https://mandimatebackend.vercel.app/seasonReport/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          reports = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load reports');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> showReportDetail(String reportId) async {
    try {
      final token = await getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(
          'https://mandimatebackend.vercel.app/seasonReport/detail/$reportId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _showDetailModal(data['data']);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showDetailModal(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Season Report Detail',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.download,
                                color: Color(0xFF2D5F4C),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Download feature coming soon',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildDetailCard('Season Information', [
                              _buildInfoRow(
                                'Season Name',
                                report['seasonId']['name'] ?? 'N/A',
                              ),
                              _buildInfoRow(
                                'Start Date',
                                _formatDate(report['seasonId']['startDate']),
                              ),
                              _buildInfoRow(
                                'End Date',
                                report['seasonId']['endDate'] != null
                                    ? _formatDate(report['seasonId']['endDate'])
                                    : 'Active',
                              ),
                              _buildInfoRow(
                                'Generated At',
                                _formatDate(report['generatedAt']),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _buildDetailCard('Financial Summary', [
                              _buildInfoRow(
                                'Total Purchases',
                                '${report['totalPurchases']}',
                              ),
                              _buildInfoRow(
                                'Purchase Amount',
                                'Rs ${_formatAmount(report['totalPurchaseAmount'])}',
                              ),
                              _buildInfoRow(
                                'Total Sales',
                                '${report['totalSales']}',
                              ),
                              _buildInfoRow(
                                'Sales Amount',
                                'Rs ${_formatAmount(report['totalSalesAmount'])}',
                              ),
                              _buildInfoRow(
                                'Total Expense',
                                'Rs ${_formatAmount(report['totalExpense'])}',
                              ),
                              _buildInfoRow(
                                'Total Advance',
                                'Rs ${_formatAmount(report['totalAdvance'])}',
                              ),
                              _buildInfoRow(
                                'Paid to Farmer',
                                'Rs ${_formatAmount(report['totalPaidToFarmer'])}',
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _buildDetailCard(
                              'Product-wise Summary',
                              (report['productWiseSummary'] as List)
                                  .map((product) => _buildProductCard(product))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product['productName'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchased: ${product['totalPurchasedQty']} kg',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      'Rs ${_formatAmount(product['totalPurchasedAmount'])}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sold: ${product['totalSoldQty']} kg',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      'Rs ${_formatAmount(product['totalSoldAmount'])}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Remaining: ${product['remainingQty']} kg',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5F4C).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F4C),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAmount(dynamic amount) {
    return NumberFormat('#,##,###').format(amount ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          elevation: 6,
          backgroundColor: const Color(0xFF2D6A4F),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Center(
              // <--- Add this
              child: Column(
                mainAxisSize: MainAxisSize.min, // <--- Important
                children: const [
                  Text(
                    "Season Reports",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "View and Analyze Your Season's Performance",
                    textAlign: TextAlign.center, // <--- ensures center
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
        ),
      ),

      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Content
          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D5F4C),
                      ),
                    )
                    : errorMessage != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchAllReports,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D5F4C),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : reports.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assessment_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No season reports found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: fetchAllReports,
                      color: const Color(0xFF2D5F4C),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return _buildReportCard(report);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // Updated Stat Column with Icon
  Widget _buildStatColumn(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final seasonName = report['seasonId']['name'] ?? 'Season Report';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showReportDetail(report['_id']),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Season Name + Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        seasonName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D6A4F),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF2D6A4F),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Generated: ${_formatDate(report['generatedAt'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Divider(height: 24),

                // Top Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        'Total Sales',
                        'Rs ${_formatAmount(report['totalSalesAmount'])}',
                        Colors.green,
                        Icons.trending_up,
                      ),
                    ),
                    Container(width: 1, height: 50),
                    Expanded(
                      child: _buildStatColumn(
                        'Total Purchases',
                        'Rs ${_formatAmount(report['totalPurchaseAmount'])}',
                        Colors.orange,
                        Icons.shopping_cart,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom Stats Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenses',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs ${_formatAmount(report['totalExpense'])}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paid to Farmer',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs ${_formatAmount(report['totalPaidToFarmer'])}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
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
  }
}
