import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:flutter_map/plugin_api.dart'; // Only import if required functionality is not exposed by default
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
  final Member deviceName = Member.lenovo;
  final websocketUrl = Uri.parse('ws://192.168.1.46:8000/ws/chat/zeroth/'); // local server.
  // final websocketUrl =  Uri.parse('wss://www.jetrock.pro/ws/chat/zeroth/'); // JetRock server.
  late var myChannel = WebSocketChannel.connect(
    websocketUrl
  );  // Without late prefix will be unable to use single websocketUrl
  LocationData? locationData;
  Timer? timer;
  MapController mapController = MapController();
  LatLng centerScreen = LatLng(0, 0);


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
          'name': memberDict[deviceName]!.name,
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
  SpeedDialChild getSpeedDialChild(MemberProfile profile){
    return SpeedDialChild(
      child: profile.icon,
      label: profile.name,
      backgroundColor: Colors.amberAccent,
      onTap: () {
        double zoom = 15.0;
        mapController.move(profile.lastKnownPosition, zoom);
      },
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
          Map _ = json.decode(otherLocations);
          Map payload = json.decode(_['message']);
          if (payload['name'] == memberDict[Member.sarit]!.name) {
            memberDict[Member.sarit]!.marker = returnMarker(
                payload, memberDict[Member.sarit]!.icon);
            memberDict[Member.sarit]!.lastKnownPosition = LatLng(payload['latitude'],
                payload['longitude']);
          }
          if (payload['name'] == memberDict[Member.suwat]!.name) {
            memberDict[Member.suwat]!.marker = returnMarker(
                payload, memberDict[Member.suwat]!.icon);
            memberDict[Member.suwat]!.lastKnownPosition = LatLng(payload['latitude'],
                payload['longitude']);
          }
          if (payload['name'] == memberDict[Member.lenovo]!.name) {
            memberDict[Member.lenovo]!.marker = returnMarker(
                payload, memberDict[Member.lenovo]!.icon);
            memberDict[Member.lenovo]!.lastKnownPosition = LatLng(payload['latitude'],
                payload['longitude']);
          }
          if (payload['name'] == memberDict[Member.palm]!.name) {
            memberDict[Member.palm]!.marker = returnMarker(
                payload, memberDict[Member.palm]!.icon);
            memberDict[Member.palm]!.lastKnownPosition = LatLng(payload['latitude'],
                payload['longitude']);
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
    memberDict.forEach((key, value) {
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
        markers.add(returnMarker({
          "latitude": value.lastKnownPosition.latitude,
          "longitude": value.lastKnownPosition.longitude,
        }, value.icon));
      }
    });
    // print("${locationData!.latitude!}, ${locationData!.longitude!}");
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
                mapController: mapController,
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
      floatingActionButton: SpeedDial(
        icon: Icons.remove_red_eye_rounded,
        backgroundColor: Colors.amber,
        children: [
          getSpeedDialChild(memberDict[Member.sarit]!),
          getSpeedDialChild(memberDict[Member.suwat]!),
          getSpeedDialChild(memberDict[Member.lenovo]!),
          getSpeedDialChild(memberDict[Member.palm]!),
        ],
      ),
    );
  }

  @override
  void dispose() {
    myChannel.sink.close();
    Wakelock.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
