import 'dart:convert';

import 'package:finalfashiontimefrontend/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as https;
import '../../../models/story_model.dart';
import '../../../utils/constants.dart';

class CreateHightlights extends StatefulWidget {
  final String id;
  final String token;
  final int myIndex;
  final Function navigateTo;
  const CreateHightlights({super.key, required this.id, required this.token, required this.myIndex, required this.navigateTo});

  @override
  State<CreateHightlights> createState() => _CreateHightlightsState();
}

class _CreateHightlightsState extends State<CreateHightlights> {
  TextEditingController _highlightNameController = TextEditingController();
  List<int> selectedStories = [];
  bool isPostHighlight = false;
  List<Map<String,dynamic>> highlights = [];
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  List<Story> groupedStoriesList = [];
  List<Story> groupedStoriesList1 = [];
  String id = "";
  String token = "";
  bool isloading2 = false;

  addHighlight(String title,int id, List<int> stories) {
    const apiUrl = "$serverUrl/highlights/highlights/";
    if(_highlightNameController.text.isEmpty == true){
      setState(() {
        isPostHighlight = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: primary,
          title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
          content: const Text("Please fill all fields",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
    else if(selectedStories.length  <= 0){
      setState(() {
        isPostHighlight = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: primary,
          title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
          content: const Text("Please add at least one story to highlight",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
    else {
      try {
        https.post(
            Uri.parse(apiUrl),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer ${widget.token}",
            },
            body: json.encode({
              "title": title,
              "user_id": id,
              "story_ids": stories
            })
        ).then((value) {
          if (value.statusCode == 201) {
            setState(() {
              isPostHighlight = false;
            });
            Navigator.pop(context);
            Fluttertoast.showToast(
                msg: "Highlight Added", backgroundColor: primary);
          } else {
            setState(() {
              isPostHighlight = false;
            });
            Navigator.pop(context);
            Fluttertoast.showToast(
                msg: "Something went wrong", backgroundColor: primary);
            print("Error received while posting data =========> ${value.body
                .toString()}");
          }
        });
      } catch (e) {
        setState(() {
          isPostHighlight = false;
        });
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: "Something went wrong", backgroundColor: primary);
        print("Error Story -> ${e.toString()}");
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("token ==> ${widget.token}");
    print("id ==> ${widget.id}");
    getCashedData();
  }


  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(preferences.getString("fcm_token"));
    print("user id is----->>>${preferences.getString("id")}");
    getAllStories();
  }

  getAllStories() {
    setState(() {
      isloading2 = true;
    });
    const apiUrl = "$serverUrl/story/my-stories/";
    try {
      https.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).then((value) {
        if (value.statusCode == 200) {
          print("Entered Story 200 response");
          final body = utf8.decode(value.bodyBytes);
          final jsonData = jsonDecode(body);

          jsonData.forEach((element) {
            final User user = User(
              name: element['user']['name'],
              username: element['user']['username'],
              profileImageUrl: element['user']['pic'] ?? '',
              id: element['user']['id'].toString(),
            );

            // Create a story object for each element
            Story story = Story(
                duration: element["time_since_created"].toString(),
                url: element["content"],
                type:element["type"],
                user: user,
                storyId: element["id"],
                viewed_users: element["viewers"],
                created: element["created_at"],
                close_friends_only: element['close_friends_only'],
                isPrivate: element["is_user_private"],
                fanList: element["fansList"]
            );
            if (mounted) {
              setState(() {
                groupedStoriesList1.add(story);
              });
            }
          });
          setState(() {
            groupedStoriesList = List.from(groupedStoriesList1)
              ..sort((a, b) => DateTime.parse(b.created).compareTo(DateTime.parse(a.created)));
            isloading2 = false;
          });
        } else {
          setState(() {
            isloading2 = false;
          });
          print("Error received while getting all stories =========> ${value.body.toString()}");
        }
      });
    } catch (e) {
      setState(() {
        isloading2 = false;
      });
      print("Error Story -> ${e.toString()}");
    }
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
        //   backgroundColor: primary,
        //   title: const Text("Create Highlights",style: TextStyle(fontFamily: Poppins),),
        // ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10),
                // Highlight Name Input
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TextFormField(
                    style: TextStyle(fontFamily: Poppins),
                    controller: _highlightNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field cannot be empty';
                      }
                      return null;
                    },
                    cursorColor: primary,
                    decoration: InputDecoration(
                      labelStyle: TextStyle(color: ascent,fontFamily: Poppins),
                      labelText: 'Highlight Name',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),

                // Story Selection Grid
                isloading2 == true ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitRipple(color: primary,)
                      ],
                    )
                  ],
                ) : GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: groupedStoriesList.length,
                  itemBuilder: (context, index) {
                    final story = groupedStoriesList[index];
                    return StoryCard(
                      story: story,
                      isSelected: selectedStories.contains(story.storyId),
                      onSelected: (isSelected) {
                        setState(() {
                          if (isSelected) {
                            selectedStories.add(story.storyId);
                          } else {
                            selectedStories.remove(story.storyId);
                          }
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: isPostHighlight == true ? SpinKitCircle(color: primary,size: 12,) : Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black54, // Background color
                foregroundColor: Colors.white, // Text color
              ),
              onPressed: () {
                // Handle highlight creation here
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    isPostHighlight = true;
                  });
                  String highlightName = _highlightNameController.text;
                  print("Highlight Name: $highlightName");
                  print("Selected Stories: $selectedStories");
                  addHighlight(
                      highlightName, int.parse(widget.id), selectedStories);
                }
              },
              child: Text('Create Highlight',style: TextStyle(fontFamily: Poppins),),
            ),
          ),
        ),
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  final Story story;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  StoryCard({
    required this.story,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: Stack(
        children: [
          // Story display based on type
          Card(
            elevation: 5,
            child: _getStoryContent(story),
          ),
          // Checkbox overlay
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Checkbox(
                activeColor: primary,
                checkColor: ascent,
                value: isSelected,
                onChanged: (value) => onSelected(value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get appropriate story content widget based on the story type
  Widget _getStoryContent(Story story) {
    switch (story.type) {
      case 'text':
        return _buildTextStory(story);
      case 'image':
        return _buildImageStory(story);
      case 'video':
        return _buildVideoStory(story);
      default:
        return Center(child: Text('Unsupported story type'));
    }
  }

  // Widget for text stories
  Widget _buildTextStory(Story story) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              story.url,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,fontFamily: Poppins),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for image stories
  Widget _buildImageStory(Story story) {
    return Container(
      height: 500,
      width: 500,
      decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              story.url,
            ),
            fit: BoxFit.fill,
          )
      ),
      child: Text(""),
    );
  }

  // Widget for video stories
  Widget _buildVideoStory(Story story) {
    return VideoStoryCard(story: story);
  }
}

// Separate Video Story widget
class VideoStoryCard extends StatefulWidget {
  final Story story;

  VideoStoryCard({required this.story});

  @override
  _VideoStoryCardState createState() => _VideoStoryCardState();
}

class _VideoStoryCardState extends State<VideoStoryCard> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.story.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _controller.value.isInitialized
            ? Container(
          height: 200,
          width: 300,
          decoration: BoxDecoration(
            color: Colors.black, // Background color of the container
          ),
          clipBehavior: Clip.hardEdge, // Clip the child with the decoration
          child: VideoPlayer(
            _controller,
          ),
        )
            : Center(child: CircularProgressIndicator()),
        Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
