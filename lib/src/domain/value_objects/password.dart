// Value Object para Password con hash
import 'package:equatable/equatable.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class Password extends Equatable {
  final String hash;

  const Password(this.hash);

  factory Password.fromPlainText(String plainText) {
    // Crear hash SHA-256 con salt
    final salt = 'anunciacion_salt_2024';
    final bytes = utf8.encode(plainText + salt);
    final digest = sha256.convert(bytes);
    return Password(digest.toString());
  }

  bool verify(String plainText) {
    final salt = 'anunciacion_salt_2024';
    final bytes = utf8.encode(plainText + salt);
    final digest = sha256.convert(bytes);
    return hash == digest.toString();
  }

  @override
  List<Object?> get props => [hash];

  @override
  String toString() => 'Password{hash: $hash}';
}
