import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';

class DeclarationPage extends StatelessWidget {
  const DeclarationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final background = AppTheme.background;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          '大厅规则',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 规则时效性声明
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: AppTheme.primaryColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '规则版本：v1.2 (2025-07-22)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '请注意：此处规则仅供参考，最新版本以官方通知为准，平台保留随时变更规则的权利。',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 30.h, thickness: 1),

            // 违规内容限制
            _buildSectionTitle('违规内容限制', Icons.block_rounded, Colors.red),
            SizedBox(height: 16.h),

            Text(
              '禁止在公开部分（封面、背景、标题、简介、公开设定）上传包括且不限于以下违规内容：',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            _buildListItem(
              '色情内容',
              description:
                  '指完全裸露且未做任何遮挡的性器官，或对性行为的露骨文字描述。注意：类似比基尼等服装的性感艺术表现形式，其界定标准由官方掌握。',
            ),
            _buildListItem(
              '暴力内容',
              description: '包含对真实人物或群体的暴力威胁、血腥场面或虐待行为的详细描述。',
            ),
            _buildListItem(
              '涉及未成年人不当内容',
              description: '任何可能对未成年人产生不良影响、或利用未成年人形象进行不当创作的内容。',
            ),
            _buildListItem(
              '赌博、吸毒相关内容',
              description: '宣传、教唆或展示任何形式的赌博、毒品及相关违法行为。',
            ),
            _buildListItem(
              '政治敏感内容',
              description: '涉及国家安全、民族宗教政策、歪曲历史或可能引发政治争议的内容。',
            ),
            _buildListItem(
              '猎奇、引人不适内容',
              description: '包含极端、血腥、恐怖、恶心或其他可能引起用户强烈不适的视觉或文字内容。',
            ),
            _buildListItem(
              '侵犯他人肖像权',
              description:
                  '尊重每位公民的肖像权，严禁在未经授权的情况下使用他人真实照片作为素材。AI 绘制、非真实的二次元虚拟角色不在此限制范围内。',
            ),
            SizedBox(height: 16.h),

            // 违规处罚明细
            _buildPenaltyBlock('首次违规', [
              '视情节严重程度给予不同处罚',
              '轻微违规：警告并要求整改',
              '严重违规：扣除72小时时长、封号1天（封号期间不停止计时）',
              '特别严重：7天封号处理并清空资产（不足72小时时长）'
            ]),

            _buildPenaltyBlock(
                '多次违规', ['扣除168-720小时不等', '封号7天', '根据违规行为轻重给予用户惩罚']),

            SizedBox(height: 12.h),
            _buildNote('最终解释权及定性权归平台所有'),

            Divider(height: 40.h, thickness: 1),

            // 原创侵权限制
            _buildSectionTitle('原创侵权限制', Icons.copyright, Colors.blue),
            SizedBox(height: 16.h),

            Text(
              '未经授权禁止转载其他平台原创角色卡并公开发布谋取创作者激励。',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 12.h),

            Text(
              '一经原作者或他人举报，平台将进行以下流程处理：',
              style: TextStyle(
                fontSize: 15.sp,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            _buildListItem('内容审核确立存在侵权行为', hasTopPadding: false),
            _buildListItem('通过软件内通知联系违规用户', hasTopPadding: false),
            _buildListItem('违规角色卡将被转为私密状态', hasTopPadding: false),
            SizedBox(height: 16.h),

            // 侵权处罚明细
            _buildPenaltyBlock('首次侵权', ['通知警告', '将角色卡转为私密']),

            _buildPenaltyBlock('二次侵权', ['临时剥夺发布角色卡权利']),

            _buildPenaltyBlock('多次/批量侵权', [
              '永久剥夺发布角色卡权利',
              '下架所有角色卡',
              '没收所有创作者激励所得并转移给原创作者',
              '给予原创作者7-15天不等的契约魔法师补偿'
            ]),

            SizedBox(height: 12.h),
            _buildNote('须满足条件：原创作者为本平台作者或原创作者愿意加入小懿AI'),
            SizedBox(height: 8.h),
            _buildNote('最终解释权及定性权归平台所有'),

            Divider(height: 40.h, thickness: 1),

            // 底部提示
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                '用户使用角色卡大厅即默认同意《大厅使用规则》条款',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: color),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPenaltyBlock(String title, List<String> items) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          ...items
              .map((item) => _buildListItem(item, hasTopPadding: false))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildListItem(String text,
      {String? description, bool hasTopPadding = true}) {
    return Padding(
      padding: EdgeInsets.only(
          left: 12.w,
          bottom: description != null ? 4.h : 8.h,
          top: hasTopPadding ? 8.h : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (description != null)
            Padding(
              padding: EdgeInsets.only(left: 20.w, top: 4.h),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondary.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNote(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 14.sp, color: AppTheme.textSecondary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
