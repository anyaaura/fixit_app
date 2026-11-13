class ServiceItem {
  final int? id;
  final String namaPelanggan;
  final String nomorHp;
  final String perangkat;
  final String merekPerangkat;
  final String modelPerangkat;
  final String deskripsi;
  final String tanggalMasuk;
  final double biaya;
  final String statusProgres;
  final String statusBayar;

  ServiceItem({
    this.id,
    required this.namaPelanggan,
    required this.nomorHp,
    required this.perangkat,
    required this.merekPerangkat,
    required this.modelPerangkat,
    required this.deskripsi,
    required this.tanggalMasuk,
    required this.biaya,
    this.statusProgres = 'Menunggu Pengecekan',
    this.statusBayar = 'Belum Lunas',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_pelanggan': namaPelanggan,
      'nomor_hp': nomorHp,
      'jenis_perangkat': perangkat,
      'merek': merekPerangkat,
      'model_tipe': modelPerangkat,
      'keluhan_kerusakan': deskripsi,
      'tanggal_masuk': tanggalMasuk,
      'estimasi_biaya': biaya,
      'status_progres': statusProgres,
      'status_bayar': statusBayar,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'],
      // Mendukung nama kolom dari Supabase maupun format lama
      namaPelanggan: map['nama_pelanggan'] ?? map['namaPelanggan'] ?? '',
      nomorHp: map['nomor_hp'] ?? map['nomorHp'] ?? '',
      perangkat: map['jenis_perangkat'] ?? map['perangkat'] ?? '',
      merekPerangkat: map['merek'] ?? map['merekPerangkat'] ?? '',
      modelPerangkat: map['model_tipe'] ?? map['modelPerangkat'] ?? '',
      deskripsi: map['keluhan_kerusakan'] ?? map['deskripsi'] ?? '',
      tanggalMasuk: map['tanggal_masuk'] ?? map['tanggalMasuk'] ?? '',
      biaya: ((map['estimasi_biaya'] ?? map['biaya'] ?? 0) as num).toDouble(),
      statusProgres: map['status_progres'] ?? map['statusProgres'] ?? 'Menunggu Pengecekan',
      statusBayar: map['status_bayar'] ?? map['statusBayar'] ?? 'Belum Lunas',
    );
  }
}