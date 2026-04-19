import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HarrowPage extends StatefulWidget {
  const HarrowPage({super.key});

  @override
  State<HarrowPage> createState() => _HarrowPageState();
}

class _HarrowPageState extends State<HarrowPage> {
  List<dynamic> harrows = [];
  String searchQuery = '';
  String? selectedState;
  String? selectedDistrict;

  Map<String, List<String>> stateDistrictMap = {};
  List<String> stateList = [];
  List<String> districtList = [];

  @override
  void initState() {
    super.initState();
    loadStateDistrictData();
    fetchHarrows();
  }

  Future<void> loadStateDistrictData() async {
    final String response = await rootBundle.loadString(
      'assets/states-and-districts.json',
    );
    final data = json.decode(response);
    final Map<String, List<String>> map = {};
    for (var state in data['states']) {
      map[state['state']] = List<String>.from(state['districts']);
    }
    setState(() {
      stateDistrictMap = map;
      stateList = map.keys.toList();
    });
  }

  Future<void> fetchHarrows() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('users_equipments')
        .select('*, Users(first_name, last_name, phone)')
        .eq('e_type', 'Harrow')
        .eq('e_hide', false);

    setState(() {
      harrows = response;
    });
  }

  Future<void> addToCart(Map<String, dynamic> harrow) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("⚠️ Please login first")));
        return;
      }

      final eId = harrow['e_id'];
      final email = user.email;

      if (eId == null || email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Missing equipment ID or email")),
        );
        return;
      }

      await supabase.from('cart').insert({'e_id': eId, 'email': email});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${harrow['model'] ?? harrow['e_model']} added to cart',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error adding to cart: $e")));
    }
  }

  List<dynamic> get filteredHarrows {
    return harrows.where((h) {
      final model = (h['model'] ?? h['e_model'] ?? '').toString().toLowerCase();
      final modelMatch = model.contains(searchQuery.toLowerCase());
      final stateMatch = selectedState == null || h['e_state'] == selectedState;
      final districtMatch =
          selectedDistrict == null || h['e_district'] == selectedDistrict;
      return modelMatch && stateMatch && districtMatch;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Used Harrows',
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search by Model",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown('State', stateList, selectedState, (
                      val,
                    ) {
                      setState(() {
                        selectedState = val;
                        selectedDistrict = null;
                        districtList = stateDistrictMap[val] ?? [];
                      });
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      'District',
                      districtList,
                      selectedDistrict,
                      (val) {
                        setState(() {
                          selectedDistrict = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...filteredHarrows.map((h) {
                final user = h['Users'] ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (h['e_photo_url'] != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            h['e_photo_url'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoLine("Name", user['first_name']),
                            _infoLine("Surname", user['last_name']),
                            _infoLine("Phone", user['phone']),
                            _infoLine("Model", h['model'] ?? h['e_model']),
                            _infoLine("Price", h['price'] ?? h['e_price']),
                            _infoLine("State", h['e_state']),
                            _infoLine("District", h['e_district']),
                            _infoLine("Taluka", h['e_taluka']),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.phone,
                                      color: Colors.blue,
                                      size: 21,
                                    ),
                                    onPressed: () {
                                      if (user['phone'] != null &&
                                          user['phone'].toString().isNotEmpty) {
                                        _launchPhone(user['phone'].toString());
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      if (user['phone'] != null &&
                                          user['phone'].toString().isNotEmpty) {
                                        _launchWhatsApp(
                                          user['phone'].toString(),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () =>
                                      addToCart(h as Map<String, dynamic>),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$label: ${value ?? ''}",
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white12,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
