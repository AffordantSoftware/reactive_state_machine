part of 'event_state_machine.dart';

/// Signature of a function that may or may not emit a new state
/// base on it's current state an an external event
typedef EventTransition<Event, SuperState, CurrentState extends SuperState>
    = SuperState? Function(Event, CurrentState);

/// Signature of a callback function called by the state machine
/// in various contexts that hasn't the ability to emit new state
typedef SideEffect<CurrentState> = void Function(CurrentState);

/// An event handler for a given [DefinedState]
/// created using on<Event>() api
class _StateEventHandler<SuperEvent, SuperState,
    DefinedEvent extends SuperEvent, DefinedState extends SuperState> {
  const _StateEventHandler({
    required this.isType,
    required this.type,
    required this.transition,
  });
  final bool Function(dynamic value) isType;
  final Type type;

  final EventTransition<DefinedEvent, SuperState, DefinedState> transition;

  SuperState? handle(SuperEvent e, SuperState s) =>
      transition(e as DefinedEvent, s as DefinedState);
}

/// Definition of a state
/// This class is intended to be constructed using
/// [StateDefinitionBuilder]
class _StateDefinition<SuperState, Event, DefinedState extends SuperState> {
  const _StateDefinition({
    List<_StateEventHandler> handlers = const [],
    SideEffect<DefinedState>? onEnter,
    SideEffect<DefinedState>? onExit,
    List<_StateDefinition>? nestedStatesDefinitions,
  })  : _handlers = handlers,
        _onEnterDelegate = onEnter,
        _onExit = onExit,
        _nestedStateDefinitions = nestedStatesDefinitions;

  const _StateDefinition.empty()
      : _handlers = const [],
        _onEnterDelegate = null,
        _onExit = null,
        _nestedStateDefinitions = null;

  final List<_StateEventHandler> _handlers;

  /// Called whenever entering state.
  final SideEffect<DefinedState>? _onEnterDelegate;

  /// Called whenever exiting state.
  final SideEffect<DefinedState>? _onExit;

  final List<_StateDefinition>? _nestedStateDefinitions;

  Type get _definedType => DefinedState;

  bool _matchType(dynamic object) => object is DefinedState;

  void _onEnter({
    required dynamic exitingState,
    required DefinedState enteringState,
  }) {
    // We avoid re-calling onEnter again if it's only a child-state transition
    if (exitingState is! DefinedState) {
      _onEnterDelegate?.call(enteringState);
    }
    _nestedStateDefinition(enteringState)?._onEnter(
      exitingState: exitingState,
      enteringState: enteringState,
    );
  }

  void onExit({
    required DefinedState exitingState,
    required dynamic enteringState,
  }) {
    // We prevent calling onExit if we transitioning to a child-state
    if (enteringState is! DefinedState) {
      _onExit?.call(exitingState);
    }
    _nestedStateDefinition(exitingState)?.onExit(
      exitingState: exitingState,
      enteringState: enteringState,
    );
  }

  SuperState? add(
    Event event,
    DefinedState state,
  ) {
    final stateHandlers = _handlers.where(
      (handler) => handler.isType(event),
    );
    for (final handler in stateHandlers) {
      final nextState = handler.handle(event, state) as SuperState?;
      if (nextState != null) return nextState;
    }
    final nestedDefinition = _nestedStateDefinition(state);
    if (nestedDefinition != null) {
      return nestedDefinition.add(event, state);
    }
    return null;
  }

  _StateDefinition? _nestedStateDefinition(DefinedState state) {
    try {
      return _nestedStateDefinitions
          ?.firstWhere((def) => def._matchType(state));
    } catch (_) {
      return null;
    }
  }
}
