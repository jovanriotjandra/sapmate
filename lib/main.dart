import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:sapmate/services/weather_service.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';

const String weatherApiKey = "4d9653b43b1120f76945ef145222616b";

void main() {
  runApp(const EntryPage());
}

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SAPA",
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "SAPA",
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "powered by SAP 'mate",
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 32,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  bool isOptimalModeOn = true;

  String currentLocation = "Garching";
  double temperature = 16.0;
  double brightness = 0.0;
  double humidity = 70.0;

  // Pending changes from preferences (for when optimal mode is OFF)
  double pendingTemperature = 22.0;
  double pendingBrightness = 80.0;
  double pendingHumidity = 45.0;

  // Optimal home settings (for when optimal mode is ON)
  final double optimalTemperature = 22.0;
  final double optimalBrightness = 80.0;
  final double optimalHumidity = 45.0;

  void _updateHomeSettings() {
    setState(() {
      if (isOptimalModeOn) {
        // Use optimal settings
        temperature = optimalTemperature;
        brightness = optimalBrightness;
        humidity = optimalHumidity;
      } else {
        // Use preference settings
        temperature = pendingTemperature;
        brightness = pendingBrightness;
        humidity = pendingHumidity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _HomeContent(
        isOptimalModeOn: isOptimalModeOn,
        onOptimalModeChanged: (value) {
          setState(() {
            isOptimalModeOn = value;
            if (value && currentIndex == 1) {
              currentIndex = 0;
            }
            // If we're at home, update settings based on new optimal mode state
            if (currentLocation == "Studentenstadt") {
              _updateHomeSettings();
            }
          });
        },
        currentLocation: currentLocation,
        temperature: temperature,
        brightness: brightness,
        humidity: humidity,
        onLocationChange: () {
          setState(() {
            if (currentLocation == "Garching") {
              // Going home
              currentLocation = "Studentenstadt";
              _updateHomeSettings();
            } else {
              // Going to work
              currentLocation = "Garching";
              temperature = 16.0;
              brightness = 0.0;
              humidity = 70.0;
            }
          });
        },
      ),
      DashboardPage(
        isOptimalModeOn: isOptimalModeOn,
        temperature: pendingTemperature,
        brightness: pendingBrightness,
        humidity: pendingHumidity,
        onValuesChanged: (temp, bright, humid) {
          setState(() {
            pendingTemperature = temp;
            pendingBrightness = bright;
            pendingHumidity = humid;
            // If we're at home AND optimal mode is OFF, apply changes immediately
            if (currentLocation == "Studentenstadt" && !isOptimalModeOn) {
              temperature = temp;
              brightness = bright;
              humidity = humid;
            }
          });
        },
      ),
      DevicesPage(),
      AIAgentPage(),
      SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue[400],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: "Preferences"),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: "Devices"),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "AI Assistant"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        currentIndex: currentIndex,
        onTap: (int index) {
          // Block navigation to Preferences (index 1) if optimal mode is on
          if (index == 1 && isOptimalModeOn) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Turn off Optimal Mode to access Preferences"),
                backgroundColor: Colors.orange[700],
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final bool isOptimalModeOn;
  final ValueChanged<bool> onOptimalModeChanged;
  final String currentLocation;
  final double temperature;
  final double brightness;
  final double humidity;
  final VoidCallback onLocationChange;

  const _HomeContent({
    required this.isOptimalModeOn,
    required this.onOptimalModeChanged,
    required this.currentLocation,
    required this.temperature,
    required this.brightness,
    required this.humidity,
    required this.onLocationChange,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile and Home title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Welcome Back, John",
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Assistant's Optimal Mode with Switch
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   "AI Assistant's",
                    //   style: GoogleFonts.inter(
                    //     fontSize: 14,
                    //     color: Colors.grey[800],
                    //   ),
                    // ),
                    const SizedBox(height: 4),
                    Text(
                      "Optimal Mode",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                value: isOptimalModeOn,
                activeColor: Colors.blue[400],
                onChanged: (value) {
                  onOptimalModeChanged(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          value
                              ? "Optimal Mode is on - Preferences locked"
                              : "Optimal Mode is off - Preferences unlocked"
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Environment card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ambiance",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Icon(
                      //   Icons.arrow_drop_down,
                      //   color: Colors.grey[800],
                      //   size: 30,
                      // ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDeviceColumn(Icons.thermostat_outlined, "Temperature", "${temperature.toStringAsFixed(0)}°C"),
                      _buildDeviceColumn(Icons.lightbulb_outline_rounded, "Brightness", "${brightness.toStringAsFixed(0)}%"),
                      _buildDeviceColumn(Icons.water_drop_outlined, "Humidity", "${humidity.toStringAsFixed(0)}%")
                    ],
                  ),
                ],
              ),
            ),

            // Calendar Widget
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Calendar",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: DateTime.now(),
                    calendarFormat: CalendarFormat.week,
                    headerVisible: false,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blue[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Weather Widget
            const SizedBox(height: 16),
            WeatherWidget(location: currentLocation),

            // Map Widget
            const SizedBox(height: 16),
            MapWidget(location: currentLocation),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLocationChange,
                icon: Icon(
                  currentLocation == "Garching" ? Icons.home : Icons.work,
                  color: Colors.white,
                ),
                label: Text(
                  currentLocation == "Garching" ? "Close to home" : "Back to work",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceColumn(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class WeatherWidget extends StatefulWidget {
  final String location;

  const WeatherWidget({super.key, required this.location});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final _weatherService = WeatherService('4d9653b43b1120f76945ef145222616b');
  Weather? _weather;

  // fetch weather based on coordinates
  _fetchWeather() async {
    try {
      // Garching Forschungszentrum: 48.2649, 11.6703
      // Studentenstadt U-Bahn: 48.1547, 11.5805

      final lat = widget.location == "Garching" ? 48.2649 : 48.1547;
      final lon = widget.location == "Garching" ? 11.6703 : 11.5805;

      // Fetch weather by coordinates instead of city name
      final response = await http.get(
          Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric')
      );

      if (response.statusCode == 200) {
        final weather = Weather.fromJson(jsonDecode(response.body));
        setState(() {
          _weather = weather;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  void didUpdateWidget(WeatherWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _fetchWeather();
    }
  }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/sunny.json';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
        return 'assets/partlycloudy.json';
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/windy.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
      case 'thunderstorm':
        return 'assets/storm.json';
      case 'clear':
        return 'assets/sunny.json';
      default:
        return 'assets/sunny.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Weather",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weather?.cityName ?? "Loading city..",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_weather?.temperature.round() ?? "--"}°C',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weather?.mainCondition ?? "",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                height: 120,
                child: Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MapWidget extends StatefulWidget {
  final String location;

  const MapWidget({Key? key, required this.location}) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  gm.GoogleMapController? _controller;
  final loc.Location _location = loc.Location();
  gm.LatLng? _currentPosition;
  final Set<gm.Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setMockLocation();
  }

  void _setMockLocation() {
    // Garching Forschungszentrum: 48.2649, 11.6703
    // Studentenstadt U-Bahn: 48.1547, 11.5805

    final coords = widget.location == "Garching"
        ? gm.LatLng(48.2649, 11.6703)
        : gm.LatLng(48.1547, 11.5805);

    setState(() {
      _currentPosition = coords;
      _isLoading = false;

      _markers.clear();
      _markers.add(
        gm.Marker(
          markerId: gm.MarkerId('current_location'),
          position: coords,
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueRed),
          infoWindow: gm.InfoWindow(
            title: widget.location == "Garching" ? "Work" : "Home",
          ),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _setMockLocation();
      _animateToCurrentPosition();
    }
  }

  Future<void> _animateToCurrentPosition() async {
    if (_controller != null && _currentPosition != null) {
      await _controller!.animateCamera(
        gm.CameraUpdate.newCameraPosition(
          gm.CameraPosition(
            target: _currentPosition!,
            zoom: 17.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _currentPosition == null
            ? const Center(
          child: Text('Unable to get location'),
        )
            : gm.GoogleMap(
          initialCameraPosition: gm.CameraPosition(
            target: _currentPosition!,
            zoom: 17.0,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          mapType: gm.MapType.normal,
          zoomControlsEnabled: false,
          onMapCreated: (gm.GoogleMapController controller) async {
            debugPrint('🗺️ Map created');
            _controller = controller;

            // If we already have the position, move camera now
            if (_currentPosition != null) {
              debugPrint('📹 Moving camera to current position');
              await controller.animateCamera(
                gm.CameraUpdate.newCameraPosition(
                  gm.CameraPosition(
                    target: _currentPosition!,
                    zoom: 17.0,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class DashboardPage extends StatefulWidget {
  final bool isOptimalModeOn;
  final double temperature;
  final double brightness;
  final double humidity;
  final Function(double, double, double) onValuesChanged;

  const DashboardPage({
    super.key,
    required this.isOptimalModeOn,
    required this.temperature,
    required this.brightness,
    required this.humidity,
    required this.onValuesChanged,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // double temperature = 22;
  // double lightingLevel = 50;
  // double humidityLevel = 50;

  // Instead of a single selected device, we use a map to track device states
  Map<String, bool> connectedDevices = {
    "LG OLED C4": false,
    "DAIKIN EVO Inverter": false,
    "Bose SoundLink Flex": false,
    "Bosch CTL636EB6": false,
  };

  @override
  Widget build(BuildContext context) {
    // If optimal mode is on, show a locked screen
    if (widget.isOptimalModeOn) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  "Preferences Locked",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Turn off Optimal Mode to customize your preferences",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal preferences page when optimal mode is off
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Preferences",
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Temperature Card
            _buildCard(
              title: "Temperature",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.temperature.toStringAsFixed(0)}°C",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: widget.temperature,
                    min: 16,
                    max: 30,
                    divisions: 14,
                    label: "${widget.temperature.toStringAsFixed(0)}°C",
                    onChanged: (value) {
                      widget.onValuesChanged(value, widget.brightness, widget.humidity);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lighting Ambiance Card
            _buildCard(
              title: "Lighting Ambiance",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.brightness.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: widget.brightness,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: "${widget.brightness.toStringAsFixed(0)}%",
                    onChanged: (value) {
                      widget.onValuesChanged(widget.temperature, value, widget.humidity);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildCard(
              title: "Humidity",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.humidity.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: widget.humidity,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: "${widget.humidity.toStringAsFixed(0)}%",
                    onChanged: (value) {
                      widget.onValuesChanged(widget.temperature, widget.brightness, value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Turn on Devices Card (dynamic list of switches)
            _buildCard(
              title: "Turn on Devices",
              child: Column(
                children: connectedDevices.keys.map((device) {
                  return SwitchListTile(
                    title: Text(device),
                    value: connectedDevices[device]!,
                    onChanged: (value) {
                      setState(() {
                        connectedDevices[device] = value;
                      });
                    },
                    activeColor: Colors.blue[400],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}


class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<String> devices = [
    "LG OLED C4",
    "DAIKIN EVO Inverter",
    "Bose SoundLink Flex",
    "Bosch CTL636EB6",
  ];

  final TextEditingController deviceController = TextEditingController();

  void _addDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Device"),
          content: TextField(
            controller: deviceController,
            decoration: const InputDecoration(
              hintText: "Enter device name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                deviceController.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newDevice = deviceController.text.trim();
                if (newDevice.isNotEmpty) {
                  setState(() {
                    devices.add(newDevice);
                  });
                }
                deviceController.clear();
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _removeDevice(int index) {
    setState(() {
      devices.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // REMOVED Scaffold wrapper here!
      child: Stack(  // Use Stack to overlay the FAB
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Connected Devices",
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // New special container for smart watch/band
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.watch,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Smart Watch / Band",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Connect to unlock more features",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Hard-coded placeholder for connection action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Connecting..."),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text("Connect"),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: devices.isEmpty
                      ? Center(
                    child: Text(
                      "No devices connected",
                      style: GoogleFonts.inter(fontSize: 18),
                    ),
                  )
                      : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: Key(devices[index]),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeDevice(index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.devices, size: 28),
                                  const SizedBox(width: 12),
                                  Text(
                                    devices[index],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeDevice(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // FAB positioned at bottom right
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _addDeviceDialog,
              backgroundColor: Colors.blue[400],
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class AIAgentPage extends StatefulWidget {
  const AIAgentPage({super.key});

  @override
  State<AIAgentPage> createState() => _AIAgentPageState();
}

class _AIAgentPageState extends State<AIAgentPage> {
  final RecorderStream _recorder = RecorderStream();
  double _micLevel = 0.0;
  bool _isListening = false;
  StreamSubscription<Uint8List>? _audioSubscription;

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  Future<void> initRecorder() async {
    var status = await Permission.microphone.request();

    // Check if permission was granted
    if (status != PermissionStatus.granted) {
      print("❌ Microphone permission denied!");
      return;
    }

    print("✅ Microphone permission granted");

    try {
      await _recorder.initialize();
      print("✅ Recorder initialized");

      _audioSubscription = _recorder.audioStream.listen(
            (data) {
          _processMicInput(data);
        },
        onError: (error) {
          print("❌ Audio stream error: $error");
        },
        onDone: () {
          print("⚠️ Audio stream done");
        },
      );
    } catch (e) {
      print("❌ Error initializing recorder: $e");
    }
  }

  void _processMicInput(Uint8List data) {
    if (!mounted) return;

    // Calculate RMS (Root Mean Square) for better amplitude detection
    double sum = 0;
    for (int i = 0; i < data.length; i++) {
      int sample = data[i] - 128; // Convert to signed
      sum += sample * sample;
    }
    double rms = math.sqrt(sum / data.length);

    // Scale the value (adjust multiplier for sensitivity)
    double scaledLevel = rms * 2.0; // Increase multiplier for more sensitivity

    // Debug output
    if (scaledLevel > 5) {  // Only print when there's actual sound
      print("🎤 Mic level: ${scaledLevel.toStringAsFixed(2)}");
    }

    setState(() {
      _micLevel = scaledLevel.clamp(0, 100); // Increased max range
    });
  }

  Future<void> _toggleListening() async {
    try {
      if (_isListening) {
        print("Stopping recording...");
        await _recorder.stop();

        // Reset mic level when stopping
        if (mounted) {
          setState(() {
            _isListening = false;
            _micLevel = 0.0; // Reset to 0
          });
        }
      } else {
        print("Starting recording...");
        await _recorder.start();

        if (mounted) {
          setState(() {
            _isListening = true;
          });
        }
      }
    } catch (e) {
      print("Error toggling recording: $e");
    }
  }

  @override
  void dispose() {
    print("🗑️ Disposing AIAgentPage");
    _audioSubscription?.cancel();
    _recorder.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // More dramatic size change
    double baseSize = 120;
    double size = baseSize + (_micLevel * 3); // Increased multiplier

    // Debug display
    String statusText = _isListening ? "Listening..." : "Tap to Start";
    String levelText = "Level: ${_micLevel.toStringAsFixed(1)}";

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "AI Assistant",
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Debug info
                  Text(
                    statusText,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      height: size,
                      width: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _isListening
                                ? Colors.blueAccent.shade200
                                : Colors.grey.shade600,
                            _isListening
                                ? Colors.blueAccent.shade700
                                : Colors.grey.shade800,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isListening
                                ? Colors.blueAccent.withOpacity(0.6)
                                : Colors.grey.withOpacity(0.3),
                            blurRadius: 30 + _micLevel,
                            spreadRadius: 5 + _micLevel / 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          color: Colors.white,
                          size: 40 + (_micLevel * 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60), // Increased spacing

                    // Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _toggleListening,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isListening
                                  ? Colors.red
                                  : Colors.blueAccent,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 40,
                              ),
                              minimumSize: const Size(200, 50), // Bigger button
                            ),
                            child: Text(
                              _isListening ? "Stop Listening" : "Start Listening",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Profile",
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage:
                    NetworkImage("https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png"),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "John Doe",
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "johndoe@example.com",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Personal Information",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _infoCard(
              title: "Address",
              value: "Musterstr. 123, Munich, Germany",
              icon: Icons.location_on,
            ),
            const SizedBox(height: 12),

            _infoCard(
              title: "Phone",
              value: "+49 176 12345678",
              icon: Icons.phone,
            ),
            const SizedBox(height: 12),

            _infoCard(
              title: "Date of Birth",
              value: "01 January 1999",
              icon: Icons.calendar_today,
            ),

            const SizedBox(height: 32),

            Text(
              "Settings",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _settingsTile(
              icon: Icons.notifications,
              title: "Notifications",
              onPressed: () {},
            ),
            _settingsTile(
              icon: Icons.lock,
              title: "Privacy",
              onPressed: () {},
            ),
            _settingsTile(
              icon: Icons.security,
              title: "Security",
              onPressed: () {},
            ),
            _settingsTile(
              icon: Icons.help_outline,
              title: "Help & Support",
              onPressed: () {},
            ),
            _settingsTile(
              icon: Icons.logout,
              title: "Logout",
              onPressed: () {},
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    Color color = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onPressed,
    );
  }
}