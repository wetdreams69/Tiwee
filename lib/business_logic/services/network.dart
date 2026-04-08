import 'dart:convert';
import 'package:tiwee/core/consts.dart';
import 'package:dio/dio.dart';
import 'package:tiwee/business_logic/model/channel.dart';

Future<List<ChannelObj>?> fetchChannels() async {
  List<ChannelObj> channels = [];

  try {
    Response response =
        await Dio().get(kPlaylistUrl);

    var responseData = response.data;
    if (responseData is String) {
      responseData = jsonDecode(responseData);
    }

    for (var channel in responseData) {
      ChannelObj channelObj = ChannelObj.fromJson(channel);

      // Si no tiene países pero la categoría es un país conocido, lo agregamos
      if (channelObj.countries.isEmpty) {
        for (var cat in channelObj.categories) {
          if (cat.name == "Argentina") {
            channelObj.countries.add(Country(name: "Argentina", code: "ar"));
          } else if (cat.name == "Uruguay") {
            channelObj.countries.add(Country(name: "Uruguay", code: "uy"));
          } else if (cat.name == "Paraguay") {
            channelObj.countries.add(Country(name: "Paraguay", code: "py"));
          }
        }
      }

      if (channelObj.categories.isNotEmpty) {
        if (channelObj.categories[0].name != "XXX") {
          channels.add(channelObj);
        }
      }
    }
    
    if (channels.isEmpty) return [];

    List<ChannelObj> repairChannels = channels.toSet().toList();

    return repairChannels;
  } catch (e) {
    print(e);
  }
  return null;
}
