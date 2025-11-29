final locator = ModuleLocator.instance;

class Module<T> {
  final T Function() builder;
  final bool lazy;
  Type get type => T;

  T? _instance;

  Module({required this.builder, required this.lazy});

  void _createInstance() {
    _instance ??= builder();
  }

  T getInstance() {
    _createInstance();
    return _instance!;
  }
}

class ModuleLocator {
  ModuleLocator._();
  static final ModuleLocator instance = ModuleLocator._();
  final Map<Type, Module> _modules = {};

  void registerMany<T>(List<Module> modules) {
    for (var module in modules) {
      final type = module.type;
      if (_modules.containsKey(type)) {
        throw ModuleAlreadyRegisteredException(type);
      }
      _modules[type] = module;

      // Create the instance immediately if it's not lazy
      if (!module.lazy) {
        module._createInstance();
      }
    }
  }

  T call<T>() {
    final module = _modules[T];
    if (module == null) {
      throw ModuleNotFoundException(T);
    }
    // getInstance will now correctly return the cached instance for non-lazy
    // or create/return the cached instance for lazy.
    return (module as Module<T>).getInstance();
  }

  void reset() {
    // Clear instances when resetting
    for (var module in _modules.values) {
      module._instance = null;
    }
    _modules.clear();
  }
}

class ModuleNotFoundException implements Exception {
  final Type type;
  ModuleNotFoundException(this.type);
}

class ModuleAlreadyRegisteredException implements Exception {
  final Type type;
  ModuleAlreadyRegisteredException(this.type);
}
