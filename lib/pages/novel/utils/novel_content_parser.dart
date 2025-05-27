class NovelContentParser {
  // 解析AI返回的内容字符串为段落列表
  static List<Map<String, dynamic>> parseContent(String content) {
    final paragraphs = content.split('\n\n');
    return paragraphs.map((p) {
      // 简单处理，如果包含引号，认为是对话
      final isDialog = p.contains('"') || p.contains('"') || p.contains('"');

      if (isDialog) {
        // 尝试提取角色名称
        final parts = p.split(':');
        if (parts.length > 1) {
          return {
            'content': parts[1].trim(),
            'type': 'character_speech',
            'character_name': parts[0].trim(),
            'created_at': DateTime.now().toString(),
          };
        }
      }

      return {
        'content': p.trim(),
        'type': 'narrator',
        'created_at': DateTime.now().toString(),
      };
    }).toList();
  }

  // 获取默认章节标题
  static String getDefaultChapterTitle(int chapterNumber) {
    return '第$chapterNumber章';
  }

  // 清理内容中的标题标签
  static String cleanContent(String content) {
    return content.replaceAll(RegExp(r'<title>.*?</title>'), '').trim();
  }
}
