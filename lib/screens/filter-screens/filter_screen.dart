import 'dart:convert';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:http/http.dart' as https;
import '../../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cool_dropdown/cool_dropdown.dart';
import 'package:cool_dropdown/models/cool_dropdown_item.dart';

class FilterScreen extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const FilterScreen({Key? key, required this.myIndex, required this.navigateTo}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

List<dynamic> responseData = [];

class _FilterScreenState extends State<FilterScreen> {
  String gender = "";
  String date = "";
  String option = "";
  int selectedIndex = -1;
  int selectedFashionId = 0;
  int selectedFashionIndex=0;
  String FashionName='';
  bool loading =true;
  List<String> get labels => ['Male', 'Female', 'Other'];
  List<CoolDropdownItem<String>> fruitDropdownItems = [];
  final FashionStyleController = DropdownController();

  @override
  void initState() {
    super.initState();
    getCachedData();
    getAllEvents();
  }

  getCachedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    gender = preferences.getString("selectedGender")!;
  //   date = preferences.getString("selectedDate")!;
  // option = preferences.getString("selectedOption")!;
  //   selectedFashionId=preferences.getInt("selectedFashionId")!;
  //   selectedFashionIndex=preferences.getInt('selectedFashionIndex')!;
    debugPrint("shared preference option $gender $date $option $selectedFashionId ");
    selectedIndex = labels.indexOf(gender);
    _selectedDate = DateTime.parse(date);
    //dropdownvalue = option;
  }

  void saveGender(String label) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedGender', label);
  }

  Future<void> saveSelectedDate(DateTime selectedDate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedDate', selectedDate.toIso8601String());
  }

  Future<void> saveSelectedOption(String selectedOption) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedOption', selectedOption);
  }

  void savefashionId(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('selectedFashionId', selectedFashionId);
  }
  void savefashionIndex(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('selectedFashionIndex', selectedFashionIndex);
  }

  void clearFilterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedGender', "");
    // prefs.remove('selectedDate');
    // prefs.remove('selectedOption');
    // prefs.remove("selectedFashionId");
  }

  getAllEvents() async {
    try {
      final response =
          await https.get(Uri.parse("$serverUrl/fashionEvents/"));
      if (response.statusCode == 200) {
        responseData = jsonDecode(response.body);
        if (responseData.isNotEmpty) {
          print("get all events data $responseData");
          setState(() {
            items =
                responseData.map<String>((event) => event["title"]).toList();
            // itemsID=responseData.map<int>((event) => event["int"]).toList();
            for (var i = 0; i < items.length; i++) {
              fruitDropdownItems.add(CoolDropdownItem<String>(
                  label: ' ${items[i]}',
                  value: items[i]));

            }
            loading=false;
            print("loading bool $loading");

            print(items.toString());
            fashionId = responseData.map<int>((event) => event["id"]).toList();
            if (option.isNotEmpty) {
              dropdownvalue = option;
            } else {
              dropdownvalue = items[0];
            }

          });
        }
      } else {
        print("Error in all event api:${response.statusCode}");
      }
    } catch (e) {
      print(" all events api didn't hit $e");
    }
  }

  DateTime? _selectedDate;

  List<String> items = [];
  List<int> itemsID=[];
  List<int> fashionId = [];
  String? dropdownvalue;

    void _pickDateDialog() {
      showDatePicker(
        context: context,

        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
        builder: (context, child) {
          Color onSurfaceColor = Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : dark1;
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: primary, // <-- SEE HERE
                onPrimary: ascent, // <-- SEE HERE
                onSurface: onSurfaceColor, // <-- SEE HERE
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  backgroundColor: primary // button text color
                ),
              ),
            ),
            child: child!,
          );
        },
      ).then((pickedDate) {
        if (pickedDate == null) {
          return;
        }
        saveSelectedDate(pickedDate);
        setState(() {
          _selectedDate = pickedDate;
        });
      });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
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
        centerTitle: true,
        title: const Text(
          "Filter on style",
          style: TextStyle(color: Colors.white, fontFamily: Poppins),
        ),
      ),
      body: loading==true?SpinKitCircle(color: primary,size: 50,):
      Center(
        child: ListView(
          children: [
             SizedBox(
              height: MediaQuery.of(context).size.height * 0.07,
            ),
            // WidgetAnimator(
            //   Padding(
            //     padding: const EdgeInsets.all(18.0),
            //     child: Row(
            //       children: [
            //         const SizedBox(
            //           width: 10,
            //         ),
            //         Text(
            //           "Select a date",
            //           style: TextStyle(
            //             color: primary,
            //             fontSize: 20,
            //             fontWeight: FontWeight.w900,
            //             fontFamily: Poppins,
            //           ),
            //         )
            //       ],
            //     ),
            //   ),
            // ),
            // WidgetAnimator(
            //   Padding(
            //     padding:
            //         const EdgeInsets.only(left: 18.0, right: 18.0, bottom: 18.0),
            //     child: Row(
            //       children: [
            //         const SizedBox(
            //           width: 10,
            //         ),
            //         GestureDetector(
            //           onTap: () {
            //             _pickDateDialog();
            //           },
            //           child: Container(
            //             decoration:
            //                 BoxDecoration(border: Border.all(color: primary)),
            //             child: Padding(
            //               padding: const EdgeInsets.all(9.0),
            //               child: Text(
            //                 _selectedDate ==
            //                         null //ternary expression to check if date is null
            //                     ? 'No date was chosen!'
            //                     : 'Picked Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
            //                 style: const TextStyle(
            //                     fontWeight: FontWeight.w500,
            //                     fontFamily: Poppins),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            WidgetAnimator(
              Padding(
                padding: const EdgeInsets.only(
                    left: 18.0, right: 18.0, top: 5, bottom: 15),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Select gender",
                      style: TextStyle(
                          color: primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: Poppins),
                    )
                  ],
                ),
              ),
            ),
            WidgetAnimator(
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 15,
                  ),
                  ToggleSwitch(
                    fontSize: 14,
                    centerText: true,
                    multiLineText: true,
                    dividerMargin: 0,
                    activeBgColor: [primary, secondary],
                    activeFgColor: ascent,
                    minWidth: MediaQuery.of(context).size.width*0.9,
                    minHeight: 60,
                    initialLabelIndex: selectedIndex,
                    totalSwitches: 4,
                    labels: const ['Male', 'Female', 'Uni-Sex','Other'],
                    onToggle: (index) {
                      print('switched to: $index');
                      String selected = labels[index!];

                      setState(() {
                        selectedIndex = index;
                        selected = labels[index];
                      });
                      saveGender(selected);
                    },
                  ),
                ],
              ),
            ),
            // const SizedBox(
            //   height: 20,
            // ),
            // WidgetAnimator(
            //   Padding(
            //     padding: const EdgeInsets.only(
            //         left: 18.0, right: 18.0, top: 25, bottom: 18),
            //     child: Row(
            //       children: [
            //         const SizedBox(
            //           width: 10,
            //         ),
            //         Text(
            //           "Select fashion event",
            //           style: TextStyle(
            //               color: primary,
            //               fontSize: 20,
            //               fontWeight: FontWeight.w900,
            //               fontFamily: Poppins),
            //         )
            //       ],
            //     ),
            //   ),
            // ),
            //items.length>4?SizedBox(height: 70,):SizedBox(height: 5,),
            // Container(
            //   child: WidgetAnimator(Row(
            //     children: [
            //       const SizedBox(
            //         width: 30,
            //       ),
            //       // Container(
            //       //   height: 34,
            //       //   decoration: BoxDecoration(
            //       //     border: Border.all(
            //       //         color: primary, style: BorderStyle.solid, width: 0.80),
            //       //   ),
            //       //   child:
            //       //   DropdownButton(
            //       //
            //       //      // Reduces the height of each item
            //       //     //itemHeight: 40, // Adjust the height of each item
            //       //     menuMaxHeight: 140, // Set the maximum height of the dropdown menu
            //       //     underline: SizedBox(),
            //       //     hint: Text("Fashion Type",style: TextStyle(fontFamily: Poppins),),
            //       //     value: dropdownvalue,
            //       //     icon: const Icon(Icons.keyboard_arrow_down),
            //       //     items: items.map((String items) {
            //       //       return DropdownMenuItem(
            //       //         value: items,
            //       //
            //       //         child: Container(
            //       //           child: Padding(
            //       //             padding: const EdgeInsets.all(8.0),
            //       //             child: Text(" "+items,style: TextStyle(
            //       //                 fontWeight: FontWeight.w500,
            //       //               fontSize: 15,
            //       //                 fontFamily: Poppins
            //       //             ),),
            //       //           ),
            //       //         ),
            //       //       );
            //       //     }).toList(),
            //       //
            //       //     onChanged: (String? newValue) {
            //       //       setState(() {
            //       //         dropdownvalue = newValue!;
            //       //         selectedFashionId=responseData.firstWhere((element) => element['title']==newValue!)['id'];
            //       //         print("selected fashion id is $selectedFashionId");
            //       //
            //       //       });
            //       //       saveSelectedOption(newValue!);
            //       //       savefashionId(selectedFashionId);
            //       //     },
            //       //   ),
            //       // ),
            //       SingleChildScrollView(
            //         child: Center(
            //           child: WillPopScope(
            //             onWillPop: () async {
            //               if (FashionStyleController.isOpen) {
            //                 FashionStyleController.close();
            //                 return Future.value(false);
            //               } else {
            //                 return Future.value(true);
            //               }
            //             },
            //             child: CoolDropdown<String>(
            //               controller: FashionStyleController,
            //               dropdownList: fruitDropdownItems,
            //
            //
            //               defaultItem:fruitDropdownItems.elementAt(selectedFashionIndex),
            //               onChange: (value)  {
            //                  selectedFashionIndex = fruitDropdownItems.indexWhere((item) => item.value == value);
            //                  savefashionIndex(selectedFashionIndex);
            //                 print("selected item index: $selectedIndex");
            //                 print("selected item $value");
            //                 selectedFashionId=responseData.firstWhere((element) => element['title']==value)['id'];
            //                 saveSelectedOption(value);
            //                 savefashionId(selectedFashionId);
            //                 setState(() {
            //
            //                 });
            //
            //               },
            //               onOpen: (value) {
            //
            //               },
            //               resultOptions: ResultOptions(
            //
            //                 padding: const EdgeInsets.symmetric(horizontal: 10),
            //                 width: 200,
            //                 render: ResultRender.all,
            //                 placeholder: 'Fashion Style',
            //                 isMarquee: false,
            //                 textStyle: const TextStyle(fontFamily: Poppins,color: Colors.white),
            //                 boxDecoration: BoxDecoration(
            //                   color: Colors.black12,
            //                   border: Border.all(color: primary),
            //                   borderRadius: BorderRadius.circular(8.0)
            //
            //
            //                 ),
            //                 openBoxDecoration: BoxDecoration(
            //                   color: Colors.black12,
            //                     border: Border.all(color: primary),
            //                     borderRadius: BorderRadius.circular(8.0),
            //                 ),
            //
            //               ),
            //               dropdownOptions: DropdownOptions(
            //                   top: MediaQuery.of(context).size.height*(Platform.isIOS?-0.005:-0.3),
            //                   height: 170,
            //                   color: Colors.black12,
            //                   gap: const DropdownGap.all(5),
            //                   borderSide:
            //                       BorderSide(width: 1, color: primary),
            //                   padding: const EdgeInsets.symmetric(horizontal: 10),
            //                   align: DropdownAlign.left,
            //                   animationType: DropdownAnimationType.size),
            //               dropdownTriangleOptions: const DropdownTriangleOptions(
            //                 width: 0,
            //                 height: 0,
            //                 align: DropdownTriangleAlign.left,
            //                 borderRadius: 0,
            //                 left:
            //                     0,
            //               ),
            //               dropdownItemOptions: const DropdownItemOptions(
            //                 textStyle: TextStyle(fontFamily: Poppins,color: Colors.white),
            //                 isMarquee: false,
            //                 mainAxisAlignment: MainAxisAlignment.start,
            //                 render: DropdownItemRender.all,
            //                 height: 30,
            //                 boxDecoration: (
            //                 BoxDecoration(color: Colors.black12)
            //                 )
            //
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   )),
            // ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 150,
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: TextButton(
                  onPressed: () {
                    clearFilterData();
                    setState(() {
                      _selectedDate = null;
                      selectedIndex = -1;
                      dropdownvalue = null;
                    });
                  },
                  child: Text(
                    "Remove Filter",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                        fontFamily: Poppins,
                        color: primary),
                  )),
            ),
            const SizedBox(height: 20),
            WidgetAnimator(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if(_selectedDate==null&&selectedIndex==-1){
                      // print("no gender selected");
                      // Navigator.pop(context);
                      // setState(() {});
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: primary,
                          title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                          content: const Text("Please select all fields.",style: TextStyle(color: ascent,fontFamily: Poppins),),
                          actions: [
                            TextButton(
                              child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                              onPressed:  () {
                                setState(() {
                                  Navigator.pop(context);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    else{
                      Navigator.pop(context);
                      setState(() {});
                    }

                    //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                  },
                  child: Card(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
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
                          borderRadius: const BorderRadius.all(Radius.circular(12))),
                      child: const Text(
                        'Apply Filter',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ascent,
                            fontFamily: Poppins),
                      ),
                    ),
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
