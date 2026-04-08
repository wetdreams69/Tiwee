import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:tiwee/business_logic/provider/channel_Provider.dart';
import 'package:tiwee/business_logic/provider/country_code.dart';
import 'package:tiwee/core/consts.dart';

import 'channel_card_provider.dart';

final categoryProvider =
    Provider<AsyncValue<Map<String, List<ChannelObj>>>>((ref) {
  Map<String, List<ChannelObj>> sortedByCategory = {};
  kCategoryType.forEach((key, value) {
    sortedByCategory[key] = [];
  });

  final channels = ref.watch(mainChannels);
  final categoriesChannels = ref.watch(channelCardProvider.state);
  final countryCode = ref.watch(countryCodeProvider.state);

  return channels.when(
    data: (value) {
      if (value == null) return AsyncValue.data(sortedByCategory);

      // Limpiar contadores previos
      for (var element in categoriesChannels.state) {
        element.channelCount = 0;
      }

      int totalChannels = value.length;

      for (ChannelObj channel in value) {
        // Procesar Países para el filtro
        if (channel.countries.isNotEmpty) {
          for (var element in channel.countries) {
            countryCode.state[element.name] = element.code;
          }
        }

        // Procesar Categorías Dinámicamente
        if (channel.categories.isNotEmpty) {
          for (var category in channel.categories) {
            final categoryName = category.name;

            // Inicializar lista si no existe
            if (!sortedByCategory.containsKey(categoryName)) {
              sortedByCategory[categoryName] = [];
            }
            sortedByCategory[categoryName]!.add(channel);

            // Actualizar contador en el provider de tarjetas (UI)
            for (var card in categoriesChannels.state) {
              if (card.name == categoryName) {
                card.channelCount++;
              }
            }
          }
        } else {
          // Si no tiene categorías, lo mandamos a "Other"
          if (!sortedByCategory.containsKey("Other")) {
            sortedByCategory["Other"] = [];
          }
          sortedByCategory["Other"]!.add(channel);
        }
      }

      // Actualizar el conteo de "Live Tv" (Total)
      for (var element in categoriesChannels.state) {
        if (element.name == "Live Tv") {
          element.channelCount = totalChannels;
        }
      }
      
      // Agregar categoría especial con todos los canales
      sortedByCategory["Live Tv"] = value;

      return AsyncValue.data(sortedByCategory);
    },
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    loading: AsyncValue.loading,
  );
});
