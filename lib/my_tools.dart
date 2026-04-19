import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyToolsPage extends StatefulWidget {
  final String userEmail;

  const MyToolsPage({super.key, required this.userEmail});

  @override
  State<MyToolsPage> createState() => _MyToolsPageState();
}

class _MyToolsPageState extends State<MyToolsPage> {
  List<Map<String, dynamic>> myTools = [];
  bool isLoading = true;

  String searchQuery = '';
  String? selectedState;
  String? selectedDistrict;

  Map<String, List<String>> stateDistrictMap = {};
  List<String> stateList = [];
  List<String> districtList = [];

  Map<String, bool> editMode = {};
  Map<String, Map<String, TextEditingController>> controllers = {};

  @override
  void initState() {
    super.initState();
    loadStateDistrictData();
    fetchUserEquipments();
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

  Future<void> fetchUserEquipments() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('users_equipments')
          .select()
          .eq('email', widget.userEmail);

      setState(() {
        myTools = List<Map<String, dynamic>>.from(response);
        for (var tool in myTools) {
          final id = tool['e_id'].toString();
          editMode[id] = false;
          controllers[id] = {
            'phone': TextEditingController(text: tool['phone'] ?? ''),
            'e_brand': TextEditingController(text: tool['e_brand'] ?? ''),
            'e_model': TextEditingController(text: tool['e_model'] ?? ''),
            'e_horsepower': TextEditingController(
              text: tool['e_horsepower'] ?? '',
            ),
            'e_state': TextEditingController(text: tool['e_state'] ?? ''),
            'e_district': TextEditingController(text: tool['e_district'] ?? ''),
            'e_taluka': TextEditingController(text: tool['e_taluka'] ?? ''),
            'e_description': TextEditingController(
              text: tool['e_description'] ?? '',
            ),
            'e_price': TextEditingController(
              text: tool['e_price']?.toString() ?? '',
            ),
          };
        }
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching equipments: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteEquipment(String eId) async {
    final supabase = Supabase.instance.client;
    await supabase.from('users_equipments').delete().eq('e_id', eId);
    fetchUserEquipments();
  }

  Future<void> confirmDelete(BuildContext context, String eId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Confirm Delete",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this equipment?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteEquipment(eId);
    }
  }

  Future<void> toggleHideEquipment(String eId, bool isCurrentlyHidden) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('users_equipments')
          .update({'e_hide': !isCurrentlyHidden})
          .eq('e_id', eId);

      await fetchUserEquipments();
    } catch (e) {
      print("Error updating hide status: $e");
    }
  }

  Future<void> saveEquipment(String eId) async {
    final supabase = Supabase.instance.client;
    final updatedData = {
      'phone': controllers[eId]!['phone']!.text,
      'e_brand': controllers[eId]!['e_brand']!.text,
      'e_model': controllers[eId]!['e_model']!.text,
      'e_horsepower': controllers[eId]!['e_horsepower']!.text,
      'e_state': controllers[eId]!['e_state']!.text,
      'e_district': controllers[eId]!['e_district']!.text,
      'e_taluka': controllers[eId]!['e_taluka']!.text,
      'e_description': controllers[eId]!['e_description']!.text,
      'e_price': controllers[eId]!['e_price']!.text,
    };

    try {
      await supabase
          .from('users_equipments')
          .update(updatedData)
          .eq('e_id', eId);
      setState(() {
        editMode[eId] = false;
      });
      await fetchUserEquipments();
    } catch (e) {
      print("Error saving equipment: $e");
    }
  }

  List<Map<String, dynamic>> get filteredTools {
    return myTools.where((tool) {
      final modelMatch = (tool['e_model'] ?? '')
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      final stateMatch =
          selectedState == null || tool['e_state'] == selectedState;
      final districtMatch =
          selectedDistrict == null || tool['e_district'] == selectedDistrict;
      return modelMatch && stateMatch && districtMatch;
    }).toList();
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
          'My Tools',
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    Center(
                      child: Text(
                        widget.userEmail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSearchAndFilters(),
                    const SizedBox(height: 12),
                    if (filteredTools.isEmpty)
                      const Center(
                        child: Text(
                          "No equipments found",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ...filteredTools.map((tool) {
                        final id = tool['e_id'].toString();
                        final bool isHidden = tool['e_hide'] ?? false;
                        final isEditing = editMode[id] ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  tool['e_photo_url'] ?? '',
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    height: 180,
                                    width: double.infinity,
                                    color: Colors.grey,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Price
                              isEditing
                                  ? TextField(
                                      controller: controllers[id]!['e_price'],
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: "Price",
                                        labelStyle: TextStyle(
                                          color: Colors.greenAccent,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "₹ ${tool['e_price'] ?? ''}",
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              const SizedBox(height: 6),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _editableLine(
                                    id,
                                    "Phone",
                                    "phone",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Brand",
                                    "e_brand",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Model",
                                    "e_model",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Horse Power",
                                    "e_horsepower",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "State",
                                    "e_state",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "District",
                                    "e_district",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Taluka",
                                    "e_taluka",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Description",
                                    "e_description",
                                    isEditing,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isEditing
                                          ? Colors.blue
                                          : Colors.teal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (isEditing) {
                                        await saveEquipment(id);
                                      } else {
                                        setState(() {
                                          editMode[id] = true;
                                        });
                                      }
                                    },
                                    icon: Icon(
                                      isEditing ? Icons.save : Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      isEditing ? "Save" : "Edit",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () async {
                                      await confirmDelete(context, id);
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "Delete",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade800,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () async {
                                      await toggleHideEquipment(id, isHidden);
                                    },
                                    icon: Icon(
                                      isHidden
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      isHidden ? "Unhide" : "Hide",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _editableLine(String id, String label, String field, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: isEditing
          ? TextField(
              controller: controllers[id]![field],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.white70),
              ),
            )
          : Text(
              "$label: ${controllers[id]![field]!.text}",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
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
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown('State', stateList, selectedState, (val) {
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
      ],
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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      value: items.contains(value) ? value : null,
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
