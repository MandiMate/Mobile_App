import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandimate_mobile_app/screens/seasonOverview_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> body;

  const ReceiptDialog({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    final data = body['data'] ?? {};
    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      backgroundColor: Colors.white, // Clean white background
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
                    "Purchase Receipt",
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

              // Fields...
              _buildRow("Product Name", data['productName']),
              _buildRow("Quantity", "${data['quantity']} ${data['unit']}"),
              _buildRow("Unit Price", "Rs. ${data['unitPrice']}"),
              _buildRow("Total Amount", "Rs. ${data['totalAmount']}"),
              _buildRow("Expense", "Rs. ${data['expense']}"),
              _buildRow("Advance", "Rs. ${data['advance']}"),
              _buildRow("Paid to Farmer", "Rs. ${data['paidToFarmer']}"),
              _buildRow("Balance", "Rs. ${data['balance']}"),
              _buildRow("Extra Payment", "Rs. ${data['extraPayment']}"),
              _buildRow("Status", data['status']),
              _buildRow(
                "Purchase Date",
                dateFormat.format(DateTime.parse(data['purchaseDate'])),
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
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeasonOverviewScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_circle_left_rounded, // More modern back icon
                      color: Color(0xFF2D6A4F),
                      size: 22,
                    ),
                    label: const Text(
                      "Back to Season Page",
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
  // Replace your existing _downloadPdf and _pdfRow with these functions:

  Future<void> _downloadPdf(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final numFmt = NumberFormat('#,##0', 'en_US');

    String safeString(dynamic v) => v == null ? '' : v.toString();
    String money(dynamic v) {
      if (v == null) return '0';
      if (v is num) return numFmt.format(v);
      final n = num.tryParse(v.toString());
      return n == null ? v.toString() : numFmt.format(n);
    }

    final product = safeString(data['productName'] ?? data['product'] ?? '');
    final qty = safeString(data['quantity'] ?? '');
    final unit = safeString(data['unit'] ?? '');
    final unitPrice = data['unitPrice'] ?? data['rate'] ?? 0;
    final totalAmount =
        data['totalAmount'] ??
        ((unitPrice is num && data['quantity'] is num)
            ? unitPrice * data['quantity']
            : null);
    final expense = data['expense'] ?? 0;
    final advance = data['advance'] ?? 0;
    final paid = data['paidToFarmer'] ?? data['paid'] ?? 0;
    final balance = data['balance'] ?? 0;
    final extra = data['extraPayment'] ?? 0;
    final status = (safeString(data['status'] ?? '')).toLowerCase();
    String purchaseDateStr = '';
    try {
      purchaseDateStr = dateFormat.format(
        DateTime.parse(safeString(data['purchaseDate'])),
      );
    } catch (_) {
      purchaseDateStr = safeString(data['purchaseDate']);
    }

    // Determine status color for PDF
    PdfColor statusColor = PdfColors.orange400;
    if (status == 'paid' || status == 'completed' || status == 'done') {
      statusColor = PdfColors.green700;
    } else if (status == 'pending') {
      statusColor = PdfColors.orange400;
    } else if (status == 'cancelled' || status == 'rejected') {
      statusColor = PdfColors.red400;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header (Logo box + name + date)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 52,
                        height: 52,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green700,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'm',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'MandiMate',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Purchase Receipt',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        purchaseDateStr,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Container(height: 2, color: PdfColors.green200),
              pw.SizedBox(height: 16),

              // Purchase Details header
              pw.Text(
                'Purchase Details',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 8),

              // Table (single row)
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    color: PdfColors.grey300,
                    width: .5,
                  ),
                ),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _pdfCellHeader('Item'),
                      _pdfCellHeader('Qty'),
                      _pdfCellHeader('Rate'),
                      _pdfCellHeader('Amount'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell(product),
                      _pdfCell(
                        '$qty ${unit.isNotEmpty ? unit : ''}',
                        align: pw.Alignment.center,
                      ),
                      _pdfCell(
                        'Rs ${money(unitPrice)}',
                        align: pw.Alignment.center,
                      ),
                      _pdfCell(
                        'Rs ${money(totalAmount)}',
                        align: pw.Alignment.centerRight,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // Payment Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.white,
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfSummaryRow(
                            'Subtotal',
                            'Rs ${money(totalAmount)}',
                          ),
                          _pdfSummaryRow('Expense', 'Rs ${money(expense)}'),
                          _pdfSummaryRow('Advance', 'Rs ${money(advance)}'),
                          _pdfSummaryRow('Paid to Farmer', 'Rs ${money(paid)}'),
                          if (extra != null && extra.toString() != '0')
                            _pdfSummaryRow(
                              'Extra Payment',
                              'Rs ${money(extra)}',
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Balance',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Rs ${money(balance)}',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green900,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: pw.BoxDecoration(
                              color: statusColor,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Text(
                              status.toUpperCase(),
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 6),
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
    final filename = 'mandimate_receipt_$now.pdf';

    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  // Helper used inside PDF building
  pw.Widget _pdfCellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _pdfCell(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: pw.Align(
        alignment: align,
        child: pw.Text(text, style: pw.TextStyle(fontSize: 11)),
      ),
    );
  }

  pw.Widget _pdfSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
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
