import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as https;
import '../../../models/story_model.dart';
import '../../../utils/constants.dart';
import '../../models/user_model.dart';

class EditHightlights extends StatefulWidget {
  final List<Story> groupedStoriesList;
  final String id;
  final String userID;
  final String token;
  final String title;
  final List<int> selectedStories;
  const EditHightlights({super.key, required this.groupedStoriesList, required this.id, required this.token, required this.selectedStories, required this.title, required this.userID});

  @override
  State<EditHightlights> createState() => _EditHightlightsState();
}

class _EditHightlightsState extends State<EditHightlights> {
  TextEditingController _highlightNameController = TextEditingController();
  bool isPostHighlight = false;
  List<Map<String,dynamic>> highlights = [];
  bool isLoading = false;
  List<Story> groupedStoriesList = [];
  List<Story> groupedStoriesList1 = [];
  String id = "";
  String token = "";
  bool isloading2 = false;

  updateHighlight(String title,String id, List<int> stories,String user_id) {
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
    else if(stories.length  <= 0){
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
      print("stories ${stories}");
      var apiUrl = "$serverUrl/highlights/highlights/${id}/";
      try {
        https.patch(
            Uri.parse(apiUrl),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer ${widget.token}",
            },
            body: json.encode({
              "title": title,
              "user_id": user_id,
              "story_ids": stories
            })
        ).then((value) {
          if (value.statusCode == 200) {
            setState(() {
              isPostHighlight = false;
            });
            Navigator.pop(context);
            Navigator.pop(context);
            Fluttertoast.showToast(
                msg: "Highlight Updated", backgroundColor: primary);
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
    _highlightNameController.text = widget.title;
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
                  ])
          ),),
        backgroundColor: primary,
        title: const Text("Edit Highlights",style: TextStyle(fontFamily: Poppins),),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            // Highlight Name Input
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TextField(
                controller: _highlightNameController,
                cursorColor: primary,
                style: TextStyle(fontFamily: Poppins),
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: ascent,fontFamily: Poppins),
                  labelText: 'Highlight Name',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primary, width: 2),
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
                  isSelected: widget.selectedStories.contains(story.storyId),
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        widget.selectedStories.add(story.storyId);
                      } else {
                        widget.selectedStories.remove(story.storyId);
                      }
                    });
                  },
                );
              },
            ),
          ],
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
              setState((){
                isPostHighlight = true;
              });
              String highlightName = _highlightNameController.text;
              print("Highlight Name: $highlightName");
              print("Selected Stories: ${widget.selectedStories}");
              updateHighlight(_highlightNameController.text, widget.id,widget.selectedStories,widget.userID);
            },
            child: Text('Edit Highlight',style: TextStyle(fontFamily: Poppins),),
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
        children: [
          Center(
            child: Text(
              story.url,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
