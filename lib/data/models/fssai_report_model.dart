class FssaiReportModel {
  final String reportId;
  final Map<int, int> scores; // Map of serialNo -> score
  final DateTime? lastModified;
  final String? organizationName;
  final String? fboName;
  final String? location;
  final String? auditorName;
  final String? date;
  final String? fssaiNumber;

  FssaiReportModel({
    required this.reportId,
    required this.scores,
    this.lastModified,
    this.organizationName,
    this.fboName,
    this.location,
    this.auditorName,
    this.date,
    this.fssaiNumber,
  });

  int get totalScore {
    return scores.values.fold(0, (sum, score) => sum + score);
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'scores': scores.map((key, value) => MapEntry(key.toString(), value)), // Convert int keys to strings for Firestore
      'lastModified': lastModified?.millisecondsSinceEpoch,
      'organizationName': organizationName,
      'fboName': fboName,
      'location': location,
      'auditorName': auditorName,
      'date': date,
      'fssaiNumber': fssaiNumber,
    };
  }

  factory FssaiReportModel.fromMap(Map<String, dynamic> map) {
    // Convert string keys back to int keys
    final scoresMap = <int, int>{};
    if (map['scores'] != null) {
      final rawScores = map['scores'] as Map<dynamic, dynamic>;
      rawScores.forEach((key, value) {
        final intKey = key is String ? int.tryParse(key) ?? 0 : key as int;
        scoresMap[intKey] = value as int;
      });
    }

    return FssaiReportModel(
      reportId: map['reportId'] ?? '',
      scores: scoresMap,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'])
          : null,
      organizationName: map['organizationName'],
      fboName: map['fboName'],
      location: map['location'],
      auditorName: map['auditorName'],
      date: map['date'],
      fssaiNumber: map['fssaiNumber'],
    );
  }

  FssaiReportModel copyWith({
    String? reportId,
    Map<int, int>? scores,
    DateTime? lastModified,
    String? organizationName,
    String? fboName,
    String? location,
    String? auditorName,
    String? date,
    String? fssaiNumber,
  }) {
    return FssaiReportModel(
      reportId: reportId ?? this.reportId,
      scores: scores ?? this.scores,
      lastModified: lastModified ?? this.lastModified,
      organizationName: organizationName ?? this.organizationName,
      fboName: fboName ?? this.fboName,
      location: location ?? this.location,
      auditorName: auditorName ?? this.auditorName,
      date: date ?? this.date,
      fssaiNumber: fssaiNumber ?? this.fssaiNumber,
    );
  }

  @override
  String toString() {
    return 'FssaiReportModel(reportId: $reportId, totalScore: $totalScore)';
  }
}
