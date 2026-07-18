enum PopularSortType {
  allTime('popular'),
  day('popular-today'),
  week('popular-week'),
  month('popular-month');

  const PopularSortType(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case PopularSortType.allTime:
        return 'All time';
      case PopularSortType.day:
        return 'Today';
      case PopularSortType.week:
        return 'This week';
      case PopularSortType.month:
        return 'This month';
    }
  }
}
