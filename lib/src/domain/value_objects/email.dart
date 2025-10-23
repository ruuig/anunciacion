// Value Object para Email
import 'package:equatable/equatable.dart';
import 'package:email_validator/email_validator.dart';

class Email extends Equatable {
  final String value;

  const Email(this.value);

  factory Email.fromString(String value) {
    if (!EmailValidator.validate(value)) {
      throw ArgumentError('Email inválido');
    }
    return Email(value.toLowerCase());
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
