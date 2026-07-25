# Tools & Automation — FINCORE

> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este diretório centraliza todos os scripts utilitários, automações, ferramentas de linha de comando (CLI) e templates de geração de código usados pela equipe de engenharia e pipelines de CI/CD.

---

## 🛠️ Conteúdo do Diretório

1. **Scripts de Build**: Automações em shell/powershell para compilação multiplataforma e disparos do build_runner.
2. **Pipelines Locais**: Scripts para validação automática de PRs antes do push remoto.
3. **Templates**: Modelos de geração automática de arquivos (ex: gerador de Use Case do Flutter, gerador de endpoints do Serverpod).
4. **Banco de Dados**: Scripts de backup, limpeza e migração do SQLite em ambiente de teste local.

---

## ⚠️ Regras de Contribuição de Ferramentas

* **Multiplataforma**: Scripts devem ser escritos em linguagens portáveis (Dart, Python ou Shell/Bash) para garantir execução em ambientes Windows, Linux e macOS sem atrito.
* **Documentação Inline**: Todo script deve conter cabeçalho descritivo com instruções de parâmetros e mensagens de log de erro amigáveis.
* **Sem Código de Produção**: Nenhuma ferramenta ou script deste diretório pode ser compilado no pacote de distribuição final enviado ao cliente.

---

*Tools & Automation — FINCORE Platform*
