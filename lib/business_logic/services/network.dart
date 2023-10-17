import 'package:dio/dio.dart';
import 'package:Tiwee/business_logic/model/channel.dart';

Future<List<ChannelObj>?> fetchChannels() async {
  List<ChannelObj> channels = [];

  try {
    Response response =
        await Dio().get('https://raw.githubusercontent.com/wetdreams69/iptv_argentina/main/playlist.json');
    print("enzo");
    print(response.toString());
    for (var channel in response.data) {
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
