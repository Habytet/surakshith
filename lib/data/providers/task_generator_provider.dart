import 'package:flutter/foundation.dart';
import 'package:surakshith/data/services/repetitive_task_generator.dart';

/// Provider for managing repetitive task generation
class TaskGeneratorProvider with ChangeNotifier {
  final RepetitiveTaskGenerator _generator = RepetitiveTaskGenerator();

  bool _isGenerating = false;
  String? _lastGenerationResult;
  DateTime? _lastGenerationTime;
  int _templatesNeedingGeneration = 0;

  bool get isGenerating => _isGenerating;
  String? get lastGenerationResult => _lastGenerationResult;
  DateTime? get lastGenerationTime => _lastGenerationTime;
  int get templatesNeedingGeneration => _templatesNeedingGeneration;

  /// Generate daily tasks from all active templates
  Future<bool> generateDailyTasks() async {
    if (_isGenerating) {
      debugPrint('Task generation already in progress');
      return false;
    }

    _isGenerating = true;
    _lastGenerationResult = null;
    notifyListeners();

    try {
      final result = await _generator.generateDailyTasks();

      _lastGenerationTime = DateTime.now();

      if (result.hasErrors) {
        _lastGenerationResult =
            'Generated ${result.successCount} tasks, ${result.failureCount} failed';
      } else if (result.successCount > 0) {
        _lastGenerationResult =
            'Successfully generated ${result.successCount} tasks';
      } else {
        _lastGenerationResult = 'No tasks needed generation today';
      }

      debugPrint(_lastGenerationResult);
      return result.successCount > 0;
    } catch (e) {
      _lastGenerationResult = 'Error: $e';
      debugPrint('Task generation error: $e');
      return false;
    } finally {
      _isGenerating = false;
      await _checkTemplatesNeedingGeneration();
      notifyListeners();
    }
  }

  /// Generate tasks from a specific template
  Future<int> generateFromTemplate({
    required String templateId,
    DateTime? dueDate,
    List<String>? assignees,
  }) async {
    try {
      final count = await _generator.generateTasksFromTemplate(
        templateId: templateId,
        dueDate: dueDate,
        assignees: assignees,
      );
      return count;
    } catch (e) {
      debugPrint('Error generating from template: $e');
      return 0;
    }
  }

  /// Check how many templates need task generation
  Future<void> _checkTemplatesNeedingGeneration() async {
    try {
      _templatesNeedingGeneration =
          await _generator.getTemplatesNeedingGeneration();
    } catch (e) {
      debugPrint('Error checking templates: $e');
      _templatesNeedingGeneration = 0;
    }
  }

  /// Initialize and check for templates needing generation
  Future<void> initialize() async {
    await _checkTemplatesNeedingGeneration();
    notifyListeners();
  }

  /// Auto-generate tasks if needed (call on app start)
  Future<void> autoGenerateIfNeeded() async {
    await _checkTemplatesNeedingGeneration();

    if (_templatesNeedingGeneration > 0) {
      debugPrint(
        '$_templatesNeedingGeneration template(s) need task generation',
      );
      // Auto-generate tasks silently in the background
      await generateDailyTasks();
    }

    notifyListeners();
  }
}
