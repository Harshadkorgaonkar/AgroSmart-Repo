import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Added for SystemUiOverlayStyle
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  List<Map<String, dynamic>> cartItems = [];
  String searchQuery = '';
  String? userEmail;
  bool isLoading = true;

  // ✅ Track expanded card
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    userEmail = user?.email;
    if (userEmail != null) {
      _fetchCartItems();
    }
  }

  Future<void> _fetchCartItems() async {
    try {
      final supabase = Supabase.instance.client;

      final cartResponse = await supabase
          .from('cart')
          .select('e_id')
          .eq('email', userEmail!);

      if (cartResponse.isEmpty) {
        setState(() {
          isLoading = false;
          cartItems = [];
        });
        return;
      }

      final List<dynamic> eIds = cartResponse.map((c) => c['e_id']).toList();

      final equipmentsResponse = await supabase
          .from('users_equipments')
          .select(
            'e_id, e_photo_url, e_price, e_type, e_brand, e_model, e_district, e_taluka, email, Users(phone)',
          )
          .inFilter('e_id', eIds);

      // Merge phone from Users
      cartItems = (equipmentsResponse as List<dynamic>)
          .map<Map<String, dynamic>>((item) {
            final map = Map<String, dynamic>.from(item);
            if (map['Users'] != null) {
              map['phone'] = map['Users']['phone'];
            }
            map.remove('Users');
            return map;
          })
          .toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching cart: $e");
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredCartItems {
    return cartItems.where((item) {
      return item['e_model']?.toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ??
          false;
    }).toList();
  }

  String get totalPrice {
    int total = 0;
    for (var item in filteredCartItems) {
      total += int.tryParse(item['e_price'].toString()) ?? 0;
    }
    return '₹${total.toStringAsFixed(0)}';
  }

  Future<void> _removeFromCart(Map<String, dynamic> item) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('cart')
          .delete()
          .eq('email', userEmail!)
          .eq('e_id', item['e_id']);

      setState(() {
        cartItems.remove(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Removed ${item['e_model']} from cart'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("Error removing from cart: $e");
    }
  }

  // ✅ Fetch owner details from Users table
  Future<Map<String, dynamic>?> _fetchUserDetails(String email) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('Users')
          .select('first_name, last_name, gender')
          .eq('email', email)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint("Error fetching user details: $e");
      return null;
    }
  }

  // ✅ Launch phone app
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

  // ✅ Launch WhatsApp
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
      extendBodyBehindAppBar: true, // ✅ so gradient flows behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // ✅ transparent
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle:
            SystemUiOverlayStyle.light, // ✅ status bar text/icons white
        title: const Text(
          "Favorites",
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
              : cartItems.isEmpty
              ? const Center(
                  child: Text(
                    "🛒 Your cart is empty",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (userEmail != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.greenAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                userEmail!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // 🔍 Search
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
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
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 💰 Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '💰Total:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            totalPrice,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🛠️ Cart Items
                    ...filteredCartItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      final isExpanded = expandedIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item['e_photo_url'] != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  item['e_photo_url'],
                                  height: isExpanded ? 240 : 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Type: ${item['e_type']}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "${item['e_brand']}",
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    "${item['e_model']}",
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "District: ${item['e_district']}",
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "Taluka: ${item['e_taluka']}",
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "₹${item['e_price']}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (!isExpanded)
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.greenAccent,
                                              foregroundColor: Colors.black,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                expandedIndex = index;
                                              });
                                            },
                                            child: const Text("View"),
                                          ),
                                        ),
                                      if (isExpanded)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                expandedIndex = null;
                                              });
                                            },
                                            icon: const Icon(Icons.close),
                                            label: const Text("Close"),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () =>
                                              _removeFromCart(item),
                                          child: const Text("Remove"),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // ✅ Show Owner + Icons when expanded
                                  if (isExpanded) ...[
                                    const SizedBox(height: 10),
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: _fetchUserDetails(
                                        item['email'] ?? "",
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Text(
                                            "Fetching owner details...",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          );
                                        }
                                        if (snapshot.hasError ||
                                            snapshot.data == null) {
                                          return const Text(
                                            "Owner details not available",
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13,
                                            ),
                                          );
                                        }
                                        final user = snapshot.data!;
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "👤 Owner: ${user['first_name']} ${user['last_name']}",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    "⚧ Gender: ${user['gender']}",
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (item['phone'] != null &&
                                                item['phone']
                                                    .toString()
                                                    .isNotEmpty)
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const FaIcon(
                                                      FontAwesomeIcons.whatsapp,
                                                      color: Colors.green,
                                                      size: 21,
                                                    ),
                                                    onPressed: () {
                                                      _launchWhatsApp(
                                                        item['phone']
                                                            .toString(),
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.phone,
                                                      color: Colors.white,
                                                      size: 21,
                                                    ),
                                                    onPressed: () {
                                                      _launchPhone(
                                                        item['phone']
                                                            .toString(),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
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
}
