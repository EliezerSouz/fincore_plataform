import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('../../../images/Icones.png');
  final image = img.decodePng(file.readAsBytesSync())!;

  print('Dimensao total: ${image.width}x${image.height}');

  // Imprimir pontos ao redor da area do Desktop Launcher para identificar exatamente o centro e o fundo
  for (int y = 850; y <= 1250; y += 50) {
    for (int x = 1400; x <= 1780; x += 50) {
      final p = image.getPixel(x, y);
      print('X:$x Y:$y -> R:${p.r} G:${p.g} B:${p.b}');
    }
  }
}
