import 'package:postgres/postgres.dart';

void main() async {
  print('Conectando ao banco Supabase PostgreSQL...');
  final connection = await Connection.open(
    Endpoint(
      host: 'db.nlaxdeqbordmovukyypk.supabase.co',
      port: 5432,
      database: 'postgres',
      username: 'postgres',
      password: 'GeR9cjvrXrujvL0R',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  print('\n=== PEDIDOS E SEUS ITENS ===');
  final pedidoRows = await connection.execute('''
    SELECT p.id, p."numeroPedido", p.status, p."tipoLogistica", p."createdAt"
    FROM public.pedido p
    WHERE p."deletedAt" IS NULL
    ORDER BY p."createdAt" DESC
  ''');

  for (final pRow in pedidoRows) {
    final pedidoId = pRow[0];
    final numPed = pRow[1];
    final status = pRow[2];
    final logistica = pRow[3];
    final criado = pRow[4];

    print('Pedido #$numPed (ID: $pedidoId) | Status: $status | Logística: $logistica | Criado: $criado');
    
    final itemRows = await connection.execute('''
      SELECT prod.nome, ip.quantidade
      FROM public.item_pedido ip
      JOIN public.produto prod ON ip."produtoId" = prod.id
      WHERE ip."pedidoId" = '$pedidoId' AND ip."deletedAt" IS NULL
    ''');
    
    for (final iRow in itemRows) {
      print('  -> Item: ${iRow[0]} | Quantidade: ${iRow[1]}');
    }
  }

  await connection.close();
}
