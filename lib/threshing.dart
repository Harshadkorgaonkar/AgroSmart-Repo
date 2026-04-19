import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tool_detail.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ThreshingPage extends StatefulWidget {
  const ThreshingPage({super.key});

  @override
  State<ThreshingPage> createState() => _ThreshingPageState();
}

class _ThreshingPageState extends State<ThreshingPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> threshingList = [];
  String searchQuery = '';
  String? selectedState;
  String? selectedDistrict;

  Map<String, List<String>> stateDistrictMap = {};
  List<String> stateList = [];
  List<String> districtList = [];

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadStateDistrictData();
    fetchThreshingData();
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

  Future<void> fetchThreshingData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await supabase
          .from('users_equipments')
          .select('*, Users(first_name, last_name, phone)')
          .eq('e_type', 'Threshing Machine')
          .eq('e_hide', false);

      threshingList = (response as List<dynamic>).map<Map<String, dynamic>>((
        item,
      ) {
        final map = Map<String, dynamic>.from(item);

        if (map['Users'] != null) {
          map['first_name'] = map['Users']['first_name'];
          map['last_name'] = map['Users']['last_name'];
          map['phone'] = map['Users']['phone'];
        }
        map.remove('Users');
        return map;
      }).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Exception: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredThreshing {
    return threshingList.where((item) {
      final model = item['model'] ?? item['e_model'] ?? '';
      final state = item['e_state'] ?? '';
      final district = item['e_district'] ?? '';

      final modelMatch = model.toString().toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final stateMatch = selectedState == null || state == selectedState;
      final districtMatch =
          selectedDistrict == null || district == selectedDistrict;

      return modelMatch && stateMatch && districtMatch;
    }).toList();
  }

  Future<void> addToCart(Map<String, dynamic> item) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("⚠️ Please login first")));
        return;
      }

      final eId = item['e_id'];
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
          content: Text('✅ Added ${item['model'] ?? item['e_model']} to cart'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error adding to cart: $e")));
    }
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

  Widget _priceWidget(dynamic price) {
    return Text(
      "₹$price",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
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
          'Used Threshers',
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search by Model",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
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
                          child: _buildDropdown(
                            'State',
                            stateList,
                            selectedState,
                            (val) {
                              setState(() {
                                selectedState = val;
                                selectedDistrict = null;
                                districtList = stateDistrictMap[val] ?? [];
                              });
                            },
                          ),
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
                    ...filteredThreshing.map((item) {
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
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child:
                                  item['e_photo_url'] != null &&
                                      item['e_photo_url'].toString().isNotEmpty
                                  ? Image.network(
                                      item['e_photo_url'],
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/threshing.png',
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
                                  _infoLine("Name", item['first_name']),
                                  _infoLine("Surname", item['last_name']),
                                  _infoLine("Phone", item['phone']),
                                  _infoLine(
                                    "Model",
                                    item['model'] ?? item['e_model'] ?? '',
                                  ),
                                  _priceWidget(
                                    item['price'] ?? item['e_price'] ?? '',
                                  ),
                                  _infoLine("State", item['e_state']),
                                  _infoLine("District", item['e_district']),
                                  _infoLine("Taluka", item['e_taluka'] ?? ''),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        IconButton(
                                          icon: const FaIcon(
                                            FontAwesomeIcons.phone,
                                            color: Colors.blue,
                                            size: 21,
                                          ),
                                          onPressed: () {
                                            if (item['phone'] != null &&
                                                item['phone']
                                                    .toString()
                                                    .isNotEmpty) {
                                              _launchPhone(
                                                item['phone'].toString(),
                                              );
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
                                            if (item['phone'] != null &&
                                                item['phone']
                                                    .toString()
                                                    .isNotEmpty) {
                                              _launchWhatsApp(
                                                item['phone'].toString(),
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
                                      height: 40,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () => addToCart(item),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.shopping_cart, size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              'Add',
                                              style: TextStyle(
                                                fontSize: 12,
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

  Widget _infoLine(String label, String? value) {
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
