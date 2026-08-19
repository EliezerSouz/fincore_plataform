import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  print('--- REMOVENDO FUNDO E CENTRALIZANDO ÍCONE ---');

  final iconesFile = File('../../../images/Icones.png');
  if (!iconesFile.existsSync()) {
    print('ERRO: Icones.png nao encontrado');
    return;
  }

  final iconesImg = img.decodePng(iconesFile.readAsBytesSync());
  if (iconesImg == null) return;

  // Caixa generosa sem cortar absolutamente NADA da logo
  // x: 1430, y: 880, w: 340, h: 340
  final cropped = img.copyCrop(
    iconesImg,
    x: 1430,
    y: 880,
    width: 340,
    height: 340,
  );

  // Criar imagem RGBA com transparência total
  final transparentImg = img.Image(width: cropped.width, height: cropped.height, numChannels: 4);

  // Analisar cor do fundo nos cantos superiores (ex: (5,5))
  final bgSample = cropped.getPixel(5, 5);
  final bgR = bgSample.r;
  final bgG = bgSample.g;
  final bgB = bgSample.b;
  print('Cor de amostragem do fundo: R=$bgR, G=$bgG, B=$bgB');

  // Centro da imagem recortada
  final cx = cropped.width / 2.0;
  final cy = cropped.height / 2.0;

  // Raio do círculo do Desktop Launcher (~150px em um container de 340px)
  final maxRadius = 152.0;
  final minRadius = 144.0;

  for (int y = 0; y < cropped.height; y++) {
    for (int x = 0; x < cropped.width; x++) {
      final pixel = cropped.getPixel(x, y);
      final pr = pixel.r;
      final pg = pixel.g;
      final pb = pixel.b;

      // Distancia do centro
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);

      // Calcular diferenca cromatica para o fundo claro
      final colorDiff = sqrt(pow(pr - bgR, 2) + pow(pg - bgG, 2) + pow(pb - bgB, 2));

      num alpha = 255;

      // 1. Fora do raio do circulo -> 100% Transparente
      if (dist > maxRadius) {
        alpha = 0;
      }
      // 2. Na borda externa (suavizacao anti-aliasing)
      else if (dist > minRadius) {
        final t = (maxRadius - dist) / (maxRadius - minRadius);
        alpha = (255 * t).clamp(0, 255);
      }

      // 3. Remover resíduos de fundo claro (R > 210, G > 210, B > 210) se a diferenca cromatica for muito baixa
      if (pr > 200 && pg > 200 && pb > 200 && colorDiff < 45) {
        final bgFactor = (colorDiff / 45.0).clamp(0.0, 1.0);
        alpha = (alpha * bgFactor).clamp(0, 255);
      }

      transparentImg.setPixelRgba(x, y, pr.toInt(), pg.toInt(), pb.toInt(), alpha.toInt());
    }
  }

  final outputDir = Directory('../../../images/extracted');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  File('${outputDir.path}/desktop_launcher_transparent_test.png')
      .writeAsBytesSync(img.encodePng(transparentImg));
  print('OK: desktop_launcher_transparent_test.png gerado com fundo transparente!');
}
