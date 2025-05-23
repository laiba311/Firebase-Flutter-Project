import 'package:finalfashiontimefrontend/screens/authentication/login_screen.dart';
import 'package:finalfashiontimefrontend/screens/profiles/change_password.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import '../../animations/bottom_animation.dart';

class SecurityTab extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const SecurityTab({super.key, required this.myIndex, required this.navigateTo});

  @override
  State<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<SecurityTab> {
  String id = "";
  String token = "";
  bool loading1 = false;
  TextEditingController password = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: AlertDialog(
            title: const Text("FashionTime",style: TextStyle(fontFamily: Poppins,)),
            backgroundColor: primary,
            content: const Text('Enter your password',style: TextStyle(fontFamily: Poppins,)),
            actions:  [ Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Enter password",
                  hintStyle: TextStyle(color: ascent,fontFamily: Poppins),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ascent), // color when not focused
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ascent), // color when focused
                  ),
                ),
                controller: password ,
              ),
            ),
              TextButton(child: const Text("Ok",style: TextStyle(fontFamily: Poppins,color: ascent)),onPressed: () {
                deleteAccountAfterVerification();
              },)],
            actionsPadding: const EdgeInsets.only(bottom: 40),
          ),
        );
      },
    );
  }

  deleteAccountAfterVerification()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    https.delete(
        Uri.parse("$serverUrl/api/delete-account/"),body: {
      'password':password.text.toString()
    },
        headers: {

          "Authorization": "Bearer $token"
        }
    ).then((value){
      print(value.body.toString());
      setState(() {
        loading1 = false;
      });
      preferences.clear().then((value){
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
      });
      // ignore: argument_type_not_assignable_to_error_handler
    }).catchError((error) {
      setState(() {
        loading1 = false;
      });
      Navigator.pop(context);
      // Handle the error or log it
      print("Error occurred during account deletion: $error");
    });
  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              SizedBox(height: 10,),
              ListTile(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePassword(code: "12345", ),));
                },
                leading: Icon(Icons.lock,size: 31,color: primary),
                title: Text("Change my password",style: TextStyle(
                    fontFamily: Poppins,
                    color: primary
                ),),
                trailing: Icon(Icons.arrow_forward_ios_outlined,color: primary),
              ),
              ListTile(
                onTap: (){
                  //Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePassword(code: "12345", ),));
                },
                leading: Icon(Icons.location_on_sharp,size: 33,color: primary,),
                title: Text("Login activities",style: TextStyle(
                    fontFamily: Poppins,
                    color: primary
                ),),
                trailing: Icon(Icons.arrow_forward_ios_outlined,color: primary),
              ),
              ListTile(
                onTap: (){
                  //Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePassword(code: "12345", ),));
                },
                leading: Image.asset("assets/2faicon.png",height: 31,width: 31,),
                title: Text("Two-factor authentication",style: TextStyle(
                    fontFamily: Poppins,
                    color: primary
                ),),
                trailing: Icon(Icons.arrow_forward_ios_outlined,color: primary),
              ),
            ],
          ),
          WidgetAnimator(
            loading1 == true ? SpinKitCircle(color: primary,size: 50,) : Padding(
              padding: const EdgeInsets.only(left:8.0,right: 8.0,top: 8,bottom: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                        style: ButtonStyle(
                            elevation: MaterialStateProperty.all(10.0),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                )
                            ),
                            backgroundColor: MaterialStateProperty.all(Colors.red),
                            padding: MaterialStateProperty.all(EdgeInsets.only(
                                top: 13,bottom: 13,
                                left:MediaQuery.of(context).size.width * 0.1,right: MediaQuery.of(context).size.width * 0.1)),
                            textStyle: MaterialStateProperty.all(
                                const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins,))),
                        onPressed: () {
                          deleteAccount();
                          //Navigator.pop(context);
                          //Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Register()));
                        },
                        child: const Text('Delete my account',style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ascent,
                          fontFamily: Poppins,
                        ),)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
