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
      currentState: state,
      nextState: to,
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
