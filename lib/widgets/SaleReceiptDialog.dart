import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandimate_mobile_app/screens/sales_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SaleReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> body;

  const SaleReceiptDialog({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    final data = body['data'] ?? {};
    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo + Title
              Column(
                children: [
                  Icon(Icons.receipt_long, color: Color(0xFF2D6A4F), size: 50),
                  const SizedBox(height: 8),
                  Text(
                    "Sale Receipt",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body['message'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const Divider(height: 20, thickness: 1),
                ],
              ),

              // Sale fields
              _buildRow("Product Name", data['productName']),
              _buildRow("Quantity", "${data['quantity']} ${data['unit']}"),
              _buildRow("Unit Price", "Rs. ${data['unitPrice']}"),
              _buildRow("Total Amount", "Rs. ${data['totalAmount']}"),
              _buildRow("Customer Name", data['customerName']),
              _buildRow(
                "Sale Date",
                dateFormat.format(DateTime.parse(data['saleDate'])),
              ),

              const SizedBox(height: 20),

              // Buttons Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _downloadPdf(data, context),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      "Download PDF",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF2D6A4F),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SalesPage()),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_circle_left_rounded,
                      color: Color(0xFF2D6A4F),
                      size: 22,
                    ),
                    label: const Text(
                      "Back to Sales Page",
                      style: TextStyle(
                        color: Color(0xFF2D6A4F),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Row Widget
  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          Text(
            value ?? '',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // PDF Download Function
  Future<void> _downloadPdf(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    String safeString(dynamic v) => v == null ? '' : v.toString();

    final product = safeString(data['productName']);
    final qty = safeString(data['quantity']);
    final unit = safeString(data['unit']);
    final unitPrice = safeString(data['unitPrice']);
    final totalAmount = safeString(data['totalAmount']);
    final customer = safeString(data['customerName']);
    String saleDateStr = '';
    try {
      saleDateStr = dateFormat.format(
        DateTime.parse(safeString(data['saleDate'])),
      );
    } catch (_) {
      saleDateStr = safeString(data['saleDate']);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'MandiMate',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.Text(
                    saleDateStr,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(height: 2, color: PdfColors.green200),
              pw.SizedBox(height: 16),

              pw.Text(
                'Sale Details',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 8),

              _pdfRow("Product Name", product),
              _pdfRow("Quantity", "$qty $unit"),
              _pdfRow("Unit Price", "Rs. $unitPrice"),
              _pdfRow("Total Amount", "Rs. $totalAmount"),
              _pdfRow("Customer", customer),
              _pdfRow("Sale Date", saleDateStr),

              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Generated by MandiMate • ${DateTime.now().year}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'mandimate_sale_receipt_$now.pdf';

    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  // PDF row helper
  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
