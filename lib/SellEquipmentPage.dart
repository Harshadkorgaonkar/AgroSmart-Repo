import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellEquipmentPage extends StatefulWidget {
  final String email; // email passed to this page

  const SellEquipmentPage({super.key, required this.email});

  @override
  State<SellEquipmentPage> createState() => _SellEquipmentPageState();
}

class _SellEquipmentPageState extends State<SellEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController hpController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController talukaController = TextEditingController();

  String selectedType = 'Tractor';
  String? selectedState;
  String? selectedDistrict;

  Map<String, List<String>> stateDistrictData = {};
  List<String> stateList = [];
  List<String> districtList = [];

  final List<String> equipmentTypes = [
    'Tractor',
    'Rotavator',
    'Cultivator',
    'Harrow',
    'Reaper',
    'Threshing Machine',
    'Front Loader',
    'Farm Trailer',
    'Power Weeder',
  ];

  final List<String> hpRequiredTypes = [
    'Tractor',
    'Power Weeder',
    'Threshing Machine',
    'Front Loader',
  ];

  bool isSubmitting = false; // 👈 loading state

  @override
  void initState() {
    super.initState();
    loadStateDistrictData();
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
      setState(() => isSubmitting = true);

      try {
        final supabase = Supabase.instance.client;

        final fileName =
            'equipment_pic/${DateTime.now().millisecondsSinceEpoch}_${widget.email}.jpg';

        // ✅ 1️⃣ Upload Image
        await supabase.storage.from('profilephotos').upload(fileName, _image!);

        // ✅ 2️⃣ Get Public URL
        final imageUrl = supabase.storage
            .from('profilephotos')
            .getPublicUrl(fileName);

        // ✅ 3️⃣ Insert Equipment Data
        await supabase.from('users_equipments').insert({
          'email': widget.email,
          'e_type': selectedType,
          'e_brand': nameController.text,
          'e_model': modelController.text,
          'e_horsepower': hpController.text.isNotEmpty
              ? int.parse(hpController.text)
              : null,
          'phone': phoneController.text,
          'e_state': selectedState,
          'e_district': selectedDistrict,
          'e_taluka': talukaController.text,
          'e_price': int.parse(priceController.text),
          'e_description': descController.text,
          'e_photo_url': imageUrl,
          'created_at': DateTime.now().toIso8601String(),
          'e_hide': false,
        });

        // ✅ 4️⃣ Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$selectedType submitted successfully ✅')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      } finally {
        setState(() => isSubmitting = false);
      }
    } else if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Sell Equipment'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      build3DField(
                        TextFormField(
                          initialValue: widget.email,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white70),
                          decoration: getInputDecoration('Your Email'),
                        ),
                      ),
                      build3DField(
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          items: equipmentTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedType = value!),
                          dropdownColor: Colors.grey.shade900,
                          decoration: getInputDecoration('Equipment Type'),
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
                                    'Tap to upload photo',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      build3DField(
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: getInputDecoration('$selectedType Brand'),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter name' : null,
                        ),
                      ),
                      build3DField(
                        TextFormField(
                          controller: modelController,
                          style: const TextStyle(color: Colors.white),
                          decoration: getInputDecoration('Model Number'),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter model number' : null,
                        ),
                      ),
                      if (hpRequiredTypes.contains(selectedType))
                        build3DField(
                          TextFormField(
                            controller: hpController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: getInputDecoration('Horsepower (HP)'),
                            validator: (value) =>
                                value!.isEmpty ? 'Enter HP' : null,
                          ),
                        ),
                      build3DField(
                        TextFormField(
                          controller: phoneController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.phone,
                          decoration: getInputDecoration('Phone Number'),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter phone number' : null,
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
                        ),
                      ),
                      build3DField(
                        TextFormField(
                          controller: priceController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: getInputDecoration('Price (₹)'),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter price' : null,
                        ),
                      ),
                      build3DField(
                        TextFormField(
                          controller: descController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: getInputDecoration('Description'),
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
          if (isSubmitting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            ),
        ],
      ),
    );
  }
}
