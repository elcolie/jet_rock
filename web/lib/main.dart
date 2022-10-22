import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:flutter_map/plugin_api.dart'; // Only import if required functionality is not exposed by default
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final _channel = WebSocketChannel.connect(
      // Uri.parse('wss://echo.websocket.events')
      Uri.parse('ws://localhost:8000') // JetRock local server.
      );
  LocationData? locationData;

  @override
  void initState() {
    super.initState();
    junk();
  }

  void junk() async {
    final Location location = new Location();
    LocationData _locationData = await location.getLocation();
    print(_locationData.latitude);
    print(_locationData.longitude);
    print(_locationData.accuracy);
    print(_locationData.altitude);
    print(_locationData.speed);
    print(_locationData.speedAccuracy);
    print(_locationData.heading);
    print(_locationData.time);
    print(_locationData.isMock);
    print(_locationData.verticalAccuracy);
    print(_locationData.headingAccuracy);
    print(_locationData.elapsedRealtimeNanos);
    print(_locationData.elapsedRealtimeUncertaintyNanos);
    print(_locationData.satelliteNumber);
    print(_locationData.provider);

    setState(() {
      locationData = _locationData;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (locationData == null) {
      return Scaffold(
        body: Center(
          child: Text("Locating..."),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Send a message'),
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder(
              stream: _channel.stream,
              builder: (context, snapshot) {
                return Text(snapshot.hasData ? '${snapshot.data}' : '');
              },
            ),
            Container(
              width: 800,
              height: 400,
              child: FlutterMap(
                options: MapOptions(
                  center:
                      LatLng(locationData!.latitude!, locationData!.longitude!),
                  // center: LatLng(51.509364, -0.128928),
                  zoom: 9.2,
                ),
                nonRotatedChildren: [
                  AttributionWidget.defaultWidget(
                    source: 'OpenStreetMap contributors',
                    onSourceTapped: null,
                  ),
                ],
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                            locationData!.latitude!, locationData!.longitude!),
                        width: 80,
                        height: 80,
                        builder: (context) =>
                            Icon(Icons.add, color: Colors.red),
                      ),
                      Marker(
                        point: LatLng(
                            locationData!.latitude!, locationData!.longitude!),
                        width: 80,
                        height: 80,
                        builder: (context) =>
                            Icon(Icons.circle_outlined, color: Colors.red),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: const Icon(Icons.send),
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(_controller.text);
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }
}
