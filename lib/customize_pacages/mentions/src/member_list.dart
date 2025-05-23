import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'mention_member_model.dart';

class MemberList extends StatelessWidget {
  final List<MentionMemberModel> data;
  final Function(MentionMemberModel) onTap;

  const MemberList({required this.onTap, required this.data, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: data.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Row(
              children: [
                SizedBox(width: 20,),
                CircleAvatar(
                  radius: 20,
                  backgroundImage: data[index].picture == null ||
                          data[index].picture!.isEmpty
                      ? null
                      : loadImage(data[index].picture!),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data[index].name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: primary,
                            fontFamily: Poppins
                        )),
                    SizedBox(height: 5,),
                    Text(data[index].uid,
                        style: TextStyle(
                            fontSize: 14,
                            color: ascent,
                            fontFamily: Poppins
                        )),
                  ],
                ),
                const SizedBox(width: 16),
                if(data[index].badge["document"] != "") InkWell(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(120)),
                    child: CachedNetworkImage(
                      imageUrl: data[index].badge["document"],
                      //imageUrl: lowestRankingOrderDocument,
                      imageBuilder:
                          (context, imageProvider) =>
                          Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              borderRadius:
                              const BorderRadius.all(
                                  Radius.circular(120)),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                      placeholder: (context, url) =>
                          Padding(
                            padding: const EdgeInsets.only(top:6.0),
                            child: SpinKitCircle(
                              color: primary,
                              size: 20,
                            ),
                          ),
                      errorWidget: (context, url,
                          error) =>
                          ClipRRect(
                              borderRadius:
                              const BorderRadius.all(
                                  Radius.circular(50)),
                              child: Image.network(
                                data[index].badge["document"],
                                width: 35,
                                height: 35,
                                fit: BoxFit.contain,
                              )),
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => onTap(data[index]),
            selectedColor: const Color(0xFFF5F5F6),
          );
        });
  }

  ImageProvider loadImage(String imagePath) {
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return NetworkImage(imagePath);
    } else {
      return AssetImage(imagePath);
    }
  }
}
