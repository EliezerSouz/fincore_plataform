import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_food_flutter/src/shared/presentation/auth/login_page.dart';
import 'package:fincore_food_flutter/src/shared/presentation/auth/signup_page.dart';
import 'package:fincore_food_flutter/src/shared/presentation/onboarding/onboarding_wizard_page.dart';
import 'package:fincore_food_flutter/src/shared/presentation/onboarding/pending_approval_page.dart';
import 'package:fincore_food_flutter/src/shared/database_initializer.dart';

void main() {
  setUpAll(() async {
    // Inicializar dependências locais Drift SQLite e DI
    await DatabaseInitializer.init(Client('http://localhost:8080/'));
  });

  group('Onboarding Screens Structural Tests', () {
    testWidgets('LoginPage structural and validation check', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: LoginPage(onLoginSuccess: () {}),
      ));

      // Verificar campos de texto e botão
      expect(find.text('Bem-vindo de volta'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Senha
      expect(find.text('ENTRAR'), findsOneWidget);

      // Clicar em Entrar sem preencher e ver validações
      await tester.tap(find.text('ENTRAR'));
      await tester.pump();
      expect(find.text('Informe seu e-mail'), findsOneWidget);
      expect(find.text('Informe a senha'), findsOneWidget);
    });

    testWidgets('SignupPage structural and validation check', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: SignupPage(onSignupSuccess: () {}),
      ));

      expect(find.text('CRIAR CONTA'), findsOneWidget);
      expect(find.text('Etapa 1 de 2: Seus Dados de Acesso'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // Nome, Email, Senha, Repetir Senha
      expect(find.text('AVANÇAR'), findsOneWidget);

      // Clicar em Avançar sem preencher para disparar validação
      await tester.tap(find.text('AVANÇAR'));
      await tester.pump();
      expect(find.text('Informe seu nome'), findsOneWidget);
      expect(find.text('Informe seu e-mail'), findsOneWidget);

      // Preencher credenciais corretas
      await tester.enterText(find.byType(TextFormField).at(0), 'Dono de Restaurante');
      await tester.enterText(find.byType(TextFormField).at(1), 'dono@fincore.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'SenhaForte123!');
      await tester.enterText(find.byType(TextFormField).at(3), 'SenhaForte123!');
      await tester.pumpAndSettle();

      // Avançar para Etapa 2
      await tester.tap(find.text('AVANÇAR'));
      await tester.pumpAndSettle();

      expect(find.text('Etapa 2 de 2: Dados do Estabelecimento'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // Razão Social, Nome Fantasia, CNPJ/CPF, Telefone
      expect(find.text('CADASTRAR'), findsOneWidget);

      // Clicar em Cadastrar sem preencher dados da empresa
      await tester.tap(find.text('CADASTRAR'));
      await tester.pump();
      expect(find.text('Informe a Razão Social'), findsOneWidget);
      expect(find.text('Informe o CNPJ/CPF'), findsOneWidget);
      expect(find.text('Informe o telefone'), findsOneWidget);
    });

    testWidgets('OnboardingWizardPage step progression check', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: OnboardingWizardPage(onCreated: () {}),
      ));

      // Passo 1: Configuração do Espaço
      expect(find.text('Passo 1 de 2'), findsOneWidget);
      expect(find.text('Sobre a Empresa'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Razão Social & Nome Fantasia

      // Preencher nome da empresa (Razão Social)
      await tester.enterText(find.byType(TextFormField).first, 'Minha Empresa Demo');
      await tester.pumpAndSettle();

      // Avançar para o Passo 2
      await tester.tap(find.text('AVANÇAR'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 2 de 2'), findsOneWidget);
      expect(find.text('Informações Fiscais e Contato'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // CNPJ/CPF, Telefone, E-mail Comercial

      // Preencher CNPJ/CPF
      await tester.enterText(find.byType(TextFormField).first, '12.345.678/0001-90');
      // Preencher Telefone
      await tester.enterText(find.byType(TextFormField).at(1), '11999999999');
      // Preencher E-mail
      await tester.enterText(find.byType(TextFormField).last, 'comercial@fincore.com');
      await tester.pumpAndSettle();

      // Finalizar Onboarding
      expect(find.text('FINALIZAR'), findsOneWidget);
    });

    testWidgets('PendingApprovalPage check SLA and layout', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: PendingApprovalPage(
          tenantId: 'tenant-demo',
          onApproved: () {},
          onLogout: () {},
        ),
      ));

      expect(find.text('Aguardando Liberação'), findsOneWidget);
      expect(find.text('Verificar Status'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });
  });
}
