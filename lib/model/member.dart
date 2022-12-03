class Member {
  double lat;
  double lng;
  int timestampInMs;
  String name;
  String id;
  String url;

  Member(
      {required this.lat,
      required this.lng,
      required this.id,
      required this.timestampInMs,
      required this.name,
      required this.url});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
        id: json['id'] as String,
        lat: json['lat'] as double,
        lng: json['lng'] as double,
        timestampInMs: json['timestampInMs'] as int,
        name: json['name'] as String,
        url: json['url'] as String);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': lat,
      'lng': lng,
      'timestampInMs': timestampInMs,
      'name': name,
      'url': url
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          runtimeType == other.runtimeType &&
          lat == other.lat &&
          lng == other.lng &&
          timestampInMs == other.timestampInMs &&
          name == other.name &&
          id == other.id &&
          url == other.url;

  @override
  int get hashCode =>
      lat.hashCode ^
      lng.hashCode ^
      timestampInMs.hashCode ^
      name.hashCode ^
      id.hashCode ^
      url.hashCode;
}
