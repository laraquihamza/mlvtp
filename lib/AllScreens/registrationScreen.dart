import "package:flutter/material.dart";
import 'package:mlvtp/AllScreens/loginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:toast/toast.dart";
import 'dart:developer';
import 'package:email_validator/email_validator.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import "../AllWidgets/progressDialog.dart";
class RegistrationScreen extends StatefulWidget {
  static const String idScreen="register";
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  TextEditingController nameTextEditingController=TextEditingController();

  TextEditingController emailTextEditingController=TextEditingController();
  TextEditingController passwordTextEditingController=TextEditingController();
  TextEditingController phoneTextEditingController=TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(height: 20.0),
              Image(
                image: AssetImage("images/mlvtransport.png"),
                width: MediaQuery.of(context).size.width*0.6,
                alignment: Alignment.center,
              ),
              SizedBox(height: 1.0,),
              Text(
                "Inscrivez-vous",
                style: TextStyle(
                  fontSize: 24.0,
                  fontFamily: "Brand-Bold",
                ),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: nameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: "Nom",
                          labelStyle: TextStyle(
                              fontSize: 14.0
                          ),
                          hintStyle: TextStyle(
                            color:Colors.grey,
                            fontSize:10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 1.0,
                    ),

                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(
                              fontSize: 14.0
                          ),
                          hintStyle: TextStyle(
                            color:Colors.grey,
                            fontSize:10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 1.0,
                    ),

                    TextField(
                      controller: phoneTextEditingController,
                      keyboardType: TextInputType.phone ,
                      decoration: InputDecoration(
                          labelText: "Numéro de téléphone",
                          labelStyle: TextStyle(
                              fontSize: 14.0
                          ),
                          hintStyle: TextStyle(
                            color:Colors.grey,
                            fontSize:10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 1.0,
                    ),


                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: "Mot de passe",
                          labelStyle: TextStyle(
                              fontSize: 14.0
                          ),
                          hintStyle: TextStyle(
                            color:Colors.grey,
                            fontSize:10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(height: 1.0,),
                    RaisedButton(
                      color: Colors.yellow,
                      textColor: Colors.white,
                      child: Container(
                          child:Text("Inscription",
                            style: TextStyle(
                                fontSize: 18.0,
                                fontFamily: "Brand-Bold",
                                color: Colors.black
                            ),
                          )
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)
                      ),
                      onPressed: (){
                        print("joo${nameTextEditingController.text}");
                        if(nameTextEditingController.text.length==0){
                          Toast.show("Veuillez saisir un nom", context);
                          return;
                        }
                        else if(!EmailValidator.validate(emailTextEditingController.text)){
                          Toast.show("Veuillez saisir une adresse mail valide", context);
                        }
                        else if (phoneTextEditingController.text.isEmpty){
                          Toast.show("Veuillez saisir un numéro de téléphone", context);
                        }
                        else if (passwordTextEditingController.text.length<8){
                          Toast.show("Veuillez saisir un mot de passe d'au moins 8 caractères", context);
                        }
                        else{
                          registerNewUser(context);
                        }

                      },
                    )


                  ],
                ),
              ),
              FlatButton(onPressed: (){
                Navigator.pushNamedAndRemoveUntil(context,LoginScreen.idScreen,(route)=>false);
              }, child: Text(
                  "Déja inscrit? Connectez-vous"
              ))
            ],
          ),
        ),
      ),
    );
  }
  final FirebaseAuth _firebaseAuth=FirebaseAuth.instance;
  registerNewUser(BuildContext context)async{
    showDialog(context: context, barrierDismissible: false,builder: (BuildContext context){
      return ProgressDialog(message: "Registring... please wait",);
    });
    final User user=(await _firebaseAuth.createUserWithEmailAndPassword(email: emailTextEditingController.text, password: passwordTextEditingController.text).catchError((errMsg){
      Navigator.pop(context);
     Toast.show("Votre adresse mail est déja utilisée", context) ;
    }
    )).user!;
    if(user!=null){
      var doc=FirebaseFirestore.instance.collection("users").doc(user.uid);
      doc.set({
        "id":user.uid,
        "name":nameTextEditingController.text,
        "email":emailTextEditingController.text,
        "phone":phoneTextEditingController.text,
      });
      Navigator.pop(context);
      Toast.show("Inscription Réussie", context);
      Navigator.pushNamedAndRemoveUntil(context, "mainScreen", (route) => false);
    }
    else{
      Toast.show("Utilisateur non crée", context);
      Navigator.pop(context);
    }

  }
}

