**`reactive_state_machine`** offers a flexible and user-friendly approach to creating reactive hierarchical finite state machines. It's written in pure Dart.

> Note: This package is not yet production-ready. APIs may changes in future version.

This package introduces two types of StateMachines. Both are hierarchical finite state machines, but they differ in how states and transitions are defined and used. Both implement the `StateMachineBase` interface.

**`EventStateMachine`** is a state machine that receives input from an event bus. Events are processed based on the current state and may trigger side effects or state transitions. It works best when state machine should react to a stream or when you need to manage multiple event source simultaneously.

**`CommandStateMachine`** is a state machine interacted with through the invocation of the state's methods. This machine is designed to leverage Dart's pattern matching, enabling compile-time safe interactions by explicitly defining permissible transitions. It works best when the consumer of the state machine want to imperatively interact with it.

Transitions and event processing rely on State and Event types, not on object equality.

State machines don't enforce a specific reactivity API, giving developers flexibility in choosing implementations like `Stream`, `ChangeNotifier`, `BehaviorSubject`, and more.

This package includes a Dart `Stream`-based implementation for both machine types: `StreamEventStateMachine` and `StreamCommandStateMachine`.

The `flutter_reactive_state_machine` package provides additional implementations for Flutter's standard `Listenable`, along with other utilities tailored for Flutter.

## EventStateMachine
```dart
sealed class State {
  const State();
}

class Green extends State {
  const Green();
}

class Red extends State {
  const Red();
}

class Orange extends State {
  const Orange();
}

sealed class Event {
  const Event();
}

class TimerFinished extends Event {
  const TimerFinished();
}

final class TraficLight extends StreamEventStateMachine<State, Event> {
  TraficLight(super.initial);

  @override
  late final states = {
    // Green state
    define<Green>(($) => $
      ..onEnter(_startTimer)
      ..on<TimerFinished>((state, event) => const Orange())),

    // Orange state
    define<Orange>(($) => $
      ..onEnter(_startTimer)
      ..on<TimerFinished>((state, event) => const Red())),

    // Red state
    define<Red>(($) => $
      ..onEnter(_startTimer)
      ..on<TimerFinished>((state, event) => const Green())),
  };

  void _startTimer(_) {
    Timer(Duration(seconds: 1), () => add(const TimerFinished()));
  }
}
```

## CommandStateMachine
```dart
sealed class UserState with State<UserModel, UserState> {}

class Unknown extends UserState {
  @override
  Future<void> onEnter() async {
    final user = await machine.authenticationService.currentUser();
    if (user != null) {
      transitionTo(Authenticated(user));
    } else {
      transitionTo(Unauthenticated());
    }
  }
}

class Unauthenticated extends UserState {
  Future<bool> login() async {
    final user = await machine.authenticationService.tryLogin();
    if (user != null) {
      transitionTo(Authenticated(user));
      return true;
    } else {
      return false;
    }
  }
}

class Authenticated extends UserState {
  Authenticated(this.user);

  final User user;

  Future<void> logout() async {
    await machine.authenticationService.logout();
    transitionTo(Unauthenticated());
  }
}

final class UserModel extends StreamCommandStateMachine<UserState> {
  UserModel({
    required this.authenticationService,
  }) : super(Unknown());

  final AuthenticationService authenticationService;
}
```

## Usage
```dart
void main() async {
  final machine = MyStateMachine();

  if (machine.state case SomeState state) {
    state.yourData;
  }

  machine.ifState((TestState state) => state.doSomething());

  final content = switch (machine.state) {
    StateA() || StateB() => "A or B",
    StateC() => "C",
  };
}
```