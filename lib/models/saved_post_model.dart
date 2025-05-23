class SavedPostModel {
  late String id;
  late String description;
  bool? addMeInFashionWeek;
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
  late int saveId;


  SavedPostModel(

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
      this.saveId,
      {
        this.addMeInFashionWeek,
      }
      );

}