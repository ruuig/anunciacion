// Value Object para Email
import 'package:equatable/equatable.dart';

class Email extends Equatable {
  final String value;

  const Email(this.value);

  factory Email.fromString(String value) {
    if (!Email._isValidEmail(value)) {
      throw ArgumentError('Email inválido');
    }
    return Email(value.toLowerCase());
  }

  static bool _isValidEmail(String email) {
    // Basic email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
