import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _cityController = TextEditingController();

  String? temperature;
  String? condition;
  String? minTemp;
  String? maxTemp;
  String? pressure;
  String? humidity;
  String? windSpeed;
  String? sunrise;
  String? sunset;
  String? cityName;
  bool isLoading = false;

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
    });

    const apiKey = "c3db44df597bbe766d1306d5a756640c";
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          cityName = data['name'];
          double tempK = data['main']['temp'];
          double minK = data['main']['temp_min'];
          double maxK = data['main']['temp_max'];

          temperature = "${(tempK - 273.15).toStringAsFixed(1)}°C";
          condition = data['weather'][0]['main'];
          minTemp = "${(minK - 273.15).toStringAsFixed(1)}°C";
          maxTemp = "${(maxK - 273.15).toStringAsFixed(1)}°C";
          pressure = "${data['main']['pressure']} hPa";
          humidity = "${data['main']['humidity']}%";
          windSpeed = "${data['wind']['speed']} m/s";

          sunrise = DateFormat('hh:mm:ss a').format(
            DateTime.fromMillisecondsSinceEpoch(
              data['sys']['sunrise'] * 1000,
              isUtc: true,
            ),
          );

          sunset = DateFormat('hh:mm:ss a').format(
            DateTime.fromMillisecondsSinceEpoch(
              data['sys']['sunset'] * 1000,
              isUtc: true,
            ),
          );
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("City not found.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong!")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget weatherTile(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white10, Colors.white12],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
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
          Icon(icon, color: Colors.greenAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$label: ${value ?? ''}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Weather Info",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enter City Name',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _cityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'City',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white12,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.greenAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: InkWell(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      fetchWeather(_cityController.text);
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
                            color: Colors.greenAccent.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Search Weather',
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
                const SizedBox(height: 30),
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  )
                else if (temperature != null)
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white10, Colors.white12],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "$cityName",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        weatherTile(Icons.cloud, "Condition", condition),
                        weatherTile(
                          Icons.thermostat,
                          "Temperature",
                          temperature,
                        ),
                        weatherTile(Icons.arrow_downward, "Min Temp", minTemp),
                        weatherTile(Icons.arrow_upward, "Max Temp", maxTemp),
                        weatherTile(Icons.water_drop, "Humidity", humidity),
                        weatherTile(Icons.compress, "Pressure", pressure),
                        weatherTile(Icons.wind_power, "Wind", windSpeed),
                        weatherTile(Icons.wb_sunny, "Sunrise", sunrise),
                        weatherTile(Icons.nightlight_round, "Sunset", sunset),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
