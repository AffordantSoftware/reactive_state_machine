import 'package:reactive_state_machine/reactive_state_machine.dart';
import 'package:test/test.dart';

import 'utils.dart';

abstract class Event {}

class EventA extends Event {}

abstract class State {
  @override
  bool operator ==(Object value) => false;

  @override
  int get hashCode => 0;
}

class StateA extends State {}

class StateB extends State {}

class DummyStateMachine extends StreamEventStateMachine<State, Event> {
  DummyStateMachine({
    State? initialState,
  }) : super(initialState ?? StateA());

  @override
  late final states = {
    define<StateA>(
      ($) => $
        ..onEnter((_) => onEnterCalls.add("StateA"))
        ..onExit((_) => onExitCalls.add("StateA"))
        ..on<EventA>((_, __) => StateB()),
    ),
    define<StateB>(
      ($) => $
        ..onEnter((_) => onEnterCalls.add("StateB"))
        ..onExit((_) => onExitCalls.add("StateB")),
    ),
  };

  List<String> onEnterCalls = [];
  List<String> onExitCalls = [];
}

void main() {
  group("Lifecycle", () {
    test("Initial state's onEnter is called at initialization", () {
      final sm = DummyStateMachine();
      expect(sm.onEnterCalls, ["StateA"]);
    });

    test("onEnter is called when entering new state", () async {
      final sm = DummyStateMachine();
      sm.add(EventA());

      await wait();

      expect(sm.onEnterCalls, ["StateA", "StateB"]);
    });

    test("onExit is called when exiting a state", () async {
      final sm = DummyStateMachine();
      sm.add(EventA());

      await wait();

      expect(sm.onExitCalls, ["StateA"]);
    });
  });
}
