class SwapModel {
  final String userid;
  final List<dynamic> image;
  final String description;
  final String createdBy;
  final String style;
  final String profile;
  final String likes;
  final String dislikes;
  final String mylike;
  final bool isPrivate;
  final String id;
  final List<dynamic> fansList;
  final List<dynamic> followList;
  final String username;
  final String token;
  bool? addMeInFashionWeek;


  SwapModel(
       this.userid,
       this.image,
       this.description,
       this.createdBy,
        this.style,
        this.profile,
        this.likes,
        this.dislikes,
        this.mylike,
       this.isPrivate,
       this.id,
       this.fansList,
       this.followList,
       this.username,
       this.token,
       this.addMeInFashionWeek
      );
}