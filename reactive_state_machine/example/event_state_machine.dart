import 'dart:async';

import 'package:reactive_state_machine/reactive_state_machine.dart';

sealed class State {
  const State();
}

class Green extends State {
  const Green();
}

class Red extends State {
  const Red();
}

class Orange extends State {
  const Orange();
}

sealed class Event {
  const Event();
}

class TimerFinished extends Event {
  const TimerFinished();
}

final class TraficLight extends StreamEventStateMachine<State, Event> {
  TraficLight(super.initial);

  @override
  late final states = {
    // Green state
    define<Green>(($) => $
      ..onEnter(_startTimer)
      ..on<TimerFinished>((state, event) => const Orange())),

    // Orange state
    define<Orange>(($) => $
      ..onEnter(_startTimer)
      ..on<TimerFinished>((state, event) => const Red())),

    // Red state
    define<Red>(($) => $
      ..onEnter(_startTimer)
      ..on<TimerFinished>((state, event) => const Green())),
  };

  void _startTimer(_) {
    Timer(Duration(seconds: 1), () => add(const TimerFinished()));
  }
}

void main() async {
  final sm = TraficLight(const Red());

  final handler = sm.stream.listen((event) {
    print("Trafic light is ${event.runtimeType}");
  });

  await handler.asFuture();
}
