import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('F:/Eigent/fincore_platform/images/icon.png');
  if (!file.existsSync()) {
    print('ERRO: icon.png nao encontrado');
    return;
  }

  final image = img.decodePng(file.readAsBytesSync())!;
  print('icon.png dimensoes: ${image.width}x${image.height}');

  // Mapear seções de icon.png
  // Seção 1: Top Left (Squircle Dark 1024px)
  // Seção 3: Bottom Left (Ícone UI Transparente sem fundo!)
  // Mapear pixels de Seção 3 (y: 1400..2100, x: 100..800)

  print('Amostragem Seção 3 (UI Transparente sem fundo):');
  for (int y = 1450; y <= 2150; y += 100) {
    for (int x = 100; x <= 700; x += 100) {
      final p = image.getPixel(x, y);
      print('X:$x Y:$y -> R:${p.r} G:${p.g} B:${p.b} A:${p.a}');
    }
  }
}
