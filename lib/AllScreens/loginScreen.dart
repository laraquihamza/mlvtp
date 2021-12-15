import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:mlvtp/AllScreens/mainscreen.dart';
import 'package:mlvtp/AllScreens/registrationScreen.dart';
import 'package:toast/toast.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import "../AllWidgets/progressDialog.dart";
class LoginScreen extends StatefulWidget {
  static const String idScreen="login";
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController=TextEditingController();
  TextEditingController passwordTextEditingController=TextEditingController();

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
              SizedBox(height: 35.0),
              Image(
                image: AssetImage("images/mlvtransport.png"),
                width: MediaQuery.of(context).size.width*0.6,
                alignment: Alignment.center,
              ),
              SizedBox(height: 1.0,),
              Text(
                "Connectez-vous",
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
                        child:Text("Connexion",
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
                        if(!EmailValidator.validate(emailTextEditingController.text)){
                          Toast.show("Veuillez saisir une adresse e-mail correcte", context);
                        }
                        else if(passwordTextEditingController.text.length<8){
                          Toast.show("Veuillez saisir un mot de passe de plus de 8 caractères", context);
                        }
                        else{
                          loginAndAuthenticateUser(context);
                        }

                      },
                    )


                  ],
                ),
              ),
              FlatButton(onPressed: (){
                Navigator.pushNamedAndRemoveUntil(context,RegistrationScreen.idScreen,(route)=>false);
              }, child: Text(
                "Vous n'avez pas de compte? Inscrivez-vous"
              ))
            ],
          ),
        ),
      ),
    );
  }
  final FirebaseAuth _firebaseAuth=FirebaseAuth.instance;

  loginAndAuthenticateUser(BuildContext context) async{
    showDialog(context: context, barrierDismissible: false,builder: (BuildContext context){
      return ProgressDialog(message: "",);
    });
    final User user=(await FirebaseAuth.instance.signInWithEmailAndPassword(email:emailTextEditingController.text, password: passwordTextEditingController.text).catchError((errMsg){
      Toast.show("Erreur de connexion",context);
      Navigator.pop(context);
    })).user!;
    if(user!=null){
      var doc= await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if(doc==null){
        FirebaseAuth.instance.signOut();
        Navigator.pop(context);
        Toast.show("errordine",context);
      }
      else{
        Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);
      }
      doc.data();
    }
    else{
      loginAndAuthenticateUser(context);

      Toast.show("Erreur de connexion",context);
    }
  }
}
