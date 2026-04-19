import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellDronPage extends StatefulWidget {
  const SellDronPage({super.key});

  @override
  State<SellDronPage> createState() => _SellDronPageState();
}

class _SellDronPageState extends State<SellDronPage> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final picker = ImagePicker();

  final TextEditingController providerController = TextEditingController();
  final TextEditingController operatorController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController fightTimeController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController talukaController = TextEditingController();

  String? selectedType;
  String? selectedState;
  String? selectedDistrict;

  Map<String, List<String>> stateDistrictData = {};
  List<String> stateList = [];
  List<String> districtList = [];

  final List<String> droneTypes = [
    'Spraying Drone',
    'Survey Drone',
    'Hybrid Drone',
    'Multi-Rotor Drone',
    'Fixed Wing Drone',
  ];

  String? userEmail;

  @override
  void initState() {
    super.initState();
    loadStateDistrictData();
    fetchUserEmail();
  }

  Future<void> fetchUserEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      userEmail = user?.email ?? "Unknown User";
    });
  }

  Future<void> loadStateDistrictData() async {
    final jsonString = await rootBundle.loadString(
      'assets/states-and-districts.json',
    );
    final data = json.decode(jsonString);
    for (var item in data['states']) {
      stateDistrictData[item['state']] = List<String>.from(item['districts']);
    }
    setState(() {
      stateList = stateDistrictData.keys.toList();
    });
  }

  InputDecoration getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.greenAccent),
      ),
    );
  }

  Widget build3DField(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _image != null) {
      try {
        final fileName =
            'drones/drone_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final fileBytes = await _image!.readAsBytes();

        await Supabase.instance.client.storage
            .from('profilephotos')
            .uploadBinary(
              fileName,
              fileBytes,
              fileOptions: const FileOptions(upsert: true),
            );

        final imageUrl = Supabase.instance.client.storage
            .from('profilephotos')
            .getPublicUrl(fileName);

        await Supabase.instance.client.from('users_drones').insert({
          'd_type': selectedType,
          'd_provider': providerController.text.trim(),
          'd_operator': operatorController.text.trim(),
          'd_model': modelController.text.trim(),
          'd_area_rate': rateController.text.trim(),
          'd_state': selectedState,
          'd_district': selectedDistrict,
          'd_taluka': talukaController.text.trim(),
          'd_image_url': imageUrl,
          'd_time': fightTimeController.text.trim(),
          'email': userEmail,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drone listing submitted successfully ✅'),
          ),
        );

        _formKey.currentState!.reset();
        setState(() {
          _image = null;
          selectedType = null;
          selectedState = null;
          selectedDistrict = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a drone image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Sell Drone'),
        backgroundColor: Colors.transparent,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userEmail != null) ...[
                    Text(
                      "            $userEmail",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  build3DField(
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: droneTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedType = value),
                      dropdownColor: Colors.grey.shade900,
                      decoration: getInputDecoration('Drone Type'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Text(
                                'Tap to upload drone photo',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  build3DField(
                    TextFormField(
                      controller: providerController,
                      style: const TextStyle(color: Colors.white),
                      decoration: getInputDecoration('Provider Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter provider name' : null,
                    ),
                  ),
                  build3DField(
                    TextFormField(
                      controller: operatorController,
                      style: const TextStyle(color: Colors.white),
                      decoration: getInputDecoration('Operator Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter operator name' : null,
                    ),
                  ),
                  build3DField(
                    TextFormField(
                      controller: modelController,
                      style: const TextStyle(color: Colors.white),
                      decoration: getInputDecoration('Drone Model'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter drone model' : null,
                    ),
                  ),
                  build3DField(
                    TextFormField(
                      controller: fightTimeController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: getInputDecoration('Fight Time (hrs)'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter fight time in hours' : null,
                    ),
                  ),
                  build3DField(
                    TextFormField(
                      controller: rateController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: getInputDecoration('Rate per Acre (₹)'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter rental rate' : null,
                    ),
                  ),
                  build3DField(
                    DropdownButtonFormField<String>(
                      value: selectedState,
                      items: stateList
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedState = value;
                          selectedDistrict = null;
                          districtList = stateDistrictData[value] ?? [];
                        });
                      },
                      dropdownColor: Colors.grey.shade900,
                      decoration: getInputDecoration('State'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  build3DField(
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      items: districtList
                          .map(
                            (district) => DropdownMenuItem(
                              value: district,
                              child: Text(district),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedDistrict = value),
                      dropdownColor: Colors.grey.shade900,
                      decoration: getInputDecoration('District'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  build3DField(
                    TextFormField(
                      controller: talukaController,
                      style: const TextStyle(color: Colors.white),
                      decoration: getInputDecoration('Taluka'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter taluka' : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: InkWell(
                      onTap: _submitForm,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF39FF14), Color(0xFF00FF9D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
