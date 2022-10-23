import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:flutter_map/plugin_api.dart'; // Only import if required functionality is not exposed by default
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wakelock/wakelock.dart';

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
      Uri.parse('ws://localhost:8000') // local server.
      );
  LocationData? locationData;
  Timer? timer;
  int counter = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 3), (timer) {
      queryMyLocation();
      if (locationData != null) {
        Map<String, dynamic> dataDict = {
          'latitude': locationData!.latitude!,
          'longitude': locationData!.longitude!,
          'accuracy': locationData!.accuracy!,
          'name': 'sarit',
        };
        _channel.sink.add(json.encode(dataDict));
      }
    });
    Wakelock.enable();
  }

  void queryMyLocation() async {
    final Location location = new Location();
    LocationData _locationData = await location.getLocation();
    setState(() {
      locationData = _locationData;
    });
  }

  @override
  Widget build(BuildContext context) {
    var _streamBuilder = StreamBuilder(
      stream: _channel.stream,
      builder: (context, snapshot) {
        String otherLocations = snapshot.hasData ? '${snapshot.data}' : '';
        return Text(otherLocations);
      },
    );

    if (locationData == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text("Locating..."),
          ),
        ),
      );
    }
    print("${locationData!.latitude!}, ${locationData!.longitude!}");
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                child: TextFormField(
                  controller: _controller,
                  decoration:
                      const InputDecoration(labelText: 'Send a message'),
                ),
              ),
              const SizedBox(height: 24),
              _streamBuilder,
              // FlutterMap(
              //   options: MapOptions(
              //     center: LatLng(
              //         locationData!.latitude!, locationData!.longitude!),
              //     // center: LatLng(51.509364, -0.128928),
              //     zoom: 15,
              //   ),
              //   nonRotatedChildren: [
              //     AttributionWidget.defaultWidget(
              //       source: 'OpenStreetMap contributors',
              //       onSourceTapped: null,
              //     ),
              //   ],
              //   children: [
              //     TileLayer(
              //       urlTemplate:
              //       'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              //       userAgentPackageName: 'com.example.app',
              //     ),
              //     MarkerLayer(
              //       markers: [
              //         // This phone position
              //         Marker(
              //           point: LatLng(locationData!.latitude!,
              //               locationData!.longitude!),
              //           width: 80,
              //           height: 80,
              //           builder: (context) =>
              //               Icon(Icons.add, color: Colors.red),
              //         ),
              //         // otherMarker
              //       ],
              //     )
              //   ],
              // ),
            ],
          ),
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
    Wakelock.disable();
    super.dispose();
  }
}
