import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_food_flutter/src/usuarios/views/usuarios_page.dart';
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

  group('UsuariosPage — Validação de Formulário (Split-View)', () {
    // UsuariosPage é um layout de listagem + header que exige viewport finito.
    Widget buildTestApp() => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              height: 900,
              child: const UsuariosPage(),
            ),
          ),
        );

    testWidgets('renderiza lista de usuários e botão de convidar', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Cabeçalho e botão de convidar devem estar visíveis
      expect(find.text('+ Novo'), findsOneWidget);
    });

    testWidgets('abrir formulário de criação exibe os campos obrigatórios', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Abrir painel de criação
      await tester.tap(find.text('+ Novo'));
      await tester.pumpAndSettle();

      // Painel deve aparecer com as abas e os 4 campos TextFormField
      expect(find.text('Dados'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // Nome, Username, Email, Senha
    });

    testWidgets('salvar sem preencher → erro nos 3 campos obrigatórios', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Novo'));
      await tester.pumpAndSettle();

      // Tentar salvar sem preencher nenhum campo
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      // Todos os 3 campos obrigatórios (Nome, Username, Senha) devem exibir "Campo obrigatório"
      expect(find.text('Campo obrigatório'), findsNWidgets(3));
    });

    testWidgets('username com espaço → mensagem de erro de formato', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Novo'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Nome válido (índice 0)
      await tester.enterText(fields.at(0), 'Carlos Oliveira');
      // Username com espaço — inválido (índice 1)
      await tester.enterText(fields.at(1), 'carlos oliveira');
      // Email válido (índice 2)
      await tester.enterText(fields.at(2), 'carlos@fincore.com');
      // Senha válida (índice 3)
      await tester.enterText(fields.at(3), 'senha123');

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('Username não pode conter espaços'), findsOneWidget);
    });

    testWidgets('email sem @ → mensagem de e-mail inválido', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Novo'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      await tester.enterText(fields.at(0), 'Carlos Oliveira');
      await tester.enterText(fields.at(1), 'coliveira');
      // Email sem @ (inválido)
      await tester.enterText(fields.at(2), 'carlos.fincore.com');
      // Senha válida (índice 3)
      await tester.enterText(fields.at(3), 'senha123');

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('E-mail inválido'), findsOneWidget);
    });

    testWidgets('cancelar fecha o painel de criação sem erros', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Novo'));
      await tester.pumpAndSettle();

      expect(find.text('Dados'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Painel de criação deve ter sido cancelado, mostrando a mensagem padrão de seleção
      expect(find.text('Selecione ou cadastre um colaborador para editar.'), findsOneWidget);
    });
  });
}
