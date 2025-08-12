import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';

class AgeConfirmationPage extends StatefulWidget {
  const AgeConfirmationPage({super.key});

  @override
  State<AgeConfirmationPage> createState() => _AgeConfirmationPageState();
}

class _AgeConfirmationPageState extends State<AgeConfirmationPage> {
  final ScrollController _scrollController = ScrollController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_canConfirm) {
        setState(() {
          _canConfirm = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 返回按钮
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
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
                '年龄确认与平台使用声明',
                style: AppTheme.headingStyle,
              ),
              SizedBox(height: 16.h),
              Text(
                '最后更新日期：2025年4月22日',
                style: AppTheme.secondaryStyle,
              ),
              SizedBox(height: 24.h),
              Text(
                '重要提醒：本平台仅向成年人提供服务',
                style: AppTheme.subheadingStyle.copyWith(
                  color: AppTheme.error,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '本平台系基于人工智能大语言模型技术的角色扮演交互服务平台。鉴于AI生成内容的特殊性和潜在风险，我们严格限制服务对象，仅向具备完全民事行为能力的成年人提供服务。',
                style: AppTheme.bodyStyle,
              ),
              SizedBox(height: 24.h),

              _buildSection(
                '1. 服务对象与年龄限制',
                '本平台仅向年满十八周岁且具有完全行为能力的成年人提供服务。我们严格遵守各国关于未成年人保护的相关法律法规。\n\n未满十八周岁的未成年人严禁注册使用本平台。',
              ),

              _buildSection(
                '2. AI生成内容特性与风险提示',
                '人工智能生成的内容具有不确定性、随机性及潜在风险性，可能包含但不限于：\n'
                '• 事实性错误或误导性信息\n'
                '• 不当言论或敏感内容\n'
                '• 版权争议或法律风险\n'
                '• 价值观偏差或伦理问题\n\n'
                '使用者应当具备充分的内容辨别能力、法律认知能力及风险防范意识，能够独立判断AI生成内容的真实性、合法性和适当性。',
              ),

              _buildSection(
                '3. 用户责任与法律后果',
                '使用者应当对其使用本平台服务的行为及后果承担完全责任，包括但不限于：\n'
                '• 因不当使用所产生的法律责任\n'
                '• 因传播不当内容所产生的后果\n'
                '• 因违反当地法律法规所产生的责任\n'
                '• 因侵犯他人权益所产生的赔偿责任\n\n'
                '平台不对用户使用AI生成内容所产生的任何后果承担责任。',
              ),

              _buildSection(
                '4. 禁止行为与违规处理',
                '用户在使用本平台时，严禁从事以下行为：\n'
                '• 生成、传播违法违规或有害内容\n'
                '• 侵犯他人知识产权、肖像权、隐私权等合法权益\n'
                '• 进行商业欺诈、虚假宣传等不当商业行为\n'
                '• 传播暴力、色情、恐怖主义等有害信息\n'
                '• 其他违反当地法律法规或社会公德的行为\n\n'
                '违反上述规定的，平台有权立即终止服务并保留追究责任的权利。',
              ),

              SizedBox(height: 24.h),
              Text(
                '如果您未满十八周岁，请立即离开本页面，不得继续注册使用本平台。继续注册即表示您确认已年满十八周岁，具备完全行为能力，理解并同意承担上述所有责任。',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 32.h),

              // 底部按钮
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          side: BorderSide(
                            color: AppTheme.textSecondary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.bodySize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canConfirm ? () {
                        Navigator.of(context).pop(true);
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canConfirm ? AppTheme.primaryColor : AppTheme.textSecondary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Text(
                        _canConfirm ? '我已年满18周岁，同意上述条款' : '请滚动到底部阅读完整条款',
                        style: TextStyle(
                          fontSize: AppTheme.captionSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
            ],
          ),
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