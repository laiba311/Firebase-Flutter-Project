import 'package:finalfashiontimefrontend/models/story_model.dart';

class PostModel {
  late String id;
  late String description;
  bool? addMeInFashionWeek;
  bool? isCommentEnabled;
  bool? isLikeEnabled;
  late List<dynamic> images;
  late String userName;
  late String userPic;
  late bool isVideo;
  late String likeCount;
  late String dislikeCount;
  late String commentCount;
  late String date;
  late String thumbnail;
  late String userid;
  late String mylike;
  late List<dynamic>? hashtags;
  late Map<String,dynamic> event;
  late Map<String,dynamic> topBadge;
  late List<Story>? recent_stories;
  late bool? show_stories_to_non_friends;
  late List<dynamic>? fanList;
  late List<dynamic>? followList;
  late List<dynamic>? close_friends;
  late bool? isPrivate;

  PostModel(
        this.id,
        this.description,
        this.images,
        this.userName,
        this.userPic,
        this.isVideo,
        this.likeCount,
        this.dislikeCount,
        this.commentCount,
        this.date,
       this.thumbnail,
       this.userid,
       this.mylike,
       this.event,
      this.topBadge,
      {
        this.addMeInFashionWeek,
        this.isCommentEnabled,
        this.isLikeEnabled,
        this.hashtags,
        this.recent_stories,
        this.show_stories_to_non_friends,
        this.fanList,
        this.followList,
        this.close_friends,
        this.isPrivate
      });
}