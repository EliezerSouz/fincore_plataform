import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/whatsapp_dialog.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WhatsAppDialog — Redesign UX/UI Testes de Interface', () {
    testWidgets('1. Cabeçalho exibe "Nome do cliente · Pedido #00123" e botão fechar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppDialog(
              rawPhone: '35998030271',
              clienteNome: 'Elisabeth Souza',
              numeroPedido: '00123',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Conversa no WhatsApp'), findsOneWidget);
      expect(find.text('Elisabeth Souza · Pedido #00123'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('2. DESTINATÁRIO é compacto, tem indicador de validade e toggle de 9º dígito',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppDialog(
              rawPhone: '35998030271',
              clienteNome: 'Elisabeth Souza',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DESTINATÁRIO'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Celular (com 9)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget); // Indicador de validade
    });

    testWidgets('3. MENSAGEM é o elemento principal, com modelo e contador de caracteres',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppDialog(
              rawPhone: '35998030271',
              clienteNome: 'Elisabeth Souza',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MENSAGEM'), findsOneWidget);
      expect(find.text('Modelo de mensagem'), findsOneWidget);
      expect(find.textContaining('caracteres'), findsOneWidget);
    });

    testWidgets('4. Pedido NÃO PIX: seção PIX NÃO é exibida', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppDialog(
              rawPhone: '35998030271',
              clienteNome: 'Elisabeth Souza',
              pixInfo: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chave: '), findsNothing);
      expect(find.text('Copiar Pix Copia e Cola'), findsNothing);
    });

    testWidgets('5. Pedido PIX pendente: exibe chave, badge pendente e botões de cópia sem QR code gigante',
        (tester) async {
      const pix = PixWhatsAppInfo(
        chaveDisplay: '07389215640',
        tipoChave: 'CPF',
        copiaECola: '00020126580014br.gov.bcb.pix...',
        confirmado: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppDialog(
              rawPhone: '35998030271',
              clienteNome: 'Elisabeth Souza',
              pixInfo: pix,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pagamento pendente'), findsOneWidget);
      expect(find.text('07389215640'), findsOneWidget);
      expect(find.text('+ Chave no Texto'), findsOneWidget);
      expect(find.text('+ Copia e Cola no Texto'), findsOneWidget);
    });

    testWidgets('6. Pedido PIX confirmado: exibe badge de pagamento confirmado',
        (tester) async {
      const pix = PixWhatsAppInfo(
        chaveDisplay: '07389215640',
        tipoChave: 'CPF',
        copiaECola: '00020126580014br.gov.bcb.pix...',
        confirmado: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppDialog(
              rawPhone: '35998030271',
              clienteNome: 'Elisabeth Souza',
              pixInfo: pix,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('✓ Pagamento confirmado'), findsOneWidget);
      expect(find.text('Pagamento pendente'), findsNothing);
      expect(find.text('Copiar chave'), findsNothing);
    });

    testWidgets('7. Rodapé possui [Cancelar], [Copiar], menu [⋮] e [🚀 Enviar pelo WhatsApp]',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppDialog(
              rawPhone: '35998030271',
              clienteNome: 'Elisabeth Souza',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      expect(find.text('Enviar pelo WhatsApp'), findsOneWidget);
    });

    testWidgets('8. Interpolação completa de todas as 24 tags de Food Service no WhatsAppDialog',
        (tester) async {
      const templateComTodasTags = '''
{cliente}
{primeiro_nome}
{loja}
{pedido}
{itens}
{itens_resumo}
{quantidade_itens}
{observacoes}
{total}
{subtotal}
{desconto}
{taxa_entrega}
{taxa_servico}
{forma_pagamento}
{troco_para}
{tipo_pedido}
{endereco}
{previsao_entrega}
{entregador}
{mesa}
{link_cardapio}
{link_rastreio}
{chave_pix}
{chave_pix_copia_cola}''';

      const pix = PixWhatsAppInfo(
        chaveDisplay: '07389215640',
        tipoChave: 'CPF',
        copiaECola: '00020126580014br.gov.bcb.pixPIXCOPIACOLA123',
        confirmado: false,
      );

      final itens = [
        {'nome': 'Burger Artesanal Especial', 'qtd': 2, 'total': 56.0, 'obs': 'Sem cebola'},
        {'nome': 'Batata Rústica', 'qtd': 1, 'total': 18.0},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WhatsAppDialog(
              rawPhone: '35998030271',
              clienteNome: 'Eliezer Severino de Souza',
              nomeEmpresa: 'Delivery do Eli',
              numeroPedido: '000124',
              enderecoCliente: 'Rua Professora Nádia Prancic Bento, 398 - Francisca Augusta Rios - (Ref: Casa)',
              pixInfo: pix,
              initialMessage: templateComTodasTags,
              itens: itens,
              subtotal: 74.0,
              desconto: 5.0,
              taxaEntrega: 7.0,
              taxaServico: 3.5,
              total: 79.5,
              formaPagamento: 'PIX',
              trocoPara: 'Não necessário',
              tipoPedido: 'Entrega (Delivery)',
              observacoes: 'Tocar a campainha',
              previsaoEntrega: '40 a 50 min',
              entregador: 'Carlos Moto',
              mesa: 'Delivery',
              linkCardapio: 'https://cardapio.fincore.app/deliverydoeli',
              linkRastreio: 'https://cardapio.fincore.app/pedido/000124',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nenhuma tag entre chaves deve restar não-substituída no campo de texto
      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields.length, greaterThanOrEqualTo(2));

      final messageField = textFields.last;
      final text = messageField.controller!.text;

      // Verifica que as tags NÃO estão literais
      expect(text.contains('{cliente}'), isFalse);
      expect(text.contains('{primeiro_nome}'), isFalse);
      expect(text.contains('{loja}'), isFalse);
      expect(text.contains('{pedido}'), isFalse);
      expect(text.contains('{itens}'), isFalse);
      expect(text.contains('{itens_resumo}'), isFalse);
      expect(text.contains('{quantidade_itens}'), isFalse);
      expect(text.contains('{observacoes}'), isFalse);
      expect(text.contains('{total}'), isFalse);
      expect(text.contains('{subtotal}'), isFalse);
      expect(text.contains('{desconto}'), isFalse);
      expect(text.contains('{taxa_entrega}'), isFalse);
      expect(text.contains('{taxa_servico}'), isFalse);
      expect(text.contains('{forma_pagamento}'), isFalse);
      expect(text.contains('{troco_para}'), isFalse);
      expect(text.contains('{tipo_pedido}'), isFalse);
      expect(text.contains('{endereco}'), isFalse);
      expect(text.contains('{previsao_entrega}'), isFalse);
      expect(text.contains('{entregador}'), isFalse);
      expect(text.contains('{mesa}'), isFalse);
      expect(text.contains('{link_cardapio}'), isFalse);
      expect(text.contains('{link_rastreio}'), isFalse);
      expect(text.contains('{chave_pix}'), isFalse);
      expect(text.contains('{chave_pix_copia_cola}'), isFalse);

      // E verifica que os valores reais foram interpolados com perfeição
      expect(text.contains('Eliezer Severino de Souza'), isTrue);
      expect(text.contains('Eliezer'), isTrue);
      expect(text.contains('Delivery do Eli'), isTrue);
      expect(text.contains('#000124'), isTrue);
      expect(text.contains('Burger Artesanal Especial'), isTrue);
      expect(text.contains('79,50'), isTrue);
      expect(text.contains('74,00'), isTrue);
      expect(text.contains('5,00'), isTrue);
      expect(text.contains('7,00'), isTrue);
      expect(text.contains('3,50'), isTrue);
      expect(text.contains('07389215640'), isTrue);
      expect(text.contains('PIXCOPIACOLA123'), isTrue);
    });

    testWidgets('9. Geração automática e dinâmica das URLs oficiais do Cardápio Web e Rastreio',
        (tester) async {
      const templateLinks = '{link_cardapio}\n{link_rastreio}';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WhatsAppDialog(
              rawPhone: '35998030271',
              clienteNome: 'Eliezer Souza',
              numeroPedido: '124',
              initialMessage: templateLinks,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      final messageField = textFields.last;
      final text = messageField.controller!.text;

      // Não deve ter gerado a URL hardcode fake 'cardapio.fincore.app'
      expect(text.contains('cardapio.fincore.app'), isFalse);

      // Deve gerar a URL oficial do cardápio web e com o parâmetro ?pedido=124
      expect(text.contains('fincore-cardapio-web.vercel.app'), isTrue);
      expect(text.contains('pedido=124'), isTrue);
    });
  });
}
