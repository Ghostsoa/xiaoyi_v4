import 'dart:convert';
import 'html_template_cache_service.dart';

/// 消息模板处理器
/// 用于检测和渲染消息中的 HTML 模板
class MessageTemplateProcessor {
  final HtmlTemplateCacheService _cacheService = HtmlTemplateCacheService();

  // 单例模式
  static final MessageTemplateProcessor _instance = MessageTemplateProcessor._internal();
  factory MessageTemplateProcessor() => _instance;
  MessageTemplateProcessor._internal();

  /// 处理消息内容，检测并渲染模板
  /// @param content 原始消息内容
  /// @param formatMode 格式模式（html/webview/markdown/disabled）
  /// @return 处理后的消息内容
  Future<String> processMessage(String content, String formatMode) async {
    print('[MessageTemplateProcessor] 处理消息，formatMode: $formatMode');
    
    // 只在 HTML 或 WebView 模式下处理
    if (formatMode != 'html' && formatMode != 'webview') {
      print('[MessageTemplateProcessor] 非HTML/WebView模式，跳过处理');
      return content;
    }

    try {
      // 查找所有的模板 JSON
      final templates = _extractTemplateJsons(content);
      
      print('[MessageTemplateProcessor] 找到 ${templates.length} 个模板');
      
      if (templates.isEmpty) {
        return content;
      }

      String processedContent = content;

      // 逐个处理模板
      for (final templateInfo in templates) {
        final originalJson = templateInfo['original'] as String;
        final templateData = templateInfo['data'] as Map<String, dynamic>;
        
        final templateId = templateData['template_id'] ?? templateData['templateId'];
        print('[MessageTemplateProcessor] 处理模板ID: $templateId');
        
        // 渲染模板
        final renderedHtml = await _renderTemplate(templateData);
        
        if (renderedHtml != null) {
          print('[MessageTemplateProcessor] 渲染成功，HTML长度: ${renderedHtml.length}');
          // 替换原始 JSON 为渲染后的 HTML
          processedContent = processedContent.replaceAll(originalJson, renderedHtml);
        } else {
          print('[MessageTemplateProcessor] 渲染失败');
        }
      }

      return processedContent;
    } catch (e) {
      print('[MessageTemplateProcessor] 处理消息失败: $e');
      return content; // 出错时返回原始内容
    }
  }

  /// 提取消息中的所有模板 JSON
  /// 主要支持 Markdown 代码块格式: ```json\n{...}\n```
  List<Map<String, dynamic>> _extractTemplateJsons(String content) {
    final List<Map<String, dynamic>> results = [];

    // 正则表达式：匹配 markdown 代码块中的 JSON
    final markdownJsonRegex = RegExp(
      r'```json\s*\n([\s\S]*?)\n```',
      multiLine: true,
    );

    // 提取 markdown 代码块中的 JSON
    final markdownMatches = markdownJsonRegex.allMatches(content);
    for (final match in markdownMatches) {
      final fullMatch = match.group(0)!; // 包含 ```json ... ```
      final jsonStr = match.group(1)!.trim(); // 只有 JSON 内容
      
      try {
        final jsonData = jsonDecode(jsonStr);
        if (jsonData is Map && (jsonData.containsKey('template_id') || jsonData.containsKey('templateId'))) {
          print('[MessageTemplateProcessor] 成功提取模板 JSON');
          results.add({
            'original': fullMatch,
            'data': jsonData,
          });
        } else {
          print('[MessageTemplateProcessor] JSON 不包含 template_id 字段，跳过');
        }
      } catch (e) {
        // JSON 解析失败，跳过这个代码块
        print('[MessageTemplateProcessor] Markdown代码块JSON解析失败，跳过: ${e.toString().substring(0, 100)}...');
      }
    }

    return results;
  }

  /// 渲染单个模板
  /// @param templateData 包含 template_id 或 templateId 和 data 的 JSON 对象
  /// @return 渲染后的 HTML，如果失败返回 null
  Future<String?> _renderTemplate(Map<String, dynamic> templateData) async {
    try {
      // 获取模板 ID（支持两种命名）
      final templateId = templateData['template_id'] ?? templateData['templateId'];
      if (templateId == null) {
        print('[MessageTemplateProcessor] 模板ID为空');
        return null;
      }

      int id;
      if (templateId is int) {
        id = templateId;
      } else if (templateId is String) {
        id = int.parse(templateId);
      } else {
        print('[MessageTemplateProcessor] 模板ID类型错误: ${templateId.runtimeType}');
        return null;
      }

      // 从缓存获取模板
      final htmlTemplate = await _cacheService.getTemplate(id);
      if (htmlTemplate == null || htmlTemplate.isEmpty) {
        print('[MessageTemplateProcessor] 模板 $id 不存在或为空');
        return null;
      }

      // 获取数据字段
      final data = templateData['data'];
      if (data == null || data is! Map) {
        return null;
      }

      // 替换占位符
      String renderedHtml = htmlTemplate;
      data.forEach((key, value) {
        final placeholder = '{{$key}}';
        final valueStr = value?.toString() ?? '';
        renderedHtml = renderedHtml.replaceAll(placeholder, valueStr);
      });

      return renderedHtml;
    } catch (e) {
      print('[MessageTemplateProcessor] 渲染模板失败: $e');
      return null;
    }
  }

  /// 批量处理消息列表
  /// @param messages 消息列表
  /// @param formatMode 格式模式
  /// @return 处理后的消息列表
  Future<List<Map<String, dynamic>>> processMessages(
    List<Map<String, dynamic>> messages,
    String formatMode,
  ) async {
    final processedMessages = <Map<String, dynamic>>[];

    for (final message in messages) {
      final newMessage = Map<String, dynamic>.from(message);
      final content = message['content']?.toString() ?? '';
      
      // 处理消息内容
      final processedContent = await processMessage(content, formatMode);
      newMessage['content'] = processedContent;
      
      processedMessages.add(newMessage);
    }

    return processedMessages;
  }
}

