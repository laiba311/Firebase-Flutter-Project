import 'dart:io';

import 'package:finalfashiontimefrontend/screens/authentication/splash_screen.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RetryHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = Duration(seconds: 20)
      ..maxConnectionsPerHost = 3;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = RetryHttpOverrides();
  if (kDebugMode) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadFromPrefs();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    MobileAds.instance.initialize();
    runApp(
        ChangeNotifierProvider(create: (_)=> themeNotifier,child: const MyApp() ,)
    );
    // runApp( const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, notifier, child) {
        return MaterialApp(
          navigatorKey: GlobalKey<NavigatorState>(),
          debugShowCheckedModeBanner: false,
          title: 'Fashion Time',
          theme: notifier.darkTheme ? dark : light,
          home: const SplashScreen(),
          //home: testing(),
        );
      },
    );
  }
}

class TempScreen extends StatefulWidget {
  const TempScreen({super.key});

  @override
  State<TempScreen> createState() => _TempScreenState();
}

class _TempScreenState extends State<TempScreen> {
  String name="";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    GetCachedData();
  }

  GetCachedData()async{
    SharedPreferences preferences= await SharedPreferences.getInstance();
    name= preferences.getString('name') == null ? "" :preferences.getString('name')!;
    print(name);
    if(name.isNotEmpty == true){

    }else {
      Navigator.push(context,MaterialPageRoute(builder: (context) => const SplashScreen()));
    }
  }




  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text(""),);
  }
}


