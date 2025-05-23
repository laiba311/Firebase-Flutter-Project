class ChatModel {
  late String id;
  late String name;
  late String pic;
  late String email;
  late String username;
  late String fcmToken;
  bool? isfan;
  bool? isCloseFriend;
  Map<String,dynamic>? badge;
  String? favouriteId;
  bool? isPrivate;
  List<dynamic>? fanList;
  String? fanID;
  List<dynamic>? followList;

  ChatModel(
      this.id,
      this.name,
      this.pic,
      this.email,
      this.username,
      this.fcmToken,
      {
        this.isfan,
        this.isCloseFriend,
        this.badge,
        this.favouriteId,
        this.isPrivate,
        this.fanList,
        this.fanID,
        this.followList
      }
      );
}

List<ChatModel> chatsList = [
];