import 'package:reactive_state_machine/reactive_state_machine.dart';
import 'package:test/test.dart';
import 'utils.dart';

abstract class Event {}

class TriggerNestedStateOnEnter extends Event {}

class TriggerNestedStateOnExit extends Event {}

abstract class State {
  @override
  bool operator ==(Object value) => false;

  @override
  int get hashCode => 0;
}

class ParentStateA extends State {}

class AChildState1 extends ParentStateA {}

class AChildState2 extends ParentStateA {}

class AChildState3 extends ParentStateA {}

class ParentStateB extends State {}

class DummyStateMachine extends StreamEventStateMachine<State, Event> {
  DummyStateMachine({
    State? initialState,
  }) : super(initialState ?? AChildState1());

  @override
  late final states = {
    define<State>(($) => $
      ..define<ParentStateA>(($) => $
        ..onEnter((_) => onEnterCalls.add("ParentStateA"))
        ..onExit((_) => onExitCalls.add("ParentStateA"))

        // Child State 1
        ..define<AChildState1>(($) => $
          ..onEnter((_) => onEnterCalls.add("AChildState1"))
          ..onExit((_) => onExitCalls.add("AChildState1"))
          ..on<TriggerNestedStateOnEnter>((e, s) => AChildState2())
          ..on<TriggerNestedStateOnExit>((e, s) => ParentStateB()))

        // Child State 2
        ..define<AChildState2>(($) => $
          ..onEnter((_) => onEnterCalls.add("AChildState2"))
          ..onExit((_) => onExitCalls.add("AChildState2")))

        // Child State 3
        ..define<AChildState3>(($) => $
          ..onEnter((_) => onEnterCalls.add("AChildState3"))
          ..onExit((_) => onExitCalls.add("AChildState3"))))
      ..define<ParentStateB>(
        ($) => $
          ..onEnter((_) => onEnterCalls.add("ParentStateB"))
          ..onExit((_) => onExitCalls.add("ParentStateB")),
      ))
  };

  List<String> onEnterCalls = [];
  List<String> onExitCalls = [];
}

void main() {
  group("deeply nested state lifecycle test", () {
    test(
        "nested state onEnter called at initialization id it's the initial state",
        () async {
      final sm = DummyStateMachine();

      await wait();

      expect(sm.onEnterCalls, ["ParentStateA", "AChildState1"]);
    });

    test("nested state onEnter called when entering sub state", () async {
      final sm = DummyStateMachine();

      sm.add(TriggerNestedStateOnEnter());

      await wait();

      expect(sm.onEnterCalls, ["ParentStateA", "AChildState1", "AChildState2"]);
      expect(sm.onExitCalls, ["AChildState1"]);
    });

    test("nested state onExit called when entering sub state", () async {
      final sm = DummyStateMachine();

      sm.add(TriggerNestedStateOnEnter());

      await wait();

      expect(sm.onEnterCalls, ["ParentStateA", "AChildState1", "AChildState2"]);
      expect(sm.onExitCalls, ["AChildState1"]);
    });

    test("parent's onEnter called when transiting to one of its sub states",
        () async {
      final sm = DummyStateMachine();

      await wait();

      expect(sm.onEnterCalls, ["ParentStateA", "AChildState1"]);
      expect(sm.onExitCalls, []);
    });

    test(
        "parent's onExit called when transiting to a state that is not one of its child",
        () async {
      final sm = DummyStateMachine();

      sm.add(TriggerNestedStateOnExit());

      await wait();

      expect(sm.onEnterCalls, ["ParentStateA", "AChildState1", "ParentStateB"]);
      expect(sm.onExitCalls, ["ParentStateA", "AChildState1"]);
    });
  });
}
