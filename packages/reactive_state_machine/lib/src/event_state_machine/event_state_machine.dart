import 'dart:async';

import 'package:reactive_state_machine/src/state_machine_base.dart';

part 'state_definition.dart';
part 'state_definition_builder.dart';

class EventStateMachineTransition<StateType, EventType>
    extends Transition<EventStateMachine<StateType, EventType>, StateType> {
  const EventStateMachineTransition({
    required super.machine,
    required super.exitingState,
    required super.enteringState,
    required this.event,
  });

  final EventType event;
}

typedef StateDefinitionBuilderCallback<StateType, EventType,
        DefinedState extends StateType>
    = StateDefinitionBuilder<StateType, EventType, DefinedState> Function(
  StateDefinitionBuilder<StateType, EventType, DefinedState>,
);

/// {@template state_machine}
/// A Bloc that provides facilities methods to create state machines
///
/// The state machine uses `Bloc`'s `on<Event>` method under the hood with a
/// custom event dispatcher that will in turn call your methods and callbacks.
///
/// State machine's states should be defined with the
/// `StateMachine`'s `define<State>` methods inside the constructor. You should
/// never try to transit to a state that hasn't been explicitly defined.
/// If the state machine detects a transition to an undefined state,
/// it will throw an error.
///
/// Each state has its own set of event handlers and side effects callbacks:
/// * **Event handlers** react to an incoming event and can emit the next
///  machine's state. We call this a _transition_.
/// * **Side effects** are callback functions called depending on state
///  lifecycle. You have access to different side effects: `onEnter` and `onExit`
///
/// When an event is received, the state machine will first search
/// for the actual state definition. Each current state's event handler
/// that matches the received event type will be evaluated.
/// If multiple events handlers match the event type, they will be evaluated
/// in their **definition order**. As soon as an event handler returns
/// a non-null state (we call this _entering a transition_), the state
/// machine stops evaluating events handlers and transit to the new
/// state immediately.
///
/// ```dart
/// class MyStateMachine extends EventStateMachine<Event, State> {
/// MyStateMachine() : super(InitialState()) {
///    define<InitialState>(($) => $
///      ..onEnter((InitialState state) { /** ... **/ })
///      ..onExit((InitialState state) { /** ... **/ })
///      ..on<SomeEvent>((SomeEvent event, InitialState state) => OtherState())
///    );
///    define<OtherState>();
///   }
/// }
/// ```
///
/// See also:
///
/// * [CommandStateMachine] an imperative-style state machine
/// {@endtemplate}
abstract class EventStateMachine<StateType, EventType>
    extends StateMachineBase<StateType> {
  EventStateMachine(StateType initial) {
    List<_StateDefinition> buildDefinitions(
      Iterable<StateDefinitionBuilder> builders,
    ) {
      final List<Type> definedStates = [];

      return builders.map(
        (b) {
          final definition = b._build();
          assert(() {
            final definedType = definition._definedType;
            if (definedStates.contains(definedType)) {
              throw "$definedType has been defined multiple times. States should only be defined once.";
            }
            definedStates.add(definedType);
            return true;
          }());

          return definition;
        },
      ).toList();
    }

    _stateDefinitions = buildDefinitions(states.toList(growable: false));
    _definitionForState(initial)._onEnter(
      exitingState: null,
      enteringState: initial,
    );
  }

  @override
  set state(StateType state);

  @override
  StateType get state;

  Set<StateDefinitionBuilder> get states;

  late final List<_StateDefinition> _stateDefinitions;

  /// Register [DefinedState] as one of the allowed machine's states.
  ///
  /// The define method should be called once for the allowed state
  /// **inside the class constructor**. Defined states should
  /// always be sub-classes of the [StateType] class.
  ///
  /// The define method takes an optional [delegate] function as
  /// a parameter that gives the opportunity to register events handler and
  /// transitions for the [DefinedState] thanks to a [StateDefinitionBuilder]
  /// passed as a parameter to the builder function.
  /// The [StateDefinitionBuilder] provides all necessary methods to register
  /// event handlers, side effects, and nested states. The [delegate]
  /// should call needed [StateDefinitionBuilder]'s object methods to describe
  /// the [DefinedState] and then return it.
  ///
  /// ```dart
  /// class MyStateMachine extends StateMachine<Event, State> {
  /// MyStateMachine() : super(InitialState()) {
  ///    define<InitialState>(($) => $
  ///      ..onEnter((InitialState state) { /** ... **/ })
  ///      ..onExit((InitialState state) { /** ... **/ })
  ///      ..on<SomeEvent>((SomeEvent event, InitialState state) => OtherState())
  ///    );
  ///    define<OtherState>();
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// * [StateDefinitionBuilder] for more information about defining states.
  StateDefinitionBuilder<StateType, EventType, DefinedState>
      define<DefinedState extends StateType>([
    StateDefinitionBuilderCallback<StateType, EventType, DefinedState>?
        delegate,
  ]) {
    final builder =
        StateDefinitionBuilder<StateType, EventType, DefinedState>();
    return delegate?.call(builder) ?? builder;
  }

  void add(EventType event) {
    final definition = _definitionForState(state);
    final enteringState = definition.add(event, state);
    if (enteringState != null && enteringState != state) {
      onTransition(EventStateMachineTransition(
        machine: this,
        exitingState: state,
        enteringState: enteringState,
        event: event,
      ));
      definition.onExit(
        exitingState: state,
        enteringState: enteringState,
      );
      final previousState = state;
      state = enteringState;
      final enteringDefinition = _definitionForState(enteringState);
      enteringDefinition._onEnter(
        exitingState: previousState,
        enteringState: enteringState,
      );
    }
  }

  _StateDefinition _definitionForState(StateType state) =>
      _stateDefinitions.firstWhere((def) => def._matchType(state));
}

abstract class StreamEventStateMachine<StateType, EventType>
    extends EventStateMachine<StateType, EventType> {
  StreamEventStateMachine(super.initial) : _state = initial;

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
