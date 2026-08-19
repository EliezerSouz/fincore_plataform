import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('--- GERANDO ÍCONE EXCLUSIVO DESKTOP LAUNCHER EM TODOS OS TAMANHOS ---');

  final iconesFile = File('../../../images/Icones.png');
  if (!iconesFile.existsSync()) {
    print('ERRO: arquivo Icones.png nao encontrado');
    return;
  }

  final iconesBytes = iconesFile.readAsBytesSync();
  final iconesImg = img.decodePng(iconesBytes);
  if (iconesImg == null) return;

  final outputDir = Directory('../../../images/extracted');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  // Crop limpo e centralizado do emlema circular "Desktop Launcher" (Atalho de Software)
  // x: 1472, y: 895, w: 260, h: 260
  final desktopLauncherMaster = img.copyCrop(
    iconesImg,
    x: 1475,
    y: 920,
    width: 250,
    height: 250,
  );

  // Salvar master em alta qualidade (1024x1024)
  final master1024 = img.copyResize(desktopLauncherMaster, width: 1024, height: 1024, interpolation: img.Interpolation.cubic);

  File('${outputDir.path}/desktop_launcher_master.png').writeAsBytesSync(img.encodePng(master1024));
  print('OK: Master de 1024x1024 gerado com sucesso!');

  // Salvar como fonte do flutter_launcher_icons
  final assetsDir = Directory('assets/images');
  if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);

  final appIconMasterPath = '${assetsDir.path}/app_launcher_icon.png';
  File(appIconMasterPath).writeAsBytesSync(img.encodePng(master1024));
  print('OK: Asset fonte assets/images/app_launcher_icon.png salvo!');

  // Gerar tamanhos padrão (16x16, 32x32, 48x48, 64x64, 128x128, 256x256, 512x512, 1024x1024)
  final sizes = [16, 24, 32, 48, 64, 128, 256, 512, 1024];
  for (final s in sizes) {
    final resized = img.copyResize(master1024, width: s, height: s, interpolation: img.Interpolation.cubic);
    File('${outputDir.path}/icon_${s}x${s}.png').writeAsBytesSync(img.encodePng(resized));
  }
  print('OK: Todos os tamanhos de PNG (16px a 1024px) gerados!');

  // Criar o arquivo ICO de atalho para Windows (.ico contendo multiplos tamanhos)
  // O formato ICO do Windows contem os frames PNG de 256, 128, 64, 48, 32, 16
  final winIcoPath = 'windows/runner/resources/app_icon.ico';
  final winIcoFile = File(winIcoPath);
  if (winIcoFile.parent.existsSync()) {
    // Encapsular PNG de 256px como ICO ou salvar imagem PNG de 256px se compativel
    // No Windows modern Flutter, o app_icon.ico pode ser gravado com a estrutura ICO basica
    final png256 = img.copyResize(master1024, width: 256, height: 256);
    final icoBytes = _createIcoFromPngs([
      img.copyResize(master1024, width: 16, height: 16),
      img.copyResize(master1024, width: 32, height: 32),
      img.copyResize(master1024, width: 48, height: 48),
      img.copyResize(master1024, width: 64, height: 64),
      img.copyResize(master1024, width: 128, height: 128),
      png256,
    ]);
    winIcoFile.writeAsBytesSync(icoBytes);
    print('OK: Atalho Desktop do Windows (windows/runner/resources/app_icon.ico) atualizado!');
  }

  // Atualizar favicon do Web se existir
  final webFavicon = File('web/favicon.png');
  if (webFavicon.parent.existsSync()) {
    final fav32 = img.copyResize(master1024, width: 32, height: 32);
    webFavicon.writeAsBytesSync(img.encodePng(fav32));
    print('OK: web/favicon.png atualizado!');
  }

  print('--- FINALIZADO COM SUCESSO ---');
}

/// Helper para gerar um arquivo binario .ICO legitimo do Windows contendo múltiplos PNGs
List<int> _createIcoFromPngs(List<img.Image> images) {
  final List<int> bytes = [];

  // Header ICO (6 bytes)
  // Reserved (2 bytes) = 0
  // Type (2 bytes) = 1 (ICO)
  // Count (2 bytes) = images.length
  bytes.addAll([0, 0, 1, 0, images.length & 0xFF, (images.length >> 8) & 0xFF]);

  final List<List<int>> pngDataList = [];
  for (final im in images) {
    pngDataList.add(img.encodePng(im));
  }

  // Directory entry = 16 bytes por imagem
  int offset = 6 + (images.length * 16);

  for (int i = 0; i < images.length; i++) {
    final im = images[i];
    final pngData = pngDataList[i];
    final w = im.width >= 256 ? 0 : im.width;
    final h = im.height >= 256 ? 0 : im.height;

    bytes.add(w); // width
    bytes.add(h); // height
    bytes.add(0); // color palette count
    bytes.add(0); // reserved
    bytes.addAll([1, 0]); // color planes
    bytes.addAll([32, 0]); // bpp

    // size of image data (4 bytes)
    final size = pngData.length;
    bytes.addAll([
      size & 0xFF,
      (size >> 8) & 0xFF,
      (size >> 16) & 0xFF,
      (size >> 24) & 0xFF,
    ]);

    // offset of image data (4 bytes)
    bytes.addAll([
      offset & 0xFF,
      (offset >> 8) & 0xFF,
      (offset >> 16) & 0xFF,
      (offset >> 24) & 0xFF,
    ]);

    offset += size;
  }

  // Anexar os dados PNG
  for (final pngData in pngDataList) {
    bytes.addAll(pngData);
  }

  return bytes;
}
