import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../services/webview_pool_service.dart';
import 'dart:convert';

class HtmlTemplatePreviewPage extends StatefulWidget {
  final String htmlTemplate;
  final String exampleData;
  final String projectName;

  const HtmlTemplatePreviewPage({
    super.key,
    required this.htmlTemplate,
    required this.exampleData,
    required this.projectName,
  });

  @override
  State<HtmlTemplatePreviewPage> createState() => _HtmlTemplatePreviewPageState();
}

class _HtmlTemplatePreviewPageState extends State<HtmlTemplatePreviewPage> {
  final WebViewPoolService _webViewPool = WebViewPoolService();
  WebViewController? _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    if (_webViewController != null) {
      _webViewPool.returnController(_webViewController!);
    }
    super.dispose();
  }

  Future<void> _initWebView() async {
    try {
      // 从对象池获取控制器
      final controller = await _webViewPool.getController();
      
      // 渲染HTML
      final renderedHtml = _renderTemplate(widget.htmlTemplate, widget.exampleData);
      
      if (mounted) {
        setState(() {
          _webViewController = controller;
        });

        await controller.loadHtmlString(renderedHtml);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '渲染失败: ${e.toString()}';
        });
      }
    }
  }

  /// 渲染模板：将 {{key}} 替换为示例数据中的值
  String _renderTemplate(String template, String jsonData) {
    try {
      // 解析JSON数据
      final Map<String, dynamic> data = json.decode(jsonData);
      
      String rendered = template;
      
      // 遍历所有键值对，替换占位符
      data.forEach((key, value) {
        final placeholder = '{{$key}}';
        final replacement = value?.toString() ?? '';
        rendered = rendered.replaceAll(placeholder, replacement);
      });
      
      return rendered;
    } catch (e) {
      throw Exception('JSON解析失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final background = AppTheme.background;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '渲染预览',
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 项目名称提示
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.border.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, size: 16.sp, color: AppTheme.primaryColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    widget.projectName,
                    style: TextStyle(
                      fontSize: AppTheme.captionSize,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // WebView内容区域
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16.h),
            Text(
              '正在渲染HTML...',
              style: TextStyle(
                fontSize: AppTheme.captionSize,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: Colors.red,
              ),
              SizedBox(height: 16.h),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initWebView();
                },
                icon: Icon(Icons.refresh),
                label: Text('重新渲染'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_webViewController == null) {
      return Center(
        child: Text(
          'WebView未初始化',
          style: TextStyle(
            fontSize: AppTheme.bodySize,
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    return WebViewWidget(
      controller: _webViewController!,
    );
  }
}

