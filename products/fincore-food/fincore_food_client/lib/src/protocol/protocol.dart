/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'greeting.dart' as _i2;
import 'audit_log.dart' as _i3;
import 'auth_user_info.dart' as _i4;
import 'bootstrap_payload.dart' as _i5;
import 'categoria.dart' as _i6;
import 'cliente.dart' as _i7;
import 'empresa.dart' as _i8;
import 'empresa_configuracao.dart' as _i9;
import 'evento_empresa.dart' as _i10;
import 'forma_pagamento.dart' as _i11;
import 'item_tabela_precificacao.dart' as _i12;
import 'local_entrega.dart' as _i13;
import 'membro_empresa.dart' as _i14;
import 'onboarding_exception.dart' as _i15;
import 'produto.dart' as _i16;
import 'produto_tabela_precificacao.dart' as _i17;
import 'sync_pull_payload.dart' as _i18;
import 'sync_push_entry.dart' as _i19;
import 'tabela_precificacao.dart' as _i20;
import 'taxa_entrega.dart' as _i21;
import 'usuario.dart' as _i22;
import 'workspace_setup_progress_info.dart' as _i23;
import 'package:fincore_food_client/src/protocol/sync_push_entry.dart' as _i24;
export 'greeting.dart';
export 'audit_log.dart';
export 'auth_user_info.dart';
export 'bootstrap_payload.dart';
export 'categoria.dart';
export 'cliente.dart';
export 'empresa.dart';
export 'empresa_configuracao.dart';
export 'evento_empresa.dart';
export 'forma_pagamento.dart';
export 'item_tabela_precificacao.dart';
export 'local_entrega.dart';
export 'membro_empresa.dart';
export 'onboarding_exception.dart';
export 'produto.dart';
export 'produto_tabela_precificacao.dart';
export 'sync_pull_payload.dart';
export 'sync_push_entry.dart';
export 'tabela_precificacao.dart';
export 'taxa_entrega.dart';
export 'usuario.dart';
export 'workspace_setup_progress_info.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    if (t == _i2.Greeting) {
      return _i2.Greeting.fromJson(data) as T;
    }
    if (t == _i3.AuditLog) {
      return _i3.AuditLog.fromJson(data) as T;
    }
    if (t == _i4.AuthUserInfo) {
      return _i4.AuthUserInfo.fromJson(data) as T;
    }
    if (t == _i5.BootstrapPayload) {
      return _i5.BootstrapPayload.fromJson(data) as T;
    }
    if (t == _i6.Categoria) {
      return _i6.Categoria.fromJson(data) as T;
    }
    if (t == _i7.Cliente) {
      return _i7.Cliente.fromJson(data) as T;
    }
    if (t == _i8.Empresa) {
      return _i8.Empresa.fromJson(data) as T;
    }
    if (t == _i9.EmpresaConfiguracao) {
      return _i9.EmpresaConfiguracao.fromJson(data) as T;
    }
    if (t == _i10.EventoEmpresa) {
      return _i10.EventoEmpresa.fromJson(data) as T;
    }
    if (t == _i11.FormaPagamento) {
      return _i11.FormaPagamento.fromJson(data) as T;
    }
    if (t == _i12.ItemTabelaPrecificacao) {
      return _i12.ItemTabelaPrecificacao.fromJson(data) as T;
    }
    if (t == _i13.LocalEntrega) {
      return _i13.LocalEntrega.fromJson(data) as T;
    }
    if (t == _i14.MembroEmpresa) {
      return _i14.MembroEmpresa.fromJson(data) as T;
    }
    if (t == _i15.OnboardingException) {
      return _i15.OnboardingException.fromJson(data) as T;
    }
    if (t == _i16.Produto) {
      return _i16.Produto.fromJson(data) as T;
    }
    if (t == _i17.ProdutoTabelaPrecificacao) {
      return _i17.ProdutoTabelaPrecificacao.fromJson(data) as T;
    }
    if (t == _i18.SyncPullPayload) {
      return _i18.SyncPullPayload.fromJson(data) as T;
    }
    if (t == _i19.SyncPushEntry) {
      return _i19.SyncPushEntry.fromJson(data) as T;
    }
    if (t == _i20.TabelaPrecificacao) {
      return _i20.TabelaPrecificacao.fromJson(data) as T;
    }
    if (t == _i21.TaxaEntrega) {
      return _i21.TaxaEntrega.fromJson(data) as T;
    }
    if (t == _i22.Usuario) {
      return _i22.Usuario.fromJson(data) as T;
    }
    if (t == _i23.WorkspaceSetupProgressInfo) {
      return _i23.WorkspaceSetupProgressInfo.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Greeting?>()) {
      return (data != null ? _i2.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AuditLog?>()) {
      return (data != null ? _i3.AuditLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AuthUserInfo?>()) {
      return (data != null ? _i4.AuthUserInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.BootstrapPayload?>()) {
      return (data != null ? _i5.BootstrapPayload.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Categoria?>()) {
      return (data != null ? _i6.Categoria.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Cliente?>()) {
      return (data != null ? _i7.Cliente.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Empresa?>()) {
      return (data != null ? _i8.Empresa.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.EmpresaConfiguracao?>()) {
      return (data != null ? _i9.EmpresaConfiguracao.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.EventoEmpresa?>()) {
      return (data != null ? _i10.EventoEmpresa.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.FormaPagamento?>()) {
      return (data != null ? _i11.FormaPagamento.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ItemTabelaPrecificacao?>()) {
      return (data != null ? _i12.ItemTabelaPrecificacao.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.LocalEntrega?>()) {
      return (data != null ? _i13.LocalEntrega.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.MembroEmpresa?>()) {
      return (data != null ? _i14.MembroEmpresa.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.OnboardingException?>()) {
      return (data != null ? _i15.OnboardingException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.Produto?>()) {
      return (data != null ? _i16.Produto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.ProdutoTabelaPrecificacao?>()) {
      return (data != null
          ? _i17.ProdutoTabelaPrecificacao.fromJson(data)
          : null) as T;
    }
    if (t == _i1.getType<_i18.SyncPullPayload?>()) {
      return (data != null ? _i18.SyncPullPayload.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.SyncPushEntry?>()) {
      return (data != null ? _i19.SyncPushEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.TabelaPrecificacao?>()) {
      return (data != null ? _i20.TabelaPrecificacao.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i21.TaxaEntrega?>()) {
      return (data != null ? _i21.TaxaEntrega.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.Usuario?>()) {
      return (data != null ? _i22.Usuario.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.WorkspaceSetupProgressInfo?>()) {
      return (data != null
          ? _i23.WorkspaceSetupProgressInfo.fromJson(data)
          : null) as T;
    }
    if (t == List<_i14.MembroEmpresa>) {
      return (data as List)
          .map((e) => deserialize<_i14.MembroEmpresa>(e))
          .toList() as T;
    }
    if (t == List<_i16.Produto>) {
      return (data as List).map((e) => deserialize<_i16.Produto>(e)).toList()
          as T;
    }
    if (t == List<_i7.Cliente>) {
      return (data as List).map((e) => deserialize<_i7.Cliente>(e)).toList()
          as T;
    }
    if (t == List<_i9.EmpresaConfiguracao>) {
      return (data as List)
          .map((e) => deserialize<_i9.EmpresaConfiguracao>(e))
          .toList() as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i24.SyncPushEntry>) {
      return (data as List)
          .map((e) => deserialize<_i24.SyncPushEntry>(e))
          .toList() as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i2.Greeting) {
      return 'Greeting';
    }
    if (data is _i3.AuditLog) {
      return 'AuditLog';
    }
    if (data is _i4.AuthUserInfo) {
      return 'AuthUserInfo';
    }
    if (data is _i5.BootstrapPayload) {
      return 'BootstrapPayload';
    }
    if (data is _i6.Categoria) {
      return 'Categoria';
    }
    if (data is _i7.Cliente) {
      return 'Cliente';
    }
    if (data is _i8.Empresa) {
      return 'Empresa';
    }
    if (data is _i9.EmpresaConfiguracao) {
      return 'EmpresaConfiguracao';
    }
    if (data is _i10.EventoEmpresa) {
      return 'EventoEmpresa';
    }
    if (data is _i11.FormaPagamento) {
      return 'FormaPagamento';
    }
    if (data is _i12.ItemTabelaPrecificacao) {
      return 'ItemTabelaPrecificacao';
    }
    if (data is _i13.LocalEntrega) {
      return 'LocalEntrega';
    }
    if (data is _i14.MembroEmpresa) {
      return 'MembroEmpresa';
    }
    if (data is _i15.OnboardingException) {
      return 'OnboardingException';
    }
    if (data is _i16.Produto) {
      return 'Produto';
    }
    if (data is _i17.ProdutoTabelaPrecificacao) {
      return 'ProdutoTabelaPrecificacao';
    }
    if (data is _i18.SyncPullPayload) {
      return 'SyncPullPayload';
    }
    if (data is _i19.SyncPushEntry) {
      return 'SyncPushEntry';
    }
    if (data is _i20.TabelaPrecificacao) {
      return 'TabelaPrecificacao';
    }
    if (data is _i21.TaxaEntrega) {
      return 'TaxaEntrega';
    }
    if (data is _i22.Usuario) {
      return 'Usuario';
    }
    if (data is _i23.WorkspaceSetupProgressInfo) {
      return 'WorkspaceSetupProgressInfo';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i2.Greeting>(data['data']);
    }
    if (dataClassName == 'AuditLog') {
      return deserialize<_i3.AuditLog>(data['data']);
    }
    if (dataClassName == 'AuthUserInfo') {
      return deserialize<_i4.AuthUserInfo>(data['data']);
    }
    if (dataClassName == 'BootstrapPayload') {
      return deserialize<_i5.BootstrapPayload>(data['data']);
    }
    if (dataClassName == 'Categoria') {
      return deserialize<_i6.Categoria>(data['data']);
    }
    if (dataClassName == 'Cliente') {
      return deserialize<_i7.Cliente>(data['data']);
    }
    if (dataClassName == 'Empresa') {
      return deserialize<_i8.Empresa>(data['data']);
    }
    if (dataClassName == 'EmpresaConfiguracao') {
      return deserialize<_i9.EmpresaConfiguracao>(data['data']);
    }
    if (dataClassName == 'EventoEmpresa') {
      return deserialize<_i10.EventoEmpresa>(data['data']);
    }
    if (dataClassName == 'FormaPagamento') {
      return deserialize<_i11.FormaPagamento>(data['data']);
    }
    if (dataClassName == 'ItemTabelaPrecificacao') {
      return deserialize<_i12.ItemTabelaPrecificacao>(data['data']);
    }
    if (dataClassName == 'LocalEntrega') {
      return deserialize<_i13.LocalEntrega>(data['data']);
    }
    if (dataClassName == 'MembroEmpresa') {
      return deserialize<_i14.MembroEmpresa>(data['data']);
    }
    if (dataClassName == 'OnboardingException') {
      return deserialize<_i15.OnboardingException>(data['data']);
    }
    if (dataClassName == 'Produto') {
      return deserialize<_i16.Produto>(data['data']);
    }
    if (dataClassName == 'ProdutoTabelaPrecificacao') {
      return deserialize<_i17.ProdutoTabelaPrecificacao>(data['data']);
    }
    if (dataClassName == 'SyncPullPayload') {
      return deserialize<_i18.SyncPullPayload>(data['data']);
    }
    if (dataClassName == 'SyncPushEntry') {
      return deserialize<_i19.SyncPushEntry>(data['data']);
    }
    if (dataClassName == 'TabelaPrecificacao') {
      return deserialize<_i20.TabelaPrecificacao>(data['data']);
    }
    if (dataClassName == 'TaxaEntrega') {
      return deserialize<_i21.TaxaEntrega>(data['data']);
    }
    if (dataClassName == 'Usuario') {
      return deserialize<_i22.Usuario>(data['data']);
    }
    if (dataClassName == 'WorkspaceSetupProgressInfo') {
      return deserialize<_i23.WorkspaceSetupProgressInfo>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
