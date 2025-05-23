import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import '../../utils/constants.dart';

class AddHashTagScreen extends StatefulWidget {
  final String postId;
  const AddHashTagScreen({super.key, required this.postId});

  @override
  State<AddHashTagScreen> createState() => _AddHashTagScreenState();
}

class _AddHashTagScreenState extends State<AddHashTagScreen> {
  String id = "";
  String token = "";
  TextEditingController hashtags = TextEditingController();
  List<String> hashtagsList = [];
  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(id);
  }


  addHashtag(String fashionId) {
    String url = "$serverUrl/fashionUpload/$fashionId/add_hashtag/";
    try {
      https.post(Uri.parse(url), headers: {
        "Authorization": "Bearer $token"
      }, body: {
        "hashtag": hashtags.text
      }).then((value) {
        if (value.statusCode == 200) {
          setState(() {
            hashtagsList.add(hashtags.text);
            hashtags.clear();
          });
          Fluttertoast.showToast(
              msg: "Hashtag added!", backgroundColor: primary);
        }
        else{
          debugPrint("error======>${value.statusCode}");
        }
      });
    } catch (e) {
      debugPrint("error received=============>${e.toString()}");
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    getCashedData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  stops: const [0.0, 0.99],
                  tileMode: TileMode.clamp,
                  colors: <Color>[
                    secondary,
                    primary,
                  ])),
        ),
        backgroundColor: primary,
        title: const Text(
          "Add Hashtags",
          style: TextStyle(fontFamily: Poppins,),
        ),
      ),
      body: ListView(children: [

        SizedBox(
          height: MediaQuery.of(context).size.height*0.2,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hashtags,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    // hintTextDirection: TextDirection.ltr,
                    contentPadding: const EdgeInsets.only(top: 10),
                    hintText: 'Add hashtags',
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      fontFamily: Poppins,
                    ),
                    border: const OutlineInputBorder(),
                    focusColor: primary,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: primary),
                    ),
                  ),
                  cursorColor: primary,
                  style: TextStyle(
                      color: primary, fontSize: 13, fontFamily: Poppins,),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.01,
              ),
              ElevatedButton(
                  onPressed: () {
                    addHashtag(widget.postId);
                  },
                  style: ButtonStyle(
                      elevation: MaterialStateProperty.all(10.0),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      )),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.pinkAccent),
                      padding: MaterialStateProperty.all(EdgeInsets.only(
                          top: 13,
                          bottom: 13,
                          left: MediaQuery.of(context).size.width * 0.1,
                          right: MediaQuery.of(context).size.width * 0.1)),
                      textStyle: MaterialStateProperty.all(const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        fontFamily: Poppins,))),
                  child: const Text("Add",style: TextStyle(fontFamily: Poppins,),))
            ],
          ),
        ),
        hashtagsList.isNotEmpty?
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: hashtagsList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3, // Adjust the aspect ratio to control item height
            mainAxisSpacing: 8.0, // Adjust spacing between rows
            crossAxisSpacing: 8.0,

          ),
          itemBuilder: (context, index) {
            return   Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text(hashtagsList[index],style: TextStyle(color: primary,fontWeight: FontWeight.bold,fontFamily: Poppins,),)),
            );
          },
        ):const SizedBox(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: 37,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    stops: const [0.0, 0.99],
                    tileMode: TileMode.clamp,
                    colors:
                         <Color>[
                      secondary,
                      primary,
                    ])),
            child: ElevatedButton(

                style: ButtonStyle(
                    shape: MaterialStateProperty.all<
                        RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12.0),
                        )),
                    backgroundColor: MaterialStateProperty.all(
                        Colors.transparent),
                    shadowColor: MaterialStateProperty.all(
                        Colors.transparent),
                    padding: MaterialStateProperty.all(EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                        left: MediaQuery.of(context).size.width *
                            0.26,
                        right:
                        MediaQuery.of(context).size.width *
                            0.26)),
                    textStyle: MaterialStateProperty.all(
                        const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          fontFamily: Poppins,))),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);

                },

                child: const Text(
                  'Submit',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    fontFamily: Poppins,),
                )),
          ),
        ),
      ]),
    );
  }
}
