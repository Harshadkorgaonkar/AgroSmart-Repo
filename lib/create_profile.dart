import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard.dart';
import 'terms.dart';

class CreateProfile extends StatefulWidget {
  final String email;

  const CreateProfile({super.key, required this.email});

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController dob = TextEditingController();
  final TextEditingController taluka = TextEditingController();

  String? selectedGender;
  String? selectedState;
  String? selectedDistrict;
  bool acceptedTerms = false;

  Map<String, List<String>> stateDistrictData = {};
  List<String> stateList = [];
  List<String> districtList = [];

  File? _profileImage;
  String? _imageExtension;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _imageExtension = pickedFile.path.split('.').last; // jpg or png
      });
    }
  }

  Future<String?> uploadImageToSupabase(File imageFile) async {
    try {
      final supabase = Supabase.instance.client;

      final fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.${_imageExtension ?? 'jpg'}';

      await supabase.storage
          .from('profilephotos')
          .upload('profile/$fileName', imageFile);

      final publicUrl = supabase.storage
          .from('profilephotos')
          .getPublicUrl('profile/$fileName');

      return publicUrl;
    } catch (e) {
      debugPrint('Image upload failed: $e');
      return null;
    }
  }

  Future<void> submitProfile() async {
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms & conditions')),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      String? imageUrl = '';
      if (_profileImage != null) {
        imageUrl = await uploadImageToSupabase(_profileImage!);
      }

      await supabase.from('Users').insert({
        'email': widget.email,
        'phone': mobile.text.trim(),
        'first_name': firstName.text.trim(),
        'last_name': lastName.text.trim(),
        'dob': dob.text.trim(),
        'gender': selectedGender,
        'state': selectedState,
        'district': selectedDistrict,
        'taluka': taluka.text.trim(),
        'profile_photo_url': imageUrl ?? '',
      });

      await supabase.auth.refreshSession();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    }
  }

  InputDecoration getInputDecoration(String label, {bool enabled = true}) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    final email = widget.email;

    return Scaffold(
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
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Create Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(
                            Icons.photo,
                            color: Colors.white70,
                            size: 30,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                build3DField(
                  TextField(
                    controller: firstName,
                    style: const TextStyle(color: Colors.white),
                    decoration: getInputDecoration('First Name'),
                  ),
                ),
                build3DField(
                  TextField(
                    controller: lastName,
                    style: const TextStyle(color: Colors.white),
                    decoration: getInputDecoration('Last Name'),
                  ),
                ),
                build3DField(
                  TextField(
                    controller: mobile,
                    style: const TextStyle(color: Colors.white),
                    decoration: getInputDecoration('Mobile Number'),
                  ),
                ),
                build3DField(
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: email),
                    style: const TextStyle(color: Colors.grey),
                    decoration: getInputDecoration('Email', enabled: false),
                  ),
                ),
                build3DField(
                  TextField(
                    controller: dob,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: getInputDecoration('Date of Birth'),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        builder: (context, child) =>
                            Theme(data: ThemeData.dark(), child: child!),
                      );
                      if (pickedDate != null) {
                        dob.text =
                            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                      }
                    },
                  ),
                ),
                build3DField(
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    decoration: getInputDecoration('Gender'),
                    value: selectedGender,
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedGender = value),
                  ),
                ),
                build3DField(
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    decoration: getInputDecoration('State'),
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
                  ),
                ),
                build3DField(
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    decoration: getInputDecoration('District'),
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
                  ),
                ),
                build3DField(
                  TextField(
                    controller: taluka,
                    style: const TextStyle(color: Colors.white),
                    decoration: getInputDecoration('Sub-District'),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: acceptedTerms,
                      activeColor: Colors.greenAccent,
                      onChanged: (value) =>
                          setState(() => acceptedTerms = value ?? false),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final accepted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsPage()),
                        );
                        if (accepted != null && accepted) {
                          setState(() {
                            acceptedTerms = true;
                          });
                        }
                      },
                      child: const Text(
                        'Terms & conditions',
                        style: TextStyle(
                          color: Colors.white70,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: InkWell(
                    onTap: submitProfile,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF39FF14), Color(0xFF00FF9D)],
                        ),
                        borderRadius: BorderRadius.circular(14),
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
                        'Done',
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
    );
  }

  @override
  bool get wantKeepAlive => true; // Important for keeping state
}
