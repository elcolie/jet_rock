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

import 'const.dart';

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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver{
  final Member deviceName = Member.sarit;
  final TextEditingController _controller = TextEditingController();
  final websocketUrl = Uri.parse('ws://192.168.1.46:8000/ws/chat/zeroth/'); // local server.
  // final websocketUrl =  Uri.parse('wss://www.jetrock.pro/ws/chat/zeroth/'); // JetRock server.
  late var myChannel = WebSocketChannel.connect(
    websocketUrl
  );
  LocationData? locationData;
  Timer? timer;
  Map<Member, Marker> dictMarkers = {
    Member.sarit: Marker(
      point: LatLng(30, 40),
      width: 80,
      height: 80,
      builder: (context) => FlutterLogo(),
    ),
    Member.palm : Marker(
      point: LatLng(30, 40),
      width: 80,
      height: 80,
      builder: (context) => FlutterLogo(),
    ),
    Member.lenovo: Marker(
      point: LatLng(30, 40),
      width: 80,
      height: 80,
      builder: (context) => FlutterLogo(),
    ),
    Member.suwat : Marker(
      point: LatLng(30, 40),
      width: 80,
      height: 80,
      builder: (context) => FlutterLogo(),
    )
  };


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      //Resume the application.
      myChannel.sink.close();
      myChannel = WebSocketChannel.connect(
          websocketUrl
      );
    }
  }


  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    Timer.periodic(Duration(seconds: 10), (timer) {
      queryMyLocation();
      // Advertise my location to server.
      if (locationData != null) {
        Map<String, dynamic> dataDict = {
          'latitude': locationData!.latitude!,
          'longitude': locationData!.longitude!,
          'accuracy': locationData!.accuracy!,
          'name': MemberDict[deviceName],
        };
        myChannel.sink.add(json.encode(dataDict));
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

  Marker returnMarker(Map<dynamic, dynamic>payload, Icon icon){
    return Marker(
      point: LatLng(
        payload['latitude'],
        payload['longitude'],
      ),
      width: 80,
      height: 80,
      builder: (context) => icon
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);
    // Get the others coordinate
    var _streamBuilder = StreamBuilder(
        stream: myChannel.stream,
        builder: (context, snapshot) {
          String otherLocations = snapshot.hasData ? '${snapshot.data}' : '';
          if (otherLocations == '') {
            return Container();
          }
          print(otherLocations);
          Map _ = json.decode(otherLocations);
          Map payload = json.decode(_['message']);
          print(payload);
          if (payload['name'] == MemberDict[Member.sarit]) {
            dictMarkers[Member.sarit] = returnMarker(
                payload, Icon(Icons.access_alarm, color: Colors.blue,));;
          }
          if (payload['name'] == MemberDict[Member.suwat]) {
            dictMarkers[Member.suwat] = returnMarker(
                payload, Icon(Icons.water_drop, color: Colors.blueAccent,));
          }
          if (payload['name'] == MemberDict[Member.lenovo]) {
            dictMarkers[Member.lenovo] = returnMarker(
                payload, Icon(Icons.adb, color: Colors.blue,));
          }
          if (payload['name'] == MemberDict[Member.palm]) {
            dictMarkers[Member.palm] = returnMarker(
                payload, Icon(Icons.local_fire_department, color: Colors.blue,));
          }
          return Container();
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
    List<Marker> markers = [];
    dictMarkers.forEach((key, value) {
      print(key);
      print(value);
      if(key == deviceName){
        markers.add(Marker(
          point: LatLng(locationData!.latitude!,
              locationData!.longitude!),
          width: 80,
          height: 80,
          builder: (context) => Icon(
            Icons.add,
            color: Colors.red,
            size: 50,
          ),
        ));
      }else{
        markers.add(value);
      }
    });


    print("${locationData!.latitude!}, ${locationData!.longitude!}");
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _streamBuilder,
            Container(
              height: queryData.size.height,
              width: queryData.size.width,
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(
                    locationData!.latitude!,
                    locationData!.longitude!,
                  ),
                  zoom: 15,
                ),
                children: [
                  TileLayer(
                    // urlTemplate:
                    //     'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    urlTemplate: 'http://mt{s}.google.com/vt/lyrs=m@221097413,parking,traffic,lyrs=m&x={x}&y={y}&z={z}',
                    userAgentPackageName: 'com.example.app',
                    retinaMode: false,
                  ),
                  MarkerLayer(
                    markers: markers,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Websocket example function call
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      myChannel.sink.add(_controller.text);
    }
  }

  @override
  void dispose() {
    myChannel.sink.close();
    _controller.dispose();
    Wakelock.disable();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }
}
