// To parse this JSON data, do
//
//     final channelObj = channelObjFromJson(jsonString);

import 'dart:convert';

ChannelObj channelObjFromJson(String str) => ChannelObj.fromJson(json.decode(str));

String channelObjToJson(ChannelObj data) => json.encode(data.toJson());

class ChannelObj {
  ChannelObj({
    required this.name,
    required this.logo,
    required this.categories,
    required this.countries,
    required this.languages,
    required this.tvg,
    required this.streams,
  });

  String name;
  String logo;
  List<Category> categories;
  List<Country> countries;
  List<Country> languages;
  Tvg tvg;
  List<StreamObj> streams;

  factory ChannelObj.fromJson(Map<String, dynamic> json) => ChannelObj(
        name: json["name"] ?? "",
        logo: json["logo"] ?? "",
        categories: List<Category>.from(
            json["categories"].map((x) => Category.fromJson(x))),
        countries: List<Country>.from(
            json["countries"].map((x) => Country.fromJson(x))),
        languages: List<Country>.from(
            json["languages"].map((x) => Country.fromJson(x))),
        tvg: Tvg.fromJson(json["tvg"]),
        streams: json["streams"] != null
            ? List<StreamObj>.from(
                json["streams"].map((x) => StreamObj.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "logo": logo,
        "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
        "countries": List<dynamic>.from(countries.map((x) => x.toJson())),
        "languages": List<dynamic>.from(languages.map((x) => x.toJson())),
        "tvg": tvg.toJson(),
        "streams": List<dynamic>.from(streams.map((x) => x.toJson())),
      };
}

class StreamObj {
  StreamObj({
    required this.url,
    this.clearkey,
    this.headers,
  });

  String url;
  List<ClearKey>? clearkey;
  Map<String, String>? headers;

  factory StreamObj.fromJson(Map<String, dynamic> json) => StreamObj(
        url: json["url"] ?? "",
        clearkey: json["clearkey"] != null
            ? List<ClearKey>.from(
                json["clearkey"].map((x) => ClearKey.fromJson(x)))
            : null,
        headers: json["headers"] != null
            ? Map<String, String>.from(json["headers"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "clearkey": clearkey != null
            ? List<dynamic>.from(clearkey!.map((x) => x.toJson()))
            : null,
        "headers": headers,
      };
}

class ClearKey {
  ClearKey({
    required this.keyId,
    required this.key,
  });

  String keyId;
  String key;

  factory ClearKey.fromJson(Map<String, dynamic> json) => ClearKey(
        keyId: json["keyId"] ?? "",
        key: json["key"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "keyId": keyId,
        "key": key,
      };
}

class Category {
  Category({
    required this.name,
    required this.slug,
  });

  String name;
  String slug;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        name: json["name"] ?? "",
        slug: json["slug"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "slug": slug,
      };
}

class Country {
  Country({
    required this.name,
    required this.code,
  });

  String name;
  String code;

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        name: json["name"] ?? "",
        code: json["code"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "code": code,
      };
}

class Tvg {
  Tvg({
    this.id,
    this.name,
    this.url,
  });

  String? id;
  String? name;
  String? url;

  factory Tvg.fromJson(Map<String, dynamic> json) => Tvg(
        id: json["id"],
        name: json["name"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "url": url,
      };
}

