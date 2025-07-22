/// 举报状态常量
class ReportStatus {
  static const int all = 0; // 全部
  static const int pending = 1; // 待审核
  static const int approved = 2; // 已通过
  static const int rejected = 3; // 已拒绝
  static const int handled = 4; // 已处理

  static String getName(int status) {
    switch (status) {
      case pending:
        return "待审核";
      case approved:
        return "已通过";
      case rejected:
        return "已拒绝";
      case handled:
        return "已处理";
      default:
        return "未知状态";
    }
  }

  static List<Map<String, dynamic>> getOptions() {
    return [
      {'value': all, 'label': '全部'},
      {'value': pending, 'label': '待审核'},
      {'value': approved, 'label': '已通过'},
      {'value': rejected, 'label': '已拒绝'},
      {'value': handled, 'label': '已处理'},
    ];
  }
}

/// 举报类型常量
class ReportType {
  static const int all = 0; // 全部
  static const int illegal = 1; // 违规内容
  static const int copyright = 2; // 侵权
  static const int plagiarism = 3; // 抄袭
  static const int porn = 4; // 色情
  static const int violence = 5; // 暴力
  static const int other = 6; // 其他

  static String getName(int type) {
    switch (type) {
      case illegal:
        return "违规内容";
      case copyright:
        return "侵权";
      case plagiarism:
        return "抄袭";
      case porn:
        return "色情";
      case violence:
        return "暴力";
      case other:
        return "其他";
      default:
        return "未知类型";
    }
  }

  static List<Map<String, dynamic>> getOptions() {
    return [
      {'value': all, 'label': '全部类型'},
      {'value': illegal, 'label': '违规内容'},
      {'value': copyright, 'label': '侵权'},
      {'value': plagiarism, 'label': '抄袭'},
      {'value': porn, 'label': '色情'},
      {'value': violence, 'label': '暴力'},
      {'value': other, 'label': '其他'},
    ];
  }
}

/// 处罚类型常量
class PenaltyType {
  static const int all = 0; // 全部
  static const int warning = 1; // 警告
  static const int contentHideTemp = 2; // 临期屏蔽（3天后自动删除）
  static const int contentRemove = 3; // 永久删除
  static const int authorBanTemp = 4; // 临时封禁作者（可变时长）
  static const int authorBanPerm = 5; // 永久封杀作者
  static const int authorBanAndRemove = 6; // 永久封杀作者并下架所有作品

  static String getName(int type) {
    switch (type) {
      case warning:
        return "警告";
      case contentHideTemp:
        return "临时屏蔽";
      case contentRemove:
        return "永久删除";
      case authorBanTemp:
        return "临时封禁作者";
      case authorBanPerm:
        return "永久封禁作者";
      case authorBanAndRemove:
        return "永久封禁并移除作品";
      default:
        return "未知处罚";
    }
  }

  static List<Map<String, dynamic>> getOptions() {
    return [
      {'value': all, 'label': '全部处罚'},
      {'value': warning, 'label': '警告'},
      {'value': contentHideTemp, 'label': '临时屏蔽'},
      {'value': contentRemove, 'label': '永久删除'},
      {'value': authorBanTemp, 'label': '临时封禁作者'},
      {'value': authorBanPerm, 'label': '永久封禁作者'},
      {'value': authorBanAndRemove, 'label': '永久封禁并移除作品'},
    ];
  }

  static bool needsDuration(int type) {
    return type == authorBanTemp;
  }
}

/// 处罚状态常量
class PenaltyStatus {
  static const int all = 0; // 全部
  static const int active = 1; // 生效中
  static const int expired = 2; // 已结束
  static const int revoked = 3; // 已撤销

  static String getName(int status) {
    switch (status) {
      case active:
        return "生效中";
      case expired:
        return "已结束";
      case revoked:
        return "已撤销";
      default:
        return "未知状态";
    }
  }

  static List<Map<String, dynamic>> getOptions() {
    return [
      {'value': all, 'label': '全部'},
      {'value': active, 'label': '生效中'},
      {'value': expired, 'label': '已结束'},
      {'value': revoked, 'label': '已撤销'},
    ];
  }
}
