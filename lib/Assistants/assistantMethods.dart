import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mlvtp/Assistants/requestAssistant.dart';
import 'package:mlvtp/DataHandler/appData.dart';
import 'package:mlvtp/Models/allUsers.dart';
import 'package:mlvtp/Models/directionDetails.dart';
import "package:mlvtp/configMaps.dart";
import "package:mlvtp/Models/address.dart";
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
class AssistantMethods{
  static Future<String> searchCoordinateAddress(Position position, BuildContext context) async{
    String placeAddress="";
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks!=null && placemarks.length>0){
      var placemark=placemarks[0];
      placeAddress=placemark.street!+", "+placemark.locality!;
      Address userPickupAddress=Address(  placeName: placeAddress,  latitude: position.latitude, longitude: position.longitude);
      Provider.of<AppData>(context,listen: false).updatePickUpLocationAddress(userPickupAddress);

    }
    return placeAddress;
  }
  static Future<DirectionDetails?> obtainPlaceDirectionsDetails(LatLng initialPosition, LatLng finalPosition)async{
    String url="https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=${mapKey}";
    var res=await RequestAssistant().getRequest(url);
    if (res=={}){
      return null;
    }
    else{
      DirectionDetails directionDetails=DirectionDetails(
          distanceText: res["routes"][0]["legs"][0]['distance']["text"],
          durationText: res["routes"][0]["legs"][0]["duration"]["text"],
          distanceValue: res["routes"][0]["legs"][0]["distance"]["value"],
          durationValue: res["routes"][0]["legs"][0]["duration"]["value"],
          encodedPoints: res["routes"][0]["overview_polyline"]["points"]);
      return directionDetails;
    }
  }
  static double calculateFares(DirectionDetails directionDetails){
    double timeTraveledFare=(directionDetails.durationValue/60)*0.77;
    double distanceTraveledFare=(directionDetails.distanceValue/1000)*0.77;
    double totalFareAmount= timeTraveledFare + distanceTraveledFare;
    return ((totalFareAmount*100).roundToDouble())/100;
  }
  static void getCurrentOnlineUserInfoAsync()async{
    user=FirebaseAuth.instance.currentUser;
    String userId=user!.uid;
    var snapshot=await FirebaseFirestore.instance.collection("users").doc(userId).get();
    if(snapshot.data()!=null){
      userCurrentInfo= Users.fromSnapshot(snapshot);
    }
  }

  }