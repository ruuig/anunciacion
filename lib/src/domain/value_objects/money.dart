// Value Object para Monto de dinero
import 'package:equatable/equatable.dart';

class Money extends Equatable {
  final double amount;
  final String currency;

  const Money(this.amount, {this.currency = 'GTQ'});

  factory Money.fromDouble(double amount) {
    if (amount < 0) {
      throw ArgumentError('El monto no puede ser negativo');
    }
    return Money(amount);
  }

  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('No se pueden sumar montos de diferentes monedas');
    }
    return Money(amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('No se pueden restar montos de diferentes monedas');
    }
    return Money(amount - other.amount, currency: currency);
  }

  @override
  List<Object?> get props => [amount, currency];

  @override
  String toString() => '$currency ${amount.toStringAsFixed(2)}';
}
