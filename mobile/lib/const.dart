import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum Member {
  sarit,
  suwat,
  palm,
  lenovo,
}

Map<Member, MemberProfile> memberDict = {
  Member.sarit: MemberProfile(
      Member.sarit,
      "sarit",
      Icon(Icons.access_alarm, color: Colors.black),
      LatLng(0, 0)),
  Member.suwat: MemberProfile(
      Member.suwat,
      "suwat",
      Icon(Icons.directions_walk, color: Colors.black),
      LatLng(0, 0)),
  Member.lenovo: MemberProfile(
      Member.lenovo,
      "lenovo",
      Icon(Icons.adb, color: Colors.black),
      LatLng(0, 0)),
  Member.palm: MemberProfile(
      Member.palm,
      "palm",
      Icon(Icons.local_fire_department, color: Colors.black),
      LatLng(0, 0)),
};

class MemberProfile {
  Member member;
  String name;
  Icon icon;
  LatLng lastKnownPosition;
  Marker? marker;

  MemberProfile(
      this.member,
      this.name,
      this.icon,
      this.lastKnownPosition,
      {this.marker});
}
