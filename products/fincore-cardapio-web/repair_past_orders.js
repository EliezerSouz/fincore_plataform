const { Client } = require('pg');

const config = {
  host: 'db.nlaxdeqbordmovukyypk.supabase.co',
  port: 5432,
  user: 'postgres',
  password: 'GeR9cjvrXrujvL0R',
  database: 'postgres',
  ssl: { rejectUnauthorized: false },
};

function formatPhone(phoneStr) {
  if (!phoneStr) return '';
  let clean = phoneStr.replace(/\D/g, '');
  if (clean.length >= 12 && clean.startsWith('55')) {
    clean = clean.substring(2);
  }
  if (clean.length === 11) {
    return `(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7)}`;
  }
  if (clean.length === 10) {
    return `(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6)}`;
  }
  return phoneStr;
}

async function run() {
  const client = new Client(config);
  try {
    await client.connect();
    console.log('🔄 Iniciando sincronização e reparo de pedidos de teste anteriores...');

    // 1. Buscar apenas os pedidos da empresa "Delivery do Eli" (65109ff8-443f-41ce-94c8-8311dfc79764)
    const resPed = await client.query(`SELECT * FROM public.pedido WHERE "tenantId" = '65109ff8-443f-41ce-94c8-8311dfc79764' ORDER BY "createdAt" ASC`);
    console.log(`Encontrados ${resPed.rows.length} pedidos da empresa Delivery do Eli.`);

    for (let i = 0; i < resPed.rows.length; i++) {
      const p = resPed.rows[i];
      const numPed = p.numeroPedido || (i + 1);

      // Padronizar telefone
      const rawTel = p.clienteTelefoneAvulso || '';
      const formattedTel = formatPhone(rawTel);

      // Atualizar numeroPedido e telefone se necessário
      await client.query(`
        UPDATE public.pedido 
        SET "numeroPedido" = $1, "clienteTelefoneAvulso" = $2
        WHERE id = $3
      `, [numPed, formattedTel || rawTel, p.id]);

      // Buscar itens do pedido
      const resItens = await client.query(`SELECT * FROM public.item_pedido WHERE "pedidoId" = $1`, [p.id]);
      const itens = resItens.rows;

      const itensPayload = itens.map(item => ({
        produtoId: item.produtoId,
        nomeProduto: item.nomeProduto,
        quantidade: parseFloat(item.quantidade),
        observacoes: item.observacoes || null
      }));

      // Verificar se já existe ordens_preparo para este pedido
      const resOp = await client.query(`SELECT id FROM public.ordens_preparo WHERE "pedidoId" = $1`, [p.id]);
      
      let enderecoStr = '';
      if (p.enderecoJson) {
        try {
          const end = typeof p.enderecoJson === 'string' ? JSON.parse(p.enderecoJson) : p.enderecoJson;
          enderecoStr = end.formatado || `${end.logradouro || ''}, ${end.numero || ''} - ${end.bairro || ''}`;
        } catch {}
      }

      const obsTags = [
        `[DADOS_PEDIDO]`,
        `Cliente: ${p.clienteNomeAvulso || 'Cliente Web'}`,
        `Telefone: ${formattedTel || p.clienteTelefoneAvulso || ''}`,
        `Tipo: ${p.tipoLogistica || 'Entrega'}`,
        `Pagamento: ${p.formaPagamentoNome || 'Pix'}`,
        enderecoStr ? `Endereco: ${enderecoStr}` : '',
        p.observacoes ? `Obs: ${p.observacoes}` : '',
        `[/DADOS_PEDIDO]`
      ].filter(Boolean).join('\n');

      if (resOp.rows.length === 0) {
        console.log(`Gerando ordem_preparo para pedido #${numPed} (ID: ${p.id})...`);
        const agora = new Date().toISOString();
        await client.query(`
          INSERT INTO public.ordens_preparo (
            id, "tenantId", "pedidoId", "itensJson", status, prioridade,
            "criadaEm", "tempoEstimadoSegundos", observacoes, "createdAt", "updatedAt",
            "createdBy", "updatedBy", "syncVersion"
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
          )
        `, [
          crypto.randomUUID(),
          p.tenantId || 'default',
          p.id,
          JSON.stringify(itensPayload),
          p.status || 'pendente',
          'normal',
          p.dataHoraCriacao || agora,
          1200,
          obsTags,
          agora,
          agora,
          p.createdBy && p.createdBy.includes('-') ? p.createdBy : '00000000-0000-0000-0000-000000000000',
          p.updatedBy && p.updatedBy.includes('-') ? p.updatedBy : '00000000-0000-0000-0000-000000000000',
          1
        ]);
      } else {
        // Atualizar observações da ordem existente para garantir tags
        await client.query(`UPDATE public.ordens_preparo SET observacoes = $1 WHERE "pedidoId" = $2`, [obsTags, p.id]);
      }
    }

    console.log('🎉 Todos os pedidos de teste anteriores foram reparados e sincronizados!');

  } catch (err) {
    console.error('❌ Erro no reparo:', err);
  } finally {
    await client.end();
  }
}

run();
