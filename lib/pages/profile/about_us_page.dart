import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _version = 'Unknown';
      });
    }
  }

  static const String _websiteUrl = 'https://xiaoyi.ink';

  // 用户协议和隐私政策内容
  static const String _content = '''欢迎使用小懿AI（以下简称"应用程序"或"服务"）。本软件专为技术学习与测试设计，严禁用于商业用途。一旦使用本软件，即视为您同意以下免责声明、使用条款及隐私政策：

一、免责声明
本应用仅提供AI对话服务，所有对话内容均由AI模型实时生成。由于AI技术的局限性，生成的内容可能存在错误、偏差或不准确的情况。因此，用户需自行承担使用本软件所带来的风险，包括但不限于因依赖AI生成内容而产生的任何损失或损害。

二、使用条款
2.1 接受条款
您访问和使用服务的前提是您接受并遵守这些条款。这些条款适用于所有访问者、用户以及访问或使用服务的其他人。通过访问或使用服务，您同意受这些条款和条件的约束。如果您不同意这些条款的任何部分，则您可能无法访问服务。您同意您创作作品中的所有角色均年满18岁。

2.2 数据处理与隐私
数据收集：为确保软件正常运行和优化服务，我们仅收集必要的模型调用信息，如调用的时间、模型类型等。
Token用量记录：我们会记录token用量统计数据，该记录仅保存30天，之后将自动删除。
隐私保护：严格遵守隐私保护原则，我们不会存储任何对话内容，也不会收集用户的隐私信息，如姓名、联系方式、身份证号等。您访问和使用服务的前提是您接受并遵守我们的隐私政策。
设备信息：设备信息及个人数据也不在我们的收集范围内，以充分保障用户的隐私安全。
您有责任保护用于访问服务的密码，并对使用您的密码进行的任何活动或操作负责。您同意不向任何第三方透露您的密码。一旦发现任何安全漏洞或未经授权使用您的帐户的情况，您必须立即通知我们（邮箱：2113979520@qq.com）。

2.3 用户内容与知识产权
AI生成的内容可能涉及第三方权益，包括但不限于版权、商标权等。用户在使用AI生成内容时应谨慎行事，充分评估可能的法律风险。若因使用AI生成内容而引发任何纠纷或法律责任，均由用户自行承担，本软件开发者及运营方不承担相关责任。

我们的服务允许您发布内容。您应对您发布到服务的内容负责，包括其合法性、可靠性和适当性。通过将内容发布到服务，您授予我们在服务上和通过服务使用、修改、公开展示、复制和分发此类内容的权利和许可。您声明并保证：（i）内容属于您或您有权使用它，（ii）发布内容不侵犯任何人的隐私权、版权等权利。

2.4 内容限制与禁止内容
您不得传输任何非法、冒犯、威胁、诽谤、淫秽或其他令人反感的内容，包括但不限于色情、仇恨言论、恶意软件等。公司保留删除不当内容并限制服务使用权的权利。

2.5 免责声明与责任限制
应用程序以"原样"提供，不保证无错误或满足特定需求。公司不对间接损害（如利润损失）负责。

2.6 终止
我们可能因违反条款等原因随时终止您的账户。如需终止账户，您可停止使用服务。

三、隐私政策
3.1 概述与定义
本隐私政策描述了当您使用本服务时，我们关于收集、使用和披露您的个人信息的政策和程序。通过使用本服务，您同意按照本隐私政策收集和使用您的个人信息。"个人信息"指与已识别或可识别个人相关的任何信息。

3.2 收集的个人信息
我们可能会要求您提供电子邮件地址以注册和沟通。用户内容或聊天通信中包含的个人信息可能会被存储并被其他用户访问，我们不对其他用户的行为负责。

通过cookies等技术，我们自动收集使用数据（如IP地址、浏览器类型、访问时间等），包括移动设备信息（如设备ID、操作系统）。

若通过第三方社交媒体服务（如Discord）注册，我们可能收集您的姓名、电子邮件等信息。

在使用应用程序时，经您许可，我们可能收集设备相机和照片库中的信息。

3.3 使用与共享个人信息
个人信息用于提供服务、管理账户、履行合同、联系您、管理请求等，可能与服务提供商、关联公司、商业伙伴共享，或因法律要求披露。

3.4 保留与权利
个人信息仅在必要时保留。如需访问、删除或纠正个人信息，请联系2113979520@qq.com。

3.5 儿童政策
服务不针对13岁以下儿童，我们不会故意收集其个人信息。若发现此类情况，我们会删除相关信息。

3.6 政策变更
隐私政策可能更新，我们将通过电子邮件或服务通知您变更。

四、联系我们
如有疑问或投诉，请通过电子邮件联系我们：2113979520@qq.com

如果您不同意上述条款，请立即停止使用本软件。''';

  Future<void> _launchWebsite(BuildContext context) async {
    try {
      final Uri url = Uri.parse(_websiteUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomToast.show(
            context,
            message: '无法打开网站',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          message: '打开网站失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _copyWebsiteUrl(BuildContext context) async {
    try {
      await Clipboard.setData(const ClipboardData(text: _websiteUrl));
      if (context.mounted) {
        CustomToast.show(
          context,
          message: '网址已复制到剪贴板',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          message: '复制失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  // 构建格式化的内容
  List<Widget> _buildFormattedContent() {
    final List<Widget> widgets = [];

    // 欢迎语
    widgets.add(_buildSectionTitle('欢迎使用小懿AI'));
    widgets.add(_buildContentText('欢迎使用小懿AI（以下简称"应用程序"或"服务"）。本软件专为技术学习与测试设计，严禁用于商业用途。一旦使用本软件，即视为您同意以下免责声明、使用条款及隐私政策：'));
    widgets.add(SizedBox(height: 20.h));

    // 一、免责声明
    widgets.add(_buildSectionTitle('一、免责声明'));
    widgets.add(_buildContentText('本应用仅提供AI对话服务，所有对话内容均由AI模型实时生成。由于AI技术的局限性，生成的内容可能存在错误、偏差或不准确的情况。因此，用户需自行承担使用本软件所带来的风险，包括但不限于因依赖AI生成内容而产生的任何损失或损害。'));
    widgets.add(SizedBox(height: 20.h));

    // 二、使用条款
    widgets.add(_buildSectionTitle('二、使用条款'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('2.1 接受条款'));
    widgets.add(_buildContentText('您访问和使用服务的前提是您接受并遵守这些条款。这些条款适用于所有访问者、用户以及访问或使用服务的其他人。通过访问或使用服务，您同意受这些条款和条件的约束。如果您不同意这些条款的任何部分，则您可能无法访问服务。您同意您创作作品中的所有角色均年满18岁。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('2.2 数据处理与隐私'));
    widgets.add(_buildBulletPoint('数据收集：为确保软件正常运行和优化服务，我们仅收集必要的模型调用信息，如调用的时间、模型类型等。'));
    widgets.add(_buildBulletPoint('Token用量记录：我们会记录token用量统计数据，该记录仅保存30天，之后将自动删除。'));
    widgets.add(_buildBulletPoint('隐私保护：严格遵守隐私保护原则，我们不会存储任何对话内容，也不会收集用户的隐私信息，如姓名、联系方式、身份证号等。您访问和使用服务的前提是您接受并遵守我们的隐私政策。'));
    widgets.add(_buildBulletPoint('设备信息：设备信息及个人数据也不在我们的收集范围内，以充分保障用户的隐私安全。'));
    widgets.add(_buildContentText('您有责任保护用于访问服务的密码，并对使用您的密码进行的任何活动或操作负责。您同意不向任何第三方透露您的密码。一旦发现任何安全漏洞或未经授权使用您的帐户的情况，您必须立即通知我们（邮箱：2113979520@qq.com）。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('2.3 用户内容与知识产权'));
    widgets.add(_buildContentText('AI生成的内容可能涉及第三方权益，包括但不限于版权、商标权等。用户在使用AI生成内容时应谨慎行事，充分评估可能的法律风险。若因使用AI生成内容而引发任何纠纷或法律责任，均由用户自行承担，本软件开发者及运营方不承担相关责任。'));
    widgets.add(SizedBox(height: 8.h));
    widgets.add(_buildContentText('我们的服务允许您发布内容。您应对您发布到服务的内容负责，包括其合法性、可靠性和适当性。通过将内容发布到服务，您授予我们在服务上和通过服务使用、修改、公开展示、复制和分发此类内容的权利和许可。您声明并保证：（i）内容属于您或您有权使用它，（ii）发布内容不侵犯任何人的隐私权、版权等权利。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('2.4 内容限制与禁止内容'));
    widgets.add(_buildContentText('您不得传输任何非法、冒犯、威胁、诽谤、淫秽或其他令人反感的内容，包括但不限于色情、仇恨言论、恶意软件等。公司保留删除不当内容并限制服务使用权的权利。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('2.5 免责声明与责任限制'));
    widgets.add(_buildContentText('应用程序以"原样"提供，不保证无错误或满足特定需求。公司不对间接损害（如利润损失）负责。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('2.6 终止'));
    widgets.add(_buildContentText('我们可能因违反条款等原因随时终止您的账户。如需终止账户，您可停止使用服务。'));
    widgets.add(SizedBox(height: 20.h));

    // 三、隐私政策
    widgets.add(_buildSectionTitle('三、隐私政策'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('3.1 概述与定义'));
    widgets.add(_buildContentText('本隐私政策描述了当您使用本服务时，我们关于收集、使用和披露您的个人信息的政策和程序。通过使用本服务，您同意按照本隐私政策收集和使用您的个人信息。"个人信息"指与已识别或可识别个人相关的任何信息。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('3.2 收集的个人信息'));
    widgets.add(_buildContentText('我们可能会要求您提供电子邮件地址以注册和沟通。用户内容或聊天通信中包含的个人信息可能会被存储并被其他用户访问，我们不对其他用户的行为负责。'));
    widgets.add(SizedBox(height: 8.h));
    widgets.add(_buildContentText('通过cookies等技术，我们自动收集使用数据（如IP地址、浏览器类型、访问时间等），包括移动设备信息（如设备ID、操作系统）。'));
    widgets.add(SizedBox(height: 8.h));
    widgets.add(_buildContentText('若通过第三方社交媒体服务（如Discord）注册，我们可能收集您的姓名、电子邮件等信息。'));
    widgets.add(SizedBox(height: 8.h));
    widgets.add(_buildContentText('在使用应用程序时，经您许可，我们可能收集设备相机和照片库中的信息。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('3.3 使用与共享个人信息'));
    widgets.add(_buildContentText('个人信息用于提供服务、管理账户、履行合同、联系您、管理请求等，可能与服务提供商、关联公司、商业伙伴共享，或因法律要求披露。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('3.4 保留与权利'));
    widgets.add(_buildContentText('个人信息仅在必要时保留。如需访问、删除或纠正个人信息，请联系2113979520@qq.com。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('3.5 儿童政策'));
    widgets.add(_buildContentText('服务不针对13岁以下儿童，我们不会故意收集其个人信息。若发现此类情况，我们会删除相关信息。'));
    widgets.add(SizedBox(height: 12.h));

    widgets.add(_buildSubSectionTitle('3.6 政策变更'));
    widgets.add(_buildContentText('隐私政策可能更新，我们将通过电子邮件或服务通知您变更。'));
    widgets.add(SizedBox(height: 20.h));

    // 四、联系我们
    widgets.add(_buildSectionTitle('四、联系我们'));
    widgets.add(_buildContentText('如有疑问或投诉，请通过电子邮件联系我们：2113979520@qq.com'));
    widgets.add(SizedBox(height: 20.h));

    // 结束语
    widgets.add(_buildContentText('如果您不同意上述条款，请立即停止使用本软件。'));

    return widgets;
  }

  // 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTheme.titleStyle.copyWith(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  // 构建子章节标题
  Widget _buildSubSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTheme.bodyStyle.copyWith(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 构建正文内容
  Widget _buildContentText(String content) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        content,
        style: AppTheme.bodyStyle.copyWith(
          fontSize: 13.sp,
          height: 1.6,
        ),
      ),
    );
  }

  // 构建项目符号内容
  Widget _buildBulletPoint(String content) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 13.sp,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: Text('关于我们', style: AppTheme.titleStyle),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 应用图标或Logo
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 2.w,
                ),
              ),
              child: Icon(
                Icons.info_outline,
                size: 40.sp,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),

            // 应用名称
            Text(
              '小懿AI',
              style: AppTheme.titleStyle.copyWith(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),

            // 版本信息
            Text(
              'Version $_version',
              style: AppTheme.secondaryStyle.copyWith(
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 24.h),

            // 官网地址操作区域
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Text(
                    '官方网站',
                    style: AppTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _websiteUrl,
                    style: AppTheme.secondaryStyle.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      // 访问网站按钮
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _launchWebsite(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppTheme.buttonGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.open_in_browser, color: Colors.white, size: 16.sp),
                                SizedBox(width: 4.w),
                                Text('访问网站', style: AppTheme.buttonTextStyle.copyWith(fontSize: 12.sp)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // 复制地址按钮
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _copyWebsiteUrl(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(color: AppTheme.primaryColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.copy, color: AppTheme.primaryColor, size: 16.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  '复制地址',
                                  style: AppTheme.buttonTextStyle.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // 用户协议和隐私政策内容 - 格式化显示
            ..._buildFormattedContent(),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
