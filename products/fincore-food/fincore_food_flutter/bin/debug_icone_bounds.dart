import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('F:/Eigent/fincore_platform/images/icons/Icone.png');
  final image = img.decodePng(file.readAsBytesSync())!;

  final w = image.width;
  final h = image.height;

  int minX = w, minY = h, maxX = 0, maxY = 0;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = image.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final a = p.a.toInt();

      // Verificar se o pixel tem alpha visível ou se a cor não é o fundo escuro (R > 15 || G > 15 || B > 15)
      final isNotBg = a > 20 && (r > 12 || g > 12 || b > 12);
      if (isNotBg) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  print('Logo 3D real bounding box: minX=$minX, maxX=$maxX, minY=$minY, maxY=$maxY');
  print('Largura logo: ${maxX - minX + 1}, Altura logo: ${maxY - minY + 1}');
  print('Centro real: X=${(minX + maxX) / 2}, Y=${(minY + maxY) / 2}');
}
