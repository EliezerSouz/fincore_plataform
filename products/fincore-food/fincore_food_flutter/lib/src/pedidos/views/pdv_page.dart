import 'package:flutter/material.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/pdv_express/views/pdv_express_screen.dart';

/// Frente de Caixa (POS / PDV) e Criação de Novos Pedidos do Fincore Food
/// Unificado ao layout do mockup aprovado (StepperHeader, catálogo com busca e pílulas).
class PdvPage extends StatelessWidget {
  final OrdemPreparo? ordemParaEditar;
  const PdvPage({super.key, this.ordemParaEditar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PdvExpressScreen(
        isEmbedded: true,
        ordemParaEditar: ordemParaEditar,
      ),
    );
  }
}
