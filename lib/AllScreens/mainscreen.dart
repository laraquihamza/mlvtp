import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mlvtp/AllScreens/loginScreen.dart';
import 'package:mlvtp/AllScreens/searchScreen.dart';
import 'package:mlvtp/AllWidgets/Divider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mlvtp/AllWidgets/progressDialog.dart';
import 'package:mlvtp/Assistants/assistantMethods.dart';
import 'package:mlvtp/DataHandler/appData.dart';
import 'package:mlvtp/Models/directionDetails.dart';
import 'package:mlvtp/configMaps.dart';
import 'package:provider/provider.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen="mainScreen";

  @override
  _MainScreenState createState() => _MainScreenState();
}



class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap=Completer();
  late GoogleMapController newGoogleMapController;


  static final CameraPosition _kGooglePlex=CameraPosition(
      target: LatLng(37.42796133580664,6122.085749655962),
    zoom: 14.4746
  );
  GlobalKey<ScaffoldState> scaffoldKey=GlobalKey<ScaffoldState>();
   DirectionDetails? tripDirectionDetails;
  List<LatLng> pLineCoordinates=[];
  Set<Polyline> polylineSet={};

  late Position currentPosition;
  var geoLocator=Geolocator();
  double bottomPaddingOfMap=0;
  Set<Marker> markerSet={};
  Set<Circle> circleSet={};
  double rideDetailsContainerHeight=0;
  double searchContainerHeight=300;
  double requestRideContainerHeight=0;
  bool drawerOpen=true;
  String ride_request_id="";
  @override
  void initState(){
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfoAsync();
  }
  void saveRideRequest(){
    var pickUp=Provider.of<AppData>(context,listen:false).pickUpLocation;
    var dropOff=Provider.of<AppData>(context,listen:false).dropOffLocation;
    Map pickUpLocMap={
      "latitude":pickUp!.latitude,
      "longitude":pickUp.longitude
    };
    Map dropOffLocMap={
      "latitude":dropOff!.latitude,
      "longitude":dropOff.longitude
    };
    Map<String,dynamic> rideInfoMap={
      "driver_id":"waiting",
      "payment_method":"cash",
      "pickup":pickUpLocMap,
      "dropoff":dropOffLocMap,
      "rider_name":userCurrentInfo!.name,
      "rider_phone":userCurrentInfo!.phone,
      "pickup_address":pickUp.placeName,
      "dropoff_address":dropOff.placeName,
      "created_at":DateTime.now()
    };
    var doc=FirebaseFirestore.instance.collection("ride_request").doc();
    ride_request_id=doc.id;
    doc.set(
      rideInfoMap);

  }
  void cancelRideRequest(){
    FirebaseFirestore.instance.collection("ride_request").doc(ride_request_id).delete();resetApp();
  }
  void displayRequestRideContainer(){
    setState(() {
      requestRideContainerHeight=250;
      rideDetailsContainerHeight=0;
      bottomPaddingOfMap=230;
      drawerOpen=true;
    });
    saveRideRequest();
  }
  resetApp(){
    setState(() {
      drawerOpen=true;
      searchContainerHeight=300;
      requestRideContainerHeight=0;
      rideDetailsContainerHeight=0;
      bottomPaddingOfMap=230.0;
      polylineSet.clear();
      circleSet.clear();
      markerSet.clear();
      pLineCoordinates.clear();
    });
    locatePosition();
  }
  void displayRideDetailsContainer()async{
    await getPlaceDirection();
    setState(() {
      searchContainerHeight=0;
      rideDetailsContainerHeight=240;
      bottomPaddingOfMap=230.0;
      drawerOpen=false;
    });
  }
  void locatePosition()async{
    late LocationPermission permission;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }


    Position position=await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition=position;
    LatLng latlngPosition= LatLng(position.latitude, position.longitude);
    CameraPosition  cameraPosition= CameraPosition(target: latlngPosition,zoom: 14);
    newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    String address=await AssistantMethods.searchCoordinateAddress(position, context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    /*  appBar: AppBar(
        title: Text("Main Screen"),
      ),*/
      key: scaffoldKey,
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.white
                    ),
                  child: Row(
                    children: [
                      Image.asset("images/user_icon.png", height: 65.0,width: 65.0,),
                      SizedBox(width: 16.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Nom du profil",
                            style:TextStyle(fontSize: 16.0,fontFamily: "Brand-Bold") ,),
                          SizedBox(
                            height: 6.0,
                          ),
                          Text("Voir profil")

                        ],
                      )

                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(height: 12.0,),
              ListTile(
                leading: Icon(Icons.history),
                title: Text("Historique",style:TextStyle(fontSize: 15.0)),

              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text("Voir profil",style:TextStyle(fontSize: 15.0)),

              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text("A propos ",style:TextStyle(fontSize: 15.0)),

              ),
              GestureDetector(
                onTap: (){
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text("Déconnexion ",style:TextStyle(fontSize: 15.0)),

                ),
              ),

            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
              mapType: MapType.normal,
              myLocationButtonEnabled: true,

              initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            polylines: polylineSet,
            markers:markerSet ,
            circles: circleSet,
            onMapCreated: (GoogleMapController controller){
              _controllerGoogleMap.complete(controller);
              newGoogleMapController=controller;
              setState(() {
                bottomPaddingOfMap+265.0;
              });
              locatePosition();
            },
          ),
          Positioned(
            top: 45.0,
            left: 22.0,
            child: GestureDetector(
              onTap: (){
                if(drawerOpen){
                  scaffoldKey.currentState!.openDrawer();

                }
                else{
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7)
                    )
                  ]
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon((drawerOpen)?Icons.menu:Icons.close, color: Colors.black,),

                ),

              ),
            ),
          ),

          Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: Duration(milliseconds: 160),
                child: Container(
                  height: searchContainerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(18.0),topRight: Radius.circular(18.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7),

                      )
                    ]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6.0,),
                        Text("Bonjour", style: TextStyle(fontSize:12.0 ),),
                        Text("Ou allez-vous?", style: TextStyle(fontSize:20.0,fontFamily: "Brand-Bold"),),
                        SizedBox(height: 20.0,),
                    GestureDetector(
                      onTap: ()async{
                        print("resddine");
                      var res=await Navigator.push(context,MaterialPageRoute(builder: (context){
                          return SearchScreen();
                        }
                        )
                        );
                        print("resddine$res");
                        if(res=="obtainDirection"){
                          print("jojojoo");
                          displayRideDetailsContainer();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7,0.7),

                              ),

                            ]
                        ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.search,color: Colors.blueAccent,),
                            SizedBox(width: 10.0,),
                            Text("Chercher adresse de destination")
                          ],
                        ),
                      ),
                      ),
                    ),
                        SizedBox(height: 24,),
                        Row(
                          children: [
                            Icon(Icons.home,color: Colors.grey,),
                    SizedBox(width: 12.0,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Provider.of<AppData>(context).pickUpLocation!=null
                          ?Provider.of<AppData>(context).pickUpLocation!.placeName
                      :"Ajouter domicile",overflow:TextOverflow.fade,
                        maxLines: 1,
                        softWrap: false,
                      ),
                      SizedBox(height: 4.0,),
                      Text("Votre adresse de domicile",style: TextStyle(
                        color: Colors.black54,fontSize: 12.0
                      ),)
                    ],
                  ),


                          ],
                        ),
                        SizedBox(height: 10.0,),
                        DividerWidget(),
                        SizedBox(height: 16.0,),

                        Row(
                          children: [
                            Icon(Icons.work,color: Colors.grey,),
                            SizedBox(width: 12.0,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Ajouter bureau"),
                                SizedBox(height: 4.0,),
                                Text("Votre adresse de travail",style: TextStyle(
                                    color: Colors.black54,fontSize: 12.0
                                ),)
                              ],
                            ),


                          ],
                        ),




                      ],
                    ),
                  ),
                ),
              )
          ),
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: Duration(milliseconds: 160),

              child: Container(
                height:rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0),topRight: Radius.circular(16.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7)
                    ),
                  ]
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Image.asset("images/taxi.png",height: 70.0,width: 80.0,),
                              SizedBox(width: 16,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Car",style: TextStyle(fontSize:18.0,fontFamily: "Brand-Bold"),),
                                  Text(tripDirectionDetails!=null?tripDirectionDetails!.distanceText:"",style: TextStyle(fontSize: 16.0,fontFamily: "Brand-Bold",color: Colors.grey),),

                                ],
                              ),
                              Expanded(child: Container()),
                                Text(
                                  tripDirectionDetails==null?"":"${AssistantMethods.calculateFares(tripDirectionDetails!)}€"
                                )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0,),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.moneyCheckAlt,size: 18.0,color: Colors.black54,),
                          SizedBox(width: 16.0,),
                          Text("Cash"),
                          SizedBox(width: 6.0,),
                          Icon(Icons.keyboard_arrow_down,color: Colors.black54,size:16.0,)
                        ],
                      ),
                      ),
                      SizedBox(height: 24,),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: RaisedButton(
                          onPressed: (){
                              displayRequestRideContainer();
                          },
                          color: Theme.of(context).accentColor,
                          child: Padding(
                            padding: EdgeInsets.all(17),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Request",style: TextStyle(fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white
                                ),
                                ),
                                Icon(FontAwesomeIcons.taxi,color: Colors.white,size:26.0),

                              ],
                            ),
                          ),
                        ),

                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topRight: Radius.circular(16),topLeft: Radius.circular(16)),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color:Colors.black54,
                    offset: Offset(0.7,0.7)
                  )
                ]
              ),
              height: requestRideContainerHeight,
              child:Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(height: 12,),
                    SizedBox(width: double.infinity,
                    child: ColorizeAnimatedTextKit(
                      onTap:(){

                      },
                      text: [
                        "Demande de course...",
                        "Veuillez Patienter...",
                        "Recherche de chauffeur..."
                      ],
                      textStyle: TextStyle(
                        fontSize: 45,
                        fontFamily: "Signatra"
                      ),
                      colors: [
                        Colors.green,
                        Colors.purple,
                        Colors.pink,
                        Colors.blue,
                        Colors.yellow,
                        Colors.red
                      ],
                      textAlign: TextAlign.center,

                    ),
                    ),
                    SizedBox(height: 22,),
                    GestureDetector(
                      onTap: (){
                        print("ajdiiiiiine");
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(width: 2.0,color: Colors.grey[300]!)
                        ),
                          child: Icon(Icons.close,size:26),
                      ),
                    ),
                    SizedBox(height: 10,),
                    Container(width: double.infinity,
                    child: Text("Annuler la course...",
                    textAlign: TextAlign.center,
                      style: TextStyle(fontSize:12.0),
                    ),
                    )

                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
  Future<void> getPlaceDirection() async{
    var initialPos=Provider.of<AppData>(context,listen: false).pickUpLocation;
    var finalPos=Provider.of<AppData>(context,listen: false).dropOffLocation;
    if(initialPos!=null && finalPos!=null){
      var pickUpLatLng= LatLng(initialPos.latitude,initialPos.longitude);
      var dropOffLatLng= LatLng(finalPos.latitude,finalPos.longitude);
      showDialog(context: context, barrierDismissible: false,builder: (BuildContext context){
        return ProgressDialog(message: "Please wait...",);
      });
      var details=await AssistantMethods.obtainPlaceDirectionsDetails(pickUpLatLng,dropOffLatLng);
      setState(() {
        tripDirectionDetails=details;
      });
      Navigator.pop(context);
      print("this is encoded points::${details!.encodedPoints}");
      PolylinePoints polylinePoints=PolylinePoints();
      List<PointLatLng> decodedPolylineResult=polylinePoints.decodePolyline(details.encodedPoints);
      pLineCoordinates.clear();
      if(decodedPolylineResult.isNotEmpty){
        decodedPolylineResult.forEach((pointLatLng) {
          pLineCoordinates.add(LatLng(pointLatLng.latitude,pointLatLng.longitude));
        });
        print(pLineCoordinates.toString());
      }
      polylineSet.clear();
      setState(() {
        Polyline polyline=Polyline(
          color: Colors.pink,
          polylineId: PolylineId("PolylineId"),
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        );
        polylineSet.add(polyline);
      });
      LatLngBounds latLngBounds;
      if(pickUpLatLng.latitude>dropOffLatLng.latitude  && pickUpLatLng.longitude>dropOffLatLng.longitude){
        latLngBounds= LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
      }
      else if(pickUpLatLng.latitude>dropOffLatLng.latitude){
        latLngBounds= LatLngBounds(
            southwest: LatLng(dropOffLatLng.latitude,pickUpLatLng.longitude),
            northeast: LatLng(pickUpLatLng.latitude,dropOffLatLng.longitude));
      }
      else if(pickUpLatLng.longitude>dropOffLatLng.longitude){
        latLngBounds= LatLngBounds(
            southwest: LatLng(pickUpLatLng.latitude,dropOffLatLng.longitude),
            northeast: LatLng(dropOffLatLng.latitude,pickUpLatLng.longitude));
      }
      else{
        latLngBounds=LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
      }
  newGoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds,70));
      Marker pickUpLocMarker=Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(title: initialPos.placeName,snippet: "ma localisation"),
        position: pickUpLatLng,
        markerId: MarkerId("pickUpId")
      );
      Marker dropOffLocMarker=Marker(
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: finalPos.placeName,snippet: "ma destination"),
          position: dropOffLatLng,
          markerId: MarkerId("dropOffId")
      );
      setState(() {
        markerSet.add(pickUpLocMarker);
        markerSet.add(dropOffLocMarker);
      });
      Circle pickUpLocCircle=Circle(
        fillColor: Colors.yellow,
        center: pickUpLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.yellowAccent,
        circleId: CircleId("pickUpId")
      );
      Circle dropOffLocCircle=Circle(
          fillColor: Colors.deepPurple,
          center: dropOffLatLng,
          radius: 12,
          strokeWidth: 4,
          strokeColor: Colors.deepPurpleAccent,
          circleId: CircleId("dropOffId")
      );
      setState(() {
        circleSet.add(pickUpLocCircle);
        circleSet.add(dropOffLocCircle);
      });

    }
}

}
