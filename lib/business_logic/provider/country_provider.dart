import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:tiwee/business_logic/provider/channel_provider.dart';

final countryProvider =
    Provider<AsyncValue<Map<String, List<ChannelObj>>>>((ref) {
  Map<String, List<ChannelObj>> sortedByCountry = {};

  final channels = ref.watch(mainChannels);

  return channels.when(
    data: (value) {
      if (value == null) return AsyncValue.data(sortedByCountry);
      int x = 0;
      for (ChannelObj channel in value) {

        if (channel.countries.isNotEmpty) {
          x++;

          for (Country element in channel.countries) {
            if (element.name != "") {
              sortedByCountry[element.name] = [
                ...?sortedByCountry[element.name],
                channel
              ];
            }
          }
        }
      }
      return AsyncValue.data(sortedByCountry);
    },
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    loading: AsyncValue.loading,
  );
});
