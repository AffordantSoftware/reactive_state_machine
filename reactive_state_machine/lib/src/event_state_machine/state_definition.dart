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
class _StateDefinition<Event, SuperState, DefinedState extends SuperState> {
  const _StateDefinition({
    List<_StateEventHandler> handlers = const [],
    SideEffect<DefinedState>? onEnter,
    SideEffect<DefinedState>? onExit,
    List<_StateDefinition>? nestedStatesDefinitions,
  })  : _handlers = handlers,
        _onEnter = onEnter,
        _onExit = onExit,
        _nestedStateDefinitions = nestedStatesDefinitions;

  const _StateDefinition.empty()
      : _handlers = const [],
        _onEnter = null,
        _onExit = null,
        _nestedStateDefinitions = null;

  final List<_StateEventHandler> _handlers;

  /// Called whenever entering state.
  final SideEffect<DefinedState>? _onEnter;

  /// Called whenever exiting state.
  final SideEffect<DefinedState>? _onExit;

  final List<_StateDefinition>? _nestedStateDefinitions;

  Type get _definedType => DefinedState;

  bool _matchType(dynamic object) => object is DefinedState;

  void onEnter(DefinedState state) {
    _onEnter?.call(state);
    _nestedStateDefinition(state)?.onEnter(state);
  }

  // void onChange(DefinedState current, DefinedState next) {
  //   final currentDefinition = _nestedStateDefinition(current);
  //   final nextDefinition = _nestedStateDefinition(next);
  //   if (currentDefinition == nextDefinition) {
  //     currentDefinition?.onChange(current, next);
  //   } else {
  //     currentDefinition?.onExit(current);
  //     nextDefinition?.onEnter(next);
  //   }
  // }

  void onExit(DefinedState state) {
    _onExit?.call(state);
    _nestedStateDefinition(state)?.onExit(state);
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
