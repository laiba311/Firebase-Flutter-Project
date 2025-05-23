
import 'package:finalfashiontimefrontend/models/story_model.dart';

class SearchModel {
  late String id;
  late String name;
  late String pic;
  late String email;
  late String username;
  late String fcmToken;
  late Map<String,dynamic> badge;
  late List<Story> most_recent_story;
  late List<dynamic> close_friends;
  late bool show_stories_to_non_friends;
  late List<dynamic> fanList;
  late List<dynamic> friendList;

  SearchModel(
      this.id,
      this.name,
      this.pic,
      this.email,
      this.username,
      this.fcmToken,
      this.badge,
      this.most_recent_story,
      this.close_friends,
      this.show_stories_to_non_friends,
      this.fanList,
      this.friendList
      );
}

