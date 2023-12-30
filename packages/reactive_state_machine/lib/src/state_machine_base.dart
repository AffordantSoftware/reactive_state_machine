class Transition<StateMachineType, StateType> {
  const Transition({
    required this.machine,
    required this.exitingState,
    required this.enteringState,
  });

  final StateMachineType machine;
  final StateType exitingState;
  final StateType enteringState;
}

abstract class StateMachineBase<StateType> {
  const StateMachineBase();

  set state(StateType newState);

  StateType get state;

  /// Called whenever a transition occurs with the given [Transition] object.
  /// A transition occurs when a new [state] is emitted.
  /// [onTransition] is called before the [state] of the state machine is updated.
  /// [onTransition] is a great spot to add logging/analytics for a specific state machine.
  ///
  /// **Note: `super.onTransition` should always be called first.**
  /// ```dart
  /// @override
  /// void onTransition(Transition transition) {
  ///   // Always call super.onTransition with the current change
  ///   super.onTransition(change);
  ///
  ///   // Custom onTransition logic goes here
  /// }
  /// ```
  ///
  // @protected
  // @mustCallSuper
  void onTransition(covariant Transition<dynamic, StateType> transition) {}

  bool isInState<SpecificState extends StateType>() {
    return state is SpecificState;
  }

  void ifState<SpecificState extends StateType>(
    Function(SpecificState) callback,
  ) {
    if (state case SpecificState s) {
      callback(s);
    }
  }
}
