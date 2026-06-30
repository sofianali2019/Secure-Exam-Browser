class CourseInfo {
  final int id;
  final String fullName;
  final String shortName;
  final String displayName;
  final String summary;
  final int? startDate;
  final int? endDate;
  final String? courseCategory;
  final int? progress;
  final bool isFavourite;
  final bool hidden;
  final int? timeaccess;
  final String? courseImageUrl;

  const CourseInfo({
    required this.id,
    required this.fullName,
    this.shortName = '',
    this.displayName = '',
    this.summary = '',
    this.startDate,
    this.endDate,
    this.courseCategory,
    this.progress,
    this.isFavourite = false,
    this.hidden = false,
    this.timeaccess,
    this.courseImageUrl,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) => CourseInfo(
    id: json['id'] as int,
    fullName: json['fullname'] as String? ?? '',
    shortName: json['shortname'] as String? ?? '',
    displayName: json['displayname'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    startDate: json['startdate'] as int?,
    endDate: json['enddate'] as int?,
    courseCategory: json['coursecategory'] as String?,
    progress: json['progress'] as int?,
    isFavourite: json['isfavourite'] as bool? ?? false,
    hidden: json['hidden'] as bool? ?? false,
    timeaccess: json['timeaccess'] as int?,
    courseImageUrl: json['courseimage'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullname': fullName,
    'shortname': shortName,
    'displayname': displayName,
    'summary': summary,
    'startdate': startDate,
    'enddate': endDate,
    'coursecategory': courseCategory,
    'progress': progress,
    'isfavourite': isFavourite,
    'hidden': hidden,
    'timeaccess': timeaccess,
    'courseimage': courseImageUrl,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseInfo && id == other.id && fullName == other.fullName;

  @override
  int get hashCode => Object.hash(id, fullName);

  @override
  String toString() =>
      'CourseInfo(id: $id, fullName: $fullName, shortName: $shortName)';
}
