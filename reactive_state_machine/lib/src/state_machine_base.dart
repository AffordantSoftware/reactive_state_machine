class Transition<StateMachineType, StateType> {
  const Transition({
    required this.machine,
    required this.currentState,
    required this.nextState,
  });

  final StateMachineType machine;
  final StateType currentState;
  final StateType nextState;
}

abstract class StateMachineBase<StateType> {
  const StateMachineBase();

  set state(StateType newState);

  StateType get state;

  /// Called whenever a [change] occurs with the given [change].
  /// A [change] occurs when a new `state` is emitted.
  /// [onChange] is called before the `state` of the `cubit` is updated.
  /// [onChange] is a great spot to add logging/analytics for a specific `cubit`.
  ///
  /// **Note: `super.onChange` should always be called first.**
  /// ```dart
  /// @override
  /// void onChange(Change change) {
  ///   // Always call super.onChange with the current change
  ///   super.onChange(change);
  ///
  ///   // Custom onChange logic goes here
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// * [BlocObserver] for observing [Cubit] behavior globally.
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
