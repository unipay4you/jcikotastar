class ProgramFolder {
  final String id;
  final String name;
  final String? programImage;
  List<ProgramImage> images;

  ProgramFolder({
    required this.id,
    required this.name,
    this.programImage,
    this.images = const [],
  });

  factory ProgramFolder.fromJson(Map<String, dynamic> json) {
    return ProgramFolder(
      id: json['id'],
      name: json['name'],
      programImage: json['programImage'],
      images: (json['images'] as List?)
              ?.map((image) => ProgramImage.fromJson(image))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'programImage': programImage,
      'images': images.map((image) => image.toJson()).toList(),
    };
  }
}

class ProgramImage {
  final String id;
  final String url;
  final String programId;
  final DateTime createdAt;

  ProgramImage({
    required this.id,
    required this.url,
    required this.programId,
    required this.createdAt,
  });

  factory ProgramImage.fromJson(Map<String, dynamic> json) {
    return ProgramImage(
      id: json['id'],
      url: json['url'],
      programId: json['program_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'program_id': programId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
