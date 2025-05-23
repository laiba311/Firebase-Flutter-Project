import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/authentication/login_screen.dart';
import 'package:finalfashiontimefrontend/screens/home_screen.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'forget_password_profile.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(
        const Duration(seconds: 3), (){
          if(mounted) {
            checkUser(context);
          }
    });
  }

  Future<void> checkUser(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var sessionEmail = prefs.getString('token');
    if (sessionEmail != null) {
      Navigator.of(context).pop();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        //Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      });
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Login()));
      //Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => const ForgetPasswordViaProfileScreen(code: "1234",)));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: secondary,
        image: const DecorationImage(
            image: AssetImage(
                "assets/background.jpg"
            ),
            fit: BoxFit.fill
        ),
      ),
      child: FadeIn(
        delay: const Duration(microseconds: 2000),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 15,),
              WidgetAnimator(
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Image.asset("assets/logo2.png",height: MediaQuery.of(context).size.height * 0.4,
                        fit: BoxFit.fill,),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2,),
            ],
          ),
          bottomNavigationBar: Container(
            color: Colors.transparent,
            height: 100,
            child: Column(
              children: [
                WidgetAnimator(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitCircle(color: ascent,size: 70,)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
