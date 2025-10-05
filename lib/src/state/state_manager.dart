// lib/src/state/state_manager.dart
// Updated to add isFaceDetected (assuming it was missing or mismatched; based on previous structure).
import 'package:flutter/foundation.dart';

class BioLogreenStateManager extends ChangeNotifier {
  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;
  set isInitializing(bool value) {
    _isInitializing = value;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  bool _isFaceDetected = false;
  bool get isFaceDetected => _isFaceDetected;
  set isFaceDetected(bool value) {
    _isFaceDetected = value;
    notifyListeners();
  }

  String? _error;
  String? get error => _error;
  set error(String? value) {
    _error = value;
    notifyListeners();
  }

}