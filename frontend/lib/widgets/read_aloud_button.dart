import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/speech_tts_service.dart';

class ReadAloudButton extends StatefulWidget {
  final String textToRead;
  final String label;

  const ReadAloudButton({
    Key? key,
    required this.textToRead,
    this.label = 'Read Aloud (TTS)',
  }) : super(key: key);

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton> {
  final SpeechTTSService _ttsService = SpeechTTSService();
  bool _isSpeaking = false;

  void _toggleSpeak() async {
    if (_isSpeaking) {
      await _ttsService.stopSpeaking();
      setState(() => _isSpeaking = false);
    } else {
      if (widget.textToRead.trim().isEmpty) return;
      setState(() => _isSpeaking = true);
      await _ttsService.speakText(widget.textToRead);
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  void dispose() {
    _ttsService.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _toggleSpeak,
      icon: Icon(
        _isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        color: _isSpeaking ? AppTheme.warningOrange : AppTheme.accentCyan,
        size: 20,
      ),
      label: Text(
        _isSpeaking ? 'Stop Reading' : widget.label,
        style: TextStyle(
          color: _isSpeaking ? AppTheme.warningOrange : AppTheme.accentCyan,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _isSpeaking ? AppTheme.warningOrange : AppTheme.accentCyan),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
