import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> sentRequests = [];
  List<Map<String, dynamic>> receivedRequests = [];

  bool isLoadingSent = true;
  bool isLoadingReceived = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchSentRequests();
    fetchReceivedRequests();
  }

  Map<String, dynamic> mapRequest(
    Map<String, dynamic> req,
    Map<String, dynamic> drone,
    String? phone,
    bool includePhone,
  ) {
    return {
      'image': drone['d_image_url'] ?? '',
      'type': drone['d_type'] ?? '-',
      'provider': drone['d_provider'] ?? '-',
      'operator': drone['d_operator'] ?? '-',
      'model': drone['d_model'] ?? '-',
      'state': drone['d_state'] ?? '-',
      'district': drone['d_district'] ?? '-',
      'taluka': drone['d_taluka'] ?? '-',
      'acres': req['acres'] ?? '-',
      'date': req['date'] ?? '-',
      'from': req['s_email'] ?? '-',
      'id': req['id'],
      'idd': req['idd'],
      'req_state': req['state'] ?? '-',
      'req_district': req['district'] ?? '-',
      'req_taluka': req['taluka'] ?? '-',
      'req_fname': req['fname'] ?? '-',
      'req_lname': req['lname'] ?? '-',
      'accepted': (req['accept'] == true),
      'phone': includePhone ? (phone ?? '-') : null,
    };
  }

  Future<void> fetchSentRequests() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final sEmail = user.email!;

    final requests = await Supabase.instance.client
        .from('req')
        .select()
        .eq('s_email', sEmail);

    List<Map<String, dynamic>> tempList = [];

    for (var req in requests) {
      final idd = req['idd'];
      final drone = await Supabase.instance.client
          .from('users_drones')
          .select()
          .eq('id', idd)
          .single();

      String? droneEmail = drone['email'];
      String? dronePhone = '-';
      if (droneEmail != null) {
        final userData = await Supabase.instance.client
            .from('Users')
            .select('phone')
            .eq('email', droneEmail)
            .maybeSingle();
        dronePhone = userData != null ? userData['phone'] : '-';
      }

      tempList.add(mapRequest(req, drone, dronePhone, true));
    }

    setState(() {
      sentRequests = tempList;
      isLoadingSent = false;
    });
  }

  Future<void> fetchReceivedRequests() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final rEmail = user.email!;

    final requests = await Supabase.instance.client
        .from('req')
        .select()
        .eq('r_email', rEmail);

    List<Map<String, dynamic>> tempList = [];

    for (var req in requests) {
      final idd = req['idd'];
      final drone = await Supabase.instance.client
          .from('users_drones')
          .select()
          .eq('id', idd)
          .single();
      tempList.add(mapRequest(req, drone, null, false));
    }

    setState(() {
      receivedRequests = tempList;
      isLoadingReceived = false;
    });
  }

  Future<void> cancelRequest(int id) async {
    await Supabase.instance.client.from('req').delete().eq('id', id);
    fetchSentRequests();
  }

  Future<void> updateAcceptStatus(int id, bool newStatus) async {
    await Supabase.instance.client
        .from('req')
        .update({'accept': newStatus})
        .eq('id', id);
    fetchReceivedRequests();
  }

  Future<void> handleAcceptOrUndo(int id, bool currentlyAccepted) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          currentlyAccepted ? "Undo Acceptance" : "Confirm Acceptance",
        ),
        content: Text(
          currentlyAccepted
              ? "Don't want to accept this request?"
              : "Are you sure you want to accept this request?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm) {
      await updateAcceptStatus(id, !currentlyAccepted);
    }
  }

  Future<void> deleteRequest(int id) async {
    await Supabase.instance.client.from('req').delete().eq('id', id);
    fetchSentRequests();
    fetchReceivedRequests();
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cannot open phone app")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error opening phone app: $e")));
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final uri = Uri.parse("https://wa.me/$phoneNumber");
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cannot open WhatsApp")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error opening WhatsApp: $e")));
    }
  }

  Widget buildRequestCard(Map<String, dynamic> item, {bool isSent = true}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shadowColor: Colors.green.shade200,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item['image'] != ''
                      ? Image.network(
                          item['image'],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['type'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (item['phone'] != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () => _launchPhone(item['phone']),
                      ),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.green,
                        ),
                        onPressed: () => _launchWhatsApp(item['phone']),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            isSent
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Provider: ${item['provider']}"),
                      Text("Operator: ${item['operator']}"),
                      Text("Model: ${item['model']}"),
                      Text(
                        "State: ${item['state']}, District: ${item['district']}",
                      ),
                      Text(
                        "Taluka: ${item['taluka']}, Acres: ${item['acres']}",
                      ),
                      Text("Date: ${item['date']}"),
                      const SizedBox(height: 8),
                      item['accepted']
                          ? Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 6),
                                  Text(
                                    "Drone Request Accepted",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: ElevatedButton(
                                onPressed: () async {
                                  bool confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Confirm Cancellation"),
                                      content: const Text(
                                        "Are you sure you want to cancel this request?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text("No"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text("Yes"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm) {
                                    cancelRequest(item['id']);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Cancel Request"),
                              ),
                            ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Request From: ${item['from']}"),
                      Text(
                        "State: ${item['req_state']}, District: ${item['req_district']}",
                      ),
                      Text("Taluka: ${item['req_taluka']}"),
                      Text("First Name: ${item['req_fname']}"),
                      Text("Last Name: ${item['req_lname']}"),
                      Text("Acres: ${item['acres']}"),
                      Text("Date: ${item['date']}"),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await handleAcceptOrUndo(
                              item['id'],
                              item['accepted'],
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: item['accepted']
                                ? Colors.grey.shade600
                                : Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            item['accepted'] ? "Accepted" : "Accept Request",
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Deletion"),
                      content: const Text(
                        "Are you sure you want to delete this request?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("No"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  );
                  if (confirm) {
                    deleteRequest(item['id']);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Delete Request"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Requests"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Sent Requests"),
            Tab(text: "Received Requests"),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 55, 86, 118),
              Color.fromARGB(255, 9, 14, 19),
              Color(0xFF000000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            isLoadingSent
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  )
                : ListView.builder(
                    itemCount: sentRequests.length,
                    itemBuilder: (context, index) =>
                        buildRequestCard(sentRequests[index], isSent: true),
                  ),
            isLoadingReceived
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  )
                : ListView.builder(
                    itemCount: receivedRequests.length,
                    itemBuilder: (context, index) => buildRequestCard(
                      receivedRequests[index],
                      isSent: false,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
