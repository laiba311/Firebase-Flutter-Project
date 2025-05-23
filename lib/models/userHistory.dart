import 'package:finalfashiontimefrontend/models/story_model.dart';

class UserHistory {
  late String historyID;
  late String id;
  late String name;
  late String username;
  late String image;
  late List<Story> most_recent_story;
  late List<dynamic> close_friends;
  late List<dynamic> fanList;
  late List<dynamic> followList;
  late bool show_stories_to_non_friends;

  UserHistory(
        this.historyID,
        this.id,
        this.name,
        this.username,
        this.image,
        this.most_recent_story,
        this.close_friends,
      this.fanList,
      this.followList,
      this.show_stories_to_non_friends
      );
}