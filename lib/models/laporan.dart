class Laporan {
  final int? id;
  final String judul;
  final String deskripsi;
  final double latitude;
  final double longitude;
  final String? fotoPath;
  final String createdAt;

  Laporan({
    this.id,
    required this.judul,
    required this.deskripsi,
    required this.latitude,
    required this.longitude,
    this.fotoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'judul': judul,
    'deskripsi': deskripsi,
    'latitude': latitude,
    'longitude': longitude,
    'foto_path': fotoPath,
    'created_at': createdAt,
  };

  factory Laporan.fromMap(Map<String, dynamic> map) => Laporan(
    id: map['id'],
    judul: map['judul'],
    deskripsi: map['deskripsi'],
    latitude: map['latitude'],
    longitude: map['longitude'],
    fotoPath: map['foto_path'],
    createdAt: map['created_at'],
  );
}