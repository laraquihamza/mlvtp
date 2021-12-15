import 'package:flutter/material.dart';
import 'package:mlvtp/Models/address.dart';

class AppData extends ChangeNotifier{
  Address? pickUpLocation=null;
  Address? dropOffLocation=null;
  void updatePickUpLocationAddress(Address pickUpAddress){
    pickUpLocation=pickUpAddress;
    notifyListeners();
  }
  void updateDropOffLocationAddress(Address dropOffAddress){
    dropOffLocation=dropOffAddress;
    notifyListeners();
  }

}