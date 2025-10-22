import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// --- CONFIGURATION ---.
const String WEATHER_API_KEY = "63ee0b07d21644fe9de63602250410";
const String MAP_API_KEY = "b14e84bc121c95643e4621bdbf557ae9";
// NEWS_API_KEY has been removed

void main() {
  runApp(const WeatherApp());
}

// --- UTILITY FUNCTIONS ---
IconData getWeatherIcon(String condition) {
  final lowerCaseCondition = condition.toLowerCase();
  if (lowerCaseCondition.contains('sunny') || lowerCaseCondition.contains('clear')) return Icons.wb_sunny_rounded;
  if (lowerCaseCondition.contains('cloudy') || lowerCaseCondition.contains('overcast')) return Icons.cloud_rounded;
  if (lowerCaseCondition.contains('mist') || lowerCaseCondition.contains('fog')) return Icons.foggy;
  if (lowerCaseCondition.contains('rain') || lowerCaseCondition.contains('drizzle')) return Icons.umbrella_rounded;
  if (lowerCaseCondition.contains('thunder')) return Icons.thunderstorm_rounded;
  if (lowerCaseCondition.contains('snow') || lowerCaseCondition.contains('sleet') || lowerCaseCondition.contains('blizzard')) return Icons.ac_unit_rounded;
  return Icons.wb_cloudy_rounded;
}

String getUvIndexDescription(double uv) {
  if (uv <= 2) return 'Low';
  if (uv <= 5) return 'Moderate';
  if (uv <= 7) return 'High';
  if (uv <= 10) return 'Very High';
  return 'Extreme';
}

Color getAirQualityColor(int index) {
  switch (index) {
    case 1: return Colors.green;
    case 2: return Colors.yellow;
    case 3: return Colors.orange;
    case 4: return Colors.red;
    case 5: return Colors.purple;
    case 6: return Colors.brown;
    default: return Colors.grey;
  }
}

String getAirQualityDescription(int usEpaIndex) {
  switch (usEpaIndex) {
    case 1: return 'Good';
    case 2: return 'Moderate';
    case 3: return 'Unhealthy for sensitive groups';
    case 4: return 'Unhealthy';
    case 5: return 'Very Unhealthy';
    case 6: return 'Hazardous';
    default: return 'Unknown';
  }
}

// --- NEW DYNAMIC BACKGROUND FUNCTION ---
BoxDecoration getWeatherBackground(String condition, int isDay) {
  final lowerCaseCondition = condition.toLowerCase();
  List<Color> colors;

  if (isDay == 0) {
    // Night
    colors = [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)];
  } else if (lowerCaseCondition.contains('sunny') || lowerCaseCondition.contains('clear')) {
    // Sunny
    colors = [const Color(0xFFff8008), const Color(0xFFffc837)];
  } else if (lowerCaseCondition.contains('rain') || lowerCaseCondition.contains('drizzle') || lowerCaseCondition.contains('thunder')) {
    // Rainy
    colors = [const Color(0xFF4c669f), const Color(0xFF3b5998), const Color(0xFF192f6a)];
  } else if (lowerCaseCondition.contains('cloudy') || lowerCaseCondition.contains('overcast') || lowerCaseCondition.contains('mist') || lowerCaseCondition.contains('fog')) {
    // Cloudy
    colors = [const Color(0xFF606c88), const Color(0xFF3f4c6b)];
  } else {
    // Default Day
    colors = [const Color(0xFF2980B9), const Color(0xFF6DD5FA)];
  }

  return BoxDecoration(
    gradient: LinearGradient(
      colors: colors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}


// --- DATA MODELS (Unchanged) ---
class WeatherData {
  final Location location; final CurrentWeather current; final Forecast forecast;
  WeatherData({required this.location, required this.current, required this.forecast});
  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        location: Location.fromJson(json['location']), current: CurrentWeather.fromJson(json['current']),
        forecast: Forecast.fromJson(json['forecast']),
      );
}
class Location {
  final String name; final String country; final double lat; final double lon;
  Location({required this.name, required this.country, required this.lat, required this.lon});
  factory Location.fromJson(Map<String, dynamic> json) => Location(
        name: json['name'], country: json['country'],
        lat: json['lat'].toDouble(), lon: json['lon'].toDouble(),
      );
}
class CurrentWeather {
  final double temp; final String description; final String icon;
  final int isDay; final double windKph; final String windDir;
  final double precipMm; final int humidity; final double feelsLike;
  final double uv; final AirQuality airQuality;
  final double visKm; final double pressureMb; 
  CurrentWeather({
    required this.temp, required this.description, required this.icon,
    required this.isDay, required this.windKph, required this.windDir,
    required this.precipMm, required this.humidity, required this.feelsLike,
    required this.uv, required this.airQuality, required this.visKm, required this.pressureMb,
  });
  factory CurrentWeather.fromJson(Map<String, dynamic> json) => CurrentWeather(
        temp: json['temp_c'].toDouble(), description: json['condition']['text'],
        icon: 'https:${json['condition']['icon']}', isDay: json['is_day'],
        windKph: json['wind_kph'].toDouble(), windDir: json['wind_dir'],
        precipMm: json['precip_mm'].toDouble(), humidity: json['humidity'],
        feelsLike: json['feelslike_c'].toDouble(), uv: json['uv'].toDouble(),
        airQuality: AirQuality.fromJson(json['air_quality']),
        visKm: json['vis_km'].toDouble(), pressureMb: json['pressure_mb'].toDouble(),
      );
}
class AirQuality {
  final int usEpaIndex;
  AirQuality({required this.usEpaIndex});
  factory AirQuality.fromJson(Map<String, dynamic> json) => AirQuality(usEpaIndex: json['us-epa-index']);
}
class Forecast {
  final List<DailyForecast> daily;
  Forecast({required this.daily});
  factory Forecast.fromJson(Map<String, dynamic> json) => Forecast(daily: (json['forecastday'] as List).map((day) => DailyForecast.fromJson(day)).toList());
}
class DailyForecast {
  final DateTime date; final double maxTemp; final double minTemp;
  final String description; final String icon; final Astro astro;
  final List<HourlyForecast> hourly;
  DailyForecast({
    required this.date, required this.maxTemp, required this.minTemp,
    required this.description, required this.icon, required this.astro, required this.hourly,
  });
  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        date: DateTime.parse(json['date']), maxTemp: json['day']['maxtemp_c'].toDouble(),
        minTemp: json['day']['mintemp_c'].toDouble(), description: json['day']['condition']['text'],
        icon: 'https:${json['day']['condition']['icon']}', astro: Astro.fromJson(json['astro']),
        hourly: (json['hour'] as List).map((hour) => HourlyForecast.fromJson(hour)).toList(),
      );
}
class Astro {
  final String sunrise; final String sunset;
  Astro({required this.sunrise, required this.sunset});
  factory Astro.fromJson(Map<String, dynamic> json) => Astro(sunrise: json['sunrise'], sunset: json['sunset']);
}
class HourlyForecast {
  final DateTime time; final double temp; final String description;
  HourlyForecast({required this.time, required this.temp, required this.description});
  factory HourlyForecast.fromJson(Map<String, dynamic> json) => HourlyForecast(
        time: DateTime.parse(json['time']), temp: json['temp_c'].toDouble(),
        description: json['condition']['text'],
      );
}
// NewsArticle model has been removed.

// --- API SERVICES ---
class WeatherService {
  final String apiKey;
  WeatherService(this.apiKey);
  Future<WeatherData> getWeatherData(String query) async {
    final url = 'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$query&days=7&aqi=yes&alerts=no';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return WeatherData.fromJson(json.decode(response.body));
    throw Exception('Failed to load weather data: ${response.body}');
  }
}
// NewsService has been removed.

// --- MAIN APP WIDGET AND SHELL ---
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SkyWise', debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue, fontFamily: 'Inter', brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white), bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        home: const MainAppShell(),
      );
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});
  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  String _selectedLocation = 'Current Location';
  List<String> _savedLocations = ['Current Location'];

  void _onLocationSelected(String location) => setState(() {
        _selectedLocation = location;
        _selectedIndex = 0;
      });
  
  void _addLocation(String location) {
    if (!_savedLocations.contains(location)) setState(() => _savedLocations.add(location));
  }

  void _removeLocation(String location) {
    if (location != 'Current Location') setState(() {
          _savedLocations.remove(location);
          if (_selectedLocation == location) _selectedLocation = 'Current Location';
        });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(key: ValueKey('home_$_selectedLocation'), locationQuery: _selectedLocation),
      WeatherScreen(key: ValueKey('weather_$_selectedLocation'), locationQuery: _selectedLocation),
      DetailsScreen(key: ValueKey('details_$_selectedLocation'), locationQuery: _selectedLocation),
      LocationsScreen(
        savedLocations: _savedLocations, selectedLocation: _selectedLocation,
        onLocationSelected: _onLocationSelected, onAddLocation: _addLocation,
        onRemoveLocation: _removeLocation,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.wb_sunny_outlined), label: 'Weather'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Forecast'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Locations'),
        ],
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// --- HOME SCREEN (With Dynamic Background) ---
class HomeScreen extends StatefulWidget {
  final String locationQuery;
  const HomeScreen({super.key, required this.locationQuery});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService(WEATHER_API_KEY);
  WeatherData? _weatherData; String? _errorMessage; bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      String query = widget.locationQuery;
      if (query == 'Current Location') {
        Position position = await _determinePosition();
        query = '${position.latitude},${position.longitude}';
      }
      final data = await _weatherService.getWeatherData(query);
      setState(() { _weatherData = data; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled; LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied.');
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_errorMessage != null) return Scaffold(body: Center(child: Text('Error: $_errorMessage')));
    if (_weatherData == null) return const Scaffold(body: Center(child: Text('No data.')));
    
    final current = _weatherData!.current;
    final daily = _weatherData!.forecast.daily[0];

    return Container(
      decoration: getWeatherBackground(current.description, current.isDay),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Important for background to show
        appBar: AppBar(
          title: Text(_weatherData!.location.name), centerTitle: true,
          backgroundColor: Colors.transparent, elevation: 0,
          // News button has been removed from actions
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Icon(getWeatherIcon(current.description), size: 120, color: Colors.white,
                shadows: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
              const SizedBox(height: 16),
              Text('${current.temp.round()}°', style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w200,
                shadows: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))])),
              Text(current.description, style: const TextStyle(fontSize: 24, color: Colors.white70)),
              Text('Day ${daily.maxTemp.round()}° • Night ${daily.minTemp.round()}°', style: const TextStyle(fontSize: 18, color: Colors.white70)),
              const Spacer(flex: 3),
              Text('Feels like ${current.feelsLike.round()}°', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WEATHER SCREEN ---
class WeatherScreen extends StatefulWidget {
  final String locationQuery;
  const WeatherScreen({super.key, required this.locationQuery});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService(WEATHER_API_KEY);
  WeatherData? _weatherData; String? _errorMessage; bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      String query = widget.locationQuery;
      if (query == 'Current Location') {
        Position position = await _determinePosition();
        query = '${position.latitude},${position.longitude}';
      }
      final data = await _weatherService.getWeatherData(query);
      setState(() { _weatherData = data; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }
  
  Future<Position> _determinePosition() async {
    bool serviceEnabled; LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied.');
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text('Error: $_errorMessage'));
    if (_weatherData == null) return const Center(child: Text('No data.'));
    
    final current = _weatherData!.current;
    final daily = _weatherData!.forecast.daily[0];
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E), title: Text(_weatherData!.location.name), centerTitle: true,
          bottom: const TabBar(tabs: [Tab(text: 'Today'), Tab(text: 'This Week')]),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${current.temp.round()}°', style: Theme.of(context).textTheme.displayLarge),
                Text('Feels like ${current.feelsLike.round()}° • Day ${daily.maxTemp.round()}° • Night ${daily.minTemp.round()}°',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[400])),
                Text(current.description, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                _buildHourlyForecastCard(_weatherData!.forecast.daily[0].hourly),
                const SizedBox(height: 24),
                _buildMapPreviewCard(), 
              ],
            ),
            _buildDailyForecastList(_weatherData!.forecast.daily),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecastCard(List<HourlyForecast> hourly) => Card(
        color: const Color(0xFF2E2E2E),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hourly Forecast', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, itemCount: hourly.length,
                  itemBuilder: (context, index) {
                    final h = hourly[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Text(DateFormat('ha').format(h.time)),
                          Icon(getWeatherIcon(h.description), size: 32),
                          Text('${h.temp.round()}°'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDailyForecastList(List<DailyForecast> daily) => ListView.builder(
      itemCount: daily.length,
      itemBuilder: (context, index) {
        final d = daily[index];
        return ListTile(
          leading: Icon(getWeatherIcon(d.description)),
          title: Text(DateFormat('EEEE').format(d.date)),
          subtitle: Text(d.description),
          trailing: Text('${d.maxTemp.round()}° / ${d.minTemp.round()}°'),
        );
      },
    );

  Widget _buildMapPreviewCard() {
    final location = _weatherData!.location;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => 
        FullScreenMapPage(center: LatLng(location.lat, location.lon)))),
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF2E2E2E),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(location.lat, location.lon),
                  initialZoom: 7.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), 
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    retinaMode: true,
                  ),
                  TileLayer(
                    urlTemplate: 'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=$MAP_API_KEY',
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ),
             Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Weather Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   Text('Tap to view more', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DETAILS SCREEN ---
class DetailsScreen extends StatefulWidget {
  final String locationQuery;
  const DetailsScreen({super.key, required this.locationQuery});
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final WeatherService _weatherService = WeatherService(WEATHER_API_KEY);
  WeatherData? _weatherData; String? _errorMessage; bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      String query = widget.locationQuery;
      if (query == 'Current Location') {
        Position position = await _determinePosition();
        query = '${position.latitude},${position.longitude}';
      }
      final data = await _weatherService.getWeatherData(query);
      setState(() { _weatherData = data; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled; LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied.');
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_weatherData?.location.name ?? 'Details'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text('Error: $_errorMessage'));
    if (_weatherData == null) return const Center(child: Text('No data.'));
    
    final current = _weatherData!.current;
    final astro = _weatherData!.forecast.daily[0].astro;

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0, 
      children: [
        DetailCard(
          title: 'Precipitation',
          value: '${current.precipMm} in',
          subtitle: 'Total rain for the day',
          icon: Icons.umbrella_rounded,
        ),
        DetailCard(
          title: 'Wind',
          value: '${current.windKph.round()} km/h',
          subtitle: 'From ${current.windDir}',
          icon: Icons.air,
        ),
        SunriseSunsetCard(sunrise: astro.sunrise, sunset: astro.sunset),
        UvIndexCard(uv: current.uv),
        AirQualityCard(aqi: current.airQuality.usEpaIndex),
        DetailCard(
          title: 'Visibility',
          value: '${current.visKm.round()} km',
          icon: Icons.visibility,
        ),
        DetailCard(
          title: 'Humidity',
          value: '${current.humidity}%',
          subtitle: 'Dew point is 24°', 
          icon: Icons.opacity,
        ),
        PressureCard(pressureMb: current.pressureMb),
      ],
    );
  }
}

// --- LOCATIONS SCREEN ---
class LocationsScreen extends StatelessWidget {
  final List<String> savedLocations; final String selectedLocation;
  final Function(String) onLocationSelected; final Function(String) onAddLocation;
  final Function(String) onRemoveLocation;

  const LocationsScreen({
    super.key, required this.savedLocations, required this.selectedLocation,
    required this.onLocationSelected, required this.onAddLocation, required this.onRemoveLocation,
  });

  Future<void> _showAddLocationDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2E2E2E), title: const Text('Add Location'),
            content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter city name"), autofocus: true),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
              TextButton(
                child: const Text('Add'),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    onAddLocation(controller.text);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Locations'), backgroundColor: const Color(0xFF1E1E1E)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Follow weather anywhere', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('Add the places that matter most to you.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...savedLocations.map((location) => Card(
                  color: const Color(0xFF2E2E2E), margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(location),
                    leading: Icon(location == 'Current Location' ? Icons.my_location : Icons.location_city),
                    trailing: selectedLocation == location
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : (location != 'Current Location'
                            ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => onRemoveLocation(location))
                            : null),
                    onTap: () => onLocationSelected(location),
                  ),
                )).toList(),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Add another location'),
              leading: const Icon(Icons.add_location_alt_outlined),
              trailing: const Icon(Icons.add),
              onTap: () => _showAddLocationDialog(context),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      );
}

// --- FULL SCREEN MAP PAGE (With Zoom Controls) ---
class FullScreenMapPage extends StatefulWidget {
  final LatLng center;
  const FullScreenMapPage({super.key, required this.center});
  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  late final MapController _mapController;
  String _selectedLayer = 'precipitation_new';
  
  final Map<String, IconData> _layerOptions = {
    'precipitation_new': Icons.umbrella_rounded,
    'clouds_new': Icons.cloud_rounded,
    'wind_new': Icons.air,
    'temp_new': Icons.thermostat,
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Map'), backgroundColor: Colors.transparent, elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.center, initialZoom: 9.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                retinaMode: true,
              ),
              if (MAP_API_KEY != "YOUR_OPENWEATHERMAP_API_KEY_HERE")
                TileLayer(
                  urlTemplate: 'https://tile.openweathermap.org/map/$_selectedLayer/{z}/{x}/{y}.png?appid=$MAP_API_KEY',
                  backgroundColor: Colors.transparent,
                ),
            ],
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _layerOptions.entries.map((entry) {
                bool isSelected = _selectedLayer == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLayer = entry.key),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Icon(entry.value, color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  onPressed: () {
                     _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- NEW STYLED DETAIL CARD WIDGETS ---
class DetailCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  const DetailCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.grey[400])),
              ],
            ),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyle(color: Colors.grey[400])),
            ]
          ],
        ),
      ),
    );
  }
}

class SunriseSunsetCard extends StatelessWidget {
  final String sunrise;
  final String sunset;

  const SunriseSunsetCard({super.key, required this.sunrise, required this.sunset});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sunrise & sunset', style: TextStyle(color: Colors.grey[400])),
            const Spacer(),
            Row(children: [
              const Icon(Icons.wb_sunny_outlined),
              const SizedBox(width: 8),
              Text(sunrise, style: Theme.of(context).textTheme.titleLarge)
            ]),
            const Spacer(),
            Row(children: [
              const Icon(Icons.nights_stay_outlined),
              const SizedBox(width: 8),
              Text(sunset, style: Theme.of(context).textTheme.titleLarge)
            ]),
          ],
        ),
      ),
    );
  }
}

class UvIndexCard extends StatelessWidget {
  final double uv;
  const UvIndexCard({super.key, required this.uv});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.wb_sunny, size: 16),
              const SizedBox(width: 8),
              Text('UV index', style: TextStyle(color: Colors.grey[400])),
            ]),
            const Spacer(),
            Text(uv.round().toString(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(getUvIndexDescription(uv), style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}

class AirQualityCard extends StatelessWidget {
  final int aqi;
  const AirQualityCard({super.key, required this.aqi});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.masks_outlined, size: 16),
              const SizedBox(width: 8),
              Text('Air quality', style: TextStyle(color: Colors.grey[400])),
            ]),
            const Spacer(),
            Text(getAirQualityDescription(aqi), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.yellow, Colors.red],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PressureCard extends StatelessWidget {
  final double pressureMb;
  const PressureCard({super.key, required this.pressureMb});

  @override
  Widget build(BuildContext context) {
    // Convert millibars to inches of mercury for display
    final pressureInHg = pressureMb * 0.02953;
    return Card(
      color: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.speed, size: 16),
              const SizedBox(width: 8),
              const Text('Pressure'),
            ]),
            Expanded(
              child: Center(
                child: Text(
                  pressureInHg.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
             const Text('inHg'),
          ],
        ),
      ),
    );
  }
}

