import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart';

extension CategoryUiX on Category {
  IconData get iconData {
    switch (this) {
      case Category.exercise:
        return LucideIcons.dumbbell;
      case Category.heatTherapy:
        return LucideIcons.flame;
      case Category.coldExposure:
        return LucideIcons.snowflake;
      case Category.nutrition:
        return LucideIcons.utensils;
      case Category.supplements:
        return LucideIcons.pill;
      case Category.mind:
        return LucideIcons.brain;
      case Category.sleep:
        return LucideIcons.moon;
    }
  }
}
