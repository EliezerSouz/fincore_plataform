import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  print('--- GERANDO ÍCONE DESKTOP LAUNCHER 100% TRANSPARENTE E SEM CORTES ---');

  final iconesFile = File('../../../images/Icones.png');
  if (!iconesFile.existsSync()) {
    print('ERRO: Icones.png nao encontrado');
    return;
  }

  final iconesImg = img.decodePng(iconesFile.readAsBytesSync())!;

  // Centro e Raio Exatos do Círculo 3D do Desktop Launcher em Icones.png
  final double cx = 1605.0;
  final double cy = 1060.0;
  final double circleRadius = 131.5; // Raio total da moldura circular metálica
  final double edgeSmoothing = 2.0;  // Largura do anti-aliasing suave

  // Tamanho do container recortado (272x272 para englobar todo o círculo com borda intacta)
  final int boxSize = (circleRadius * 2 + 8).round(); // 271px -> 272px
  final int cropX = (cx - boxSize / 2).round(); // 1469
  final int cropY = (cy - boxSize / 2).round(); // 924

  print('Recortando regiao: X=$cropX, Y=$cropY, Tamanho=${boxSize}x$boxSize');

  // Criar imagem RGBA 272x272
  final resultImg = img.Image(width: boxSize, height: boxSize, numChannels: 4);

  final double boxCenterX = boxSize / 2.0;
  final double boxCenterY = boxSize / 2.0;

  for (int py = 0; py < boxSize; py++) {
    for (int px = 0; px < boxSize; px++) {
      // Mapear para coordenadas originais da imagem
      final origX = cropX + px;
      final origY = cropY + py;

      // Distancia euclidiana ao centro do circulo
      final dx = px - boxCenterX;
      final dy = py - boxCenterY;
      final dist = sqrt(dx * dx + dy * dy);

      if (origX >= 0 && origX < iconesImg.width && origY >= 0 && origY < iconesImg.height) {
        final pixel = iconesImg.getPixel(origX, origY);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        int alpha = 255;

        if (dist > circleRadius + edgeSmoothing) {
          // Totalmente fora do circulo -> 100% Transparente
          alpha = 0;
        } else if (dist > circleRadius - edgeSmoothing) {
          // Borda externa -> Anti-aliasing suave
          final t = (circleRadius + edgeSmoothing - dist) / (edgeSmoothing * 2);
          alpha = (255 * t).clamp(0, 255).round();
        } else {
          // Dentro da moldura circular -> 100% Opaco
          alpha = 255;
        }

        resultImg.setPixelRgba(px, py, r, g, b, alpha);
      }
    }
  }

  // Redimensionar para Master 1024x1024 com interpolação de altíssima qualidade
  final master1024 = img.copyResize(resultImg, width: 1024, height: 1024, interpolation: img.Interpolation.cubic);

  final outputDir = Directory('../../../images/extracted');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  // Salvar master transparente
  final transparentMasterFile = File('${outputDir.path}/desktop_launcher_transparent.png');
  transparentMasterFile.writeAsBytesSync(img.encodePng(master1024));
  print('OK: desktop_launcher_transparent.png (1024x1024 HD com fundo transparente!) gerado.');

  // Salvar em assets/images/app_launcher_icon.png
  final assetsFile = File('assets/images/app_launcher_icon.png');
  assetsFile.writeAsBytesSync(img.encodePng(master1024));
  print('OK: assets/images/app_launcher_icon.png atualizado.');

  // Gerar PNGs transparentes em todos os tamanhos padrao (16px a 1024px)
  final sizes = [16, 24, 32, 48, 64, 128, 256, 512, 1024];
  for (final s in sizes) {
    final resized = img.copyResize(master1024, width: s, height: s, interpolation: img.Interpolation.cubic);
    File('${outputDir.path}/icon_${s}x${s}.png').writeAsBytesSync(img.encodePng(resized));
  }
  print('OK: Todos os PNGs transparentes (16px a 1024px) gerados!');

  // Atualizar ICO do Windows
  final winIcoFile = File('windows/runner/resources/app_icon.ico');
  if (winIcoFile.parent.existsSync()) {
    final icoBytes = _createIcoFromPngs([
      img.copyResize(master1024, width: 16, height: 16),
      img.copyResize(master1024, width: 32, height: 32),
      img.copyResize(master1024, width: 48, height: 48),
      img.copyResize(master1024, width: 64, height: 64),
      img.copyResize(master1024, width: 128, height: 128),
      img.copyResize(master1024, width: 256, height: 256),
    ]);
    winIcoFile.writeAsBytesSync(icoBytes);
    print('OK: windows/runner/resources/app_icon.ico atualizado com suporte a transparência!');
  }

  // Atualizar Web favicon
  final webFavicon = File('web/favicon.png');
  if (webFavicon.parent.existsSync()) {
    final fav32 = img.copyResize(master1024, width: 32, height: 32);
    webFavicon.writeAsBytesSync(img.encodePng(fav32));
    print('OK: web/favicon.png atualizado com fundo transparente!');
  }
}

List<int> _createIcoFromPngs(List<img.Image> images) {
  final List<int> bytes = [];
  bytes.addAll([0, 0, 1, 0, images.length & 0xFF, (images.length >> 8) & 0xFF]);

  final List<List<int>> pngDataList = [];
  for (final im in images) {
    pngDataList.add(img.encodePng(im));
  }

  int offset = 6 + (images.length * 16);

  for (int i = 0; i < images.length; i++) {
    final im = images[i];
    final pngData = pngDataList[i];
    final w = im.width >= 256 ? 0 : im.width;
    final h = im.height >= 256 ? 0 : im.height;

    bytes.add(w);
    bytes.add(h);
    bytes.add(0);
    bytes.add(0);
    bytes.addAll([1, 0]);
    bytes.addAll([32, 0]);

    final size = pngData.length;
    bytes.addAll([
      size & 0xFF,
      (size >> 8) & 0xFF,
      (size >> 16) & 0xFF,
      (size >> 24) & 0xFF,
    ]);

    bytes.addAll([
      offset & 0xFF,
      (offset >> 8) & 0xFF,
      (offset >> 16) & 0xFF,
      (offset >> 24) & 0xFF,
    ]);

    offset += size;
  }

  for (final pngData in pngDataList) {
    bytes.addAll(pngData);
  }

  return bytes;
}
