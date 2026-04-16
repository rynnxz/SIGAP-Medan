import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class FloatingSearchBar extends StatefulWidget {
  const FloatingSearchBar({super.key});

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    
    _controller.addListener(() {
      setState(() {});
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    var status = await Permission.microphone.request();
    
    if (status.isGranted) {
      if (_speechAvailable && !_isListening) {
        setState(() => _isListening = true);
        
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'id_ID',
          cancelOnError: true,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin mikrofon diperlukan untuk voice search'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isFocused || _isListening
              ? const Color(0xFF10B981)
              : isDark 
                  ? const Color(0xFF374151) 
                  : const Color(0xFFE5E7EB),
          width: _isFocused || _isListening ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused || _isListening
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: _isFocused || _isListening ? 24 : 16,
            offset: const Offset(0, 4),
            spreadRadius: _isFocused || _isListening ? 2 : 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: Icon(
              _isListening ? LucideIcons.radio : LucideIcons.search,
              color: _isFocused || _isListening
                  ? const Color(0xFF10B981)
                  : isDark 
                      ? const Color(0xFF9CA3AF) 
                      : const Color(0xFF6B7280),
              size: 22,
            ),
          ),
          
          // Text Input
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                });
              },
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: _isListening 
                      ? 'Mendengarkan...' 
                      : 'Cari jalan atau kawasan...',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: _isListening
                        ? const Color(0xFF10B981)
                        : isDark 
                            ? const Color(0xFF9CA3AF) 
                            : const Color(0xFF6B7280),
                    fontWeight: _isListening 
                        ? FontWeight.w500 
                        : FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          
          // Clear Button
          if (_controller.text.isNotEmpty && !_isListening)
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.clear();
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF374151) 
                        : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: isDark 
                        ? const Color(0xFF9CA3AF) 
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          
          // Mic Button
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [
                            const Color(0xFFEF4444),
                            const Color(0xFFDC2626),
                          ]
                        : [
                            const Color(0xFF10B981),
                            const Color(0xFF059669),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening 
                          ? const Color(0xFFEF4444) 
                          : const Color(0xFF10B981)).withValues(alpha: 0.3),
                      blurRadius: _isListening ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.mic,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
