import 'package:finalfashiontimefrontend/models/user_model.dart';

enum MediaType {
  image,
  video,
  text
}
class Story {
  var url;
  final String type;
  final User user;
  var viewedBy;
  var uploadObject;
  var closeFriend;
  final int storyId;
  final String duration;
  final String created;
  final List<dynamic> viewed_users;
  final bool close_friends_only;
  final bool isPrivate;
  final List<dynamic> fanList;

   Story({
     required this.duration,
    required this.url,
    required this.type,
    required this.user,
    this.viewedBy,
     this.uploadObject,
     this.closeFriend,
     required this.storyId,
     required this.created,
     required this.viewed_users,
     required this.close_friends_only,
     required this.isPrivate,
     required this.fanList
   });
}