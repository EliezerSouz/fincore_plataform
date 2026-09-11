import 'dart:io';
import 'package:drift/native.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

void main() async {
  final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\eliez';
  final dbPath = p.join(userProfile, 'Documents', 'fincore_v3.db');
  
  print('Abrindo banco local: $dbPath');
  if (!File(dbPath).existsSync()) {
    print('Erro: Banco local não encontrado.');
    return;
  }
  
  final db = FincoreDatabase(NativeDatabase(File(dbPath)));
  
  try {
    print('Buscando ordens de preparo ativas na tabela ordens_preparo_table...');
    final rows = await db.customSelect(
      "SELECT id, criada_em, observacoes, prioridade, status FROM ordens_preparo_table WHERE status IN ('pendente', 'em_preparo') AND deleted_at IS NULL"
    ).get();
    
    if (rows.isEmpty) {
      print('Nenhuma ordem de preparo ativa encontrada.');
      return;
    }
    
    print('Encontrada(s) ${rows.length} ordens ativas. Analisando agendamentos...');
    int modificadas = 0;
    
    for (final row in rows) {
      final id = row.read<String>('id');
      final criadaEmStr = row.read<String>('criada_em');
      final obs = row.read<String?>('observacoes') ?? '';
      final prioridade = row.read<String>('prioridade');
      final status = row.read<String>('status');
      
      // Parse criadaEm
      DateTime criadaEm;
      try {
        if (RegExp(r'^\d+$').hasMatch(criadaEmStr)) {
          final val = int.parse(criadaEmStr);
          if (val < 10000000000) {
            // Segundos Unix -> converter para milissegundos
            criadaEm = DateTime.fromMillisecondsSinceEpoch(val * 1000).toLocal();
          } else {
            criadaEm = DateTime.fromMillisecondsSinceEpoch(val).toLocal();
          }
        } else {
          criadaEm = DateTime.parse(criadaEmStr).toLocal();
        }
      } catch (e) {
        try {
          final val = row.read<int>('criada_em');
          if (val < 10000000000) {
            criadaEm = DateTime.fromMillisecondsSinceEpoch(val * 1000).toLocal();
          } else {
            criadaEm = DateTime.fromMillisecondsSinceEpoch(val).toLocal();
          }
        } catch (_) {
          print('  Erro ao fazer parse da data criada_em: $criadaEmStr');
          continue;
        }
      }
      
      final agora = DateTime.now();
      final diferencaMinutos = criadaEm.difference(agora).inMinutes;
      
      print('  [DEBUG KDS] ID: $id | CriadaEm: $criadaEm | Agora: $agora | Diferença: $diferencaMinutos min | Obs contém agendado: ${obs.contains('agendado:')} | Prioridade: $prioridade');
      
      // Consideramos agendamento se data for futura e não possuir a tag agendado
      if (diferencaMinutos > 5 && !obs.contains('agendado:')) {
        print('  -> Ordem ID $id é um agendamento antigo!');
        
        final fmtDate = DateFormat('dd/MM/yyyy HH:mm').format(criadaEm);
        
        String newObs = obs;
        if (obs.contains('[/DADOS_PEDIDO]')) {
          newObs = obs.replaceFirst('[/DADOS_PEDIDO]', 'agendado: $fmtDate\n[/DADOS_PEDIDO]');
        } else {
          newObs = '[DADOS_PEDIDO]\nagendado: $fmtDate\n[/DADOS_PEDIDO]\n' + obs;
        }
        
        await db.customStatement(
          "UPDATE ordens_preparo_table SET observacoes = ?, prioridade = 'programado', sync_status = 'pending', updated_at = ? WHERE id = ?",
          [newObs, DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000, id]
        );
        
        modificadas++;
        print('     Ordem ID $id atualizada! Tag "agendado: $fmtDate" injetada e prioridade alterada para "programado".');
      }
    }
    print('\nTotal de ordens corrigidas: $modificadas');
  } catch (e) {
    print('Erro ao corrigir ordens de preparo: $e');
  } finally {
    await db.close();
  }
}
