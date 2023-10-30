import 'package:flutter/foundation.dart';
import 'package:reactive_state_machine/reactive_state_machine.dart';

abstract class ListenableEventStateMachine<StateType, EventType>
    extends EventStateMachine<StateType, EventType> with ChangeNotifier {
  ListenableEventStateMachine(super.initial) : _state = initial;

  StateType _state;

  @override
  StateType get state => _state;

  @override
  set state(StateType newState) {
    _state = newState;
    notifyListeners();
  }
}

abstract class ListenableCommandStateMachine<
    StateType extends State<ListenableCommandStateMachine<StateType>,
        StateType>> extends CommandStateMachine<StateType> with ChangeNotifier {
  ListenableCommandStateMachine(super.initial) : _state = initial;

  StateType _state;

  @override
  StateType get state => _state;

  @override
  set state(StateType newState) {
    _state = newState;
    notifyListeners();
  }
}
