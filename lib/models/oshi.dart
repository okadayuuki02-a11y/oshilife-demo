class Oshi {
  final String id;

  String name;
  String groupName;
  String furigana;
  String nickname;
  DateTime? birthday;
  String hometown;
  String height;
  String hobby;
  String skill;
  String likes;
  String officialUrl;
  String profile;
  String personalNickname;
  String oshiReason;
  String personalMemo;
  bool isPrimary;
  DateTime? oshiStartDate;
  String favoriteSong;
  String? memberColorHex;
  final DateTime registeredAt;
  bool isGraduated;
  DateTime? graduatedAt;

  // 推し写真（Demo版は shared_preferences に保存するため Base64）
  String? profilePhotoBase64;
  List<String> profilePhotoHistory;

  // Freeプラン移行時などに使う「管理休止中」の土台。
  // 現時点では課金機能そのものは未接続。
  bool isManagementPaused;
  DateTime? managementPausedAt;
  int? frozenOshiDays;
  int? frozenRegisteredDays;

  Oshi({
    required this.id,
    required this.name,
    required this.groupName,
    this.furigana = '',
    this.nickname = '',
    this.birthday,
    this.hometown = '',
    this.height = '',
    this.hobby = '',
    this.skill = '',
    this.likes = '',
    this.officialUrl = '',
    this.profile = '',
    this.personalNickname = '',
    this.oshiReason = '',
    this.personalMemo = '',
    this.isPrimary = false,
    this.oshiStartDate,
    this.favoriteSong = 'まだ分からない',
    this.memberColorHex,
    DateTime? registeredAt,
    this.isGraduated = false,
    this.graduatedAt,
    this.profilePhotoBase64,
    List<String>? profilePhotoHistory,
    this.isManagementPaused = false,
    this.managementPausedAt,
    this.frozenOshiDays,
    this.frozenRegisteredDays,
  }) : registeredAt = registeredAt ?? DateTime.now(),
       profilePhotoHistory = profilePhotoHistory ?? <String>[];

  bool get isActive => !isGraduated;

  int? get oshiDays {
    if (isManagementPaused && frozenOshiDays != null) {
      return frozenOshiDays;
    }
    if (oshiStartDate == null) return null;

    final today = DateTime.now();
    final start = DateTime(
      oshiStartDate!.year,
      oshiStartDate!.month,
      oshiStartDate!.day,
    );
    final endDate = isGraduated && graduatedAt != null ? graduatedAt! : today;
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  int get registeredDays {
    if (isManagementPaused && frozenRegisteredDays != null) {
      return frozenRegisteredDays!;
    }

    final today = DateTime.now();
    final start = DateTime(
      registeredAt.year,
      registeredAt.month,
      registeredAt.day,
    );
    final now = DateTime(today.year, today.month, today.day);
    return now.difference(start).inDays + 1;
  }

  void graduate({DateTime? date}) {
    isGraduated = true;
    graduatedAt = date ?? DateTime.now();
    isPrimary = false;
  }

  void restore() {
    isGraduated = false;
    graduatedAt = null;
  }

  void pauseManagement({DateTime? date}) {
    if (isManagementPaused) return;
    final currentOshiDays = oshiDays;
    final currentRegisteredDays = registeredDays;
    isManagementPaused = true;
    managementPausedAt = date ?? DateTime.now();
    frozenOshiDays = currentOshiDays;
    frozenRegisteredDays = currentRegisteredDays;
    isPrimary = false;
  }

  void resumeManagement() {
    isManagementPaused = false;
    managementPausedAt = null;
    frozenOshiDays = null;
    frozenRegisteredDays = null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'groupName': groupName,
      'furigana': furigana,
      'nickname': nickname,
      'birthday': birthday?.toIso8601String(),
      'hometown': hometown,
      'height': height,
      'hobby': hobby,
      'skill': skill,
      'likes': likes,
      'officialUrl': officialUrl,
      'profile': profile,
      'personalNickname': personalNickname,
      'oshiReason': oshiReason,
      'personalMemo': personalMemo,
      'isPrimary': isPrimary,
      'oshiStartDate': oshiStartDate?.toIso8601String(),
      'favoriteSong': favoriteSong,
      'memberColorHex': memberColorHex,
      'registeredAt': registeredAt.toIso8601String(),
      'isGraduated': isGraduated,
      'graduatedAt': graduatedAt?.toIso8601String(),
      'profilePhotoBase64': profilePhotoBase64,
      'profilePhotoHistory': profilePhotoHistory,
      'isManagementPaused': isManagementPaused,
      'managementPausedAt': managementPausedAt?.toIso8601String(),
      'frozenOshiDays': frozenOshiDays,
      'frozenRegisteredDays': frozenRegisteredDays,
    };
  }

  factory Oshi.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['profilePhotoHistory'];

    return Oshi(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      furigana: json['furigana'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      birthday: DateTime.tryParse(json['birthday'] as String? ?? ''),
      hometown: json['hometown'] as String? ?? '',
      height: json['height'] as String? ?? '',
      hobby: json['hobby'] as String? ?? '',
      skill: json['skill'] as String? ?? '',
      likes: json['likes'] as String? ?? '',
      officialUrl: json['officialUrl'] as String? ?? '',
      profile: json['profile'] as String? ?? '',
      personalNickname: json['personalNickname'] as String? ?? '',
      oshiReason: json['oshiReason'] as String? ?? '',
      personalMemo: json['personalMemo'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
      oshiStartDate: json['oshiStartDate'] == null
          ? null
          : DateTime.tryParse(json['oshiStartDate'] as String),
      favoriteSong: json['favoriteSong'] as String? ?? 'まだ分からない',
      memberColorHex: json['memberColorHex'] as String?,
      registeredAt:
          DateTime.tryParse(json['registeredAt'] as String? ?? '') ??
          DateTime.now(),
      isGraduated: json['isGraduated'] as bool? ?? false,
      graduatedAt: json['graduatedAt'] == null
          ? null
          : DateTime.tryParse(json['graduatedAt'] as String),
      profilePhotoBase64: json['profilePhotoBase64'] as String?,
      profilePhotoHistory: rawHistory is List
          ? rawHistory.whereType<String>().toList()
          : <String>[],
      isManagementPaused: json['isManagementPaused'] as bool? ?? false,
      managementPausedAt: json['managementPausedAt'] == null
          ? null
          : DateTime.tryParse(json['managementPausedAt'] as String),
      frozenOshiDays: (json['frozenOshiDays'] as num?)?.toInt(),
      frozenRegisteredDays: (json['frozenRegisteredDays'] as num?)?.toInt(),
    );
  }
}
