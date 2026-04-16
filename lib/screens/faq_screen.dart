import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _expanded;

  static const _faqs = [
    (
      q: 'Apa itu SIGAP Medan?',
      a:
          'SIGAP Medan (Sistem Informasi Gotong-royong dan Pengaduan) adalah aplikasi pelaporan kerusakan jalan dan infrastruktur kota Medan berbasis komunitas. Warga dapat melaporkan kerusakan, memantau progres penanganan, dan mendapatkan poin reward atas kontribusi mereka.',
    ),
    (
      q: 'Bagaimana cara melaporkan jalan rusak?',
      a:
          'Buka tab "Laporan" → ketuk tombol "+" → isi deskripsi kerusakan → tambahkan foto → izinkan akses lokasi agar koordinat otomatis terdeteksi → kirim laporan. Kamu akan langsung mendapatkan +5 Poin Horas.',
    ),
    (
      q: 'Apa itu Poin Horas dan bagaimana cara mendapatkannya?',
      a:
          'Poin Horas adalah sistem reward gamifikasi di SIGAP Medan.\n\n• +5 poin setiap kali kamu mengirim laporan baru\n• +20 poin ketika laporan kamu dinyatakan selesai/terselesaikan\n• -10 poin jika laporan kamu dihapus karena dianggap spam\n\nPoin dapat ditukarkan dengan berbagai hadiah di menu Katalog.',
    ),
    (
      q: 'Apa itu fitur Jejak Kesawan?',
      a:
          'Jejak Kesawan adalah fitur check-in wisata di Kota Medan. Kunjungi destinasi wisata, check-in saat berada dalam radius lokasi, dan kumpulkan XP untuk naik level. Setiap check-in terverifikasi memberikan XP dan menambahkan destinasi ke koleksi kunjunganmu.',
    ),
    (
      q: 'Berapa radius GPS yang dibutuhkan untuk check-in?',
      a:
          'Kamu harus berada dalam radius 300 meter dari koordinat resmi destinasi agar check-in dapat diverifikasi. Pastikan GPS aktif dan koneksi internet stabil saat melakukan check-in.',
    ),
    (
      q: 'Bagaimana cara menukarkan Poin Horas?',
      a:
          'Buka tab "Poin Horas" → pilih tab "Katalog" → pilih hadiah yang diinginkan → ketuk tombol "Tukar" → konfirmasi penukaran. Poin akan otomatis dipotong dan transaksi tercatat di tab "Riwayat".',
    ),
    (
      q: 'Bagaimana sistem level di SIGAP Medan?',
      a:
          'Level ditentukan oleh akumulasi XP dari check-in dan aktivitas di aplikasi:\n\n• Pemula: 0–199 XP\n• Penjelajah: 200–499 XP\n• Relawan: 500–999 XP\n• Detektif Kota: 1.000–1.999 XP\n• Penjaga Kota: 2.000+ XP',
    ),
    (
      q: 'Apakah laporan saya akan ditindaklanjuti?',
      a:
          'Laporan yang masuk akan ditinjau oleh admin SIGAP Medan dan diteruskan ke dinas terkait. Status laporan akan diperbarui dari "Menunggu" → "Diproses" → "Selesai". Kamu akan mendapatkan notifikasi setiap ada perubahan status.',
    ),
    (
      q: 'Bagaimana jika laporan saya dihapus?',
      a:
          'Admin dapat menghapus laporan yang dianggap tidak sesuai, duplikat, atau spam. Alasan penghapusan akan ditampilkan di detail laporan. Penghapusan laporan spam akan memotong 10 Poin Horas dari akunmu.',
    ),
    (
      q: 'Bagaimana cara menghubungi tim SIGAP Medan?',
      a:
          'Untuk pertanyaan lebih lanjut, hubungi kami melalui:\n\n• Email: sigap.medan@gmail.com\n• Instagram: @sigapmedan\n• Atau melalui fitur "Tentang Aplikasi" di menu Profil.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FAQ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.helpCircle,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pertanyaan Umum',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ketuk pertanyaan untuk melihat jawaban',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_faqs.length, (i) {
            final faq = _faqs[i];
            final isOpen = _expanded == i;
            return _FaqTile(
              question: faq.q,
              answer: faq.a,
              isOpen: isOpen,
              isDark: isDark,
              onTap: () => setState(() => _expanded = isOpen ? null : i),
            );
          }),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool isOpen;
  final bool isDark;
  final VoidCallback onTap;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isOpen,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOpen
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : (isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E7EB)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.helpCircle,
                          size: 14, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: isOpen
                            ? const Color(0xFF10B981)
                            : (isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ],
                ),
                if (isOpen) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    answer,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: isDark
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
