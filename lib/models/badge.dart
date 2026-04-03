class Badge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
  });

  Badge copyWith({bool? unlocked}) => Badge(
    id: id,
    title: title,
    description: description,
    icon: icon,
    unlocked: unlocked ?? this.unlocked,
  );
}
