import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_food_flutter/src/categorias/views/categorias_page.dart';
import 'package:fincore_food_flutter/src/shared/database_initializer.dart';

import 'package:fincore_core/fincore_core.dart';

void main() {
  setUpAll(() async {
    LogService.init('.');
    await DatabaseInitializer.init(Client('http://localhost:8080/'));

    final context = DependencyInjection().get<TenantContext>();
    if (!context.hasContext) {
      final mockMetadata = SyncMetadata(
        version: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin',
        updatedBy: 'admin',
      );
      context.setContext(
        empresa: CoreEmpresa(
          id: '00000000-0000-4000-a000-000000000001',
          razaoSocial: 'Demo Empresa LTDA',
          nomeFantasia: 'FINCORE Food Demo',
          documentoFiscal: '00000000000000',
          email: 'demo@fincore.com',
          telefone: '0000000000',
          status: StatusEmpresa.ativo,
          plano: PlanoEmpresa.ouro,
          timezone: 'America/Sao_Paulo',
          locale: 'pt_BR',
          currency: 'BRL',
          country: 'BR',
          createdFrom: 'seed',
          version: 1,
          metadata: mockMetadata,
          tipoPessoa: 'J',
        ),
        usuario: CoreUsuario(
          id: '00000000-0000-4000-a000-000000009999',
          nome: 'Usuario Teste',
          email: 'teste@fincore.com',
          role: 'ADMIN',
          ativo: true,
          metadata: mockMetadata,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
      );
    }
  });

  group('CategoriasPage — Validação de Formulário', () {
    // CategoriasPage é um Split View (Row com dois Expanded) e exige
    // um viewport com tamanho finito para renderizar corretamente.
    Widget buildTestApp() => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              height: 900,
              child: const CategoriasPage(),
            ),
          ),
        );

    testWidgets('renderiza painel de formulário com campos esperados', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Clica em + Novo para limpar o painel e ir para modo de criação
      await tester.tap(find.text('+ Novo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // O botão de criar exibe "+ Novo"
      expect(find.text('+ Novo'), findsOneWidget);
      expect(find.text('Salvar Categoria'), findsOneWidget);
    });

    testWidgets('salvar com nome vazio exibe erro de validação no campo', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Clica em + Novo para abrir formulário limpo
      await tester.tap(find.text('+ Novo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tentar salvar sem preencher o nome
      await tester.tap(find.text('Salvar Categoria'));
      await tester.pump();

      // Deve aparecer a mensagem de erro do validator required
      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets('salvar com nome de 1 char exibe erro de minLength', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Clica em + Novo para abrir formulário limpo
      await tester.tap(find.text('+ Novo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Preencher nome com apenas 1 char
      final nomeField = find.byType(TextFormField).first;
      await tester.enterText(nomeField, 'A');
      await tester.tap(find.text('Salvar Categoria'));
      await tester.pump();

      // Deve aparecer mensagem de mínimo de caracteres
      expect(find.text('Mínimo de 2 caracteres'), findsOneWidget);
    });

    testWidgets('salvar com ordem inválida (texto) exibe erro de integer', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Clica em + Novo para abrir formulário limpo
      await tester.tap(find.text('+ Novo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final fields = find.byType(TextFormField);

      // Nome válido (campo 0)
      await tester.enterText(fields.first, 'Mini Salgados');

      // Ordem é o 3º TextFormField — busca pelo hint '0'
      final ordemField = find.widgetWithText(TextFormField, '0');
      await tester.enterText(ordemField, 'abc');

      await tester.tap(find.text('Salvar Categoria'));
      await tester.pump();

      // Deve exibir erro de número inválido
      expect(find.text('Deve ser um número inteiro'), findsOneWidget);
    });

    testWidgets('preencher dados válidos — sem erros de validação', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Clica em + Novo para abrir formulário limpo
      await tester.tap(find.text('+ Novo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final fields = find.byType(TextFormField);

      // Nome válido (mínimo 2 chars)
      await tester.enterText(fields.first, 'Bebidas Geladas');

      // Descrição (campo opcional)
      await tester.enterText(fields.at(1), 'Sucos, refrigerantes e água');

      // Ordem válida
      final ordemField = find.widgetWithText(TextFormField, '0');
      await tester.enterText(ordemField, '2');

      await tester.tap(find.text('Salvar Categoria'));
      await tester.pump();

      // Nenhuma mensagem de validação deve aparecer
      expect(find.text('Campo obrigatório'), findsNothing);
      expect(find.text('Mínimo de 2 caracteres'), findsNothing);
      expect(find.text('Deve ser zero ou maior'), findsNothing);
    });
  });
}
