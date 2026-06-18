class CustomSound {
  final String id;
  final String name;
  final String filePath;

  const CustomSound({
    required this.id,
    required this.name,
    required this.filePath,
  });

  CustomSound copyWith({String? name, String? filePath}) => CustomSound(
        id: id,
        name: name ?? this.name,
        filePath: filePath ?? this.filePath,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'filePath': filePath,
      };

  factory CustomSound.fromMap(Map<String, dynamic> map) => CustomSound(
        id: map['id'] as String,
        name: map['name'] as String,
        filePath: map['filePath'] as String,
      );
}
