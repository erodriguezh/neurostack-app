mixin EntityMixin<T> {
  T get id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityMixin<T> &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType(id: $id)';
}
