import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
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
                    '服务条款',
                    style: AppTheme.headingStyle,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '最后更新日期：2025年4月22日',
                    style: AppTheme.secondaryStyle,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '欢迎使用我们的AI角色扮演服务',
                    style: AppTheme.subheadingStyle,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '请仔细阅读以下条款。通过访问或使用我们的服务，您同意受这些条款的约束。如果您不同意这些条款的任何部分，则不得使用我们的服务。',
                    style: AppTheme.bodyStyle,
                  ),
                  SizedBox(height: 24.h),
                  _buildSection(
                    '1. 服务说明',
                    '我们提供基于人工智能的角色扮演服务，允许用户与AI角色进行互动。这些角色由我们的系统创建和控制，旨在提供娱乐和互动体验。',
                  ),
                  _buildSection(
                    '2. 用户账户',
                    '使用我们的服务需要创建账户。您负责维护账户安全，并对发生在您账户下的所有活动负责。您必须立即通知我们任何未经授权使用您账户的情况。',
                  ),
                  _buildSection(
                    '3. 用户行为',
                    '您同意不使用我们的服务来：\n'
                        '• 违反任何适用法律或规定\n'
                        '• 侵犯他人的权利\n'
                        '• 发布或分享非法、有害、威胁、辱骂、骚扰、诽谤、淫秽或其他不当内容\n'
                        '• 尝试规避我们的内容过滤系统\n'
                        '• 未经允许收集其他用户的信息',
                  ),
                  _buildSection(
                    '4. AI角色互动',
                    '我们的AI角色仅用于娱乐目的，不应被视为真实个体。AI生成的内容不代表我们的观点，我们对AI生成的内容不承担责任。我们努力防止AI生成有害内容，但系统并非完美。',
                  ),
                  _buildSection(
                    '5. 内容限制',
                    '我们严格禁止使用我们的服务创建或传播涉及以下内容的材料：\n'
                        '• 违法活动\n'
                        '• 暴力或仇恨言论\n'
                        '• 色情或性暗示内容\n'
                        '• 未成年人不当内容\n'
                        '• 骚扰、欺凌或威胁',
                  ),
                  _buildSection(
                    '6. 知识产权',
                    '我们的服务及其原始内容、功能和设计都是我们的专有财产，受著作权、商标和其他知识产权法律保护。',
                  ),
                  _buildSection(
                    '7. 终止',
                    '如果您违反这些条款，我们有权在不另行通知的情况下终止或暂停您的账户和访问权限。',
                  ),
                  _buildSection(
                    '8. 免责声明',
                    '我们的服务按"原样"和"可用"基础提供，不提供任何明示或暗示的保证。我们不保证服务将不间断、及时、安全或无错误，也不保证结果准确或可靠。',
                  ),
                  _buildSection(
                    '9. 责任限制',
                    '在法律允许的最大范围内，我们对任何直接、间接、附带、特殊、示范或后果性损害不承担责任。',
                  ),
                  _buildSection(
                    '10. 条款变更',
                    '我们保留随时修改这些条款的权利。修改后的条款将在我们的网站上发布时生效。继续使用我们的服务将视为您接受修改后的条款。',
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '如有任何问题或疑虑，请联系我们的客户服务团队。',
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
