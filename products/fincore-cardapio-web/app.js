/* ═══════════════════════════════════════════════════════════════════
   FINCORE Cardápio Digital Web — app.js (v2.0.0 Gourmet Edition)
   Plataforma Completa: Home Dashboard + Cardápio + Encomendas + Pedidos + Conta
   ═══════════════════════════════════════════════════════════════════ */

'use strict';

// ─── Configurações do Supabase & Backend ─────────────────────────────
const SUPABASE_URL     = 'https://nlaxdeqbordmovukyypk.supabase.co';
const SUPABASE_ANON    = 'sb_publishable_PR7Yj7hXLnn5kuiNhbcAjg_x3sN7Xsy';
const DEFAULT_TENANT_ID = '65109ff8-443f-41ce-94c8-8311dfc79764'; // Delivery do Eli

// ─── Inicialização do Cliente Supabase ──────────────────────────────
const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON);

// ─── Estado Global da Aplicação ─────────────────────────────────────
const state = {
  session:            null,    // Sessão Supabase Auth
  profile:            null,    // Registro do cliente em cardapio_clientes
  tenantId:           DEFAULT_TENANT_ID,
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
  customerOrders:     [],      // Histórico de pedidos do cliente logado
  activeOrder:        null,    // Pedido em andamento do cliente
  searchTerm:         '',
  activeOrderFilter:  'all',
};

// ─── Horários de Funcionamento & Status da Loja ──────────────────────
function isLojaAbertaAgora() {
  const h = state.horariosAtendimento;
  if (!h) return { isOpen: true, label: 'Aberto para pedidos', badgeClass: 'aberto', motivo: 'Recebendo pedidos normalmente' };

  if (h.status === 'fechado') {
    return {
      isOpen: false,
      label: 'Fechado no momento',
      motivo: h.mensagemFechado || 'Pausado para novos pedidos',
      badgeClass: 'fechado'
    };
  }

  if (h.status === 'aberto') {
    return {
      isOpen: true,
      label: 'Aberto para pedidos',
      motivo: 'Recebendo pedidos normalmente',
      badgeClass: 'aberto'
    };
  }

  // Modo 'auto': verificar dia da semana e hora atual
  const now = new Date();
  const dayIndex = now.getDay(); // 0 = dom, 1 = seg ...
  const dayKeys = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sab'];
  const currentKey = dayKeys[dayIndex];
  const diaConfig = h.dias ? h.dias[currentKey] : null;

  if (!diaConfig || !diaConfig.ativo) {
    return {
      isOpen: false,
      label: 'Fechado hoje',
      motivo: h.mensagemFechado || 'Não abrimos neste dia da semana',
      badgeClass: 'fechado'
    };
  }

  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const [abH, abM] = (diaConfig.abertura || '08:00').split(':').map(Number);
  const [feH, feM] = (diaConfig.fechamento || '22:00').split(':').map(Number);
  const openMinutes = abH * 60 + abM;
  const closeMinutes = feH * 60 + feM;

  if (currentMinutes >= openMinutes && currentMinutes <= closeMinutes) {
    return {
      isOpen: true,
      label: `Aberto · até ${diaConfig.fechamento}`,
      motivo: `Horário de hoje: ${diaConfig.abertura} às ${diaConfig.fechamento}`,
      badgeClass: 'aberto'
    };
  } else if (currentMinutes < openMinutes) {
    return {
      isOpen: false,
      label: `Fechado · Abre às ${diaConfig.abertura}`,
      motivo: `Abre hoje às ${diaConfig.abertura}`,
      badgeClass: 'aviso'
    };
  } else {
    return {
      isOpen: false,
      label: 'Fechado agora',
      motivo: h.mensagemFechado || `Atendimento de hoje encerrado às ${diaConfig.fechamento}`,
      badgeClass: 'fechado'
    };
  }
}

function updateStoreStatusUI() {
  const statusInfo = isLojaAbertaAgora();
  const headerPill = document.getElementById('header-status-pill');
  if (headerPill) {
    headerPill.innerHTML = `<span class="pulse-dot ${statusInfo.isOpen ? '' : 'pulse-dot-red'}"></span> ${statusInfo.label}`;
    headerPill.style.cursor = 'pointer';
    headerPill.title = 'Clique para ver os horários de atendimento';
  }

  const minPrazoEl = document.getElementById('checkout-min-prazo-txt');
  if (minPrazoEl && state.horariosAtendimento) {
    const prazo = state.horariosAtendimento.prazoMinimoMinutos || 120;
    minPrazoEl.textContent = prazo >= 60 ? `${Math.round(prazo / 60)} hora(s) (${prazo} min)` : `${prazo} minutos`;
  }
}

function openHorariosModal() {
  const modal = document.getElementById('modal-horarios');
  if (!modal) return;

  const statusInfo = isLojaAbertaAgora();
  const tagEl = document.getElementById('modal-horarios-status-tag');
  if (tagEl) {
    tagEl.textContent = statusInfo.label;
    tagEl.className = `order-status-pill ${statusInfo.isOpen ? 'status-confirmado' : 'status-cancelado'}`;
  }

  const prazoEl = document.getElementById('modal-horarios-prazo-desc');
  if (prazoEl && state.horariosAtendimento) {
    const p = state.horariosAtendimento.prazoMinimoMinutos || 120;
    prazoEl.textContent = `Antecedência mínima de ${p} minutos (${(p/60).toFixed(1).replace('.0','')}h) para envio de pedidos.`;
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

  // 3. Validar Prazo Mínimo de Antecedência (em minutos)
  const prazoMin = parseInt(h.prazoMinimoMinutos || 0, 10);
  if (prazoMin > 0) {
    const diffMs = selectedDateTime.getTime() - agora.getTime();
    const diffMin = Math.floor(diffMs / (60 * 1000));
    if (diffMin < prazoMin) {
      const horasFmt = (prazoMin / 60).toFixed(1).replace('.0', '');
      const dataSugerida = new Date(agora.getTime() + prazoMin * 60000);
      const horaSugerida = dataSugerida.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
      return {
        valid: false,
        message: `Prazo mínimo de antecedência exigido: ${prazoMin} min (${horasFmt}h). Horário mais próximo permitido: a partir das ${horaSugerida}.`
      };
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
      if (cleanDigits && cleanDigits.length >= 8) {
        existingCustomer = allClients.find(c => {
          let cDigits = (c.telefone || '').replace(/\D/g, '');
          if (cDigits.length >= 12 && cDigits.startsWith('55')) cDigits = cDigits.substring(2);
          return cDigits === cleanDigits || (cDigits.length >= 10 && cleanDigits.length >= 10 && (cDigits.endsWith(cleanDigits) || cleanDigits.endsWith(cDigits)));
        });
      }

      // Se não achou por telefone, tentar por email
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

    // 3. Sincronizar endereço na tabela 'local_entrega'
    if (cust.logradouro && cust.numero && resolvedClientId) {
      const { data: existingLocais } = await sb
        .from('local_entrega')
        .select('id')
        .eq('tenantId', tenantId)
        .eq('clienteId', resolvedClientId)
        .limit(1);

      if (!existingLocais || existingLocais.length === 0) {
        const { error: locErr } = await sb.from('local_entrega').insert({
          id: crypto.randomUUID(),
          tenantId: tenantId,
          clienteId: resolvedClientId,
          nomeIdentificador: 'Endereço Principal',
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

function gerarPayloadPixEMV(chave, nome, cidade, valorCentavos, txid = '***') {
  if (!chave) return '';
  const cleanStr = (s) => (s || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toUpperCase();
  const formatField = (id, val) => {
    const len = String(val.length).padStart(2, '0');
    return `${id}${len}${val}`;
  };

  const merchantName = cleanStr(nome).slice(0, 25) || 'FINCORE FOOD';
  const merchantCity = cleanStr(cidade).slice(0, 15) || 'POUSO ALEGRE';
  const formattedValor = (valorCentavos > 0 ? (valorCentavos / 100).toFixed(2) : '');

  const gui = formatField('00', 'br.gov.bcb.pix');
  const keyField = formatField('01', chave.trim());
  const merchantAccountInfo = formatField('26', `${gui}${keyField}`);

  let payload = [
    formatField('00', '01'),
    formatField('01', '12'),
    merchantAccountInfo,
    formatField('52', '0000'),
    formatField('53', '986'),
    formattedValor ? formatField('54', formattedValor) : '',
    formatField('58', 'BR'),
    formatField('59', merchantName),
    formatField('60', merchantCity),
    formatField('62', formatField('05', txid)),
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

  return { valid: errors.length === 0, errors };
}

// ─── Toasts & Notificações ───────────────────────────────────────────
function toast(msg, type = 'info', duration = 3500) {
  const icons = { success: '✅', error: '❌', info: 'ℹ️' };
  const container = document.getElementById('toast-container');
  if (!container) return;

  const el = document.createElement('div');
  el.className = `toast toast-${type}`;
  el.innerHTML = `<span>${icons[type] || 'ℹ️'}</span><span>${msg}</span>`;
  container.appendChild(el);

  setTimeout(() => {
    el.classList.add('toast-out');
    el.addEventListener('animationend', () => el.remove());
  }, duration);
}

function showLoading(show, message = 'Carregando cardápio...') {
  const overlay = document.getElementById('loading-overlay');
  const textEl = document.getElementById('loading-text');
  if (textEl) textEl.textContent = message;
  if (overlay) overlay.style.display = show ? 'flex' : 'none';
}

// ─── Gerenciamento de Navegação Unificada ─────────────────────────────
function showScreen(screenId) {
  // Proteger áreas de gestão de conta com autenticação obrigatória
  if ((screenId === 'screen-account' || screenId === 'screen-orders') && !state.session && !state.profile) {
    state.redirectAfterAuth = screenId;
    screenId = 'screen-auth';
  }

  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const target = document.getElementById(screenId);
  if (target) {
    target.classList.add('active');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // Marcar body para ocultar a barra de navegação global inferior durante o checkout
  document.body.classList.toggle('in-checkout', screenId === 'screen-checkout');

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
  }

  updateCartBar();
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

  if (urlTenant) {
    localStorage.setItem('fincore_cardapio_tenant', urlTenant);
    return urlTenant;
  }
  return localStorage.getItem('fincore_cardapio_tenant') || null;
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
    } else {
      query = query.eq('tenant_id', DEFAULT_TENANT_ID);
    }

    let { data, error } = await query.maybeSingle();
    if (error || !data) {
      // Fallback: busca a primeira empresa disponível no view se o tenant informado não for encontrado
      const { data: fallbackEmp } = await sb.from('vw_cardapio_empresa').select('*').limit(1).maybeSingle();
      if (fallbackEmp) {
        data = fallbackEmp;
      } else {
        return;
      }
    }

    state.empresa  = data;
    state.tenantId = data.tenant_id;
    localStorage.setItem('fincore_cardapio_tenant', state.tenantId);

    // Carregar configurações de Pix, banco e endereço estendido
    try {
      const [{ data: empData }, { data: configData }, { data: fpData }] = await Promise.all([
        sb.from('empresa').select('*').eq('id', state.tenantId).maybeSingle(),
        sb.from('empresa_configuracao').select('*').eq('tenantId', state.tenantId).maybeSingle(),
        sb.from('forma_pagamento').select('*').eq('tenantId', state.tenantId).ilike('tipo', '%pix%').eq('ativo', true).maybeSingle()
      ]);

      if (empData) state.empresa = { ...data, ...empData };
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
      if (!state.empresa.chave_pix && fpData) {
        if (fpData.pixChave) state.empresa.chave_pix = fpData.pixChave;
        if (fpData.pixTipoBanco) state.empresa.pix_banco = fpData.pixTipoBanco;
        if (fpData.pixTipoChave) state.empresa.pix_tipo = fpData.pixTipoChave;
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

      const homeGreetingName = document.getElementById('home-greeting-name');
      if (homeGreetingName) homeGreetingName.textContent = nome;

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
    const homeInfoPhone = document.getElementById('home-info-phone');
    if (homeInfoPhone) {
      if (phone) {
        homeInfoPhone.textContent = `WhatsApp: ${formatPhone(phone)}`;
        homeInfoPhone.style.display = '';
      } else {
        homeInfoPhone.style.display = 'none';
      }
    }
  } catch (e) {
    console.warn('Erro ao carregar dados da empresa:', e.message);
  }
}

// ─── Carregamento de Produtos e Categorias ───────────────────────────
async function loadCatalog() {
  try {
    let query = sb.from('vw_cardapio_produtos').select('*');
    let pQuery = sb.from('vw_cardapio_precificacao').select('*');

    if (state.tenantId) {
      query = query.eq('tenant_id', state.tenantId);
      pQuery = pQuery.eq('tenant_id', state.tenantId);
    }

    const [{ data: prods, error }, { data: precData }] = await Promise.all([
      query,
      pQuery
    ]);

    if (error) throw error;
    state.produtos     = prods || [];
    state.precificacao = precData || [];

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
  } catch (e) {
    toast('Erro ao carregar cardápio: ' + e.message, 'error');
    console.error(e);
  }
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

// ─── TELA 1: HOME / DASHBOARD ─────────────────────────────────────────
async function renderHome() {
  // Saudação personalizada (somente cliente, nunca duplicar empresa)
  const welcomeBadge = document.getElementById('home-welcome-badge');
  const greetingSub = document.getElementById('home-greeting-sub');
  if (welcomeBadge) {
    if (state.profile?.nome) {
      const firstName = state.profile.nome.trim().split(' ')[0];
      welcomeBadge.textContent = `Olá, ${firstName}!`;
    } else {
      welcomeBadge.textContent = `Olá!`;
    }
  }
  if (greetingSub) {
    greetingSub.textContent = 'O que você deseja fazer hoje?';
  }

  // 1. Pedido Ativo em Andamento (se houver)
  await renderActiveOrderWidget();

  // 2. Próximas Encomendas Agendadas Futuras (se houver)
  renderHomeScheduledOrders();

  // 3. Compre Novamente (se houver histórico de pedidos concluídos)
  renderHomeReorderSection();

  // 4. Produtos Mais Pedidos do Cardápio
  renderHomeFeaturedProducts();

  // 5. Categorias Reais do Cadastro
  renderHomeCategories();

  // 6. Tabela de Preços por Quantidade (Lote)
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

function renderHomeCategories() {
  const container = document.getElementById('home-categories-grid');
  if (!container) return;

  if (state.categorias.length === 0) {
    container.innerHTML = `<div style="grid-column: 1/-1; color: var(--text-muted); font-size:13px;">Carregando categorias...</div>`;
    return;
  }

  container.innerHTML = state.categorias.map(cat => {
    const count = state.produtos.filter(p => p.categoria_id === cat.id).length;
    return `
      <div class="home-cat-card" data-cat-id="${cat.id}">
        <div class="home-cat-icon">${cat.icone}</div>
        <div class="home-cat-name">${cat.nome}</div>
        <div class="home-cat-count">${count} ${count === 1 ? 'opção' : 'opções'}</div>
      </div>
    `;
  }).join('');

  container.querySelectorAll('.home-cat-card').forEach(card => {
    card.addEventListener('click', () => {
      selectCategory(card.dataset.catId);
      showScreen('screen-cardapio');
    });
  });
}

function renderHomeFeaturedProducts() {
  const container = document.getElementById('home-featured-grid');
  if (!container) return;

  // Pegar os 6 primeiros produtos com prioridade
  const featured = state.produtos.slice(0, 6);
  if (featured.length === 0) {
    container.innerHTML = `<div style="grid-column: 1/-1; color: var(--text-muted); font-size:13px;">Nenhum produto cadastrado no momento.</div>`;
    return;
  }

  container.innerHTML = featured.map(prod => createProductCardHtml(prod, false)).join('');
  attachProductCardEvents(container);
}

// Mapeamento Canônico de Status do Kanban para Exibição
const KANBAN_STATUS_MAP = {
  pendente:            { label: 'Recebido',             icon: '📋' },
  recebido:            { label: 'Recebido',             icon: '📋' },
  confirmado:          { label: 'Recebido',             icon: '📋' },
  em_preparo:          { label: 'Em Preparação',        icon: '🍳' },
  empreparo:           { label: 'Em Preparação',        icon: '🍳' },
  pronto:              { label: 'Pronto',               icon: '📦' },
  aguardando_retirada: { label: 'Pronto para Retirada', icon: '📦' },
  saiu_para_entrega:   { label: 'Saiu para Entrega 🛵', icon: '🛵' },
  saiuparaentrega:     { label: 'Saiu para Entrega 🛵', icon: '🛵' },
  saiu_entrega:        { label: 'Saiu para Entrega 🛵', icon: '🛵' },
  em_entrega:          { label: 'Saiu para Entrega 🛵', icon: '🛵' },
  em_transito:         { label: 'Saiu para Entrega 🛵', icon: '🛵' },
  a_caminho:           { label: 'A Caminho 🛵',         icon: '🛵' },
  entregue:            { label: 'Entregue',             icon: '✅' },
  concluido:           { label: 'Entregue',             icon: '✅' },
  finalizado:          { label: 'Entregue',             icon: '✅' },
  cancelado:           { label: 'Cancelado',            icon: '❌' },
};

async function renderActiveOrderWidget() {
  const container = document.getElementById('home-active-order-container');
  const card      = document.getElementById('home-active-order-card');
  const dot       = document.getElementById('bnav-orders-dot');

  if (!container || !card) return;

  if (!state.session && !state.profile) {
    container.style.display = 'none';
    if (dot) dot.style.display = 'none';
    return;
  }

  // Permanece na tela da dashboard até REALMENTE SER ENTREGUE (ou cancelado)
  const activeOrders = state.customerOrders.filter(o => {
    const st = String(o.status || '').toLowerCase().trim();
    return st !== 'entregue' && st !== 'concluido' && st !== 'finalizado' && st !== 'cancelado';
  });

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

  const statusInfo = KANBAN_STATUS_MAP[o.status] || { label: o.status, icon: '⚡' };
  const statusLabel = statusInfo.label;
  const statusIcon  = statusInfo.icon;

  card.innerHTML = `
    <div class="active-order-info">
      <div class="active-order-icon">${statusIcon}</div>
      <div>
        <div class="active-order-num">Pedido #${num} • ${total}</div>
        <div class="active-order-desc">Previsão: <strong>${dataHoraPrev}</strong> (${o.tipoLogistica || 'Entrega'})</div>
        <span class="active-order-status-tag status-${o.status}">${statusLabel}</span>
      </div>
    </div>
    <button type="button" class="btn btn-primary btn-sm" id="btn-home-track-active-order">
      🔍 Acompanhar Pedido
    </button>
  `;

  document.getElementById('btn-home-track-active-order')?.addEventListener('click', () => {
    openOrderDetailModal(o);
  });
}

function renderHomeReorderSection() {
  const container = document.getElementById('home-reorder-section');
  const card = document.getElementById('home-reorder-card');
  if (!container || !card) return;

  // Pegar último pedido concluído
  const completedOrders = state.customerOrders.filter(o =>
    o.status === 'concluido' || o.status === 'entregue' || o.status === 'finalizado'
  );

  if (completedOrders.length > 0) {
    const lastOrder = completedOrders[0];
    container.style.display = 'flex';

    card.innerHTML = `
      <div class="reorder-items-preview">
        <span class="reorder-order-header">ÚLTIMO PEDIDO #${lastOrder.numeroPedido || lastOrder.id.slice(0, 6)} • ${fmtDate(lastOrder.createdAt)}</span>
        <span class="reorder-items-text">${lastOrder.tipoLogistica} • ${fmt(lastOrder.valorTotalCentavos)}</span>
        <span class="reorder-total-text">Clique para adicionar todos os itens deste pedido ao seu carrinho agora mesmo.</span>
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

// Badge de categoria: somente na Home (seção "Produtos do Cardápio")
// Não repetir no card se a seção já contextualiza a categoria.
// Mantemos apenas no modo de busca/filtragem individual (screen-cardapio)
// A função recebe showCatBadge=true para exibir, false para ocultar
function createProductCardHtml(prod, showCatBadge = false) {
  const tiers = getTiersForProduct(prod);
  // Preço base unitário de catálogo (independente do carrinho)
  const catalogBasePrice = getBaseUnitPrice(prod);
  const inCartQty = getCartQtyFor(prod.id);

  // Garante que o ícone é sempre um emoji — nunca um slug Material Design
  const catIcon = getCategoryIcon(prod.categoria_icone, prod.categoria_nome);
  const catNameClean = sanitizeCategoryName(prod.categoria_nome);

  // Área de Imagem/Ícone:
  // - Se tiver imagem no banco de dados (URL válida) → exibe a imagem real do produto
  // - Se não tiver imagem (ou for inválida) → fallback para o emoji da categoria
  let mediaHtml = '';
  const imgUrl = getProductImageUrl(prod);
  if (imgUrl) {
    mediaHtml = `
      <img src="${imgUrl}" alt="${prod.nome}" class="product-card-img" loading="lazy"
           onerror="this.style.display='none';this.nextElementSibling.style.display='flex'" />
      <div class="product-card-fallback-icon" style="display:none">${catIcon}</div>
    `;
  } else {
    // Slug de ícone (ex: "fastfood") ou vazio → exibe emoji da categoria
    mediaHtml = `<div class="product-card-fallback-icon">${catIcon}</div>`;
  }

  // Pill de Lote: mostra a faixa de maior desconto da categoria de forma estável e consistente
  let tierPillHtml = '';
  if (tiers && tiers.length > 1) {
    // Pega o tier com maior quantidade (maior desconto)
    const bestTier = tiers[tiers.length - 1];
    const minQty = bestTier.qtd_minima;
    const discountPct = calculateDiscountPercent(catalogBasePrice, bestTier.valor_unitario_centavos);
    const discountTag = discountPct > 0 ? ` <strong class="tier-pill-discount">(${discountPct}% OFF)</strong>` : '';
    tierPillHtml = `<span class="product-card-tier-pill">🛒 A partir de ${minQty} un: ${fmt(bestTier.valor_unitario_centavos)}/un${discountTag}</span>`;
  }

  const descClean = (prod.descricao && String(prod.descricao).trim()) ? String(prod.descricao).trim() : '';

  return `
    <article class="product-card" data-prod-id="${prod.id}">
      <div class="product-card-media">
        ${showCatBadge ? `<span class="product-card-badge-cat">${catIcon} ${catNameClean}</span>` : ''}
        ${inCartQty > 0 ? `<span class="product-card-cart-qty-badge">${inCartQty} no pedido</span>` : ''}
        ${mediaHtml}
      </div>
      <div class="product-card-body">
        <h3 class="product-card-title">${prod.nome}</h3>
        ${descClean ? `<p class="product-card-desc">${descClean}</p>` : ''}
        ${tierPillHtml}
      </div>
      <div class="product-card-footer">
        <div class="product-card-price-wrap">
          <span class="product-card-price-label">A partir de</span>
          <span class="product-card-price">${fmt(catalogBasePrice)}/un</span>
        </div>
        <button type="button" class="btn btn-primary product-card-add-btn" data-prod-id="${prod.id}">
          + Adicionar
        </button>
      </div>
    </article>
  `;
}

function attachProductCardEvents(container) {
  container.querySelectorAll('.product-card').forEach(card => {
    card.addEventListener('click', (e) => {
      const prodId = card.dataset.prodId;
      const prod = state.produtos.find(p => p.id === prodId);
      if (prod) openProductModal(prod);
    });
  });
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
  state.modalQty = getMinQtyForCategory(prod.categoria_id) || 1;

  const modal = document.getElementById('product-modal');
  const nameEl = document.getElementById('modal-prod-name');
  const descEl = document.getElementById('modal-prod-desc');
  const priceEl = document.getElementById('modal-prod-price');
  const catEl = document.getElementById('modal-prod-cat');
  const imageArea = document.getElementById('modal-image-area');
  const qtyInput = document.getElementById('modal-qty-input');
  const tiersContainer = document.getElementById('modal-pricing-tiers');

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
  if (qtyInput) qtyInput.value = state.modalQty;

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
  const unitPrice = getPreco(prod, state.modalQty);
  const totalPrice = unitPrice * state.modalQty;

  const priceEl = document.getElementById('modal-prod-price');
  if (priceEl) {
    priceEl.innerHTML = `${fmt(totalPrice)} <small style="font-size:12px;color:var(--text-muted);font-weight:600">(${fmt(unitPrice)} /un)</small>`;
  }

  // Destacar faixa ativa na tabela de tiers
  const tiers = getTiersForProduct(prod);
  if (tiers && tiers.length > 0) {
    tiers.forEach(t => {
      const row = document.getElementById(`tier-row-${t.qtd_minima}`);
      if (row) {
        const isActive = state.modalQty >= t.qtd_minima && (!t.qtd_maxima || state.modalQty <= t.qtd_maxima);
        row.classList.toggle('active-tier', isActive);
      }
    });
  }
}

// ─── TELA 3: CHECKOUT & ENCOMENDAS ────────────────────────────────────
function renderCheckoutPage() {
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

  // Totais
  const total = cartTotal();
  if (subtotalEl) subtotalEl.textContent = fmt(total);
  if (totalEl) totalEl.textContent = fmt(total);

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

  // Preenchimento de identificação e endereço salvo se o usuário estiver logado
  populateSavedAddressInCheckout();
  validateCheckoutForm();
}

function populateSavedAddressInCheckout() {
  // 1. Contato do Cliente: Se estiver logado, não precisa pedir dados de contato
  const isLogged = !!(state.session || (state.profile && state.profile.nome));
  const contactSection = document.getElementById('checkout-contact-section');
  const loggedUserBox = document.getElementById('checkout-logged-user-box');
  const loggedUserName = document.getElementById('checkout-logged-user-name');
  const loggedUserPhone = document.getElementById('checkout-logged-user-phone');

  const nomeInput = document.getElementById('checkout-nome-cliente');
  const phoneInput = document.getElementById('checkout-phone-cliente');

  if (isLogged) {
    if (contactSection) contactSection.style.display = 'none';
    if (loggedUserBox) loggedUserBox.style.display = 'block';
    const nome = state.profile?.nome || 'Cliente Cadastrado';
    const phone = formatPhone(state.profile?.whatsapp || '');
    if (loggedUserName) loggedUserName.textContent = nome;
    if (loggedUserPhone) loggedUserPhone.textContent = phone || 'Sem telefone';
    if (nomeInput) nomeInput.value = nome;
    if (phoneInput) phoneInput.value = phone;
  } else {
    if (contactSection) contactSection.style.display = 'block';
    if (loggedUserBox) loggedUserBox.style.display = 'none';
    let savedContact = null;
    try {
      savedContact = JSON.parse(localStorage.getItem('fincore_guest_contact') || 'null');
    } catch (_) {}
    if (nomeInput && !nomeInput.value) {
      nomeInput.value = savedContact?.nome || '';
    }
    if (phoneInput && !phoneInput.value) {
      phoneInput.value = formatPhone(savedContact?.phone || '');
    }
  }

  // 2. Endereço Salvo / Cadastrado
  let savedAddr = null;
  try {
    savedAddr = JSON.parse(localStorage.getItem('fincore_saved_address') || 'null');
  } catch (_) {}

  const savedBox = document.getElementById('checkout-saved-address-box');
  const savedText = document.getElementById('checkout-saved-address-text');
  const formContainer = document.getElementById('checkout-address-form-container');
  const btnAddNovo = document.getElementById('btn-add-novo-endereco');
  const btnVoltarSalvo = document.getElementById('btn-voltar-endereco-salvo');

  if (!savedBox || !formContainer) return;

  const hasProfileAddress = state.profile && (state.profile.logradouro || state.profile.endereco_padrao);
  const hasLocalAddress = savedAddr && savedAddr.logradouro && savedAddr.numero;

  const activeSaved = hasProfileAddress ? {
    logradouro: state.profile.logradouro,
    numero: state.profile.numero,
    bairro: state.profile.bairro,
    cidade: state.profile.cidade,
    uf: state.profile.uf || 'SP',
    complemento: state.profile.complemento || '',
    referencia: state.profile.referencia || '',
    cep: state.profile.cep || ''
  } : (hasLocalAddress ? savedAddr : null);

  const cepEl = document.getElementById('checkout-cep');
  const logrEl = document.getElementById('checkout-logradouro');
  const numEl = document.getElementById('checkout-numero');
  const bairEl = document.getElementById('checkout-bairro');
  const cidEl = document.getElementById('checkout-cidade');
  const ufEl = document.getElementById('checkout-uf');
  const compEl = document.getElementById('checkout-complemento');
  const refEl = document.getElementById('checkout-referencia');

  if (activeSaved) {
    const formatted = `${activeSaved.logradouro}, ${activeSaved.numero}${activeSaved.complemento ? ' (' + activeSaved.complemento + ')' : ''} - ${activeSaved.bairro}, ${activeSaved.cidade} - ${activeSaved.uf}`;
    if (savedText) savedText.textContent = formatted;

    savedBox.style.display = 'block';
    formContainer.style.display = 'none';

    if (cepEl) cepEl.value = activeSaved.cep || '';
    if (logrEl) logrEl.value = activeSaved.logradouro || '';
    if (numEl) numEl.value = activeSaved.numero || '';
    if (bairEl) bairEl.value = activeSaved.bairro || '';
    if (cidEl) cidEl.value = activeSaved.cidade || '';
    if (ufEl) ufEl.value = activeSaved.uf || 'SP';
    if (compEl) compEl.value = activeSaved.complemento || '';
    if (refEl) refEl.value = activeSaved.referencia || '';

    if (btnAddNovo) {
      btnAddNovo.onclick = () => {
        savedBox.style.display = 'none';
        formContainer.style.display = 'block';
        if (btnVoltarSalvo) btnVoltarSalvo.style.display = 'inline-block';
        if (logrEl) {
          logrEl.value = '';
          if (numEl) numEl.value = '';
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
        if (cepEl) cepEl.value = activeSaved.cep || '';
        if (logrEl) logrEl.value = activeSaved.logradouro || '';
        if (numEl) numEl.value = activeSaved.numero || '';
        if (bairEl) bairEl.value = activeSaved.bairro || '';
        if (cidEl) cidEl.value = activeSaved.cidade || '';
        if (ufEl) ufEl.value = activeSaved.uf || 'SP';
        validateCheckoutForm();
      };
    }
  } else {
    savedBox.style.display = 'none';
    formContainer.style.display = 'block';
    if (btnVoltarSalvo) btnVoltarSalvo.style.display = 'none';
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

  // Validação de Contato do Cliente (se logado, valida com os dados do perfil)
  const isLogged = !!(state.session || (state.profile && state.profile.nome));
  let nomeCliente = '';
  let phoneCliente = '';

  if (isLogged) {
    nomeCliente = state.profile?.nome || document.getElementById('checkout-nome-cliente')?.value.trim() || 'Cliente';
    phoneCliente = (state.profile?.whatsapp || document.getElementById('checkout-phone-cliente')?.value || '').replace(/\D/g, '');
  } else {
    nomeCliente = document.getElementById('checkout-nome-cliente')?.value.trim() || '';
    phoneCliente = (document.getElementById('checkout-phone-cliente')?.value || '').replace(/\D/g, '');
  }

  if (nomeCliente.length < 2) {
    warning.className = 'validation-warning-box invalid';
    msgEl.textContent = 'Por favor, informe seu Nome Completo para identificação do pedido.';
    submitBtn.disabled = true;
    return;
  }

  if (phoneCliente.length < 8) {
    warning.className = 'validation-warning-box invalid';
    msgEl.textContent = 'Por favor, informe seu WhatsApp / Telefone com DDD.';
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
}

// ─── Criação e Confirmação de Pedidos (100% Real Supabase Schema) ──────
async function abrirModalConfirmacaoCheckout() {
  const val = validateMinimumCategoryQuantities();
  if (!val.valid) {
    toast(val.message, 'error', 4000);
    return;
  }

  const isLogged = !!(state.session || (state.profile && state.profile.nome));
  const nome = isLogged
    ? (state.profile?.nome || document.getElementById('checkout-nome-cliente')?.value.trim() || 'Cliente')
    : (document.getElementById('checkout-nome-cliente')?.value.trim() || '');
  const phone = isLogged
    ? (state.profile?.whatsapp || document.getElementById('checkout-phone-cliente')?.value.trim() || '')
    : (document.getElementById('checkout-phone-cliente')?.value.trim() || '');

  if (nome.length < 2) {
    toast('Por favor, preencha o seu nome completo.', 'error');
    if (!isLogged) document.getElementById('checkout-nome-cliente')?.focus();
    return;
  }

  if (phone.replace(/\D/g, '').length < 8) {
    toast('Por favor, informe seu telefone / WhatsApp.', 'error');
    if (!isLogged) document.getElementById('checkout-phone-cliente')?.focus();
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
  document.getElementById('cm-subtotal-val').textContent = fmt(subtotal);
  document.getElementById('cm-total-val').textContent = fmt(subtotal);

  // Pix no Modal
  const pixBox = document.getElementById('cm-pix-box');
  if (pixBox && state.formaPagamentoNome === 'Pix' && state.empresa?.chave_pix) {
    pixBox.style.display = 'block';
    document.getElementById('cm-pix-favorecido').textContent = state.empresa.pix_favorecido || state.empresa.nomeFantasia || 'FinCore Food';
    document.getElementById('cm-pix-banco').textContent = state.empresa.pix_banco || 'Instituição Bancária';
    document.getElementById('cm-pix-tipo').textContent = state.empresa.pix_tipo || 'Chave';
    document.getElementById('cm-pix-chave').textContent = state.empresa.chave_pix;

    const payload = gerarPayloadPixEMV(state.empresa.chave_pix, state.empresa.pix_favorecido, state.empresa?.cidade || 'Pouso Alegre', subtotal);
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
  const total = cartTotal();

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
  txt += `💰 *TOTAL GERAL: ${fmt(total)}*\n`;

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
  const btnFinal = document.getElementById('cm-btn-confirm-final');
  if (btnFinal) {
    btnFinal.disabled = true;
    btnFinal.textContent = '⏳ Enviando Pedido...';
  }

  try {
    const data = document.getElementById('checkout-data').value;
    const hora = document.getElementById('checkout-hora').value;
    const obs = document.getElementById('checkout-obs').value.trim();

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

    // Salvar no localStorage para agilizar próximas compras
    try {
      localStorage.setItem('fincore_guest_contact', JSON.stringify({ nome, phone }));
      if (logr && num) {
        localStorage.setItem('fincore_saved_address', JSON.stringify({
          logradouro: logr,
          numero: num,
          bairro: bair,
          cidade: cid,
          uf: uf,
          complemento: comp,
          referencia: ref,
          cep: cep
        }));
      }
    } catch (_) {}

    const fullAddressStr = [
      `${logr}, ${num}`,
      comp ? `(${comp})` : '',
      bair,
      `${cid} - ${uf}`,
      cep ? `CEP: ${cep}` : ''
    ].filter(Boolean).join(' - ');

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
      taxaEntregaCentavos: 0
    };

    let dataEntrega = null;
    if (data && hora) {
      dataEntrega = new Date(`${data}T${hora}:00`).toISOString();
    }

    let trocoCentavos = null;
    if (state.formaPagamentoNome === 'Dinheiro') {
      const trocoVal = document.getElementById('checkout-troco')?.value.trim();
      if (trocoVal) {
        const n = parseFloat(trocoVal.replace(',', '.').replace(/[^\d.]/g, ''));
        if (!isNaN(n) && n > 0) trocoCentavos = Math.round(n * 100);
      }
    }

    const subtotal = cartTotal();
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

    const userIdValid = (state.profile?.id && state.profile.id.includes('-'))
      ? state.profile.id
      : (state.session?.user?.id || '00000000-0000-0000-0000-000000000000');

    const targetClienteLocalId = erpCliente?.id || state.profile?.cliente_local_id || state.profile?.clienteLocalId || state.profile?.id || null;
    const finalClienteNome = erpCliente?.nome || nome;
    const finalClienteTelefone = erpCliente?.telefone ? formatPhone(erpCliente.telefone) : (formatPhone(phone) || null);

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
      valorTaxaEntregaCentavos:  0,
      valorTotalCentavos:        subtotal,
      trocoParaCentavos:         trocoCentavos,
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
        `cliente: ${state.profile?.nome || 'Consumidor'}`,
        `telefone: ${state.profile?.whatsapp ? state.profile.whatsapp.replace(/\\D/g, '') : ''}`,
        `tipo: ${state.tipoLogistica}`,
        `pagamento: ${pagDesc}`,
        `total: ${subtotal}`,
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
  if (order.formaPagamentoNome === 'Pix' && pixContainer) {
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

      const payload = gerarPayloadPixEMV(chave, favorecido, state.empresa?.cidade || 'Pouso Alegre', order.valorTotalCentavos, order.numeroPedido || order.id.slice(0, 6));

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
  } else if (pixContainer) {
    pixContainer.style.display = 'none';
  }

  renderTimeline(order.status || 'confirmado');
}

function renderTimeline(status) {
  const container = document.getElementById('status-timeline');
  if (!container) return;

  const steps = [
    { key: 'pendente',     label: 'Aguardando Aprovação' },
    { key: 'confirmado',   label: 'Aprovado / Na Fila' },
    { key: 'em_preparo',   label: 'Em Preparo' },
    { key: 'pronto',       label: 'Pronto' },
    { key: 'entregue',     label: 'Entregue' }
  ];

  const getIdx = (st) => {
    const s = String(st || '').toLowerCase().trim();
    if (s === 'pendente' || s === 'aguardando_aprovacao' || s === 'rascunho') return 0;
    if (s === 'recebido' || s === 'confirmado' || s === 'aprovado') return 1;
    if (s === 'em_preparo' || s === 'empreparo' || s === 'preparando') return 2;
    if (s === 'pronto' || s === 'aguardando_retirada') return 3;
    if (s === 'saiu_para_entrega' || s === 'saiuparaentrega' || s === 'saiu_entrega' || s === 'em_entrega' || s === 'em_transito' || s === 'entregue' || s === 'concluido' || s === 'finalizado') return 4;
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

  if (!state.session && !state.profile) {
    if (container) container.innerHTML = '';
    if (emptyState) emptyState.style.display = 'flex';
    return;
  }

  if (showSpinner) showLoading(true, 'Carregando seus pedidos...');

  try {
    const phone = state.profile?.whatsapp ? formatPhone(state.profile.whatsapp) : null;
    const clientLocalId = state.profile?.cliente_local_id || state.profile?.id;

    let query = sb
      .from('pedido')
      .select('*, item_pedido(*)')
      .eq('tenantId', state.tenantId || DEFAULT_TENANT_ID)
      .order('createdAt', { ascending: false });

    // Filtrar pelo cliente logado
    if (clientLocalId) {
      query = query.or(`clienteId.eq.${clientLocalId},clienteTelefoneAvulso.eq.${phone},clienteTelefoneAvulso.eq.${state.profile?.whatsapp}`);
    } else if (phone) {
      query = query.or(`clienteTelefoneAvulso.eq.${phone},clienteTelefoneAvulso.eq.${state.profile?.whatsapp}`);
    }

    const { data, error } = await query.limit(20);
    if (error) throw error;

    state.customerOrders = data || [];
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
        pendente:            '📋 Aguardando Aprovação',
        recebido:            '📋 Aprovado / Na Fila',
        confirmado:          '📋 Aprovado / Na Fila',
        em_preparo:          '🍳 Em Preparação',
        pronto:              '📦 Pronto',
        aguardando_retirada: '📦 Pronto para Retirada',
        saiu_entrega:        '🛵 Saiu para Entrega',
        em_entrega:          '🛵 Saiu para Entrega',
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

// ─── Funcionalidade "Comprar Novamente" (1-Clique) ────────────────────
async function reorderOrder(orderId) {
  const order = state.customerOrders.find(o => o.id === orderId);
  if (!order) return;

  showLoading(true, 'Carregando itens para o carrinho...');

  try {
    let items = order.item_pedido;
    if (!items || items.length === 0) {
      const { data } = await sb.from('item_pedido').select('*').eq('pedidoId', orderId);
      items = data || [];
    }

    if (items.length === 0) {
      toast('Não foi possível recuperar os itens deste pedido.', 'error');
      return;
    }

    // Limpa o carrinho e adiciona os itens do pedido anterior
    state.cart = [];
    for (const item of items) {
      let prod = state.produtos.find(p => p.id === item.produtoId);
      if (!prod) {
        prod = {
          id: item.produtoId,
          nome: item.nomeProduto,
          categoria_id: 'default',
          categoria_nome: 'Geral',
          categoria_icone: '🍽️',
          metadata: { preco_base: (item.valorUnitarioCentavos / 100).toFixed(2) }
        };
      }
      state.cart.push({
        produto: prod,
        qty: item.quantidade
      });
    }

    saveCart();
    updateCartBar();
    showScreen('screen-checkout');
    toast('🎉 Itens carregados no carrinho! Revise e finalize seu pedido.', 'success', 4000);
  } catch (err) {
    toast('Erro ao repetir pedido: ' + err.message, 'error');
  } finally {
    showLoading(false);
  }
}

function openOrderDetailModal(order) {
  const modal = document.getElementById('modal-order-detail');
  if (!modal) return;

  const st = String(order.status || 'pendente').toLowerCase().trim();
  const STATUS_MODAL_LABELS = {
    pendente:            { label: '📋 Aguardando Aprovação', icon: '📋' },
    recebido:            { label: '📋 Aprovado / Na Fila', icon: '📋' },
    confirmado:          { label: '📋 Aprovado / Na Fila', icon: '📋' },
    em_preparo:          { label: '🍳 Em Preparação', icon: '🍳' },
    pronto:              { label: '📦 Pronto', icon: '📦' },
    aguardando_retirada: { label: '📦 Pronto para Retirada', icon: '📦' },
    saiu_entrega:        { label: '🛵 Saiu para Entrega', icon: '🛵' },
    em_entrega:          { label: '🛵 Saiu para Entrega', icon: '🛵' },
    concluido:           { label: '✅ Entregue', icon: '✅' },
    entregue:            { label: '✅ Entregue', icon: '✅' },
    finalizado:          { label: '✅ Entregue', icon: '✅' },
    cancelado:           { label: '❌ Cancelado', icon: '❌' },
  };
  const statusInfo = STATUS_MODAL_LABELS[st] || { label: order.status || 'Pendente', icon: '⚡' };

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

  // Timeline
  const timelineEl = document.getElementById('detail-status-timeline');
  if (timelineEl) {
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

  // Bloco Pix no Detalhe do Pedido (se forma for Pix)
  const pixContainer = document.getElementById('detail-pix-container');
  if (pixContainer) {
    const isPix = String(order.formaPagamentoNome || '').toLowerCase().includes('pix');
    const chave = state.empresa?.chave_pix || '';
    const favorecido = state.empresa?.pix_favorecido || state.empresa?.nomeFantasia || 'FinCore Food';
    const banco = state.empresa?.pix_banco || 'Instituição Bancária';
    const tipo = state.empresa?.pix_tipo || 'Chave';

    if (isPix && chave) {
      pixContainer.style.display = 'block';
      document.getElementById('detail-pix-favorecido').textContent = favorecido;
      document.getElementById('detail-pix-banco').textContent = banco;
      document.getElementById('detail-pix-tipo').textContent = tipo;
      document.getElementById('detail-pix-chave').textContent = chave;

      const payload = gerarPayloadPixEMV(chave, favorecido, state.empresa?.cidade || 'Pouso Alegre', order.valorTotalCentavos, order.numeroPedido || order.id.slice(0, 6));

      const btnPayload = document.getElementById('btn-detail-copiar-pix-payload');
      if (btnPayload) {
        btnPayload.onclick = () => {
          copiarParaClipboard(payload, 'Pix Copia e Cola copiado! Cole no app do seu banco.');
        };
      }

      const btnChave = document.getElementById('btn-detail-copiar-pix-chave');
      if (btnChave) {
        btnChave.onclick = () => {
          copiarParaClipboard(chave, 'Chave Pix copiada com sucesso!');
        };
      }
    } else {
      pixContainer.style.display = 'none';
    }
  }

  document.getElementById('detail-reorder-btn').onclick = () => {
    modal.classList.remove('open');
    reorderOrder(order.id);
  };

  modal.classList.add('open');
}

// ─── TELA 5: MINHA CONTA / PERFIL ────────────────────────────────────
function populateAccountForm() {
  if (!state.profile) return;
  const p = state.profile;

  document.getElementById('account-user-display-name').textContent = p.nome || 'Seu Nome';
  document.getElementById('account-user-display-email').textContent = p.email || p.whatsapp || '';

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

  if (nameEl) nameEl.value = p.nome || '';
  if (phoneEl) phoneEl.value = p.whatsapp || '';
  if (emailEl) emailEl.value = p.email || '';
  if (cepEl) cepEl.value = p.cep || '';
  if (ufEl) ufEl.value = p.uf || 'SP';
  if (logrEl) logrEl.value = p.logradouro || '';
  if (numEl) numEl.value = p.numero || '';
  if (bairEl) bairEl.value = p.bairro || '';
  if (cidEl) cidEl.value = p.cidade || '';
  if (compEl) compEl.value = p.complemento || '';
  if (refEl) refEl.value = p.referencia || '';
}

async function saveAccountChanges(e) {
  e.preventDefault();
  if (!state.session || !state.profile) {
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

  const fullAddress = [
    `${logr}, ${num}`,
    comp ? `(${comp})` : '',
    bair,
    `${cid} - ${uf}`,
    cep ? `CEP: ${cep}` : ''
  ].filter(Boolean).join(' - ');

  showLoading(true, 'Salvando alterações...');

  try {
    const { error } = await sb
      .from('cardapio_clientes')
      .update({
        nome,
        whatsapp: phone,
        email,
        cep,
        uf,
        logradouro: logr,
        numero: num,
        bairro: bair,
        cidade: cid,
        complemento: comp || null,
        referencia: ref || null,
        endereco_padrao: fullAddress
      })
      .eq('id', state.profile.id);

    if (error) throw error;

    state.profile = {
      ...state.profile,
      nome, whatsapp: phone, email, cep, uf,
      logradouro: logr, numero: num, bairro: bair,
      cidade: cid, complemento: comp, referencia: ref,
      endereco_padrao: fullAddress
    };

    // Sincronizar alterações com cadastro de cliente no ERP
    await syncCustomerToErp({
      nome,
      telefone: phone,
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

    updateHeaderUI();
    toast('✅ Dados atualizados com sucesso!', 'success');
  } catch (err) {
    toast('Erro ao atualizar dados: ' + err.message, 'error');
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
    toast('Preencha e-mail/telefone e senha.', 'error');
    return;
  }

  showLoading(true, 'Entrando na sua conta...');
  try {
    let emailToUse = emailOrPhone;
    if (!emailOrPhone.includes('@')) {
      const cleanPhone = emailOrPhone.replace(/\D/g, '');
      emailToUse = `user_${cleanPhone}@fincore.com`;
    }

    const { data, error } = await sb.auth.signInWithPassword({
      email: emailToUse,
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
  const email = document.getElementById('reg-email')?.value.trim();
  const password = document.getElementById('reg-password')?.value;

  const cep = document.getElementById('reg-cep')?.value.trim();
  const uf = document.getElementById('reg-uf')?.value.trim();
  const logr = document.getElementById('reg-logradouro')?.value.trim();
  const num = document.getElementById('reg-numero')?.value.trim();
  const bair = document.getElementById('reg-bairro')?.value.trim();
  const cid = document.getElementById('reg-cidade')?.value.trim();
  const comp = document.getElementById('reg-complemento')?.value.trim();
  const ref = document.getElementById('reg-referencia')?.value.trim();

  if (!nome || !phone || !email || !password || !logr || !num) {
    toast('Preencha todos os campos obrigatórios (*)', 'error');
    return;
  }

  showLoading(true, 'Criando sua conta...');
  try {
    const { data: authData, error: authError } = await sb.auth.signUp({
      email: email,
      password: password
    });

    if (authError) throw authError;

    const userId = authData.user?.id || crypto.randomUUID();
    const fullAddress = [
      `${logr}, ${num}`,
      comp ? `(${comp})` : '',
      bair,
      `${cid} - ${uf}`,
      cep ? `CEP: ${cep}` : ''
    ].filter(Boolean).join(' - ');

    // Inserir em cardapio_clientes
    const { data: profileData, error: profErr } = await sb
      .from('cardapio_clientes')
      .insert({
        user_id: userId,
        tenant_id: state.tenantId || DEFAULT_TENANT_ID,
        nome,
        whatsapp: phone,
        email,
        cep,
        uf,
        logradouro: logr,
        numero: num,
        bairro: bair,
        cidade: cid,
        complemento: comp || null,
        referencia: ref || null,
        endereco_padrao: fullAddress
      })
      .select()
      .single();

    if (profErr) throw profErr;

    state.session = authData.session;
    state.profile = profileData;

    // Sincronizar imediatamente com a tabela 'cliente' e 'local_entrega' do ERP
    try {
      const erpClient = await syncCustomerToErp({
        nome,
        telefone: phone,
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

    updateHeaderUI();
    const nextScreen = state.redirectAfterAuth || (state.cart.length > 0 ? 'screen-checkout' : 'screen-home');
    state.redirectAfterAuth = null;
    showScreen(nextScreen);
    toast('🎉 Conta criada com sucesso!', 'success');
  } catch (err) {
    toast('Erro ao criar conta: ' + err.message, 'error');
  } finally {
    showLoading(false);
  }
}

async function loadUserProfile() {
  if (!state.session?.user) return;
  try {
    const { data } = await sb
      .from('cardapio_clientes')
      .select('*')
      .eq('user_id', state.session.user.id)
      .maybeSingle();

    if (data) {
      state.profile = data;
      updateHeaderUI();
    }
  } catch (_) {}
}

async function handleLogout() {
  await sb.auth.signOut();
  state.session = null;
  state.profile = null;
  updateHeaderUI();
  showScreen('screen-home');
  toast('Você saiu da sua conta.', 'info');
}

function updateHeaderUI() {
  const avatarEl = document.getElementById('header-avatar');
  const drawerName = document.getElementById('drawer-user-name');
  const drawerPhone = document.getElementById('drawer-user-phone');

  if (state.profile?.nome) {
    const initials = state.profile.nome.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase();
    if (avatarEl) avatarEl.textContent = initials;
    if (drawerName) drawerName.textContent = state.profile.nome;
    if (drawerPhone) drawerPhone.textContent = formatPhone(state.profile.whatsapp || '');
  } else {
    if (avatarEl) avatarEl.textContent = '👤';
    if (drawerName) drawerName.textContent = 'Visitante';
    if (drawerPhone) drawerPhone.textContent = 'Toque para entrar';
  }
}

// ─── Busca de CEP (ViaCEP) ───────────────────────────────────────────
async function fetchViaCep(cep, prefix) {
  const clean = cep.replace(/\D/g, '');
  if (clean.length !== 8) {
    toast('CEP inválido (deve conter 8 dígitos)', 'error');
    return;
  }

  showLoading(true, 'Buscando endereço pelo CEP...');
  try {
    const res = await fetch(`https://viacep.com.br/ws/${clean}/json/`);
    const data = await res.json();

    if (data.erro) {
      toast('CEP não encontrado.', 'error');
      return;
    }

    const logr = document.getElementById(`${prefix}-logradouro`);
    const bair = document.getElementById(`${prefix}-bairro`);
    const cid  = document.getElementById(`${prefix}-cidade`);
    const uf   = document.getElementById(`${prefix}-uf`);
    const num  = document.getElementById(`${prefix}-numero`);

    if (logr) logr.value = data.logradouro || '';
    if (bair) bair.value = data.bairro || '';
    if (cid)  cid.value  = data.localidade || '';
    if (uf)   uf.value   = data.uf || 'SP';

    if (num) num.focus();
    toast('📍 Endereço preenchido automaticamente!', 'success');
  } catch (err) {
    toast('Erro ao buscar CEP: ' + err.message, 'error');
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

  // Carrinho Topbar & Floating Bar -> Checkout
  document.getElementById('header-cart-btn')?.addEventListener('click', () => showScreen('screen-checkout'));
  document.getElementById('bottom-cart-action')?.addEventListener('click', () => showScreen('screen-checkout'));

  // Avatar Header -> Drawer ou Perfil
  document.getElementById('header-avatar')?.addEventListener('click', () => {
    if (state.session) openDrawer();
    else showScreen('screen-auth');
  });

  // Botões e Atalhos da Central de Ações na Home
  const triggerHomeSearch = () => {
    const val = document.getElementById('home-search-input')?.value.trim();
    if (val) {
      state.searchTerm = val;
      const searchInput = document.getElementById('product-search-input');
      const searchClear = document.getElementById('product-search-clear');
      if (searchInput) searchInput.value = val;
      if (searchClear) searchClear.style.display = 'block';
      renderProductsGrid();
      showScreen('screen-cardapio');
    }
  };

  document.getElementById('home-search-btn')?.addEventListener('click', triggerHomeSearch);
  document.getElementById('home-search-input')?.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      triggerHomeSearch();
    }
  });

  document.getElementById('shortcut-cardapio')?.addEventListener('click', () => showScreen('screen-cardapio'));
  document.getElementById('shortcut-encomenda')?.addEventListener('click', () => showScreen('screen-cardapio'));
  document.getElementById('shortcut-pedidos')?.addEventListener('click', () => showScreen('screen-orders'));
  document.getElementById('shortcut-tabela')?.addEventListener('click', () => {
    const tiersSec = document.getElementById('home-pricing-tiers-section');
    if (tiersSec && tiersSec.style.display !== 'none') {
      tiersSec.scrollIntoView({ behavior: 'smooth' });
    } else {
      showScreen('screen-cardapio');
    }
  });

  document.getElementById('btn-party-order-cta')?.addEventListener('click', () => showScreen('screen-cardapio'));
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
    const min = getMinQtyForCategory(state.modalProduct?.categoria_id) || 1;
    if (state.modalQty > min) {
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
    if (!isNaN(val) && val >= 1) {
      state.modalQty = val;
      updateModalPrice();
    }
  });

  document.getElementById('modal-add-btn')?.addEventListener('click', () => {
    if (state.modalProduct) {
      addToCart(state.modalProduct, state.modalQty);
      closeProductModal();
    }
  });

  // Checkout Controles
  document.getElementById('checkout-back-btn')?.addEventListener('click', () => showScreen('screen-cardapio'));

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
    const phone = (state.empresa?.whatsapp || state.empresa?.telefone || '').replace(/\D/g, '');
    let url = `https://api.whatsapp.com/send?text=${encodeURIComponent(txt)}`;
    if (phone) {
      const fullPhone = phone.startsWith('55') ? phone : `55${phone}`;
      url = `https://api.whatsapp.com/send?phone=${fullPhone}&text=${encodeURIComponent(txt)}`;
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
      if (endSec) endSec.style.display = state.tipoLogistica === 'Entrega' ? 'block' : 'none';
      validateCheckoutForm();
    });
  });

  // Atalhos de Data no Checkout
  const dataInput = document.getElementById('checkout-data');
  const horaInput = document.getElementById('checkout-hora');

  // Inicializa data de hoje e hora + 45min
  const today = new Date();
  const yyyy = today.getFullYear();
  const mm = String(today.getMonth() + 1).padStart(2, '0');
  const dd = String(today.getDate()).padStart(2, '0');
  if (dataInput) {
    dataInput.value = `${yyyy}-${mm}-${dd}`;
    dataInput.min = `${yyyy}-${mm}-${dd}`;
  }

  today.setMinutes(today.getMinutes() + 45);
  const hh = String(today.getHours()).padStart(2, '0');
  const min = String(today.getMinutes()).padStart(2, '0');
  if (horaInput) horaInput.value = `${hh}:${min}`;

  document.getElementById('btn-date-hoje')?.addEventListener('click', () => {
    document.querySelectorAll('.date-chip').forEach(c => c.classList.remove('active'));
    document.getElementById('btn-date-hoje')?.classList.add('active');
    const d = new Date();
    dataInput.value = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    validateCheckoutForm();
  });

  document.getElementById('btn-date-amanha')?.addEventListener('click', () => {
    document.querySelectorAll('.date-chip').forEach(c => c.classList.remove('active'));
    document.getElementById('btn-date-amanha')?.classList.add('active');
    const d = new Date();
    d.setDate(d.getDate() + 1);
    dataInput.value = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    validateCheckoutForm();
  });

  document.getElementById('btn-date-custom')?.addEventListener('click', () => {
    document.querySelectorAll('.date-chip').forEach(c => c.classList.remove('active'));
    document.getElementById('btn-date-custom')?.classList.add('active');
    dataInput.focus();
  });

  // Formas de Pagamento
  document.querySelectorAll('.payment-card').forEach(card => {
    card.addEventListener('click', () => {
      document.querySelectorAll('.payment-card').forEach(c => c.classList.remove('active'));
      card.classList.add('active');
      state.formaPagamentoNome = card.dataset.payment;

      const trocoSec = document.getElementById('troco-section');
      if (trocoSec) trocoSec.style.display = state.formaPagamentoNome === 'Dinheiro' ? 'block' : 'none';
      validateCheckoutForm();
    });
  });

  // Validação em tempo real dos campos de contato e endereço
  ['checkout-nome-cliente', 'checkout-phone-cliente', 'checkout-cep', 'checkout-logradouro', 'checkout-numero', 'checkout-bairro', 'checkout-cidade', 'checkout-data', 'checkout-hora'].forEach(id => {
    document.getElementById(id)?.addEventListener('input', validateCheckoutForm);
  });

  // Máscaras automáticas para todos os campos de telefone / WhatsApp
  const applyMask = (e) => {
    e.target.value = formatPhone(e.target.value);
  };
  document.getElementById('checkout-phone-cliente')?.addEventListener('input', (e) => {
    applyMask(e);
    validateCheckoutForm();
  });
  document.getElementById('reg-whatsapp')?.addEventListener('input', applyMask);
  document.getElementById('account-phone')?.addEventListener('input', applyMask);

  // Botão de trocar de conta no checkout
  document.getElementById('btn-checkout-trocar-conta')?.addEventListener('click', () => {
    state.redirectAfterAuth = 'screen-checkout';
    showScreen('screen-auth');
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
  document.getElementById('btn-ver-horarios-checkout')?.addEventListener('click', openHorariosModal);
  document.getElementById('modal-horarios-close-btn')?.addEventListener('click', closeHorariosModal);
  document.getElementById('modal-horarios-ok-btn')?.addEventListener('click', closeHorariosModal);
  document.getElementById('modal-horarios')?.addEventListener('click', (e) => {
    if (e.target.id === 'modal-horarios') closeHorariosModal();
  });

  document.getElementById('form-login')?.addEventListener('submit', handleLogin);
  document.getElementById('form-register')?.addEventListener('submit', handleRegister);
  document.getElementById('back-to-landing-btn')?.addEventListener('click', () => showScreen('screen-home'));
}

// ─── Inicialização da Aplicação ───────────────────────────────────────
async function initApp() {
  showLoading(true, 'Iniciando portal de pedidos...');
  loadCart();
  initEventListeners();

  try {
    // 1. Carrega sessão do Supabase se existir
    const { data: { session } } = await sb.auth.getSession();
    state.session = session;

    // 2. Carrega perfil do usuário
    if (session) {
      await loadUserProfile();
    }

    // 3. Carrega dados do tenant e da empresa
    await loadEmpresa();

    // 4. Carrega catálogo de produtos e precificação em lote
    await loadCatalog();

    // 5. Carrega pedidos existentes do cliente
    if (state.session || state.profile) {
      await loadCustomerOrders();
    }

    // 6. Exibe a tela inicial (Home Dashboard)
    showScreen('screen-home');

    // 7. Sincronização em tempo real dos pedidos (Polling a cada 3s + Realtime)
    setInterval(() => {
      if (state.session || state.profile) {
        loadCustomerOrders(false);
      }
    }, 3000);

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
