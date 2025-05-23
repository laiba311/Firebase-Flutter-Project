import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/widgets/giphy_context.dart';

/// Provides a default text editor implementation for search operations.
class GiphySearchText extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ScrollController scrollController;

  const GiphySearchText({super.key, required this.controller, this.onChanged, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Container(
        alignment: Alignment.bottomCenter,
        width: MediaQuery.of(context).size.width * 0.98,
        child: Column(
          children: [
            SizedBox(height: 30,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 3,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(20))
                  ),
                  child: Text(""),
                )
              ],
            ),
            SizedBox(height: 20,),
            Card(
              elevation: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.topRight,
                      stops: const [0.0, 0.99],
                      tileMode: TileMode.clamp,
                      colors:  <Color>[Colors.black12, Colors.black12] ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      child: Container(
                          height: 40,
                          width: 20,
                          child: Icon(Icons.search,color: ascent,)
                      ),
                    ),
                    const SizedBox(width: 16,),
                    Expanded(
                        child: TextField(
                            controller: controller,
                            style: const TextStyle(color: ascent,fontFamily: Poppins,),
                            cursorColor: ascent,
                            decoration: const InputDecoration(
                                fillColor: ascent,
                                hintText: "Search GIPHY",
                                hintStyle: TextStyle(
                                  color: ascent,
                                  fontFamily: Poppins,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none
                            ),
                            onChanged: onChanged),),
                    const SizedBox(width: 16,),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // return Padding(
    //   padding: const EdgeInsets.symmetric(horizontal: 10),
    //   child: TextField(
    //       controller: controller,
    //       style: const TextStyle(color: ascent,fontFamily: Poppins,),
    //       cursorColor: ascent,
    //       decoration: const InputDecoration(
    //           fillColor: ascent,
    //           hintText: "Search",
    //           hintStyle: TextStyle(
    //             color: ascent,
    //             fontFamily: Poppins,
    //             fontSize: 16,
    //           ),
    //           border: InputBorder.none
    //       ),
    //       onChanged: onChanged),
    // );
  }
}
