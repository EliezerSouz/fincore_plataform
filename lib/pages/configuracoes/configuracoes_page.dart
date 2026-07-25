import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../providers/app_view_model.dart';
import '../../services/settings_service.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<ConfiguracoesPage> {
  late final TextEditingController _empresa;
  late final TextEditingController _telefone;
  late final TextEditingController _endereco;
  late final TextEditingController _rodape;
  late final TextEditingController _impressora;
  late final TextEditingController _taxa;
  int _largura = 80;
  String _horizonteOperacional = 'Hoje + Amanhã';
  bool _testandoConexao = false;

  // Novos controllers da Empresa e PIX
  late final TextEditingController _razaoSocial;
  late final TextEditingController _whatsapp;
  late final TextEditingController _instagram;
  late final TextEditingController _logoPath;
  bool _habilitarPix = false;
  String _pixTipoChave = 'CPF';
  late final TextEditingController _pixChave;
  late final TextEditingController _pixFavorecido;
  late final TextEditingController _pixBanco;
  late final TextEditingController _pixCidade;
  late final TextEditingController _pixMensagem;
  bool _pixGerarQrCodeAuto = true;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppViewModel>().settings;
    _empresa = TextEditingController(text: s.empresa);
    _telefone = TextEditingController(text: s.telefone);
    _endereco = TextEditingController(text: s.endereco);
    _rodape = TextEditingController(text: s.rodape);
    _impressora = TextEditingController(text: s.impressora);
    _taxa = TextEditingController(
        text: (s.taxaPadrao / 100).toStringAsFixed(2));
    _largura = s.largura;
    _horizonteOperacional = s.horizonteOperacional;

    _razaoSocial = TextEditingController(text: s.razaoSocial);
    _whatsapp = TextEditingController(text: s.whatsapp);
    _instagram = TextEditingController(text: s.instagram);
    _logoPath = TextEditingController(text: s.logoPath);
    _habilitarPix = s.habilitarPix;
    _pixTipoChave = s.pixTipoChave;
    _pixChave = TextEditingController(text: s.pixChave);
    _pixFavorecido = TextEditingController(text: s.pixFavorecido);
    _pixBanco = TextEditingController(text: s.pixBanco);
    _pixCidade = TextEditingController(text: s.pixCidade);
    _pixMensagem = TextEditingController(text: s.pixMensagem);
    _pixGerarQrCodeAuto = s.pixGerarQrCodeAuto;
  }

  @override
  void dispose() {
    _empresa.dispose();
    _telefone.dispose();
    _endereco.dispose();
    _rodape.dispose();
    _impressora.dispose();
    _taxa.dispose();
    _razaoSocial.dispose();
    _whatsapp.dispose();
    _instagram.dispose();
    _logoPath.dispose();
    _pixChave.dispose();
    _pixFavorecido.dispose();
    _pixBanco.dispose();
    _pixCidade.dispose();
    _pixMensagem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações do Sistema',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Defina as informações do estabelecimento e parâmetros de impressão.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: SizedBox(
                  width: 680,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DADOS DO ESTABELECIMENTO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _campo('Nome Fantasia', _empresa),
                      _campo('Razão Social', _razaoSocial),
                      Row(
                        children: [
                          Expanded(child: _campo('Telefone Comercial', _telefone)),
                          const SizedBox(width: 12),
                          Expanded(child: _campo('WhatsApp Comercial', _whatsapp)),
                        ],
                      ),
                      _campo('Instagram da Empresa', _instagram),
                      _campo('Endereço Completo', _endereco),
                      _campo('Caminho da Imagem do Logo', _logoPath, helper: 'Caminho local ou URL do logotipo'),
                      _campo('Mensagem do Rodapé da Comanda', _rodape),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      
                      const Text(
                        'RECEBIMENTOS PIX',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        title: const Text('Habilitar Recebimentos PIX'),
                        subtitle: const Text('Imprime dados e chave PIX para pagamentos automáticos'),
                        value: _habilitarPix,
                        onChanged: (v) => setState(() => _habilitarPix = v),
                      ),
                      if (_habilitarPix) ...[
                        SwitchListTile(
                          title: const Text('Gerar QR Code Automaticamente'),
                          subtitle: const Text('Gera e imprime o QR Code EMV dinâmico automaticamente nas comandas PIX'),
                          value: _pixGerarQrCodeAuto,
                          onChanged: (v) => setState(() => _pixGerarQrCodeAuto = v),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _pixTipoChave,
                          decoration: const InputDecoration(labelText: 'Tipo da Chave Pix'),
                          items: const [
                            DropdownMenuItem(value: 'CPF', child: Text('CPF')),
                            DropdownMenuItem(value: 'CNPJ', child: Text('CNPJ')),
                            DropdownMenuItem(value: 'Telefone', child: Text('Telefone')),
                            DropdownMenuItem(value: 'Email', child: Text('E-mail')),
                            DropdownMenuItem(value: 'Aleatória', child: Text('Chave Aleatória')),
                          ],
                          onChanged: (v) => setState(() => _pixTipoChave = v!),
                        ),
                        const SizedBox(height: 12),
                        _campo('Chave PIX', _pixChave),
                        _campo('Nome do Favorecido', _pixFavorecido),
                        _campo('Cidade do Beneficiário (PIX)', _pixCidade, helper: 'Ex.: Sorocaba (sem acentos)'),
                        _campo('Nome do Banco (Opcional)', _pixBanco),
                        _campo('Mensagem do PIX', _pixMensagem, helper: 'Instruções para o cliente'),
                      ],
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),

                      const Text(
                        'IMPRESSÃO E IMPRESSORA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Nota: O navegador executa a aplicação em um ambiente isolado (sandbox). Por questões de segurança, a impressão térmica direta via rede local (spooler) ou cabo USB não funciona de forma transparente na Web. O sistema abrirá a pré-visualização nativa do navegador para salvar/imprimir.',
                                style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _campo(
                              'Nome do Compartilhamento ou IP da Impressora',
                              _impressora,
                              helper:
                                  'Ex.: \\\\SERVIDOR\\EPSON  ou  192.168.1.100',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: OutlinedButton.icon(
                              onPressed: _testandoConexao
                                  ? null
                                  : () async {
                                      setState(() => _testandoConexao = true);
                                      final ok = await vm.impressoraPort
                                          .testarConexao(_impressora.text);
                                      if (!mounted) return;
                                      setState(() => _testandoConexao = false);
                                      if (ok) {
                                        AppSnackbar.sucesso(context,
                                            'Impressora conectada e acessível!');
                                      } else {
                                        AppSnackbar.erro(context,
                                            'Não foi possível conectar com a impressora.');
                                      }
                                    },
                              icon: _testandoConexao
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.print_outlined),
                              label: const Text('Testar'),
                            ),
                          ),
                        ],
                      ),
                      _campo('Taxa Padrão de Entrega (R\$)', _taxa),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _largura,
                        decoration: const InputDecoration(
                            labelText: 'Largura da Bobina de Papel'),
                        items: const [
                          DropdownMenuItem(
                              value: 58, child: Text('58 mm (Bobina Fina)')),
                          DropdownMenuItem(
                              value: 80, child: Text('80 mm (Bobina Larga)')),
                        ],
                        onChanged: (v) => setState(() => _largura = v!),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      const Text(
                        'PARÂMETROS OPERACIONAIS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _horizonteOperacional,
                        decoration: const InputDecoration(
                            labelText: 'Horizonte Operacional para Reservas e Produção'),
                        items: const [
                          DropdownMenuItem(value: 'Hoje', child: Text('Hoje')),
                          DropdownMenuItem(value: 'Hoje + Amanhã', child: Text('Hoje + Amanhã')),
                          DropdownMenuItem(value: 'Próximos 3 dias', child: Text('Próximos 3 dias')),
                          DropdownMenuItem(value: 'Próximos 7 dias', child: Text('Próximos 7 dias')),
                          DropdownMenuItem(value: 'Todos', child: Text('Todos os agendados')),
                        ],
                        onChanged: (v) => setState(() => _horizonteOperacional = v!),
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Salvar Configurações'),
                          onPressed: () async {
                            final taxaValor = double.tryParse(
                                _taxa.text.replaceAll(',', '.'));
                            await vm.salvarSettings(AppSettings(
                              empresa: _empresa.text,
                              telefone: _telefone.text,
                              endereco: _endereco.text,
                              rodape: _rodape.text,
                              impressora: _impressora.text,
                              taxaPadrao: taxaValor != null
                                  ? (taxaValor * 100).round()
                                  : vm.settings.taxaPadrao,
                              largura: _largura,
                              horizonteOperacional: _horizonteOperacional,
                              razaoSocial: _razaoSocial.text,
                              whatsapp: _whatsapp.text,
                              instagram: _instagram.text,
                              logoPath: _logoPath.text,
                              habilitarPix: _habilitarPix,
                              pixTipoChave: _pixTipoChave,
                              pixChave: _pixChave.text,
                              pixFavorecido: _pixFavorecido.text,
                              pixBanco: _pixBanco.text,
                              pixCidade: _pixCidade.text,
                              pixMensagem: _pixMensagem.text,
                              pixGerarQrCodeAuto: _pixGerarQrCodeAuto,
                            ));
                            if (!mounted) return;
                            AppSnackbar.sucesso(
                                context, 'Configurações salvas com sucesso.');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, {String? helper}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label, helperText: helper),
        ),
      );
}
