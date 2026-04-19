import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DroneListPage extends StatefulWidget {
  const DroneListPage({super.key});

  @override
  State<DroneListPage> createState() => _DroneListPageState();
}

class _DroneListPageState extends State<DroneListPage> {
  List<Map<String, dynamic>> drones = [];

  String searchQuery = '';
  String? selectedState;
  String? selectedDistrict;

  Map<String, List<String>> stateDistrictMap = {};
  List<String> stateList = [];
  List<String> districtList = [];

  Map<int, bool> expandedCards = {}; // For tracking which card is expanded

  final Map<int, TextEditingController> talukaControllers = {};
  final Map<int, TextEditingController> acresControllers = {};
  final Map<int, TextEditingController> dateControllers = {};
  final Map<int, String?> farmState = {}; // Separate state for farm location
  final Map<int, String?> farmDistrict =
      {}; // Separate district for farm location

  @override
  void initState() {
    super.initState();
    loadStateDistrictData();
    fetchDrones();
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

  Future<void> fetchDrones() async {
    final response = await Supabase.instance.client
        .from('users_drones')
        .select();
    setState(() {
      // Only include drones where e_hide is null or false
      drones = List<Map<String, dynamic>>.from(
        response,
      ).where((d) => !(d['e_hide'] == true)).toList();
    });
  }

  List<Map<String, dynamic>> get filteredDrones {
    return drones.where((d) {
      final modelMatch =
          d['d_model']?.toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ??
          false;
      final stateMatch = selectedState == null || d['d_state'] == selectedState;
      final districtMatch =
          selectedDistrict == null || d['d_district'] == selectedDistrict;
      return modelMatch && stateMatch && districtMatch;
    }).toList();
  }

  Widget _priceWidget(String price) {
    return Text(
      "₹$price per acre",
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
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Drone Services',
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
          child: drones.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    TextField(
                      onChanged: (value) =>
                          setState(() => searchQuery = value.trim()),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search by Model",
                        hintStyle: const TextStyle(color: Colors.white54),
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
                    ...filteredDrones.asMap().entries.map((entry) {
                      final index = entry.key;
                      final d = entry.value;
                      expandedCards.putIfAbsent(index, () => false);
                      talukaControllers.putIfAbsent(
                        index,
                        () => TextEditingController(),
                      );
                      acresControllers.putIfAbsent(
                        index,
                        () => TextEditingController(),
                      );
                      dateControllers.putIfAbsent(
                        index,
                        () => TextEditingController(),
                      );
                      farmState.putIfAbsent(index, () => null);
                      farmDistrict.putIfAbsent(index, () => null);

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
                              child: d['d_image_url'] != null
                                  ? Image.network(
                                      d['d_image_url'],
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 180,
                                      color: Colors.grey[800],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white54,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: _priceWidget(
                                      d['d_area_rate'] ?? '0',
                                    ),
                                  ),
                                  _infoLine("Provider", d['d_provider']),
                                  _infoLine("Operator", d['d_operator']),
                                  _infoLine("Type", d['d_type']),
                                  _infoLine("Model", d['d_model']),
                                  _infoLine("Flight Time", d['d_time']),
                                  _infoLine(
                                    "📍 Location",
                                    "${d['d_district']}, ${d['d_state']}",
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 45,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          expandedCards[index] =
                                              !expandedCards[index]!;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF39FF14),
                                              Color(0xFF00FF9D),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.greenAccent
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          expandedCards[index]!
                                              ? 'Cancel Booking'
                                              : 'Book Drone',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (expandedCards[index]!)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Farm Location",
                                            style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDropdown(
                                            'State',
                                            stateList,
                                            farmState[index],
                                            (val) {
                                              setState(() {
                                                farmState[index] = val;
                                                farmDistrict[index] = null;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDropdown(
                                            'District',
                                            farmState[index] != null
                                                ? stateDistrictMap[farmState[index]] ??
                                                      []
                                                : [],
                                            farmDistrict[index],
                                            (val) {
                                              setState(() {
                                                farmDistrict[index] = val;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller:
                                                talukaControllers[index]!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "Taluka",
                                              hintStyle: const TextStyle(
                                                color: Colors.white54,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white12,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller:
                                                acresControllers[index]!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "Acres",
                                              hintStyle: const TextStyle(
                                                color: Colors.white54,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white12,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: dateControllers[index]!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "Date",
                                              hintStyle: const TextStyle(
                                                color: Colors.white54,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white12,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 45,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.greenAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () async {
                                                final user = Supabase
                                                    .instance
                                                    .client
                                                    .auth
                                                    .currentUser;
                                                if (user == null) return;
                                                final sEmail = user.email!;
                                                final userInfo = await Supabase
                                                    .instance
                                                    .client
                                                    .from('Users')
                                                    .select(
                                                      'first_name,last_name',
                                                    )
                                                    .eq('email', sEmail)
                                                    .single();
                                                final fname =
                                                    userInfo['first_name'];
                                                final lname =
                                                    userInfo['last_name'];

                                                await Supabase.instance.client
                                                    .from('req')
                                                    .insert({
                                                      'idd': d['id'],
                                                      'state': farmState[index],
                                                      'district':
                                                          farmDistrict[index],
                                                      'taluka':
                                                          talukaControllers[index]!
                                                              .text
                                                              .trim(),
                                                      'acres':
                                                          acresControllers[index]!
                                                              .text
                                                              .trim(),
                                                      'date':
                                                          dateControllers[index]!
                                                              .text
                                                              .trim(),
                                                      'fname': fname,
                                                      'lname': lname,
                                                      's_email': sEmail,
                                                      'r_email':
                                                          d['email'], // provider email
                                                    });

                                                setState(() {
                                                  expandedCards[index] = false;
                                                });

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    backgroundColor:
                                                        Colors.greenAccent,
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    content: Row(
                                                      children: const [
                                                        Icon(
                                                          Icons.check_circle,
                                                          color: Colors.black,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            "Booking request sent successfully",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Confirm Booking',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
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
        "$label: ${value ?? '-'}",
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
