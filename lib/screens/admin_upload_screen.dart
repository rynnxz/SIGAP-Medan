import 'package:flutter/material.dart';
import '../utils/upload_landmarks.dart';
import '../utils/upload_reports.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final UploadLandmarks _landmarksUploader = UploadLandmarks();
  final UploadReports _reportsUploader = UploadReports();
  bool _isUploading = false;
  String _status = '';

  Future<void> _uploadLandmarks() async {
    setState(() {
      _isUploading = true;
      _status = 'Uploading landmarks...';
    });

    try {
      await _landmarksUploader.resetAndUpload();
      setState(() {
        _status = '✅ Landmarks uploaded successfully!';
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Landmarks uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadReports() async {
    setState(() {
      _isUploading = true;
      _status = 'Uploading reports...';
    });

    try {
      await _reportsUploader.resetAndUpload();
      setState(() {
        _status = '✅ Reports uploaded successfully!';
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reports uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadAll() async {
    setState(() {
      _isUploading = true;
      _status = 'Uploading all data...';
    });

    try {
      await _landmarksUploader.resetAndUpload();
      setState(() => _status = 'Landmarks done, uploading reports...');
      
      await _reportsUploader.resetAndUpload();
      setState(() {
        _status = '✅ All data uploaded successfully!';
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Upload Data'),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.cloud_upload,
              size: 80,
              color: Color(0xFF10B981),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Upload Data ke Firestore',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Upload landmarks dan reports dengan field terbaru',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadAll,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? 'Uploading...' : 'Upload Semua Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _uploadLandmarks,
                    icon: const Icon(Icons.place),
                    label: const Text('Landmarks'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _uploadReports,
                    icon: const Icon(Icons.report),
                    label: const Text('Reports'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('✅')
                      ? Colors.green.withOpacity(0.1)
                      : _status.contains('❌')
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status.contains('✅')
                        ? Colors.green
                        : _status.contains('❌')
                            ? Colors.red
                            : Colors.blue,
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains('✅')
                        ? Colors.green.shade700
                        : _status.contains('❌')
                            ? Colors.red.shade700
                            : Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const Spacer(),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data yang akan diupload:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('📍 15 landmarks (wisata/kuliner/sejarah)'),
                    Text('   • Field baru: favoritedBy, reviews'),
                    SizedBox(height: 4),
                    Text('📢 12 reports (laporan warga)'),
                    Text('   • Field baru: upvotedBy, timeline'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
