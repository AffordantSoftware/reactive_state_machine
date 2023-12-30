import 'dart:async';

import 'package:reactive_state_machine/reactive_state_machine.dart';

/// Todo: better example

class User {}

class AuthenticationService {
  Future<User?> currentUser() async => null;
  Future<User?> tryLogin() async => null;
  Future<void> logout() async {}
}

sealed class UserState with State<UserModel, UserState> {}

class Unknown extends UserState {
  @override
  Future<void> onEnter() async {
    final user = await machine.authenticationService.currentUser();
    if (user != null) {
      transitionTo(Authenticated(user));
    } else {
      transitionTo(Unauthenticated());
    }
  }
}

class Unauthenticated extends UserState {
  Future<bool> login() async {
    final user = await machine.authenticationService.tryLogin();
    if (user != null) {
      transitionTo(Authenticated(user));
      return true;
    } else {
      return false;
    }
  }
}

class Authenticated extends UserState {
  Authenticated(this.user);

  final User user;

  Future<void> logout() async {
    await machine.authenticationService.logout();
    transitionTo(Unauthenticated());
  }
}

final class UserModel extends StreamCommandStateMachine<UserState> {
  UserModel({
    required this.authenticationService,
  }) : super(Unknown());

  final AuthenticationService authenticationService;
}

void main() async {
  final machine = UserModel(
    authenticationService: AuthenticationService(),
  );

  if (machine.state case Authenticated auth) {
    auth.user;
  }

  machine.ifState((Unauthenticated state) => state.login());

  final content = switch (machine.state) {
    Unknown() || Unauthenticated() => "Unauthenticated",
    Authenticated() => "Authenticated",
  };
  print(content);
}
