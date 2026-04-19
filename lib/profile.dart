import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'dashboard.dart';

class Profile extends StatefulWidget {
  final String email;
  const Profile({super.key, required this.email});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;

  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final mobileController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final stateController = TextEditingController();
  final districtController = TextEditingController();
  final talukaController = TextEditingController();

  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  String? profilePhotoUrl;
  File? profilePhotoFile;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final res = await supabase
        .from('Users')
        .select()
        .eq('email', widget.email)
        .maybeSingle();

    if (res != null) {
      nameController.text = res['first_name'] ?? '';
      surnameController.text = res['last_name'] ?? '';
      mobileController.text = res['phone'] ?? '';
      dobController.text = res['dob'] ?? '';
      genderController.text = res['gender'] ?? '';
      stateController.text = res['state'] ?? '';
      districtController.text = res['district'] ?? '';
      talukaController.text = res['taluka'] ?? '';
      profilePhotoUrl = res['profile_photo_url'];
    }

    setState(() => isLoading = false);
  }

  Future<void> saveProfile() async {
    setState(() => isSaving = true);

    String? uploadedUrl = profilePhotoUrl;

    if (profilePhotoFile != null) {
      final fileBytes = await profilePhotoFile!.readAsBytes();
      final fileExt = profilePhotoFile!.path.split('.').last;
      final fileName = 'profile/${widget.email}.$fileExt';

      await supabase.storage
          .from('profilephotos')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Fixed: getPublicUrl directly returns string
      uploadedUrl = supabase.storage
          .from('profilephotos')
          .getPublicUrl(fileName);
    }

    final updates = {
      'email': widget.email,
      'first_name': nameController.text,
      'last_name': surnameController.text,
      'phone': mobileController.text,
      'dob': dobController.text,
      'gender': genderController.text,
      'state': stateController.text,
      'district': districtController.text,
      'taluka': talukaController.text,
      'profile_photo_url': uploadedUrl,
    };

    try {
      final response = await supabase
          .from('Users')
          .upsert(updates, onConflict: 'email')
          .select();

      setState(() => isSaving = false);

      if (response != null && response.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile updated")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update failed: No data returned")),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
      print("Error updating profile: $e");
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profilePhotoFile = File(pickedFile.path);
        profilePhotoUrl = pickedFile.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo selected successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
            ? const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color.fromARGB(255, 254, 254, 254),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Dashboard(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        /// Soft Shadow Base (Depth Effect)
                        Container(
                          width: 125,
                          height: 125,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 25,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                        ),

                        /// Main Profile Container
                        Container(
                          width: 115,
                          height: 115,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.shade800,
                                Colors.grey.shade900,
                              ],
                            ),
                            border: Border.all(
                              color: Colors.grey.shade600,
                              width: 2,
                            ),
                            image:
                                profilePhotoUrl != null &&
                                    profilePhotoUrl!.isNotEmpty &&
                                    profilePhotoFile != null
                                ? DecorationImage(
                                    image: FileImage(profilePhotoFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (profilePhotoUrl != null &&
                                      profilePhotoUrl!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(profilePhotoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              (profilePhotoUrl == null ||
                                  profilePhotoUrl!.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                  size: 50,
                                )
                              : null,
                        ),

                        /// Subtle Glass Highlight
                        Positioned(
                          top: 20,
                          left: 35,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        /// Edit Button (Clean Version)
                        if (isEditing)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade300,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoTile('Name', nameController),
                    _buildInfoTile('Surname', surnameController),
                    _buildInfoTile('Mobile', mobileController),
                    _buildInfoTile('Date of Birth', dobController),
                    _buildInfoTile('Gender', genderController),
                    _buildInfoTile('State', stateController),
                    _buildInfoTile('District', districtController),
                    _buildInfoTile('Taluka', talukaController),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: InkWell(
                        onTap: isSaving
                            ? null
                            : () async {
                                if (isEditing) await saveProfile();
                                setState(() => isEditing = !isEditing);
                              },
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
                                color: Colors.greenAccent.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  isEditing ? 'Save' : 'Edit Profile',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoTile(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white10, Colors.white12],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Text(
                    controller.text,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.right,
                  ),
          ),
        ],
      ),
    );
  }
}
