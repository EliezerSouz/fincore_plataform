import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hierarquia Estrita de Mensageria por Evento (WhatsAppService)', () {
    const kTenantId = 'tenant_hierarquia_test';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Nível 1: Trava Global da Empresa (usarWhatsApp == false) bloqueia qualquer disparo', () async {
      final h = await WhatsAppService.avaliarHierarquiaEvento(
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tenantId: kTenantId,
        empresaUsarWhatsApp: false,
      );

      expect(h.eventoDesativado, isTrue);
      expect(h.podeDispararAutomatico, isFalse);
      expect(h.politica, equals(WhatsAppEventPolicy.desativado));
    });

    test('Nível 2: Política do Evento em DESATIVADO (OFF) bloqueia envio automático', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.desativado,
      }, tenantId: kTenantId);

      final h = await WhatsAppService.avaliarHierarquiaEvento(
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tenantId: kTenantId,
        empresaUsarWhatsApp: true,
      );

      expect(h.eventoDesativado, isTrue);
      expect(h.podeDispararAutomatico, isFalse);
      expect(h.politica, equals(WhatsAppEventPolicy.desativado));
    });

    test('Nível 2: Política do Evento em MANUAL não autoriza disparo automático em background', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.manual,
      }, tenantId: kTenantId);

      final h = await WhatsAppService.avaliarHierarquiaEvento(
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tenantId: kTenantId,
        empresaUsarWhatsApp: true,
      );

      expect(h.eventoDesativado, isFalse);
      expect(h.podeDispararAutomatico, isFalse);
      expect(h.politica, equals(WhatsAppEventPolicy.manual));
    });

    test('Nível 2: Política do Evento em AUTOMÁTICO autoriza quando conectado', () async {
      await WhatsAppService.salvarPoliticasEventos({
        WhatsAppService.kEventoPedidoCriadoPdv: WhatsAppEventPolicy.automatico,
      }, tenantId: kTenantId);

      final h = await WhatsAppService.avaliarHierarquiaEvento(
        eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
        tenantId: kTenantId,
        empresaUsarWhatsApp: true,
      );

      expect(h.eventoDesativado, isFalse);
      expect(h.politica, equals(WhatsAppEventPolicy.automatico));
    });
  });
}
