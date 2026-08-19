import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_food_flutter/src/pdv_express/views/pdv_express_screen.dart';
import 'package:fincore_food_flutter/src/shared/database_initializer.dart';

import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/sync/sync_engine.dart';

void main() {
  testWidgets('fincore_food_flutter FincoreShell loading and routing test', (WidgetTester tester) async {
    // 1. Configurar tamanho da tela para modo Desktop Expandido (1200x800)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    
    // Resetar tamanho no final do teste
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      try {
        DependencyInjection().get<SyncEngine>().stopAutoSync();
      } catch (_) {}
    });

    // Inicializar o banco de dados em memória e injeção para o escopo do teste
    await DatabaseInitializer.init(Client('http://localhost:8080/'));

    // 2. Carregar o app
    await tester.pumpWidget(const MaterialApp(home: FincoreShell()));
    
    // 3. Verificar que o FincoreShell foi instanciado
    expect(find.byType(FincoreShell), findsOneWidget);
    
    // 4. Verificar a presença dos elementos fundamentais do Shell (Logo e Topbar)
    expect(find.text('FINCORE'), findsWidgets);
    expect(find.text('FOOD'), findsWidgets);
    
    // 5. Verificar que a visualização inicial activa é a Dashboard (Empty State)
    expect(find.text('Visão geral do negócio'), findsOneWidget);

    // 6. Testar navegação para o PDV Express
    await tester.tap(find.text('Frente de Caixa'));
    await tester.pumpAndSettle();
    
    // Verificar que o PdvExpressScreen foi carregado
    expect(find.byType(PdvExpressScreen), findsOneWidget);

    // 7. Testar navegação livre do Stepper do PDV
    // Inicialmente deve exibir "IDENTIFICAÇÃO DO CLIENTE" (Etapa 0)
    expect(find.text('IDENTIFICAÇÃO DO CLIENTE'), findsOneWidget);

    // Clicar na Etapa 2: Seleção de Produtos no StepperHeader
    await tester.tap(find.text('2  Produtos'));
    await tester.pumpAndSettle();

    // Deve exibir o Catálogo de Produtos
    expect(find.text('Todos'), findsOneWidget); // choice chips

    // Clicar na Etapa 3: Forma de Pagamento no StepperHeader
    await tester.tap(find.text('3  Pagamento & Confirmação'));
    await tester.pumpAndSettle();

    // Deve exibir Pagamento & Observações
    expect(find.text('PAGAMENTO & OBSERVAÇÕES'), findsWidgets);

    // Parar timer de auto sync do SyncEngine
    try {
      DependencyInjection().get<SyncEngine>().stopAutoSync();
    } catch (_) {}
  });
}
