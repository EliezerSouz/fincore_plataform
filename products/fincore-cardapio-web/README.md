# 🍽️ FinCore Cardápio Digital Web

Cardápio digital self-hosted para o **FinCore Food**.  
Permite que clientes acessem o cardápio online, façam login, montem o carrinho e **enviem pedidos direto ao sistema** — sem precisar copiar/colar para WhatsApp.

---

## 📁 Estrutura de Arquivos

```
fincore-cardapio-web/
├── index.html         # SPA principal (6 telas)
├── style.css          # Design premium mobile-first
├── app.js             # Toda a lógica (Supabase, carrinho, pedidos)
├── supabase/
│   ├── 001_cardapio_clientes.sql   # Tabela de clientes web + RLS
│   ├── 002_pedidos_web_rls.sql     # RLS de pedidos para clientes
│   └── 003_produtos_public_read.sql # Views e RLS públicos
└── README.md
```

---

## 🚀 Como Fazer o Deploy (Vercel — Grátis)

### Pré-requisitos
- Conta no [Vercel](https://vercel.com) (gratuita)
- Conta no [GitHub](https://github.com) (para subir o código)
- Git instalado na máquina

### Passo a Passo

**1. Criar repositório no GitHub**
```bash
# Dentro da pasta fincore-cardapio-web
git init
git add .
git commit -m "feat: cardápio digital fincore"
# Criar repo no GitHub e fazer push
git remote add origin https://github.com/SEU-USUARIO/fincore-cardapio.git
git push -u origin main
```

**2. Deploy no Vercel**
1. Acesse [vercel.com](https://vercel.com) e faça login
2. Clique em **"New Project"**
3. Importe o repositório criado
4. Clique em **"Deploy"** — pronto! ✅

Seu cardápio estará online em: `https://fincore-cardapio.vercel.app`

**3. Domínio personalizado (opcional)**
No painel do Vercel, vá em **Domains** e adicione seu domínio.

---

## 🗄️ Configurar o Supabase

Execute os scripts SQL na seguinte ordem no **Supabase SQL Editor**:

```
1. supabase/001_cardapio_clientes.sql
2. supabase/002_pedidos_web_rls.sql
3. supabase/003_produtos_public_read.sql
```

**Acesso ao SQL Editor:**
1. Acesse [supabase.com](https://supabase.com) → seu projeto
2. Menu lateral → **SQL Editor**
3. Cole cada arquivo e execute (Run)

---

## ⚙️ Configurações Importantes

### WhatsApp da Loja
No arquivo `app.js`, linha 9:
```js
const WHATSAPP_LOJA = '5511999999999'; // ← Substitua pelo número real
```
Formato: `55` + DDD + número (sem espaços ou traços).

Ou configure o WhatsApp no `metadata_payload` da empresa no banco de dados — o app carrega automaticamente.

### URL e Chave do Supabase
As credenciais já estão configuradas automaticamente usando as mesmas do `.env` do FinCore Food.

---

## 📱 Compartilhar com Clientes

Envie o link do seu cardápio via WhatsApp:

```
🍽️ Olá! Já pode fazer seu pedido direto pelo nosso cardápio digital:

👉 https://fincore-cardapio.vercel.app

Crie sua conta, monte o carrinho e o pedido já chega pra gente aqui! 🚀
```

---

## 🔒 Segurança

| Camada | Proteção |
|---|---|
| Senhas | bcrypt no servidor (Supabase Auth) |
| Transporte | HTTPS obrigatório |
| Sessão | JWT com expiração |
| Dados | Row Level Security — cliente A nunca vê dados do cliente B |
| Cardápio | Apenas campos necessários expostos (sem dados fiscais) |

---

## 🔄 Fluxo Completo

```
Cliente abre o link
    ↓
Cadastro / Login (Supabase Auth)
    ↓
Navega pelo cardápio (produtos do Supabase — sincronizados do FinCore Food)
    ↓
Monta carrinho → Finaliza pedido
    ↓
Pedido salvo no Supabase → Sync automático → FinCore Food recebe
    ↓
🔔 Alerta sonoro na cozinha!
    ↓
Status atualiza em tempo real na tela do cliente
```

---

## 📊 Funcionalidades

- ✅ Login e cadastro seguro (Supabase Auth)
- ✅ Cardápio por categorias com busca
- ✅ Carrinho persistente (localStorage)
- ✅ Envio direto ao FinCore Food
- ✅ Status em tempo real via WebSocket
- ✅ Histórico de pedidos
- ✅ Botão "Pedir Orçamento" (WhatsApp)
- ✅ Botão "Copiar Texto" do pedido
- ✅ Design mobile-first premium
- ✅ 100% responsivo (celular, tablet, desktop)
