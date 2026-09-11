import 'dart:io';

String _extractCep(String address) {
  final cepMatch = RegExp(r'\b\d{2}\.?\d{3}-?\d{3}\b').firstMatch(address);
  if (cepMatch != null) {
    return cepMatch.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
  }
  final digitsMatch = RegExp(r'\b\d{8}\b').firstMatch(address);
  if (digitsMatch != null) {
    return digitsMatch.group(0)!;
  }
  return '';
}

void main() {
  final origin = "Rua Professora Nádia Prancic Bento, 398, Francisca Augusta Rios, Pouso Alegre, MG, 37.557-044";
  final destinationSameCep = "Rua Milton Varlan Ferreira, Pitangueiras, Pouso Alegre, 37557044";

  print('=== SIMULAÇÃO DA EXTRAÇÃO DE CEP ===');
  print('Endereço Origem: "$origin"');
  print('Endereço Destino (Mesmo CEP): "$destinationSameCep"');

  // Lógica antiga
  final oldCleanOrigCep = origin.replaceAll(RegExp(r'[^0-9]'), '');
  final oldCleanDestCep = destinationSameCep.replaceAll(RegExp(r'[^0-9]'), '');
  print('\n[Lógica Antiga] CEP Origem limpo: "$oldCleanOrigCep"');
  print('[Lógica Antiga] CEP Destino limpo: "$oldCleanDestCep"');
  print('[Lógica Antiga] CEPs são iguais? ${oldCleanOrigCep == oldCleanDestCep}');

  // Lógica nova
  final newCleanOrigCep = _extractCep(origin);
  final newCleanDestCep = _extractCep(destinationSameCep);
  print('\n[Lógica Nova] CEP Origem extraído: "$newCleanOrigCep"');
  print('[Lógica Nova] CEP Destino extraído: "$newCleanDestCep"');
  print('[Lógica Nova] CEPs são iguais? ${newCleanOrigCep.isNotEmpty && newCleanOrigCep == newCleanDestCep}');
}
