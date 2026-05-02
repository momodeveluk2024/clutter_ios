// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final map = {
    'beer': 'beer_1777580636283.png',
    'beets': 'beets_1777580650943.png',
    'bibimbap': 'bibimbap_1777580667937.png',
    'biryani': 'biryani_1777580692171.png',
    'bananas': 'bananas_1777580705989.png',
    'banh_mi': 'banh_mi_1777580719381.png',
    'beef': 'beef_1777580746340.png',
    'beef_steak': 'beef_steak_1777580761541.png',
    'apricots': 'apricots_1777580776308.png',
    'arepas': 'arepas_1777580801113.png',
    'artichoke': 'artichoke_1777580815546.png',
  };
  final srcDir =
      r'C:\Users\PC\.gemini\antigravity\brain\6a65b6eb-a7fe-4e70-94f7-b9250e809fbb';
  final destDir =
      r'c:\Users\PC\Downloads\he mamosta kollage\applicationfluttter\myapplication\assets\foods';
  for (final entry in map.entries) {
    final src = File('$srcDir\\${entry.value}');
    if (src.existsSync()) {
      src.copySync('$destDir\\${entry.key}.jpg');
      print('Copied ${entry.key}');
    } else {
      print('Missing ${entry.value}');
    }
  }
}
