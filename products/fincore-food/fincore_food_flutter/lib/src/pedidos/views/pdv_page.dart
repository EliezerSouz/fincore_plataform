import 'package:flutter/material.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_food_flutter/src/pdv_express/views/pdv_express_screen.dart';

/// Frente de Caixa (POS / PDV) e Criação de Novos Pedidos do Fincore Food
/// Unificado ao layout do mockup aprovado (StepperHeader, catálogo com busca e pílulas).
class PdvPage extends StatelessWidget {
  final OrdemPreparo? ordemParaEditar;
  final Cliente? clienteInicial;
  final String? repetirPedidoId;
  const PdvPage({
    super.key,
    this.ordemParaEditar,
    this.clienteInicial,
    this.repetirPedidoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PdvExpressScreen(
        isEmbedded: ordemParaEditar == null && clienteInicial == null && repetirPedidoId == null,
        ordemParaEditar: ordemParaEditar,
        clienteInicial: clienteInicial,
        repetirPedidoId: repetirPedidoId,
      ),
    );
  }
}
