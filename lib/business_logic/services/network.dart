import 'dart:convert';
import 'package:tiwee/core/consts.dart';
import 'package:dio/dio.dart';
import 'package:tiwee/business_logic/model/channel.dart';

Future<List<ChannelObj>?> fetchChannels() async {
  List<ChannelObj> channels = [];

  try {
    Response response =
        await Dio().get(kPlaylistUrl);
    print("enzo");
    print(response.toString());

    var responseData = response.data;
    if (responseData is String) {
      responseData = jsonDecode(responseData);
    }

    for (var channel in responseData) {
      ChannelObj channelObj = ChannelObj.fromJson(channel);

      if (channelObj.categories.isNotEmpty) {
        if (channelObj.categories[0].name != "XXX") {
          channels.add(channelObj);

        }
      }
    }
    print("salmm");

    print(channels[0].countries[0].name);
    List<ChannelObj> repairChannels = channels.toSet().toList();

    return repairChannels;
  } catch (e) {
    print(e);
  }
  return null;
}
