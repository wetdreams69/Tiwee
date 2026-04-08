
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:tiwee/business_logic/provider/channel_provider.dart';

final languageProvider =
    Provider<AsyncValue<Map<String, List<ChannelObj>>>>((ref) {
  final channels = ref.watch(mainChannels);
  Map<String, List<ChannelObj>> sortedByLanguage = {};
  return channels.when(
    data: (value) {
      for (ChannelObj channelObj in value!) {
        if (channelObj.languages.isNotEmpty) {
          sortedByLanguage.keys.contains(channelObj.languages[0].name)
              ? null
              : sortedByLanguage[channelObj.languages[0].name] = [];
          sortedByLanguage[channelObj.languages[0].name]?.add(channelObj);
        }
      }
      return AsyncValue.data(sortedByLanguage);
    },
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    loading: AsyncValue.loading,
  );
});
