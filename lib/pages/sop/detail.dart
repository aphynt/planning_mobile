part of '../pages.dart';

class SOPDetailPage extends StatefulWidget {
  final String uuid;

  const SOPDetailPage({Key? key, required this.uuid}) : super(key: key);

  @override
  State<SOPDetailPage> createState() => _SOPDetailPageState();
}

class _SOPDetailPageState extends State<SOPDetailPage> {
  late Future<Uint8List> _pdfBytesFuture;
  String? fileTitle;

  @override
  void initState() {
    super.initState();
    _pdfBytesFuture = _getPdfBytes();
  }

  Future<Uint8List> _getPdfBytes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      // 1. PANGGIL API UNTUK DAPATKAN URL
      final metaResponse = await http.get(
        Uri.parse('$baseUrl/api/sop/file/${widget.uuid}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("STATUS FETCH SOP: ${metaResponse.statusCode}");
      debugPrint("BODY FETCH SOP: ${metaResponse.body}");

      if (metaResponse.statusCode != 200) {
        throw Exception(
          "Gagal memuat metadata SOP (${metaResponse.statusCode}) : ${metaResponse.body}",
        );
      }

      final data = jsonDecode(metaResponse.body);
      if (data is! Map<String, dynamic> ||
          data['data'] is! Map<String, dynamic>) {
        throw Exception("Format response API tidak sesuai");
      }

      final inner = data['data'] as Map<String, dynamic>;

      String? rawUrl = inner['url'];
      if (rawUrl == null || rawUrl.isEmpty) {
        throw Exception("URL file PDF tidak ditemukan di response API");
      }
      fileTitle = inner['namaFile'] ?? "Detail SOP";
      setState(() {});

      // Encode supaya spasi & karakter khusus aman
      final encodedUrl = Uri.encodeFull(rawUrl);
      debugPrint('FINAL PDF URL: $encodedUrl');

      // 2. DOWNLOAD FILE PDF-NYA
      final pdfResponse = await http.get(Uri.parse(encodedUrl));

      debugPrint('STATUS FETCH PDF: ${pdfResponse.statusCode}');
      debugPrint('CONTENT-LENGTH: ${pdfResponse.contentLength}');
      debugPrint('CONTENT-TYPE: ${pdfResponse.headers['content-type']}');

      if (pdfResponse.statusCode != 200) {
        throw Exception(
          "Gagal mengambil file PDF (${pdfResponse.statusCode})",
        );
      }

      final bytes = pdfResponse.bodyBytes;

      // Cek beberapa byte pertama, harusnya mulai dengan '%PDF'
      if (bytes.length >= 4) {
        final header = String.fromCharCodes(bytes.sublist(0, 4));
        debugPrint('PDF HEADER BYTES: $header');
        if (!header.startsWith('%PDF')) {
          // Berarti yang diterima kemungkinan HTML / error page
          debugPrint('WARNING: file bukan PDF, kemungkinan HTML/error page');
        }
      }

      return bytes;
    } catch (e) {
      debugPrint("ERROR FETCH SOP: $e");
      throw Exception("Terjadi kesalahan saat mengambil PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                fileTitle ?? 'Detail SOP',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
        backgroundColor: Color(0xFF001932),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfBytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Terjadi kesalahan:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final bytes = snapshot.data!;

          return SfPdfViewer.memory(
            bytes,
            onDocumentLoadFailed: (details) {
              debugPrint(
                  'PDF LOAD FAILED: ${details.error} | ${details.description}');
            },
          );
        },
      ),
    );
  }
}
