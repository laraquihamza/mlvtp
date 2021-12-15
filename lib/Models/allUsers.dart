import 'package:firebase_auth/firebase_auth.dart';
import "package:firebase_core/firebase_core.dart";
import "package:cloud_firestore/cloud_firestore.dart";
class Users{
  String id="";
  String email="";
  String name="";
  String phone="";
  Users({required this.phone,required this.email,required this.id,required this.name});
  Users.fromSnapshot(DocumentSnapshot<Map<String,dynamic>> snapshot){
    id=snapshot.data()!["id"] ;
    email=snapshot.data()!["email"];
    name=snapshot.data()!["name"];
    phone=snapshot.data()!["phone"];
  }
}