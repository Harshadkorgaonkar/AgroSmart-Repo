import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyDronesPage extends StatefulWidget {
  final String userEmail;
  const MyDronesPage({super.key, required this.userEmail});

  @override
  State<MyDronesPage> createState() => _MyDronesPageState();
}

class _MyDronesPageState extends State<MyDronesPage> {
  List<Map<String, dynamic>> myDrones = [];
  bool isLoading = true;

  String searchQuery = '';
  String? selectedState;
  String? selectedDistrict;

  Map<String, List<String>> stateDistrictMap = {};
  List<String> stateList = [];
  List<String> districtList = [];

  Map<int, bool> editMode = {};
  Map<int, Map<String, TextEditingController>> controllers = {};

  @override
  void initState() {
    super.initState();
    loadStateDistrictData();
    fetchUserDrones();
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

  Future<void> fetchUserDrones() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('users_drones')
          .select()
          .eq('email', widget.userEmail);

      setState(() {
        myDrones = List<Map<String, dynamic>>.from(data as List);
        for (var drone in myDrones) {
          final id = drone['id'] as int;
          editMode[id] = false;
          controllers[id] = {
            'd_type': TextEditingController(text: drone['d_type'] ?? ''),
            'd_provider': TextEditingController(
              text: drone['d_provider'] ?? '',
            ),
            'd_operator': TextEditingController(
              text: drone['d_operator'] ?? '',
            ),
            'd_model': TextEditingController(text: drone['d_model'] ?? ''),
            'd_time': TextEditingController(text: drone['d_time'] ?? ''),
            'd_area_rate': TextEditingController(
              text: drone['d_area_rate'] ?? '',
            ),
            'd_state': TextEditingController(text: drone['d_state'] ?? ''),
            'd_district': TextEditingController(
              text: drone['d_district'] ?? '',
            ),
            'd_taluka': TextEditingController(text: drone['d_taluka'] ?? ''),
            'd_image_url': TextEditingController(
              text: drone['d_image_url'] ?? '',
            ),
            'e_hide': TextEditingController(
              text: (drone['e_hide'] ?? false).toString(),
            ),
          };
        }
        isLoading = false;
      });
    } catch (e, st) {
      debugPrint("Error fetching drones: $e\n$st");
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteDrone(int id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('users_drones').delete().eq('id', id);
      await fetchUserDrones();
    } catch (e) {
      debugPrint("Error deleting drone: $e");
    }
  }

  Future<void> confirmDelete(BuildContext context, int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Confirm Delete",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this drone?",
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
    if (confirm == true) await deleteDrone(id);
  }

  Future<void> toggleHideDrone(int id) async {
    final supabase = Supabase.instance.client;
    try {
      final currentHide = (controllers[id]!['e_hide']!.text == 'true');
      await supabase
          .from('users_drones')
          .update({'e_hide': !currentHide})
          .eq('id', id);
      await fetchUserDrones();
    } catch (e) {
      debugPrint("Error updating hide status: $e");
    }
  }

  Future<void> saveDrone(int id) async {
    final supabase = Supabase.instance.client;
    final updatedData = {
      'd_type': controllers[id]!['d_type']!.text,
      'd_provider': controllers[id]!['d_provider']!.text,
      'd_operator': controllers[id]!['d_operator']!.text,
      'd_model': controllers[id]!['d_model']!.text,
      'd_time': controllers[id]!['d_time']!.text,
      'd_area_rate': controllers[id]!['d_area_rate']!.text,
      'd_state': controllers[id]!['d_state']!.text,
      'd_district': controllers[id]!['d_district']!.text,
      'd_taluka': controllers[id]!['d_taluka']!.text,
      'd_image_url': controllers[id]!['d_image_url']!.text,
    };

    try {
      await supabase.from('users_drones').update(updatedData).eq('id', id);
      setState(() => editMode[id] = false);
      await fetchUserDrones();
    } catch (e) {
      debugPrint("Error saving drone: $e");
    }
  }

  List<Map<String, dynamic>> get filteredDrones {
    return myDrones.where((d) {
      final modelMatch = (d['d_model'] ?? '').toString().toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final stateMatch = selectedState == null || d['d_state'] == selectedState;
      final districtMatch =
          selectedDistrict == null || d['d_district'] == selectedDistrict;
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
          'My Drones',
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
                    if (filteredDrones.isEmpty)
                      const Center(
                        child: Text(
                          "No drones found",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ...filteredDrones.map((d) {
                        final id = d['id'] as int;
                        final bool isHidden = d['e_hide'] ?? false;
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
                                  d['d_image_url'] ?? '',
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _editableLine(
                                    id,
                                    "Type",
                                    "d_type",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Provider",
                                    "d_provider",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Operator",
                                    "d_operator",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Model",
                                    "d_model",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Time",
                                    "d_time",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Area Rate",
                                    "d_area_rate",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "State",
                                    "d_state",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "District",
                                    "d_district",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Taluka",
                                    "d_taluka",
                                    isEditing,
                                  ),
                                  _editableLine(
                                    id,
                                    "Image URL",
                                    "d_image_url",
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
                                        await saveDrone(id);
                                      } else {
                                        setState(() => editMode[id] = true);
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
                                      await toggleHideDrone(id);
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

  Widget _editableLine(int id, String label, String field, bool isEditing) {
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
          onChanged: (val) => setState(() => searchQuery = val),
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
                (val) => setState(() => selectedDistrict = val),
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
