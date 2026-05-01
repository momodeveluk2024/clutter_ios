import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/ai.dart';

class AiProvider extends ChangeNotifier {
  AiProvider({required ApiClient api}) : _api = api;

  final ApiClient _api;

  AiMealEstimate? currentEstimate;
  List<AiChatMessage> messages = [];
  String? conversationId;
  bool isAnalyzing = false;
  bool isSaving = false;
  bool isChatting = false;
  String? error;

  Future<AiMealEstimate> analyzeMealPhoto({
    required String imagePath,
    required String mealType,
    required String loggedOn,
    String question = '',
    String locale = 'en',
    String unitSystem = 'metric',
  }) async {
    isAnalyzing = true;
    error = null;
    notifyListeners();
    try {
      final data = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'meal_type': mealType,
        'logged_on': loggedOn,
        'locale': locale,
        'unit_system': unitSystem,
        if (question.trim().isNotEmpty) 'question': question.trim(),
      });
      final response = await _api.postMultipart(
        ApiEndpoints.aiMealPhotoAnalyze,
        data,
      );
      currentEstimate = AiMealEstimate.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return currentEstimate!;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<AiMealEstimate> updateEstimateItems(List<AiEstimateItem> items) async {
    final estimate = currentEstimate;
    if (estimate == null) throw StateError('No estimate selected');
    isSaving = true;
    notifyListeners();
    try {
      final response = await _api.patch(
        ApiEndpoints.aiEstimate(estimate.id),
        data: {'items': items.map((item) => item.toJson()).toList()},
      );
      currentEstimate = AiMealEstimate.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return currentEstimate!;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> acceptCurrentEstimate() async {
    final estimate = currentEstimate;
    if (estimate == null) throw StateError('No estimate selected');
    isSaving = true;
    notifyListeners();
    try {
      await _api.post(ApiEndpoints.acceptAiEstimate(estimate.id));
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<AiChatMessage> sendMessage(String message) async {
    final estimate = currentEstimate;
    isChatting = true;
    error = null;
    notifyListeners();
    messages = [...messages, AiChatMessage(role: 'user', content: message)];
    try {
      final response = await _api.post(
        ApiEndpoints.aiChat,
        data: {
          'message': message,
          if (conversationId != null) 'conversation_id': conversationId,
          if (estimate != null) 'estimate_id': estimate.id,
        },
      );
      final raw = Map<String, dynamic>.from(response.data as Map);
      conversationId = raw['conversation_id']?.toString() ?? conversationId;
      final reply = AiChatMessage(
        role: 'assistant',
        content: (raw['message'] ?? '').toString(),
        model: raw['model']?.toString(),
      );
      messages = [...messages, reply];
      return reply;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isChatting = false;
      notifyListeners();
    }
  }

  void editLocalItem(AiEstimateItem item) {
    final estimate = currentEstimate;
    if (estimate == null) return;
    currentEstimate = estimate.copyWith(
      items: estimate.items.map((existing) {
        return existing.id == item.id ? item : existing;
      }).toList(),
    );
    notifyListeners();
  }

  void removeLocalItem(String id) {
    final estimate = currentEstimate;
    if (estimate == null) return;
    currentEstimate = estimate.copyWith(
      items: estimate.items.where((item) => item.id != id).toList(),
    );
    notifyListeners();
  }
}
