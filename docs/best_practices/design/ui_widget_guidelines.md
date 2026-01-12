## 1. Classes Over Helper Methods

Extract UI into `StatelessWidget` classes, not methods that return widgets.

```dart
// ❌ Rebuilds every time, breaks Flutter's caching
Widget _buildHeader() => Container(child: const Text('Header'));

// ✅ Flutter can skip rebuilding this subtree
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});
  @override
  Widget build(BuildContext context) => Container(child: const Text('Header'));
}
```

**Why:** Helper methods share parent's `BuildContext` and rebuild on every parent rebuild. Classes get their own `Element` node that Flutter can cache.

**Clarification:** Methods returning data (booleans, strings) are fine. Only avoid methods returning `Widget`.

---

## 2. Const in Hot Paths

Add `const` to constructors and instantiations in lists, animations, and frequently rebuilt areas.

```dart
// ❌ New allocation every rebuild
Text('Hello', style: TextStyle(fontSize: 16))

// ✅ Compile-time constant, reused across rebuilds
const Text('Hello', style: TextStyle(fontSize: 16))
```

**Where it matters:** List items, widgets inside animations, widgets below changing state.

**Where it doesn't:** Static screens that rebuild rarely. Don't obsess over a settings page.

---

## 3. Composition Over Inheritance

Build widgets by combining smaller widgets. Never create `BasePage` or `BaseWidget`.

```dart
// ❌ Breaks dirty-state tracking
class ProfilePage extends BasePage { }

// ✅ Compose with wrappers
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc(),
      child: const Scaffold(body: ProfileContent()),
    );
  }
}
```

---

## 4. StatelessWidget by Default

Use `StatefulWidget` only when the widget manages its own internal state.

```
Need internal state?
├── NO  → StatelessWidget
└── YES → Ancestor manages it?
          ├── YES → StatelessWidget (receive via constructor/Provider)
          └── NO  → StatefulWidget
```

**Ephemeral state stays local:** Tab index, animation controller, text field content belong in `StatefulWidget`, not global stores.

---

## 5. Separate UI from Logic

Widgets receive data and emit events. They don't fetch, validate, or compute.

### State Management Options

Use ValueNotifier
### Page/View/Content Pattern

```dart
// Sealed state classes
sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final User user;
  const ProfileLoaded(this.user);
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
}

// ViewModel
class ProfileViewModel {
  ProfileViewModel({required UserRepository userRepository})
      : _userRepository = userRepository;

  final UserRepository _userRepository;
  final _state = ValueNotifier<ProfileState>(const ProfileLoading());

  ValueListenable<ProfileState> get state => _state;

  Future<void> loadProfile(String userId) async {
    _state.value = const ProfileLoading();
    final result = await _userRepository.getById(userId);
    result.fold(
      (failure) => _state.value = ProfileError(failure.message),
      (user) => _state.value = ProfileLoaded(user),
    );
  }

  void dispose() {
    _state.dispose();
  }
}

// View
class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.userId});
  final String userId;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel = ProfileViewModel(
    userRepository: locator<UserRepository>(),
  );

  @override
  void initState() {
    super.initState();
    _viewModel.loadProfile(widget.userId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ValueListenableBuilder<ProfileState>(
        valueListenable: _viewModel.state,
        builder: (context, state, _) => switch (state) {
          ProfileLoading() => const Center(child: CircularProgressIndicator()),
          ProfileLoaded(:final user) => Center(child: Text(user.displayName)),
          ProfileError(:final message) => Center(child: Text(message)),
        },
      ),
    );
  }
}
```

---

## 6. Lazy List Building

Use `ListView.builder` for any list that can grow or has expensive items.

```dart
// ❌ All items built immediately
ListView(children: items.map(ItemTile.new).toList())

// ✅ Only visible items built
ListView.builder(
  itemCount: items.length,
  itemExtent: 72, // Fixed height = scroll perf boost
  itemBuilder: (context, index) => ItemTile(item: items[index]),
)
```

---

## 7. Keys for Dynamic Lists

Add stable keys to stateful widgets in lists that reorder or remove items.

```dart
ListView.builder(
  itemCount: todos.length,
  itemBuilder: (context, index) => TodoTile(
    key: ValueKey(todos[index].id), // State follows item
    todo: todos[index],
  ),
)
```

|Scenario|Key Type|
|---|---|
|Has unique ID|`ValueKey(item.id)`|
|Object without ID|`ObjectKey(item)`|

**Anti-pattern:** `Key(Random()...)` destroys and recreates every frame.

---

## 8. Pure Build Methods

Keep `build()` pure. Move async and heavy work elsewhere.

```dart
// ❌ Expensive transform on every rebuild
@override
Widget build(BuildContext context) {
  final processed = items.map(expensiveTransform).toList();
  return ListView(children: processed.map(Text.new).toList());
}

// ✅ Compute once, use isolate for heavy work
@override
void initState() {
  super.initState();
  compute(_transform, items).then((r) {
    if (mounted) setState(() => _processed = r);
  });
}
```

---

## 9. Avoid Opacity Widget

`Opacity` triggers expensive `saveLayer()`. Use alternatives.

```dart
// ❌ Triggers saveLayer
Opacity(opacity: 0.5, child: Container(color: Colors.black))

// ✅ Direct color opacity
Container(color: Colors.black.withOpacity(0.5))

// ✅ Animated opacity without saveLayer
FadeTransition(opacity: _animation, child: widget)
```

---

## 10. RepaintBoundary for Animations

Wrap infinite animations so they don't repaint the entire page.

```dart
RepaintBoundary(child: SpinningLoader())
```

**Diagnose first:** `debugRepaintRainbowEnabled = true` shows what's repainting.

**Wrap:** Loaders, video players, maps, frequently-updating custom painters.

**Don't wrap:** Static content (adds overhead).

---

## 11. Widget Granularity

One widget = one responsibility. Split when you can't describe it in one sentence.

**Split when:**

- Repeated patterns exist
- Sections have different rebuild frequencies
- Hard to test

```dart
// ✅ Composed from focused widgets
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(children: [
        ProfileHeader(),
        ProfileStats(),
        ProfileActions(),
      ]),
    );
  }
}
```


---

## 12. Never Override Widget Equality

```dart
// ❌ Breaks Flutter's reconciliation, causes O(N²) perf hit
@override
bool operator ==(Object other) => other is MyWidget && other.data == data;
```

Let Flutter handle widget comparison. Custom equality is never needed.

---

## PR Checklist

- [ ] UI in `StatelessWidget` classes, not helper methods
- [ ] `const` in hot paths
- [ ] `ListView.builder` for dynamic lists
- [ ] Keys on stateful list items
- [ ] No async/heavy work in `build()`
- [ ] `Opacity` avoided where possible
- [ ] State management separates UI from logic

---

## Lint Config

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    sized_box_for_whitespace: true
    use_key_in_widget_constructors: true
    avoid_unnecessary_containers: true
```