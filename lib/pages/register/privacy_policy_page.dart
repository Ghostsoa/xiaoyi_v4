import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _showBackToTopButton = _scrollController.offset >= 200;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 返回按钮
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: AppTheme.backButtonDecoration,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back,
                          size: 22.w,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Text(
                    '隐私政策',
                    style: AppTheme.headingStyle,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '最后更新日期：2025年4月22日',
                    style: AppTheme.secondaryStyle,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '保护您的隐私对我们至关重要',
                    style: AppTheme.subheadingStyle,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '本隐私政策说明了我们如何收集、使用、披露和保护您的个人信息。使用我们的AI角色扮演服务，即表示您同意本隐私政策中描述的做法。',
                    style: AppTheme.bodyStyle,
                  ),
                  SizedBox(height: 24.h),
                  _buildSection(
                    '1. 我们收集的信息',
                    '我们可能收集以下类型的信息：\n'
                        '• 账户信息：当您注册账户时，我们收集您的姓名、电子邮件地址和密码\n'
                        '• 使用数据：关于您如何使用我们的服务的信息，如交互历史、访问时间和使用偏好\n'
                        '• 内容数据：您在使用我们的服务时创建的内容和与AI角色的对话\n'
                        '• 设备信息：设备类型、操作系统、浏览器类型和IP地址',
                  ),
                  _buildSection(
                    '2. 我们如何使用您的信息',
                    '我们使用收集的信息来：\n'
                        '• 提供、维护和改进我们的服务\n'
                        '• 创建和维护您的账户\n'
                        '• 个性化您的体验\n'
                        '• 分析使用模式以改进服务\n'
                        '• 与您沟通关于服务的更新、安全警报和支持信息\n'
                        '• 防止欺诈行为和保护我们服务的安全',
                  ),
                  _buildSection(
                    '3. AI角色对话数据',
                    '我们会存储您与AI角色的对话以提供和改进我们的服务。这些数据可能被用于：\n'
                        '• 改善AI响应的质量\n'
                        '• 训练我们的AI模型\n'
                        '• 解决服务问题\n'
                        '• 确保内容符合我们的使用条款',
                  ),
                  _buildSection(
                    '4. 数据安全',
                    '我们采取合理的安全措施保护您的个人信息免遭未经授权的访问、使用或披露。然而，没有任何传输方法或电子存储方法是100%安全的。',
                  ),
                  _buildSection(
                    '5. 信息共享',
                    '我们不会出售您的个人信息。我们可能在以下情况下共享您的信息：\n'
                        '• 征得您的同意\n'
                        '• 与提供服务所需的第三方服务提供商共享\n'
                        '• 遵守法律要求\n'
                        '• 保护我们的权利和财产',
                  ),
                  _buildSection(
                    '6. 您的选择和权利',
                    '您可以：\n'
                        '• 访问、更新或删除您的账户信息\n'
                        '• 选择退出营销通信\n'
                        '• 要求删除您的账户和相关数据（根据适用法律，某些信息可能被保留）',
                  ),
                  _buildSection(
                    '7. 未成年人',
                    '我们的服务不面向13岁以下的儿童。如果我们得知我们收集了13岁以下儿童的个人信息，我们将采取措施删除该信息。',
                  ),
                  _buildSection(
                    '8. 第三方链接',
                    '我们的服务可能包含指向第三方网站或服务的链接，我们对这些第三方的隐私做法不负责任。',
                  ),
                  _buildSection(
                    '9. 国际数据传输',
                    '我们可能在全球范围内处理和存储您的信息。使用我们的服务，即表示您同意将您的信息传输和处理到中国和其他您可能居住地以外的国家。',
                  ),
                  _buildSection(
                    '10. 政策变更',
                    '我们可能会不时更新本隐私政策。我们将通过在我们的网站上发布新的隐私政策来通知您任何变更。',
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '如果您对我们的隐私政策有任何疑问，请联系我们的隐私团队。',
                    style: AppTheme.bodyStyle,
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),

            // 回到顶部的悬浮按钮
            if (_showBackToTopButton)
              Positioned(
                right: 24.w,
                bottom: 24.h,
                child: FloatingActionButton(
                  onPressed: _scrollToTop,
                  backgroundColor: AppTheme.primaryColor,
                  mini: true,
                  child: Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20.w,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          content,
          style: AppTheme.bodyStyle,
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
