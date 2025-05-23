class MentionMemberModel {
  final String id;
  final String uid;
  final String name;
  late final String nameForMention;
  final String? picture;
  final Map<String, dynamic> badge;

  MentionMemberModel({
    required this.id,
    required this.uid,
    required this.name,
    this.picture,
    required this.badge
  }) {
    nameForMention = name.replaceAllMapped(' ', (match) => '_');
  }
}