import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('--- PROCESSANDO LOGO 3D EXCLUSIVA (Icone.png) COM CORTE PERFEITO E FUNDO TRANSPARENTE ---');

  final file = File('F:/Eigent/fincore_platform/images/icons/Icone.png');
  if (!file.existsSync()) {
    print('ERRO: Icone.png nao encontrado');
    return;
  }

  final rawImg = img.decodePng(file.readAsBytesSync());
  if (rawImg == null) return;

  final w = rawImg.width;
  final h = rawImg.height;

  // Bounding box exato da logo 3D
  // minX=358, maxX=1177, minY=48, maxY=962 (largura 820, altura 915)
  // Criar container quadrado de 960x960 (com 22px de respiro em cada lado para NAO cortar NENHUM MILÍMETRO da logo!)
  const squareSize = 960;
  const centerX = 767.5;
  const centerY = 505.0;

  final cropX = (centerX - squareSize / 2.0).round().clamp(0, w - squareSize);
  final cropY = (centerY - squareSize / 2.0).round().clamp(0, h - squareSize);

  print('Recortando regiao quadrada perfeita 960x960: cropX=$cropX, cropY=$cropY');

  final cropped = img.copyCrop(rawImg, x: cropX, y: cropY, width: squareSize, height: squareSize);

  // Criar imagem RGBA com fundo 100% transparente
  final transparentImg = img.Image(width: squareSize, height: squareSize, numChannels: 4);

  for (int y = 0; y < squareSize; y++) {
    for (int x = 0; x < squareSize; x++) {
      final p = cropped.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();

      // Verificar se e o fundo preto/escuro puro da imagem original (R<=10, G<=10, B<=10)
      final isDarkBg = r <= 12 && g <= 12 && b <= 12;

      int alpha = 255;
      if (isDarkBg) {
        // Fundo escuro em volta da logo -> 100% Transparente
        alpha = 0;
      } else if (r <= 22 && g <= 22 && b <= 25) {
        // Transicao de borda externa (anti-aliasing)
        final maxC = [r, g, b].reduce((a, b) => a > b ? a : b);
        final t = (maxC - 12) / 10.0;
        alpha = (255 * t).clamp(0, 255).round();
      } else {
        alpha = 255;
      }

      transparentImg.setPixelRgba(x, y, r, g, b, alpha);
    }
  }

  // Redimensionar para Master 1024x1024 com interpolação Cúbica HD
  final master1024 = img.copyResize(transparentImg, width: 1024, height: 1024, interpolation: img.Interpolation.cubic);

  final outputDir = Directory('F:/Eigent/fincore_platform/images/extracted');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  // Salvar master transparente
  File('${outputDir.path}/icone_3d_master_transparent.png').writeAsBytesSync(img.encodePng(master1024));
  File('${outputDir.path}/desktop_launcher_master.png').writeAsBytesSync(img.encodePng(master1024));
  print('OK: Master de 1024x1024 com fundo transparente e sem cortes salvo em images/extracted!');

  // Salvar no assets do Flutter
  final flutterAssetsDir = Directory('assets/images');
  if (!flutterAssetsDir.existsSync()) flutterAssetsDir.createSync(recursive: true);
  File('${flutterAssetsDir.path}/app_launcher_icon.png').writeAsBytesSync(img.encodePng(master1024));
  print('OK: Assets do Flutter (assets/images/app_launcher_icon.png) atualizado.');

  // Gerar PNGs transparentes para todas as resoluçoes padrao
  final sizes = [16, 24, 32, 48, 64, 128, 256, 512, 1024];
  for (final s in sizes) {
    final resized = img.copyResize(master1024, width: s, height: s, interpolation: img.Interpolation.cubic);
    File('${outputDir.path}/icon_${s}x${s}.png').writeAsBytesSync(img.encodePng(resized));
  }
  print('OK: Todos os PNGs transparentes (16px a 1024px) gerados!');

  // Atualizar ICO do Windows (Multi-resolucao .ico)
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
    print('OK: windows/runner/resources/app_icon.ico atualizado!');
  }

  // Atualizar Web Favicon
  final webFavicon = File('web/favicon.png');
  if (webFavicon.parent.existsSync()) {
    final fav32 = img.copyResize(master1024, width: 32, height: 32);
    webFavicon.writeAsBytesSync(img.encodePng(fav32));
    print('OK: web/favicon.png atualizado!');
  }

  print('--- PROCESSAMENTO CONCLUIDO COM SUCESSO ---');
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
