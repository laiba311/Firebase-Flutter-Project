import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';

import '../../../helpers/database_methods.dart';

class CallerScreen extends StatefulWidget {
  final String callRoomId;
  final String name;
  final String pic;
  final String email;
  const CallerScreen({Key? key, required this.callRoomId, required this.name, required this.pic, required this.email}) : super(key: key);

  @override
  State<CallerScreen> createState() => _CallerScreenState();
}

class _CallerScreenState extends State<CallerScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  endCall(chatRoomId){
    DatabaseMethods().endCallRoom(chatRoomId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(widget.pic),
          fit: BoxFit.fill,
        ),
      ),
      child: WillPopScope(
        onWillPop: () async {
          print('The user tries to pop()');
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: const SizedBox(),
            centerTitle: true,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            title: const Text("",style: TextStyle(fontFamily: Poppins),),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top:20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        widget.name,
                       style: const TextStyle(
                         fontSize: 36,
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                           fontFamily: Poppins
                       ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom:MediaQuery.of(context).size.height * 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 5,),
                    GestureDetector(
                      onTap: (){
                        endCall(widget.callRoomId);
                      },
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.call_end,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.phone,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 5,),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
