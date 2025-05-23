import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart'as https;

class ForgetPasswordViaProfileScreen extends StatefulWidget {
  const ForgetPasswordViaProfileScreen({required this.code, Key? key, required this.email, required this.username}) : super(key: key);
  final String email;
  final String username;
  final String code;

  @override
  State<ForgetPasswordViaProfileScreen> createState() => _ForgetPasswordViaProfileScreenState();
}

class _ForgetPasswordViaProfileScreenState extends State<ForgetPasswordViaProfileScreen> {
  bool loading=false;
  bool loading1=false;
  bool eye1=false;
  bool eye2=false;
  String? passwordError;
  String? passwordError1;
  TextEditingController newPassword = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  resetPassword(){
    print("password token and password2 is ======>${newPassword.text} ${confirmPassword.text} ${widget.code}");
    debugPrint("otp code is ===========>${widget.code.toString()}");
    const String url='$serverUrl/password/reset/confirm/';
    try{
      setState(() {
        loading1=true;
      });
      https.post(Uri.parse(url),body: {
        "password":newPassword.text.toString(),
        "token":widget.code.toString(),
        "password2":confirmPassword.text.toString(),
        "email": widget.email,
        "username": widget.username

      }).then((value) {
        if(value.statusCode==200|| value.statusCode==201){
          Fluttertoast.showToast(msg: "Password Changed Successfully!",backgroundColor: primary);
          setState(() {
            loading1=false;
          });
          Navigator.pop(context);
          Navigator.pop(context);

        }
        else{
          debugPrint("error received with status code============>${value.statusCode}");
          setState(() {
            loading1=false;
          });
        }
      });
    }catch(e){
      setState(() {
        loading1=false;
        debugPrint("error received============>${e.toString()}");
      });
    }
  }

  bool isPasswordValid(String value) {
    // Use regex for simple email validation
    final RegExp passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[\d_!@#$%^&*()-+=]).{7,}$');
    return passwordRegex.hasMatch(value);
  }
  void validatePassword() {
    setState(() {
      if(newPassword.text == ''){
        passwordError="Password is required.";
      }
      else if(newPassword.text != confirmPassword.text){
        passwordError ="Passwords do not match";
        passwordError1 ="Passwords do not match";
      }
      else{
        passwordError = isPasswordValid(newPassword.text) ? null : "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      }
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
                      Container(
                          child: Image.asset("assets/logo.png",height: 150,)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50,),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      onChanged: (value){
                        setState(() {
                          passwordError = null;
                          passwordError1 = null;
                        });
                      },
                      controller: newPassword,
                      style: const TextStyle(
                          color: Colors.pink,
                          fontFamily: Poppins
                      ),
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(eye1 == true ?Icons.visibility:Icons.visibility_off,color: Colors.black54,),
                          onPressed: (){
                            setState(() {
                              eye1 = !eye1;
                            });
                          },
                        ),
                        hintStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            fontFamily: Poppins
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink),
                        ),
                        errorBorder: InputBorder.none,
                        errorText: passwordError,
                        errorMaxLines: 3,
                        errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins),
                        alignLabelWithHint: true,
                        hintText: "Enter new password",
                      ),
                      cursorColor: Colors.pink,
                      obscureText: eye1,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      onChanged: (value){
                        setState(() {
                          passwordError1 = null;
                          passwordError = null;
                        });
                      },
                      controller: confirmPassword,
                      style: const TextStyle(
                          color: Colors.pink,
                          fontFamily: Poppins
                      ),
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(eye2 == true ?Icons.visibility:Icons.visibility_off,color: Colors.black54,),
                            onPressed: (){
                              setState(() {
                                eye2 = !eye2;
                              });
                            },
                          ),
                          hintStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              fontFamily: Poppins
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                          ),
                          errorBorder: InputBorder.none,
                          errorText: passwordError1,
                          errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins),
                          errorMaxLines: 3,
                          alignLabelWithHint: true,
                          hintText: "Confirm password"
                      ),
                      cursorColor: Colors.pink,
                      obscureText: eye2,
                    ),
                  ),
                ),
                const SizedBox(height: 50,),
                WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        loading == true ? const SpinKitCircle(color: ascent,size: 70,) :
                        loading1 ? SpinKitCircle(color: primary,):
                        Container(
                          height: 35,
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
                          child:

                          ElevatedButton(
                              style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      )
                                  ),
                                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                                  padding: MaterialStateProperty.all(EdgeInsets.only(
                                      top: 5,bottom: 8,
                                      left:MediaQuery.of(context).size.width * 0.1,right: MediaQuery.of(context).size.width * 0.1)),
                                  textStyle: MaterialStateProperty.all(
                                      const TextStyle(fontSize: 12, color: Colors.white,fontFamily: Poppins))),
                              onPressed: () {
                                  validatePassword();
                                  if(passwordError == null && passwordError1 == null) {
                                    resetPassword();
                                  }
                              },
                              child: const Text('Save Password',style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
