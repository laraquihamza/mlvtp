import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mlvtp/AllScreens/loginScreen.dart';
import 'package:mlvtp/AllScreens/registrationScreen.dart';
import 'package:mlvtp/DataHandler/appData.dart';
import 'AllScreens/mainscreen.dart';
import "package:firebase_core/firebase_core.dart";
import 'package:provider/provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context)=>AppData(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: "Brand-Regular"
        ),
        initialRoute: FirebaseAuth.instance.currentUser==null?LoginScreen.idScreen:MainScreen.idScreen,
        routes:{
          RegistrationScreen.idScreen:(context)=>RegistrationScreen(),
          LoginScreen.idScreen:(context)=>LoginScreen(),
          MainScreen.idScreen:(context)=>MainScreen()


        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

