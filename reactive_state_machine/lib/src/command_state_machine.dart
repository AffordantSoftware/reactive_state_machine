import 'dart:async';

import 'state_machine_base.dart';

typedef CommandStateMachineTransition<StateType>
    = Transition<CommandStateMachine, StateType>;

abstract class CommandStateMachine<
        StateType extends State<CommandStateMachine<StateType>, StateType>>
    extends StateMachineBase<StateType> {
  CommandStateMachine(StateType initial) {
    initial._machine = this;
    initial.onEnter();
  }

  @override
  void onTransition(CommandStateMachineTransition<StateType> transition) {}

  void _requestTransition<Requester>(Requester from, StateType to) {
    if (state is! Requester) return;
    state.onExit();
    to._machine = this;
    onTransition(Transition(
      machine: this,
      exitingState: state,
      enteringState: to,
    ));
    state = to;
    state.onEnter();
  }
}

mixin State<MachineType extends CommandStateMachine<StateType>,
    StateType extends State<MachineType, StateType>> {
  MachineType? _machine;

  MachineType get machine => _machine!;

  FutureOr<void> onEnter() {}

  FutureOr<void> onExit() {}

  void transitionTo(StateType state) {
    _machine?._requestTransition(this, state);
  }
}

abstract class StreamCommandStateMachine<
    StateType extends State<StreamCommandStateMachine<StateType>,
        StateType>> extends CommandStateMachine<StateType> {
  StreamCommandStateMachine(super.initial) : _state = initial;

  StateType _state;

  final _controller = StreamController<StateType>.broadcast();

  @override
  StateType get state => _state;

  Stream<StateType> get stream => _controller.stream;

  @override
  set state(StateType newState) {
    _state = newState;
    _controller.add(newState);
  }
}
