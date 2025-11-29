/// Protocol categorization for organization.
///
/// Values defined in ubiquitous language:
/// - Exercise, Heat Therapy, Cold Exposure, Nutrition, Supplements, Mind, Sleep
enum Category {
  exercise('Exercise', '🏃'),
  heatTherapy('Heat Therapy', '🔥'),
  coldExposure('Cold Exposure', '🧊'),
  nutrition('Nutrition', '🥗'),
  supplements('Supplements', '💊'),
  mind('Mind', '🧘'),
  sleep('Sleep', '😴');

  const Category(this.displayName, this.icon);

  final String displayName;
  final String icon;
}
