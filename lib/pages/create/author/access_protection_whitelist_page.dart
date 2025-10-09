import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';

class AccessProtectionWhitelistPage extends StatefulWidget {
  final List<String> initialWhitelist;

  const AccessProtectionWhitelistPage({
    super.key,
    required this.initialWhitelist,
  });

  @override
  State<AccessProtectionWhitelistPage> createState() =>
      _AccessProtectionWhitelistPageState();
}

class _AccessProtectionWhitelistPageState
    extends State<AccessProtectionWhitelistPage> {
  late TextEditingController _textController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.initialWhitelist.join('\n'),
    );
    _textController.addListener(() {
      final currentList = _getCurrentWhitelist();
      final hasChanges = !_listsEqual(currentList, widget.initialWhitelist);
      if (_hasChanges != hasChanges) {
        setState(() => _hasChanges = hasChanges);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<String> _getCurrentWhitelist() {
    return _textController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _saveAndReturn() {
    final newWhitelist = _getCurrentWhitelist();
    Navigator.pop(context, newWhitelist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.border.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.shadowColor.withOpacity(0.1),
                            blurRadius: 6.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppTheme.textPrimary,
                        size: 16.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '编辑白名单',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  // 保存按钮
                  GestureDetector(
                    onTap: _hasChanges ? _saveAndReturn : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: _hasChanges
                            ? LinearGradient(
                                colors: AppTheme.buttonGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _hasChanges ? null : AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: _hasChanges
                            ? [
                                BoxShadow(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '保存',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: _hasChanges
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 提示信息
            Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '请输入允许访问的IP地址或域名，每行一个。\n例如：192.168.1.1 或 example.com',
                      style: TextStyle(
                        fontSize: AppTheme.smallSize,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 文本编辑区域
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor.withOpacity(0.05),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: '192.168.1.1\nexample.com\napi.example.com',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.5),
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15.sp,
                    height: 1.6,
                  ),
                ),
              ),
            ),

            // 底部信息栏
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.border.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    color: AppTheme.textSecondary,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '共 ${_getCurrentWhitelist().length} 条记录',
                    style: TextStyle(
                      fontSize: AppTheme.smallSize,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_hasChanges) ...[
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '已修改',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

