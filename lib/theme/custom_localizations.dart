import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// 自定义Material组件的中文本地化
class ChineseMaterialLocalizations extends DefaultMaterialLocalizations {
  const ChineseMaterialLocalizations();

  @override
  String get selectAllButtonLabel => '全选';

  @override
  String get copyButtonLabel => '复制';

  @override
  String get cutButtonLabel => '剪切';

  @override
  String get pasteButtonLabel => '粘贴';

  @override
  String get deleteButtonTooltip => '删除';

  @override
  String get closeButtonLabel => '关闭';

  @override
  String get searchFieldLabel => '搜索';

  @override
  String get contextMenuCopyButtonLabel => '复制';

  @override
  String get contextMenuCutButtonLabel => '剪切';

  @override
  String get contextMenuPasteButtonLabel => '粘贴';

  @override
  String get contextMenuSelectAllButtonLabel => '全选';

  @override
  String get shareButtonLabel => '分享';
}

// 中文Material本地化委托
class ChineseMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const ChineseMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'zh';
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
        const ChineseMaterialLocalizations());
  }

  @override
  bool shouldReload(ChineseMaterialLocalizationsDelegate old) => false;
}
