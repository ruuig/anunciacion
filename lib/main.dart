// Archivo principal - Sistema de Gestión Escolar con Clean Architecture
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'clean_architecture_main.dart';

void main() {
  print('🚀 Iniciando Sistema de Gestión Escolar...');
  print('📊 Conexión a Clever Cloud PostgreSQL configurada');

  runApp(
    const ProviderScope(
      child: AnunciacionApp(),
    ),
  );
}
