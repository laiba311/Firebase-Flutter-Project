import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/authentication/otp_screen_email.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart'as https;
import 'package:shared_preferences/shared_preferences.dart';
class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

bool loading =false;
String id='';
String token='';
bool loading1=false;

TextEditingController email=TextEditingController();


class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  @override
  void initState() {
    // TODO: implement initState
    getCashedData();
    super.initState();
  }
  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    debugPrint("user token===========>$token");

  }
  getOtpForEmail(){
    const String url='$serverUrl/user/api/profile/';
    loading1=true;
    https.patch(Uri.parse(url),headers:{
      "Authorization": "Bearer $token"
    },body: {
      "email":email.text
    }).then((value) {
      print("response========>${value.body}");
      if(value.statusCode==200){
        setState(() {
          loading1=false;
        });
        Fluttertoast.showToast(msg: "Verification code sent to the new email address.",backgroundColor: primary);
        Navigator.push(context, MaterialPageRoute(builder: (context) => OtpEmailScreen(email: email.text),));
      } else {
        // Handle HTTP error status codes
        print('HTTP Error: ${value.statusCode}');
      }
    }).catchError((error) {
      // Handle asynchronous errors
      print('Async Error: $error');
      setState(() {
        loading1=false;
      });
    });
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: WidgetAnimator(
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                const SizedBox(height: 30,),
                WidgetAnimator(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/logo.png",height: 150,),
                    ],
                  ),
                ),
                const SizedBox(height: 50,),
                WidgetAnimator(
                    Text('Enter your email address.',style: TextStyle(color: Colors.black54,fontFamily:Poppins,fontWeight: FontWeight.bold,fontSize: 16 ),)
                ),
                SizedBox(height: MediaQuery.of(context).size.height*0.03),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(
                            RegExp(r'\s')),
                      ],
                      controller: email,
                      style: const TextStyle(
                          color: Colors.pink,
                          fontFamily: Poppins
                      ),
                      decoration: const InputDecoration(

                        hintStyle: TextStyle(
                            color: Colors.black54,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            fontFamily: Poppins
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink),
                        ),
                        //enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        //disabledBorder: InputBorder.none,
                        alignLabelWithHint: true,
                        hintText: "Enter Email",
                      ),
                      cursorColor: Colors.pink,

                    ),
                  ),
                ),
                const SizedBox(height: 50,),
                WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        loading1 == true ? const SpinKitCircle(color: ascent,size: 70,) : Container(
                          height: 40,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.topRight,
                                  stops: const [0.0, 0.99],
                                  tileMode: TileMode.clamp,
                                  colors: <Color>[
                                    primary,
                                    secondary
                                  ])
                          ),
                          child: ElevatedButton(
                              style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      )
                                  ),
                                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                                  padding: MaterialStateProperty.all(EdgeInsets.only(
                                      top: 8,bottom: 8,
                                      left:MediaQuery.of(context).size.width * 0.1,right: MediaQuery.of(context).size.width * 0.1)),
                                  textStyle: MaterialStateProperty.all(
                                      const TextStyle(fontSize: 12, color: Colors.white,fontFamily: Poppins))),
                              onPressed: () {
                                getOtpForEmail();
                              },
                              child: const Text('Send Verification Link',style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: ascent,
                                  fontFamily: Poppins
                              ),)),
                        ),
                      ],
                    )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
