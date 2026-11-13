import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'service_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qbvhuypfhnsymacprzij.supabase.co',
    anonKey: 'sb_publishable_NSB5UOZw8zhoZoDZ2kEpxA_J44p6mVX',
  );

  runApp(const FixItApp());
}

class FixItApp extends StatelessWidget {
  const FixItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixIT Servis Laptop & HP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFEFEFF9),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ServiceItem>> _serviceList;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Mengambil data secara Hybrid (Supabase -> Fallback ke SQLite)
  void _refreshData() {
    setState(() {
      _serviceList = _fetchServicesHybrid();
    });
  }

  Future<List<ServiceItem>> _fetchServicesHybrid() async {
    try {
      final response = await Supabase.instance.client
          .from('services records')
          .select()
          .order('id', ascending: false);

      return (response as List).map((map) => ServiceItem.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Offline/Error Supabase, mengambil dari SQLite lokal: $e');
      return await DatabaseHelper.instance.getAllServices();
    }
  }

  // Pencarian secara Hybrid
  void _searchData(String query) async {
    setState(() {
      _serviceList = _searchServicesHybrid(query);
    });
  }

  Future<List<ServiceItem>> _searchServicesHybrid(String query) async {
    if (query.isEmpty) {
      return _fetchServicesHybrid();
    }
    try {
      final response = await Supabase.instance.client
          .from('services records')
          .select()
          .or('nama_pelanggan.ilike.%$query%,merek.ilike.%$query%,jenis_perangkat.ilike.%$query%');
      return (response as List).map((map) => ServiceItem.fromMap(map)).toList();
    } catch (e) {
      return await DatabaseHelper.instance.searchServices(query);
    }
  }

  void _openAddServiceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddServiceModal(onSave: () {
        _refreshData();
      }),
    );
  }

  void _openDetailCard(ServiceItem item) {
    showDialog(
      context: context,
      builder: (context) => DetailProgressDialog(
        item: item,
        onStatusChanged: () {
          _refreshData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF4A89DC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FixIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Servis Laptop & HP (Hybrid Online/Offline)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.build_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _searchData,
                  decoration: InputDecoration(
                    hintText: 'Cari nama pelanggan, perangkat, merek...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ServiceItem>>(
              future: _serviceList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Belum ada catatan servis.\nTekan tombol "+ Tambah Servis" di bawah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  );
                }

                final data = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final isLunas = item.statusBayar == 'Lunas';
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.devices, color: Colors.blue),
                        ),
                        title: Text(
                          item.namaPelanggan,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${item.perangkat}: ${item.merekPerangkat} ${item.modelPerangkat}'),
                            Text('No. HP: ${item.nomorHp}'),
                            Row(
                              children: [
                                Text('Status: ${item.statusProgres}',
                                    style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isLunas ? Colors.green.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.statusBayar,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isLunas ? Colors.green.shade800 : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _openDetailCard(item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddServiceModal,
        backgroundColor: const Color(0xFF4A89DC),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Servis'),
      ),
    );
  }
}

class AddServiceModal extends StatefulWidget {
  final VoidCallback onSave;
  const AddServiceModal({super.key, required this.onSave});

  @override
  State<AddServiceModal> createState() => _AddServiceModalState();
}

class _AddServiceModalState extends State<AddServiceModal> {
  final _namaController = TextEditingController();
  final _nomorHpController = TextEditingController();
  String _jenisPerangkat = 'Laptop';
  final _merekController = TextEditingController();
  final _modelController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _tanggalController = TextEditingController(
    text: DateTime.now().toString().split(' ')[0],
  );
  final _biayaController = TextEditingController();

  void _simpanData() async {
    await simpanDataServis(
      namaPelanggan: _namaController.text.isEmpty ? 'Tanpa Nama' : _namaController.text,
      nomorHp: _nomorHpController.text,
      jenisPerangkat: _jenisPerangkat,
      merek: _merekController.text,
      modelTipe: _modelController.text,
      keluhanKerusakan: _deskripsiController.text.isEmpty ? '-' : _deskripsiController.text,
      tanggalMasuk: _tanggalController.text,
      estimasiBiaya: double.tryParse(_biayaController.text) ?? 0.0,
      statusProgres: 'Menunggu Pengecekan',
      statusBayar: 'Belum Lunas',
      context: context,
    );

    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tambah Catatan Servis Baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nomorHpController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _jenisPerangkat,
              items: ['Laptop', 'HP'].map((val) {
                return DropdownMenuItem(value: val, child: Text(val));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _jenisPerangkat = val!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Jenis Perangkat',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _merekController,
                    decoration: const InputDecoration(
                      labelText: 'Merek (contoh: ASUS, Oppo)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model / Tipe',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deskripsiController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Keluhan / Kerusakan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tanggalController,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Masuk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _biayaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Estimasi Biaya (Rp)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A89DC),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _simpanData,
                child: const Text(
                  'Simpan ke Database',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailProgressDialog extends StatefulWidget {
  final ServiceItem item;
  final VoidCallback onStatusChanged;

  const DetailProgressDialog({super.key, required this.item, required this.onStatusChanged});

  @override
  State<DetailProgressDialog> createState() => _DetailProgressDialogState();
}

class _DetailProgressDialogState extends State<DetailProgressDialog> {
  late String _currentStatus;
  late String _currentBayar;

  final List<String> _statusList = [
    'Menunggu Pengecekan',
    'Sedang Diperbaiki',
    'Selesai Servis',
    'Sudah Diambil'
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.item.statusProgres;
    _currentBayar = widget.item.statusBayar;
  }

  void _updateStatus(String newStatus) async {
    setState(() {
      _currentStatus = newStatus;
    });

    try {
      await Supabase.instance.client
          .from('services records')
          .update({'status_progres': newStatus})
          .eq('id', widget.item.id!);
    } catch (_) {
      if (widget.item.id != null) {
        await DatabaseHelper.instance.updateStatus(widget.item.id!, newStatus);
      }
    }
    widget.onStatusChanged();
  }

  void _prosesBayarDanNota() async {
    setState(() {
      _currentBayar = 'Lunas';
    });

    try {
      await Supabase.instance.client
          .from('services records')
          .update({'status_bayar': 'Lunas'})
          .eq('id', widget.item.id!);
    } catch (_) {
      if (widget.item.id != null) {
        await DatabaseHelper.instance.updatePaymentStatus(widget.item.id!, 'Lunas');
      }
    }
    widget.onStatusChanged();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.receipt_long, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NOTA PEMBAYARAN FIXIT',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('----------------------------------------', style: TextStyle(color: Colors.grey)),
              Text('Pelanggan : ${widget.item.namaPelanggan}'),
              Text('No. HP    : ${widget.item.nomorHp}'),
              Text('Perangkat : ${widget.item.perangkat} (${widget.item.merekPerangkat} ${widget.item.modelPerangkat})'),
              Text('Keluhan   : ${widget.item.deskripsi}'),
              Text('Tanggal   : ${widget.item.tanggalMasuk}'),
              const Text('----------------------------------------', style: TextStyle(color: Colors.grey)),
              Text('Total Biaya : Rp ${widget.item.biaya.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('Status Bayar: LUNAS',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const Text('----------------------------------------', style: TextStyle(color: Colors.grey)),
              const Center(
                child: Text('Terima Kasih Telah Servis di FixIT!',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Tutup & Selesai', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _hapusData() async {
    try {
      await Supabase.instance.client
          .from('services records')
          .delete()
          .eq('id', widget.item.id!);
    } catch (_) {
      if (widget.item.id != null) {
        await DatabaseHelper.instance.deleteService(widget.item.id!);
      }
    }
    widget.onStatusChanged();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLunas = _currentBayar == 'Lunas';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Detail & Kartu Progres Servis'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('Nama Pelanggan', widget.item.namaPelanggan),
            const Divider(),
            _buildInfoRow('Nomor HP', widget.item.nomorHp),
            const Divider(),
            _buildInfoRow('Perangkat', '${widget.item.perangkat} ${widget.item.merekPerangkat} ${widget.item.modelPerangkat}'),
            const Divider(),
            _buildInfoRow('Keluhan / Kerusakan', widget.item.deskripsi),
            const Divider(),
            _buildInfoRow('Tanggal Masuk', widget.item.tanggalMasuk),
            const Divider(),
            _buildInfoRow('Estimasi Biaya', 'Rp ${widget.item.biaya.toStringAsFixed(0)}'),
            const Divider(),
            _buildInfoRow('Status Pembayaran', _currentBayar,
                valueColor: isLunas ? Colors.green : Colors.orange),
            const SizedBox(height: 12),
            const Text(
              'Status Progres Saat Ini:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _statusList.contains(_currentStatus) ? _currentStatus : _statusList[0],
              items: _statusList.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _updateStatus(val);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            if (!isLunas)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _prosesBayarDanNota,
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text('Bayar & Cetak Nota',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _hapusData,
          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: valueColor ?? Colors.black87,
              )),
        ],
      ),
    );
  }
}

Future<void> simpanDataServis({
  required String namaPelanggan,
  required String nomorHp,
  required String jenisPerangkat,
  required String merek,
  required String modelTipe,
  required String keluhanKerusakan,
  required String tanggalMasuk,
  required double estimasiBiaya,
  required String statusProgres,
  required String statusBayar,
  required BuildContext context,
}) async {
  try {
    // 1. Coba simpan ke Supabase terlebih dahulu
    await Supabase.instance.client.from('services records').insert({
      'nama_pelanggan': namaPelanggan,
      'nomor_hp': nomorHp,
      'jenis_perangkat': jenisPerangkat,
      'merek': merek,
      'model_tipe': modelTipe,
      'keluhan_kerusakan': keluhanKerusakan,
      'tanggal_masuk': tanggalMasuk,
      'estimasi_biaya': estimasiBiaya,
      'status_progres': statusProgres,
      'status_bayar': statusBayar,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil menyimpan data ke Supabase!')),
      );
      Navigator.of(context).pop();
    }
  } catch (error) {
    // 2. Jika offline/gagal, otomatis simpan cadangan ke SQLite lokal
    try {
      final localItem = ServiceItem(
        namaPelanggan: namaPelanggan,
        nomorHp: nomorHp,
        perangkat: jenisPerangkat,
        merekPerangkat: merek,
        modelPerangkat: modelTipe,
        deskripsi: keluhanKerusakan,
        tanggalMasuk: tanggalMasuk,
        biaya: estimasiBiaya,
        statusProgres: statusProgres,
        statusBayar: statusBayar,
      );
      await DatabaseHelper.instance.insertService(localItem);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mode Offline: Data disimpan ke SQLite lokal!')),
        );
        Navigator.of(context).pop();
      }
    } catch (localError) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $localError')),
        );
      }
    }
  }
}