
import 'package:finalfashiontimefrontend/screens/authentication/change_email.dart';
import 'package:finalfashiontimefrontend/screens/authentication/email.dart';
import 'package:finalfashiontimefrontend/screens/profiles/change_password.dart';
import 'package:finalfashiontimefrontend/screens/profiles/change_username.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../animations/bottom_animation.dart';
import '../../../utils/constants.dart';
class PersonalSettingScreen extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const PersonalSettingScreen({super.key, required this.myIndex, required this.navigateTo});

  @override
  State<PersonalSettingScreen> createState() => _PersonalSettingScreenState();
}

class _PersonalSettingScreenState extends State<PersonalSettingScreen> {
   String username='';
   String email='';
   TextEditingController emailController=TextEditingController();
   TextEditingController usernameController=TextEditingController();
  getCachedData()async{
  SharedPreferences preferences=await SharedPreferences.getInstance();
    username= preferences.getString("username")!;
    email=preferences.getString('email')!;
    emailController.text=email;
    usernameController.text=username;
  }
  @override
  void initState() {
    getCachedData();
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.navigateTo(widget.myIndex);
        return Future.value(false);
      },
      child: Scaffold(
        // appBar: AppBar(
        //   centerTitle: true,
        //   flexibleSpace: Container(
        //     decoration: BoxDecoration(
        //         gradient: LinearGradient(
        //             begin: Alignment.topLeft,
        //             end: Alignment.topRight,
        //             stops: const [0.0, 0.99],
        //             tileMode: TileMode.clamp,
        //             colors: <Color>[
        //               secondary,
        //               primary,
        //             ])
        //     ),),
        //   backgroundColor: ascent,
        //
        //   title: const Text("Personal Settings",style: TextStyle(fontFamily: Poppins,),),
        // ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Center(
            child: WidgetAnimator(
              Padding(
                padding: const EdgeInsets.only(left:25.0,right: 25.0,top: 8.0,bottom: 8.0),
                child: TextField(
                controller: usernameController,
                  enabled: false,
                  style: TextStyle(
                      color: primary,
                    fontFamily: Poppins,
                  ),
                  decoration: InputDecoration(
                      hintStyle: const TextStyle(
                        //color: Colors.black54,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        fontFamily: Poppins,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 1, color: primary),
                      ),
                      focusColor: primary,
                      alignLabelWithHint: true,
                      hintText: "Enter Your Username"
                  ),
                  cursorColor: primary,
                ),
              ),
            ),
          ),
              const SizedBox(height: 10,),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangeUsernameScreen(),));
                },
                child: WidgetAnimator(Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    height: 35,
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.topRight,
                            stops: const [0.0, 0.99],
                            tileMode: TileMode.clamp,
                            colors: <Color>[
                              secondary,
                              primary,
                            ]),
                        borderRadius: const BorderRadius.all(Radius.circular(12))
                    ),
                    child: const Text('Change Username',style: TextStyle(
                        fontSize: 18,
                        color: ascent,
                        fontWeight: FontWeight.w700,
                      fontFamily: Poppins,
                    ),),
                  ),
                )),
              ),
          WidgetAnimator(
            Padding(
              padding: const EdgeInsets.only(left:25.0,right: 25.0,top: 8.0,bottom: 8.0),
              child: TextField(
                controller: emailController,
                enabled: false,
                style: TextStyle(
                    color: primary,
                  fontFamily: Poppins,
                ),
                decoration: InputDecoration(
                    hintStyle: const TextStyle(
                      //color: Colors.black54,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      fontFamily: Poppins,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: primary),
                    ),
                    focusColor: primary,
                    alignLabelWithHint: true,
                    hintText: "Email"
                ),
                cursorColor: primary,
              ),
            ),
          ),
              const SizedBox(height: 10,),
              GestureDetector(
                onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangeEmailScreen(),));
                },
                child: WidgetAnimator(Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    height: 35,
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.topRight,
                            stops: const [0.0, 0.99],
                            tileMode: TileMode.clamp,
                            colors: <Color>[
                              secondary,
                              primary,
                            ]),
                        borderRadius: const BorderRadius.all(Radius.circular(12))
                    ),
                    child: const Text('Change Email',style: TextStyle(
                        fontSize: 18,
                        color: ascent,
                        fontWeight: FontWeight.w700,
                      fontFamily: Poppins,
                    ),),
                  ),
                )),
              ),
              const SizedBox(height: 30,),
              // GestureDetector(
              //   onTap: () {
              //   Navigator.push(context, MaterialPageRoute(builder: (context) => const EmailScreen(),));
              //   },
              //   child: WidgetAnimator(Card(
              //     shape: const RoundedRectangleBorder(
              //         borderRadius: BorderRadius.all(Radius.circular(12))
              //     ),
              //     child: Container(
              //       alignment: Alignment.center,
              //       height: 35,
              //       width: MediaQuery.of(context).size.width * 0.8,
              //       decoration: BoxDecoration(
              //           gradient: LinearGradient(
              //               begin: Alignment.topLeft,
              //               end: Alignment.topRight,
              //               stops: const [0.0, 0.99],
              //               tileMode: TileMode.clamp,
              //               colors: <Color>[
              //                 secondary,
              //                 primary,
              //               ]),
              //           borderRadius: const BorderRadius.all(Radius.circular(12))
              //       ),
              //       child: const Text('Forgot Password?',style: TextStyle(
              //           fontSize: 18,
              //           color: ascent,
              //           fontWeight: FontWeight.w700,
              //         fontFamily: Poppins,
              //       ),),
              //     ),
              //   )),
              // ),
              // const SizedBox(height: 30,),
              // GestureDetector(
              //   onTap: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePassword(code: "12345", ),));
              //   },
              //   child: WidgetAnimator(Card(
              //     shape: const RoundedRectangleBorder(
              //         borderRadius: BorderRadius.all(Radius.circular(12))
              //     ),
              //     child: Container(
              //       alignment: Alignment.center,
              //       height: 35,
              //       width: MediaQuery.of(context).size.width * 0.8,
              //       decoration: BoxDecoration(
              //           gradient: LinearGradient(
              //               begin: Alignment.topLeft,
              //               end: Alignment.topRight,
              //               stops: const [0.0, 0.99],
              //               tileMode: TileMode.clamp,
              //               colors: <Color>[
              //                 secondary,
              //                 primary,
              //               ]),
              //           borderRadius: const BorderRadius.all(Radius.circular(12))
              //       ),
              //       child: const Text('Change Password',style: TextStyle(
              //           fontSize: 18,
              //           color: ascent,
              //           fontWeight: FontWeight.w700,
              //         fontFamily: Poppins,
              //       ),),
              //     ),
              //   )),
              // )
        ]),
      ),
    );
  }
}
