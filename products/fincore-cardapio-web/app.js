/* ═══════════════════════════════════════════════════════════════════
   FINCORE Cardápio Digital Web — app.js (v2.0.0 Gourmet Edition)
   Plataforma Completa: Home Dashboard + Cardápio + Encomendas + Pedidos + Conta
   ═══════════════════════════════════════════════════════════════════ */

'use strict';

// ─── Configurações do Supabase & Backend ─────────────────────────────
const SUPABASE_URL     = 'https://nlaxdeqbordmovukyypk.supabase.co';
const SUPABASE_ANON    = 'sb_publishable_PR7Yj7hXLnn5kuiNhbcAjg_x3sN7Xsy';
const DEFAULT_TENANT_ID = null; // Sem tenant estático forçado: resolução 100% dinâmica

// ─── Inicialização do Cliente Supabase ──────────────────────────────
const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON);

// ─── Estado Global da Aplicação ─────────────────────────────────────
const state = {
  session:            null,    // Sessão Supabase Auth
  profile:            null,    // Registro do cliente em cardapio_clientes
  tenantId:           getTenantFromUrl(),
  empresa:            null,    // Dados da vw_cardapio_empresa + empresa
  empresaConfig:      null,    // Configurações da empresa (Pix, horários)
  horariosAtendimento: null,   // Dias, horários de atendimento e prazo mínimo
  categorias:         [],      // Categorias reais do banco
  produtos:           [],      // Produtos reais de vw_cardapio_produtos
  precificacao:       [],      // Faixas de preço por quantidade de vw_cardapio_precificacao
  cart:               [],      // { produto, qty, obs }
  currentCat:         'all',
  currentOrder:       null,    // Pedido recém-criado ou visualizado
  orderSub:           null,    // Supabase Realtime Subscription
  modalProduct:       null,    // Produto atualmente aberto no modal
  modalQty:           1,
  tipoLogistica:      'Entrega',
  formaPagamentoNome: 'Pix',
  formaPagamentoId:   null,
  formaPagamentoTipo: 'pix',
  formaPagamentoPermiteTroco: false,
  formasPagamento:    [],
  customerOrders:     [],      // Histórico de pedidos do cliente logado
  activeOrder:        null,    // Pedido em andamento do cliente
  customerAddresses:  [],      // Lista de múltiplos endereços cadastrados no ERP (local_entrega)
  selectedAddressId:  null,    // ID do endereço atualmente selecionado para entrega
  searchTerm:         '',
  activeOrderFilter:  'all',
  expressoCart:       {},      // { [prodId]: qty }
  expressoConfig:     { ativo: true, estoqueMinimo: 1, titulo: 'Disponíveis para Envio Imediato' },
  expressoLogistica:  'Entrega',
  expressoFormaPagamento: 'Pix',
  expressoTaxaEntregaCentavos: 0,
};

// ─── Carregamento de Endereços Cadastrados do Cliente (local_entrega / perfil) ───
async function loadCustomerAddresses() {
  if (!state.session && !state.profile) {
    state.customerAddresses = [];
    return [];
  }

  const tenantId = state.tenantId || DEFAULT_TENANT_ID;
  const clienteId = state.profile?.cliente_local_id;
  const profileId = state.profile?.id;

  try {
    let enderecosRaw = [];

    // 1. Busca todos os endereços ativos do tenant em local_entrega
    const { data: locais, error } = await sb
      .from('local_entrega')
      .select('*')
      .eq('tenantId', tenantId)
      .eq('ativo', true)
      .is('deletedAt', null);

    if (locais && locais.length > 0) {
      enderecosRaw = locais.filter(loc => {
        if (clienteId && String(loc.clienteId) === String(clienteId)) return true;
        if (profileId && String(loc.clienteId) === String(profileId)) return true;
        return false;
      });
    }

    // Helper para normalizar rua e número para evitar qualquer duplicidade visual
    const normStreet = (s) => (s || '').toLowerCase().trim().replace(/^(rua|av|avenida|travessa|alameda|r\.)\s+/i, '').replace(/\s+/g, ' ');
    const normNum = (n) => String(n || '').toLowerCase().trim();

    // Deduplica endereços do local_entrega (mantém o que tiver mais detalhes)
    const mapEnderecos = new Map();
    for (const loc of enderecosRaw) {
      const key = `${normStreet(loc.logradouro)}::${normNum(loc.numero)}`;
      if (!mapEnderecos.has(key)) {
        mapEnderecos.set(key, loc);
      } else {
        const existing = mapEnderecos.get(key);
        // Se o novo tiver referência e o antigo não, substitui
        if ((!existing.referencia && loc.referencia) || (existing.nomeIdentificador === 'Endereço Principal' && loc.nomeIdentificador !== 'Endereço Principal')) {
          mapEnderecos.set(key, loc);
        }
      }
    }

    let enderecos = Array.from(mapEnderecos.values());

    // 2. Se o perfil em cardapio_clientes possui endereço e ele não está na lista, adiciona como opção
    if (state.profile?.logradouro) {
      const profileKey = `${normStreet(state.profile.logradouro)}::${normNum(state.profile.numero)}`;
      if (!mapEnderecos.has(profileKey)) {
        enderecos.unshift({
          id: 'profile_default',
          nomeIdentificador: 'Cadastrado no Perfil',
          logradouro: state.profile.logradouro,
          numero: state.profile.numero || '',
          bairro: state.profile.bairro || '',
          cidade: state.profile.cidade || state.empresa?.cidade || 'Pouso Alegre',
          uf: state.profile.uf || state.empresa?.estado || 'MG',
          cep: state.profile.cep || '',
          complemento: state.profile.complemento || '',
          referencia: state.profile.referencia || '',
          isPadrao: enderecos.length === 0
        });
      }
    }

    state.customerAddresses = enderecos;
    return enderecos;
  } catch (err) {
    console.warn('Erro ao carregar endereços do cliente:', err);
    return state.customerAddresses || [];
  }
}

// ─── Helpers de Formatação de Horários ────────────────────────────────
function formatHoraCurta(hStr) {
  if (!hStr) return '';
  const [h, m] = String(hStr).trim().split(':');
  const numH = parseInt(h, 10);
  if (!m || m === '00') return `${numH}h`;
  return `${numH}h${m}`;
}

// ─── Cálculo Operacional: Primeiro Horário de Entrega Possível ───────
// Considera aprovação prévia obrigatória e horário real de expediente da cozinha.
function calcularPrimeiraEntregaPossivel(agora = new Date(), h = state.horariosAtendimento) {
  const toYmdLocal = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const toHhMmLocal = (d) => `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;

  if (!h) {
    const prazoMin = 120;
    const cand = new Date(agora.getTime() + prazoMin * 60000);
    const rem = cand.getMinutes() % 15;
    if (rem !== 0) cand.setMinutes(cand.getMinutes() + (15 - rem), 0, 0);
    else cand.setSeconds(0, 0);
    return {
      canOrder: true,
      data: cand,
      dataStr: toYmdLocal(cand),
      horaStr: toHhMmLocal(cand),
      horaFmt: formatHoraCurta(toHhMmLocal(cand)),
      isHoje: toYmdLocal(cand) === toYmdLocal(agora),
      isAmanha: false,
      motivo: 'Recebendo pedidos normalmente'
    };
  }

  if (h.status === 'fechado') {
    return {
      canOrder: false,
      data: null,
      motivo: h.mensagemFechado || 'Pausado para novos pedidos'
    };
  }

  const prazoMin = Math.max(30, parseInt(h.prazoMinimoMinutos || 120, 10));
  const dayKeys = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sab'];
  const dayNames = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];

  function isBlockedDate(d) {
    if (!Array.isArray(h.bloqueios) || h.bloqueios.length === 0) return false;
    const dateStr = toYmdLocal(d);
    return h.bloqueios.some(b => {
      if (!b || !b.data) return false;
      const bStr = String(b.data).split('T')[0];
      return bStr === dateStr && (b.diaTodo === true || b.dia_todo === true || (!b.inicio && !b.fim));
    });
  }

  // 1. Verificar se hoje está no horário de atendimento e há tempo para preparo e entrega hoje
  const todayKey = dayKeys[agora.getDay()];
  const diaHoje = h.dias ? h.dias[todayKey] : null;

  if (diaHoje && diaHoje.ativo && !isBlockedDate(agora)) {
    const [abH, abM] = (diaHoje.abertura || '08:00').split(':').map(Number);
    const [feH, feM] = (diaHoje.fechamento || '22:00').split(':').map(Number);
    const openMin = abH * 60 + abM;
    const closeMin = feH * 60 + feM;
    const nowMin = agora.getHours() * 60 + agora.getMinutes();

    const isOpenNow = (h.status === 'aberto') || (nowMin >= openMin && nowMin < closeMin);

    if (isOpenNow) {
      const cand = new Date(agora.getTime() + prazoMin * 60000);
      const rem = cand.getMinutes() % 15;
      if (rem !== 0) cand.setMinutes(cand.getMinutes() + (15 - rem), 0, 0);
      else cand.setSeconds(0, 0);

      const candMin = cand.getHours() * 60 + cand.getMinutes();
      if (candMin <= closeMin && toYmdLocal(cand) === toYmdLocal(agora)) {
        return {
          canOrder: true,
          data: cand,
          dataStr: toYmdLocal(cand),
          horaStr: toHhMmLocal(cand),
          horaFmt: formatHoraCurta(toHhMmLocal(cand)),
          isHoje: true,
          isAmanha: false,
          diaNome: dayNames[cand.getDay()],
          motivo: `Aprovação em horário de atendimento (entregas até ${formatHoraCurta(diaHoje.fechamento)})`
        };
      }
    } else if (nowMin < openMin) {
      // Antes de abrir hoje (ex: madrugada) - aprovação inicia na abertura
      const cand = new Date(agora);
      cand.setHours(abH, abM + prazoMin, 0, 0);
      const rem = cand.getMinutes() % 15;
      if (rem !== 0) cand.setMinutes(cand.getMinutes() + (15 - rem), 0, 0);

      const candMin = cand.getHours() * 60 + cand.getMinutes();
      if (candMin <= closeMin && toYmdLocal(cand) === toYmdLocal(agora)) {
        return {
          canOrder: true,
          data: cand,
          dataStr: toYmdLocal(cand),
          horaStr: toHhMmLocal(cand),
          horaFmt: formatHoraCurta(toHhMmLocal(cand)),
          isHoje: true,
          isAmanha: false,
          diaNome: dayNames[cand.getDay()],
          motivo: `Aprovação a partir das ${formatHoraCurta(diaHoje.abertura)}`
        };
      }
    }
  }

  // 2. Se não foi viável hoje, buscar o próximo dia útil a partir de amanhã (offset = 1 .. 14)
  for (let offset = 1; offset <= 14; offset++) {
    const nextDate = new Date(agora);
    nextDate.setDate(agora.getDate() + offset);
    nextDate.setHours(0, 0, 0, 0);

    const dKey = dayKeys[nextDate.getDay()];
    const diaCfg = h.dias ? h.dias[dKey] : null;

    if (!diaCfg || !diaCfg.ativo || isBlockedDate(nextDate)) continue;

    const [abH, abM] = (diaCfg.abertura || '08:00').split(':').map(Number);
    const [feH, feM] = (diaCfg.fechamento || '22:00').split(':').map(Number);
    const closeMin = feH * 60 + feM;

    const cand = new Date(nextDate);
    cand.setHours(abH, abM + prazoMin, 0, 0);
    const rem = cand.getMinutes() % 15;
    if (rem !== 0) cand.setMinutes(cand.getMinutes() + (15 - rem), 0, 0);

    const candMin = cand.getHours() * 60 + cand.getMinutes();
    if (candMin <= closeMin) {
      return {
        canOrder: true,
        data: cand,
        dataStr: toYmdLocal(cand),
        horaStr: toHhMmLocal(cand),
        horaFmt: formatHoraCurta(toHhMmLocal(cand)),
        isHoje: false,
        isAmanha: offset === 1,
        diaNome: dayNames[cand.getDay()],
        motivo: `Aprovação a partir das ${formatHoraCurta(diaCfg.abertura)}`
      };
    }
  }

  return {
    canOrder: false,
    data: null,
    motivo: 'Não há horários disponíveis para entrega no momento'
  };
}

// ─── Horários de Funcionamento & Status da Loja ──────────────────────
function isLojaAbertaAgora() {
  const h = state.horariosAtendimento;
  const now = new Date();
  const primEntrega = calcularPrimeiraEntregaPossivel(now, h);

  if (!h) {
    return {
      isOpenImediato: true,
      canSchedule: true,
      labelHeader: 'Aberto para pedidos · Entregas até 22h',
      labelHome: 'Aberto para pedidos · Entregas até 22h',
      badgeClass: 'aberto',
      motivo: 'Recebendo pedidos normalmente',
      primeiraEntrega: primEntrega
    };
  }

  if (h.status === 'fechado') {
    return {
      isOpenImediato: false,
      canSchedule: false,
      labelHeader: 'Fechado temporariamente',
      labelHome: 'Loja fechada temporariamente',
      motivo: h.mensagemFechado || 'Pausado para novos pedidos',
      badgeClass: 'fechado',
      primeiraEntrega: primEntrega
    };
  }

  // Modo 'auto' ou 'aberto': verificar dia da semana e hora atual
  const dayIndex = now.getDay(); // 0 = dom, 1 = seg ...
  const dayKeys = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sab'];
  const currentKey = dayKeys[dayIndex];
  const diaConfig = h.dias ? h.dias[currentKey] : null;

  if (!diaConfig || !diaConfig.ativo) {
    const quandoFmt = primEntrega.isAmanha 
      ? `amanhã, ${primEntrega.horaFmt}` 
      : `${primEntrega.diaNome || 'próximo dia útil'}, ${primEntrega.horaFmt}`;
    return {
      isOpenImediato: false,
      canSchedule: true,
      labelHeader: `Aberto para encomendas · Entregas a partir de ${quandoFmt}`,
      labelHome: `Aberto para encomendas · Entregas a partir de ${quandoFmt}`,
      motivo: h.mensagemFechado || `Não realizamos entregas neste dia. Faça sua encomenda para ${quandoFmt}.`,
      badgeClass: 'agendando',
      fechadoHoje: true,
      primeiraEntrega: primEntrega
    };
  }

  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const [abH, abM] = (diaConfig.abertura || '08:00').split(':').map(Number);
  const [feH, feM] = (diaConfig.fechamento || '22:00').split(':').map(Number);
  const openMinutes = abH * 60 + abM;
  const closeMinutes = feH * 60 + feM;

  let isOpenNow = false;
  if (closeMinutes >= openMinutes) {
    isOpenNow = currentMinutes >= openMinutes && currentMinutes < closeMinutes;
  } else {
    // Horário que cruza meia-noite
    isOpenNow = currentMinutes >= openMinutes || currentMinutes < closeMinutes;
  }

  if (h.status === 'aberto') {
    isOpenNow = true;
  }

  const horaFechamentoFmt = formatHoraCurta(diaConfig.fechamento);

  if (isOpenNow) {
    if (primEntrega.isHoje) {
      return {
        isOpenImediato: true,
        canSchedule: true,
        labelHeader: `Aberto para pedidos · Entregas até ${horaFechamentoFmt}`,
        labelHome: `Aberto para pedidos · Entregas até ${horaFechamentoFmt}`,
        motivo: `Horário de atendimento hoje: ${diaConfig.abertura} às ${diaConfig.fechamento}`,
        badgeClass: 'aberto',
        primeiraEntrega: primEntrega
      };
    } else {
      const quandoFmt = primEntrega.isAmanha 
        ? `amanhã, ${primEntrega.horaFmt}` 
        : `${primEntrega.diaNome || 'próximo dia útil'}, ${primEntrega.horaFmt}`;
      return {
        isOpenImediato: true,
        canSchedule: true,
        labelHeader: `Aberto para pedidos · Entregas a partir de ${quandoFmt}`,
        labelHome: `Aberto para pedidos · Entregas a partir de ${quandoFmt}`,
        motivo: `Horário de atendimento hoje até ${diaConfig.fechamento}. Novos pedidos têm entrega a partir de ${quandoFmt} devido ao tempo de preparo.`,
        badgeClass: 'aviso',
        primeiraEntrega: primEntrega
      };
    }
  } else if (currentMinutes < openMinutes && closeMinutes >= openMinutes) {
    const quandoFmt = primEntrega.isHoje 
      ? primEntrega.horaFmt 
      : (primEntrega.isAmanha ? `amanhã, ${primEntrega.horaFmt}` : `${primEntrega.diaNome}, ${primEntrega.horaFmt}`);
    return {
      isOpenImediato: false,
      canSchedule: true,
      labelHeader: `Aberto para pedidos · Entregas a partir de ${quandoFmt}`,
      labelHome: `Abre hoje às ${diaConfig.abertura} · Entregas a partir de ${quandoFmt}`,
      motivo: `Atendimento inicia hoje às ${diaConfig.abertura}. Pedidos são conferidos e aprovados na abertura, com entrega a partir das ${quandoFmt}.`,
      badgeClass: 'aviso',
      primeiraEntrega: primEntrega
    };
  } else {
    const quandoFmt = primEntrega.isAmanha 
      ? `amanhã, ${primEntrega.horaFmt}` 
      : `${primEntrega.diaNome || 'próximo dia útil'}, ${primEntrega.horaFmt}`;
    return {
      isOpenImediato: false,
      canSchedule: true,
      labelHeader: `Aberto para pedidos · Entregas a partir de ${quandoFmt}`,
      labelHome: `Entregas de hoje encerradas · Próximas entregas a partir de ${quandoFmt}`,
      motivo: h.mensagemFechado || `Atendimento de hoje encerrou às ${diaConfig.fechamento}. Pedidos enviados agora serão aprovados no próximo expediente (${quandoFmt}).`,
      badgeClass: 'agendando',
      primeiraEntrega: primEntrega
    };
  }
}

function updateStoreStatusUI() {
  const statusInfo = isLojaAbertaAgora();

  const dotClass = statusInfo.isOpenImediato && statusInfo.badgeClass === 'aberto'
    ? 'pulse-dot'
    : (statusInfo.badgeClass === 'aviso' ? 'pulse-dot pulse-dot-amber' : 'pulse-dot pulse-dot-red');

  // 1. Header status pill
  const headerPill = document.getElementById('header-status-pill');
  if (headerPill) {
    headerPill.innerHTML = `<span class="${dotClass}"></span> <span class="header-store-pill-txt">${statusInfo.labelHeader}</span>`;
    headerPill.className = `header-store-pill ${statusInfo.badgeClass}`;
    headerPill.style.cursor = 'pointer';
    headerPill.title = 'Clique para ver os horários de atendimento e regras de entrega';
  }

  const minPrazoEl = document.getElementById('checkout-min-prazo-txt');
  if (minPrazoEl) {
    const pe = statusInfo.primeiraEntrega || calcularPrimeiraEntregaPossivel(new Date(), state.horariosAtendimento);
    if (pe && pe.canOrder && pe.horaStr) {
      const dataLabel = pe.isHoje ? 'hoje' : (pe.isAmanha ? 'amanhã' : pe.diaNome);
      minPrazoEl.textContent = `${dataLabel} a partir das ${pe.horaStr}`;
    } else {
      const prazo = state.horariosAtendimento?.prazoMinimoMinutos || 120;
      minPrazoEl.textContent = prazo >= 60 ? `${Math.round(prazo / 60)} hora(s)` : `${prazo} min`;
    }
  }
}

function openHorariosModal() {
  const modal = document.getElementById('modal-horarios');
  if (!modal) return;

  const statusInfo = isLojaAbertaAgora();
  const tagEl = document.getElementById('modal-horarios-status-tag');
  if (tagEl) {
    tagEl.textContent = statusInfo.isOpenImediato ? statusInfo.labelHeader : 'Aberto para Encomendas Agendadas';
    tagEl.className = `order-status-pill ${statusInfo.isOpenImediato && statusInfo.badgeClass === 'aberto' ? 'status-confirmado' : 'status-preparando'}`;
  }

  const prazoEl = document.getElementById('modal-horarios-prazo-desc');
  if (prazoEl && state.horariosAtendimento) {
    const p = state.horariosAtendimento.prazoMinimoMinutos || 120;
    const horasFmt = p >= 60 ? `${Math.round(p / 60)}h (${p} min)` : `${p} minutos`;
    prazoEl.textContent = `Prazo mínimo de produção de ${horasFmt} para entrega após aprovação do pedido. Pedidos feitos fora do horário de atendimento são conferidos e aprovados no início do próximo expediente.`;
  }

  const gridEl = document.getElementById('modal-horarios-grid');
  if (gridEl && state.horariosAtendimento?.dias) {
    const dayKeys = [
      { key: 'seg', label: 'Segunda-feira' },
      { key: 'ter', label: 'Terça-feira' },
      { key: 'qua', label: 'Quarta-feira' },
      { key: 'qui', label: 'Quinta-feira' },
      { key: 'sex', label: 'Sexta-feira' },
      { key: 'sab', label: 'Sábado' },
      { key: 'dom', label: 'Domingo' }
    ];

    const todayIdx = new Date().getDay(); // 0=dom, 1=seg...
    const todayKey = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sab'][todayIdx];

    gridEl.innerHTML = dayKeys.map(d => {
      const diaConfig = state.horariosAtendimento.dias[d.key] || { ativo: true, abertura: '08:00', fechamento: '22:00' };
      const isToday = d.key === todayKey;
      const horarioStr = diaConfig.ativo ? `${diaConfig.abertura} às ${diaConfig.fechamento}` : 'Fechado';
      const statusColor = diaConfig.ativo ? 'var(--text-primary)' : 'var(--text-muted)';
      const isTodayBg = isToday ? 'background:rgba(249, 115, 22, 0.1);border:1px solid rgba(249, 115, 22, 0.3);border-radius:8px;' : 'background:rgba(255,255,255,0.03);border-radius:8px;';

      return `
        <div style="display:flex;justify-content:space-between;align-items:center;padding:8px 12px;font-size:12.5px;${isTodayBg}">
          <div style="font-weight:${isToday ? '800' : '600'};color:${isToday ? 'var(--brand-400)' : 'var(--text-secondary)'}">
            ${d.label} ${isToday ? '<span style="font-size:10px;background:var(--brand-400);color:#fff;padding:2px 6px;border-radius:10px;margin-left:4px">HOJE</span>' : ''}
          </div>
          <div style="font-weight:700;color:${statusColor};font-family:monospace">
            ${horarioStr}
          </div>
        </div>
      `;
    }).join('');
  }

  modal.classList.add('open');
}

function closeHorariosModal() {
  document.getElementById('modal-horarios')?.classList.remove('open');
}

// ─── Validação de Horários de Atendimento & Prazo Mínimo ────────────
function validateOrderSchedule(data, hora) {
  if (!data || !hora) {
    return { valid: false, message: 'Informe a data e o horário previstos para o pedido.' };
  }

  const selectedDateTime = new Date(`${data}T${hora}:00`);
  if (isNaN(selectedDateTime.getTime())) {
    return { valid: false, message: 'Data ou horário inválidos.' };
  }

  const agora = new Date();
  if (selectedDateTime <= agora) {
    return { valid: false, message: 'A data e horário selecionados não podem ser retroativos. Escolha um horário futuro.' };
  }

  const h = state.horariosAtendimento;
  if (!h) {
    return { valid: true };
  }

  // 1. Validar se a loja está com status 'fechado' forçado
  if (h.status === 'fechado') {
    return { valid: false, message: h.mensagemFechado || 'A loja está fechada no momento para novos pedidos.' };
  }

  // 1.1 Validar Primeiro Horário Viável (Considera aprovação prévia e expediente da cozinha)
  const primEntrega = calcularPrimeiraEntregaPossivel(agora, h);
  if (!primEntrega.canOrder) {
    return { valid: false, message: primEntrega.motivo || 'A loja está fechada no momento para novos pedidos.' };
  }

  if (primEntrega.data && selectedDateTime < primEntrega.data) {
    const dataFmt = primEntrega.isHoje 
      ? 'hoje' 
      : (primEntrega.isAmanha ? 'amanhã' : `${primEntrega.diaNome} (${primEntrega.data.toLocaleDateString('pt-BR')})`);
    return {
      valid: false,
      message: `Horário mais próximo disponível para entrega: ${dataFmt} a partir das ${primEntrega.horaStr}. Pedidos realizados fora do expediente aguardam aprovação da cozinha na abertura.`
    };
  }

  // 2. Validar Bloqueios Específicos de Agendamento (Feriados / Compromissos / Datas Bloqueadas)
  if (Array.isArray(h.bloqueios) && h.bloqueios.length > 0) {
    const toIsoDate = (val) => {
      if (!val) return '';
      const s = String(val).trim().split('T')[0];
      if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
      if (/^\d{2}\/\d{2}\/\d{4}$/.test(s)) {
        const [d, m, y] = s.split('/');
        return `${y}-${m}-${d}`;
      }
      return s;
    };

    const targetDateIso = toIsoDate(data);

    for (const b of h.bloqueios) {
      if (!b || !b.data) continue;
      const blockDateIso = toIsoDate(b.data);

      if (blockDateIso === targetDateIso) {
        const parts = blockDateIso.split('-');
        const dataFmt = parts.length === 3 ? `${parts[2]}/${parts[1]}/${parts[0]}` : b.data;
        const motivo = b.motivo ? ` (Motivo: ${b.motivo})` : '';

        const isDiaTodo = b.diaTodo === true || b.dia_todo === true || (!b.inicio && !b.fim);
        if (isDiaTodo) {
          return {
            valid: false,
            message: `Não estamos aceitando agendamentos para o dia ${dataFmt}${motivo}. Por favor, escolha outra data.`
          };
        } else {
          // Validação de intervalo de horário específico
          const [bIniH, bIniM] = (b.inicio || '00:00').split(':').map(Number);
          const [bFimH, bFimM] = (b.fim || '23:59').split(':').map(Number);
          const blockStartMin = (bIniH || 0) * 60 + (bIniM || 0);
          const blockEndMin = (bFimH || 0) * 60 + (bFimM || 0);
          const selectedMin = selectedDateTime.getHours() * 60 + selectedDateTime.getMinutes();

          if (selectedMin >= blockStartMin && selectedMin <= blockEndMin) {
            return {
              valid: false,
              message: `No dia ${dataFmt}, não estamos aceitando agendamentos entre ${b.inicio} e ${b.fim}${motivo}. Por favor, selecione outro horário.`
            };
          }
        }
      }
    }
  }

  // 4. Validar Dia da Semana e Horário de Funcionamento para o dia agendado
  if (h.dias) {
    const dayKeys = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sab'];
    const selectedDayKey = dayKeys[selectedDateTime.getDay()];
    const diaConfig = h.dias[selectedDayKey];

    const dayNames = {
      dom: 'Domingo',
      seg: 'Segunda-feira',
      ter: 'Terça-feira',
      qua: 'Quarta-feira',
      qui: 'Quinta-feira',
      sex: 'Sexta-feira',
      sab: 'Sábado'
    };

    if (!diaConfig || !diaConfig.ativo) {
      return {
        valid: false,
        message: `Não realizamos entregas/atendimento aos(às) ${dayNames[selectedDayKey] || 'dias selecionados'}. Escolha outro dia de funcionamento.`
      };
    }

    const selectedMinOfDay = selectedDateTime.getHours() * 60 + selectedDateTime.getMinutes();
    const [abH, abM] = (diaConfig.abertura || '08:00').split(':').map(Number);
    const [feH, feM] = (diaConfig.fechamento || '22:00').split(':').map(Number);
    const openMin = abH * 60 + abM;
    const closeMin = feH * 60 + feM;

    if (selectedMinOfDay < openMin || selectedMinOfDay > closeMin) {
      return {
        valid: false,
        message: `O horário selecionado (${hora}) está fora do horário de atendimento de ${dayNames[selectedDayKey]} (${diaConfig.abertura} às ${diaConfig.fechamento}).`
      };
    }
  }

  return { valid: true };
}

// ─── Sincronização Automática com Cadastro de Clientes do ERP ────────
async function syncCustomerToErp(cust) {
  if (!cust) return null;
  const tenantId = cust.tenantId || state.tenantId || DEFAULT_TENANT_ID;
  const agora = new Date().toISOString();
  const fallbackUserId = (state.session?.user?.id && state.session.user.id.includes('-')) 
    ? state.session.user.id 
    : '00000000-0000-0000-0000-000000000000';

  let rawPhone = cust.telefone || '';
  let cleanDigits = rawPhone.replace(/\D/g, '');
  if (cleanDigits.length >= 12 && cleanDigits.startsWith('55')) {
    cleanDigits = cleanDigits.substring(2);
  }
  const formattedPhone = formatPhone(cleanDigits);

  let existingCustomer = null;

  try {
    // 1. Buscar todos os clientes da empresa para comparação normalizada de dígitos
    const { data: allClients } = await sb
      .from('cliente')
      .select('id, nome, telefone, email, observacoes')
      .eq('tenantId', tenantId);

    if (allClients && allClients.length > 0) {
      // 1.1 Se o perfil já tiver cliente_local_id salvo, verifica se existe
      if (state.profile?.cliente_local_id) {
        existingCustomer = allClients.find(c => c.id === state.profile.cliente_local_id);
      }

      // 1.2 Busca por dígitos de telefone (prefere o cadastro mais completo / oficial)
      if (!existingCustomer && cleanDigits && cleanDigits.length >= 8) {
        const matches = allClients.filter(c => {
          let cDigits = (c.telefone || '').replace(/\D/g, '');
          if (cDigits.length >= 12 && cDigits.startsWith('55')) cDigits = cDigits.substring(2);
          return cDigits === cleanDigits || (cDigits.length >= 10 && cleanDigits.length >= 10 && (cDigits.endsWith(cleanDigits) || cleanDigits.endsWith(cDigits)));
        });

        if (matches.length > 0) {
          // Ordena para priorizar o cadastro mais detalhado/completo
          matches.sort((a, b) => (b.nome || '').length - (a.nome || '').length);
          existingCustomer = matches[0];
        }
      }

      // 1.3 Se não achou por telefone, tentar por email
      if (!existingCustomer && cust.email && cust.email.includes('@')) {
        existingCustomer = allClients.find(c => (c.email || '').trim().toLowerCase() === cust.email.trim().toLowerCase());
      }
    }

    let resolvedClientId = null;
    let resolvedClientName = cust.nome;

    if (!existingCustomer) {
      // Criar novo registro de Cliente no ERP
      resolvedClientId = crypto.randomUUID();
      const { error: insErr } = await sb.from('cliente').insert({
        id: resolvedClientId,
        tenantId: tenantId,
        nome: cust.nome,
        telefone: formattedPhone || cleanDigits || 'Não informado',
        email: cust.email || null,
        observacoes: 'Cliente cadastrado via Cardápio Digital Web',
        ativo: true,
        aceitaWhatsapp: true,
        aceitaMarketing: false,
        preferenciaEntrega: 'Entrega',
        createdAt: agora,
        updatedAt: agora,
        createdBy: fallbackUserId,
        updatedBy: fallbackUserId,
        syncVersion: 1
      });
      if (insErr) console.warn('Aviso ao inserir cliente no ERP:', insErr.message);
    } else {
      // Cliente existente encontrado! O cadastro do ERP SEMPRE prevalece (nome oficial do cliente)
      resolvedClientId = existingCustomer.id;
      resolvedClientName = existingCustomer.nome;

      // Se o telefone do cadastro oficial ainda não estiver com máscara, formata
      const updates = {
        updatedAt: agora,
        updatedBy: fallbackUserId,
      };
      if (formattedPhone && existingCustomer.telefone !== formattedPhone) {
        updates.telefone = formattedPhone;
      }
      if (cust.email && !existingCustomer.email) {
        updates.email = cust.email;
      }

      if (!existingCustomer.observacoes || existingCustomer.observacoes.trim() === '') {
        updates.observacoes = 'Cliente do Cardápio Digital Web';
      }

      await sb.from('cliente').update(updates).eq('id', resolvedClientId);
    }

    // 3. Sincronizar endereço na tabela 'local_entrega' (evitando duplicatas da mesma rua e número)
    if (cust.logradouro && cust.numero && resolvedClientId) {
      const { data: existingLocais } = await sb
        .from('local_entrega')
        .select('id, logradouro, numero, referencia, nomeIdentificador')
        .eq('tenantId', tenantId)
        .eq('clienteId', resolvedClientId)
        .is('deletedAt', null);

      const normStreet = (s) => (s || '').toLowerCase().trim().replace(/^(rua|av|avenida|travessa|alameda|r\.)\s+/i, '').replace(/\s+/g, ' ');
      const normNum = (n) => String(n || '').toLowerCase().trim();
      const currentKey = `${normStreet(cust.logradouro)}::${normNum(cust.numero)}`;

      const duplicate = (existingLocais || []).find(l => `${normStreet(l.logradouro)}::${normNum(l.numero)}` === currentKey);

      if (duplicate) {
        // Já existe esse endereço: se tiver nova referência ou complemento, atualiza
        const novaRef = cust.referencia || (cust.complemento ? `Compl: ${cust.complemento}` : '');
        if (novaRef && !duplicate.referencia) {
          await sb.from('local_entrega').update({
            referencia: novaRef,
            updatedAt: agora,
            updatedBy: fallbackUserId
          }).eq('id', duplicate.id);
        }
      } else {
        const { error: locErr } = await sb.from('local_entrega').insert({
          id: crypto.randomUUID(),
          tenantId: tenantId,
          clienteId: resolvedClientId,
          nomeIdentificador: (existingLocais && existingLocais.length > 0) ? 'Outro Endereço' : 'Endereço Principal',
          logradouro: cust.logradouro,
          numero: cust.numero || 'S/N',
          bairro: cust.bairro || '',
          cidade: cust.cidade || '',
          cep: cust.cep || '',
          referencia: cust.referencia || (cust.complemento ? `Compl: ${cust.complemento}` : ''),
          ativo: true,
          createdAt: agora,
          updatedAt: agora,
          createdBy: fallbackUserId,
          updatedBy: fallbackUserId,
          syncVersion: 1
        });
        if (locErr) console.warn('Aviso ao inserir local_entrega no ERP:', locErr.message);
      }
    }

    // 4. Se tiver perfil em cardapio_clientes, atualizar cliente_local_id
    if (state.profile && state.profile.id && state.profile.cliente_local_id !== resolvedClientId) {
      await sb.from('cardapio_clientes').update({
        cliente_local_id: resolvedClientId
      }).eq('id', state.profile.id);
      state.profile.cliente_local_id = resolvedClientId;
    }

    return {
      id: resolvedClientId,
      nome: resolvedClientName,
      telefone: formattedPhone || existingCustomer?.telefone || rawPhone
    };
  } catch (err) {
    console.warn('Erro ao sincronizar cliente com ERP:', err);
    return {
      id: existingCustomer?.id || null,
      nome: existingCustomer?.nome || cust.nome,
      telefone: formattedPhone || rawPhone
    };
  }
}

// ─── Utilitários de Formatação & Sanitização ─────────────────────────
function formatPhone(phoneStr) {
  if (!phoneStr) return '';
  let clean = String(phoneStr).replace(/\D/g, '');
  if (clean.length >= 12 && clean.startsWith('55')) {
    clean = clean.substring(2);
  }
  if (clean.length > 11) {
    clean = clean.substring(0, 11);
  }
  if (clean.length === 11) {
    return `(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7)}`;
  }
  if (clean.length === 10) {
    return `(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6)}`;
  }
  if (clean.length > 6) {
    return `(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6)}`;
  }
  if (clean.length > 2) {
    return `(${clean.substring(0, 2)}) ${clean.substring(2)}`;
  }
  if (clean.length > 0) {
    return `(${clean}`;
  }
  return '';
}

function validatePhone(phoneStr) {
  if (!phoneStr) return { valid: false, error: 'Por favor, informe seu WhatsApp / Telefone com DDD.' };
  let clean = String(phoneStr).replace(/\D/g, '');
  if (clean.length >= 12 && clean.startsWith('55')) {
    clean = clean.substring(2);
  }
  if (clean.length < 10) {
    return { valid: false, error: 'Telefone incompleto. Informe DDD + número (ex: 35 99999-9999).' };
  }
  if (clean.length > 11) {
    return { valid: false, error: 'Telefone com dígitos a mais. Verifique o número informado.' };
  }
  const ddd = parseInt(clean.substring(0, 2), 10);
  if (isNaN(ddd) || ddd < 11 || ddd > 99) {
    return { valid: false, error: 'DDD inválido. Informe um DDD válido do Brasil (ex: 35, 11).' };
  }
  if (clean.length === 11 && clean[2] !== '9') {
    return { valid: false, error: 'Celulares com 11 dígitos devem começar com 9 após o DDD.' };
  }
  return { valid: true, clean, formatted: formatPhone(clean) };
}

// ─── Busca e Amarração de Cliente pelo Telefone (Sistema Windows / ERP) ────
async function findErpCustomerByPhone(phoneStr) {
  const phoneVal = validatePhone(phoneStr);
  if (!phoneVal.valid) return null;
  const cleanDigits = phoneVal.clean;
  const tenantId = state.tenantId || DEFAULT_TENANT_ID;

  try {
    const { data: allClients, error } = await sb
      .from('cliente')
      .select('id, nome, telefone, email, observacoes')
      .eq('tenantId', tenantId);

    if (error || !allClients || allClients.length === 0) return null;

    const matched = allClients.find(c => {
      let cDigits = (c.telefone || '').replace(/\D/g, '');
      if (cDigits.length >= 12 && cDigits.startsWith('55')) cDigits = cDigits.substring(2);
      return cDigits === cleanDigits || (cDigits.length >= 10 && cleanDigits.length >= 10 && (cDigits.endsWith(cleanDigits) || cleanDigits.endsWith(cDigits)));
    });

    if (!matched) return null;

    // Se encontrou o cliente no ERP, busca endereços cadastrados no local_entrega
    const { data: locais } = await sb
      .from('local_entrega')
      .select('*')
      .eq('tenantId', tenantId)
      .eq('clienteId', matched.id)
      .eq('ativo', true)
      .limit(1);

    const mainEndereco = (locais && locais.length > 0) ? locais[0] : null;

    return {
      cliente: matched,
      endereco: mainEndereco
    };
  } catch (err) {
    console.warn('Aviso ao buscar cliente do ERP por telefone:', err);
    return null;
  }
}

// ─── Modal de Confirmação de Cadastro Localizado no ERP ("Encontramos você!") ──
let currentErpFoundContext = {
  cliente: null,
  endereco: null,
  inputEl: null,
  prefix: 'account',
  previousName: '',
  previousPhone: ''
};

function openErpFoundModal(cliente, endereco, inputEl = null, prefix = 'account', previousName = '', previousPhone = '') {
  const modal = document.getElementById('modal-erp-customer-found');
  if (!modal) return;

  currentErpFoundContext = {
    cliente,
    endereco,
    inputEl,
    prefix,
    previousName,
    previousPhone
  };

  const nameEl = document.getElementById('erp-found-client-name');
  const phoneEl = document.getElementById('erp-found-client-phone');
  const streetEl = document.getElementById('erp-found-addr-street');
  const bairroEl = document.getElementById('erp-found-addr-bairro');
  const cityUfEl = document.getElementById('erp-found-addr-city-uf');
  const cepEl = document.getElementById('erp-found-addr-cep');
  const linesBox = document.getElementById('erp-found-client-address');
  const noAddrMsg = document.getElementById('erp-found-no-address');
  const editAddrBtn = document.getElementById('btn-erp-found-edit-address');

  if (nameEl) nameEl.textContent = cliente.nome || 'Cliente';
  if (phoneEl) phoneEl.textContent = formatPhone(cliente.telefone || '');

  const hasAddress = endereco && (endereco.logradouro || endereco.bairro);
  if (hasAddress) {
    if (streetEl) streetEl.textContent = `${endereco.logradouro || 'Rua não informada'}, ${endereco.numero || 'S/N'}${endereco.referencia ? ' (' + endereco.referencia + ')' : ''}`;
    if (bairroEl) bairroEl.textContent = endereco.bairro || '';
    if (cityUfEl) cityUfEl.textContent = `${endereco.cidade || state.empresa?.cidade || 'Pouso Alegre'}${endereco.uf ? ' - ' + endereco.uf : ' - MG'}`;
    if (cepEl) cepEl.textContent = endereco.cep ? `CEP ${endereco.cep}` : '';

    if (linesBox) linesBox.style.display = 'flex';
    if (noAddrMsg) noAddrMsg.style.display = 'none';
    if (editAddrBtn) editAddrBtn.style.display = 'inline-block';
  } else {
    if (linesBox) linesBox.style.display = 'none';
    if (noAddrMsg) noAddrMsg.style.display = 'block';
    if (editAddrBtn) editAddrBtn.style.display = 'none';
  }

  modal.classList.add('open');
}

function closeErpFoundModal() {
  document.getElementById('modal-erp-customer-found')?.classList.remove('open');
}

function handleConfirmFoundCustomer() {
  const ctx = currentErpFoundContext;
  const btn = document.getElementById('btn-erp-found-confirm');
  const btnText = document.getElementById('btn-confirm-text');
  
  if (btn) btn.disabled = true;
  if (btnText) btnText.textContent = 'Confirmando...';

  setTimeout(() => {
    closeErpFoundModal();
    if (btn) btn.disabled = false;
    if (btnText) btnText.textContent = 'Usar este cadastro e continuar';

    toast(`Olá, ${ctx.cliente?.nome || 'Cliente'}! Cadastro confirmado com sucesso.`, 'success', 3500);

    // Se estiver no checkout, atualiza a exibição de endereço e contato
    if (ctx.prefix === 'checkout' || document.getElementById('screen-checkout')?.classList.contains('active')) {
      populateSavedAddressInCheckout();
      updateCheckoutTotals();
      validateCheckoutForm();
    }
  }, 350);
}

function handleRejectFoundCustomer() {
  const ctx = currentErpFoundContext;
  closeErpFoundModal();

  // Limpa o input do WhatsApp e foca para que o usuário informe seu próprio número
  if (ctx.inputEl) {
    ctx.inputEl.value = '';
    ctx.inputEl.focus();
  }

  // Restaura o nome anterior se havia sido alterado
  const nameEl = document.getElementById(`${ctx.prefix === 'account' ? 'account' : 'reg'}-name`);
  if (nameEl && ctx.previousName) {
    nameEl.value = ctx.previousName;
  }
  const checkoutNameEl = document.getElementById('checkout-nome-cliente');
  if (checkoutNameEl && ctx.previousName) {
    checkoutNameEl.value = ctx.previousName;
  }
  const displayAccountName = document.getElementById('account-user-display-name');
  if (displayAccountName && ctx.previousName) {
    displayAccountName.textContent = ctx.previousName;
  }

  // Reverte no profile em memória (sem deletar nem criar outro cliente no banco)
  if (state.profile) {
    state.profile.cliente_local_id = null;
    state.profile.nome = ctx.previousName || state.session?.user?.user_metadata?.full_name || 'Cliente';
  }
  updateHeaderUI();

  toast('Sem problemas! Informe o seu WhatsApp correto abaixo.', 'info', 3500);
}

function handleEditAddressFromModal() {
  const ctx = currentErpFoundContext;
  closeErpFoundModal();

  toast('Você pode alterar ou adicionar um novo endereço abaixo.', 'info', 3500);

  if (ctx.prefix === 'checkout' || document.getElementById('screen-checkout')?.classList.contains('active')) {
    // Aciona o fluxo existente de adicionar/editar endereço do checkout
    const btnAddNovo = document.getElementById('btn-add-novo-endereco');
    if (btnAddNovo) {
      btnAddNovo.click();
    } else {
      document.getElementById('checkout-logradouro')?.focus();
    }
  } else if (ctx.prefix === 'account' || document.getElementById('screen-account')?.classList.contains('active')) {
    document.getElementById('account-logradouro')?.focus();
  } else {
    document.getElementById('reg-logradouro')?.focus();
  }
}

async function checkPhoneErpAutoLink(phoneInputEl, prefix = 'account') {
  const raw = phoneInputEl?.value || '';
  const val = validatePhone(raw);
  if (!val.valid) return;

  const previousName = document.getElementById(`${prefix === 'account' ? 'account' : 'reg'}-name`)?.value || state.profile?.nome || '';
  const previousPhone = raw;

  const found = await findErpCustomerByPhone(val.clean);
  if (found && found.cliente) {
    const cli = found.cliente;
    const end = found.endereco;

    // 1. Atualizar o Nome do Cliente na tela com o nome oficial do sistema Windows
    const nameEl = document.getElementById(`${prefix === 'account' ? 'account' : 'reg'}-name`);
    if (nameEl) {
      nameEl.value = cli.nome;
    }
    const checkoutNameEl = document.getElementById('checkout-nome-cliente');
    if (checkoutNameEl) {
      checkoutNameEl.value = cli.nome;
    }

    // Atualiza nome na tela de Minha Conta (título do display)
    const displayAccountName = document.getElementById('account-user-display-name');
    if (displayAccountName) displayAccountName.textContent = cli.nome;

    // 2. Preencher endereço do ERP se houver
    if (end) {
      const logrEl = document.getElementById(`${prefix === 'account' ? 'account' : 'reg'}-logradouro`);
      const numEl  = document.getElementById(`${prefix === 'account' ? 'account' : 'reg'}-numero`);
      const bairEl = document.getElementById(`${prefix === 'account' ? 'account' : 'reg'}-bairro`);
      const cidEl  = document.getElementById(`${prefix === 'account' ? 'account' : 'reg'}-cidade`);
      const cepEl  = document.getElementById(`${prefix === 'account' ? 'account' : 'reg'}-cep`);
      const compEl = document.getElementById(`${prefix === 'account' ? 'account' : 'reg'}-complemento`);

      if (logrEl && end.logradouro) logrEl.value = end.logradouro;
      if (numEl && end.numero) numEl.value = end.numero;
      if (bairEl && end.bairro) bairEl.value = end.bairro;
      if (cidEl && end.cidade) cidEl.value = end.cidade;
      if (cepEl && end.cep) cepEl.value = end.cep;
      if (compEl && end.referencia) compEl.value = end.referencia;
    }

    // 3. Atualiza estado em memória e banco de dados
    if (state.profile) {
      state.profile.nome = cli.nome;
      state.profile.whatsapp = val.clean;
      state.profile.cliente_local_id = cli.id;
      if (end) {
        state.profile.logradouro = end.logradouro || state.profile.logradouro;
        state.profile.numero = end.numero || state.profile.numero;
        state.profile.bairro = end.bairro || state.profile.bairro;
        state.profile.cidade = end.cidade || state.profile.cidade;
        state.profile.cep = end.cep || state.profile.cep;
      }

      // Sincronizar em cardapio_clientes
      sb.from('cardapio_clientes').update({
        nome: cli.nome,
        whatsapp: val.clean,
        cliente_local_id: cli.id,
        logradouro: end?.logradouro || state.profile.logradouro || null,
        numero: end?.numero || state.profile.numero || null,
        bairro: end?.bairro || state.profile.bairro || null,
        cidade: end?.cidade || state.profile.cidade || null,
        cep: end?.cep || state.profile.cep || null,
        updated_at: new Date().toISOString()
      }).eq('id', state.profile.id).then(() => {}).catch(err => console.warn('Erro ao sincronizar perfil:', err));
    }

    // Atualiza cabeçalho e avatar
    updateHeaderUI();

    // 4. Dispara a nova experiência visual do modal "Encontramos você!"
    openErpFoundModal(cli, end, phoneInputEl, prefix, previousName, previousPhone);
  }
}

const fmt = (centavos) =>
  'R$ ' + (Number(centavos || 0) / 100).toFixed(2).replace('.', ',');

const fmtDate = (iso) => {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' });
};

const fmtDateTime = (iso) => {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleString('pt-BR', {
    day: '2-digit', month: '2-digit',
    hour: '2-digit', minute: '2-digit'
  });
};

function getDeliveryDateTime(order) {
  if (!order) return '—';
  if (order.dataHoraEntregaPrevista) return fmtDateTime(order.dataHoraEntregaPrevista);
  if (order.data_hora_entrega_prevista) return fmtDateTime(order.data_hora_entrega_prevista);
  if (order.dataEntrega) return fmtDateTime(order.dataEntrega);
  if (order.observacoes && typeof order.observacoes === 'string') {
    const match = order.observacoes.match(/agendado:\s*([^\n\r]+)/i);
    if (match && match[1]) return match[1].trim();
  }
  return fmtDateTime(order.createdAt || order.dataHoraCriacao);
}

function slugify(text) {
  return String(text || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim();
}

// Mapeador Inteligente de Ícones — converte qualquer slug do Material Icons em emoji
// Nunca deixa strings como "fastfood", "local_pizza", "restaurant" aparecerem na UI
function getCategoryIcon(iconRaw, nameRaw = '') {
  const iconStr = String(iconRaw || '').toLowerCase().trim();
  const nameStr = String(nameRaw || '').toLowerCase().trim();

  // Se já for um emoji Unicode válido, retorna direto
  if (/\p{Emoji}/u.test(String(iconRaw || '')) && !/^[a-zA-Z_]+$/.test(String(iconRaw || '').trim())) {
    return iconRaw;
  }

  // Mapeamento por nome do produto/categoria (mais específico primeiro)
  if (nameStr.includes('coxinha')) return '🍗';
  if (nameStr.includes('kibe') || nameStr.includes('quibe')) return '🥙';
  if (nameStr.includes('bolinha') || nameStr.includes('risole') || nameStr.includes('rissole')) return '🥟';
  if (nameStr.includes('cigarrete') || nameStr.includes('enrolado') || nameStr.includes('salsicha')) return '🌯';
  if (nameStr.includes('empada') || nameStr.includes('empadin')) return '🥐';
  if (nameStr.includes('pastel')) return '🥐';
  if (nameStr.includes('festa') || nameStr.includes('kit') || nameStr.includes('cento') || nameStr.includes('bandeja')) return '🎉';
  if (nameStr.includes('pizza')) return '🍕';
  if (nameStr.includes('burger') || nameStr.includes('hamburguer') || nameStr.includes('lanche')) return '🍔';
  if (nameStr.includes('doce') || nameStr.includes('bolo') || nameStr.includes('torta') || nameStr.includes('sobremesa')) return '🍰';
  if (nameStr.includes('suco') || nameStr.includes('refrigerante') || nameStr.includes('bebida') || nameStr.includes('drink')) return '🥤';
  if (nameStr.includes('cafe') || nameStr.includes('coffee')) return '☕';
  if (nameStr.includes('salgado') || nameStr.includes('frito') || nameStr.includes('assado')) return '🥟';

  // Mapeamento por slug do ícone Material Design
  if (iconStr === 'fastfood' || iconStr.includes('fastfood')) return '🥟'; // Mini salgados são snacks
  if (iconStr.includes('local_pizza') || iconStr.includes('pizza')) return '🍕';
  if (iconStr.includes('restaurant') || iconStr.includes('dining')) return '🍽️';
  if (iconStr.includes('bakery') || iconStr.includes('cake')) return '🎂';
  if (iconStr.includes('coffee') || iconStr.includes('cafe') || iconStr.includes('local_cafe')) return '☕';
  if (iconStr.includes('drink') || iconStr.includes('liquor') || iconStr.includes('local_bar')) return '🥤';
  if (iconStr.includes('icecream') || iconStr.includes('ice_cream')) return '🍦';
  if (iconStr.includes('tapas') || iconStr.includes('appetizer')) return '🥗';
  if (iconStr.includes('ramen') || iconStr.includes('soup')) return '🍜';
  if (iconStr.includes('lunch') || iconStr.includes('brunch')) return '🥘';
  if (iconStr.includes('star') || iconStr.includes('grade')) return '⭐';
  if (iconStr.includes('set_meal') || iconStr.includes('meal')) return '🍱';

  return '🍽️';
}

function sanitizeCategoryName(rawName) {
  if (!rawName) return 'Geral';
  // Remove qualquer slug do Material Icons que possa ter vazado
  const cleaned = rawName
    .replace(/\bfastfood\b|\blocal_\w+\b|\brestaurant\b|\bbakery\b|\bcake\b|\bcoffee\b|\bdrink\b|\bdining\b/gi, '')
    .trim();
  return cleaned || rawName;
}

// ─── Motor de Precificação Comercial & Lotes ─────────────────────────
function getCategoryCartQty(categoriaId, excludeProdId = null) {
  return state.cart
    .filter(item => item.produto.categoria_id === categoriaId && item.produto.id !== excludeProdId)
    .reduce((sum, item) => sum + item.qty, 0);
}

function getMinQtyForCategory(categoriaId) {
  if (!state.precificacao || state.precificacao.length === 0) return 0;
  const tiers = state.precificacao.filter(t => t.categoria_id === categoriaId);
  if (tiers.length === 0) return 0;
  const minTiers = tiers.map(t => t.qtd_minima).filter(q => q > 0);
  return minTiers.length > 0 ? Math.min(...minTiers) : 0;
}

function getTiersForProduct(produto) {
  if (!produto || !state.precificacao) return [];
  const pId = produto.id;
  const cId = produto.categoria_id;

  const rawTiers = state.precificacao.filter(t =>
    (t.categoria_id && t.categoria_id === cId) ||
    (t.produto_id && t.produto_id === pId)
  );

  const uniqueTiers = [];
  const seen = new Set();
  for (const t of rawTiers) {
    const key = `${t.qtd_minima}_${t.qtd_maxima || ''}_${t.valor_unitario_centavos}`;
    if (!seen.has(key)) {
      seen.add(key);
      uniqueTiers.push(t);
    }
  }

  return uniqueTiers.sort((a, b) => a.qtd_minima - b.qtd_minima);
}

function getBaseUnitPrice(produto) {
  if (!produto) return 0;
  const tiers = getTiersForProduct(produto);
  if (tiers && tiers.length > 0 && tiers[0].valor_unitario_centavos) {
    return tiers[0].valor_unitario_centavos;
  }
  try {
    if (produto.metadata) {
      const m = typeof produto.metadata === 'string' ? JSON.parse(produto.metadata) : produto.metadata;
      if (m.preco_base) return Math.round(parseFloat(m.preco_base) * 100);
    }
  } catch (_) {}
  return 100;
}

function normalizarChavePixBacen(chave, tipo = '') {
  if (!chave) return '';
  let clean = String(chave).trim();
  const tipoUpper = String(tipo || '').toUpperCase().trim();

  // 1. Tipo Telefone / Celular
  if (tipoUpper.includes('TEL') || tipoUpper.includes('CEL') || tipoUpper.includes('FONE')) {
    let digits = clean.replace(/\D/g, '');
    if (digits.startsWith('55') && (digits.length === 12 || digits.length === 13)) {
      digits = digits.substring(2);
    }
    return `+55${digits}`;
  }

  // 2. CPF
  if (tipoUpper.includes('CPF')) {
    return clean.replace(/\D/g, '');
  }

  // 3. CNPJ
  if (tipoUpper.includes('CNPJ')) {
    return clean.replace(/\D/g, '');
  }

  // 4. E-mail
  if (tipoUpper.includes('EMAIL') || tipoUpper.includes('E-MAIL') || clean.includes('@')) {
    return clean.toLowerCase().replace(/\s+/g, '');
  }

  // 5. Auto-detecção inteligente quando tipo omitido
  if (clean.includes('@')) {
    return clean.toLowerCase().replace(/\s+/g, '');
  }
  if (clean.startsWith('+')) {
    return `+${clean.replace(/\D/g, '')}`;
  }

  const digits = clean.replace(/\D/g, '');
  // CNPJ: 14 dígitos
  if (digits.length === 14) return digits;

  // Telefone com DDI 55 já embutido
  if ((digits.length === 12 || digits.length === 13) && digits.startsWith('55')) {
    return `+${digits}`;
  }

  // Telefone fixo (10 dígitos: DDD + 8 dígitos)
  if (digits.length === 10) return `+55${digits}`;

  // Celular 11 dígitos (DDD + 9 dígitos)
  if (digits.length === 11) {
    const ddd = parseInt(digits.substring(0, 2), 10);
    const nono = digits.substring(2, 3);
    // Se tem formato de celular brasileiro com 9 no início
    if (ddd >= 11 && ddd <= 99 && nono === '9' && (clean.includes('(') || clean.includes('-') || clean.includes(' ') || clean.length > 11)) {
      return `+55${digits}`;
    }
    return digits; // CPF 11 dígitos
  }

  // Chave Aleatória (EVP UUID) ou texto
  return clean.toLowerCase().replace(/\s+/g, '');
}

function getEmpresaWhatsAppClean() {
  const raw = state.empresa?.whatsapp || state.empresa?.telefone || '';
  let digits = String(raw).replace(/\D/g, '');
  if (!digits) return '';

  // Corrige duplicações acidentais de DDI 55 (ex: 555535998339825 -> 5535998339825)
  while (digits.startsWith('5555')) {
    digits = digits.substring(2);
  }

  // Se tem 10 ou 11 dígitos (DDD + número), adiciona o DDI 55
  if (digits.length === 10 || digits.length === 11) {
    return `55${digits}`;
  }

  // Se tem 12 ou 13 dígitos e já começa com 55, está perfeito
  if ((digits.length === 12 || digits.length === 13) && digits.startsWith('55')) {
    return digits;
  }

  // Fallback
  if (!digits.startsWith('55') && digits.length <= 11) {
    return `55${digits}`;
  }
  return digits;
}

function gerarPayloadPixEMV(chave, nome, cidade, valorCentavos, txid = '***', tipoChave = '') {
  if (!chave) return '';
  const chaveNormalizada = normalizarChavePixBacen(chave, tipoChave);
  if (!chaveNormalizada) return '';

  const cleanAscii = (s) => (s || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9 ]/g, '')
    .trim()
    .toUpperCase();

  const formatField = (id, val) => {
    const len = String(val.length).padStart(2, '0');
    return `${id}${len}${val}`;
  };

  const merchantName = cleanAscii(nome).slice(0, 25) || cleanAscii(state.empresa?.nomeFantasia || state.empresa?.razaoSocial).slice(0, 25) || 'FINCORE FOOD';
  const merchantCity = cleanAscii(cidade).slice(0, 15) || cleanAscii(state.empresa?.cidade).slice(0, 15) || 'POUSO ALEGRE';
  const formattedValor = (valorCentavos > 0 ? (valorCentavos / 100).toFixed(2) : '');

  // 00: Payload Format Indicator (Fixed "01")
  // 26: Merchant Account Information (GUI: br.gov.bcb.pix + chave)
  const gui = formatField('00', 'br.gov.bcb.pix');
  const keyField = formatField('01', chaveNormalizada);
  const merchantAccountInfo = formatField('26', `${gui}${keyField}`);

  // Saneamento de TxId (Tag 62 subtag 05) - max 25 chars alfanuméricos sem traços
  let cleanTxid = cleanAscii(String(txid || '')).replace(/\s+/g, '').slice(0, 25);
  if (!cleanTxid || cleanTxid === '***') cleanTxid = '***';

  // ATENÇÃO: Tag 01 com '12' REMOVIDA! No padrão EMVCo do Bacen para QR Code Estático com valor,
  // a Tag 01 '12' é exclusiva para QR dinâmico com API do PSP. Incluir '12' faz apps bancários
  // (Nubank, Itaú, Bradesco, Inter, Mercado Pago) rejeitarem o payload com erro de validação.
  let payload = [
    formatField('00', '01'),
    merchantAccountInfo,
    formatField('52', '0000'),
    formatField('53', '986'),
    formattedValor ? formatField('54', formattedValor) : '',
    formatField('58', 'BR'),
    formatField('59', merchantName),
    formatField('60', merchantCity),
    formatField('62', formatField('05', cleanTxid)),
    '6304'
  ].join('');

  let crc = 0xFFFF;
  for (let i = 0; i < payload.length; i++) {
    crc ^= payload.charCodeAt(i) << 8;
    for (let j = 0; j < 8; j++) {
      if ((crc & 0x8000) !== 0) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  const crcHex = crc.toString(16).toUpperCase().padStart(4, '0');
  return `${payload.slice(0, -4)}6304${crcHex}`;
}

async function copiarParaClipboard(texto, mensagemSucesso = 'Copiado com sucesso!') {
  if (!texto) {
    toast('Nenhum texto disponível para copiar.', 'info');
    return;
  }
  try {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(texto);
    } else {
      const ta = document.createElement('textarea');
      ta.value = texto;
      ta.style.position = 'fixed';
      ta.style.left = '-999999px';
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
    }
    toast(mensagemSucesso, 'success', 2500);
  } catch (err) {
    toast('Erro ao copiar: ' + err.message, 'error');
  }
}

function getPreco(produto, qtyOverride = null) {
  if (!produto) return 0;
  const pId = produto.id;
  const cId = produto.categoria_id;

  const categoryCartQty = getCategoryCartQty(cId);
  const currentInCartForProd = state.cart.find(i => i.produto.id === pId)?.qty || 0;

  const effectiveQty = qtyOverride !== null
    ? (categoryCartQty - currentInCartForProd + qtyOverride)
    : categoryCartQty;

  const qtyToUse = Math.max(1, effectiveQty);

  const tiers = getTiersForProduct(produto);
  if (tiers && tiers.length > 0) {
    const match = tiers.find(t =>
      qtyToUse >= t.qtd_minima && (!t.qtd_maxima || qtyToUse <= t.qtd_maxima)
    );

    if (match) return match.valor_unitario_centavos;

    const lastTier = tiers[tiers.length - 1];
    if (qtyToUse >= lastTier.qtd_minima) return lastTier.valor_unitario_centavos;

    if (tiers[0] && tiers[0].valor_unitario_centavos) {
      return tiers[0].valor_unitario_centavos;
    }
  }

  // Preço base nos metadados ou padrão
  try {
    if (produto.metadata) {
      const m = typeof produto.metadata === 'string' ? JSON.parse(produto.metadata) : produto.metadata;
      if (m.preco_base) return Math.round(parseFloat(m.preco_base) * 100);
    }
  } catch (_) {}

  return 100; // R$ 1,00 por padrão
}

function validateMinimumCategoryQuantities() {
  if (!state.cart || state.cart.length === 0) return { valid: true, errors: [] };

  const catTotals = new Map();
  for (const item of state.cart) {
    const cId = item.produto.categoria_id;
    const cName = item.produto.categoria_nome || 'Categoria';
    const current = catTotals.get(cId) || { name: cName, qty: 0, catId: cId };
    current.qty += item.qty;
    catTotals.set(cId, current);
  }

  const errors = [];
  for (const [cId, cat] of catTotals.entries()) {
    const minRequired = getMinQtyForCategory(cId);
    if (minRequired > 0 && cat.qty < minRequired) {
      errors.push({
        catId: cId,
        categoryName: cat.name,
        categoryQty: cat.qty,
        minRequiredQty: minRequired,
        missingQty: minRequired - cat.qty
      });
    }
  }

  const message = errors.map(err => `A categoria "${err.categoryName}" exige no mínimo ${err.minRequiredQty} un no pedido (atual: ${err.categoryQty} un. Faltam ${err.missingQty} un).`).join('\n');
  return { valid: errors.length === 0, errors, message };
}

// ─── Toasts & Notificações Amigáveis (Zero Erros Técnicos) ───────────
function getFriendlyErrorMessage(rawMsg) {
  if (!rawMsg) return 'Ocorreu um imprevisto. Por favor, tente novamente.';
  const str = String(rawMsg);
  if (str.includes('PGRST116') || str.includes('Results contain 0 rows') || str.includes('not found')) {
    return 'Item ou registro não encontrado.';
  }
  if (str.includes('Failed to fetch') || str.includes('NetworkError') || str.includes('network')) {
    return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
  }
  if (str.includes('JWT') || str.includes('token is expired') || str.includes('unauthorized')) {
    return 'Sua sessão expirou. Faça login novamente para continuar.';
  }
  if (str.includes('violates foreign key constraint') || str.includes('foreign key')) {
    return 'Não foi possível completar a operação com os dados informados.';
  }
  if (str.includes('violates check constraint') || str.includes('check constraint')) {
    return 'Alguns dos dados informados não atendem aos critérios de validação da loja.';
  }
  if (str.includes('Unsupported provider') || str.includes('provider is not enabled')) {
    return 'O login com Google ainda não está ativado no painel da loja. Utilize o login ou cadastro por e-mail e senha abaixo.';
  }
  return str;
}

function toast(msg, type = 'info', duration = 3500) {
  const icons = { success: '✅', error: '❌', info: 'ℹ️' };
  const container = document.getElementById('toast-container');
  if (!container) return;

  const displayMsg = type === 'error' ? getFriendlyErrorMessage(msg) : msg;

  const el = document.createElement('div');
  el.className = `toast toast-${type}`;
  el.innerHTML = `<span>${icons[type] || 'ℹ️'}</span><span>${displayMsg}</span>`;
  container.appendChild(el);

  setTimeout(() => {
    el.classList.add('toast-out');
    el.addEventListener('animationend', () => el.remove());
  }, duration);
}

let _loadingTimeoutId = null;
function showLoading(show, message = 'Carregando cardápio...') {
  const overlay = document.getElementById('loading-overlay');
  const textEl = document.getElementById('loading-text');
  if (textEl) textEl.textContent = message;
  if (overlay) {
    overlay.style.display = show ? 'flex' : 'none';
    // Permite ao usuário clicar no overlay para fechar se travar
    overlay.onclick = () => {
      overlay.style.display = 'none';
    };
  }
  if (_loadingTimeoutId) {
    clearTimeout(_loadingTimeoutId);
    _loadingTimeoutId = null;
  }
  if (show) {
    // Trava de segurança absoluta: fecha automaticamente o loading se demorar mais de 3.5 segundos
    _loadingTimeoutId = setTimeout(() => {
      if (overlay) overlay.style.display = 'none';
    }, 3500);
  }
}

// ─── Gerenciamento de Navegação Unificada ─────────────────────────────
function showScreen(screenId) {
  const isLogged = !!(state.session?.user || (state.profile && state.profile.id));

  // Proteger checkout e áreas de conta com autenticação e cadastro completo
  if (screenId === 'screen-checkout') {
    if (!state.cart || state.cart.length === 0) {
      toast('Seu carrinho está vazio! Adicione itens do cardápio.', 'info');
      screenId = 'screen-cardapio';
    } else if (!isLogged) {
      state.redirectAfterAuth = 'screen-checkout';
      toast('🔐 Para sua segurança, faça login ou cadastre-se para finalizar seu pedido.', 'info', 4500);
      screenId = 'screen-auth';
    } else if (!isProfileComplete(state.profile)) {
      state.redirectAfterAuth = 'screen-checkout';
      prepareGoogleOnboardingUI(state.session?.user);
      toast('📱 Complete seu WhatsApp e endereço de entrega para finalizar seu pedido.', 'info', 5000);
      screenId = 'screen-auth';
    }
  } else if ((screenId === 'screen-account' || screenId === 'screen-orders') && !isLogged) {
    state.redirectAfterAuth = screenId;
    screenId = 'screen-auth';
  }

  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const target = document.getElementById(screenId);
  if (target) {
    target.classList.add('active');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // Marcar body para ocultar a barra de navegação global inferior durante o checkout e confirmação
  document.body.classList.toggle('in-checkout', screenId === 'screen-checkout');
  document.body.classList.toggle('in-confirmation', screenId === 'screen-confirmation');

  // Atualizar botões da barra superior desktop
  document.querySelectorAll('.desktop-nav-link').forEach(link => {
    const isAct = link.dataset.target === screenId;
    link.classList.toggle('active', isAct);
  });

  // Atualizar botões da barra inferior mobile
  document.querySelectorAll('.bnav-item').forEach(item => {
    const isAct = item.dataset.target === screenId;
    item.classList.toggle('active', isAct);
  });

  // Atualizar Drawer se aberto
  closeDrawer();

  // Execuções específicas de tela
  if (screenId === 'screen-home') {
    renderHome();
  } else if (screenId === 'screen-cardapio') {
    renderProductsGrid();
  } else if (screenId === 'screen-checkout') {
    renderCheckoutPage();
  } else if (screenId === 'screen-orders') {
    loadCustomerOrders();
  } else if (screenId === 'screen-account') {
    populateAccountForm();
  } else if (screenId === 'screen-auth') {
    renderAuthScreen();
  } else if (screenId === 'screen-expresso') {
    renderExpressoScreen();
  }

  updateCartBar();
}

function renderAuthScreen() {
  const notice = document.getElementById('checkout-auth-notice');
  const noticeSub = document.getElementById('checkout-auth-notice-sub');
  const mainTitle = document.getElementById('auth-main-title');
  const subtitle = document.getElementById('auth-subtitle');
  const backBtn = document.getElementById('auth-back-to-cart-btn');

  if (state.redirectAfterAuth === 'screen-checkout' && state.cart && state.cart.length > 0) {
    const count = cartCount();
    const totalStr = fmt(cartTotal());
    if (notice) {
      notice.style.display = 'flex';
      if (noticeSub) {
        noticeSub.textContent = `Seu carrinho possui ${count} ${count === 1 ? 'item' : 'itens'} (${totalStr}). Faça login ou crie sua conta para informar o endereço e concluir o pedido!`;
      }
    }
    if (mainTitle) mainTitle.textContent = 'Finalize seu Pedido';
    if (subtitle) subtitle.textContent = 'Faça login ou crie sua conta para continuar para o checkout.';
    if (backBtn) backBtn.style.display = 'inline-flex';
  } else {
    if (notice) notice.style.display = 'none';
    if (mainTitle) mainTitle.textContent = 'Bem-vindo!';
    if (subtitle) subtitle.textContent = 'Entre ou crie sua conta para acessar o cardápio e fazer seus pedidos.';
    if (backBtn) backBtn.style.display = 'none';
  }
}

// ─── Gerenciamento do Carrinho ───────────────────────────────────────
function cartTotal() {
  return state.cart.reduce((sum, item) => sum + getPreco(item.produto, item.qty) * item.qty, 0);
}

function cartCount() {
  return state.cart.reduce((sum, item) => sum + item.qty, 0);
}

function addToCart(produto, qty) {
  const parsedQty = Math.max(1, parseInt(qty, 10) || 1);
  const existing = state.cart.find(i => i.produto.id === produto.id);
  if (existing) {
    existing.qty += parsedQty;
  } else {
    state.cart.push({ produto, qty: parsedQty });
  }
  saveCart();
  updateCartBar();
  renderProductsGrid();
  toast(`${parsedQty}x ${produto.nome} adicionado! 🛒`, 'success', 2000);
}

function removeFromCart(produtoId) {
  state.cart = state.cart.filter(i => i.produto.id !== produtoId);
  saveCart();
  updateCartBar();
  renderProductsGrid();
  renderCheckoutPage();
}

function changeCartQty(produtoId, delta) {
  const item = state.cart.find(i => i.produto.id === produtoId);
  if (!item) return;
  item.qty = Math.max(0, item.qty + delta);
  if (item.qty === 0) {
    removeFromCart(produtoId);
  } else {
    saveCart();
    updateCartBar();
    renderProductsGrid();
    renderCheckoutPage();
  }
}

function getCartQtyFor(produtoId) {
  return state.cart
    .filter(i => i.produto.id === produtoId)
    .reduce((s, i) => s + i.qty, 0);
}

function saveCart() {
  localStorage.setItem('fincore_cart', JSON.stringify(state.cart));
}

function loadCart() {
  try {
    const saved = localStorage.getItem('fincore_cart');
    if (saved) state.cart = JSON.parse(saved);
  } catch { state.cart = []; }
}

function clearCart() {
  state.cart = [];
  saveCart();
  updateCartBar();
  renderProductsGrid();
  renderCheckoutPage();
}

function updateCartBar() {
  const n = cartCount();
  const total = cartTotal();
  const totalStr = fmt(total);

  // Header Badge (Desktop & Mobile)
  const headerCartBtn = document.getElementById('header-cart-btn');
  const headerCount   = document.getElementById('header-cart-count');
  const headerTotal   = document.getElementById('header-cart-total');

  if (headerCount) headerCount.textContent = n;
  if (headerTotal) headerTotal.textContent = totalStr;
  if (headerCartBtn) {
    if (n > 0) headerCartBtn.classList.add('has-items');
    else headerCartBtn.classList.remove('has-items');
  }

  // Floating Bottom Cart Bar (Mobile & Desktop)
  const bottomBar   = document.getElementById('bottom-cart-bar');
  const bottomCount = document.getElementById('bottom-cart-count');
  const bottomTotal = document.getElementById('bottom-cart-total');

  if (bottomBar) {
    const currentScreen = document.querySelector('.screen.active')?.id;
    // Não exibir a floating bar na própria tela de checkout ou confirmação
    if (n > 0 && currentScreen !== 'screen-checkout' && currentScreen !== 'screen-confirmation' && currentScreen !== 'screen-auth') {
      bottomBar.style.display = 'block';
      if (bottomCount) bottomCount.textContent = n;
      if (bottomTotal) bottomTotal.textContent = totalStr;
    } else {
      bottomBar.style.display = 'none';
    }
  }
}

// ─── Carregamento de Dados do Estabelecimento ────────────────────────
function getTenantFromUrl() {
  const params = new URLSearchParams(window.location.search);
  const urlTenant = 
    params.get('tenant_id') ||
    params.get('tenant') ||
    params.get('empresa') ||
    params.get('loja') ||
    params.get('slug') ||
    params.get('t');

  if (urlTenant && urlTenant.trim().length > 0) {
    localStorage.setItem('fincore_cardapio_tenant', urlTenant.trim());
    return urlTenant.trim();
  }
  const cached = localStorage.getItem('fincore_cardapio_tenant');
  if (cached && cached.trim().length > 0) {
    return cached.trim();
  }
  return null;
}

async function loadEmpresa() {
  try {
    const requestedTenant = getTenantFromUrl();
    let tenantId = requestedTenant;

    // Se o identificador não for um UUID padrão, tenta buscar por slug ou nome da empresa
    if (requestedTenant && !/^[0-9a-fA-F-]{36}$/.test(requestedTenant)) {
      try {
        const { data: empBySlug } = await sb
          .from('empresa')
          .select('id')
          .or(`slug.eq.${requestedTenant},nomeFantasia.ilike.%${requestedTenant}%,razaoSocial.ilike.%${requestedTenant}%`)
          .maybeSingle();

        if (empBySlug && empBySlug.id) {
          tenantId = empBySlug.id;
        }
      } catch (_) {}
    }

    let query = sb.from('vw_cardapio_empresa').select('*');

    if (tenantId) {
      query = query.eq('tenant_id', tenantId);
    }

    let { data, error } = await query.maybeSingle();
    if (error || !data) {
      // Fallback: se o tenant especificado não for encontrado ou não fornecido, busca a primeira empresa ativa
      const { data: fallbackEmp } = await sb.from('vw_cardapio_empresa').select('*').limit(1).maybeSingle();
      if (fallbackEmp) {
        data = fallbackEmp;
        tenantId = fallbackEmp.tenant_id;
        localStorage.setItem('fincore_cardapio_tenant', tenantId);
      } else {
        return;
      }
    }

    state.empresa  = data;
    state.tenantId = data.tenant_id;
    localStorage.setItem('fincore_cardapio_tenant', state.tenantId);

    // Carregar configurações de Pix, banco, endereço estendido e regras de taxa de entrega
    try {
      const [{ data: empData }, { data: configData }, { data: fpList }, { data: taxasData }] = await Promise.all([
        sb.from('empresa').select('*').eq('id', state.tenantId).maybeSingle(),
        sb.from('empresa_configuracao').select('*').eq('tenantId', state.tenantId).maybeSingle(),
        sb.from('forma_pagamento').select('*').eq('tenantId', state.tenantId).eq('ativo', true).is('deletedAt', null).order('ordem', { ascending: true }),
        sb.from('taxa_entrega').select('*').eq('tenantId', state.tenantId).eq('ativo', true).is('deletedAt', null)
      ]);

      state.taxasEntrega = taxasData || [];
      state.formasPagamento = (fpList || []).filter(fp => {
        if (!fp || !fp.ativo) return false;
        const t = String(fp.tipo || '').toLowerCase();
        const n = String(fp.nome || '').toLowerCase();
        // Não permitir consumo interno nem faturamento a prazo / nota a prazo no cardápio online
        if (t === 'consumointerno' || t.includes('interno')) return false;
        if (t === 'notaprazo' || t.includes('prazo') || n.includes('prazo') || n.includes('fiado')) return false;
        return true;
      });

      if (state.formasPagamento.length === 0) {
        state.formasPagamento = [
          { id: 'default-pix', nome: 'Pix Instantâneo', tipo: 'pix', permiteTroco: false },
          { id: 'default-dinheiro', nome: 'Dinheiro', tipo: 'DINHEIRO', permiteTroco: true },
          { id: 'default-credito', nome: 'Cartão de Crédito', tipo: 'cartaoCredito', permiteTroco: false },
          { id: 'default-debito', nome: 'Cartão de Débito', tipo: 'cartaoDebito', permiteTroco: false }
        ];
      }

      if (empData) {
        state.empresa = { ...data, ...empData };
        if (empData.telefone) {
          state.empresa.whatsapp = empData.telefone;
          state.empresa.telefone = empData.telefone;
        }
      }
      if (configData) {
        state.empresaConfig = configData;
        let pKey = null;
        let pFav = configData.pixFavorecido || null;
        let pBanco = configData.pixBanco || null;
        let pTipo = configData.pixTipo || null;

        if (configData.pixKey) {
          try {
            const parsed = typeof configData.pixKey === 'string' ? JSON.parse(configData.pixKey) : configData.pixKey;
            if (Array.isArray(parsed) && parsed.length > 0) {
              const principal = parsed.find(k => k.isPrincipal) || parsed[0];
              pKey = principal.chave;
              if (principal.favorecido) pFav = principal.favorecido;
              if (principal.banco) pBanco = principal.banco;
              if (principal.tipo) pTipo = principal.tipo;
            } else if (typeof parsed === 'string') {
              pKey = parsed;
            }
          } catch (_) {
            pKey = configData.pixKey;
          }
        }

        if (pKey) state.empresa.chave_pix = pKey;
        if (pFav) state.empresa.pix_favorecido = pFav;
        if (pBanco) state.empresa.pix_banco = pBanco;
        if (pTipo) state.empresa.pix_tipo = pTipo;
      }

      // Fallback em forma_pagamento se não veio de empresa_configuracao
      const pixFp = state.formasPagamento.find(fp => String(fp.tipo || '').toLowerCase().includes('pix') || String(fp.nome || '').toLowerCase().includes('pix'));
      if (pixFp) {
        if (!state.empresa.chave_pix && pixFp.pixChave) state.empresa.chave_pix = pixFp.pixChave;
        if (!state.empresa.pix_banco && pixFp.pixTipoBanco) state.empresa.pix_banco = pixFp.pixTipoBanco;
        if (!state.empresa.pix_tipo && pixFp.pixTipoChave) state.empresa.pix_tipo = pixFp.pixTipoChave;
        if (pixFp.descricao) {
          const matchFav = pixFp.descricao.match(/\[Favorecido:\s*([^\]]+)\]/i);
          if (matchFav && matchFav[1] && !state.empresa.pix_favorecido) state.empresa.pix_favorecido = matchFav[1].trim();
          const matchCid = pixFp.descricao.match(/\[Cidade:\s*([^\]]+)\]/i);
          if (matchCid && matchCid[1] && !state.empresa.cidade) state.empresa.cidade = matchCid[1].trim();
        }
      }

      if (!state.empresa.pix_favorecido) {
        state.empresa.pix_favorecido = state.empresa.nomeFantasia || state.empresa.nome_fantasia || state.empresa.razaoSocial || 'FinCore Food';
      }
      if (!state.empresa.pix_banco) {
        state.empresa.pix_banco = 'Conta Digital';
      }
      if (!state.empresa.pix_tipo) {
        state.empresa.pix_tipo = 'Chave Pix';
      }

      // Atualiza dinamicamente título da página e meta tags OpenGraph para WhatsApp Card
      const nomeLoja = state.empresa.nomeFantasia || state.empresa.nome_fantasia || state.empresa.razaoSocial || 'Cardápio & Encomendas Online';
      document.title = `${nomeLoja} — Cardápio Digital`;
      const ogTitle = document.querySelector('meta[property="og:title"]');
      if (ogTitle) ogTitle.setAttribute('content', `🍽️ ${nomeLoja} — Cardápio & Encomendas`);
      const ogDesc = document.querySelector('meta[property="og:description"]');
      if (ogDesc) ogDesc.setAttribute('content', `Acesse o cardápio oficial da ${nomeLoja}. Faça seu pedido e acompanhe a entrega em tempo real!`);

      renderPaymentMethods();

      // Parse horários de atendimento & regras de pedido
      state.horariosAtendimento = {
        status: 'auto',
        prazoMinimoMinutos: 120,
        mensagemFechado: 'Estamos fora do horário de atendimento. Faça seu pedido agendado!',
        dias: {
          dom: { ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Domingo' },
          seg: { ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Segunda-feira' },
          ter: { ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Terça-feira' },
          qua: { ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Quarta-feira' },
          qui: { ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Quinta-feira' },
          sex: { ativo: true, abertura: '08:00', fechamento: '23:00', nome: 'Sexta-feira' },
          sab: { ativo: true, abertura: '08:00', fechamento: '23:00', nome: 'Sábado' }
        },
        bloqueios: []
      };

      const rawHorarios = configData?.horariosAtendimento || configData?.horarios_atendimento;
      if (rawHorarios) {
        try {
          const parsedH = typeof rawHorarios === 'string'
            ? JSON.parse(rawHorarios)
            : rawHorarios;
          if (parsedH.status) state.horariosAtendimento.status = parsedH.status;
          if (parsedH.prazoMinimoMinutos != null) state.horariosAtendimento.prazoMinimoMinutos = Number(parsedH.prazoMinimoMinutos);
          if (parsedH.mensagemFechado) state.horariosAtendimento.mensagemFechado = parsedH.mensagemFechado;
          if (parsedH.dias) {
            Object.keys(parsedH.dias).forEach(k => {
              if (state.horariosAtendimento.dias[k]) {
                state.horariosAtendimento.dias[k] = {
                  ...state.horariosAtendimento.dias[k],
                  ...parsedH.dias[k]
                };
              }
            });
          }
          if (Array.isArray(parsedH.bloqueios)) {
            state.horariosAtendimento.bloqueios = parsedH.bloqueios;
          }
          if (parsedH.modoExpresso) {
            state.horariosAtendimento.modoExpresso = parsedH.modoExpresso;
            state.expressoConfig = {
              ativo: parsedH.modoExpresso.ativo !== false,
              estoqueMinimo: Number(parsedH.modoExpresso.estoqueMinimo ?? 1),
              titulo: parsedH.modoExpresso.titulo || 'Disponíveis para Envio Imediato'
            };
          }
        } catch (e) {
          console.warn('Erro ao parsear horariosAtendimento:', e);
        }
      }

      updateStoreStatusUI();
    } catch (_) {}

    // ─── Identidade da Empresa (100% dados reais, sem fallbacks de marketing) ───
    // Logo: lida de configData.logoUrl (campo canônico) ou de metadata_payload
    let meta = {};
    try {
      meta = state.empresa.metadata_payload
        ? (typeof state.empresa.metadata_payload === 'string'
            ? JSON.parse(state.empresa.metadata_payload)
            : state.empresa.metadata_payload)
        : {};
    } catch {}

    const nome = state.empresa.nomeFantasia || state.empresa.nome_fantasia || state.empresa.razaoSocial || '';
    // REGRA: tagline/slogan somente se existir em dados reais da empresa. NUNCA fallback hardcoded.
    const tagline = meta.descricao || meta.tagline || meta.slogan || state.empresa.descricao || null;

    // SEO e Títulos
    if (nome) {
      document.title = `${nome} — Cardápio Online`;
      const pageTitleEl = document.getElementById('page-title');
      if (pageTitleEl) pageTitleEl.textContent = nome;

      const headerStoreName = document.getElementById('header-store-name');
      if (headerStoreName) headerStoreName.textContent = nome;

      const homeInfoStoreName = document.getElementById('home-info-store-name');
      if (homeInfoStoreName) homeInfoStoreName.textContent = nome;
    }

    // Tagline: exibe somente se existir nos dados reais. Oculta o elemento se não existir.
    const homeStoreTagline = document.getElementById('home-store-tagline');
    if (homeStoreTagline) {
      if (tagline && tagline.trim()) {
        homeStoreTagline.textContent = tagline.trim();
        homeStoreTagline.style.display = '';
      } else {
        homeStoreTagline.textContent = '';
        homeStoreTagline.style.display = 'none';
      }
    }

    // Logo: prioridade → configData.logoUrl → meta.logo_url → meta.logo → empresa.logoUrl
    const logoUrl = (state.empresaConfig?.logoUrl) || 
                    (state.empresaConfig?.logo_url) || 
                    meta.logo_url || 
                    meta.logo || 
                    state.empresa?.logoUrl || 
                    state.empresa?.logo_url || 
                    state.empresa?.logo || 
                    null;
    const headerLogoImg = document.getElementById('header-logo-img');
    const homeStoreAvatar = document.getElementById('home-store-avatar');

    if (logoUrl && (logoUrl.startsWith('http') || logoUrl.startsWith('/') || logoUrl.startsWith('data:image'))) {
      const imgTag = `<img src="${logoUrl}" alt="${nome}" style="width:100%;height:100%;object-fit:contain;border-radius:inherit;" />`;
      if (headerLogoImg) headerLogoImg.innerHTML = imgTag;
      if (homeStoreAvatar) homeStoreAvatar.innerHTML = imgTag;
    }
    // Se não tiver logo: mantém o fallback visual já existente no HTML (inicial do nome ou ícone)

    // Telefone / WhatsApp
    const phone = state.empresa.whatsapp || state.empresa.telefone;
    const phoneClean = getEmpresaWhatsAppClean();
    const homeInfoPhoneItem = document.getElementById('home-info-phone-item');
    const homeInfoPhone = document.getElementById('home-info-phone');
    if (homeInfoPhone) {
      if (phone && phoneClean) {
        homeInfoPhone.innerHTML = `<a href="https://wa.me/${phoneClean}" target="_blank" rel="noopener noreferrer" style="color:inherit;text-decoration:none;font-weight:600;">WhatsApp: ${formatPhone(phone)} ↗</a>`;
        if (homeInfoPhoneItem) homeInfoPhoneItem.style.display = '';
        homeInfoPhone.style.display = '';
      } else {
        if (homeInfoPhoneItem) homeInfoPhoneItem.style.display = 'none';
        homeInfoPhone.style.display = 'none';
      }
    }
  } catch (e) {
    console.warn('Erro ao carregar dados da empresa:', e.message);
  }
}

// ─── Carregamento de Produtos, Categorias e Estoque Real ────────────
async function loadCatalog() {
  try {
    let query = sb.from('vw_cardapio_produtos').select('*');
    let pQuery = sb.from('vw_cardapio_precificacao').select('*');
    let eQuery = sb.from('estoque_produto').select('produtoId, quantidadeAtual, quantidadeReservada, quantidadeCritica').is('deletedAt', null);

    if (state.tenantId) {
      query = query.eq('tenant_id', state.tenantId);
      pQuery = pQuery.eq('tenant_id', state.tenantId);
      eQuery = eQuery.eq('tenantId', state.tenantId);
    }

    const [{ data: prods, error }, { data: precData }, { data: estoqueData }] = await Promise.all([
      query,
      pQuery,
      eQuery
    ]);

    if (error) throw error;
    state.produtos     = prods || [];
    state.precificacao = precData || [];

    // Mapeia estoque real para os produtos
    const estoqueMap = new Map();
    if (estoqueData && Array.isArray(estoqueData)) {
      for (const est of estoqueData) {
        estoqueMap.set(est.produtoId, est);
      }
    }
    for (const p of state.produtos) {
      p.estoqueInfo = estoqueMap.get(p.id) || null;
    }

    // Montar categorias únicas
    const catMap = new Map();
    for (const p of state.produtos) {
      if (!catMap.has(p.categoria_id)) {
        catMap.set(p.categoria_id, {
          id:     p.categoria_id,
          nome:   sanitizeCategoryName(p.categoria_nome),
          icone:  getCategoryIcon(p.categoria_icone, p.categoria_nome),
          ordem:  p.categoria_ordem || 0,
        });
      }
    }
    state.categorias = [...catMap.values()].sort((a, b) => a.ordem - b.ordem);

    renderCategoriesBar();
    renderHome();
    renderProductsGrid();
    setupExpressoVitrine();
  } catch (e) {
    toast('Erro ao carregar cardápio: ' + e.message, 'error');
    console.error(e);
  }
}

// ─── Disponibilidade Real do Produto no Estoque ──────────────────────
function getProductAvailability(prod) {
  if (!prod || prod.ativo === false || prod.status_comercial === 'indisponivel') {
    return {
      status: 'indisponivel',
      label: 'Indisponível no momento',
      badgeClass: 'avail-out',
      dot: '🔴',
      showBadge: true,
      canAdd: false,
      qty: 0
    };
  }

  if (prod.estoqueInfo) {
    const atual = Number(prod.estoqueInfo.quantidadeAtual || 0);
    const reservado = Number(prod.estoqueInfo.quantidadeReservada || 0);
    const disponivel = atual - reservado;
    const critico = Number(prod.estoqueInfo.quantidadeCritica || 20);

    if (disponivel <= 0) {
      return {
        status: 'indisponivel',
        label: 'Indisponível no momento',
        badgeClass: 'avail-out',
        dot: '🔴',
        showBadge: true,
        canAdd: false,
        qty: 0
      };
    }

    if (disponivel <= critico) {
      return {
        status: 'poucas_unidades',
        label: `Poucas unidades (${disponivel} un)`,
        badgeClass: 'avail-low',
        dot: '🟡',
        showBadge: true,
        canAdd: true,
        qty: disponivel
      };
    }

    return {
      status: 'disponivel',
      label: 'Disponível',
      badgeClass: 'avail-ok',
      dot: '🟢',
      showBadge: true,
      canAdd: true,
      qty: disponivel
    };
  }

  // Itens sem registro de estoque são feitos sob encomenda/demanda da cozinha.
  // canAdd é permitido, mas não exibimos o selo '🟢 Disponível' para não sugerir falsa pronta entrega de balcão.
  return {
    status: 'sob_demanda',
    label: '',
    badgeClass: '',
    dot: '',
    showBadge: false,
    canAdd: true,
    qty: 999
  };
}

// ─── Renderização da Barra de Categorias (Tela Cardápio) ──────────────
function renderCategoriesBar() {
  const select = document.getElementById('category-select');
  const navList = document.getElementById('categories-nav-list');
  const chipAllCount = document.getElementById('chip-count-all');
  const totalCount = state.produtos.length;
  if (chipAllCount) chipAllCount.textContent = totalCount;

  let selectHtml = `<option value="all">🍽️ Todas as Categorias (${totalCount} itens)</option>`;
  let navHtml = `
    <button type="button" class="category-chip ${state.currentCat === 'all' ? 'active' : ''}" data-cat-id="all" role="tab" aria-selected="${state.currentCat === 'all'}">
      <span class="cat-chip-icon">🍽️</span>
      <span class="cat-chip-name">Todos</span>
      <span class="cat-chip-count">${totalCount}</span>
    </button>
  `;

  for (const cat of state.categorias) {
    const emoji = getCategoryIcon(cat.icone, cat.nome);
    const count = state.produtos.filter(p => p.categoria_id === cat.id).length;
    const isAct = state.currentCat === cat.id;

    selectHtml += `<option value="${cat.id}" ${isAct ? 'selected' : ''}>${emoji} ${cat.nome} (${count})</option>`;
    navHtml += `
      <button type="button" class="category-chip ${isAct ? 'active' : ''}" data-cat-id="${cat.id}" role="tab" aria-selected="${isAct}">
        <span class="cat-chip-icon">${emoji}</span>
        <span class="cat-chip-name">${cat.nome}</span>
        <span class="cat-chip-count">${count}</span>
      </button>
    `;
  }

  if (select) select.innerHTML = selectHtml;
  if (navList) {
    navList.innerHTML = navHtml;
    navList.querySelectorAll('.category-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        selectCategory(chip.dataset.catId);
        chip.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
      });
    });
  }
}

function selectCategory(catId) {
  state.currentCat = catId;
  const select = document.getElementById('category-select');
  if (select) select.value = catId;

  const navList = document.getElementById('categories-nav-list');
  if (navList) {
    navList.querySelectorAll('.category-chip').forEach(c => {
      const match = c.dataset.catId === catId;
      c.classList.toggle('active', match);
      c.setAttribute('aria-selected', match ? 'true' : 'false');
    });
  }
  renderProductsGrid();
}

// ─── TELA 1: HOME / EXPERIÊNCIA DE PEDIDOS ONLINE ─────────────────────
async function renderHome() {
  // 1. Saudação personalizada ao cliente identificado (sem duplicar nome/marca da loja)
  const welcomeBadge  = document.getElementById('home-welcome-badge');
  const greetingTitle = document.getElementById('home-greeting-name');
  const storeAvatar   = document.getElementById('home-store-avatar');

  if (state.profile?.nome) {
    const firstName = state.profile.nome.trim().split(' ')[0];
    if (welcomeBadge) welcomeBadge.textContent = 'Bem-vindo de volta';
    if (greetingTitle) greetingTitle.textContent = `Olá, ${firstName}! O que vamos pedir hoje?`;
    if (storeAvatar) {
      storeAvatar.textContent = firstName[0].toUpperCase();
      storeAvatar.style.background = 'linear-gradient(135deg, var(--brand-500), #ea580c)';
    }
  } else {
    if (welcomeBadge) welcomeBadge.textContent = 'Bem-vindo';
    if (greetingTitle) greetingTitle.textContent = 'Olá! O que vamos pedir hoje?';
    if (storeAvatar) {
      storeAvatar.textContent = '🍽️';
      storeAvatar.style.background = '';
    }
  }

  updateStoreStatusUI();

  // 2. Categorias Horizontais em Carrossel (Navegação visual imediata)
  renderHomeCategories();

  // 3. Pedido em Andamento (Máxima prioridade visual — se existir)
  await renderActiveOrderWidget();

  // 4. Configuração dos Atalhos de Escolha Rápida e Super Busca
  setupHomeIntentShortcuts();

  // 5. Compre Novamente (se houver histórico de pedidos concluídos)
  renderHomeReorderSection();

  // 6. Próximas Encomendas Agendadas Futuras (se houver)
  renderHomeScheduledOrders();

  // 7. Produtos em Destaque do Cardápio
  renderHomeFeaturedProducts();

  // 7.1 Destaque Compacto de Festas & Eventos (com fotos reais do cardápio)
  updatePartyBannerVisual();

  // 8. Tabela de Preços por Quantidade (Lote)
  renderHomePricingTiersSection();
}

function renderHomeScheduledOrders() {
  const container = document.getElementById('home-scheduled-orders-container');
  const grid = document.getElementById('home-scheduled-orders-grid');
  if (!container || !grid) return;

  if (!state.session && !state.profile) {
    container.style.display = 'none';
    return;
  }

  const now = new Date();
  const scheduledOrders = state.customerOrders.filter(o => {
    const st = String(o.status || '').toLowerCase().trim();
    if (st === 'cancelado' || st === 'entregue' || st === 'concluido' || st === 'finalizado') return false;
    if (!o.dataHoraEntregaPrevista) return false;
    return new Date(o.dataHoraEntregaPrevista) > now;
  });

  if (scheduledOrders.length === 0) {
    container.style.display = 'none';
    return;
  }

  container.style.display = 'flex';
  grid.innerHTML = scheduledOrders.slice(0, 3).map(o => {
    const num = o.numeroPedido || o.id.slice(0, 6);
    const dateStr = fmtDateTime(o.dataHoraEntregaPrevista);
    const items = o.item_pedido || [];
    const itemsSummary = items.map(i => `${i.quantidade}x ${i.nomeProduto}`).join(', ') || 'Itens diversos';
    const statusInfo = KANBAN_STATUS_MAP[o.status] || { label: o.status, icon: '📋' };

    return `
      <div class="scheduled-order-card">
        <div class="soc-top">
          <span class="soc-num">Pedido #${num}</span>
          <span class="order-status-pill status-${o.status}">${statusInfo.label}</span>
        </div>
        <div class="soc-datetime">
          <span>📅</span>
          <span>${dateStr}</span>
        </div>
        <div class="soc-info">
          <div>🚚 <strong>${o.tipoLogistica || 'Entrega'}</strong></div>
          <div style="margin-top:4px;color:var(--text-muted);font-size:12px">🛒 ${itemsSummary}</div>
        </div>
        <div class="soc-footer">
          <span class="soc-total">${fmt(o.valorTotalCentavos)}</span>
          <button type="button" class="btn btn-secondary btn-sm btn-view-scheduled" data-id="${o.id}">
            Ver Detalhes
          </button>
        </div>
      </div>
    `;
  }).join('');

  grid.querySelectorAll('.btn-view-scheduled').forEach(b => {
    b.addEventListener('click', () => {
      const ord = scheduledOrders.find(o => o.id === b.dataset.id);
      if (ord) openOrderDetailModal(ord);
    });
  });
}

function calculateDiscountPercent(basePrice, tierPrice) {
  if (!basePrice || basePrice <= 0 || !tierPrice || tierPrice >= basePrice) return 0;
  return Math.round(((basePrice - tierPrice) / basePrice) * 100);
}

function renderHomePricingTiersSection() {
  const container = document.getElementById('home-pricing-tiers-section');
  const box = document.getElementById('home-pricing-tiers-box');
  if (!container || !box) return;

  if (!state.precificacao || state.precificacao.length === 0) {
    container.style.display = 'none';
    return;
  }

  const uniqueTiers = [];
  const seen = new Set();

  for (const t of state.precificacao) {
    const key = `${t.qtd_minima}_${t.qtd_maxima || ''}_${t.valor_unitario_centavos}`;
    if (!seen.has(key)) {
      seen.add(key);
      uniqueTiers.push(t);
    }
  }

  if (uniqueTiers.length <= 1) {
    container.style.display = 'none';
    return;
  }

  uniqueTiers.sort((a, b) => a.qtd_minima - b.qtd_minima);
  container.style.display = 'flex';

  const baseTierPrice = uniqueTiers[0].valor_unitario_centavos;

  const cardsHtml = uniqueTiers.map((t, idx) => {
    const rangeText = t.qtd_maxima ? `${t.qtd_minima} a ${t.qtd_maxima} un` : `A partir de ${t.qtd_minima} un`;
    const isBest = idx === uniqueTiers.length - 1;
    const discountPct = calculateDiscountPercent(baseTierPrice, t.valor_unitario_centavos);
    
    let tagHtml = '';
    if (discountPct > 0) {
      tagHtml = `<span class="ptsc-tag">${isBest ? '⭐ ' : ''}${discountPct}% OFF</span>`;
    } else if (idx === 0) {
      tagHtml = `<span class="ptsc-tag ptsc-tag-base">Preço Base</span>`;
    }

    return `
      <div class="pricing-tier-summary-card ${isBest ? 'highlight' : ''}">
        <span class="ptsc-range">${rangeText}</span>
        <span class="ptsc-price">${fmt(t.valor_unitario_centavos)}<small style="font-size:12px;font-weight:600;color:var(--text-muted)">/un</small></span>
        ${tagHtml}
      </div>
    `;
  }).join('');

  box.innerHTML = `
    <div class="pricing-tiers-cards-grid">
      ${cardsHtml}
    </div>
    <div class="pricing-tiers-note">
      💡 Os descontos progressivos por quantidade são calculados automaticamente e aplicados diretamente no seu carrinho.
    </div>
  `;
}

// ─── Carrossel Horizontal de Categorias (Home) ───────────────────────
function renderHomeCategories() {
  const container = document.getElementById('home-categories-carousel');
  if (!container) return;

  if (state.categorias.length === 0) {
    container.innerHTML = `<span style="color: var(--text-muted); font-size:13px;">Carregando categorias...</span>`;
    return;
  }

  // Primeiro chip: 🍽️ Todos
  let html = `
    <button type="button" class="home-cat-chip ${state.currentCat === 'all' ? 'active' : ''}" data-cat-id="all">
      <span class="home-cat-chip-icon">🍽️</span>
      <span class="home-cat-chip-name">Todos</span>
      <span class="home-cat-chip-count">${state.produtos.length}</span>
    </button>
  `;

  for (const cat of state.categorias) {
    const emoji = getCategoryIcon(cat.icone, cat.nome);
    const count = state.produtos.filter(p => p.categoria_id === cat.id).length;
    const isAct = state.currentCat === cat.id;

    html += `
      <button type="button" class="home-cat-chip ${isAct ? 'active' : ''}" data-cat-id="${cat.id}">
        <span class="home-cat-chip-icon">${emoji}</span>
        <span class="home-cat-chip-name">${cat.nome}</span>
        <span class="home-cat-chip-count">${count}</span>
      </button>
    `;
  }

  container.innerHTML = html;

  container.querySelectorAll('.home-cat-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      const catId = chip.dataset.catId;
      selectCategory(catId);
      if (catId === 'all') {
        document.getElementById('home-featured-section')?.scrollIntoView({ behavior: 'smooth' });
      } else {
        showScreen('screen-cardapio');
      }
    });
  });
}

// ─── Configuração de Atalhos de Escolha Rápida & Super Busca ───────────
function setupHomeIntentShortcuts() {
  // 1. Quero alguns salgados -> vai para o cardápio
  const btnSalgados = document.getElementById('shortcut-salgados');
  if (btnSalgados && !btnSalgados.dataset.bound) {
    btnSalgados.dataset.bound = 'true';
    btnSalgados.addEventListener('click', () => {
      selectCategory('all');
      showScreen('screen-cardapio');
    });
  }

  // 2. Tenho uma festa -> navega até o banner de encomendas
  const btnFesta = document.getElementById('shortcut-festa');
  if (btnFesta && !btnFesta.dataset.bound) {
    btnFesta.dataset.bound = 'true';
    btnFesta.addEventListener('click', () => {
      const banner = document.getElementById('home-party-orders-banner');
      if (banner) banner.scrollIntoView({ behavior: 'smooth' });
      else showScreen('screen-cardapio');
    });
  }

  // 3. Quero pedir igual -> repete o último pedido concluído com validação
  const btnRepetir = document.getElementById('shortcut-repetir');
  if (btnRepetir && !btnRepetir.dataset.bound) {
    btnRepetir.dataset.bound = 'true';
    btnRepetir.addEventListener('click', () => {
      const completedOrders = state.customerOrders.filter(o => {
        const st = String(o.status || '').toLowerCase().trim();
        return st === 'concluido' || st === 'entregue' || st === 'finalizado';
      });
      if (completedOrders.length > 0) {
        reorderOrder(completedOrders[0].id);
      } else {
        toast('Você ainda não possui pedidos anteriores registrados para repetir.', 'info');
        showScreen('screen-cardapio');
      }
    });
  }

  // 4. Ver meus pedidos -> vai para a tela de pedidos
  const btnPedidos = document.getElementById('shortcut-pedidos');
  if (btnPedidos && !btnPedidos.dataset.bound) {
    btnPedidos.dataset.bound = 'true';
    btnPedidos.addEventListener('click', () => {
      showScreen('screen-orders');
      loadCustomerOrders();
    });
  }

  // Super Barra de Busca da Home
  const homeInput = document.getElementById('home-search-input');
  const homeBtn   = document.getElementById('home-search-btn');
  const homeClear = document.getElementById('home-search-clear-btn');

  function executeHomeSearch() {
    const term = (homeInput?.value || '').trim();
    if (!term) return;

    state.searchTerm = term;
    const catSearchInput = document.getElementById('product-search-input');
    if (catSearchInput) catSearchInput.value = term;

    showScreen('screen-cardapio');
    renderProductsGrid();
  }

  if (homeBtn && !homeBtn.dataset.bound) {
    homeBtn.dataset.bound = 'true';
    homeBtn.addEventListener('click', executeHomeSearch);
  }
  if (homeInput && !homeInput.dataset.bound) {
    homeInput.dataset.bound = 'true';
    homeInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        executeHomeSearch();
      }
    });
    homeInput.addEventListener('input', () => {
      if (homeClear) homeClear.style.display = homeInput.value ? 'block' : 'none';
    });
  }
  if (homeClear && !homeClear.dataset.bound) {
    homeClear.dataset.bound = 'true';
    homeClear.addEventListener('click', () => {
      if (homeInput) homeInput.value = '';
      if (homeClear) homeClear.style.display = 'none';
      state.searchTerm = '';
    });
  }
}

// ─── Pedido em Andamento com Stepper Kanban Real de 5 Etapas ──────────
const KANBAN_STATUS_MAP = {
  pendente:            { label: 'Aguardando Confirmação', icon: '⏳' },
  aguardando_aprovacao:{ label: 'Aguardando Confirmação', icon: '⏳' },
  recebido:            { label: 'Confirmado pela Loja',   icon: '✅' },
  confirmado:          { label: 'Confirmado pela Loja',   icon: '✅' },
  aprovado:            { label: 'Confirmado pela Loja',   icon: '✅' },
  em_preparo:          { label: 'Em Preparação',          icon: '🍳' },
  empreparo:           { label: 'Em Preparação',          icon: '🍳' },
  pronto:              { label: 'Pronto',                 icon: '📦' },
  aguardando_retirada: { label: 'Pronto para Retirada',   icon: '📦' },
  saiu_para_entrega:   { label: 'Saiu para Entrega 🛵',   icon: '🛵' },
  saiuparaentrega:     { label: 'Saiu para Entrega 🛵',   icon: '🛵' },
  saiu_entrega:        { label: 'Saiu para Entrega 🛵',   icon: '🛵' },
  em_entrega:          { label: 'Saiu para Entrega 🛵',   icon: '🛵' },
  em_transito:         { label: 'Saiu para Entrega 🛵',   icon: '🛵' },
  a_caminho:           { label: 'A Caminho 🛵',           icon: '🛵' },
  entregue:            { label: 'Entregue',               icon: '✅' },
  concluido:           { label: 'Entregue',               icon: '✅' },
  finalizado:          { label: 'Entregue',               icon: '✅' },
  cancelado:           { label: 'Cancelado',              icon: '❌' },
};

async function renderActiveOrderWidget() {
  const container = document.getElementById('home-active-order-container');
  const card      = document.getElementById('home-active-order-card');
  const dot       = document.getElementById('bnav-orders-dot');

  if (!container || !card) return;

  let activeOrders = state.customerOrders.filter(o => {
    const st = String(o.status || '').toLowerCase().trim();
    return st !== 'entregue' && st !== 'concluido' && st !== 'finalizado' && st !== 'cancelado';
  });

  // Recuperação do último pedido feito mesmo para clientes não autenticados via localStorage
  if (activeOrders.length === 0) {
    const lastOrderId = localStorage.getItem('fincore_last_order_id');
    if (lastOrderId) {
      try {
        const { data: lastOrder } = await sb.from('pedido').select('*, item_pedido(*)').eq('id', lastOrderId).maybeSingle();
        if (lastOrder) {
          const st = String(lastOrder.status || '').toLowerCase().trim();
          if (st !== 'entregue' && st !== 'concluido' && st !== 'finalizado' && st !== 'cancelado') {
            activeOrders = [lastOrder];
          }
        }
      } catch (_) {}
    }
  }

  if (activeOrders.length === 0) {
    container.style.display = 'none';
    if (dot) dot.style.display = 'none';
    return;
  }

  state.activeOrder = activeOrders[0];
  container.style.display = 'flex';
  if (dot) dot.style.display = 'block';

  const o = state.activeOrder;
  const num   = o.numeroPedido || o.id.slice(0, 6);
  const total = fmt(o.valorTotalCentavos);
  const dataHoraPrev = o.dataHoraEntregaPrevista
    ? fmtDateTime(o.dataHoraEntregaPrevista)
    : fmtDateTime(o.createdAt);

  const rawStatus = String(o.status || 'pendente').toLowerCase().trim();

  // Status mapping para Kanban de 5 passos reais:
  // 1: Aguardando confirmação da loja
  // 2: Confirmado pela loja
  // 3: Em preparação
  // 4: Pronto / A caminho
  // 5: Entregue
  let currentStep = 1;
  let headline = '⏳ Recebemos sua solicitação! Aguardando confirmação da loja.';
  let icon = '⏳';

  if (rawStatus.includes('saiu') || rawStatus.includes('entrega') || rawStatus.includes('transito') || rawStatus.includes('caminho')) {
    currentStep = 4;
    headline = '🛵 Seu pedido está a caminho!';
    icon = '🛵';
  } else if (rawStatus.includes('pronto') || rawStatus.includes('aguardando_retirada')) {
    currentStep = 4;
    headline = '📦 Seu pedido está pronto para entrega/retirada!';
    icon = '📦';
  } else if (rawStatus.includes('prepar') || rawStatus.includes('cozinha')) {
    currentStep = 3;
    headline = '🍳 Seu pedido está sendo preparado com carinho!';
    icon = '🍳';
  } else if (rawStatus === 'confirmado' || rawStatus === 'recebido' || rawStatus === 'aprovado') {
    currentStep = 2;
    headline = '✅ Pedido confirmado pela loja! Na fila de preparo.';
    icon = '✅';
  } else {
    currentStep = 1;
    headline = '⏳ Recebemos sua solicitação! Aguardando confirmação da loja.';
    icon = '⏳';
  }

  const steps = [
    { num: 1, label: 'Enviado' },
    { num: 2, label: 'Confirmado' },
    { num: 3, label: 'Em Preparo' },
    { num: 4, label: 'Pronto / Rota' },
    { num: 5, label: 'Entregue' }
  ];

  let stepperHtml = '<div class="active-order-stepper">';
  for (let i = 0; i < steps.length; i++) {
    const s = steps[i];
    let stepClass = 'step-pending';
    let bulletContent = '○';

    if (s.num < currentStep) {
      stepClass = 'step-done';
      bulletContent = '✓';
    } else if (s.num === currentStep) {
      stepClass = 'step-active';
      bulletContent = '●';
    }

    stepperHtml += `
      <div class="stepper-step ${stepClass}">
        <div class="stepper-bullet">${bulletContent}</div>
        <span class="stepper-label">${s.label}</span>
      </div>
    `;

    if (i < steps.length - 1) {
      let lineClass = '';
      if (s.num < currentStep) lineClass = 'line-done';
      else if (s.num === currentStep) lineClass = 'line-active';
      stepperHtml += `<div class="stepper-line ${lineClass}"></div>`;
    }
  }
  stepperHtml += '</div>';

  card.innerHTML = `
    <div class="active-order-top-row">
      <div class="active-order-info">
        <div class="active-order-icon">${icon}</div>
        <div class="active-order-details">
          <div class="active-order-headline">${headline}</div>
          <div class="active-order-subline">Pedido <strong>#${num}</strong> • <strong>${total}</strong> • Previsão: ${dataHoraPrev}</div>
        </div>
      </div>
      <button type="button" class="btn btn-primary btn-sm" id="btn-home-track-active-order">
        🔍 Acompanhar ao Vivo →
      </button>
    </div>
    ${stepperHtml}
  `;

  document.getElementById('btn-home-track-active-order')?.addEventListener('click', () => {
    openOrderDetailModal(o);
  });
}

// ─── Compre Novamente (Recompra do Último Pedido) ─────────────────────
function renderHomeReorderSection() {
  const container = document.getElementById('home-reorder-section');
  const card = document.getElementById('home-reorder-card');
  if (!container || !card) return;

  const completedOrders = state.customerOrders.filter(o => {
    const st = String(o.status || '').toLowerCase().trim();
    return st === 'concluido' || st === 'entregue' || st === 'finalizado';
  });

  if (completedOrders.length > 0) {
    const lastOrder = completedOrders[0];
    const items = lastOrder.item_pedido || [];
    const num = lastOrder.numeroPedido || lastOrder.id.slice(0, 6);
    const dateStr = fmtDate(lastOrder.createdAt);
    const totalStr = fmt(lastOrder.valorTotalCentavos);

    const itemsPills = items.slice(0, 4).map(i =>
      `<span class="reorder-item-pill">${i.quantidade}x ${i.nomeProduto}</span>`
    ).join('') + (items.length > 4 ? `<span class="reorder-item-pill">+${items.length - 4} itens</span>` : '');

    container.style.display = 'flex';
    card.innerHTML = `
      <div class="reorder-items-preview">
        <span class="reorder-order-header">PEDIDO ANTERIOR #${num} • ${dateStr}</span>
        <span class="reorder-items-text">${totalStr} (${lastOrder.tipoLogistica || 'Entrega'})</span>
        <div class="reorder-pills-row">${itemsPills}</div>
      </div>
      <button type="button" class="btn btn-primary" id="btn-home-reorder-cta">
        🔁 Comprar Novamente em 1 Clique
      </button>
    `;

    document.getElementById('btn-home-reorder-cta')?.addEventListener('click', () => {
      reorderOrder(lastOrder.id);
    });
  } else {
    container.style.display = 'none';
  }
}

// ─── Adição Rápida e Microinteração de Compra no Card ────────────────
function quickAddToCart(produtoId, delta = 1) {
  const prod = state.produtos.find(p => p.id === produtoId);
  if (!prod) return;

  const avail = getProductAvailability(prod);
  if (!avail.canAdd && delta > 0) {
    toast(`O produto "${prod.nome}" está indisponível no momento.`, 'warning');
    return;
  }

  const existingIdx = state.cart.findIndex(i => i.produto.id === produtoId);
  let newQty = 0;

  if (existingIdx >= 0) {
    newQty = state.cart[existingIdx].qty + delta;
    if (newQty <= 0) {
      state.cart.splice(existingIdx, 1);
      newQty = 0;
    } else {
      state.cart[existingIdx].qty = newQty;
    }
  } else if (delta > 0) {
    state.cart.push({ produto: prod, qty: delta, obs: '' });
    newQty = delta;
  }

  saveCart();
  updateCartBar();

  // Microinteração visual: animação pop nos contadores do carrinho
  const bottomBadge = document.getElementById('bottom-cart-count');
  const headerBadge = document.getElementById('header-cart-count');
  if (bottomBadge) {
    bottomBadge.classList.remove('cart-pop-anim');
    void bottomBadge.offsetWidth;
    bottomBadge.classList.add('cart-pop-anim');
  }
  if (headerBadge) {
    headerBadge.classList.remove('cart-pop-anim');
    void headerBadge.offsetWidth;
    headerBadge.classList.add('cart-pop-anim');
  }

  // Atualiza controles do card no DOM instantaneamente
  updateCardQtyControl(produtoId, newQty, avail);

  if (delta > 0 && newQty === 1) {
    toast(`🛒 ${prod.nome} adicionado ao pedido!`, 'success', 2000);
  }
}

function updateCardQtyControl(produtoId, inCartQty, avail) {
  document.querySelectorAll(`.product-card[data-prod-id="${produtoId}"]`).forEach(card => {
    let cartBadge = card.querySelector('.product-card-cart-qty-badge');
    if (inCartQty > 0) {
      if (!cartBadge) {
        cartBadge = document.createElement('span');
        cartBadge.className = 'product-card-cart-qty-badge';
        card.querySelector('.product-card-media')?.appendChild(cartBadge);
      }
      cartBadge.textContent = `${inCartQty} no pedido`;
      cartBadge.style.display = 'inline-block';
    } else if (cartBadge) {
      cartBadge.style.display = 'none';
    }

    const footerAction = card.querySelector('.product-card-action-slot');
    if (footerAction) {
      if (!avail.canAdd) {
        footerAction.innerHTML = `<button type="button" class="btn btn-secondary product-card-unavail-btn" disabled>Indisponível</button>`;
      } else if (inCartQty > 0) {
        footerAction.innerHTML = `
          <div class="product-card-qty-ctrl" onclick="event.stopPropagation()">
            <button type="button" class="btn-qty-mini btn-qty-minus" data-prod-id="${produtoId}" aria-label="Diminuir quantidade">−</button>
            <span class="qty-mini-value" data-prod-id="${produtoId}" title="Toque para alterar a quantidade">${inCartQty}</span>
            <button type="button" class="btn-qty-mini btn-qty-plus" data-prod-id="${produtoId}" aria-label="Aumentar quantidade">+</button>
          </div>
        `;
        attachCardQtyEvents(footerAction);
      } else {
        footerAction.innerHTML = `
          <button type="button" class="btn btn-primary product-card-add-btn" data-prod-id="${produtoId}">
            + Adicionar
          </button>
        `;
        footerAction.querySelector('.product-card-add-btn')?.addEventListener('click', (e) => {
          e.stopPropagation();
          const prod = state.produtos.find(p => p.id === produtoId);
          if (prod) openProductModal(prod);
        });
      }
    }
  });
}

function attachCardQtyEvents(container) {
  container.querySelectorAll('.btn-qty-minus').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      quickAddToCart(btn.dataset.prodId, -1);
    });
  });
  container.querySelectorAll('.btn-qty-plus').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      quickAddToCart(btn.dataset.prodId, 1);
    });
  });
  container.querySelectorAll('.qty-mini-value').forEach(el => {
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      const prodId = el.dataset.prodId || el.closest('.product-card')?.dataset.prodId;
      const prod = state.produtos.find(p => p.id === prodId);
      if (prod) openProductModal(prod);
    });
  });
}

// ─── Helper de Imagem do Produto ──────────────────────────────────────
function getProductImageUrl(prod) {
  if (!prod) return '';
  const raw = prod.imagem || prod.imagem_url || prod.imagemUrl || prod.foto || prod.foto_url || '';
  const str = String(raw).trim();
  if (str.startsWith('http://') || str.startsWith('https://') || str.startsWith('/') || str.startsWith('data:image/')) {
    return str;
  }
  return '';
}

// ─── Card Comercial Gourmet do Produto ────────────────────────────────
function createProductCardHtml(prod, showCatBadge = false) {
  const tiers = getTiersForProduct(prod);
  const catalogBasePrice = getBaseUnitPrice(prod);
  const inCartQty = getCartQtyFor(prod.id);
  const avail = getProductAvailability(prod);

  const catIcon = getCategoryIcon(prod.categoria_icone, prod.categoria_nome);
  const catNameClean = sanitizeCategoryName(prod.categoria_nome);

  let mediaHtml = '';
  const imgUrl = getProductImageUrl(prod);
  if (imgUrl) {
    mediaHtml = `
      <img src="${imgUrl}" alt="${prod.nome}" class="product-card-img" loading="lazy"
           onerror="this.style.display='none';this.nextElementSibling.style.display='flex'" />
      <div class="product-card-fallback-icon" style="display:none">${catIcon}</div>
    `;
  } else {
    mediaHtml = `<div class="product-card-fallback-icon">${catIcon}</div>`;
  }

  // Pill de Lote
  let tierPillHtml = '';
  if (tiers && tiers.length > 1) {
    const bestTier = tiers[tiers.length - 1];
    const minQty = bestTier.qtd_minima;
    const discountPct = calculateDiscountPercent(catalogBasePrice, bestTier.valor_unitario_centavos);
    const discountTag = discountPct > 0 ? ` <strong class="tier-pill-discount">(${discountPct}% OFF)</strong>` : '';
    tierPillHtml = `<span class="product-card-tier-pill">🛒 A partir de ${minQty} un: ${fmt(bestTier.valor_unitario_centavos)}/un${discountTag}</span>`;
  }

  const descClean = (prod.descricao && String(prod.descricao).trim()) ? String(prod.descricao).trim() : '';

  let actionSlotHtml = '';
  if (!avail.canAdd) {
    actionSlotHtml = `<button type="button" class="btn btn-secondary product-card-unavail-btn" disabled>Indisponível</button>`;
  } else if (inCartQty > 0) {
    actionSlotHtml = `
      <div class="product-card-qty-ctrl" onclick="event.stopPropagation()">
        <button type="button" class="btn-qty-mini btn-qty-minus" data-prod-id="${prod.id}" aria-label="Diminuir quantidade">−</button>
        <span class="qty-mini-value" data-prod-id="${prod.id}" title="Toque para alterar a quantidade">${inCartQty}</span>
        <button type="button" class="btn-qty-mini btn-qty-plus" data-prod-id="${prod.id}" aria-label="Aumentar quantidade">+</button>
      </div>
    `;
  } else {
    actionSlotHtml = `
      <button type="button" class="btn btn-primary product-card-add-btn" data-prod-id="${prod.id}">
        + Adicionar
      </button>
    `;
  }

  return `
    <article class="product-card ${!avail.canAdd ? 'is-unavailable' : ''}" data-prod-id="${prod.id}">
      <div class="product-card-media">
        <span class="product-card-badge-cat">${catIcon} ${catNameClean}</span>
        ${avail.showBadge !== false ? `<span class="avail-badge ${avail.badgeClass}">${avail.dot} ${avail.label}</span>` : ''}
        <span class="product-card-cart-qty-badge" style="${inCartQty > 0 ? '' : 'display:none'}">${inCartQty} no pedido</span>
        ${mediaHtml}
      </div>
      <div class="product-card-body">
        <h3 class="product-card-title">${prod.nome}</h3>
        ${descClean ? `<p class="product-card-desc">${descClean}</p>` : ''}
        ${tierPillHtml}
      </div>
      <div class="product-card-footer">
        <div class="product-card-price-wrap">
          <span class="product-card-price-label">Unidade</span>
          <span class="product-card-price">${fmt(catalogBasePrice)}</span>
        </div>
        <div class="product-card-action-slot">
          ${actionSlotHtml}
        </div>
      </div>
    </article>
  `;
}

function attachProductCardEvents(container) {
  container.querySelectorAll('.product-card').forEach(card => {
    // Clique no card abre o modal detalhado (exceto se clicar nos botões rápidos de mais e menos)
    card.addEventListener('click', (e) => {
      if (e.target.closest('.btn-qty-mini') || e.target.closest('.product-card-unavail-btn')) {
        return;
      }
      const prodId = card.dataset.prodId;
      const prod = state.produtos.find(p => p.id === prodId);
      if (prod) openProductModal(prod);
    });

    const addBtn = card.querySelector('.product-card-add-btn');
    if (addBtn) {
      addBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        const prodId = card.dataset.prodId;
        const prod = state.produtos.find(p => p.id === prodId);
        if (prod) openProductModal(prod);
      });
    }
  });

  attachCardQtyEvents(container);
}

function renderHomeFeaturedProducts() {
  const container = document.getElementById('home-featured-grid');
  if (!container) return;

  const featured = state.produtos.slice(0, 6);
  if (featured.length === 0) {
    container.innerHTML = `<div style="grid-column: 1/-1; color: var(--text-muted); font-size:13px;">Nenhum produto cadastrado no momento.</div>`;
    return;
  }

  container.innerHTML = featured.map(prod => createProductCardHtml(prod, true)).join('');
  attachProductCardEvents(container);
}

// ─── Destaque Visual Compacto para Festas & Encomendas ──────────────
function updatePartyBannerVisual() {
  const visualContainer = document.getElementById('party-banner-visual');
  const tierTag = document.getElementById('party-banner-tier-tag');

  if (tierTag) {
    const hasTiers = Array.isArray(state.precificacao) && state.precificacao.some(p => p.qtd_minima > 1);
    tierTag.style.display = hasTiers ? 'inline-flex' : 'none';
  }

  if (!visualContainer) return;

  const prodsComFoto = (state.produtos || []).filter(p => getProductImageUrl(p));
  if (prodsComFoto.length >= 2) {
    const fotos = prodsComFoto.slice(0, 3);
    visualContainer.innerHTML = `
      <div class="party-visual-mosaic">
        ${fotos.map(p => `
          <div class="party-mosaic-item" title="${p.nome}">
            <img src="${getProductImageUrl(p)}" alt="${p.nome}" class="party-mosaic-img" loading="lazy" onerror="this.parentElement.style.display='none'" />
          </div>
        `).join('')}
      </div>
    `;
  } else {
    visualContainer.innerHTML = `<span class="party-visual-emoji">🥟</span>`;
  }
}

function renderProductsGrid() {
  const wrapper = document.getElementById('products-grid-wrapper');
  const emptyState = document.getElementById('products-empty');
  const searchFeedback = document.getElementById('search-feedback');

  if (!wrapper) return;

  let filtered = [...state.produtos];

  // Filtro de Categoria
  if (state.currentCat !== 'all') {
    filtered = filtered.filter(p => p.categoria_id === state.currentCat);
  }

  // Filtro de Busca
  if (state.searchTerm) {
    const term = slugify(state.searchTerm);
    filtered = filtered.filter(p =>
      slugify(p.nome).includes(term) ||
      slugify(p.descricao).includes(term) ||
      slugify(p.categoria_nome).includes(term)
    );

    if (searchFeedback) {
      searchFeedback.style.display = 'block';
      searchFeedback.textContent = `Exibindo ${filtered.length} ${filtered.length === 1 ? 'resultado' : 'resultados'} para "${state.searchTerm}"`;
    }
  } else if (searchFeedback) {
    searchFeedback.style.display = 'none';
  }

  if (filtered.length === 0) {
    wrapper.innerHTML = '';
    if (emptyState) emptyState.style.display = 'flex';
  } else {
    if (emptyState) emptyState.style.display = 'none';
    wrapper.innerHTML = filtered.map(prod => createProductCardHtml(prod, true)).join('');
    attachProductCardEvents(wrapper);
  }
}

// ─── Modal de Produto Gastronômico ────────────────────────────────────
function openProductModal(prod) {
  state.modalProduct = prod;
  const currentInCart = getCartQtyFor(prod.id);
  state.modalQty = currentInCart > 0 ? currentInCart : 1;

  const modal = document.getElementById('product-modal');
  const nameEl = document.getElementById('modal-prod-name');
  const descEl = document.getElementById('modal-prod-desc');
  const priceEl = document.getElementById('modal-prod-price');
  const catEl = document.getElementById('modal-prod-cat');
  const imageArea = document.getElementById('modal-image-area');
  const qtyInput = document.getElementById('modal-qty-input');
  const tiersContainer = document.getElementById('modal-pricing-tiers');
  const minHintEl = document.getElementById('modal-cat-min-hint');

  if (!modal) return;

  const catIcon = getCategoryIcon(prod.categoria_icone, prod.categoria_nome);

  if (nameEl) nameEl.textContent = prod.nome;
  
  // Descrição REAL: se não existir, oculta o elemento
  if (descEl) {
    const descReal = (prod.descricao && String(prod.descricao).trim()) ? String(prod.descricao).trim() : '';
    if (descReal) {
      descEl.textContent = descReal;
      descEl.style.display = 'block';
    } else {
      descEl.textContent = '';
      descEl.style.display = 'none';
    }
  }

  if (catEl) catEl.textContent = `${catIcon} ${sanitizeCategoryName(prod.categoria_nome)}`;
  if (qtyInput) {
    qtyInput.value = state.modalQty;
    qtyInput.min = '0';
  }

  // Aviso informativo de quantidade mínima da categoria no pedido
  const minRequiredCat = getMinQtyForCategory(prod.categoria_id);
  if (minHintEl) {
    if (minRequiredCat > 1) {
      minHintEl.innerHTML = `ℹ️ O pedido mínimo para a categoria <strong>${sanitizeCategoryName(prod.categoria_nome)}</strong> é de <strong>${minRequiredCat} unidades</strong> no total do pedido. Você pode selecionar a partir de 1 unidade e combinar produtos.`;
      minHintEl.style.display = 'flex';
    } else {
      minHintEl.style.display = 'none';
      minHintEl.innerHTML = '';
    }
  }

  // Imagem no Modal — busca imagem real no banco ou emoji de fallback
  if (imageArea) {
    const imgUrl = getProductImageUrl(prod);
    if (imgUrl) {
      imageArea.innerHTML = `
        <img
          src="${imgUrl}"
          alt="${prod.nome}"
          style="width:100%;height:100%;object-fit:cover;border-radius:inherit;"
          onerror="this.parentElement.innerHTML='<div style=\\'font-size:72px;display:flex;align-items:center;justify-content:center;height:100%;\\'>${catIcon}</div>'"
        />`;
    } else {
      imageArea.innerHTML = `<div style="font-size:72px;display:flex;align-items:center;justify-content:center;height:100%;">${catIcon}</div>`;
    }
  }

  // Tabela de Faixas de Preço por Quantidade (Factual)
  const tiers = getTiersForProduct(prod);
  if (tiers && tiers.length > 1 && tiersContainer) {
    const baseTierPrice = tiers[0].valor_unitario_centavos;
    tiersContainer.style.display = 'block';
    tiersContainer.innerHTML = `
      <div class="pricing-tiers-title">Tabela de Preços por Quantidade</div>
      ${tiers.map((t, idx) => {
        const rangeText = t.qtd_maxima ? `${t.qtd_minima} a ${t.qtd_maxima} un` : `A partir de ${t.qtd_minima} un`;
        const discountPct = calculateDiscountPercent(baseTierPrice, t.valor_unitario_centavos);
        let discountBadge = '';
        if (discountPct > 0) {
          discountBadge = `<span class="tier-row-discount-badge">${discountPct}% OFF</span>`;
        } else if (idx === 0) {
          discountBadge = `<span class="tier-row-base-badge">Preço Base</span>`;
        }
        return `
          <div class="tier-row" id="tier-row-${t.qtd_minima}">
            <div class="tier-row-left">
              <span class="tier-range">${rangeText}</span>
              ${discountBadge}
            </div>
            <span class="tier-price"><strong>${fmt(t.valor_unitario_centavos)}</strong> /un</span>
          </div>
        `;
      }).join('')}
    `;
  } else if (tiersContainer) {
    tiersContainer.style.display = 'none';
  }

  // Disponibilidade do Produto e Badge
  const isInactive = prod.ativo === false || prod.status_comercial === 'indisponivel';
  const isLimited = prod.status_comercial === 'limitado';
  const availBadge = document.getElementById('modal-availability-badge');
  const addBtn = document.getElementById('modal-add-btn');

  if (availBadge) {
    if (isInactive) {
      availBadge.className = 'product-availability-badge unavailable';
      availBadge.textContent = '❌ Indisponível';
    } else if (isLimited) {
      availBadge.className = 'product-availability-badge limited';
      availBadge.textContent = '⚠️ Disponibilidade Limitada';
    } else {
      availBadge.className = 'product-availability-badge available';
      availBadge.textContent = '✅ Disponível';
    }
  }

  if (addBtn) {
    addBtn.disabled = isInactive;
    if (isInactive) {
      addBtn.style.opacity = '0.5';
      addBtn.style.cursor = 'not-allowed';
    } else {
      addBtn.style.opacity = '1';
      addBtn.style.cursor = 'pointer';
    }
  }
  if (qtyInput) qtyInput.disabled = isInactive;

  // Botões rápidos de incremento / seleção de quantidade (+1, +5, +10, +25, +50, +100)
  document.querySelectorAll('.quick-qty-chip').forEach(chip => {
    chip.onclick = (e) => {
      e.preventDefault();
      e.stopPropagation();
      if (isInactive) return;
      const addQty = parseInt(chip.dataset.qty, 10) || 1;
      const cur = parseInt(state.modalQty, 10) || 0;
      if (cur === 1 && addQty >= 5 && currentInCart === 0) {
        state.modalQty = addQty;
      } else {
        state.modalQty = cur + addQty;
      }
      if (qtyInput) qtyInput.value = state.modalQty;
      updateModalPrice();
    };
  });

  updateModalPrice();
  modal.classList.add('open');
}

function closeProductModal() {
  const modal = document.getElementById('product-modal');
  if (modal) modal.classList.remove('open');
  state.modalProduct = null;
}

function updateModalPrice() {
  if (!state.modalProduct) return;
  const prod = state.modalProduct;
  const currentInCart = getCartQtyFor(prod.id);
  const qty = Math.max(0, parseInt(state.modalQty, 10) || 0);
  const unitPrice = getPreco(prod, Math.max(1, qty));
  const totalPrice = unitPrice * qty;

  const priceEl = document.getElementById('modal-prod-price');
  if (priceEl) {
    if (qty > 0) {
      priceEl.innerHTML = `${fmt(totalPrice)} <small style="font-size:12px;color:var(--text-muted);font-weight:600">(${fmt(unitPrice)} /un)</small>`;
    } else {
      priceEl.innerHTML = `${fmt(unitPrice)} <small style="font-size:12px;color:var(--text-muted);font-weight:600">/unidade</small>`;
    }
  }

  const addBtn = document.getElementById('modal-add-btn');
  const isInactive = prod.ativo === false || prod.status_comercial === 'indisponivel';
  if (addBtn && !isInactive) {
    if (qty > 0) {
      addBtn.disabled = false;
      addBtn.style.opacity = '1';
      addBtn.style.cursor = 'pointer';
      if (currentInCart > 0) {
        addBtn.innerHTML = `🛒 Atualizar Pedido (${qty} un) • <span id="modal-btn-price">${fmt(totalPrice)}</span>`;
      } else {
        addBtn.innerHTML = `🛒 Adicionar ao Pedido (${qty} un) • <span id="modal-btn-price">${fmt(totalPrice)}</span>`;
      }
    } else {
      if (currentInCart > 0) {
        addBtn.disabled = false;
        addBtn.style.opacity = '1';
        addBtn.style.cursor = 'pointer';
        addBtn.innerHTML = `🗑️ Remover do Pedido`;
      } else {
        addBtn.disabled = true;
        addBtn.style.opacity = '0.6';
        addBtn.style.cursor = 'not-allowed';
        addBtn.innerHTML = `🛒 Digite a quantidade`;
      }
    }
  } else if (addBtn && isInactive) {
    addBtn.disabled = true;
    addBtn.style.opacity = '0.5';
    addBtn.style.cursor = 'not-allowed';
  }

  // Destacar faixa ativa na tabela de tiers
  const tiers = getTiersForProduct(prod);
  if (tiers && tiers.length > 0) {
    tiers.forEach(t => {
      const row = document.getElementById(`tier-row-${t.qtd_minima}`);
      if (row) {
        const isActive = qty >= t.qtd_minima && (!t.qtd_maxima || qty <= t.qtd_maxima);
        row.classList.toggle('active-tier', isActive);
      }
    });
  }
}

// ─── Motor de Geocodificação & Rotas Reais de Entrega ────────────────
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return parseFloat((R * c * 1.30).toFixed(1)); // 1.30 fator de malha viária urbana brasileira
}

async function geocodeAddress(addressStr) {
  if (!addressStr || addressStr.trim().length < 4) return null;
  const cleanAddr = addressStr.trim().toLowerCase();
  const cacheKey = 'fincore_geo_' + btoa(unescape(encodeURIComponent(cleanAddr))).slice(0, 32);

  try {
    const cached = localStorage.getItem(cacheKey);
    if (cached) {
      const parsed = JSON.parse(cached);
      if (parsed && parsed.lat && parsed.lon) return parsed;
    }
  } catch (_) {}

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3500);
    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(addressStr)}&countrycodes=br&limit=1`;
    const res = await fetch(url, {
      signal: controller.signal,
      headers: {
        'Accept-Language': 'pt-BR',
        'User-Agent': 'FinCoreFoodCardapio/2.0'
      }
    });
    clearTimeout(timeoutId);

    if (!res.ok) return null;
    const data = await res.json();
    if (data && data.length > 0) {
      const geo = {
        lat: parseFloat(data[0].lat),
        lon: parseFloat(data[0].lon),
        displayName: data[0].display_name
      };
      try {
        localStorage.setItem(cacheKey, JSON.stringify(geo));
      } catch (_) {}
      return geo;
    }
  } catch (_) {}
  return null;
}

async function getStoreCoordinates() {
  if (state.storeCoords && state.storeCoords.lat) return state.storeCoords;
  const emp = state.empresa || {};
  const rua = emp.logradouro || '';
  const num = emp.numero || '';
  const bair = emp.bairro || '';
  const cid = emp.cidade || 'Pouso Alegre';
  const uf = emp.estado || 'MG';

  // Se for a matriz conhecida em Francisca Augusta Rios, Pouso Alegre
  if (bair.toLowerCase().includes('francisca augusta') || rua.toLowerCase().includes('nadia prancic')) {
    state.storeCoords = { lat: -22.2592283, lon: -45.9260035 };
    return state.storeCoords;
  }

  // Tentar em cascata para máxima resiliência
  const attempts = [
    `${rua}, ${num} - ${bair}, ${cid} - ${uf}, Brasil`,
    `${rua}, ${bair}, ${cid} - ${uf}, Brasil`,
    `${bair}, ${cid} - ${uf}, Brasil`,
    `${cid} - ${uf}, Brasil`
  ];

  for (const query of attempts) {
    if (query.trim().length > 8) {
      const coords = await geocodeAddress(query);
      if (coords && coords.lat) {
        state.storeCoords = coords;
        return coords;
      }
    }
  }

  // Fallback padrão se nada responder
  state.storeCoords = { lat: -22.2592283, lon: -45.9260035 };
  return state.storeCoords;
}

async function calculateRouteDistance(originCoords, destCoords) {
  if (!originCoords || !destCoords) return null;
  const cacheKey = `fincore_route_${originCoords.lat.toFixed(4)}_${originCoords.lon.toFixed(4)}_${destCoords.lat.toFixed(4)}_${destCoords.lon.toFixed(4)}`;
  try {
    const cached = localStorage.getItem(cacheKey);
    if (cached) return JSON.parse(cached);
  } catch (_) {}

  // 1. Tentar rota viária real OSRM
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 2500);
    const url = `https://router.project-osrm.org/route/v1/driving/${originCoords.lon},${originCoords.lat};${destCoords.lon},${destCoords.lat}?overview=false`;
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timeoutId);

    if (res.ok) {
      const data = await res.json();
      if (data && data.routes && data.routes.length > 0) {
        const route = data.routes[0];
        const distKm = parseFloat((route.distance / 1000).toFixed(1));
        const durMin = Math.round(route.duration / 60) || 5;
        const result = {
          distanceMeters: route.distance,
          distanceKm: distKm,
          durationMinutes: durMin,
          provedor: 'osrm'
        };
        try {
          localStorage.setItem(cacheKey, JSON.stringify(result));
        } catch (_) {}
        return result;
      }
    }
  } catch (_) {}

  // 2. Fallback imediato: Haversine viário (Garante que nunca trava ou fica sem cálculo)
  const hKm = haversineKm(originCoords.lat, originCoords.lon, destCoords.lat, destCoords.lon);
  const durEstimado = Math.max(5, Math.round(hKm * 2.5));
  const fallbackResult = {
    distanceMeters: hKm * 1000,
    distanceKm: hKm,
    durationMinutes: durEstimado,
    provedor: 'haversine_viario'
  };
  try {
    localStorage.setItem(cacheKey, JSON.stringify(fallbackResult));
  } catch (_) {}
  return fallbackResult;
}

let routeCalcDebounce = null;
function triggerAsyncRouteCalculation() {
  if (state.tipoLogistica !== 'Entrega') return;
  const cep = (document.getElementById('checkout-cep')?.value || state.profile?.cep || '').replace(/\D/g, '');
  const logr = (document.getElementById('checkout-logradouro')?.value || state.profile?.logradouro || '').trim();
  const num = (document.getElementById('checkout-numero')?.value || state.profile?.numero || '').trim();
  const bair = (document.getElementById('checkout-bairro')?.value || state.profile?.bairro || '').trim();
  const cid = (document.getElementById('checkout-cidade')?.value || state.profile?.cidade || state.empresa?.cidade || 'Pouso Alegre').trim();
  const uf = (document.getElementById('checkout-uf')?.value || state.profile?.uf || state.empresa?.estado || 'MG').trim();

  // Precisa ter pelo menos (logradouro e bairro) OU (bairro e cidade) OU CEP completo
  const hasMinLocation = (logr && (num || bair)) || (bair && cid) || (cep.length === 8);
  if (!hasMinLocation) {
    const routeBox = document.getElementById('checkout-route-summary');
    if (routeBox) routeBox.style.display = 'none';
    return;
  }

  const routeBox = document.getElementById('checkout-route-summary');
  const distEl = document.getElementById('route-summary-distance');
  const ruleEl = document.getElementById('route-summary-rule');
  const badgeEl = document.getElementById('route-badge-fee');

  if (routeBox && distEl && !state.routeInfo) {
    routeBox.style.display = 'flex';
    distEl.textContent = '📍 Calculando distância e rota de entrega...';
    if (ruleEl) ruleEl.textContent = 'Consultando rota viária oficial';
    if (badgeEl) badgeEl.textContent = '...';
  }

  clearTimeout(routeCalcDebounce);
  routeCalcDebounce = setTimeout(async () => {
    try {
      const storeCoords = await getStoreCoordinates();
      if (!storeCoords) return;

      // Monta tentativas de geocodificação do destino
      let destCoords = null;
      const queries = [];
      if (logr && num) queries.push(`${logr}, ${num} - ${bair}, ${cid} - ${uf}, Brasil`);
      if (logr && bair) queries.push(`${logr}, ${bair}, ${cid} - ${uf}, Brasil`);
      if (bair && cid) queries.push(`${bair}, ${cid} - ${uf}, Brasil`);
      if (cep && cep.length === 8) queries.push(`${cep}, Brasil`);
      if (cid && uf) queries.push(`${cid} - ${uf}, Brasil`);

      for (const q of queries) {
        destCoords = await geocodeAddress(q);
        if (destCoords && destCoords.lat) break;
      }

      if (!destCoords) return;

      const routeInfo = await calculateRouteDistance(storeCoords, destCoords);
      if (routeInfo && routeInfo.distanceKm >= 0) {
        state.routeInfo = routeInfo;
        state.destCoords = destCoords;

        if (routeBox && distEl) {
          routeBox.style.display = 'flex';
          distEl.textContent = `📍 ${routeInfo.distanceKm} km até você (~${routeInfo.durationMinutes} min de trajeto)`;
        }

        updateCheckoutTotals();
        validateCheckoutForm();
      }
    } catch (e) {
      console.warn('Erro ao calcular rota:', e);
    }
  }, 400);
}

function renderPickupStoreInfo() {
  const storeNameEl = document.getElementById('retirada-store-name');
  const storeAddrEl = document.getElementById('retirada-store-address');
  const emp = state.empresa || {};
  const nome = emp.nomeFantasia || emp.razaoSocial || 'FinCore Food';
  const rua = emp.logradouro || '';
  const num = emp.numero || '';
  const bair = emp.bairro || '';
  const cid = emp.cidade || '';
  const uf = emp.estado || '';
  const full = [rua ? `${rua}, ${num}` : '', bair, cid ? `${cid} - ${uf}` : ''].filter(Boolean).join(' - ');

  if (storeNameEl) storeNameEl.textContent = nome;
  if (storeAddrEl) storeAddrEl.textContent = full || 'Endereço disponível para retirada no balcão.';
}

// ─── Fallback Inteligente de Taxa de Entrega ────────────────────────
function getTaxaEntregaFallback() {
  const regras = state.taxasEntrega || [];
  // 1. Regra explícita do tipo FIXO cadastrada pelo lojista
  const fixa = regras.find(r => r.ativo && (r.tipoRegra === 'fixo' || r.tipo_regra === 'fixo'));
  if (fixa) {
    return {
      valorCentavos: parseInt(fixa.valorCentavos || 0, 10),
      nome: fixa.nome || 'Taxa Fixa Padrão',
      isGratis: parseInt(fixa.valorCentavos || 0, 10) === 0
    };
  }

  // 2. Se houver qualquer regra de KM ou Bairro cadastrada, usar a primeira regra ativa da loja
  const ativas = regras.filter(r => r.ativo);
  if (ativas.length > 0) {
    const primeira = ativas[0];
    return {
      valorCentavos: parseInt(primeira.valorCentavos || 500, 10),
      nome: primeira.nome || 'Taxa Padrão',
      isGratis: parseInt(primeira.valorCentavos || 500, 10) === 0
    };
  }

  // 3. Fallback comercial padrão (R$ 5,00)
  return {
    valorCentavos: 500,
    nome: 'Taxa Padrão',
    isGratis: false
  };
}

// ─── Motor de Cálculo de Taxa de Entrega / Frete Comercial ───────────
function calcularTaxaEntrega() {
  if (state.tipoLogistica === 'Retirada') {
    state.entregaMetadata = {
      tipoLogistica: 'Retirada',
      taxaCentavos: 0,
      metodoCalculo: 'retirada_balcao'
    };
    return { valorCentavos: 0, label: 'Grátis (Retirada no Balcão)', isGratis: true };
  }

  const subtotal = cartTotal();
  const regras = state.taxasEntrega || [];
  const bairroInput = (document.getElementById('checkout-bairro')?.value || state.profile?.bairro || '').trim().toLowerCase();
  const cepInput = (document.getElementById('checkout-cep')?.value || state.profile?.cep || '').replace(/\D/g, '');

  let taxaEncontrada = null;

  // 1. Busca prioritária por Bairro (exato ou similar na tabela de regras da loja)
  if (bairroInput && regras.length > 0) {
    taxaEncontrada = regras.find(r => {
      if (r.ativo && (r.tipoRegra === 'bairro' || r.tipo_regra === 'bairro') && r.bairro) {
        const b = r.bairro.trim().toLowerCase();
        return b === bairroInput || bairroInput.includes(b) || b.includes(bairroInput);
      }
      return false;
    });

    if (taxaEncontrada) {
      const valor = parseInt(taxaEncontrada.valorCentavos || 0, 10);
      const minFreteGratis = parseInt(taxaEncontrada.pedidoMinimoCentavos || 0, 10);
      const nomeRegra = `Bairro: ${taxaEncontrada.bairro || taxaEncontrada.nome}`;

      state.entregaMetadata = {
        tipoLogistica: 'Entrega',
        latitude: state.destCoords?.lat || null,
        longitude: state.destCoords?.lon || null,
        distanciaKm: state.routeInfo?.distanceKm || null,
        tempoMinutos: state.routeInfo?.durationMinutes || null,
        metodoCalculo: 'regra_bairro',
        regraAplicada: nomeRegra,
        taxaCentavos: (minFreteGratis > 0 && subtotal >= minFreteGratis) ? 0 : valor
      };

      const routeRuleEl = document.getElementById('route-summary-rule');
      const routeBadgeEl = document.getElementById('route-badge-fee');
      if (routeRuleEl) routeRuleEl.textContent = `Regra: ${state.entregaMetadata.regraAplicada}`;
      if (routeBadgeEl) routeBadgeEl.textContent = state.entregaMetadata.taxaCentavos === 0 ? 'Grátis' : fmt(state.entregaMetadata.taxaCentavos);

      if (minFreteGratis > 0 && subtotal >= minFreteGratis) {
        return { valorCentavos: 0, label: `Grátis (Pedido acima de ${fmt(minFreteGratis)})`, isGratis: true, nomeRegra };
      }
      return { valorCentavos: valor, label: fmt(valor), isGratis: valor === 0, nomeRegra };
    }
  }

  // 2. Busca por Faixa de CEP (se não encontrou por bairro)
  if (!taxaEncontrada && cepInput.length === 8 && regras.length > 0) {
    const cepNum = parseInt(cepInput, 10);
    taxaEncontrada = regras.find(r => {
      if (r.ativo && (r.tipoRegra === 'cep' || r.tipo_regra === 'cep') && r.cepInicial && r.cepFinal) {
        const ini = parseInt(r.cepInicial.replace(/\D/g, ''), 10);
        const fim = parseInt(r.cepFinal.replace(/\D/g, ''), 10);
        return !isNaN(ini) && !isNaN(fim) && cepNum >= ini && cepNum <= fim;
      }
      return false;
    });

    if (taxaEncontrada) {
      const valor = parseInt(taxaEncontrada.valorCentavos || 0, 10);
      const minFreteGratis = parseInt(taxaEncontrada.pedidoMinimoCentavos || 0, 10);
      const nomeRegra = `Faixa CEP: ${taxaEncontrada.cepInicial} a ${taxaEncontrada.cepFinal}`;

      state.entregaMetadata = {
        tipoLogistica: 'Entrega',
        latitude: state.destCoords?.lat || null,
        longitude: state.destCoords?.lon || null,
        distanciaKm: state.routeInfo?.distanceKm || null,
        tempoMinutos: state.routeInfo?.durationMinutes || null,
        metodoCalculo: 'regra_cep',
        regraAplicada: nomeRegra,
        taxaCentavos: (minFreteGratis > 0 && subtotal >= minFreteGratis) ? 0 : valor
      };

      const routeRuleEl = document.getElementById('route-summary-rule');
      const routeBadgeEl = document.getElementById('route-badge-fee');
      if (routeRuleEl) routeRuleEl.textContent = `Regra: ${state.entregaMetadata.regraAplicada}`;
      if (routeBadgeEl) routeBadgeEl.textContent = state.entregaMetadata.taxaCentavos === 0 ? 'Grátis' : fmt(state.entregaMetadata.taxaCentavos);

      if (minFreteGratis > 0 && subtotal >= minFreteGratis) {
        return { valorCentavos: 0, label: `Grátis (Pedido acima de ${fmt(minFreteGratis)})`, isGratis: true, nomeRegra };
      }
      return { valorCentavos: valor, label: fmt(valor), isGratis: valor === 0, nomeRegra };
    }
  }

  // 3. Busca por Faixa de KM / Distância Geolocalizada (quando não há taxa específica de Bairro ou CEP)
  const kmRules = regras.filter(r => r.ativo && (r.tipoRegra === 'km' || r.tipo_regra === 'km'));
  if (state.routeInfo && state.routeInfo.distanceKm >= 0 && kmRules.length > 0) {
    const km = state.routeInfo.distanceKm;

    // Ordenar faixas por distanciaMinKm crescente
    const sortedKmRules = [...kmRules].sort((a, b) => {
      const minA = parseFloat(a.distanciaMinKm || a.distancia_min_km || 0);
      const minB = parseFloat(b.distanciaMinKm || b.distancia_min_km || 0);
      return minA - minB;
    });

    // Encontrar faixa exata
    taxaEncontrada = sortedKmRules.find(r => {
      const minKm = parseFloat(r.distanciaMinKm || r.distancia_min_km || 0);
      const maxKm = parseFloat(r.distanciaMaxKm || r.distancia_max_km || 99999);
      return km >= minKm && km <= maxKm;
    });

    // Se o KM for menor que o início da primeira faixa cadastrada (ex: deu 0.8 km e a primeira faixa começa em 2.0 km):
    // Como não há regra cobrando abaixo desse valor, é ENTREGA GRÁTIS (R$ 0,00)
    if (!taxaEncontrada && sortedKmRules.length > 0) {
      const firstMin = parseFloat(sortedKmRules[0].distanciaMinKm || sortedKmRules[0].distancia_min_km || 0);
      if (km < firstMin) {
        state.entregaMetadata = {
          tipoLogistica: 'Entrega',
          latitude: state.destCoords?.lat || null,
          longitude: state.destCoords?.lon || null,
          distanciaKm: km,
          tempoMinutos: state.routeInfo?.durationMinutes || null,
          metodoCalculo: 'faixa_km_gratis',
          regraAplicada: `Entrega Grátis (Raio Próximo - ${km} km)`,
          taxaCentavos: 0
        };

        const routeRuleEl = document.getElementById('route-summary-rule');
        const routeBadgeEl = document.getElementById('route-badge-fee');
        if (routeRuleEl) routeRuleEl.textContent = `Regra: Entrega Grátis (${km} km - Raio Próximo)`;
        if (routeBadgeEl) routeBadgeEl.textContent = 'Grátis';

        return {
          valorCentavos: 0,
          label: `Grátis (${km} km)`,
          isGratis: true,
          nomeRegra: `Entrega Grátis (Até ${firstMin} km)`
        };
      }
    }

    if (taxaEncontrada) {
      const valor = parseInt(taxaEncontrada.valorCentavos || 0, 10);
      const minFreteGratis = parseInt(taxaEncontrada.pedidoMinimoCentavos || 0, 10);
      const nomeRegra = taxaEncontrada.nome || `Faixa ${taxaEncontrada.distanciaMinKm || 0} a ${taxaEncontrada.distanciaMaxKm || '∞'} km`;

      state.entregaMetadata = {
        tipoLogistica: 'Entrega',
        latitude: state.destCoords?.lat || null,
        longitude: state.destCoords?.lon || null,
        distanciaKm: km,
        tempoMinutos: state.routeInfo?.durationMinutes || null,
        metodoCalculo: 'faixa_km_osrm',
        regraAplicada: `${nomeRegra} (${km} km)`,
        taxaCentavos: (minFreteGratis > 0 && subtotal >= minFreteGratis) ? 0 : valor
      };

      const routeRuleEl = document.getElementById('route-summary-rule');
      const routeBadgeEl = document.getElementById('route-badge-fee');
      if (routeRuleEl) routeRuleEl.textContent = `Regra: ${state.entregaMetadata.regraAplicada}`;
      if (routeBadgeEl) routeBadgeEl.textContent = state.entregaMetadata.taxaCentavos === 0 ? 'Grátis' : fmt(state.entregaMetadata.taxaCentavos);

      if (minFreteGratis > 0 && subtotal >= minFreteGratis) {
        return { valorCentavos: 0, label: `Grátis (Pedido acima de ${fmt(minFreteGratis)})`, isGratis: true, nomeRegra };
      }
      return { valorCentavos: valor, label: fmt(valor), isGratis: valor === 0, nomeRegra };
    } else if (sortedKmRules.length > 0) {
      // Fora de todas as faixas (ex: cliente está a 18 km e o máx cadastrado é 8 km)
      // Usa fallback da maior faixa ou taxa de fallback com aviso claro
      const maiorFaixa = sortedKmRules[sortedKmRules.length - 1];
      const maxKmTotal = parseFloat(maiorFaixa.distanciaMaxKm || maiorFaixa.distancia_max_km || 0);
      const valorFallback = parseInt(maiorFaixa.valorCentavos || 800, 10);

      state.entregaMetadata = {
        tipoLogistica: 'Entrega',
        distanciaKm: km,
        taxaCentavos: valorFallback,
        metodoCalculo: 'taxa_fallback_raio',
        regraAplicada: `Taxa Excedente (${km} km - máx padrão ${maxKmTotal} km)`
      };
      const routeRuleEl = document.getElementById('route-summary-rule');
      const routeBadgeEl = document.getElementById('route-badge-fee');
      if (routeRuleEl) routeRuleEl.textContent = `Regra: ${state.entregaMetadata.regraAplicada}`;
      if (routeBadgeEl) routeBadgeEl.textContent = fmt(valorFallback);

      return {
        valorCentavos: valorFallback,
        label: `${fmt(valorFallback)} (Acima de ${maxKmTotal} km)`,
        isGratis: false,
        nomeRegra: `Acima de ${maxKmTotal} km`
      };
    }
  }

  // 4. Regra geral FIXA explícita (somente tipoRegra == 'fixo')
  if (!taxaEncontrada && regras.length > 0) {
    taxaEncontrada = regras.find(r => r.ativo && (r.tipoRegra === 'fixo' || r.tipo_regra === 'fixo'));
  }

  // 5. Aplicação da regra da tabela de taxas (Bairro / CEP / Fixa)
  if (taxaEncontrada) {
    const valor = parseInt(taxaEncontrada.valorCentavos || 0, 10);
    const minFreteGratis = parseInt(taxaEncontrada.pedidoMinimoCentavos || 0, 10);

    state.entregaMetadata = {
      tipoLogistica: 'Entrega',
      latitude: state.destCoords?.lat || null,
      longitude: state.destCoords?.lon || null,
      distanciaKm: state.routeInfo?.distanceKm || null,
      tempoMinutos: state.routeInfo?.durationMinutes || null,
      metodoCalculo: 'tabela_bairro',
      regraAplicada: `Tabela: ${taxaEncontrada.nome}`,
      taxaCentavos: (minFreteGratis > 0 && subtotal >= minFreteGratis) ? 0 : valor
    };

    const routeRuleEl = document.getElementById('route-summary-rule');
    const routeBadgeEl = document.getElementById('route-badge-fee');
    if (routeRuleEl) routeRuleEl.textContent = `Regra: ${taxaEncontrada.nome}`;
    if (routeBadgeEl) routeBadgeEl.textContent = state.entregaMetadata.taxaCentavos === 0 ? 'Grátis' : fmt(valor);

    if (minFreteGratis > 0 && subtotal >= minFreteGratis) {
      return { 
        valorCentavos: 0, 
        label: `Grátis (Pedido acima de ${fmt(minFreteGratis)})`, 
        isGratis: true,
        nomeRegra: taxaEncontrada.nome 
      };
    }
    return { 
      valorCentavos: valor, 
      label: fmt(valor), 
      isGratis: valor === 0,
      nomeRegra: taxaEncontrada.nome 
    };
  }

  // 6. FALLBACK AUTOMÁTICO SE O CEP NÃO FOR ENCONTRADO OU SE O ENDEREÇO NÃO FOR MAPEADO
  if (bairroInput || cepInput) {
    const fallback = getTaxaEntregaFallback();
    state.entregaMetadata = {
      tipoLogistica: 'Entrega',
      latitude: state.destCoords?.lat || null,
      longitude: state.destCoords?.lon || null,
      distanciaKm: state.routeInfo?.distanceKm || null,
      tempoMinutos: state.routeInfo?.durationMinutes || null,
      metodoCalculo: 'taxa_fallback',
      regraAplicada: `${fallback.nome} (Endereço manual / CEP não mapeado)`,
      taxaCentavos: fallback.valorCentavos
    };

    const routeRuleEl = document.getElementById('route-summary-rule');
    const routeBadgeEl = document.getElementById('route-badge-fee');
    if (routeRuleEl) routeRuleEl.textContent = `Regra: ${fallback.nome}`;
    if (routeBadgeEl) routeBadgeEl.textContent = fallback.isGratis ? 'Grátis' : fmt(fallback.valorCentavos);

    return {
      valorCentavos: fallback.valorCentavos,
      label: `${fmt(fallback.valorCentavos)} (${fallback.nome})`,
      isGratis: fallback.isGratis,
      nomeRegra: fallback.nome,
      isFallback: true
    };
  }

  state.entregaMetadata = {
    tipoLogistica: 'Entrega',
    latitude: state.destCoords?.lat || null,
    longitude: state.destCoords?.lon || null,
    distanciaKm: null,
    tempoMinutos: null,
    metodoCalculo: 'aguardando_endereco',
    regraAplicada: 'Aguardando endereço',
    taxaCentavos: 0
  };

  return { valorCentavos: 0, label: 'Informe o endereço para calcular', isGratis: true };
}

function updateCheckoutTotals() {
  const subtotalEl = document.getElementById('checkout-subtotal');
  const taxaEl = document.getElementById('checkout-taxa');
  const totalEl = document.getElementById('checkout-total');

  const subtotal = cartTotal();
  const taxa = calcularTaxaEntrega();
  state.taxaEntregaCentavos = taxa.valorCentavos;

  if (subtotalEl) subtotalEl.textContent = fmt(subtotal);

  if (taxaEl) {
    taxaEl.textContent = taxa.label;
    if (taxa.isGratis) {
      taxaEl.className = 'text-success';
    } else {
      taxaEl.className = 'text-brand font-bold';
    }
  }

  const grandTotal = subtotal + state.taxaEntregaCentavos;
  if (totalEl) totalEl.textContent = fmt(grandTotal);

  return { subtotal, taxaCentavos: state.taxaEntregaCentavos, grandTotal };
}

// ─── TELA 3: CHECKOUT & ENCOMENDAS ────────────────────────────────────
function renderCheckoutPage() {
  const isLogged = !!(state.session?.user || (state.profile && state.profile.id));
  if (!isLogged) {
    state.redirectAfterAuth = 'screen-checkout';
    toast('🔐 Faça login ou crie sua conta para finalizar o pedido.', 'info', 4000);
    showScreen('screen-auth');
    return;
  }

  const itemsContainer = document.getElementById('checkout-items-list');
  const subtotalEl = document.getElementById('checkout-subtotal');
  const totalEl = document.getElementById('checkout-total');
  const minQtyAlert = document.getElementById('checkout-min-qty-alert');

  if (!itemsContainer) return;

  if (state.cart.length === 0) {
    itemsContainer.innerHTML = `
      <div style="text-align:center;padding:30px 10px;color:var(--text-muted);">
        <div style="font-size:36px;margin-bottom:8px">🛒</div>
        <p>Seu carrinho está vazio.</p>
        <button type="button" class="btn btn-primary btn-sm" id="btn-cart-empty-go-menu" style="margin-top:12px">
          🍽️ Ver Cardápio
        </button>
      </div>
    `;
    document.getElementById('btn-cart-empty-go-menu')?.addEventListener('click', () => {
      showScreen('screen-cardapio');
    });
    if (subtotalEl) subtotalEl.textContent = 'R$ 0,00';
    if (totalEl) totalEl.textContent = 'R$ 0,00';
    validateCheckoutForm();
    return;
  }

  // Agrupar itens por Categoria para exibir lotes de forma clara e profissional
  const categoriesMap = new Map();
  for (const item of state.cart) {
    const cId = item.produto.categoria_id || 'geral';
    const cName = sanitizeCategoryName(item.produto.categoria_nome) || 'Outros Produtos';
    const cIcon = getCategoryIcon(item.produto.categoria_icone, item.produto.categoria_nome);
    if (!categoriesMap.has(cId)) {
      categoriesMap.set(cId, { id: cId, name: cName, icon: cIcon, items: [], totalQty: 0 });
    }
    const catGroup = categoriesMap.get(cId);
    catGroup.items.push(item);
    catGroup.totalQty += item.qty;
  }

  let html = '';
  for (const [cId, cat] of categoriesMap.entries()) {
    const tiers = state.precificacao ? state.precificacao.filter(t => t.categoria_id === cId).sort((a, b) => a.qtd_minima - b.qtd_minima) : [];
    const hasTiers = tiers.length > 1;

    let catBannerHtml = '';
    if (hasTiers && cat.items.length > 0) {
      const sampleProd = cat.items[0].produto;
      const baseUnitPrice = getBaseUnitPrice(sampleProd);
      const currentUnitPrice = getPreco(sampleProd);
      const discountPct = calculateDiscountPercent(baseUnitPrice, currentUnitPrice);
      const nextTier = tiers.find(t => t.qtd_minima > cat.totalQty);

      if (nextTier) {
        const missing = nextTier.qtd_minima - cat.totalQty;
        const nextDiscount = calculateDiscountPercent(baseUnitPrice, nextTier.valor_unitario_centavos);

        if (discountPct > 0) {
          catBannerHtml = `
            <div class="checkout-category-tier-banner">
              <span class="cctb-icon">🎉</span>
              <div class="cctb-content">
                <strong>${discountPct}% OFF ativado (${fmt(currentUnitPrice)}/un)!</strong> Adicione +<strong>${missing} un</strong> para liberar <strong>${nextDiscount}% OFF</strong> (${fmt(nextTier.valor_unitario_centavos)}/un).
              </div>
            </div>
          `;
        } else {
          catBannerHtml = `
            <div class="checkout-category-tier-upsell">
              💡 Adicione mais <strong>${missing} un</strong> de ${cat.name} para ativar o lote de <strong>${nextDiscount}% OFF</strong> (${fmt(nextTier.valor_unitario_centavos)}/un)!
            </div>
          `;
        }
      } else if (discountPct > 0) {
        catBannerHtml = `
          <div class="checkout-category-tier-banner">
            <span class="cctb-icon">🏆</span>
            <div class="cctb-content">
              <strong>Desconto Máximo de ${discountPct}% OFF ativado!</strong> Melhor preço garantido (${fmt(currentUnitPrice)}/un).
            </div>
          </div>
        `;
      }
    }

    const itemsHtml = cat.items.map(item => {
      const unitPrice = getPreco(item.produto);
      const itemTotal = unitPrice * item.qty;

      return `
        <div class="checkout-item-row">
          <div class="checkout-item-details">
            <div class="checkout-item-name">${item.produto.nome}</div>
            <div class="checkout-item-sub">${fmt(unitPrice)} × ${item.qty} = <strong>${fmt(itemTotal)}</strong></div>
          </div>
          <div style="display:flex;align-items:center;gap:8px">
            <div class="qty-control">
              <button type="button" class="qty-btn btn-cart-minus" data-id="${item.produto.id}" aria-label="Diminuir">−</button>
              <span class="qty-input" style="line-height:38px">${item.qty}</span>
              <button type="button" class="qty-btn btn-cart-plus" data-id="${item.produto.id}" aria-label="Aumentar">+</button>
            </div>
            <button type="button" class="btn btn-ghost btn-sm btn-danger-text btn-cart-remove" data-id="${item.produto.id}" title="Remover item" aria-label="Remover item">
              🗑️
            </button>
          </div>
        </div>
      `;
    }).join('');

    html += `
      <div class="checkout-category-block">
        <div class="checkout-category-header">
          <span>${cat.icon} ${cat.name}</span>
          <span class="checkout-category-total-badge">${cat.totalQty} un</span>
        </div>
        ${catBannerHtml}
        <div class="checkout-category-items">
          ${itemsHtml}
        </div>
      </div>
    `;
  }

  itemsContainer.innerHTML = html;

  itemsContainer.querySelectorAll('.btn-cart-minus').forEach(b => {
    b.addEventListener('click', () => changeCartQty(b.dataset.id, -1));
  });

  itemsContainer.querySelectorAll('.btn-cart-plus').forEach(b => {
    b.addEventListener('click', () => changeCartQty(b.dataset.id, 1));
  });

  itemsContainer.querySelectorAll('.btn-cart-remove').forEach(b => {
    b.addEventListener('click', () => {
      removeFromCart(b.dataset.id);
      toast('Item removido do carrinho.', 'info', 2000);
    });
  });

  // Totais & Taxa de Entrega Dinâmica
  updateCheckoutTotals();

  // Validação de Quantidade Mínima
  const valResult = validateMinimumCategoryQuantities();
  if (!valResult.valid && minQtyAlert) {
    minQtyAlert.style.display = 'flex';
    minQtyAlert.innerHTML = valResult.errors.map(err =>
      `⚠️ A categoria "<strong>${err.categoryName}</strong>" exige no mínimo ${err.minRequiredQty} un (atual: ${err.categoryQty} un. Faltam ${err.missingQty} un).`
    ).join('<br>');
  } else if (minQtyAlert) {
    minQtyAlert.style.display = 'none';
  }

  // Renderizar formas de pagamento dinâmicas da loja
  renderPaymentMethods();

  // Preenchimento de identificação e endereço salvo se o usuário estiver logado
  populateSavedAddressInCheckout();
  validateCheckoutForm();
}

function renderPaymentMethods() {
  const grid = document.getElementById('checkout-payment-grid');
  if (!grid) return;

  const fps = (state.formasPagamento && state.formasPagamento.length > 0)
    ? state.formasPagamento
    : [
        { id: 'default-pix', nome: 'Pix Instantâneo', tipo: 'pix', permiteTroco: false },
        { id: 'default-dinheiro', nome: 'Dinheiro', tipo: 'DINHEIRO', permiteTroco: true },
        { id: 'default-credito', nome: 'Cartão de Crédito', tipo: 'cartaoCredito', permiteTroco: false },
        { id: 'default-debito', nome: 'Cartão de Débito', tipo: 'cartaoDebito', permiteTroco: false }
      ];

  function getPaymentMeta(fp) {
    const t = String(fp.tipo || '').toLowerCase();
    const n = String(fp.nome || '').toLowerCase();
    if (t.includes('pix') || n.includes('pix')) {
      return { icon: '⚡', desc: 'Copia e Cola Automático com valor' };
    }
    if (t.includes('dinheiro') || n.includes('dinheiro')) {
      return { icon: '💵', desc: 'Pagamento em espécie na entrega ou balcão' };
    }
    if (t.includes('credito') || n.includes('credito')) {
      return { icon: '💳', desc: 'Cartão de crédito na maquininha' };
    }
    if (t.includes('debito') || n.includes('debito')) {
      return { icon: '💳', desc: 'Cartão de débito na maquininha' };
    }
    return { icon: '💳', desc: 'Pagamento na entrega ou balcão' };
  }

  // Se nada foi selecionado ainda, define a primeira opção (preferindo Pix se houver)
  if (!state.formaPagamentoId && fps.length > 0) {
    const defaultFp = fps.find(f => String(f.tipo || '').toLowerCase().includes('pix') || String(f.nome || '').toLowerCase().includes('pix')) || fps[0];
    state.formaPagamentoId = defaultFp.id;
    state.formaPagamentoNome = defaultFp.nome;
    state.formaPagamentoTipo = defaultFp.tipo;
    state.formaPagamentoPermiteTroco = !!defaultFp.permiteTroco;
  }

  grid.innerHTML = fps.map(fp => {
    const meta = getPaymentMeta(fp);
    const isSelected = state.formaPagamentoId === fp.id || (!state.formaPagamentoId && state.formaPagamentoNome === fp.nome);
    return `
      <div
        class="payment-card ${isSelected ? 'active' : ''}"
        data-id="${fp.id}"
        data-payment="${fp.nome}"
        data-type="${fp.tipo || ''}"
        data-troco="${fp.permiteTroco ? 'true' : 'false'}"
        role="button"
        tabindex="0"
      >
        <div class="payment-card-icon">${meta.icon}</div>
        <div class="payment-card-title">${fp.nome}</div>
        <div class="payment-card-desc">${meta.desc}</div>
      </div>
    `;
  }).join('');

  grid.querySelectorAll('.payment-card').forEach(card => {
    card.addEventListener('click', () => {
      grid.querySelectorAll('.payment-card').forEach(c => c.classList.remove('active'));
      card.classList.add('active');

      state.formaPagamentoId = card.dataset.id;
      state.formaPagamentoNome = card.dataset.payment;
      state.formaPagamentoTipo = card.dataset.type;
      state.formaPagamentoPermiteTroco = card.dataset.troco === 'true';

      const trocoSec = document.getElementById('troco-section');
      if (trocoSec) {
        trocoSec.style.display = (state.formaPagamentoPermiteTroco || state.formaPagamentoNome === 'Dinheiro') ? 'block' : 'none';
      }
      validateCheckoutForm();
    });
  });

  const trocoSec = document.getElementById('troco-section');
  if (trocoSec) {
    trocoSec.style.display = (state.formaPagamentoPermiteTroco || state.formaPagamentoNome === 'Dinheiro') ? 'block' : 'none';
  }
}

async function populateSavedAddressInCheckout() {
  // 1. Contato do Cliente: Obrigatório estar autenticado
  const isLogged = !!(state.session?.user || (state.profile && state.profile.id));
  const contactSection = document.getElementById('checkout-contact-section');
  const loggedUserBox = document.getElementById('checkout-logged-user-box');
  const loggedUserName = document.getElementById('checkout-logged-user-name');
  const loggedUserPhone = document.getElementById('checkout-logged-user-phone');

  const nomeInput = document.getElementById('checkout-nome-cliente');
  const phoneInput = document.getElementById('checkout-phone-cliente');

  if (contactSection) contactSection.style.display = 'none';

  if (isLogged) {
    if (loggedUserBox) loggedUserBox.style.display = 'block';
    const nome = state.profile?.nome || state.session?.user?.user_metadata?.full_name || 'Cliente Cadastrado';
    const phone = formatPhone(state.profile?.whatsapp || '');
    if (loggedUserName) loggedUserName.textContent = nome;
    if (loggedUserPhone) loggedUserPhone.textContent = phone || 'Sem WhatsApp informado';
    if (nomeInput) nomeInput.value = nome;
    if (phoneInput) phoneInput.value = phone;
  } else {
    if (loggedUserBox) loggedUserBox.style.display = 'none';
    state.redirectAfterAuth = 'screen-checkout';
    showScreen('screen-auth');
    return;
  }

  // 2. Endereços Salvos / Cadastrados do cliente
  const savedBox = document.getElementById('checkout-saved-address-box');
  const addressesList = document.getElementById('checkout-saved-addresses-list');
  const formContainer = document.getElementById('checkout-address-form-container');
  const btnAddNovo = document.getElementById('btn-add-novo-endereco');
  const btnVoltarSalvo = document.getElementById('btn-voltar-endereco-salvo');

  if (!savedBox || !formContainer) return;

  await loadCustomerAddresses();

  const cepEl = document.getElementById('checkout-cep');
  const logrEl = document.getElementById('checkout-logradouro');
  const numEl = document.getElementById('checkout-numero');
  const bairEl = document.getElementById('checkout-bairro');
  const cidEl = document.getElementById('checkout-cidade');
  const ufEl = document.getElementById('checkout-uf');
  const compEl = document.getElementById('checkout-complemento');
  const refEl = document.getElementById('checkout-referencia');

  function applySelectedAddress(addr) {
    if (!addr) return;
    state.selectedAddressId = addr.id;
    if (cepEl) cepEl.value = addr.cep || '';
    if (logrEl) logrEl.value = addr.logradouro || '';
    if (numEl) numEl.value = addr.numero || '';
    if (bairEl) bairEl.value = addr.bairro || '';
    if (cidEl) cidEl.value = addr.cidade || state.empresa?.cidade || 'Pouso Alegre';
    if (ufEl) ufEl.value = addr.uf || state.empresa?.estado || 'MG';
    if (compEl) compEl.value = addr.complemento || '';
    if (refEl) refEl.value = addr.referencia || '';

    // Atualiza classes dos cards
    document.querySelectorAll('#checkout-saved-addresses-list .address-card-item').forEach(card => {
      card.classList.toggle('selected', card.dataset.id === String(addr.id));
    });

    triggerAsyncRouteCalculation();
    validateCheckoutForm();
    updateCheckoutTotals();
  }

  if (state.customerAddresses && state.customerAddresses.length > 0) {
    savedBox.style.display = 'block';
    formContainer.style.display = 'none';

    let defaultAddr = state.customerAddresses.find(a => a.id === state.selectedAddressId);
    if (!defaultAddr) {
      defaultAddr = state.customerAddresses.find(a => a.isPadrao || a.is_padrao) || state.customerAddresses[0];
    }

    if (addressesList) {
      addressesList.innerHTML = state.customerAddresses.map(addr => {
        const isSel = String(addr.id) === String(defaultAddr.id);
        const icon = (addr.nomeIdentificador || '').toLowerCase().includes('trab') ? '💼' : ((addr.nomeIdentificador || '').toLowerCase().includes('casa') ? '🏠' : '📍');
        const tag = addr.nomeIdentificador || 'Endereço';
        const street = `${addr.logradouro || ''}, ${addr.numero || 'S/N'}${addr.complemento ? ' (' + addr.complemento + ')' : ''}`;
        const sub = `${addr.bairro || ''} - ${addr.cidade || ''} / ${addr.uf || ''}${addr.cep ? ' • CEP: ' + addr.cep : ''}`;
        const ref = addr.referencia ? `Ponto de ref: ${addr.referencia}` : '';

        return `
          <div class="address-card-item ${isSel ? 'selected' : ''}" data-id="${addr.id}">
            <div class="address-card-radio"></div>
            <div class="address-card-content">
              <div class="address-card-top-row">
                <div class="address-card-badge-row">
                  <span class="address-card-tag">${icon} ${tag}</span>
                  ${addr.isPadrao ? '<span class="address-badge-pill">Principal</span>' : ''}
                </div>
              </div>
              <div class="address-card-street">${street}</div>
              <div class="address-card-sub">${sub}</div>
              ${ref ? `<div class="address-card-ref">${ref}</div>` : ''}
            </div>
          </div>
        `;
      }).join('');

      addressesList.querySelectorAll('.address-card-item').forEach(card => {
        card.addEventListener('click', () => {
          const found = state.customerAddresses.find(a => String(a.id) === card.dataset.id);
          if (found) applySelectedAddress(found);
        });
      });
    }

    applySelectedAddress(defaultAddr);

    if (btnAddNovo) {
      btnAddNovo.onclick = () => {
        savedBox.style.display = 'none';
        formContainer.style.display = 'block';
        if (btnVoltarSalvo) btnVoltarSalvo.style.display = 'inline-block';
        if (logrEl) {
          logrEl.value = '';
          if (numEl) numEl.value = '';
          if (bairEl) bairEl.value = '';
          if (cepEl) cepEl.value = '';
          if (compEl) compEl.value = '';
          if (refEl) refEl.value = '';
          logrEl.focus();
        }
        validateCheckoutForm();
      };
    }

    if (btnVoltarSalvo) {
      btnVoltarSalvo.onclick = () => {
        savedBox.style.display = 'block';
        formContainer.style.display = 'none';
        btnVoltarSalvo.style.display = 'none';
        applySelectedAddress(defaultAddr);
      };
    }
  } else {
    savedBox.style.display = 'none';
    formContainer.style.display = 'block';
    if (btnVoltarSalvo) btnVoltarSalvo.style.display = 'none';
  }

  updateCheckoutTotals();
  updateCheckoutStepper();
}

// ─── Controle Dinâmico do Stepper de Checkout ───────────────────────
function updateCheckoutStepper(targetStep = null) {
  const step1 = document.getElementById('step-ind-1');
  const step2 = document.getElementById('step-ind-2');
  const step3 = document.getElementById('step-ind-3');
  const line1 = document.getElementById('step-line-1');
  const line2 = document.getElementById('step-line-2');
  if (!step1 || !step2 || !step3) return;

  let currentStep = targetStep;
  if (!currentStep) {
    if (!state.cart || state.cart.length === 0) {
      currentStep = 1;
    } else {
      const isLogged = !!(state.session || (state.profile && state.profile.nome));
      const nome = isLogged ? (state.profile?.nome || 'Cliente') : (document.getElementById('checkout-nome-cliente')?.value.trim() || '');
      const phone = isLogged ? (state.profile?.whatsapp || '') : (document.getElementById('checkout-phone-cliente')?.value || '');
      const hasContact = nome.length >= 2 && phone.replace(/\D/g, '').length >= 8;

      let hasDelivery = true;
      if (state.tipoLogistica === 'Entrega') {
        const logr = document.getElementById('checkout-logradouro')?.value.trim();
        const num = document.getElementById('checkout-numero')?.value.trim();
        hasDelivery = !!(logr && num);
      }
      const data = document.getElementById('checkout-data')?.value;
      const hora = document.getElementById('checkout-hora')?.value;
      const hasSchedule = !!(data && hora);

      if (hasContact && hasDelivery && hasSchedule) {
        currentStep = 3;
      } else {
        currentStep = 2;
      }
    }
  }

  const num1 = step1.querySelector('.step-num');
  const num2 = step2.querySelector('.step-num');
  const num3 = step3.querySelector('.step-num');

  if (currentStep === 1) {
    step1.className = 'step-item active';
    if (num1) num1.textContent = '1';
    step2.className = 'step-item';
    if (num2) num2.textContent = '2';
    step3.className = 'step-item';
    if (num3) num3.textContent = '3';
    if (line1) line1.className = 'step-line';
    if (line2) line2.className = 'step-line';
  } else if (currentStep === 2) {
    step1.className = 'step-item completed';
    if (num1) num1.textContent = '✓';
    step2.className = 'step-item active';
    if (num2) num2.textContent = '2';
    step3.className = 'step-item';
    if (num3) num3.textContent = '3';
    if (line1) line1.className = 'step-line active';
    if (line2) line2.className = 'step-line';
  } else if (currentStep >= 3) {
    step1.className = 'step-item completed';
    if (num1) num1.textContent = '✓';
    step2.className = 'step-item completed';
    if (num2) num2.textContent = '✓';
    step3.className = 'step-item active';
    if (num3) num3.textContent = '3';
    if (line1) line1.className = 'step-line active';
    if (line2) line2.className = 'step-line active';
  }
}

function validateCheckoutForm() {
  const warning = document.getElementById('checkout-validation-warning');
  const msgEl = document.getElementById('checkout-validation-msg');
  const submitBtn = document.getElementById('btn-confirmar-pedido');

  if (!warning || !submitBtn) return;

  if (state.cart.length === 0) {
    warning.className = 'validation-warning-box invalid';
    msgEl.textContent = 'Adicione itens ao seu pedido antes de finalizar.';
    submitBtn.disabled = true;
    return;
  }

  // Validação de Autenticação Obrigatória
  const isLogged = !!(state.session?.user || (state.profile && state.profile.id));
  if (!isLogged) {
    warning.className = 'validation-warning-box invalid';
    msgEl.textContent = 'Você precisa estar logado na sua conta para finalizar o pedido.';
    submitBtn.disabled = true;
    submitBtn.textContent = '🔐 Faça Login para Continuar';
    return;
  }

  // Validação de Contato do Cliente Autenticado
  const nomeCliente = state.profile?.nome || document.getElementById('checkout-nome-cliente')?.value.trim() || 'Cliente';
  const rawPhoneCliente = state.profile?.whatsapp || document.getElementById('checkout-phone-cliente')?.value || '';
  const phoneVal = validatePhone(rawPhoneCliente);

  if (nomeCliente.length < 2) {
    warning.className = 'validation-warning-box invalid';
    msgEl.textContent = 'Por favor, informe seu Nome Completo para identificação do pedido.';
    submitBtn.disabled = true;
    return;
  }

  if (!phoneVal.valid) {
    warning.className = 'validation-warning-box invalid';
    msgEl.textContent = phoneVal.error || 'Por favor, informe seu WhatsApp / Telefone com DDD no seu perfil.';
    submitBtn.disabled = true;
    return;
  }

  const valResult = validateMinimumCategoryQuantities();
  if (!valResult.valid) {
    warning.className = 'validation-warning-box invalid';
    msgEl.textContent = 'Seu pedido não atinge a quantidade mínima exigida em algumas categorias.';
    submitBtn.disabled = true;
    return;
  }

  // Validação de Endereço se Logística for Entrega
  if (state.tipoLogistica === 'Entrega') {
    const logr = document.getElementById('checkout-logradouro')?.value.trim();
    const num = document.getElementById('checkout-numero')?.value.trim();
    const bair = document.getElementById('checkout-bairro')?.value.trim();
    const cid = document.getElementById('checkout-cidade')?.value.trim();

    if (!logr || !num || !bair || !cid) {
      warning.className = 'validation-warning-box invalid';
      msgEl.textContent = 'Preencha o endereço completo (Rua, Número, Bairro e Cidade) para entrega.';
      submitBtn.disabled = true;
      return;
    }

    if (state.entregaMetadata && state.entregaMetadata.foraDoRaio) {
      warning.className = 'validation-warning-box invalid';
      msgEl.textContent = 'O endereço informado está fora do raio de entrega configurado. Escolha a opção "Retirada no Balcão" ou consulte a loja.';
      submitBtn.disabled = true;
      return;
    }
  }

  // Validação de Data e Hora com Regras de Atendimento e Antecedência
  const data = document.getElementById('checkout-data')?.value;
  const hora = document.getElementById('checkout-hora')?.value;
  const schedVal = validateOrderSchedule(data, hora);
  if (!schedVal.valid) {
    warning.className = 'validation-warning-box invalid';
    msgEl.textContent = schedVal.message;
    submitBtn.disabled = true;
    return;
  }

  warning.className = 'validation-warning-box';
  submitBtn.disabled = false;
  submitBtn.textContent = '🚀 Revisar e Confirmar Pedido';
  updateCheckoutStepper();
}

// ─── Criação e Confirmação de Pedidos (100% Real Supabase Schema) ──────
async function abrirModalConfirmacaoCheckout() {
  const isLogged = !!(state.session?.user || (state.profile && state.profile.id));
  if (!isLogged) {
    toast('🔐 Faça login ou cadastre-se para confirmar seu pedido.', 'error', 4000);
    state.redirectAfterAuth = 'screen-checkout';
    showScreen('screen-auth');
    return;
  }

  const val = validateMinimumCategoryQuantities();
  if (!val.valid) {
    toast(val.message, 'error', 4000);
    return;
  }

  const nome = state.profile?.nome || document.getElementById('checkout-nome-cliente')?.value.trim() || 'Cliente';
  const phone = state.profile?.whatsapp || document.getElementById('checkout-phone-cliente')?.value.trim() || '';

  if (nome.length < 2) {
    toast('Por favor, preencha o seu nome completo.', 'error');
    return;
  }

  if (phone.replace(/\D/g, '').length < 8) {
    toast('Por favor, informe seu telefone / WhatsApp no seu cadastro.', 'error');
    return;
  }

  const data = document.getElementById('checkout-data')?.value;
  const hora = document.getElementById('checkout-hora')?.value;
  const schedVal = validateOrderSchedule(data, hora);
  if (!schedVal.valid) {
    toast(schedVal.message, 'error', 5000);
    return;
  }

  const modal = document.getElementById('modal-confirm-checkout');
  if (!modal) return;

  const obs = document.getElementById('checkout-obs')?.value.trim();

  // Endereço
  const logr = document.getElementById('checkout-logradouro')?.value.trim() || state.profile?.logradouro || '';
  const num = document.getElementById('checkout-numero')?.value.trim() || state.profile?.numero || '';
  const bair = document.getElementById('checkout-bairro')?.value.trim() || state.profile?.bairro || '';
  const cid = document.getElementById('checkout-cidade')?.value.trim() || state.profile?.cidade || '';
  const fullAddress = `${logr}, ${num} - ${bair}, ${cid}`;

  document.getElementById('cm-cliente-nome').textContent = nome;
  document.getElementById('cm-cliente-phone').textContent = formatPhone(phone);
  document.getElementById('cm-logistica-tipo').textContent = state.tipoLogistica;
  document.getElementById('cm-endereco-texto').textContent = state.tipoLogistica === 'Entrega' ? fullAddress : 'Retirada no estabelecimento';
  document.getElementById('cm-data-hora').textContent = `${data ? data.split('-').reverse().join('/') : ''} às ${hora || ''}`;
  document.getElementById('cm-forma-pagamento').textContent = state.formaPagamentoNome;

  const obsRow = document.getElementById('cm-obs-row');
  if (obsRow) {
    if (obs) {
      obsRow.style.display = 'block';
      document.getElementById('cm-obs-texto').textContent = obs;
    } else {
      obsRow.style.display = 'none';
    }
  }

  // Lista de Itens no Modal
  const itemsList = document.getElementById('cm-items-list');
  if (itemsList) {
    itemsList.innerHTML = state.cart.map(item => `
      <div style="display:flex;justify-content:space-between;font-size:13px;padding:4px 0;border-bottom:1px solid rgba(255,255,255,0.05)">
        <span>${item.qty}x ${item.produto.nome}</span>
        <strong>${fmt(getPreco(item.produto) * item.qty)}</strong>
      </div>
    `).join('');
  }

  const subtotal = cartTotal();
  const taxaEntrega = (state.tipoLogistica === 'Entrega') ? (state.taxaEntregaCentavos || 0) : 0;
  const grandTotal = subtotal + taxaEntrega;

  document.getElementById('cm-subtotal-val').textContent = fmt(subtotal);
  const cmTaxaEl = document.getElementById('cm-taxa-val');
  if (cmTaxaEl) {
    if (taxaEntrega === 0) {
      cmTaxaEl.textContent = state.tipoLogistica === 'Retirada' ? 'Grátis (Retirada)' : 'Grátis';
      cmTaxaEl.style.color = 'var(--success)';
    } else {
      cmTaxaEl.textContent = fmt(taxaEntrega);
      cmTaxaEl.style.color = 'var(--brand-400)';
    }
  }
  document.getElementById('cm-total-val').textContent = fmt(grandTotal);

  // Pix no Modal
  const pixBox = document.getElementById('cm-pix-box');
  const isPixSelected = String(state.formaPagamentoNome || '').toLowerCase().includes('pix') || String(state.formaPagamentoTipo || '').toLowerCase().includes('pix');
  if (pixBox && isPixSelected && state.empresa?.chave_pix) {
    pixBox.style.display = 'block';
    document.getElementById('cm-pix-favorecido').textContent = state.empresa.pix_favorecido || state.empresa.nomeFantasia || 'FinCore Food';
    document.getElementById('cm-pix-banco').textContent = state.empresa.pix_banco || 'Instituição Bancária';
    document.getElementById('cm-pix-tipo').textContent = state.empresa.pix_tipo || 'Chave';
    document.getElementById('cm-pix-chave').textContent = state.empresa.chave_pix;

    const payload = gerarPayloadPixEMV(state.empresa.chave_pix, state.empresa.pix_favorecido, state.empresa?.cidade || 'Pouso Alegre', grandTotal, '***', state.empresa.pix_tipo);
    const cmBtnPayload = document.getElementById('cm-btn-copiar-pix-payload');
    if (cmBtnPayload) {
      cmBtnPayload.onclick = () => {
        copiarParaClipboard(payload, 'Pix Copia e Cola copiado com sucesso!');
      };
    }
  } else if (pixBox) {
    pixBox.style.display = 'none';
  }

  modal.classList.add('open');
}

function gerarTextoResumoPedido() {
  const empresaNome = state.empresa?.nomeFantasia || state.empresa?.razaoSocial || 'FinCore Food';
  const clienteNome = document.getElementById('checkout-nome-cliente')?.value.trim() || state.profile?.nome || 'Cliente';
  const clientePhone = formatPhone(document.getElementById('checkout-phone-cliente')?.value.trim() || state.profile?.whatsapp || '');

  const data = document.getElementById('checkout-data')?.value || '';
  const hora = document.getElementById('checkout-hora')?.value || '';
  const dataFmt = data ? data.split('-').reverse().join('/') : 'A combinar';
  const horaFmt = hora || 'A combinar';

  const logr = document.getElementById('checkout-logradouro')?.value.trim() || state.profile?.logradouro || '';
  const num = document.getElementById('checkout-numero')?.value.trim() || state.profile?.numero || '';
  const bair = document.getElementById('checkout-bairro')?.value.trim() || state.profile?.bairro || '';
  const cid = document.getElementById('checkout-cidade')?.value.trim() || state.profile?.cidade || '';
  const fullAddress = `${logr}, ${num} - ${bair}, ${cid}`;

  const obs = document.getElementById('checkout-obs')?.value.trim() || '';
  const subtotal = cartTotal();
  const taxaEntrega = (state.tipoLogistica === 'Entrega') ? (state.taxaEntregaCentavos || 0) : 0;
  const grandTotal = subtotal + taxaEntrega;

  let txt = `*📋 RESUMO DO PEDIDO - ${empresaNome.toUpperCase()}*\n`;
  txt += `━━━━━━━━━━━━━━━━━━━━━\n`;
  txt += `👤 *Cliente:* ${clienteNome}\n`;
  if (clientePhone) txt += `📱 *Telefone/WhatsApp:* ${clientePhone}\n`;
  txt += `🚚 *Modalidade:* ${state.tipoLogistica}\n`;
  if (state.tipoLogistica === 'Entrega') {
    txt += `📍 *Endereço:* ${fullAddress}\n`;
  }
  txt += `📅 *Previsão/Agendamento:* ${dataFmt} às ${horaFmt}\n`;
  txt += `💳 *Forma de Pagamento:* ${state.formaPagamentoNome}\n`;

  if (obs) {
    txt += `📝 *Observações:* ${obs}\n`;
  }

  txt += `━━━━━━━━━━━━━━━━━━━━━\n`;
  txt += `🛒 *ITENS DO PEDIDO:*\n`;
  state.cart.forEach((item, index) => {
    const precoUnit = getPreco(item.produto);
    const itemTotal = precoUnit * item.qty;
    txt += `${index + 1}. *${item.qty}x* ${item.produto.nome} (${fmt(precoUnit)} un) = *${fmt(itemTotal)}*\n`;
  });

  txt += `━━━━━━━━━━━━━━━━━━━━━\n`;
  txt += `💵 *Subtotal dos Itens:* ${fmt(subtotal)}\n`;
  txt += `🛵 *Taxa de Entrega:* ${taxaEntrega > 0 ? fmt(taxaEntrega) : (state.tipoLogistica === 'Retirada' ? 'Grátis (Balcão)' : 'Grátis')}\n`;
  txt += `💰 *TOTAL A PAGAR: ${fmt(grandTotal)}*\n`;

  if (state.formaPagamentoNome === 'Pix' && state.empresa?.chave_pix) {
    txt += `━━━━━━━━━━━━━━━━━━━━━\n`;
    txt += `⚡ *DADOS PARA PAGAMENTO PIX:*\n`;
    txt += `• *Favorecido:* ${state.empresa.pix_favorecido || empresaNome}\n`;
    if (state.empresa.pix_banco) txt += `• *Banco:* ${state.empresa.pix_banco}\n`;
    txt += `• *Chave Pix (${state.empresa.pix_tipo || 'Chave'}):* ${state.empresa.chave_pix}\n`;
  }

  return txt;
}

async function submeterPedidoAoBanco() {
  const isLogged = !!(state.session?.user || (state.profile && state.profile.id));
  if (!isLogged) {
    toast('🔐 Sua sessão expirou. Faça login para enviar seu pedido.', 'error', 4000);
    state.redirectAfterAuth = 'screen-checkout';
    showScreen('screen-auth');
    return;
  }

  const btnFinal = document.getElementById('cm-btn-confirm-final');
  if (btnFinal) {
    btnFinal.disabled = true;
    btnFinal.textContent = '⏳ Enviando Pedido...';
  }

  try {
    const data = document.getElementById('checkout-data').value;
    const hora = document.getElementById('checkout-hora').value;
    const obs = document.getElementById('checkout-obs').value.trim();
    const subtotal = cartTotal();

    // Validação estrita de Horários e Prazo Mínimo
    const schedVal = validateOrderSchedule(data, hora);
    if (!schedVal.valid) {
      throw new Error(schedVal.message);
    }

    const nome  = document.getElementById('checkout-nome-cliente')?.value.trim() || state.profile?.nome || 'Cliente';
    const phone = document.getElementById('checkout-phone-cliente')?.value.trim() || state.profile?.whatsapp || '';

    const cep   = document.getElementById('checkout-cep')?.value.trim() || state.profile?.cep || '';
    const logr  = document.getElementById('checkout-logradouro')?.value.trim() || state.profile?.logradouro || '';
    const num   = document.getElementById('checkout-numero')?.value.trim() || state.profile?.numero || '';
    const bair  = document.getElementById('checkout-bairro')?.value.trim() || state.profile?.bairro || '';
    const cid   = document.getElementById('checkout-cidade')?.value.trim() || state.profile?.cidade || '';
    const uf    = document.getElementById('checkout-uf')?.value.trim() || state.profile?.uf || 'SP';
    const comp  = document.getElementById('checkout-complemento')?.value.trim() || state.profile?.complemento || '';
    const ref   = document.getElementById('checkout-referencia')?.value.trim() || state.profile?.referencia || '';

    // Sincronizar Cliente e Endereço automaticamente no cadastro do ERP
    let erpCliente = null;
    try {
      erpCliente = await syncCustomerToErp({
        nome,
        telefone: phone,
        email: state.profile?.email || null,
        logradouro: logr,
        numero: num,
        bairro: bair,
        cidade: cid,
        cep: cep,
        complemento: comp,
        referencia: ref,
        tenantId: state.tenantId || DEFAULT_TENANT_ID
      });
    } catch (e) {
      console.warn('Aviso ao sincronizar cliente com ERP:', e.message);
    }

    // Atualiza endereço padrão no cadastro do cliente se logado
    if (state.profile?.id && logr && num) {
      try {
        const fullAddr = [
          `${logr}, ${num}`,
          comp ? `(${comp})` : '',
          bair,
          `${cid} - ${uf}`,
          cep ? `CEP: ${cep}` : ''
        ].filter(Boolean).join(' - ');
        
        sb.from('cardapio_clientes').update({
          logradouro: logr,
          numero: num,
          bairro: bair,
          cidade: cid,
          uf: uf,
          cep: cep,
          complemento: comp || null,
          referencia: ref || null,
          endereco_padrao: fullAddr
        }).eq('id', state.profile.id).then();
      } catch (_) {}
    }

    const fullAddressStr = [
      `${logr}, ${num}`,
      comp ? `(${comp})` : '',
      bair,
      `${cid} - ${uf}`,
      cep ? `CEP: ${cep}` : ''
    ].filter(Boolean).join(' - ');

    const taxaEntrega = (state.tipoLogistica === 'Entrega') ? (state.taxaEntregaCentavos || 0) : 0;
    const totalFinal = subtotal + taxaEntrega;

    const enderecoObj = {
      cep: cep || '',
      logradouro: logr || '',
      numero: num || '',
      bairro: bair || '',
      cidade: cid || '',
      uf: uf || 'SP',
      complemento: comp || '',
      referencia: ref || '',
      formatado: fullAddressStr,
      taxaEntregaCentavos: taxaEntrega,
      latitude: state.entregaMetadata?.latitude || null,
      longitude: state.entregaMetadata?.longitude || null,
      distanciaKm: state.entregaMetadata?.distanciaKm || null,
      tempoEstimadoMinutos: state.entregaMetadata?.tempoMinutos || null,
      metodoCalculoEntrega: state.entregaMetadata?.metodoCalculo || null,
      regraEntregaAplicada: state.entregaMetadata?.regraAplicada || null
    };

    let dataEntrega = null;
    if (data && hora) {
      dataEntrega = new Date(`${data}T${hora}:00`).toISOString();
    }

    let trocoCentavos = null;
    if (state.formaPagamentoPermiteTroco || state.formaPagamentoNome === 'Dinheiro') {
      const trocoVal = document.getElementById('checkout-troco')?.value.trim();
      if (trocoVal) {
        const n = parseFloat(trocoVal.replace(',', '.').replace(/[^\d.]/g, ''));
        if (!isNaN(n) && n > 0) {
          trocoCentavos = Math.round(n * 100);
          if (trocoCentavos < totalFinal) {
            toast(`O valor informado para o troco (${fmt(trocoCentavos)}) não pode ser menor que o total do pedido (${fmt(totalFinal)}).`, 'error', 5000);
            document.getElementById('checkout-troco')?.focus();
            if (btnFinal) {
              btnFinal.disabled = false;
              btnFinal.textContent = '🚀 Confirmar e Enviar Pedido';
            }
            return;
          }
        }
      }
    }

    const agora    = new Date().toISOString();
    const pedidoId = crypto.randomUUID();

    // Obter próximo numeroPedido
    let nextNumPed = 1;
    try {
      const { data: maxRows } = await sb
        .from('pedido')
        .select('numeroPedido')
        .eq('tenantId', state.tenantId || DEFAULT_TENANT_ID)
        .order('numeroPedido', { ascending: false })
        .limit(1);

      if (maxRows && maxRows.length > 0 && maxRows[0].numeroPedido) {
        nextNumPed = maxRows[0].numeroPedido + 1;
      }
    } catch (_) {}

    // Salvar ID do pedido no localStorage para acompanhamento mesmo de usuários avulsos/convidados
    localStorage.setItem('fincore_last_order_id', pedidoId);

    const userIdValid = state.session?.user?.id || state.profile?.user_id;
    if (!userIdValid || !userIdValid.includes('-')) {
      throw new Error('Sua conta precisa estar conectada para enviar o pedido. Faça login novamente.');
    }

    // Vincula diretamente ao ID do Cliente no ERP (tabela 'cliente')
    const targetClienteLocalId = erpCliente?.id || state.profile?.cliente_local_id || null;
    const finalClienteNome = erpCliente?.nome || state.profile?.nome || nome;
    const finalClienteTelefone = state.profile?.whatsapp ? formatPhone(state.profile.whatsapp) : (erpCliente?.telefone ? formatPhone(erpCliente.telefone) : (formatPhone(phone) || null));

    // 1. Inserir na tabela 'pedido' com status 'pendente' (Aguardando aprovação do responsável)
    const pedidoPayload = {
      id:                         pedidoId,
      tenantId:                   state.tenantId || DEFAULT_TENANT_ID,
      createdAt:                  agora,
      updatedAt:                  agora,
      createdBy:                  userIdValid,
      updatedBy:                  userIdValid,
      syncVersion:                1,
      status:                     'pendente',
      tipoLogistica:              state.tipoLogistica,
      clienteId:                  targetClienteLocalId,
      clienteNomeAvulso:         finalClienteNome,
      clienteTelefoneAvulso:     finalClienteTelefone,
      valorSubtotalCentavos:     subtotal,
      valorTaxaEntregaCentavos:  taxaEntrega,
      valorTotalCentavos:        totalFinal,
      trocoParaCentavos:         trocoCentavos,
      formaPagamentoId:          state.formaPagamentoId || null,
      formaPagamentoNome:        state.formaPagamentoNome,
      canalOrigem:                'cardapio_web',
      dataHoraCriacao:           agora,
      dataHoraEntregaPrevista:   dataEntrega,
      observacoes:               obs || null,
      enderecoJson:              state.tipoLogistica === 'Entrega' ? JSON.stringify(enderecoObj) : null,
      numeroPedido:               nextNumPed,
    };

    const { error: pedErr } = await sb.from('pedido').insert(pedidoPayload);
    if (pedErr) throw pedErr;

    // 2. Inserir na tabela 'item_pedido'
    try {
      const itens = state.cart.map(item => ({
        id:                    crypto.randomUUID(),
        pedidoId:              pedidoId,
        produtoId:             item.produto.id,
        nomeProduto:           item.produto.nome,
        quantidade:            Number(item.qty),
        valorUnitarioCentavos: getPreco(item.produto),
        valorTotalCentavos:    getPreco(item.produto) * item.qty,
        observacoes:           null,
        tenantId:              state.tenantId || DEFAULT_TENANT_ID,
        createdAt:             agora,
        updatedAt:             agora,
        createdBy:             userIdValid,
        updatedBy:             userIdValid,
        syncVersion:           1,
      }));
      await sb.from('item_pedido').insert(itens);
    } catch (e) {
      console.warn('Erro em item_pedido:', e.message);
    }

    // 3. Inserir na tabela 'ordens_preparo' (KDS da Cozinha / Kanban) com status 'pendente'
    const ordemId = crypto.randomUUID();
    try {
      let pagDesc = state.formaPagamentoNome;
      if (state.formaPagamentoNome === 'Dinheiro' && trocoCentavos) {
        pagDesc += ` (Troco p/ ${fmt(trocoCentavos)})`;
      }

      let dataAgendadaTag = '';
      if (data && hora) {
        const [yyyy, mm, dd] = data.split('-');
        dataAgendadaTag = `agendado: ${dd}/${mm}/${yyyy} ${hora}`;
      }

      const totalUnidades = state.cart.reduce((sum, item) => sum + item.qty, 0);

      const obsTags = [
        `[DADOS_PEDIDO]`,
        `cliente: ${finalClienteNome || state.profile?.nome || 'Consumidor'}`,
        `telefone: ${state.profile?.whatsapp ? state.profile.whatsapp.replace(/\\D/g, '') : ''}`,
        `tipo: ${state.tipoLogistica}`,
        `pagamento: ${pagDesc}`,
        `total: ${totalFinal}`,
        `unidades: ${totalUnidades}`,
        state.tipoLogistica === 'Entrega' ? `endereco: ${logr ? `${logr}, ${num}` : ''}` : '',
        state.tipoLogistica === 'Entrega' && bair ? `bairro: ${bair}` : '',
        dataAgendadaTag,
        obs ? `obs: ${obs}` : '',
        `[/DADOS_PEDIDO]`
      ].filter(Boolean).join('\n');

      const ordemPayload = {
        id:                    ordemId,
        tenantId:              state.tenantId || DEFAULT_TENANT_ID,
        pedidoId:              pedidoId,
        itensJson:             JSON.stringify(state.cart.map(item => ({
          produtoId:   item.produto.id,
          nomeProduto: item.produto.nome,
          quantidade:  Number(item.qty),
          unidade:     item.produto.unidadeVenda || 'un',
          observacoes: null
        }))),
        status:                'pendente',
        prioridade:            dataAgendadaTag ? 'programado' : 'normal',
        criadaEm:              agora,
        createdAt:             agora,
        updatedAt:             agora,
        tempoEstimadoSegundos: 1800,
        observacoes:           obsTags,
        createdBy:             userIdValid,
        updatedBy:             userIdValid,
        syncVersion:           1,
      };

      const { error: ordErr } = await sb.from('ordens_preparo').insert(ordemPayload);
      if (ordErr) {
        console.error('Erro ao inserir ordem_preparo no Supabase:', ordErr);
      }

      // 4. Inserir histórico de auditoria na tabela 'historicos_ordem_preparo'
      try {
        const histPayload = {
          id:             crypto.randomUUID(),
          tenantId:       state.tenantId || DEFAULT_TENANT_ID,
          ordemPreparoId: ordemId,
          titulo:         'Pedido Recebido via Cardápio Web',
          descricao:      'Pedido enviado online pelo cliente. Aguardando aprovação e conferência de horário pelo responsável.',
          operadorNome:   state.profile?.nome || 'Cliente Web',
          criadaEm:       agora,
          versao:         '1.0',
          createdAt:      agora,
          updatedAt:      agora,
          createdBy:      userIdValid,
          updatedBy:      userIdValid,
          syncVersion:    1,
        };
        await sb.from('historicos_ordem_preparo').insert(histPayload);
      } catch (eHist) {
        console.warn('Erro ao inserir historicos_ordem_preparo:', eHist.message);
      }
    } catch (e) {
      console.error('Erro em ordens_preparo:', e.message);
    }

    state.currentOrder = { ...pedidoPayload, items: [...state.cart] };
    clearCart();

    document.getElementById('modal-confirm-checkout')?.classList.remove('open');
    renderConfirmationPage(state.currentOrder);
    showScreen('screen-confirmation');
    toast('📋 Pedido enviado com sucesso! Aguarde a aprovação do estabelecimento.', 'success', 5000);

    // Recarrega pedidos do cliente em background
    loadCustomerOrders();
  } catch (err) {
    toast('Erro ao realizar pedido: ' + err.message, 'error', 5000);
    console.error(err);
  } finally {
    if (btnFinal) {
      btnFinal.disabled = false;
      btnFinal.textContent = '🚀 Confirmar e Enviar Pedido';
    }
  }
}

function renderConfirmationPage(order) {
  if (!order) return;

  const numEl = document.getElementById('confirm-order-number');
  const dateEl = document.getElementById('confirm-order-date-text');
  const totalEl = document.getElementById('confirm-order-total-text');
  const pixContainer = document.getElementById('confirm-pix-container');

  if (numEl) numEl.textContent = `#${order.numeroPedido || order.id.slice(0, 6)}`;
  if (dateEl) dateEl.textContent = order.dataHoraEntregaPrevista ? fmtDateTime(order.dataHoraEntregaPrevista) : 'Em preparação';
  if (totalEl) totalEl.textContent = fmt(order.valorTotalCentavos);

  // Renderizar Pix se selecionado
  const isPix = String(order.formaPagamentoNome || '').toLowerCase().includes('pix');
  if (isPix && pixContainer) {
    const chave = state.empresa?.chave_pix || '';
    const favorecido = state.empresa?.pix_favorecido || state.empresa?.nomeFantasia || state.empresa?.razaoSocial || 'FinCore Food';
    const banco = state.empresa?.pix_banco || 'Instituição Bancária';
    const tipo = state.empresa?.pix_tipo || 'Chave';

    if (chave) {
      pixContainer.style.display = 'block';
      document.getElementById('confirm-pix-favorecido').textContent = favorecido;
      document.getElementById('confirm-pix-banco').textContent = banco;
      document.getElementById('confirm-pix-tipo').textContent = tipo;
      document.getElementById('confirm-pix-chave-raw').textContent = chave;
      document.getElementById('confirm-pix-valor').textContent = fmt(order.valorTotalCentavos);

      const payload = gerarPayloadPixEMV(chave, favorecido, state.empresa?.cidade || 'Pouso Alegre', order.valorTotalCentavos, order.numeroPedido || '***', tipo);

      document.getElementById('btn-confirm-copiar-pix-payload')?.setAttribute('onclick', '');
      const btnPayload = document.getElementById('btn-confirm-copiar-pix-payload');
      if (btnPayload) {
        btnPayload.onclick = () => {
          copiarParaClipboard(payload, 'Pix Copia e Cola copiado com sucesso! Cole no app do seu banco.');
        };
      }

      const btnChave = document.getElementById('btn-confirm-copiar-pix');
      if (btnChave) {
        btnChave.onclick = () => {
          copiarParaClipboard(chave, 'Chave Pix copiada com sucesso!');
        };
      }
    } else {
      pixContainer.style.display = 'none';
    }
  }

  // Ações de compartilhamento de link direto e WhatsApp da loja
  const trackUrl = `${window.location.origin}${window.location.pathname}?p=${order.id}`;
  const copyLinkBtn = document.getElementById('btn-confirm-copy-link');
  if (copyLinkBtn) {
    copyLinkBtn.onclick = () => {
      copiarParaClipboard(trackUrl, 'Link de rastreio direto copiado!');
    };
  }

  const waBtn = document.getElementById('btn-confirm-whatsapp-store');
  const storePhoneClean = getEmpresaWhatsAppClean();
  if (waBtn && storePhoneClean) {
    const num = order.numeroPedido || order.id.slice(0, 6);
    const msg = `Olá! Acabei de enviar o pedido #${num} no valor de ${fmt(order.valorTotalCentavos)}. Segue meu link de acompanhamento: ${trackUrl}`;
    waBtn.href = `https://wa.me/${storePhoneClean}?text=${encodeURIComponent(msg)}`;
    waBtn.style.display = 'inline-flex';
  } else if (waBtn) {
    waBtn.style.display = 'none';
  }

  const subEl = document.getElementById('confirm-subtitle');
  const rawSt = String(order.status || 'pendente').toLowerCase().trim();
  if (subEl) {
    if (rawSt === 'pendente' || rawSt === 'aguardando_aprovacao') {
      subEl.innerHTML = 'Recebemos sua solicitação! Seu pedido está <strong>aguardando confirmação da loja</strong>.';
    } else if (rawSt === 'confirmado' || rawSt === 'recebido' || rawSt === 'aprovado') {
      subEl.innerHTML = 'Pedido <strong>confirmado pela loja</strong>! Já foi encaminhado para a fila de preparo.';
    } else if (rawSt.includes('prepar')) {
      subEl.innerHTML = 'Seu pedido está sendo <strong>preparado na cozinha</strong>!';
    } else if (rawSt.includes('pronto')) {
      subEl.innerHTML = 'Seu pedido está <strong>pronto</strong>!';
    } else if (rawSt.includes('entrega') || rawSt.includes('caminho')) {
      subEl.innerHTML = 'Seu pedido está <strong>a caminho da entrega</strong>!';
    } else if (rawSt === 'entregue' || rawSt === 'concluido') {
      subEl.innerHTML = 'Pedido <strong>entregue</strong> com sucesso! Bom apetite!';
    }
  }

  renderTimeline(order.status || 'pendente');
}

function renderTimeline(status) {
  const container = document.getElementById('status-timeline');
  if (!container) return;

  const steps = [
    { key: 'pendente',     label: 'Aguardando Confirmação' },
    { key: 'confirmado',   label: 'Confirmado pela Loja' },
    { key: 'em_preparo',   label: 'Em Preparo' },
    { key: 'pronto',       label: 'Pronto / A Caminho' },
    { key: 'entregue',     label: 'Entregue' }
  ];

  const getIdx = (st) => {
    const s = String(st || '').toLowerCase().trim();
    if (s === 'pendente' || s === 'aguardando_aprovacao' || s === 'rascunho') return 0;
    if (s === 'recebido' || s === 'confirmado' || s === 'aprovado') return 1;
    if (s === 'em_preparo' || s === 'empreparo' || s === 'preparando') return 2;
    if (s === 'pronto' || s === 'aguardando_retirada' || s === 'saiu_para_entrega' || s === 'saiuparaentrega' || s === 'saiu_entrega' || s === 'em_entrega' || s === 'em_transito' || s === 'a_caminho') return 3;
    if (s === 'entregue' || s === 'concluido' || s === 'finalizado') return 4;
    return 0;
  };

  const currentIndex = getIdx(status);

  container.innerHTML = steps.map((step, idx) => {
    let stateClass = '';
    if (idx < currentIndex) stateClass = 'done';
    else if (idx === currentIndex) stateClass = 'current';

    return `
      <div class="timeline-step ${stateClass}">
        <div class="timeline-dot">${idx < currentIndex ? '✓' : idx + 1}</div>
        <span class="timeline-label">${step.label}</span>
      </div>
    `;
  }).join('');
}

// ─── TELA 4: MEUS PEDIDOS & ENCOMENDAS ────────────────────────────────
async function loadCustomerOrders(showSpinner = true) {
  const container = document.getElementById('orders-list');
  const emptyState = document.getElementById('orders-empty');

  // Recupera lastOrderId caso exista para fallback imediato
  const lastOrderId = localStorage.getItem('fincore_last_order_id');

  if (!state.session && !state.profile) {
    if (lastOrderId) {
      try {
        const { data: lastOrder } = await sb
          .from('pedido')
          .select('*, item_pedido(*)')
          .eq('id', lastOrderId)
          .maybeSingle();

        if (lastOrder) {
          state.customerOrders = [lastOrder];
          renderOrdersList();
          renderActiveOrderWidget();
          return;
        }
      } catch (_) {}
    }

    if (container) container.innerHTML = '';
    if (emptyState) emptyState.style.display = 'flex';
    return;
  }

  if (showSpinner) showLoading(true, 'Carregando seus pedidos...');

  try {
    const rawPhone = state.profile?.whatsapp ? state.profile.whatsapp.replace(/\D/g, '') : null;
    const formattedPhone = rawPhone ? formatPhone(rawPhone) : null;
    const clientLocalId = state.profile?.cliente_local_id;
    const profileId = state.profile?.id;
    const userId = state.session?.user?.id;

    const orClauses = [];
    if (userId) {
      orClauses.push(`createdBy.eq.${userId}`);
    }
    if (clientLocalId) {
      orClauses.push(`clienteId.eq.${clientLocalId}`);
    }
    if (profileId && profileId !== clientLocalId) {
      orClauses.push(`clienteId.eq.${profileId}`);
    }
    if (rawPhone) {
      orClauses.push(`clienteTelefoneAvulso.eq.${rawPhone}`);
      if (formattedPhone && formattedPhone !== rawPhone) {
        orClauses.push(`clienteTelefoneAvulso.eq."${formattedPhone}"`);
      }
    }
    if (lastOrderId) {
      orClauses.push(`id.eq.${lastOrderId}`);
    }

    let query = sb
      .from('pedido')
      .select('*, item_pedido(*)')
      .eq('tenantId', state.tenantId || DEFAULT_TENANT_ID)
      .order('createdAt', { ascending: false });

    if (orClauses.length > 0) {
      query = query.or(orClauses.join(','));
    }

    const { data, error } = await query.limit(30);
    if (error) throw error;

    let orders = data || [];

    // Se o pedido recente do localStorage não veio no filtro or, busca diretamente e anexa
    if (lastOrderId && !orders.some(o => o.id === lastOrderId)) {
      try {
        const { data: directOrder } = await sb
          .from('pedido')
          .select('*, item_pedido(*)')
          .eq('id', lastOrderId)
          .maybeSingle();
        if (directOrder) {
          orders.unshift(directOrder);
        }
      } catch (_) {}
    }

    state.customerOrders = orders;
    renderOrdersList();
    renderActiveOrderWidget();

    // Se o modal de detalhes estiver aberto, atualiza o pedido aberto em tempo real
    const modal = document.getElementById('modal-order-detail');
    if (modal && modal.classList.contains('open') && state.activeOrder) {
      const updatedOrder = state.customerOrders.find(o => o.id === state.activeOrder.id);
      if (updatedOrder) {
        state.activeOrder = updatedOrder;
        openOrderDetailModal(updatedOrder);
      }
    }
  } catch (e) {
    console.warn('Erro ao carregar pedidos do cliente:', e.message);
  } finally {
    if (showSpinner) showLoading(false);
  }
}

function renderOrdersList() {
  const container = document.getElementById('orders-list');
  const emptyState = document.getElementById('orders-empty');

  if (!container) return;

  let filtered = [...state.customerOrders];
  const now = new Date();

  if (state.activeOrderFilter === 'em_andamento') {
    filtered = filtered.filter(o => {
      const st = String(o.status || '').toLowerCase().trim();
      return st !== 'entregue' && st !== 'concluido' && st !== 'finalizado' && st !== 'cancelado';
    });
  } else if (state.activeOrderFilter === 'agendados') {
    filtered = filtered.filter(o => {
      if (o.status === 'cancelado' || o.status === 'concluido' || o.status === 'entregue' || o.status === 'finalizado') return false;
      if (!o.dataHoraEntregaPrevista) return false;
      return new Date(o.dataHoraEntregaPrevista) >= now;
    });
  } else if (state.activeOrderFilter === 'concluido') {
    filtered = filtered.filter(o => o.status === 'concluido' || o.status === 'entregue' || o.status === 'finalizado');
  } else if (state.activeOrderFilter === 'cancelado') {
    filtered = filtered.filter(o => o.status === 'cancelado');
  }

  if (filtered.length === 0) {
    container.innerHTML = '';
    if (emptyState) emptyState.style.display = 'flex';
  } else {
    if (emptyState) emptyState.style.display = 'none';

    container.innerHTML = filtered.map(order => {
      const items = order.item_pedido || [];
      const itemsSummary = items.map(i => `${i.quantidade}x ${i.nomeProduto}`).join(', ') || 'Itens diversos';

      // Mapeamento canônico: status operacional do Kanban
      const STATUS_CLIENTE = {
        pendente:            '⏳ Aguardando Confirmação',
        aguardando_aprovacao:'⏳ Aguardando Confirmação',
        recebido:            '✅ Confirmado pela Loja',
        confirmado:          '✅ Confirmado pela Loja',
        aprovado:            '✅ Confirmado pela Loja',
        em_preparo:          '🍳 Em Preparação',
        empreparo:           '🍳 Em Preparação',
        pronto:              '📦 Pronto',
        aguardando_retirada: '📦 Pronto para Retirada',
        saiu_entrega:        '🛵 Saiu para Entrega',
        em_entrega:          '🛵 Saiu para Entrega',
        a_caminho:           '🛵 A Caminho',
        concluido:           '✅ Entregue',
        entregue:            '✅ Entregue',
        finalizado:          '✅ Entregue',
        cancelado:           '❌ Cancelado',
      };

      const dateLabel = order.dataHoraEntregaPrevista
        ? `Previsão: ${fmtDateTime(order.dataHoraEntregaPrevista)}`
        : `Criado em: ${fmtDateTime(order.createdAt)}`;

      return `
        <div class="order-history-card">
          <div class="order-card-top">
            <span class="order-card-num">Pedido #${order.numeroPedido || order.id.slice(0, 6)}</span>
            <span class="order-status-pill status-${order.status}">${STATUS_CLIENTE[order.status] || order.status}</span>
          </div>
          <div style="font-size:12px;color:var(--text-muted)">
            📅 ${dateLabel} • ${order.tipoLogistica} • ${order.formaPagamentoNome || 'Pix'}
          </div>
          <div class="order-card-items-preview">
            🛒 ${itemsSummary}
          </div>
          <div class="order-card-footer">
            <span class="order-card-total">${fmt(order.valorTotalCentavos)}</span>
            <div class="order-card-actions">
              <button type="button" class="btn btn-secondary btn-sm btn-order-track" data-id="${order.id}">
                🔍 Detalhes
              </button>
              <button type="button" class="btn btn-primary btn-sm btn-order-reorder" data-id="${order.id}">
                🔁 Repetir
              </button>
            </div>
          </div>
        </div>
      `;
    }).join('');

    container.querySelectorAll('.btn-order-track').forEach(b => {
      b.addEventListener('click', () => {
        const order = state.customerOrders.find(o => o.id === b.dataset.id);
        if (order) openOrderDetailModal(order);
      });
    });

    container.querySelectorAll('.btn-order-reorder').forEach(b => {
      b.addEventListener('click', () => {
        reorderOrder(b.dataset.id);
      });
    });
  }
}

// ─── Funcionalidade "Comprar Novamente" Inteligente (Revalidação de Catálogo) ──
async function reorderOrder(orderId) {
  showLoading(true, 'Verificando disponibilidade e preços dos itens...');

  try {
    let order = state.customerOrders.find(o => o.id === orderId);
    let items = order?.item_pedido;

    if (!items || items.length === 0) {
      const { data: dbItems } = await sb.from('item_pedido').select('*').eq('pedidoId', orderId);
      items = dbItems || [];
    }

    if (items.length === 0) {
      toast('Não foi possível recuperar os itens deste pedido anterior.', 'error');
      return;
    }

    // Garante que o catálogo mais recente esteja em memória
    if (!state.produtos || state.produtos.length === 0) {
      await loadCatalog();
    }

    const validItems = [];
    const discontinued = [];

    for (const item of items) {
      const currentProd = state.produtos.find(p => p.id === item.produtoId);
      if (!currentProd || currentProd.ativo === false || currentProd.status_comercial === 'indisponivel') {
        discontinued.push(item.nomeProduto || 'Item');
      } else {
        validItems.push({
          produto: currentProd,
          qty: Number(item.quantidade) || 1
        });
      }
    }

    if (validItems.length === 0) {
      toast('Infelizmente todos os itens deste pedido foram descontinuados.', 'error', 5000);
      return;
    }

    state.cart = validItems;
    saveCart();
    updateCartBar();
    showScreen('screen-checkout');

    if (discontinued.length > 0) {
      toast(`Itens indisponíveis foram removidos: ${discontinued.join(', ')}. Os itens disponíveis foram adicionados com os preços vigentes!`, 'info', 6000);
    } else {
      toast('🎉 Itens carregados no pedido com os preços e condições vigentes!', 'success', 4000);
    }
  } catch (err) {
    toast('Erro ao repetir pedido: ' + err.message, 'error');
  } finally {
    showLoading(false);
  }
}

function openOrderDetailModal(order) {
  const modal = document.getElementById('modal-order-detail');
  if (!modal || !order) return;

  state.activeOrder = order;
  if (order.id) {
    localStorage.setItem('fincore_last_order_id', order.id);
    if (!state.customerOrders.some(o => o.id === order.id)) {
      state.customerOrders.unshift(order);
      renderOrdersList();
      renderActiveOrderWidget();
    }
  }

  const st = String(order.status || 'pendente').toLowerCase().trim();
  const STATUS_MODAL_LABELS = {
    pendente:            { label: '⏳ Aguardando Confirmação', icon: '⏳' },
    aguardando_aprovacao:{ label: '⏳ Aguardando Confirmação', icon: '⏳' },
    recebido:            { label: '✅ Confirmado pela Loja',   icon: '✅' },
    confirmado:          { label: '✅ Confirmado pela Loja',   icon: '✅' },
    aprovado:            { label: '✅ Confirmado pela Loja',   icon: '✅' },
    em_preparo:          { label: '🍳 Em Preparação',          icon: '🍳' },
    empreparo:           { label: '🍳 Em Preparação',          icon: '🍳' },
    pronto:              { label: '📦 Pronto',                 icon: '📦' },
    aguardando_retirada: { label: '📦 Pronto para Retirada',   icon: '📦' },
    saiu_entrega:        { label: '🛵 Saiu para Entrega',      icon: '🛵' },
    em_entrega:          { label: '🛵 Saiu para Entrega',      icon: '🛵' },
    a_caminho:           { label: '🛵 A Caminho',              icon: '🛵' },
    concluido:           { label: '✅ Entregue',               icon: '✅' },
    entregue:            { label: '✅ Entregue',               icon: '✅' },
    finalizado:          { label: '✅ Entregue',               icon: '✅' },
    cancelado:           { label: '❌ Cancelado',              icon: '❌' },
  };
  const isCancelado = st === 'cancelado';
  const statusInfo = STATUS_MODAL_LABELS[st] || { label: order.status || 'Pendente', icon: '⚡' };

  const headerSub = document.getElementById('detail-modal-header-subtitle');
  if (headerSub) {
    headerSub.textContent = isCancelado ? 'Aviso sobre o Pedido' : 'Acompanhamento do Pedido';
  }

  document.getElementById('detail-order-number').textContent = `#${order.numeroPedido || order.id.slice(0, 6)}`;
  document.getElementById('detail-order-date').textContent = getDeliveryDateTime(order);
  document.getElementById('detail-order-logistics').textContent = order.tipoLogistica;
  document.getElementById('detail-order-payment').textContent = order.formaPagamentoNome || 'Pix';
  document.getElementById('detail-order-total').textContent = fmt(order.valorTotalCentavos);

  const badgeEl = document.getElementById('detail-status-badge');
  if (badgeEl) {
    badgeEl.textContent = statusInfo.label;
    badgeEl.className = `order-status-pill status-${st}`;
  }

  // Banner e Motivo do Cancelamento
  const cancelledBanner = document.getElementById('detail-cancelled-banner');
  const cancelledReasonBox = document.getElementById('detail-cancelled-reason');
  const cancelledReasonText = document.getElementById('detail-cancelled-reason-text');

  if (cancelledBanner) {
    if (isCancelado) {
      cancelledBanner.style.display = 'block';
      const motivo = (order.motivo_cancelamento || order.motivoCancelamento || order.observacoes || '').trim();
      if (motivo && motivo.toLowerCase() !== 'sem observações' && motivo.toLowerCase() !== 'sem observacoes') {
        if (cancelledReasonBox) cancelledReasonBox.style.display = 'block';
        if (cancelledReasonText) cancelledReasonText.textContent = motivo;
      } else {
        if (cancelledReasonBox) cancelledReasonBox.style.display = 'none';
      }
    } else {
      cancelledBanner.style.display = 'none';
    }
  }

  // Controle de visibilidade de linhas para pedidos cancelados
  const dateRow = document.getElementById('detail-order-date-row');
  if (dateRow) {
    dateRow.style.display = isCancelado ? 'none' : 'flex';
  }
  const paymentRow = document.getElementById('detail-order-payment-row');
  if (paymentRow) {
    paymentRow.style.display = isCancelado ? 'none' : 'flex';
  }

  // Endereço
  const addrCont = document.getElementById('detail-address-container');
  if (order.enderecoJson && addrCont) {
    try {
      const end = typeof order.enderecoJson === 'string' ? JSON.parse(order.enderecoJson) : order.enderecoJson;
      addrCont.style.display = 'block';
      document.getElementById('detail-order-address').textContent = end.formatado || `${end.logradouro}, ${end.numero} - ${end.bairro}`;
    } catch (_) {}
  } else if (addrCont) {
    addrCont.style.display = 'none';
  }

  // Itens
  const itemsList = document.getElementById('detail-items-list');
  const items = order.item_pedido || [];
  if (itemsList) {
    itemsList.innerHTML = items.map(i => `
      <div style="display:flex;justify-content:space-between;font-size:13px;padding:4px 0;border-bottom:1px solid rgba(255,255,255,0.05)">
        <span>${i.quantidade}x ${i.nomeProduto}</span>
        <strong>${fmt(i.valorTotalCentavos)}</strong>
      </div>
    `).join('');
  }

  // Timeline (ocultada se o pedido estiver cancelado)
  const timelineEl = document.getElementById('detail-status-timeline');
  if (timelineEl) {
    if (isCancelado) {
      timelineEl.style.display = 'none';
    } else {
      timelineEl.style.display = 'flex';
      const steps = [
        { key: 'pendente',     label: 'Aguardando Aprovação' },
        { key: 'confirmado',   label: 'Aprovado / Na Fila' },
        { key: 'em_preparo',   label: 'Em Preparo' },
        { key: 'pronto',       label: 'Pronto' },
        { key: 'entregue',     label: 'Entregue' }
      ];

      const getIdx = (stVal) => {
        const s = String(stVal || '').toLowerCase().trim();
        if (s === 'pendente' || s === 'aguardando_aprovacao' || s === 'rascunho') return 0;
        if (s === 'recebido' || s === 'confirmado' || s === 'aprovado') return 1;
        if (s === 'em_preparo' || s === 'empreparo' || s === 'preparando') return 2;
        if (s === 'pronto' || s === 'aguardando_retirada') return 3;
        if (s === 'saiu_para_entrega' || s === 'saiuparaentrega' || s === 'saiu_entrega' || s === 'em_entrega' || s === 'em_transito' || s === 'entregue' || s === 'concluido' || s === 'finalizado') return 4;
        return 0;
      };

      const currentIndex = getIdx(order.status || 'pendente');

      timelineEl.innerHTML = steps.map((step, idx) => {
        let stateClass = '';
        if (idx < currentIndex) stateClass = 'done';
        else if (idx === currentIndex) stateClass = 'current';

        return `
          <div class="timeline-step ${stateClass}">
            <div class="timeline-dot">${idx < currentIndex ? '✓' : idx + 1}</div>
            <span class="timeline-label">${step.label}</span>
          </div>
        `;
      }).join('');
    }
  }

  // Bloco Pix no Detalhe do Pedido (Apenas se pendente e NÃO cancelado)
  const pixContainer = document.getElementById('detail-pix-container');
  if (pixContainer) {
    const isPix = String(order.formaPagamentoNome || '').toLowerCase().includes('pix');
    const chave = state.empresa?.chave_pix || '';
    const favorecido = state.empresa?.pix_favorecido || state.empresa?.nomeFantasia || 'FinCore Food';
    const isPendente = !['concluido', 'entregue', 'finalizado', 'cancelado'].includes(st);

    if (!isCancelado && isPix && chave && isPendente) {
      pixContainer.style.display = 'block';
      const pixTipoEl = document.getElementById('detail-pix-tipo');
      if (pixTipoEl) pixTipoEl.textContent = state.empresa?.pix_tipo || 'Pix';
      const pixChaveEl = document.getElementById('detail-pix-chave');
      if (pixChaveEl) pixChaveEl.textContent = chave;

      const payload = gerarPayloadPixEMV(chave, favorecido, state.empresa?.cidade || 'Pouso Alegre', order.valorTotalCentavos, order.numeroPedido || '***', state.empresa?.pix_tipo);

      const btnPayload = document.getElementById('btn-detail-copiar-pix-payload');
      if (btnPayload) {
        btnPayload.onclick = () => {
          copiarParaClipboard(payload, 'Pix Copia e Cola copiado! Cole no app do seu banco.');
        };
      }
    } else {
      pixContainer.style.display = 'none';
    }
  }

  // Banner Inteligente de Divulgação: ocultado se o pedido foi cancelado
  const canal = String(order.canalOrigem || order.canal_origem || '').toLowerCase().trim();
  const isOrigemPdv = canal !== 'cardapio_web';
  const promoBanner = document.getElementById('detail-promo-cardapio-banner');
  const reorderBtn = document.getElementById('detail-reorder-btn');

  if (promoBanner) {
    promoBanner.style.display = (!isCancelado && isOrigemPdv) ? 'block' : 'none';
    const btnExplorar = document.getElementById('btn-explorar-cardapio-online');
    if (btnExplorar) {
      btnExplorar.onclick = () => {
        modal.classList.remove('open');
        showScreen('screen-cardapio');
        toast('🍽️ Bem-vindo ao Cardápio Online! Faça seu pedido direto por aqui.', 'success', 3500);
      };
    }
  }

  if (reorderBtn) {
    reorderBtn.style.display = !isOrigemPdv ? 'inline-flex' : 'none';
    reorderBtn.onclick = () => {
      modal.classList.remove('open');
      reorderOrder(order.id);
    };
  }

  // Botões de link de rastreio e WhatsApp no Detalhe do Pedido
  const trackUrl = `${window.location.origin}${window.location.pathname}?p=${order.id}`;
  const copyDetailLinkBtn = document.getElementById('btn-detail-copy-link');
  if (copyDetailLinkBtn) {
    copyDetailLinkBtn.onclick = () => {
      copiarParaClipboard(trackUrl, 'Link de rastreio copiado!');
    };
  }

  const waDetailBtn = document.getElementById('btn-detail-whatsapp-store');
  const detailPhoneClean = getEmpresaWhatsAppClean();
  if (waDetailBtn && detailPhoneClean) {
    const num = order.numeroPedido || order.id.slice(0, 6);
    const msg = `Olá! Gostaria de informações sobre o meu pedido #${num}. Segue o link de acompanhamento: ${trackUrl}`;
    waDetailBtn.href = `https://wa.me/${detailPhoneClean}?text=${encodeURIComponent(msg)}`;
    waDetailBtn.style.display = 'inline-flex';
  } else if (waDetailBtn) {
    waDetailBtn.style.display = 'none';
  }

  modal.classList.add('open');
}

// ─── TELA 5: MINHA CONTA / PERFIL ────────────────────────────────────
function populateAccountForm() {
  const user = state.session?.user;
  const p = state.profile || {};
  const meta = user?.user_metadata || {};

  const nome = p.nome || meta.full_name || meta.name || meta.display_name || (user?.email ? user.email.split('@')[0] : '');
  const email = p.email || user?.email || '';
  const phone = p.whatsapp || user?.phone || meta.phone || '';
  const avatarUrl = meta.avatar_url || meta.picture || '';

  const nameDisplay = document.getElementById('account-user-display-name');
  const emailDisplay = document.getElementById('account-user-display-email');
  const avatarLarge = document.getElementById('account-avatar-large');

  if (nameDisplay) nameDisplay.textContent = nome || 'Minha Conta';
  if (emailDisplay) emailDisplay.textContent = email || phone || '';

  if (avatarLarge) {
    if (avatarUrl) {
      avatarLarge.innerHTML = `<img src="${avatarUrl}" alt="Avatar" style="width:100%;height:100%;border-radius:50%;object-fit:cover;" />`;
    } else if (nome) {
      avatarLarge.textContent = nome.split(' ').filter(Boolean).map(n => n[0]).join('').slice(0, 2).toUpperCase();
    } else {
      avatarLarge.textContent = '👤';
    }
  }

  const nameEl = document.getElementById('account-name');
  const phoneEl = document.getElementById('account-phone');
  const emailEl = document.getElementById('account-email');
  const cepEl = document.getElementById('account-cep');
  const ufEl = document.getElementById('account-uf');
  const logrEl = document.getElementById('account-logradouro');
  const numEl = document.getElementById('account-numero');
  const bairEl = document.getElementById('account-bairro');
  const cidEl = document.getElementById('account-cidade');
  const compEl = document.getElementById('account-complemento');
  const refEl = document.getElementById('account-referencia');

  if (nameEl) nameEl.value = nome;
  if (phoneEl) phoneEl.value = phone;
  if (emailEl) emailEl.value = email;
  if (cepEl) cepEl.value = p.cep || '';
  if (ufEl) ufEl.value = p.uf || state.empresa?.estado || 'SP';
  if (logrEl) logrEl.value = p.logradouro || '';
  if (numEl) numEl.value = p.numero || '';
  if (bairEl) bairEl.value = p.bairro || '';
  if (cidEl) cidEl.value = p.cidade || state.empresa?.cidade || '';
  if (compEl) compEl.value = p.complemento || '';
  if (refEl) refEl.value = p.referencia || '';
}

async function saveAccountChanges(e) {
  e.preventDefault();
  if (!state.session?.user) {
    toast('Você precisa estar logado para salvar.', 'error');
    return;
  }

  const nome = document.getElementById('account-name')?.value.trim();
  const phone = document.getElementById('account-phone')?.value.trim();
  const email = document.getElementById('account-email')?.value.trim();
  const cep = document.getElementById('account-cep')?.value.trim();
  const uf = document.getElementById('account-uf')?.value.trim();
  const logr = document.getElementById('account-logradouro')?.value.trim();
  const num = document.getElementById('account-numero')?.value.trim();
  const bair = document.getElementById('account-bairro')?.value.trim();
  const cid = document.getElementById('account-cidade')?.value.trim();
  const comp = document.getElementById('account-complemento')?.value.trim();
  const ref = document.getElementById('account-referencia')?.value.trim();

  // 1. Validação de Nome
  if (!nome || nome.length < 2) {
    toast('Por favor, informe seu Nome Completo.', 'error');
    document.getElementById('account-name')?.focus();
    return;
  }

  // 2. Validação Rigorosa de Telefone (conforme regra do negócio / ERP Windows)
  const phoneVal = validatePhone(phone);
  if (!phoneVal.valid) {
    toast(phoneVal.error, 'error', 5000);
    document.getElementById('account-phone')?.focus();
    return;
  }

  // 3. Validação Rigorosa de Email
  if (!isValidEmail(email)) {
    toast('Por favor, informe um e-mail válido (ex: seu@email.com).', 'error');
    document.getElementById('account-email')?.focus();
    return;
  }

  showLoading(true, 'Salvando e vinculando seu cadastro...');

  try {
    // 4. Amarração com o cadastro do sistema Windows (ERP)
    let resolvedClienteLocalId = state.profile?.cliente_local_id || null;
    let erpRes = null;
    try {
      erpRes = await syncCustomerToErp({
        nome,
        telefone: phoneVal.clean,
        email,
        logradouro: logr,
        numero: num,
        bairro: bair,
        cidade: cid,
        cep,
        complemento: comp,
        referencia: ref,
        tenantId: state.tenantId || DEFAULT_TENANT_ID
      });
      if (erpRes && erpRes.id) {
        resolvedClienteLocalId = erpRes.id;
      }
    } catch (e) {
      console.warn('Aviso ao sincronizar com ERP Windows:', e);
    }

    const fullAddress = [
      `${logr}, ${num}`,
      comp ? `(${comp})` : '',
      bair,
      `${cid} - ${uf}`,
      cep ? `CEP: ${cep}` : ''
    ].filter(Boolean).join(' - ');

    const payload = {
      user_id: state.session.user.id,
      tenant_id: state.tenantId || DEFAULT_TENANT_ID,
      nome,
      whatsapp: phoneVal.clean,
      email,
      cep,
      uf: uf || state.empresa?.estado || 'SP',
      logradouro: logr,
      numero: num,
      bairro: bair,
      cidade: cid || state.empresa?.cidade || '',
      complemento: comp || null,
      referencia: ref || null,
      endereco_padrao: fullAddress,
      cliente_local_id: resolvedClienteLocalId,
      updated_at: new Date().toISOString()
    };

    // 5. Gravação segura em cardapio_clientes sem erro de onConflict (respeitando tenant_id)
    const targetTenant = state.tenantId || DEFAULT_TENANT_ID;
    const { data: existingProf } = await sb
      .from('cardapio_clientes')
      .select('id')
      .eq('user_id', state.session.user.id)
      .eq('tenant_id', targetTenant)
      .maybeSingle();

    let savedProfile = null;
    if (existingProf && existingProf.id) {
      const { data: updData, error: updErr } = await sb
        .from('cardapio_clientes')
        .update(payload)
        .eq('id', existingProf.id)
        .select()
        .single();
      if (updErr) throw updErr;
      savedProfile = updData;
    } else {
      const { data: insData, error: insErr } = await sb
        .from('cardapio_clientes')
        .insert(payload)
        .select()
        .single();
      if (insErr) throw insErr;
      savedProfile = insData;
    }

    state.profile = savedProfile || {
      ...state.profile,
      ...payload
    };

    updateHeaderUI();
    populateAccountForm();

    if (erpRes && erpRes.id) {
      toast('✅ Dados salvos e vinculados ao cadastro do restaurante!', 'success', 4500);
    } else {
      toast('✅ Dados atualizados com sucesso!', 'success');
    }
  } catch (err) {
    console.error('Erro ao atualizar dados:', err);
    toast('Erro ao atualizar dados: ' + (err.message || 'Falha ao salvar'), 'error');
  } finally {
    showLoading(false);
  }
}

// ─── Utilitários de Validação e Consulta de CEP ──────────────────────
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  const regex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  return regex.test(email.trim());
}

async function fetchViaCep(rawCep, prefix = 'reg') {
  const clean = (rawCep || '').replace(/\D/g, '');
  if (clean.length !== 8) {
    if (clean.length > 0) toast('Informe um CEP com 8 dígitos.', 'error');
    return;
  }

  const logrEl = document.getElementById(`${prefix}-logradouro`);
  const bairEl = document.getElementById(`${prefix}-bairro`);
  const cidEl = document.getElementById(`${prefix}-cidade`);
  const ufEl = document.getElementById(`${prefix}-uf`);
  const compEl = document.getElementById(`${prefix}-complemento`);
  const numEl = document.getElementById(`${prefix}-numero`);

  const cepBtn = document.getElementById(`${prefix}-cep-btn`);
  const originalBtnText = cepBtn ? cepBtn.innerHTML : '';
  if (cepBtn) cepBtn.innerHTML = '⏳ Buscando...';

  try {
    let addressFound = null;

    // 1. Tenta ViaCEP
    try {
      const res = await fetch(`https://viacep.com.br/ws/${clean}/json/`);
      if (res.ok) {
        const data = await res.json();
        if (data && !data.erro) {
          addressFound = {
            logradouro: data.logradouro || '',
            bairro: data.bairro || '',
            cidade: data.localidade || '',
            uf: (data.uf || 'MG').toUpperCase(),
            complemento: data.complemento || ''
          };
        }
      }
    } catch (_) {}

    // 2. Se ViaCEP falhou, tenta BrasilAPI
    if (!addressFound) {
      try {
        const resB = await fetch(`https://brasilapi.com.br/api/cep/v1/${clean}`);
        if (resB.ok) {
          const dataB = await resB.json();
          if (dataB && dataB.city) {
            addressFound = {
              logradouro: dataB.street || '',
              bairro: dataB.neighborhood || '',
              cidade: dataB.city || '',
              uf: (dataB.state || 'MG').toUpperCase(),
              complemento: ''
            };
          }
        }
      } catch (_) {}
    }

    if (addressFound) {
      if (logrEl) logrEl.value = addressFound.logradouro;
      if (bairEl) bairEl.value = addressFound.bairro;
      if (cidEl) cidEl.value = addressFound.cidade;
      if (ufEl) ufEl.value = addressFound.uf;
      if (compEl && addressFound.complemento && !compEl.value) {
        compEl.value = addressFound.complemento;
      }

      toast('📍 Endereço preenchido automaticamente!', 'success');
      if (prefix === 'checkout') {
        state.routeInfo = null;
        state.destCoords = null;
        updateCheckoutTotals();
        validateCheckoutForm();
        triggerAsyncRouteCalculation();
      } else if (prefix === 'expresso') {
        updateExpressoTotals();
      }
      if (numEl) numEl.focus();
    } else {
      // 3. FALLBACK: CEP não localizado nas bases postais
      if (cidEl && !cidEl.value) cidEl.value = state.empresa?.cidade || 'Pouso Alegre';
      if (ufEl && !ufEl.value) ufEl.value = state.empresa?.estado || 'MG';

      toast('ℹ️ CEP não encontrado nos Correios. Preencha seu bairro e rua abaixo.', 'info', 4500);

      if (prefix === 'checkout') {
        state.routeInfo = null;
        state.destCoords = null;
        // Aplica a taxa de fallback imediatamente para não deixar o cliente sem cálculo
        updateCheckoutTotals();
        validateCheckoutForm();
      } else if (prefix === 'expresso') {
        updateExpressoTotals();
      }

      if (bairEl && !bairEl.value) bairEl.focus();
      else if (logrEl && !logrEl.value) logrEl.focus();
      else if (numEl) numEl.focus();
    }
  } catch (err) {
    console.warn('Erro ao consultar CEP:', err);
    if (cidEl && !cidEl.value) cidEl.value = state.empresa?.cidade || 'Pouso Alegre';
    if (ufEl && !ufEl.value) ufEl.value = state.empresa?.estado || 'MG';
    toast('Preencha seu endereço manualmente abaixo.', 'info');
    if (prefix === 'checkout') {
      updateCheckoutTotals();
      validateCheckoutForm();
    }
  } finally {
    if (cepBtn) cepBtn.innerHTML = originalBtnText;
  }
}

// ─── Autenticação com Google (Gmail OAuth) ───────────────────────────
async function loginWithGoogle() {
  showLoading(true, 'Conectando com o Google...');
  try {
    const redirectUrl = window.location.origin + window.location.pathname;
    const { data, error } = await sb.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: redirectUrl
      }
    });
    if (error) throw error;
  } catch (err) {
    console.error('Erro no login com Google:', err);
    const msg = String(err.message || '');
    if (msg.includes('provider is not enabled') || msg.includes('Unsupported provider') || msg.includes('validation_failed')) {
      toast('ℹ️ O login com Google ainda não está habilitado no Supabase. Por favor, entre ou crie sua conta com e-mail e senha abaixo.', 'warning', 6000);
      document.getElementById('login-email')?.focus();
    } else {
      toast('Erro ao autenticar com Google: ' + err.message, 'error');
    }
  } finally {
    showLoading(false);
  }
}

// ─── Autenticação Supabase (Login / Cadastro) ─────────────────────────
async function handleLogin(e) {
  e.preventDefault();
  const emailOrPhone = document.getElementById('login-email')?.value.trim();
  const password = document.getElementById('login-password')?.value;

  if (!emailOrPhone || !password) {
    toast('Preencha seu e-mail e senha para entrar.', 'error');
    return;
  }

  let emailToUse = emailOrPhone;
  if (!emailOrPhone.includes('@')) {
    const cleanPhone = emailOrPhone.replace(/\D/g, '');
    emailToUse = `user_${cleanPhone}@fincore.com`;
  } else if (!isValidEmail(emailOrPhone)) {
    toast('Por favor, informe um endereço de e-mail válido (ex: seu@gmail.com).', 'error');
    return;
  }

  showLoading(true, 'Entrando na sua conta...');
  try {
    const { data, error } = await sb.auth.signInWithPassword({
      email: emailToUse.toLowerCase(),
      password: password
    });

    if (error) throw error;

    state.session = data.session;
    await loadUserProfile();
    const nextScreen = state.redirectAfterAuth || (state.cart.length > 0 ? 'screen-checkout' : 'screen-home');
    state.redirectAfterAuth = null;
    showScreen(nextScreen);
    toast(`Bem-vindo(a), ${state.profile?.nome || 'Cliente'}! 👋`, 'success');
  } catch (err) {
    toast('Falha no login: ' + err.message, 'error');
  } finally {
    showLoading(false);
  }
}

async function handleRegister(e) {
  e.preventDefault();
  const nome = document.getElementById('reg-name')?.value.trim();
  const phone = document.getElementById('reg-whatsapp')?.value.trim();
  const email = document.getElementById('reg-email')?.value.trim().toLowerCase();
  const password = document.getElementById('reg-password')?.value;

  const cep = document.getElementById('reg-cep')?.value.trim();
  const uf = (document.getElementById('reg-uf')?.value.trim() || 'SP').toUpperCase();
  const logr = document.getElementById('reg-logradouro')?.value.trim();
  const num = document.getElementById('reg-numero')?.value.trim();
  const bair = document.getElementById('reg-bairro')?.value.trim();
  const cid = document.getElementById('reg-cidade')?.value.trim();
  const comp = document.getElementById('reg-complemento')?.value.trim();
  const ref = document.getElementById('reg-referencia')?.value.trim();

  // Verifica se o usuário já está autenticado via Google OAuth
  const isGoogleAuthUser = Boolean(state.session?.user && state.session.user.email);

  if (!nome || !phone || !email || !logr || !num) {
    toast('Preencha todos os campos obrigatórios (*)', 'error');
    return;
  }

  // Validação Rigorosa de Telefone (conforme regra do negócio / ERP Windows)
  const phoneVal = validatePhone(phone);
  if (!phoneVal.valid) {
    toast(phoneVal.error, 'error', 5000);
    document.getElementById('reg-whatsapp')?.focus();
    return;
  }

  if (!isValidEmail(email)) {
    toast('Por favor, informe um endereço de e-mail válido (ex: seu@gmail.com).', 'error');
    document.getElementById('reg-email')?.focus();
    return;
  }

  if (!isGoogleAuthUser && (!password || password.length < 6)) {
    toast('A senha deve conter no mínimo 6 caracteres.', 'error');
    document.getElementById('reg-password')?.focus();
    return;
  }

  showLoading(true, isGoogleAuthUser ? 'Salvando seus dados de entrega...' : 'Criando sua conta...');
  try {
    let userId = state.session?.user?.id;

    if (!isGoogleAuthUser) {
      // Cria usuário no Supabase Auth
      const { data: authData, error: authError } = await sb.auth.signUp({
        email: email,
        password: password
      });

      if (authError) throw authError;
      userId = authData.user?.id || crypto.randomUUID();
      state.session = authData.session;
    }

    const fullAddress = [
      `${logr}, ${num}`,
      comp ? `(${comp})` : '',
      bair,
      `${cid} - ${uf}`,
      cep ? `CEP: ${cep}` : ''
    ].filter(Boolean).join(' - ');

    const payload = {
      user_id: userId,
      tenant_id: state.tenantId || DEFAULT_TENANT_ID,
      nome,
      whatsapp: phoneVal.clean,
      email,
      cep,
      uf,
      logradouro: logr,
      numero: num,
      bairro: bair,
      cidade: cid,
      complemento: comp || null,
      referencia: ref || null,
      endereco_padrao: fullAddress,
      updated_at: new Date().toISOString()
    };

    // Gravação segura em cardapio_clientes sem erro de onConflict (respeitando tenant_id)
    const targetTenant = state.tenantId || DEFAULT_TENANT_ID;
    const { data: existingProf } = await sb
      .from('cardapio_clientes')
      .select('id')
      .eq('user_id', userId)
      .eq('tenant_id', targetTenant)
      .maybeSingle();

    let profileData = null;
    if (existingProf && existingProf.id) {
      const { data: updData, error: updErr } = await sb
        .from('cardapio_clientes')
        .update(payload)
        .eq('id', existingProf.id)
        .select()
        .single();
      if (updErr) throw updErr;
      profileData = updData;
    } else {
      const { data: insData, error: insErr } = await sb
        .from('cardapio_clientes')
        .insert(payload)
        .select()
        .single();
      if (insErr) throw insErr;
      profileData = insData;
    }

    state.profile = profileData || { ...payload, id: userId };

    // Sincronizar imediatamente com a tabela 'cliente' e 'local_entrega' do ERP
    try {
      const erpClient = await syncCustomerToErp({
        nome,
        telefone: phoneVal.clean,
        email,
        logradouro: logr,
        numero: num,
        bairro: bair,
        cidade: cid,
        cep,
        complemento: comp,
        referencia: ref,
        tenantId: state.tenantId || DEFAULT_TENANT_ID
      });
      if (erpClient && erpClient.id) {
        state.profile.cliente_local_id = erpClient.id;
      }
    } catch (e) {
      console.warn('Aviso ao sincronizar novo usuário no ERP:', e.message);
    }

    // Pré-preenche os inputs do formulário de checkout imediatamente
    const checkoutNome = document.getElementById('checkout-nome-cliente');
    const checkoutPhone = document.getElementById('checkout-phone-cliente');
    const checkoutLogr = document.getElementById('checkout-logradouro');
    const checkoutNum = document.getElementById('checkout-numero');
    const checkoutBair = document.getElementById('checkout-bairro');
    const checkoutCid = document.getElementById('checkout-cidade');
    const checkoutCep = document.getElementById('checkout-cep');
    const checkoutUf = document.getElementById('checkout-uf');
    const checkoutComp = document.getElementById('checkout-complemento');

    if (checkoutNome) checkoutNome.value = nome;
    if (checkoutPhone) checkoutPhone.value = formatPhone(phoneVal.clean);
    if (checkoutLogr) checkoutLogr.value = logr;
    if (checkoutNum) checkoutNum.value = num;
    if (checkoutBair) checkoutBair.value = bair;
    if (checkoutCid) checkoutCid.value = cid;
    if (checkoutCep) checkoutCep.value = cep;
    if (checkoutUf) checkoutUf.value = uf;
    if (checkoutComp) checkoutComp.value = comp;

    // Restaura layout da tela de auth
    resetAuthLayout();
    updateHeaderUI();

    const urlParams = new URLSearchParams(window.location.search);
    const isExpresso = urlParams.get('modo') === 'expresso' || urlParams.get('expresso') === '1';
    const nextScreen = state.redirectAfterAuth || (isExpresso ? 'screen-expresso' : (state.cart.length > 0 ? 'screen-checkout' : 'screen-home'));
    state.redirectAfterAuth = null;
    showScreen(nextScreen);
    toast('🎉 Cadastro salvo com sucesso! Pode continuar seu pedido.', 'success');
  } catch (err) {
    toast('Erro ao salvar cadastro: ' + err.message, 'error');
  } finally {
    showLoading(false);
  }
}

function resetAuthLayout() {
  const gContainer = document.getElementById('google-auth-container');
  const tabs = document.getElementById('auth-tabs');
  const banner = document.getElementById('google-onboarding-banner');
  const pwdGroup = document.getElementById('reg-password-group');
  const emailInput = document.getElementById('reg-email');
  const regBtn = document.getElementById('register-btn');

  if (gContainer) gContainer.style.display = 'block';
  if (tabs) tabs.style.display = 'flex';
  if (banner) banner.style.display = 'none';
  if (pwdGroup) pwdGroup.style.display = 'block';
  if (emailInput) emailInput.readOnly = false;
  if (regBtn) regBtn.textContent = 'Criar minha conta';
}

function isProfileComplete(prof) {
  if (!prof) return false;
  const phone = String(prof.whatsapp || prof.telefone || '').replace(/\D/g, '');
  const logr = String(prof.logradouro || '').trim();
  const num = String(prof.numero || '').trim();
  return phone.length >= 10 && logr.length > 0 && num.length > 0;
}

function prepareGoogleOnboardingUI(user) {
  if (!user) return;
  const gContainer = document.getElementById('google-auth-container');
  const tabs = document.getElementById('auth-tabs');
  const banner = document.getElementById('google-onboarding-banner');
  const pwdGroup = document.getElementById('reg-password-group');
  const emailInput = document.getElementById('reg-email');
  const nameInput = document.getElementById('reg-name');
  const phoneInput = document.getElementById('reg-whatsapp');
  const regBtn = document.getElementById('register-btn');
  const userNameEl = document.getElementById('gob-user-name');

  const fullName = user.user_metadata?.full_name || user.user_metadata?.name || state.profile?.nome || '';
  const email = user.email || state.profile?.email || '';

  if (gContainer) gContainer.style.display = 'none';
  if (tabs) tabs.style.display = 'none';
  if (banner) banner.style.display = 'flex';
  if (pwdGroup) pwdGroup.style.display = 'none';
  
  if (userNameEl && fullName) {
    userNameEl.textContent = `Olá, ${fullName.split(' ')[0]}!`;
  }

  if (nameInput && (!nameInput.value || nameInput.value === 'Cliente')) {
    nameInput.value = fullName;
  }
  if (emailInput) {
    emailInput.value = email;
    emailInput.readOnly = true;
  }

  // Preenche dados já existentes no perfil caso disponíveis
  if (phoneInput && !phoneInput.value && state.profile?.whatsapp) {
    phoneInput.value = formatPhone(state.profile.whatsapp);
  }
  const cepEl = document.getElementById('reg-cep');
  const logrEl = document.getElementById('reg-logradouro');
  const numEl = document.getElementById('reg-numero');
  const bairEl = document.getElementById('reg-bairro');
  const cidEl = document.getElementById('reg-cidade');
  const ufEl = document.getElementById('reg-uf');
  const compEl = document.getElementById('reg-complemento');

  if (cepEl && !cepEl.value && state.profile?.cep) cepEl.value = state.profile.cep;
  if (logrEl && !logrEl.value && state.profile?.logradouro) logrEl.value = state.profile.logradouro;
  if (numEl && !numEl.value && state.profile?.numero) numEl.value = state.profile.numero;
  if (bairEl && !bairEl.value && state.profile?.bairro) bairEl.value = state.profile.bairro;
  if (cidEl && !cidEl.value && state.profile?.cidade) cidEl.value = state.profile.cidade;
  if (ufEl && !ufEl.value && state.profile?.uf) ufEl.value = state.profile.uf;
  if (compEl && !compEl.value && state.profile?.complemento) compEl.value = state.profile.complemento;

  if (regBtn) {
    regBtn.textContent = '💾 Salvar e Continuar Pedido';
  }

  // Ativa o formulário de cadastro e oculta o formulário de login
  const formLogin = document.getElementById('form-login');
  const formReg = document.getElementById('form-register');
  if (formLogin) formLogin.style.display = 'none';
  if (formReg) formReg.style.display = 'block';

  // Foco imediato no WhatsApp se estiver em branco
  if (phoneInput && !phoneInput.value) {
    setTimeout(() => phoneInput.focus(), 300);
  }
}

async function checkExistingCustomerByPhone(rawPhone) {
  const clean = String(rawPhone || '').replace(/\D/g, '');
  const badge = document.getElementById('phone-check-status');
  if (clean.length < 10) {
    if (badge) badge.style.display = 'none';
    return;
  }

  try {
    const targetTenant = state.tenantId || DEFAULT_TENANT_ID;
    const { data: found } = await sb
      .from('cardapio_clientes')
      .select('*')
      .eq('whatsapp', clean)
      .eq('tenant_id', targetTenant)
      .maybeSingle();

    if (found && badge) {
      badge.style.display = 'block';
      badge.innerHTML = `✅ Cadastro anterior localizado (${found.nome || 'Cliente'}). Endereço pré-preenchido!`;
      badge.className = 'phone-status-badge text-success';

      const cepEl = document.getElementById('reg-cep');
      const logrEl = document.getElementById('reg-logradouro');
      const numEl = document.getElementById('reg-numero');
      const bairEl = document.getElementById('reg-bairro');
      const cidEl = document.getElementById('reg-cidade');
      const ufEl = document.getElementById('reg-uf');
      const compEl = document.getElementById('reg-complemento');

      if (found.cep && cepEl && !cepEl.value) cepEl.value = found.cep;
      if (found.logradouro && logrEl && !logrEl.value) logrEl.value = found.logradouro;
      if (found.numero && numEl && !numEl.value) numEl.value = found.numero;
      if (found.bairro && bairEl && !bairEl.value) bairEl.value = found.bairro;
      if (found.cidade && cidEl && !cidEl.value) cidEl.value = found.cidade;
      if (found.uf && ufEl && !ufEl.value) ufEl.value = found.uf;
      if (found.complemento && compEl && !compEl.value) compEl.value = found.complemento;
    } else if (badge) {
      badge.style.display = 'none';
    }
  } catch (_) {}
}

async function loadUserProfile() {
  if (!state.session?.user) return;
  const user = state.session.user;
  const meta = user.user_metadata || {};
  const googleName = meta.full_name || meta.name || meta.display_name || (user.email ? user.email.split('@')[0] : 'Cliente');
  const googleEmail = user.email || '';
  const googlePhone = user.phone || meta.phone || '';

  try {
    const targetTenant = state.tenantId || DEFAULT_TENANT_ID;
    const { data } = await sb
      .from('cardapio_clientes')
      .select('*')
      .eq('user_id', user.id)
      .eq('tenant_id', targetTenant)
      .maybeSingle();

    if (data) {
      let updated = false;
      const updates = {};
      if (!data.nome && googleName) {
        updates.nome = googleName;
        data.nome = googleName;
        updated = true;
      }
      if (!data.email && googleEmail) {
        updates.email = googleEmail;
        data.email = googleEmail;
        updated = true;
      }
      if (updated) {
        await sb.from('cardapio_clientes').update(updates).eq('id', data.id);
      }
      state.profile = data;
    } else {
      // Se não existe para este tenant, busca se já tem cadastro preenchido em qualquer outro tenant para reaproveitar tudo!
      const { data: anyProf } = await sb
        .from('cardapio_clientes')
        .select('*')
        .eq('user_id', user.id)
        .order('updated_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      const initialProfile = {
        user_id: user.id,
        tenant_id: targetTenant,
        nome: anyProf?.nome || googleName,
        email: anyProf?.email || googleEmail,
        whatsapp: anyProf?.whatsapp || googlePhone,
        cep: anyProf?.cep || null,
        uf: anyProf?.uf || state.empresa?.estado || 'SP',
        logradouro: anyProf?.logradouro || null,
        numero: anyProf?.numero || null,
        bairro: anyProf?.bairro || null,
        cidade: anyProf?.cidade || state.empresa?.cidade || '',
        complemento: anyProf?.complemento || null,
        referencia: anyProf?.referencia || null,
        endereco_padrao: anyProf?.endereco_padrao || null,
        cliente_local_id: anyProf?.cliente_local_id || null,
      };

      const { data: newProfile } = await sb
        .from('cardapio_clientes')
        .insert(initialProfile)
        .select()
        .maybeSingle();

      state.profile = newProfile || initialProfile;
    }
  } catch (e) {
    console.warn('Erro ao carregar ou auto-provisionar perfil do usuário:', e);
    if (!state.profile) {
      state.profile = {
        user_id: user.id,
        nome: googleName,
        email: googleEmail,
        whatsapp: googlePhone
      };
    }
  }

  // Atualiza imediatamente a UI global
  updateHeaderUI();
  populateAccountForm();

  if (isProfileComplete(state.profile)) {
    resetAuthLayout();
  }
}

async function handleLogout(redirectToHome = true) {
  showLoading(true, 'Saindo da sua conta...');
  try {
    await sb.auth.signOut();
  } catch (e) {
    console.warn('Aviso ao sair da conta:', e);
  }

  // 1. Limpa sessão e perfil em memória
  state.session = null;
  state.profile = null;
  state.redirectAfterAuth = null;
  state.customerOrders = [];
  state.activeOrder = null;
  state.routeInfo = null;
  state.destCoords = null;
  state.taxaEntregaCentavos = 0;
  state.entregaMetadata = null;

  // 2. Limpa completamente o carrinho e itens da tela
  clearCart();

  // 3. Remove do localStorage storages de contato e endereço para nunca vazar dados de usuário anterior
  try {
    localStorage.removeItem('fincore_cart');
    localStorage.removeItem('fincore_saved_address');
    localStorage.removeItem('fincore_guest_contact');
    localStorage.removeItem('fincore_last_order_id');
  } catch (_) {}

  // 4. Limpa todos os inputs do formulário de checkout e de conta no DOM
  const inputsToClear = [
    'checkout-nome-cliente', 'checkout-phone-cliente', 'checkout-cep',
    'checkout-logradouro', 'checkout-numero', 'checkout-bairro',
    'checkout-cidade', 'checkout-complemento', 'checkout-referencia',
    'checkout-obs', 'checkout-troco', 'account-name', 'account-phone',
    'account-email', 'account-cep', 'account-logradouro', 'account-numero',
    'account-bairro', 'account-cidade', 'account-complemento', 'account-referencia'
  ];
  inputsToClear.forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });

  // 5. Reseta caixas de endereço do checkout
  const savedBox = document.getElementById('checkout-saved-address-box');
  const savedText = document.getElementById('checkout-saved-address-text');
  const formContainer = document.getElementById('checkout-address-form-container');
  const loggedUserBox = document.getElementById('checkout-logged-user-box');
  const contactSection = document.getElementById('checkout-contact-section');

  if (savedBox) savedBox.style.display = 'none';
  if (savedText) savedText.textContent = '';
  if (formContainer) formContainer.style.display = 'block';
  if (loggedUserBox) loggedUserBox.style.display = 'none';
  if (contactSection) contactSection.style.display = 'none';

  // 6. Reseta layout de autenticação e cabeçalhos
  resetAuthLayout();
  updateHeaderUI();
  updateCartBar();

  showLoading(false);
  if (redirectToHome) {
    showScreen('screen-home');
    toast('Você saiu da sua conta e os dados foram limpos com segurança.', 'info');
  }
}

function updateHeaderUI() {
  const avatarEl = document.getElementById('header-avatar');
  const drawerName = document.getElementById('drawer-user-name');
  const drawerPhone = document.getElementById('drawer-user-phone');

  const user = state.session?.user;
  const meta = user?.user_metadata || {};
  const nome = state.profile?.nome || meta.full_name || meta.name || meta.display_name || '';
  const email = state.profile?.email || user?.email || '';
  const phone = state.profile?.whatsapp || user?.phone || meta.phone || '';
  const avatarUrl = meta.avatar_url || meta.picture || '';

  if (nome || email || user) {
    if (avatarEl) {
      if (avatarUrl) {
        avatarEl.innerHTML = `<img src="${avatarUrl}" alt="Avatar" style="width:100%;height:100%;border-radius:50%;object-fit:cover;" />`;
      } else if (nome) {
        const initials = nome.split(' ').filter(Boolean).map(n => n[0]).join('').slice(0, 2).toUpperCase();
        avatarEl.textContent = initials || '👤';
      } else {
        avatarEl.textContent = '👤';
      }
    }
    if (drawerName) drawerName.textContent = nome || (email ? email.split('@')[0] : 'Cliente');
    if (drawerPhone) drawerPhone.textContent = formatPhone(phone) || email || 'Conectado';
  } else {
    if (avatarEl) {
      avatarEl.innerHTML = '';
      avatarEl.textContent = '👤';
    }
    if (drawerName) drawerName.textContent = 'Visitante';
    if (drawerPhone) drawerPhone.textContent = 'Toque para entrar';
  }
}

// ═══════════════════════════════════════════════════════════════════
// MÓDULO VITRINE DE PEDIDO EXPRESSO (Pronta Entrega por Estoque) — v2.9.8
// ═══════════════════════════════════════════════════════════════════

function getSaldoEstoqueProduto(prod) {
  if (!prod) return 0;
  if (prod.estoqueInfo) {
    const atual = Number(prod.estoqueInfo.quantidadeAtual || 0);
    const reservado = Number(prod.estoqueInfo.quantidadeReservada || 0);
    return Math.max(0, atual - reservado);
  }
  if (prod.estoque_atual !== undefined && prod.estoque_atual !== null) {
    return Math.max(0, Number(prod.estoque_atual));
  }
  return 999;
}

function getProdutosExpressoDisponiveis() {
  const minStock = Number(state.expressoConfig?.estoqueMinimo ?? 1);
  return state.produtos.filter(p => {
    if (p.ativo === false || p.status_comercial === 'indisponivel') return false;
    const saldo = getSaldoEstoqueProduto(p);
    return saldo >= minStock;
  });
}

function setupExpressoVitrine() {
  const cfg = state.expressoConfig || { ativo: true, estoqueMinimo: 1, titulo: 'Disponíveis para Envio Imediato' };
  const banner = document.getElementById('home-expresso-banner');
  const bannerTitle = document.getElementById('home-expresso-title');
  const bannerBadge = document.getElementById('home-expresso-stock-badge');
  const screenTitle = document.getElementById('expresso-screen-title');
  const headerStockBadge = document.getElementById('expresso-header-stock-badge');

  if (bannerTitle) bannerTitle.textContent = cfg.titulo || 'Disponíveis para Envio Imediato';
  if (screenTitle) screenTitle.textContent = cfg.titulo || 'Disponíveis para Envio Imediato';
  if (headerStockBadge) headerStockBadge.textContent = `Estoque mínimo: ${cfg.estoqueMinimo || 1} un`;

  const prods = getProdutosExpressoDisponiveis();
  if (bannerBadge) {
    bannerBadge.textContent = `🟢 ${prods.length} ${prods.length === 1 ? 'item disponível' : 'itens disponíveis'}`;
  }

  if (banner) {
    banner.style.display = (cfg.ativo && prods.length > 0) ? 'block' : 'none';
  }

  // Acesso direto via URL (?modo=expresso ou ?expresso=1)
  try {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('modo') === 'expresso' || urlParams.get('expresso') === '1') {
      showScreen('screen-expresso');
    }
  } catch (_) {}
}

function renderExpressoScheduleBanner() {
  const banner = document.getElementById('expresso-schedule-banner');
  if (!banner) return;

  const now = new Date();
  const pe = calcularPrimeiraEntregaPossivel(now, state.horariosAtendimento);
  const prazoMin = state.horariosAtendimento?.prazoMinimoMinutos || 40;

  if (pe.isHoje && pe.canOrder) {
    banner.className = 'expresso-schedule-banner';
    banner.innerHTML = `
      <span class="esb-icon">⚡</span>
      <div class="esb-text">
        <strong>Atendimento aberto agora!</strong> Pedidos expressos têm prazo estimado em cerca de ${prazoMin} minutos (previsão às ${pe.horaFmt}).
      </div>
    `;
  } else {
    banner.className = 'expresso-schedule-banner is-closed';
    const nextText = pe.isAmanha 
      ? `amanhã a partir das ${pe.horaFmt}` 
      : `${pe.diaNome || 'próximo expediente'} às ${pe.horaFmt}`;
    banner.innerHTML = `
      <span class="esb-icon">🕒</span>
      <div class="esb-text">
        <strong>Fora do expediente no momento.</strong> Seu pedido expresso será preparado e enviado no próximo atendimento (${nextText}).
      </div>
    `;
  }
}

function renderExpressoScreen() {
  renderExpressoScheduleBanner();
  const grid = document.getElementById('expresso-products-grid');
  const emptyState = document.getElementById('expresso-empty-state');
  if (!grid) return;

  const prods = getProdutosExpressoDisponiveis();

  if (prods.length === 0) {
    if (emptyState) emptyState.style.display = 'block';
    grid.innerHTML = '';
    updateExpressoStickyBar();
    return;
  }

  if (emptyState) emptyState.style.display = 'none';

  grid.innerHTML = prods.map(prod => {
    const saldo = getSaldoEstoqueProduto(prod);
    const inCartQty = state.expressoCart[prod.id] || 0;
    const unitPrice = getPreco(prod, inCartQty || 1);
    
    // Tiers de desconto por quantidade
    const tiers = getTiersForProduct(prod);
    let tierTagHtml = '';
    if (tiers && tiers.length > 1) {
      const basePrice = tiers[0].valor_unitario_centavos;
      if (unitPrice < basePrice) {
        const discPct = Math.round(((basePrice - unitPrice) / basePrice) * 100);
        tierTagHtml = `<span class="ec-tier-tag">⭐ ${discPct}% de desconto aplicado</span>`;
      } else {
        tierTagHtml = `<span class="ec-tier-tag" style="color:var(--text-muted)">Preço especial por atacado</span>`;
      }
    }

    const foto = prod.foto_url || prod.imagem_url;
    const thumbHtml = foto
      ? `<img src="${foto}" alt="${prod.nome}" class="ec-thumb" loading="lazy" />`
      : `<div class="ec-thumb-fallback">${getCategoryIcon(prod.categoria_icone, prod.categoria_nome)}</div>`;

    const isLow = saldo <= 15;
    const stockBadge = `<span class="ec-stock-badge ${isLow ? 'low' : ''}">🟢 ${saldo} un em estoque</span>`;

    return `
      <div class="expresso-card ${inCartQty > 0 ? 'in-cart' : ''}" id="expresso-card-${prod.id}">
        <div class="ec-top-row">
          <div class="ec-thumb-wrap">
            ${thumbHtml}
          </div>
          <div class="ec-info">
            ${stockBadge}
            <h3 class="ec-name">${prod.nome}</h3>
            ${prod.descricao ? `<p class="ec-desc">${prod.descricao}</p>` : ''}
          </div>
        </div>
        <div class="ec-bottom-row">
          <div class="ec-price-block">
            <span class="ec-price-unit" id="expresso-price-${prod.id}">
              ${fmt(unitPrice)} <small>/un</small>
            </span>
            ${tierTagHtml}
          </div>
          <div class="ec-stepper">
            <button type="button" class="ec-step-btn" onclick="changeExpressoQty('${prod.id}', -1)" aria-label="Diminuir quantidade">−</button>
            <input type="number" class="ec-step-input" id="expresso-input-${prod.id}" value="${inCartQty}" min="0" max="${saldo}" onchange="setExpressoQty('${prod.id}', this.value)" />
            <button type="button" class="ec-step-btn" onclick="changeExpressoQty('${prod.id}', 1)" aria-label="Aumentar quantidade">+</button>
          </div>
        </div>
      </div>
    `;
  }).join('');

  updateExpressoStickyBar();
}

function changeExpressoQty(prodId, delta) {
  const current = state.expressoCart[prodId] || 0;
  const prod = state.produtos.find(p => p.id === prodId);
  const saldo = getSaldoEstoqueProduto(prod);

  let next = current + delta;
  if (next < 0) next = 0;
  if (saldo > 0 && next > saldo) {
    next = saldo;
    toast(`Quantidade máxima disponível em estoque: ${saldo} un.`, 'info', 2500);
  }

  setExpressoQty(prodId, next);
}

function setExpressoQty(prodId, val) {
  const prod = state.produtos.find(p => p.id === prodId);
  if (!prod) return;

  const saldo = getSaldoEstoqueProduto(prod);
  let qty = parseInt(val, 10);
  if (isNaN(qty) || qty < 0) qty = 0;
  if (saldo > 0 && qty > saldo) {
    qty = saldo;
    toast(`Quantidade limitada ao estoque disponível (${saldo} un).`, 'info', 2500);
  }

  if (qty > 0) {
    state.expressoCart[prodId] = qty;
  } else {
    delete state.expressoCart[prodId];
  }

  const input = document.getElementById(`expresso-input-${prodId}`);
  if (input) input.value = qty;

  const card = document.getElementById(`expresso-card-${prodId}`);
  if (card) {
    card.classList.toggle('in-cart', qty > 0);
  }

  const priceEl = document.getElementById(`expresso-price-${prodId}`);
  if (priceEl) {
    const unitPrice = getPreco(prod, qty || 1);
    priceEl.innerHTML = `${fmt(unitPrice)} <small>/un</small>`;
  }

  updateExpressoStickyBar();
}

function updateExpressoStickyBar() {
  const bar = document.getElementById('expresso-sticky-bar');
  const countEl = document.getElementById('expresso-bar-count');
  const labelEl = document.getElementById('expresso-bar-label');
  const totalEl = document.getElementById('expresso-bar-total');

  let totalItems = 0;
  let subtotalCentavos = 0;

  for (const [pId, qty] of Object.entries(state.expressoCart)) {
    if (qty > 0) {
      const prod = state.produtos.find(p => p.id === pId);
      if (prod) {
        totalItems += qty;
        subtotalCentavos += getPreco(prod, qty) * qty;
      }
    }
  }

  if (countEl) countEl.textContent = totalItems;
  if (labelEl) labelEl.textContent = totalItems === 1 ? 'item selecionado' : 'itens selecionados';
  if (totalEl) totalEl.textContent = fmt(subtotalCentavos);

  if (bar) {
    bar.style.display = totalItems > 0 ? 'block' : 'none';
  }
}

function getExpressoCartSummary() {
  const items = [];
  let totalItems = 0;
  let subtotalCentavos = 0;

  for (const [pId, qty] of Object.entries(state.expressoCart)) {
    if (qty > 0) {
      const prod = state.produtos.find(p => p.id === pId);
      if (prod) {
        const unitPrice = getPreco(prod, qty);
        const itemTotal = unitPrice * qty;
        totalItems += qty;
        subtotalCentavos += itemTotal;
        items.push({
          produto: prod,
          qty,
          valorUnitarioCentavos: unitPrice,
          valorTotalCentavos: itemTotal
        });
      }
    }
  }

  return { items, totalItems, subtotalCentavos };
}

function calcularTaxaEntregaExpresso(subtotalCentavos) {
  if (state.expressoLogistica === 'Retirada') {
    return { valorCentavos: 0, label: 'Grátis (Retirada)', isGratis: true };
  }

  const regras = state.taxasEntrega || [];
  const bairroInput = (document.getElementById('expresso-bairro')?.value || '').trim().toLowerCase();
  const cepInput = (document.getElementById('expresso-cep')?.value || '').replace(/\D/g, '');

  let taxaEncontrada = null;

  if (bairroInput && regras.length > 0) {
    taxaEncontrada = regras.find(r => {
      if (r.ativo && (r.tipoRegra === 'bairro' || r.tipo_regra === 'bairro') && r.bairro) {
        const b = r.bairro.trim().toLowerCase();
        return b === bairroInput || bairroInput.includes(b) || b.includes(bairroInput);
      }
      return false;
    });

    if (taxaEncontrada) {
      const valor = parseInt(taxaEncontrada.valorCentavos || 0, 10);
      const minGratis = parseInt(taxaEncontrada.pedidoMinimoCentavos || 0, 10);
      const finalValor = (minGratis > 0 && subtotalCentavos >= minGratis) ? 0 : valor;
      return { valorCentavos: finalValor, label: finalValor === 0 ? 'Grátis' : fmt(finalValor), isGratis: finalValor === 0 };
    }
  }

  if (cepInput && cepInput.length === 8 && regras.length > 0) {
    const cepNum = parseInt(cepInput, 10);
    taxaEncontrada = regras.find(r => {
      if (r.ativo && (r.tipoRegra === 'faixa_cep' || r.tipo_regra === 'faixa_cep') && r.cepInicio && r.cepFim) {
        const ini = parseInt(String(r.cepInicio).replace(/\D/g, ''), 10);
        const fim = parseInt(String(r.cepFim).replace(/\D/g, ''), 10);
        return cepNum >= ini && cepNum <= fim;
      }
      return false;
    });

    if (taxaEncontrada) {
      const valor = parseInt(taxaEncontrada.valorCentavos || 0, 10);
      const minGratis = parseInt(taxaEncontrada.pedidoMinimoCentavos || 0, 10);
      const finalValor = (minGratis > 0 && subtotalCentavos >= minGratis) ? 0 : valor;
      return { valorCentavos: finalValor, label: finalValor === 0 ? 'Grátis' : fmt(finalValor), isGratis: finalValor === 0 };
    }
  }

  const fallback = regras.find(r => r.ativo && (r.tipoRegra === 'padrao' || r.tipo_regra === 'padrao'));
  if (fallback) {
    const valor = parseInt(fallback.valorCentavos || 0, 10);
    return { valorCentavos: valor, label: valor === 0 ? 'Grátis' : fmt(valor), isGratis: valor === 0 };
  }

  return { valorCentavos: 0, label: 'Grátis', isGratis: true };
}

function updateExpressoTotals() {
  const { subtotalCentavos } = getExpressoCartSummary();
  const taxaObj = calcularTaxaEntregaExpresso(subtotalCentavos);
  state.expressoTaxaEntregaCentavos = taxaObj.valorCentavos;

  const totalGeral = subtotalCentavos + taxaObj.valorCentavos;

  const subtotalEl = document.getElementById('expresso-modal-subtotal');
  const taxaEl = document.getElementById('expresso-modal-taxa');
  const totalEl = document.getElementById('expresso-modal-total');

  if (subtotalEl) subtotalEl.textContent = fmt(subtotalCentavos);
  if (taxaEl) {
    taxaEl.textContent = taxaObj.label;
    taxaEl.className = taxaObj.isGratis ? 'text-success' : '';
  }
  if (totalEl) totalEl.textContent = fmt(totalGeral);
}

function openExpressoCheckoutModal() {
  const { items, totalItems, subtotalCentavos } = getExpressoCartSummary();
  if (totalItems <= 0) {
    toast('Selecione ao menos 1 item para continuar.', 'warning');
    return;
  }

  const listEl = document.getElementById('expresso-modal-items-list');
  if (listEl) {
    listEl.innerHTML = items.map(i => `
      <div class="eisl-item">
        <div class="eisl-name-wrap">
          <span class="eisl-qty">${i.qty}x</span>
          <span class="eisl-name">${i.produto.nome}</span>
        </div>
        <span class="eisl-price">${fmt(i.valorTotalCentavos)}</span>
      </div>
    `).join('');
  }

  let savedClient = null;
  try {
    const raw = localStorage.getItem('fincore_expresso_cliente');
    if (raw) savedClient = JSON.parse(raw);
  } catch (_) {}

  const nomeInput = document.getElementById('expresso-cliente-nome');
  const phoneInput = document.getElementById('expresso-cliente-phone');
  const cepInput = document.getElementById('expresso-cep');
  const logrInput = document.getElementById('expresso-logradouro');
  const numInput = document.getElementById('expresso-numero');
  const bairInput = document.getElementById('expresso-bairro');
  const cidInput = document.getElementById('expresso-cidade');
  const compInput = document.getElementById('expresso-complemento');

  if (nomeInput && !nomeInput.value) {
    nomeInput.value = savedClient?.nome || state.profile?.nome || '';
  }
  if (phoneInput && !phoneInput.value) {
    phoneInput.value = formatPhone(savedClient?.telefone || state.profile?.whatsapp || '');
  }
  if (cepInput && !cepInput.value) {
    cepInput.value = savedClient?.cep || state.profile?.cep || '';
  }
  if (logrInput && !logrInput.value) {
    logrInput.value = savedClient?.logradouro || state.profile?.logradouro || '';
  }
  if (numInput && !numInput.value) {
    numInput.value = savedClient?.numero || state.profile?.numero || '';
  }
  if (bairInput && !bairInput.value) {
    bairInput.value = savedClient?.bairro || state.profile?.bairro || '';
  }
  if (cidInput && !cidInput.value) {
    cidInput.value = savedClient?.cidade || state.profile?.cidade || state.empresa?.cidade || 'Pouso Alegre';
  }
  if (compInput && !compInput.value) {
    compInput.value = savedClient?.complemento || state.profile?.complemento || '';
  }

  const now = new Date();
  const pe = calcularPrimeiraEntregaPossivel(now, state.horariosAtendimento);
  const dataInput = document.getElementById('expresso-data');
  const horaInput = document.getElementById('expresso-hora');
  const scheduleBox = document.getElementById('expresso-schedule-info-box');

  const toYmd = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  if (dataInput && pe.dataStr) {
    dataInput.value = pe.dataStr;
    dataInput.min = toYmd(now);
  }
  if (horaInput && pe.horaStr) {
    horaInput.value = pe.horaStr;
  }

  if (scheduleBox) {
    if (pe.isHoje && pe.canOrder) {
      scheduleBox.innerHTML = `✅ <strong>Atendimento ativo agora.</strong> Horário sugerido para envio imediato: <strong>${pe.horaFmt}</strong> (ou ajuste se preferir receber mais tarde).`;
    } else {
      const nextTxt = pe.isAmanha ? `amanhã às ${pe.horaFmt}` : `${pe.diaNome || 'próximo expediente'} às ${pe.horaFmt}`;
      scheduleBox.innerHTML = `ℹ️ <strong>Fora do expediente comercial.</strong> Primeiro horário sugerido pela cozinha: <strong>${nextTxt}</strong>.`;
    }
  }

  const retTxt = document.getElementById('expresso-retirada-endereco-text');
  if (retTxt && state.empresa) {
    const endLoja = [
      state.empresa.logradouro ? `${state.empresa.logradouro}, ${state.empresa.numero || 'S/N'}` : '',
      state.empresa.bairro,
      state.empresa.cidade ? `${state.empresa.cidade} - ${state.empresa.estado || 'MG'}` : ''
    ].filter(Boolean).join(' - ');
    retTxt.textContent = endLoja || 'Retirada no balcão principal da loja.';
  }

  updateExpressoTotals();
  document.getElementById('modal-expresso-checkout')?.classList.add('open');
}

function closeExpressoCheckoutModal() {
  document.getElementById('modal-expresso-checkout')?.classList.remove('open');
}

async function finalizarPedidoExpresso(e) {
  if (e) e.preventDefault();

  const { items, totalItems, subtotalCentavos } = getExpressoCartSummary();
  if (totalItems <= 0) {
    toast('Selecione itens no pedido expresso.', 'warning');
    return;
  }

  const nome = (document.getElementById('expresso-cliente-nome')?.value || '').trim();
  const phone = (document.getElementById('expresso-cliente-phone')?.value || '').trim();
  const cep = (document.getElementById('expresso-cep')?.value || '').trim();
  const logr = (document.getElementById('expresso-logradouro')?.value || '').trim();
  const num = (document.getElementById('expresso-numero')?.value || '').trim();
  const bair = (document.getElementById('expresso-bairro')?.value || '').trim();
  const cid = (document.getElementById('expresso-cidade')?.value || '').trim();
  const comp = (document.getElementById('expresso-complemento')?.value || '').trim();
  const data = (document.getElementById('expresso-data')?.value || '').trim();
  const hora = (document.getElementById('expresso-hora')?.value || '').trim();
  const obs = (document.getElementById('expresso-obs')?.value || '').trim();

  if (!nome || nome.length < 2) {
    toast('Por favor, informe seu Nome Completo.', 'error');
    document.getElementById('expresso-cliente-nome')?.focus();
    return;
  }

  const phoneVal = validatePhone(phone);
  if (!phoneVal.valid) {
    toast(phoneVal.error, 'error', 5000);
    document.getElementById('expresso-cliente-phone')?.focus();
    return;
  }

  if (state.expressoLogistica === 'Entrega') {
    if (!logr || !num || !bair) {
      toast('Para entrega, informe a Rua, o Número e o Bairro.', 'error');
      if (!logr) document.getElementById('expresso-logradouro')?.focus();
      else if (!num) document.getElementById('expresso-numero')?.focus();
      else document.getElementById('expresso-bairro')?.focus();
      return;
    }
  }

  const scheduleVal = validateOrderSchedule(data, hora);
  if (!scheduleVal.valid) {
    toast(scheduleVal.message, 'error', 6000);
    document.getElementById('expresso-hora')?.focus();
    return;
  }

  try {
    localStorage.setItem('fincore_expresso_cliente', JSON.stringify({
      nome,
      telefone: phoneVal.clean,
      cep,
      logradouro: logr,
      numero: num,
      bairro: bair,
      cidade: cid,
      complemento: comp
    }));
  } catch (_) {}

  const taxaObj = calcularTaxaEntregaExpresso(subtotalCentavos);
  const taxaEntrega = taxaObj.valorCentavos;
  const totalFinal = subtotalCentavos + taxaEntrega;

  let trocoCentavos = null;
  if (state.expressoFormaPagamento === 'Dinheiro') {
    const rawTroco = document.getElementById('expresso-troco')?.value.trim();
    if (rawTroco) {
      const trocoVal = parseFloat(rawTroco.replace(/\./g, '').replace(',', '.'));
      if (!isNaN(trocoVal) && trocoVal > 0) {
        trocoCentavos = Math.round(trocoVal * 100);
        if (trocoCentavos < totalFinal) {
          toast(`O valor informado para troco (${fmt(trocoCentavos)}) é menor que o total do pedido (${fmt(totalFinal)}).`, 'error');
          document.getElementById('expresso-troco')?.focus();
          return;
        }
      }
    }
  }

  showLoading(true, 'Registrando seu pedido expresso...');

  try {
    const agora = new Date().toISOString();
    const dataEntrega = `${data}T${hora}:00`;
    const pedidoId = crypto.randomUUID();

    let nextNumPed = 1001;
    try {
      const { data: maxPed } = await sb
        .from('pedido')
        .select('numeroPedido')
        .eq('tenantId', state.tenantId || DEFAULT_TENANT_ID)
        .order('numeroPedido', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (maxPed && maxPed.numeroPedido) {
        nextNumPed = Number(maxPed.numeroPedido) + 1;
      }
    } catch (_) {}

    const fullAddress = state.expressoLogistica === 'Entrega'
      ? [
          `${logr}, ${num}`,
          comp ? `(${comp})` : '',
          bair,
          `${cid} - ${state.empresa?.estado || 'MG'}`,
          cep ? `CEP: ${cep}` : ''
        ].filter(Boolean).join(' - ')
      : 'Retirada no Balcão da Loja';

    const enderecoObj = state.expressoLogistica === 'Entrega' ? {
      logradouro: logr,
      numero: num,
      bairro: bair,
      cidade: cid,
      uf: state.empresa?.estado || 'MG',
      cep: cep || null,
      complemento: comp || null,
      enderecoCompleto: fullAddress
    } : null;

    let userIdValid = state.session?.user?.id || null;
    let clienteLocalId = state.profile?.cliente_local_id || null;

    // 1. Inserir Pedido na tabela 'pedido'
    const pedidoPayload = {
      id:                        pedidoId,
      tenantId:                  state.tenantId || DEFAULT_TENANT_ID,
      clienteId:                 clienteLocalId,
      clienteNomeAvulso:         nome,
      clienteTelefoneAvulso:     phoneVal.clean,
      valorSubtotalCentavos:     subtotalCentavos,
      valorTaxaEntregaCentavos:  taxaEntrega,
      valorTotalCentavos:        totalFinal,
      trocoParaCentavos:         trocoCentavos,
      formaPagamentoId:          null,
      formaPagamentoNome:        state.expressoFormaPagamento,
      canalOrigem:                'expresso_web',
      dataHoraCriacao:           agora,
      dataHoraEntregaPrevista:   dataEntrega,
      observacoes:               obs ? `[PEDIDO_EXPRESSO] ${obs}` : '[PEDIDO_EXPRESSO]',
      enderecoJson:              state.expressoLogistica === 'Entrega' ? JSON.stringify(enderecoObj) : null,
      numeroPedido:               nextNumPed,
      status:                    'pendente'
    };

    const { error: pedErr } = await sb.from('pedido').insert(pedidoPayload);
    if (pedErr) throw pedErr;

    // 2. Inserir Itens na tabela 'item_pedido'
    try {
      const itensPayload = items.map(i => ({
        id:                    crypto.randomUUID(),
        pedidoId:              pedidoId,
        produtoId:             i.produto.id,
        nomeProduto:           i.produto.nome,
        quantidade:            Number(i.qty),
        valorUnitarioCentavos: i.valorUnitarioCentavos,
        valorTotalCentavos:    i.valorTotalCentavos,
        observacoes:           null,
        tenantId:              state.tenantId || DEFAULT_TENANT_ID,
        createdAt:             agora,
        updatedAt:             agora,
        createdBy:             userIdValid,
        updatedBy:             userIdValid,
        syncVersion:           1
      }));
      await sb.from('item_pedido').insert(itensPayload);
    } catch (e) {
      console.warn('Erro ao inserir item_pedido no expresso:', e);
    }

    // 3. Inserir Ordem de Preparo (Kanban da Central de Pedidos do PDV)
    const ordemId = crypto.randomUUID();
    try {
      let pagDesc = state.expressoFormaPagamento;
      if (state.expressoFormaPagamento === 'Dinheiro' && trocoCentavos) {
        pagDesc += ` (Troco p/ ${fmt(trocoCentavos)})`;
      }

      let dataAgendadaTag = '';
      if (data && hora) {
        const [yyyy, mm, dd] = data.split('-');
        dataAgendadaTag = `agendado: ${dd}/${mm}/${yyyy} ${hora}`;
      }

      const obsTags = [
        `[DADOS_PEDIDO]`,
        `cliente: ${nome}`,
        `telefone: ${phoneVal.clean}`,
        `tipo: ${state.expressoLogistica}`,
        `pagamento: ${pagDesc}`,
        `total: ${totalFinal}`,
        `unidades: ${totalItems}`,
        state.expressoLogistica === 'Entrega' ? `endereco: ${logr ? `${logr}, ${num}` : ''}` : '',
        state.expressoLogistica === 'Entrega' && bair ? `bairro: ${bair}` : '',
        dataAgendadaTag,
        `modo: EXPRESSO`,
        obs ? `obs: ${obs}` : '',
        `[/DADOS_PEDIDO]`
      ].filter(Boolean).join('\n');

      const ordemPayload = {
        id:                    ordemId,
        tenantId:              state.tenantId || DEFAULT_TENANT_ID,
        pedidoId:              pedidoId,
        itensJson:             JSON.stringify(items.map(i => ({
          produtoId:   i.produto.id,
          nomeProduto: i.produto.nome,
          quantidade:  Number(i.qty),
          unidade:     i.produto.unidadeVenda || 'un',
          observacoes: null
        }))),
        status:                'pendente',
        prioridade:            'alta',
        criadaEm:              agora,
        createdAt:             agora,
        updatedAt:             agora,
        tempoEstimadoSegundos: 1200,
        observacoes:           obsTags,
        createdBy:             userIdValid,
        updatedBy:             userIdValid,
        syncVersion:           1
      };

      await sb.from('ordens_preparo').insert(ordemPayload);

      try {
        await sb.from('historicos_ordem_preparo').insert({
          id:             crypto.randomUUID(),
          tenantId:       state.tenantId || DEFAULT_TENANT_ID,
          ordemPreparoId: ordemId,
          titulo:         'Pedido Expresso Recebido via Cardápio Web',
          descricao:      `Pedido pronto entrega nº ${nextNumPed} enviado pelo cliente com ${totalItems} un.`,
          operadorNome:   nome,
          criadaEm:       agora,
          createdAt:      agora
        });
      } catch (_) {}
    } catch (e) {
      console.warn('Erro ao inserir ordem_preparo no expresso:', e);
    }

    const orderData = {
      ...pedidoPayload,
      item_pedido: items.map(i => ({
        nomeProduto: i.produto.nome,
        quantidade: i.qty,
        valorUnitarioCentavos: i.valorUnitarioCentavos,
        valorTotalCentavos: i.valorTotalCentavos
      }))
    };
    state.currentOrder = orderData;
    state.activeOrder = orderData;
    localStorage.setItem('fincore_last_order_id', pedidoId);

    const [yyyy, mm, dd] = data.split('-');
    const dataFmt = `${dd}/${mm}/${yyyy}`;
    const trackingUrl = `${window.location.origin}${window.location.pathname}?track=${pedidoId}`;

    const itensTxt = items.map(i => `• ${i.qty}x ${i.produto.nome} — ${fmt(i.valorTotalCentavos)}`).join('\n');
    let msgZap = `*⚡ NOVO PEDIDO EXPRESSO — Nº ${nextNumPed}*\n\n`;
    msgZap += `*Cliente:* ${nome}\n`;
    msgZap += `*WhatsApp:* ${phoneVal.clean}\n`;
    msgZap += `*Modalidade:* ${state.expressoLogistica === 'Entrega' ? '🛵 Entrega' : '🏪 Retirada'}\n`;
    if (state.expressoLogistica === 'Entrega') {
      msgZap += `*Endereço:* ${fullAddress}\n`;
    }
    msgZap += `*Data/Hora Prevista:* ${dataFmt} às ${hora}\n`;
    msgZap += `*Pagamento:* ${state.expressoFormaPagamento}${trocoCentavos ? ` (Troco para ${fmt(trocoCentavos)})` : ''}\n\n`;
    msgZap += `*🛒 ITENS:*\n${itensTxt}\n\n`;
    msgZap += `*Subtotal:* ${fmt(subtotalCentavos)}\n`;
    if (taxaEntrega > 0) msgZap += `*Taxa de Entrega:* ${fmt(taxaEntrega)}\n`;
    msgZap += `*TOTAL:* ${fmt(totalFinal)}\n`;
    if (obs) msgZap += `*Obs:* ${obs}\n`;
    msgZap += `\n*🔗 Acompanhar Pedido:* ${trackingUrl}`;

    const phoneClean = getEmpresaWhatsAppClean();
    let zapUrl = `https://api.whatsapp.com/send?text=${encodeURIComponent(msgZap)}`;
    if (phoneClean) {
      zapUrl = `https://api.whatsapp.com/send?phone=${phoneClean}&text=${encodeURIComponent(msgZap)}`;
    }
    window.open(zapUrl, '_blank');

    state.expressoCart = {};
    updateExpressoStickyBar();
    closeExpressoCheckoutModal();

    toast(`🎉 Pedido expresso nº ${nextNumPed} confirmado com sucesso!`, 'success', 5000);
    renderConfirmationPage(orderData, nextNumPed, totalFinal);
    showScreen('screen-confirmation');
  } catch (err) {
    console.error('Erro ao finalizar pedido expresso:', err);
    toast('Erro ao registrar pedido expresso: ' + err.message, 'error', 6000);
  } finally {
    showLoading(false);
  }
}

// ─── Drawer & Modais Auxiliares ──────────────────────────────────────
function openDrawer() {
  document.getElementById('user-drawer')?.classList.add('open');
}

function closeDrawer() {
  document.getElementById('user-drawer')?.classList.remove('open');
}

// ─── Inicialização de Eventos DOM ─────────────────────────────────────
function initEventListeners() {
  // Navegação Topbar Desktop
  document.querySelectorAll('.desktop-nav-link').forEach(btn => {
    btn.addEventListener('click', () => showScreen(btn.dataset.target));
  });

  // Navegação Bottombar Mobile
  document.querySelectorAll('.bnav-item').forEach(btn => {
    btn.addEventListener('click', () => showScreen(btn.dataset.target));
  });

  // Logo Header -> Home
  document.getElementById('header-logo-container')?.addEventListener('click', () => showScreen('screen-home'));

  // Carrinho Topbar & Floating Bar -> Checkout com validação obrigatória de login
  const handleGoToCheckout = () => {
    if (!state.cart || state.cart.length === 0) {
      toast('Seu carrinho está vazio! Adicione produtos deliciosos do cardápio.', 'info');
      showScreen('screen-cardapio');
      return;
    }
    const isLogged = !!(state.session?.user || (state.profile && state.profile.id));
    if (!isLogged) {
      state.redirectAfterAuth = 'screen-checkout';
      toast('🔐 Para sua segurança, faça login ou cadastre-se para finalizar seu pedido.', 'info', 4500);
      showScreen('screen-auth');
    } else {
      showScreen('screen-checkout');
    }
  };

  document.getElementById('header-cart-btn')?.addEventListener('click', handleGoToCheckout);
  document.getElementById('bottom-cart-action')?.addEventListener('click', handleGoToCheckout);
  document.getElementById('auth-back-to-cart-btn')?.addEventListener('click', () => showScreen('screen-cardapio'));

  // Avatar Header -> Drawer ou Perfil
  document.getElementById('header-avatar')?.addEventListener('click', () => {
    if (state.session) openDrawer();
    else showScreen('screen-auth');
  });

  // Atalhos de Escolha Rápida e Super Busca da Home
  setupHomeIntentShortcuts();

  document.getElementById('btn-party-order-cta')?.addEventListener('click', () => {
    selectCategory('all');
    showScreen('screen-cardapio');
  });
  document.getElementById('home-view-all-cats-btn')?.addEventListener('click', () => showScreen('screen-cardapio'));
  document.getElementById('home-view-all-prods-btn')?.addEventListener('click', () => showScreen('screen-cardapio'));
  document.getElementById('home-view-all-scheduled-btn')?.addEventListener('click', () => {
    state.activeOrderFilter = 'agendados';
    document.querySelectorAll('.filter-chip').forEach(c => {
      c.classList.toggle('active', c.dataset.filter === 'agendados');
    });
    renderOrdersList();
    showScreen('screen-orders');
  });

  // Busca no Cardápio com Debounce
  let searchTimeout = null;
  const searchInput = document.getElementById('product-search-input');
  const searchClear = document.getElementById('product-search-clear');

  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const val = e.target.value.trim();
      state.searchTerm = val;
      if (searchClear) searchClear.style.display = val ? 'block' : 'none';

      clearTimeout(searchTimeout);
      searchTimeout = setTimeout(() => {
        renderProductsGrid();
      }, 250);
    });
  }

  if (searchClear) {
    searchClear.addEventListener('click', () => {
      if (searchInput) searchInput.value = '';
      state.searchTerm = '';
      searchClear.style.display = 'none';
      renderProductsGrid();
    });
  }

  document.getElementById('btn-reset-search')?.addEventListener('click', () => {
    if (searchInput) searchInput.value = '';
    state.searchTerm = '';
    state.currentCat = 'all';
    renderCategoriesBar();
    renderProductsGrid();
  });

  // Modal de Produto Controles
  document.getElementById('modal-product-close')?.addEventListener('click', closeProductModal);
  document.getElementById('product-modal')?.addEventListener('click', (e) => {
    if (e.target.id === 'product-modal') closeProductModal();
  });

  document.getElementById('modal-qty-minus')?.addEventListener('click', () => {
    if (state.modalQty > 0) {
      state.modalQty--;
      const input = document.getElementById('modal-qty-input');
      if (input) input.value = state.modalQty;
      updateModalPrice();
    }
  });

  document.getElementById('modal-qty-plus')?.addEventListener('click', () => {
    state.modalQty++;
    const input = document.getElementById('modal-qty-input');
    if (input) input.value = state.modalQty;
    updateModalPrice();
  });

  document.getElementById('modal-qty-input')?.addEventListener('input', (e) => {
    const val = parseInt(e.target.value, 10);
    if (!isNaN(val) && val >= 0) {
      state.modalQty = val;
      updateModalPrice();
    }
  });

  document.getElementById('modal-qty-input')?.addEventListener('blur', (e) => {
    const val = parseInt(e.target.value, 10);
    if (isNaN(val) || val < 0) {
      state.modalQty = 0;
      e.target.value = 0;
      updateModalPrice();
    }
  });

  const modalQtyInput = document.getElementById('modal-qty-input');
  if (modalQtyInput) {
    modalQtyInput.addEventListener('focus', () => {
      setTimeout(() => modalQtyInput.select(), 40);
    });
  }

  document.getElementById('modal-add-btn')?.addEventListener('click', () => {
    if (!state.modalProduct) return;
    const prod = state.modalProduct;
    const targetQty = parseInt(state.modalQty, 10) || 0;
    const currentInCart = getCartQtyFor(prod.id);

    if (targetQty <= 0) {
      if (currentInCart > 0) {
        removeFromCart(prod.id);
        closeProductModal();
        toast(`🗑️ ${prod.nome} removido do pedido.`, 'info', 2000);
      } else {
        toast('Informe pelo menos 1 unidade para adicionar ao pedido.', 'info', 2500);
      }
      return;
    }

    const existing = state.cart.find(i => i.produto.id === prod.id);
    if (existing) {
      existing.qty = targetQty;
      saveCart();
      updateCartBar();
      renderProductsGrid();
      toast(`✅ Quantidade de ${prod.nome} atualizada para ${targetQty}! 🛒`, 'success', 2000);
    } else {
      state.cart.push({ produto: prod, qty: targetQty });
      saveCart();
      updateCartBar();
      renderProductsGrid();
      toast(`🛒 ${targetQty}x ${prod.nome} adicionado ao pedido!`, 'success', 2000);
    }
    closeProductModal();
  });

  // Checkout Controles
  document.getElementById('checkout-back-btn')?.addEventListener('click', () => showScreen('screen-cardapio'));

  // Stepper Interativo de Navegação do Checkout
  [1, 2, 3].forEach(stepNum => {
    document.getElementById(`step-ind-${stepNum}`)?.addEventListener('click', () => {
      const targetSec = document.getElementById(`checkout-sec-${stepNum}`);
      if (targetSec) {
        targetSec.scrollIntoView({ behavior: 'smooth', block: 'start' });
        updateCheckoutStepper(stepNum);
      }
    });
  });

  // Limpar Carrinho com confirmação de segurança
  document.getElementById('btn-limpar-carrinho')?.addEventListener('click', () => {
    if (!state.cart || state.cart.length === 0) {
      toast('Seu carrinho já está vazio!', 'info');
      return;
    }
    if (confirm('Deseja realmente esvaziar todos os itens do seu carrinho?')) {
      clearCart();
      toast('🗑️ Carrinho esvaziado com sucesso!', 'info', 2500);
    }
  });

  // Cancelar / Limpar Pedido no Checkout com confirmação
  document.getElementById('btn-cancelar-rascunho-pedido')?.addEventListener('click', () => {
    if (!state.cart || state.cart.length === 0) {
      showScreen('screen-cardapio');
      return;
    }
    if (confirm('Deseja realmente cancelar este pedido e limpar todos os itens selecionados?')) {
      clearCart();
      showScreen('screen-cardapio');
      toast('🗑️ Pedido cancelado e carrinho esvaziado.', 'info', 3000);
    }
  });

  // Enviar Pedido via WhatsApp
  document.getElementById('btn-enviar-whatsapp')?.addEventListener('click', () => {
    if (!state.cart || state.cart.length === 0) {
      toast('Seu carrinho está vazio!', 'warning');
      return;
    }
    const txt = gerarTextoResumoPedido();
    const phoneClean = getEmpresaWhatsAppClean();
    let url = `https://api.whatsapp.com/send?text=${encodeURIComponent(txt)}`;
    if (phoneClean) {
      url = `https://api.whatsapp.com/send?phone=${phoneClean}&text=${encodeURIComponent(txt)}`;
    }
    window.open(url, '_blank');
    toast('📱 Redirecionando para o WhatsApp...', 'success');
  });

  // Copiar Texto Formatado do Pedido
  document.getElementById('btn-copiar-pedido')?.addEventListener('click', () => {
    if (!state.cart || state.cart.length === 0) {
      toast('Seu carrinho está vazio!', 'warning');
      return;
    }
    const txt = gerarTextoResumoPedido();
    copiarParaClipboard(txt, '📋 Resumo do pedido copiado para a área de transferência!');
  });

  // Modalidade de Logística
  document.querySelectorAll('.logistica-card').forEach(card => {
    card.addEventListener('click', () => {
      document.querySelectorAll('.logistica-card').forEach(c => c.classList.remove('active'));
      card.classList.add('active');
      state.tipoLogistica = card.dataset.logistica;

      const endSec = document.getElementById('endereco-section');
      const retSec = document.getElementById('retirada-section');
      if (state.tipoLogistica === 'Entrega') {
        if (endSec) endSec.style.display = 'block';
        if (retSec) retSec.style.display = 'none';
        triggerAsyncRouteCalculation();
      } else {
        if (endSec) endSec.style.display = 'none';
        if (retSec) retSec.style.display = 'block';
        renderPickupStoreInfo();
      }
      updateCheckoutTotals();
      validateCheckoutForm();
    });
  });

  // Atalhos de Data no Checkout
  const dataInput = document.getElementById('checkout-data');
  const horaInput = document.getElementById('checkout-hora');

  const toYmd = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const now = new Date();
  const primEntrega = calcularPrimeiraEntregaPossivel(now, state.horariosAtendimento);

  if (dataInput && primEntrega.dataStr) {
    dataInput.value = primEntrega.dataStr;
    dataInput.min = toYmd(now);
  }

  if (horaInput && primEntrega.horaStr) {
    horaInput.value = primEntrega.horaStr;
  }

  document.querySelectorAll('.date-chip').forEach(c => c.classList.remove('active'));
  if (primEntrega.isHoje) {
    document.getElementById('btn-date-hoje')?.classList.add('active');
  } else if (primEntrega.isAmanha) {
    document.getElementById('btn-date-amanha')?.classList.add('active');
  } else {
    document.getElementById('btn-date-custom')?.classList.add('active');
  }

  document.getElementById('btn-date-hoje')?.addEventListener('click', () => {
    const pe = calcularPrimeiraEntregaPossivel(new Date(), state.horariosAtendimento);
    if (!pe.canOrder || !pe.isHoje) {
      const proximo = pe.isAmanha 
        ? `amanhã a partir das ${pe.horaStr}` 
        : `${pe.diaNome || 'próximo dia útil'} a partir das ${pe.horaStr}`;
      toast(`Não há mais janelas de entrega disponíveis para hoje. Próximo horário: ${proximo}.`, 'warning', 4500);
      return;
    }
    document.querySelectorAll('.date-chip').forEach(c => c.classList.remove('active'));
    document.getElementById('btn-date-hoje')?.classList.add('active');
    dataInput.value = toYmd(new Date());
    if (!horaInput.value || horaInput.value < pe.horaStr) {
      horaInput.value = pe.horaStr;
    }
    validateCheckoutForm();
  });

  document.getElementById('btn-date-amanha')?.addEventListener('click', () => {
    document.querySelectorAll('.date-chip').forEach(c => c.classList.remove('active'));
    document.getElementById('btn-date-amanha')?.classList.add('active');
    const d = new Date();
    d.setDate(d.getDate() + 1);
    dataInput.value = toYmd(d);
    const pe = calcularPrimeiraEntregaPossivel(new Date(), state.horariosAtendimento);
    if (pe.isAmanha && (!horaInput.value || horaInput.value < pe.horaStr)) {
      horaInput.value = pe.horaStr;
    }
    validateCheckoutForm();
  });

  document.getElementById('btn-date-custom')?.addEventListener('click', () => {
    document.querySelectorAll('.date-chip').forEach(c => c.classList.remove('active'));
    document.getElementById('btn-date-custom')?.classList.add('active');
    dataInput.focus();
  });

  // Listener de troco no checkout
  document.getElementById('checkout-troco')?.addEventListener('input', validateCheckoutForm);

  // Validação em tempo real dos campos de contato e endereço com recálculo de taxa e rota
  ['checkout-nome-cliente', 'checkout-phone-cliente', 'checkout-cep', 'checkout-logradouro', 'checkout-numero', 'checkout-bairro', 'checkout-cidade', 'checkout-data', 'checkout-hora'].forEach(id => {
    document.getElementById(id)?.addEventListener('input', () => {
      if (id === 'checkout-bairro' || id === 'checkout-cep' || id === 'checkout-logradouro' || id === 'checkout-numero') {
        updateCheckoutTotals();
        triggerAsyncRouteCalculation();
      }
      validateCheckoutForm();
    });
  });

  // Formatação de CEP com busca automática ao atingir 8 dígitos
  const formatCep = (raw) => {
    const clean = String(raw || '').replace(/\D/g, '').slice(0, 8);
    if (clean.length > 5) return `${clean.slice(0, 5)}-${clean.slice(5)}`;
    return clean;
  };

  const setupCepAutoFetch = (id, prefix) => {
    const input = document.getElementById(id);
    if (!input) return;
    input.addEventListener('input', (e) => {
      const clean = e.target.value.replace(/\D/g, '');
      e.target.value = formatCep(clean);
      if (clean.length === 8) {
        fetchViaCep(clean, prefix);
      }
    });
  };

  setupCepAutoFetch('checkout-cep', 'checkout');
  setupCepAutoFetch('reg-cep', 'reg');
  setupCepAutoFetch('account-cep', 'account');

  // Máscaras automáticas para todos os campos de telefone / WhatsApp com Amarração ao ERP Windows
  const applyMask = (e) => {
    e.target.value = formatPhone(e.target.value);
  };

  document.getElementById('checkout-phone-cliente')?.addEventListener('input', (e) => {
    applyMask(e);
    validateCheckoutForm();
  });

  const setupPhoneAutoLink = (id, prefix) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.addEventListener('input', (e) => {
      applyMask(e);
      const clean = e.target.value.replace(/\D/g, '');
      if (clean.length === 10 || clean.length === 11) {
        checkPhoneErpAutoLink(el, prefix);
      }
    });
    el.addEventListener('blur', () => {
      checkPhoneErpAutoLink(el, prefix);
    });
  };

  setupPhoneAutoLink('account-phone', 'account');
  setupPhoneAutoLink('reg-whatsapp', 'reg');
  setupPhoneAutoLink('checkout-phone-cliente', 'account');

  // Botão de trocar de conta no checkout
  document.getElementById('btn-checkout-trocar-conta')?.addEventListener('click', async () => {
    state.redirectAfterAuth = 'screen-checkout';
    await handleLogout(false);
    showScreen('screen-auth');
    toast('Faça login com a sua outra conta para continuar.', 'info', 3500);
  });

  // CEP Lookup
  document.getElementById('checkout-cep-btn')?.addEventListener('click', () => {
    const val = document.getElementById('checkout-cep')?.value || '';
    fetchViaCep(val, 'checkout');
  });

  document.getElementById('reg-cep-btn')?.addEventListener('click', () => {
    const val = document.getElementById('reg-cep')?.value || '';
    fetchViaCep(val, 'reg');
  });

  document.getElementById('account-cep-btn')?.addEventListener('click', () => {
    const val = document.getElementById('account-cep')?.value || '';
    fetchViaCep(val, 'account');
  });

  // Modal de Identificação do Cliente ("Encontramos você!")
  document.getElementById('modal-erp-found-close-btn')?.addEventListener('click', closeErpFoundModal);
  document.getElementById('btn-erp-found-confirm')?.addEventListener('click', handleConfirmFoundCustomer);
  document.getElementById('btn-erp-found-reject')?.addEventListener('click', handleRejectFoundCustomer);
  document.getElementById('btn-erp-found-edit-address')?.addEventListener('click', handleEditAddressFromModal);
  document.getElementById('modal-erp-customer-found')?.addEventListener('click', (e) => {
    if (e.target.id === 'modal-erp-customer-found') closeErpFoundModal();
  });

  // Submissão do Checkout
  document.getElementById('btn-confirmar-pedido')?.addEventListener('click', abrirModalConfirmacaoCheckout);
  document.getElementById('confirm-modal-close-btn')?.addEventListener('click', () => {
    document.getElementById('modal-confirm-checkout')?.classList.remove('open');
  });
  document.getElementById('cm-btn-edit')?.addEventListener('click', () => {
    document.getElementById('modal-confirm-checkout')?.classList.remove('open');
  });
  document.getElementById('cm-btn-confirm-final')?.addEventListener('click', submeterPedidoAoBanco);

  // Botões pós-confirmação
  document.getElementById('btn-novo-pedido')?.addEventListener('click', () => showScreen('screen-cardapio'));
  document.getElementById('btn-ver-pedidos')?.addEventListener('click', () => showScreen('screen-orders'));

  // Filtros de Meus Pedidos
  document.querySelectorAll('.order-filter-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.order-filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      state.activeOrderFilter = chip.dataset.filter;
      renderOrdersList();
    });
  });

  document.getElementById('orders-back-btn')?.addEventListener('click', () => showScreen('screen-home'));
  document.getElementById('orders-empty-cta')?.addEventListener('click', () => showScreen('screen-cardapio'));

  // Modais de Detalhe de Pedido
  document.getElementById('order-detail-close-btn')?.addEventListener('click', () => {
    document.getElementById('modal-order-detail')?.classList.remove('open');
  });
  document.getElementById('detail-close-modal-btn')?.addEventListener('click', () => {
    document.getElementById('modal-order-detail')?.classList.remove('open');
  });

  // Minha Conta
  document.getElementById('account-back-btn')?.addEventListener('click', () => showScreen('screen-home'));
  document.getElementById('form-account')?.addEventListener('submit', saveAccountChanges);
  document.getElementById('account-logout-btn')?.addEventListener('click', handleLogout);

  // Drawer
  document.getElementById('drawer-home-btn')?.addEventListener('click', () => showScreen('screen-home'));
  document.getElementById('drawer-cardapio-btn')?.addEventListener('click', () => showScreen('screen-cardapio'));
  document.getElementById('drawer-orders-btn')?.addEventListener('click', () => showScreen('screen-orders'));
  document.getElementById('drawer-profile-btn')?.addEventListener('click', () => showScreen('screen-account'));
  document.getElementById('drawer-logout-btn')?.addEventListener('click', handleLogout);
  document.getElementById('user-drawer')?.addEventListener('click', (e) => {
    if (e.target.id === 'user-drawer') closeDrawer();
  });

  // Máscara e auto-link de WhatsApp no formulário de cadastro
  const regPhoneInput = document.getElementById('reg-whatsapp');
  if (regPhoneInput) {
    regPhoneInput.addEventListener('input', (e) => {
      let v = e.target.value.replace(/\D/g, '').slice(0, 11);
      if (v.length > 6) {
        v = `(${v.slice(0, 2)}) ${v.slice(2, 7)}-${v.slice(7)}`;
      } else if (v.length > 2) {
        v = `(${v.slice(0, 2)}) ${v.slice(2)}`;
      }
      e.target.value = v;

      const clean = e.target.value.replace(/\D/g, '');
      if (clean.length >= 10) {
        checkExistingCustomerByPhone(clean);
      }
    });
  }

  // Google Auth Button
  document.getElementById('btn-google-login')?.addEventListener('click', loginWithGoogle);

  // Máscaras automáticas para todos os campos de CEP
  const formatCepInput = (e) => {
    let v = e.target.value.replace(/\D/g, '').slice(0, 8);
    if (v.length > 5) v = `${v.slice(0, 5)}-${v.slice(5)}`;
    e.target.value = v;
  };

  ['reg-cep', 'checkout-cep', 'account-cep'].forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.addEventListener('input', (e) => {
        formatCepInput(e);
        const clean = e.target.value.replace(/\D/g, '');
        if (clean.length === 8) {
          const prefix = id.split('-')[0];
          fetchViaCep(clean, prefix);
        }
      });
      el.addEventListener('blur', (e) => {
        const clean = e.target.value.replace(/\D/g, '');
        if (clean.length === 8) {
          const prefix = id.split('-')[0];
          fetchViaCep(clean, prefix);
        }
      });
    }
  });

  // Auth Tabs & Forms
  document.getElementById('tab-login')?.addEventListener('click', () => {
    document.getElementById('tab-login')?.classList.add('active');
    document.getElementById('tab-register')?.classList.remove('active');
    document.getElementById('form-login').style.display = 'block';
    document.getElementById('form-register').style.display = 'none';
  });

  document.getElementById('tab-register')?.addEventListener('click', () => {
    document.getElementById('tab-register')?.classList.add('active');
    document.getElementById('tab-login')?.classList.remove('active');
    document.getElementById('form-register').style.display = 'block';
    document.getElementById('form-login').style.display = 'none';
  });

  // Modal de Horários de Atendimento & Status da Loja
  document.getElementById('header-status-pill')?.addEventListener('click', openHorariosModal);
  document.getElementById('home-status-pill')?.addEventListener('click', openHorariosModal);
  document.getElementById('btn-ver-horarios-checkout')?.addEventListener('click', openHorariosModal);
  document.getElementById('modal-horarios-close-btn')?.addEventListener('click', closeHorariosModal);
  document.getElementById('modal-horarios-ok-btn')?.addEventListener('click', closeHorariosModal);
  document.getElementById('modal-horarios')?.addEventListener('click', (e) => {
    if (e.target.id === 'modal-horarios') closeHorariosModal();
  });

  document.getElementById('form-login')?.addEventListener('submit', handleLogin);
  document.getElementById('form-register')?.addEventListener('submit', handleRegister);
  document.getElementById('back-to-landing-btn')?.addEventListener('click', () => showScreen('screen-home'));

  // Listeners do Modo Pedido Expresso
  document.getElementById('btn-home-expresso-cta')?.addEventListener('click', () => showScreen('screen-expresso'));
  document.getElementById('expresso-back-btn')?.addEventListener('click', () => showScreen('screen-home'));
  document.getElementById('expresso-btn-ver-cardapio-completo')?.addEventListener('click', () => showScreen('screen-cardapio'));
  document.getElementById('btn-expresso-empty-go-cardapio')?.addEventListener('click', () => showScreen('screen-cardapio'));
  document.getElementById('btn-expresso-go-checkout')?.addEventListener('click', openExpressoCheckoutModal);
  document.getElementById('expresso-modal-close-btn')?.addEventListener('click', closeExpressoCheckoutModal);
  document.getElementById('btn-expresso-cancel')?.addEventListener('click', closeExpressoCheckoutModal);
  document.getElementById('btn-expresso-edit-items')?.addEventListener('click', closeExpressoCheckoutModal);

  // Alternador de Logística no Expresso
  document.getElementById('expresso-btn-entrega')?.addEventListener('click', () => {
    document.getElementById('expresso-btn-entrega')?.classList.add('active');
    document.getElementById('expresso-btn-retirada')?.classList.remove('active');
    state.expressoLogistica = 'Entrega';
    const endBox = document.getElementById('expresso-address-box');
    const retBox = document.getElementById('expresso-retirada-box');
    if (endBox) endBox.style.display = 'block';
    if (retBox) retBox.style.display = 'none';
    updateExpressoTotals();
  });

  document.getElementById('expresso-btn-retirada')?.addEventListener('click', () => {
    document.getElementById('expresso-btn-retirada')?.classList.add('active');
    document.getElementById('expresso-btn-entrega')?.classList.remove('active');
    state.expressoLogistica = 'Retirada';
    const endBox = document.getElementById('expresso-address-box');
    const retBox = document.getElementById('expresso-retirada-box');
    if (endBox) endBox.style.display = 'none';
    if (retBox) retBox.style.display = 'block';
    updateExpressoTotals();
  });

  // CEP Lookup no Expresso
  setupCepAutoFetch('expresso-cep', 'expresso');
  document.getElementById('expresso-cep-btn')?.addEventListener('click', () => {
    const val = document.getElementById('expresso-cep')?.value || '';
    fetchViaCep(val, 'expresso');
  });

  // Recálculo ao digitar Bairro no Expresso
  document.getElementById('expresso-bairro')?.addEventListener('input', updateExpressoTotals);

  // Alternância de Formas de Pagamento no Expresso
  document.querySelectorAll('input[name="expresso-payment"]').forEach(radio => {
    radio.addEventListener('change', (e) => {
      state.expressoFormaPagamento = e.target.value;
      document.querySelectorAll('.expresso-pay-chip').forEach(c => c.classList.remove('active'));
      e.target.closest('.expresso-pay-chip')?.classList.add('active');
      const trocoBox = document.getElementById('expresso-troco-box');
      if (trocoBox) {
        trocoBox.style.display = state.expressoFormaPagamento === 'Dinheiro' ? 'block' : 'none';
      }
    });
  });

  // Submissão do Formulário de Checkout Expresso
  document.getElementById('form-expresso-checkout')?.addEventListener('submit', finalizarPedidoExpresso);
}

// ─── Inicialização da Aplicação ───────────────────────────────────────
async function initApp() {
  showLoading(true, 'Iniciando portal de pedidos...');
  loadCart();
  initEventListeners();

  try {
    // 1. Carrega dados do tenant e da empresa PRIMEIRO (para saber o tenant_id da URL)
    await loadEmpresa();

    // 2. Carrega sessão do Supabase se existir
    const { data: { session } } = await sb.auth.getSession();
    state.session = session;

    // 3. Carrega perfil do usuário se já estiver logado (com o tenantId correto da URL)
    if (session) {
      await loadUserProfile();
    }

    // 4. Escuta mudanças na autenticação sem sequestrar a tela inicial
    sb.auth.onAuthStateChange(async (event, newSession) => {
      state.session = newSession;
      if (newSession) {
        await loadUserProfile();
        await loadCustomerOrders(false);

        const activeScreen = document.querySelector('.screen.active')?.id;
        const complete = isProfileComplete(state.profile);

        // Só redireciona se o usuário estava no checkout aguardando login
        if (state.redirectAfterAuth === 'screen-checkout') {
          if (!complete) {
            prepareGoogleOnboardingUI(newSession.user);
            showScreen('screen-auth');
            toast('📱 Complete seu WhatsApp e endereço para finalizar seu pedido.', 'info', 5000);
          } else {
            state.redirectAfterAuth = null;
            showScreen('screen-checkout');
            toast(`Bem-vindo(a), ${state.profile?.nome || 'Cliente'}! Continue para finalizar seu pedido.`, 'success', 3500);
          }
        } else if (state.redirectAfterAuth === 'screen-account') {
          state.redirectAfterAuth = null;
          showScreen('screen-account');
        } else if (state.redirectAfterAuth === 'screen-orders') {
          state.redirectAfterAuth = null;
          showScreen('screen-orders');
        } else if (activeScreen === 'screen-auth' && complete) {
          showScreen('screen-home');
        }
      } else {
        state.profile = null;
        resetAuthLayout();
        updateHeaderUI();
      }
    });

    // 5. Carrega catálogo de produtos e precificação em lote
    await loadCatalog();

    // 6. Carrega pedidos existentes do cliente
    if (state.session || state.profile) {
      await loadCustomerOrders();
    }

    // 7. Navegação inicial baseada estritamente nos parâmetros da URL (NUNCA bloquear visitante com cadastro)
    const urlParams = new URLSearchParams(window.location.search);
    const isModoExpresso = urlParams.get('modo') === 'expresso' || urlParams.get('expresso') === '1';
    const isModoCardapio = urlParams.get('cardapio') === '1' || urlParams.get('c') === '1';

    if (isModoExpresso) {
      showScreen('screen-expresso');
    } else if (isModoCardapio) {
      showScreen('screen-cardapio');
    } else {
      showScreen('screen-home');
    }

    // 7.1 Rastreamento Público por Link / Token (?p=UUID ou ?pedido=UUID ou ?rastreio=UUID)
    const trackId = urlParams.get('p') || urlParams.get('pedido') || urlParams.get('rastreio');
    const tenantParam = urlParams.get('tenant_id') || urlParams.get('tenant') || urlParams.get('t') || state.tenantId;
    if (trackId) {
      try {
        let orderData = null;
        const numOnly = parseInt(String(trackId).replace(/\D/g, ''), 10);

        // A. Se for UUID (contém hífen)
        if (String(trackId).includes('-')) {
          const res = await sb.from('pedido').select('*, item_pedido(*)').eq('id', trackId).maybeSingle();
          orderData = res.data;
        }

        // B. Se for número de pedido
        if (!orderData && !isNaN(numOnly) && numOnly > 0) {
          // B1. Tenta filtrar pelo tenant da URL/sessão
          if (tenantParam) {
            const resTenant = await sb
              .from('pedido')
              .select('*, item_pedido(*)')
              .eq('tenantId', tenantParam)
              .eq('numeroPedido', numOnly)
              .order('createdAt', { ascending: false })
              .limit(1);
            if (resTenant.data && resTenant.data.length > 0) {
              orderData = resTenant.data[0];
            }
          }

          // B2. Fallback: busca por número ordenando pelo mais recente
          if (!orderData) {
            const resAny = await sb
              .from('pedido')
              .select('*, item_pedido(*)')
              .eq('numeroPedido', numOnly)
              .order('createdAt', { ascending: false })
              .limit(1);
            if (resAny.data && resAny.data.length > 0) {
              orderData = resAny.data[0];
            }
          }
        }

        // C. Fallback final por id literal
        if (!orderData) {
          const res = await sb.from('pedido').select('*, item_pedido(*)').eq('id', trackId).maybeSingle();
          orderData = res.data;
        }

        if (orderData) {
          state.activeOrder = orderData;
          localStorage.setItem('fincore_last_order_id', orderData.id);

          if (!state.customerOrders.some(o => o.id === orderData.id)) {
            state.customerOrders.unshift(orderData);
          }

          if (orderData.tenantId && orderData.tenantId !== state.tenantId) {
            state.tenantId = orderData.tenantId;
            localStorage.setItem('fincore_cardapio_tenant', state.tenantId);
            await loadEmpresa();
          }

          renderOrdersList();
          renderActiveOrderWidget();
          openOrderDetailModal(orderData);
        } else {
          toast('Pedido não encontrado para o link de rastreio informado.', 'error', 4000);
        }
      } catch (e) {
        console.warn('Erro ao carregar pedido por rastreio:', e);
      }
    }

    // 8. Sincronização em tempo real dos pedidos (Polling a cada 15s + Realtime)
    setInterval(() => {
      if (state.session || state.profile) {
        loadCustomerOrders(false);
      }
    }, 15000);

    // 9. Reavaliação periódica em tempo real do status de abertura/fechamento (a cada 10 segundos)
    setInterval(updateStoreStatusUI, 10000);
    window.addEventListener('focus', updateStoreStatusUI);
    document.addEventListener('visibilitychange', () => {
      if (!document.hidden) updateStoreStatusUI();
    });

    try {
      sb.channel('realtime_pedido_sync')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'pedido' }, () => {
          if (state.session || state.profile) {
            loadCustomerOrders(false);
          }
        })
        .subscribe();
    } catch (_) {}
  } catch (err) {
    console.error('Erro na inicialização:', err);
    toast('Erro ao inicializar o portal: ' + err.message, 'error');
  } finally {
    showLoading(false);
  }
}

// Executa assim que o DOM estiver pronto
document.addEventListener('DOMContentLoaded', initApp);

