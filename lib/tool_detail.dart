import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ToolDetailPage extends StatelessWidget {
  final Map<String, dynamic> loader;

  const ToolDetailPage({super.key, required this.loader});

  // ✅ Launch phone dialer
  Future<void> _callPhoneNumber(String phone, BuildContext context) async {
    final Uri phoneUri = Uri.parse('tel:$phone'); // Use Uri.parse

    try {
      if (!await launchUrl(phoneUri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer for: $phone')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = loader['photo'];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tool Details',
          style: TextStyle(color: Colors.greenAccent),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo != null && photo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  photo,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white30,
                    size: 48,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            _infoLine("Phone", loader['phone']),
            _infoLine("Model", loader['model']),
            _infoLine("State", loader['state']),
            _infoLine("District", loader['district']),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: InkWell(
                onTap: () {
                  final phone = loader['phone'];
                  if (phone != null && phone.isNotEmpty) {
                    _callPhoneNumber(phone, context);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF39FF14), Color(0xFF00FF9D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Call Owner',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        "$label: ${value ?? 'N/A'}",
        style: const TextStyle(color: Colors.white70, fontSize: 15),
      ),
    );
  }
}
