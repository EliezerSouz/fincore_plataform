// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GruposPrecoTable extends GruposPreco
    with TableInfo<$GruposPrecoTable, GruposPrecoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GruposPrecoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _descricaoMeta =
      const VerificationMeta('descricao');
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
      'descricao', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
      'ativo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ativo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [id, nome, descricao, ativo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grupos_preco';
  @override
  VerificationContext validateIntegrity(Insertable<GruposPrecoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(_descricaoMeta,
          descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta));
    }
    if (data.containsKey('ativo')) {
      context.handle(
          _ativoMeta, ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GruposPrecoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GruposPrecoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      descricao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descricao'])!,
      ativo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ativo'])!,
    );
  }

  @override
  $GruposPrecoTable createAlias(String alias) {
    return $GruposPrecoTable(attachedDatabase, alias);
  }
}

class GruposPrecoData extends DataClass implements Insertable<GruposPrecoData> {
  final int id;
  final String nome;
  final String descricao;
  final bool ativo;
  const GruposPrecoData(
      {required this.id,
      required this.nome,
      required this.descricao,
      required this.ativo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['descricao'] = Variable<String>(descricao);
    map['ativo'] = Variable<bool>(ativo);
    return map;
  }

  GruposPrecoCompanion toCompanion(bool nullToAbsent) {
    return GruposPrecoCompanion(
      id: Value(id),
      nome: Value(nome),
      descricao: Value(descricao),
      ativo: Value(ativo),
    );
  }

  factory GruposPrecoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GruposPrecoData(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      descricao: serializer.fromJson<String>(json['descricao']),
      ativo: serializer.fromJson<bool>(json['ativo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'descricao': serializer.toJson<String>(descricao),
      'ativo': serializer.toJson<bool>(ativo),
    };
  }

  GruposPrecoData copyWith(
          {int? id, String? nome, String? descricao, bool? ativo}) =>
      GruposPrecoData(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        descricao: descricao ?? this.descricao,
        ativo: ativo ?? this.ativo,
      );
  GruposPrecoData copyWithCompanion(GruposPrecoCompanion data) {
    return GruposPrecoData(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GruposPrecoData(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('descricao: $descricao, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, descricao, ativo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GruposPrecoData &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.descricao == this.descricao &&
          other.ativo == this.ativo);
}

class GruposPrecoCompanion extends UpdateCompanion<GruposPrecoData> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String> descricao;
  final Value<bool> ativo;
  const GruposPrecoCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.descricao = const Value.absent(),
    this.ativo = const Value.absent(),
  });
  GruposPrecoCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    this.descricao = const Value.absent(),
    this.ativo = const Value.absent(),
  }) : nome = Value(nome);
  static Insertable<GruposPrecoData> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? descricao,
    Expression<bool>? ativo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (descricao != null) 'descricao': descricao,
      if (ativo != null) 'ativo': ativo,
    });
  }

  GruposPrecoCompanion copyWith(
      {Value<int>? id,
      Value<String>? nome,
      Value<String>? descricao,
      Value<bool>? ativo}) {
    return GruposPrecoCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GruposPrecoCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('descricao: $descricao, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }
}

class $ProdutosTable extends Produtos with TableInfo<$ProdutosTable, Produto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProdutosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoriaMeta =
      const VerificationMeta('categoria');
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
      'categoria', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Salgados'));
  static const VerificationMeta _grupoPrecoIdMeta =
      const VerificationMeta('grupoPrecoId');
  @override
  late final GeneratedColumn<int> grupoPrecoId = GeneratedColumn<int>(
      'grupo_preco_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES grupos_preco (id)'));
  static const VerificationMeta _tempoMedioMinutosMeta =
      const VerificationMeta('tempoMedioMinutos');
  @override
  late final GeneratedColumn<int> tempoMedioMinutos = GeneratedColumn<int>(
      'tempo_medio_minutos', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _controlaEstoqueMeta =
      const VerificationMeta('controlaEstoque');
  @override
  late final GeneratedColumn<bool> controlaEstoque = GeneratedColumn<bool>(
      'controla_estoque', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("controla_estoque" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _ordemProducaoMeta =
      const VerificationMeta('ordemProducao');
  @override
  late final GeneratedColumn<int> ordemProducao = GeneratedColumn<int>(
      'ordem_producao', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
      'ativo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ativo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nome,
        categoria,
        grupoPrecoId,
        tempoMedioMinutos,
        controlaEstoque,
        ordemProducao,
        ativo
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'produtos';
  @override
  VerificationContext validateIntegrity(Insertable<Produto> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(_categoriaMeta,
          categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta));
    }
    if (data.containsKey('grupo_preco_id')) {
      context.handle(
          _grupoPrecoIdMeta,
          grupoPrecoId.isAcceptableOrUnknown(
              data['grupo_preco_id']!, _grupoPrecoIdMeta));
    }
    if (data.containsKey('tempo_medio_minutos')) {
      context.handle(
          _tempoMedioMinutosMeta,
          tempoMedioMinutos.isAcceptableOrUnknown(
              data['tempo_medio_minutos']!, _tempoMedioMinutosMeta));
    }
    if (data.containsKey('controla_estoque')) {
      context.handle(
          _controlaEstoqueMeta,
          controlaEstoque.isAcceptableOrUnknown(
              data['controla_estoque']!, _controlaEstoqueMeta));
    }
    if (data.containsKey('ordem_producao')) {
      context.handle(
          _ordemProducaoMeta,
          ordemProducao.isAcceptableOrUnknown(
              data['ordem_producao']!, _ordemProducaoMeta));
    }
    if (data.containsKey('ativo')) {
      context.handle(
          _ativoMeta, ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Produto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Produto(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      categoria: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categoria'])!,
      grupoPrecoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grupo_preco_id']),
      tempoMedioMinutos: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}tempo_medio_minutos'])!,
      controlaEstoque: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}controla_estoque'])!,
      ordemProducao: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordem_producao'])!,
      ativo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ativo'])!,
    );
  }

  @override
  $ProdutosTable createAlias(String alias) {
    return $ProdutosTable(attachedDatabase, alias);
  }
}

class Produto extends DataClass implements Insertable<Produto> {
  final int id;
  final String nome;
  final String categoria;
  final int? grupoPrecoId;
  final int tempoMedioMinutos;
  final bool controlaEstoque;
  final int ordemProducao;
  final bool ativo;
  const Produto(
      {required this.id,
      required this.nome,
      required this.categoria,
      this.grupoPrecoId,
      required this.tempoMedioMinutos,
      required this.controlaEstoque,
      required this.ordemProducao,
      required this.ativo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['categoria'] = Variable<String>(categoria);
    if (!nullToAbsent || grupoPrecoId != null) {
      map['grupo_preco_id'] = Variable<int>(grupoPrecoId);
    }
    map['tempo_medio_minutos'] = Variable<int>(tempoMedioMinutos);
    map['controla_estoque'] = Variable<bool>(controlaEstoque);
    map['ordem_producao'] = Variable<int>(ordemProducao);
    map['ativo'] = Variable<bool>(ativo);
    return map;
  }

  ProdutosCompanion toCompanion(bool nullToAbsent) {
    return ProdutosCompanion(
      id: Value(id),
      nome: Value(nome),
      categoria: Value(categoria),
      grupoPrecoId: grupoPrecoId == null && nullToAbsent
          ? const Value.absent()
          : Value(grupoPrecoId),
      tempoMedioMinutos: Value(tempoMedioMinutos),
      controlaEstoque: Value(controlaEstoque),
      ordemProducao: Value(ordemProducao),
      ativo: Value(ativo),
    );
  }

  factory Produto.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Produto(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      categoria: serializer.fromJson<String>(json['categoria']),
      grupoPrecoId: serializer.fromJson<int?>(json['grupoPrecoId']),
      tempoMedioMinutos: serializer.fromJson<int>(json['tempoMedioMinutos']),
      controlaEstoque: serializer.fromJson<bool>(json['controlaEstoque']),
      ordemProducao: serializer.fromJson<int>(json['ordemProducao']),
      ativo: serializer.fromJson<bool>(json['ativo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'categoria': serializer.toJson<String>(categoria),
      'grupoPrecoId': serializer.toJson<int?>(grupoPrecoId),
      'tempoMedioMinutos': serializer.toJson<int>(tempoMedioMinutos),
      'controlaEstoque': serializer.toJson<bool>(controlaEstoque),
      'ordemProducao': serializer.toJson<int>(ordemProducao),
      'ativo': serializer.toJson<bool>(ativo),
    };
  }

  Produto copyWith(
          {int? id,
          String? nome,
          String? categoria,
          Value<int?> grupoPrecoId = const Value.absent(),
          int? tempoMedioMinutos,
          bool? controlaEstoque,
          int? ordemProducao,
          bool? ativo}) =>
      Produto(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        categoria: categoria ?? this.categoria,
        grupoPrecoId:
            grupoPrecoId.present ? grupoPrecoId.value : this.grupoPrecoId,
        tempoMedioMinutos: tempoMedioMinutos ?? this.tempoMedioMinutos,
        controlaEstoque: controlaEstoque ?? this.controlaEstoque,
        ordemProducao: ordemProducao ?? this.ordemProducao,
        ativo: ativo ?? this.ativo,
      );
  Produto copyWithCompanion(ProdutosCompanion data) {
    return Produto(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      grupoPrecoId: data.grupoPrecoId.present
          ? data.grupoPrecoId.value
          : this.grupoPrecoId,
      tempoMedioMinutos: data.tempoMedioMinutos.present
          ? data.tempoMedioMinutos.value
          : this.tempoMedioMinutos,
      controlaEstoque: data.controlaEstoque.present
          ? data.controlaEstoque.value
          : this.controlaEstoque,
      ordemProducao: data.ordemProducao.present
          ? data.ordemProducao.value
          : this.ordemProducao,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Produto(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('categoria: $categoria, ')
          ..write('grupoPrecoId: $grupoPrecoId, ')
          ..write('tempoMedioMinutos: $tempoMedioMinutos, ')
          ..write('controlaEstoque: $controlaEstoque, ')
          ..write('ordemProducao: $ordemProducao, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, categoria, grupoPrecoId,
      tempoMedioMinutos, controlaEstoque, ordemProducao, ativo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Produto &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.categoria == this.categoria &&
          other.grupoPrecoId == this.grupoPrecoId &&
          other.tempoMedioMinutos == this.tempoMedioMinutos &&
          other.controlaEstoque == this.controlaEstoque &&
          other.ordemProducao == this.ordemProducao &&
          other.ativo == this.ativo);
}

class ProdutosCompanion extends UpdateCompanion<Produto> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String> categoria;
  final Value<int?> grupoPrecoId;
  final Value<int> tempoMedioMinutos;
  final Value<bool> controlaEstoque;
  final Value<int> ordemProducao;
  final Value<bool> ativo;
  const ProdutosCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.categoria = const Value.absent(),
    this.grupoPrecoId = const Value.absent(),
    this.tempoMedioMinutos = const Value.absent(),
    this.controlaEstoque = const Value.absent(),
    this.ordemProducao = const Value.absent(),
    this.ativo = const Value.absent(),
  });
  ProdutosCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    this.categoria = const Value.absent(),
    this.grupoPrecoId = const Value.absent(),
    this.tempoMedioMinutos = const Value.absent(),
    this.controlaEstoque = const Value.absent(),
    this.ordemProducao = const Value.absent(),
    this.ativo = const Value.absent(),
  }) : nome = Value(nome);
  static Insertable<Produto> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? categoria,
    Expression<int>? grupoPrecoId,
    Expression<int>? tempoMedioMinutos,
    Expression<bool>? controlaEstoque,
    Expression<int>? ordemProducao,
    Expression<bool>? ativo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (categoria != null) 'categoria': categoria,
      if (grupoPrecoId != null) 'grupo_preco_id': grupoPrecoId,
      if (tempoMedioMinutos != null) 'tempo_medio_minutos': tempoMedioMinutos,
      if (controlaEstoque != null) 'controla_estoque': controlaEstoque,
      if (ordemProducao != null) 'ordem_producao': ordemProducao,
      if (ativo != null) 'ativo': ativo,
    });
  }

  ProdutosCompanion copyWith(
      {Value<int>? id,
      Value<String>? nome,
      Value<String>? categoria,
      Value<int?>? grupoPrecoId,
      Value<int>? tempoMedioMinutos,
      Value<bool>? controlaEstoque,
      Value<int>? ordemProducao,
      Value<bool>? ativo}) {
    return ProdutosCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      grupoPrecoId: grupoPrecoId ?? this.grupoPrecoId,
      tempoMedioMinutos: tempoMedioMinutos ?? this.tempoMedioMinutos,
      controlaEstoque: controlaEstoque ?? this.controlaEstoque,
      ordemProducao: ordemProducao ?? this.ordemProducao,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (grupoPrecoId.present) {
      map['grupo_preco_id'] = Variable<int>(grupoPrecoId.value);
    }
    if (tempoMedioMinutos.present) {
      map['tempo_medio_minutos'] = Variable<int>(tempoMedioMinutos.value);
    }
    if (controlaEstoque.present) {
      map['controla_estoque'] = Variable<bool>(controlaEstoque.value);
    }
    if (ordemProducao.present) {
      map['ordem_producao'] = Variable<int>(ordemProducao.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProdutosCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('categoria: $categoria, ')
          ..write('grupoPrecoId: $grupoPrecoId, ')
          ..write('tempoMedioMinutos: $tempoMedioMinutos, ')
          ..write('controlaEstoque: $controlaEstoque, ')
          ..write('ordemProducao: $ordemProducao, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }
}

class $FaixasPrecoTable extends FaixasPreco
    with TableInfo<$FaixasPrecoTable, FaixasPrecoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FaixasPrecoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _produtoIdMeta =
      const VerificationMeta('produtoId');
  @override
  late final GeneratedColumn<int> produtoId = GeneratedColumn<int>(
      'produto_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES produtos (id) ON DELETE CASCADE'));
  static const VerificationMeta _grupoPrecoIdMeta =
      const VerificationMeta('grupoPrecoId');
  @override
  late final GeneratedColumn<int> grupoPrecoId = GeneratedColumn<int>(
      'grupo_preco_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES grupos_preco (id) ON DELETE CASCADE'));
  static const VerificationMeta _quantidadeMinimaMeta =
      const VerificationMeta('quantidadeMinima');
  @override
  late final GeneratedColumn<int> quantidadeMinima = GeneratedColumn<int>(
      'quantidade_minima', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _quantidadeMaximaMeta =
      const VerificationMeta('quantidadeMaxima');
  @override
  late final GeneratedColumn<int> quantidadeMaxima = GeneratedColumn<int>(
      'quantidade_maxima', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _valorUnitarioCentavosMeta =
      const VerificationMeta('valorUnitarioCentavos');
  @override
  late final GeneratedColumn<int> valorUnitarioCentavos = GeneratedColumn<int>(
      'valor_unitario_centavos', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        produtoId,
        grupoPrecoId,
        quantidadeMinima,
        quantidadeMaxima,
        valorUnitarioCentavos
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'faixas_preco';
  @override
  VerificationContext validateIntegrity(Insertable<FaixasPrecoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('produto_id')) {
      context.handle(_produtoIdMeta,
          produtoId.isAcceptableOrUnknown(data['produto_id']!, _produtoIdMeta));
    }
    if (data.containsKey('grupo_preco_id')) {
      context.handle(
          _grupoPrecoIdMeta,
          grupoPrecoId.isAcceptableOrUnknown(
              data['grupo_preco_id']!, _grupoPrecoIdMeta));
    }
    if (data.containsKey('quantidade_minima')) {
      context.handle(
          _quantidadeMinimaMeta,
          quantidadeMinima.isAcceptableOrUnknown(
              data['quantidade_minima']!, _quantidadeMinimaMeta));
    } else if (isInserting) {
      context.missing(_quantidadeMinimaMeta);
    }
    if (data.containsKey('quantidade_maxima')) {
      context.handle(
          _quantidadeMaximaMeta,
          quantidadeMaxima.isAcceptableOrUnknown(
              data['quantidade_maxima']!, _quantidadeMaximaMeta));
    }
    if (data.containsKey('valor_unitario_centavos')) {
      context.handle(
          _valorUnitarioCentavosMeta,
          valorUnitarioCentavos.isAcceptableOrUnknown(
              data['valor_unitario_centavos']!, _valorUnitarioCentavosMeta));
    } else if (isInserting) {
      context.missing(_valorUnitarioCentavosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FaixasPrecoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FaixasPrecoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      produtoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}produto_id']),
      grupoPrecoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grupo_preco_id']),
      quantidadeMinima: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantidade_minima'])!,
      quantidadeMaxima: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantidade_maxima']),
      valorUnitarioCentavos: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}valor_unitario_centavos'])!,
    );
  }

  @override
  $FaixasPrecoTable createAlias(String alias) {
    return $FaixasPrecoTable(attachedDatabase, alias);
  }
}

class FaixasPrecoData extends DataClass implements Insertable<FaixasPrecoData> {
  final int id;
  final int? produtoId;
  final int? grupoPrecoId;
  final int quantidadeMinima;
  final int? quantidadeMaxima;
  final int valorUnitarioCentavos;
  const FaixasPrecoData(
      {required this.id,
      this.produtoId,
      this.grupoPrecoId,
      required this.quantidadeMinima,
      this.quantidadeMaxima,
      required this.valorUnitarioCentavos});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || produtoId != null) {
      map['produto_id'] = Variable<int>(produtoId);
    }
    if (!nullToAbsent || grupoPrecoId != null) {
      map['grupo_preco_id'] = Variable<int>(grupoPrecoId);
    }
    map['quantidade_minima'] = Variable<int>(quantidadeMinima);
    if (!nullToAbsent || quantidadeMaxima != null) {
      map['quantidade_maxima'] = Variable<int>(quantidadeMaxima);
    }
    map['valor_unitario_centavos'] = Variable<int>(valorUnitarioCentavos);
    return map;
  }

  FaixasPrecoCompanion toCompanion(bool nullToAbsent) {
    return FaixasPrecoCompanion(
      id: Value(id),
      produtoId: produtoId == null && nullToAbsent
          ? const Value.absent()
          : Value(produtoId),
      grupoPrecoId: grupoPrecoId == null && nullToAbsent
          ? const Value.absent()
          : Value(grupoPrecoId),
      quantidadeMinima: Value(quantidadeMinima),
      quantidadeMaxima: quantidadeMaxima == null && nullToAbsent
          ? const Value.absent()
          : Value(quantidadeMaxima),
      valorUnitarioCentavos: Value(valorUnitarioCentavos),
    );
  }

  factory FaixasPrecoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FaixasPrecoData(
      id: serializer.fromJson<int>(json['id']),
      produtoId: serializer.fromJson<int?>(json['produtoId']),
      grupoPrecoId: serializer.fromJson<int?>(json['grupoPrecoId']),
      quantidadeMinima: serializer.fromJson<int>(json['quantidadeMinima']),
      quantidadeMaxima: serializer.fromJson<int?>(json['quantidadeMaxima']),
      valorUnitarioCentavos:
          serializer.fromJson<int>(json['valorUnitarioCentavos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'produtoId': serializer.toJson<int?>(produtoId),
      'grupoPrecoId': serializer.toJson<int?>(grupoPrecoId),
      'quantidadeMinima': serializer.toJson<int>(quantidadeMinima),
      'quantidadeMaxima': serializer.toJson<int?>(quantidadeMaxima),
      'valorUnitarioCentavos': serializer.toJson<int>(valorUnitarioCentavos),
    };
  }

  FaixasPrecoData copyWith(
          {int? id,
          Value<int?> produtoId = const Value.absent(),
          Value<int?> grupoPrecoId = const Value.absent(),
          int? quantidadeMinima,
          Value<int?> quantidadeMaxima = const Value.absent(),
          int? valorUnitarioCentavos}) =>
      FaixasPrecoData(
        id: id ?? this.id,
        produtoId: produtoId.present ? produtoId.value : this.produtoId,
        grupoPrecoId:
            grupoPrecoId.present ? grupoPrecoId.value : this.grupoPrecoId,
        quantidadeMinima: quantidadeMinima ?? this.quantidadeMinima,
        quantidadeMaxima: quantidadeMaxima.present
            ? quantidadeMaxima.value
            : this.quantidadeMaxima,
        valorUnitarioCentavos:
            valorUnitarioCentavos ?? this.valorUnitarioCentavos,
      );
  FaixasPrecoData copyWithCompanion(FaixasPrecoCompanion data) {
    return FaixasPrecoData(
      id: data.id.present ? data.id.value : this.id,
      produtoId: data.produtoId.present ? data.produtoId.value : this.produtoId,
      grupoPrecoId: data.grupoPrecoId.present
          ? data.grupoPrecoId.value
          : this.grupoPrecoId,
      quantidadeMinima: data.quantidadeMinima.present
          ? data.quantidadeMinima.value
          : this.quantidadeMinima,
      quantidadeMaxima: data.quantidadeMaxima.present
          ? data.quantidadeMaxima.value
          : this.quantidadeMaxima,
      valorUnitarioCentavos: data.valorUnitarioCentavos.present
          ? data.valorUnitarioCentavos.value
          : this.valorUnitarioCentavos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FaixasPrecoData(')
          ..write('id: $id, ')
          ..write('produtoId: $produtoId, ')
          ..write('grupoPrecoId: $grupoPrecoId, ')
          ..write('quantidadeMinima: $quantidadeMinima, ')
          ..write('quantidadeMaxima: $quantidadeMaxima, ')
          ..write('valorUnitarioCentavos: $valorUnitarioCentavos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, produtoId, grupoPrecoId, quantidadeMinima,
      quantidadeMaxima, valorUnitarioCentavos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FaixasPrecoData &&
          other.id == this.id &&
          other.produtoId == this.produtoId &&
          other.grupoPrecoId == this.grupoPrecoId &&
          other.quantidadeMinima == this.quantidadeMinima &&
          other.quantidadeMaxima == this.quantidadeMaxima &&
          other.valorUnitarioCentavos == this.valorUnitarioCentavos);
}

class FaixasPrecoCompanion extends UpdateCompanion<FaixasPrecoData> {
  final Value<int> id;
  final Value<int?> produtoId;
  final Value<int?> grupoPrecoId;
  final Value<int> quantidadeMinima;
  final Value<int?> quantidadeMaxima;
  final Value<int> valorUnitarioCentavos;
  const FaixasPrecoCompanion({
    this.id = const Value.absent(),
    this.produtoId = const Value.absent(),
    this.grupoPrecoId = const Value.absent(),
    this.quantidadeMinima = const Value.absent(),
    this.quantidadeMaxima = const Value.absent(),
    this.valorUnitarioCentavos = const Value.absent(),
  });
  FaixasPrecoCompanion.insert({
    this.id = const Value.absent(),
    this.produtoId = const Value.absent(),
    this.grupoPrecoId = const Value.absent(),
    required int quantidadeMinima,
    this.quantidadeMaxima = const Value.absent(),
    required int valorUnitarioCentavos,
  })  : quantidadeMinima = Value(quantidadeMinima),
        valorUnitarioCentavos = Value(valorUnitarioCentavos);
  static Insertable<FaixasPrecoData> custom({
    Expression<int>? id,
    Expression<int>? produtoId,
    Expression<int>? grupoPrecoId,
    Expression<int>? quantidadeMinima,
    Expression<int>? quantidadeMaxima,
    Expression<int>? valorUnitarioCentavos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (produtoId != null) 'produto_id': produtoId,
      if (grupoPrecoId != null) 'grupo_preco_id': grupoPrecoId,
      if (quantidadeMinima != null) 'quantidade_minima': quantidadeMinima,
      if (quantidadeMaxima != null) 'quantidade_maxima': quantidadeMaxima,
      if (valorUnitarioCentavos != null)
        'valor_unitario_centavos': valorUnitarioCentavos,
    });
  }

  FaixasPrecoCompanion copyWith(
      {Value<int>? id,
      Value<int?>? produtoId,
      Value<int?>? grupoPrecoId,
      Value<int>? quantidadeMinima,
      Value<int?>? quantidadeMaxima,
      Value<int>? valorUnitarioCentavos}) {
    return FaixasPrecoCompanion(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      grupoPrecoId: grupoPrecoId ?? this.grupoPrecoId,
      quantidadeMinima: quantidadeMinima ?? this.quantidadeMinima,
      quantidadeMaxima: quantidadeMaxima ?? this.quantidadeMaxima,
      valorUnitarioCentavos:
          valorUnitarioCentavos ?? this.valorUnitarioCentavos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (produtoId.present) {
      map['produto_id'] = Variable<int>(produtoId.value);
    }
    if (grupoPrecoId.present) {
      map['grupo_preco_id'] = Variable<int>(grupoPrecoId.value);
    }
    if (quantidadeMinima.present) {
      map['quantidade_minima'] = Variable<int>(quantidadeMinima.value);
    }
    if (quantidadeMaxima.present) {
      map['quantidade_maxima'] = Variable<int>(quantidadeMaxima.value);
    }
    if (valorUnitarioCentavos.present) {
      map['valor_unitario_centavos'] =
          Variable<int>(valorUnitarioCentavos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FaixasPrecoCompanion(')
          ..write('id: $id, ')
          ..write('produtoId: $produtoId, ')
          ..write('grupoPrecoId: $grupoPrecoId, ')
          ..write('quantidadeMinima: $quantidadeMinima, ')
          ..write('quantidadeMaxima: $quantidadeMaxima, ')
          ..write('valorUnitarioCentavos: $valorUnitarioCentavos')
          ..write(')'))
        .toString();
  }
}

class $ClientesTable extends Clientes with TableInfo<$ClientesTable, Cliente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _telefoneMeta =
      const VerificationMeta('telefone');
  @override
  late final GeneratedColumn<String> telefone = GeneratedColumn<String>(
      'telefone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _logradouroMeta =
      const VerificationMeta('logradouro');
  @override
  late final GeneratedColumn<String> logradouro = GeneratedColumn<String>(
      'logradouro', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _numeroMeta = const VerificationMeta('numero');
  @override
  late final GeneratedColumn<String> numero = GeneratedColumn<String>(
      'numero', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _bairroMeta = const VerificationMeta('bairro');
  @override
  late final GeneratedColumn<String> bairro = GeneratedColumn<String>(
      'bairro', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _cidadeMeta = const VerificationMeta('cidade');
  @override
  late final GeneratedColumn<String> cidade = GeneratedColumn<String>(
      'cidade', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _cepMeta = const VerificationMeta('cep');
  @override
  late final GeneratedColumn<String> cep = GeneratedColumn<String>(
      'cep', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _referenciaMeta =
      const VerificationMeta('referencia');
  @override
  late final GeneratedColumn<String> referencia = GeneratedColumn<String>(
      'referencia', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _observacoesMeta =
      const VerificationMeta('observacoes');
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
      'observacoes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
      'ativo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ativo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nome,
        telefone,
        logradouro,
        numero,
        bairro,
        cidade,
        cep,
        referencia,
        observacoes,
        ativo
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clientes';
  @override
  VerificationContext validateIntegrity(Insertable<Cliente> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('telefone')) {
      context.handle(_telefoneMeta,
          telefone.isAcceptableOrUnknown(data['telefone']!, _telefoneMeta));
    }
    if (data.containsKey('logradouro')) {
      context.handle(
          _logradouroMeta,
          logradouro.isAcceptableOrUnknown(
              data['logradouro']!, _logradouroMeta));
    }
    if (data.containsKey('numero')) {
      context.handle(_numeroMeta,
          numero.isAcceptableOrUnknown(data['numero']!, _numeroMeta));
    }
    if (data.containsKey('bairro')) {
      context.handle(_bairroMeta,
          bairro.isAcceptableOrUnknown(data['bairro']!, _bairroMeta));
    }
    if (data.containsKey('cidade')) {
      context.handle(_cidadeMeta,
          cidade.isAcceptableOrUnknown(data['cidade']!, _cidadeMeta));
    }
    if (data.containsKey('cep')) {
      context.handle(
          _cepMeta, cep.isAcceptableOrUnknown(data['cep']!, _cepMeta));
    }
    if (data.containsKey('referencia')) {
      context.handle(
          _referenciaMeta,
          referencia.isAcceptableOrUnknown(
              data['referencia']!, _referenciaMeta));
    }
    if (data.containsKey('observacoes')) {
      context.handle(
          _observacoesMeta,
          observacoes.isAcceptableOrUnknown(
              data['observacoes']!, _observacoesMeta));
    }
    if (data.containsKey('ativo')) {
      context.handle(
          _ativoMeta, ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cliente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cliente(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      telefone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}telefone'])!,
      logradouro: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logradouro'])!,
      numero: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}numero'])!,
      bairro: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bairro'])!,
      cidade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cidade'])!,
      cep: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cep'])!,
      referencia: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}referencia'])!,
      observacoes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacoes'])!,
      ativo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ativo'])!,
    );
  }

  @override
  $ClientesTable createAlias(String alias) {
    return $ClientesTable(attachedDatabase, alias);
  }
}

class Cliente extends DataClass implements Insertable<Cliente> {
  final int id;
  final String nome;
  final String telefone;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String cep;
  final String referencia;
  final String observacoes;
  final bool ativo;
  const Cliente(
      {required this.id,
      required this.nome,
      required this.telefone,
      required this.logradouro,
      required this.numero,
      required this.bairro,
      required this.cidade,
      required this.cep,
      required this.referencia,
      required this.observacoes,
      required this.ativo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['telefone'] = Variable<String>(telefone);
    map['logradouro'] = Variable<String>(logradouro);
    map['numero'] = Variable<String>(numero);
    map['bairro'] = Variable<String>(bairro);
    map['cidade'] = Variable<String>(cidade);
    map['cep'] = Variable<String>(cep);
    map['referencia'] = Variable<String>(referencia);
    map['observacoes'] = Variable<String>(observacoes);
    map['ativo'] = Variable<bool>(ativo);
    return map;
  }

  ClientesCompanion toCompanion(bool nullToAbsent) {
    return ClientesCompanion(
      id: Value(id),
      nome: Value(nome),
      telefone: Value(telefone),
      logradouro: Value(logradouro),
      numero: Value(numero),
      bairro: Value(bairro),
      cidade: Value(cidade),
      cep: Value(cep),
      referencia: Value(referencia),
      observacoes: Value(observacoes),
      ativo: Value(ativo),
    );
  }

  factory Cliente.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cliente(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      telefone: serializer.fromJson<String>(json['telefone']),
      logradouro: serializer.fromJson<String>(json['logradouro']),
      numero: serializer.fromJson<String>(json['numero']),
      bairro: serializer.fromJson<String>(json['bairro']),
      cidade: serializer.fromJson<String>(json['cidade']),
      cep: serializer.fromJson<String>(json['cep']),
      referencia: serializer.fromJson<String>(json['referencia']),
      observacoes: serializer.fromJson<String>(json['observacoes']),
      ativo: serializer.fromJson<bool>(json['ativo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'telefone': serializer.toJson<String>(telefone),
      'logradouro': serializer.toJson<String>(logradouro),
      'numero': serializer.toJson<String>(numero),
      'bairro': serializer.toJson<String>(bairro),
      'cidade': serializer.toJson<String>(cidade),
      'cep': serializer.toJson<String>(cep),
      'referencia': serializer.toJson<String>(referencia),
      'observacoes': serializer.toJson<String>(observacoes),
      'ativo': serializer.toJson<bool>(ativo),
    };
  }

  Cliente copyWith(
          {int? id,
          String? nome,
          String? telefone,
          String? logradouro,
          String? numero,
          String? bairro,
          String? cidade,
          String? cep,
          String? referencia,
          String? observacoes,
          bool? ativo}) =>
      Cliente(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        telefone: telefone ?? this.telefone,
        logradouro: logradouro ?? this.logradouro,
        numero: numero ?? this.numero,
        bairro: bairro ?? this.bairro,
        cidade: cidade ?? this.cidade,
        cep: cep ?? this.cep,
        referencia: referencia ?? this.referencia,
        observacoes: observacoes ?? this.observacoes,
        ativo: ativo ?? this.ativo,
      );
  Cliente copyWithCompanion(ClientesCompanion data) {
    return Cliente(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      telefone: data.telefone.present ? data.telefone.value : this.telefone,
      logradouro:
          data.logradouro.present ? data.logradouro.value : this.logradouro,
      numero: data.numero.present ? data.numero.value : this.numero,
      bairro: data.bairro.present ? data.bairro.value : this.bairro,
      cidade: data.cidade.present ? data.cidade.value : this.cidade,
      cep: data.cep.present ? data.cep.value : this.cep,
      referencia:
          data.referencia.present ? data.referencia.value : this.referencia,
      observacoes:
          data.observacoes.present ? data.observacoes.value : this.observacoes,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cliente(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('telefone: $telefone, ')
          ..write('logradouro: $logradouro, ')
          ..write('numero: $numero, ')
          ..write('bairro: $bairro, ')
          ..write('cidade: $cidade, ')
          ..write('cep: $cep, ')
          ..write('referencia: $referencia, ')
          ..write('observacoes: $observacoes, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, telefone, logradouro, numero,
      bairro, cidade, cep, referencia, observacoes, ativo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cliente &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.telefone == this.telefone &&
          other.logradouro == this.logradouro &&
          other.numero == this.numero &&
          other.bairro == this.bairro &&
          other.cidade == this.cidade &&
          other.cep == this.cep &&
          other.referencia == this.referencia &&
          other.observacoes == this.observacoes &&
          other.ativo == this.ativo);
}

class ClientesCompanion extends UpdateCompanion<Cliente> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String> telefone;
  final Value<String> logradouro;
  final Value<String> numero;
  final Value<String> bairro;
  final Value<String> cidade;
  final Value<String> cep;
  final Value<String> referencia;
  final Value<String> observacoes;
  final Value<bool> ativo;
  const ClientesCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.telefone = const Value.absent(),
    this.logradouro = const Value.absent(),
    this.numero = const Value.absent(),
    this.bairro = const Value.absent(),
    this.cidade = const Value.absent(),
    this.cep = const Value.absent(),
    this.referencia = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.ativo = const Value.absent(),
  });
  ClientesCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    this.telefone = const Value.absent(),
    this.logradouro = const Value.absent(),
    this.numero = const Value.absent(),
    this.bairro = const Value.absent(),
    this.cidade = const Value.absent(),
    this.cep = const Value.absent(),
    this.referencia = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.ativo = const Value.absent(),
  }) : nome = Value(nome);
  static Insertable<Cliente> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? telefone,
    Expression<String>? logradouro,
    Expression<String>? numero,
    Expression<String>? bairro,
    Expression<String>? cidade,
    Expression<String>? cep,
    Expression<String>? referencia,
    Expression<String>? observacoes,
    Expression<bool>? ativo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (telefone != null) 'telefone': telefone,
      if (logradouro != null) 'logradouro': logradouro,
      if (numero != null) 'numero': numero,
      if (bairro != null) 'bairro': bairro,
      if (cidade != null) 'cidade': cidade,
      if (cep != null) 'cep': cep,
      if (referencia != null) 'referencia': referencia,
      if (observacoes != null) 'observacoes': observacoes,
      if (ativo != null) 'ativo': ativo,
    });
  }

  ClientesCompanion copyWith(
      {Value<int>? id,
      Value<String>? nome,
      Value<String>? telefone,
      Value<String>? logradouro,
      Value<String>? numero,
      Value<String>? bairro,
      Value<String>? cidade,
      Value<String>? cep,
      Value<String>? referencia,
      Value<String>? observacoes,
      Value<bool>? ativo}) {
    return ClientesCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      cep: cep ?? this.cep,
      referencia: referencia ?? this.referencia,
      observacoes: observacoes ?? this.observacoes,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (telefone.present) {
      map['telefone'] = Variable<String>(telefone.value);
    }
    if (logradouro.present) {
      map['logradouro'] = Variable<String>(logradouro.value);
    }
    if (numero.present) {
      map['numero'] = Variable<String>(numero.value);
    }
    if (bairro.present) {
      map['bairro'] = Variable<String>(bairro.value);
    }
    if (cidade.present) {
      map['cidade'] = Variable<String>(cidade.value);
    }
    if (cep.present) {
      map['cep'] = Variable<String>(cep.value);
    }
    if (referencia.present) {
      map['referencia'] = Variable<String>(referencia.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientesCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('telefone: $telefone, ')
          ..write('logradouro: $logradouro, ')
          ..write('numero: $numero, ')
          ..write('bairro: $bairro, ')
          ..write('cidade: $cidade, ')
          ..write('cep: $cep, ')
          ..write('referencia: $referencia, ')
          ..write('observacoes: $observacoes, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }
}

class $LocaisEntregaTable extends LocaisEntrega
    with TableInfo<$LocaisEntregaTable, LocaisEntregaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocaisEntregaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _clienteIdMeta =
      const VerificationMeta('clienteId');
  @override
  late final GeneratedColumn<int> clienteId = GeneratedColumn<int>(
      'cliente_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES clientes (id) ON DELETE CASCADE'));
  static const VerificationMeta _nomeIdentificadorMeta =
      const VerificationMeta('nomeIdentificador');
  @override
  late final GeneratedColumn<String> nomeIdentificador =
      GeneratedColumn<String>('nome_identificador', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('Principal'));
  static const VerificationMeta _logradouroMeta =
      const VerificationMeta('logradouro');
  @override
  late final GeneratedColumn<String> logradouro = GeneratedColumn<String>(
      'logradouro', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numeroMeta = const VerificationMeta('numero');
  @override
  late final GeneratedColumn<String> numero = GeneratedColumn<String>(
      'numero', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bairroMeta = const VerificationMeta('bairro');
  @override
  late final GeneratedColumn<String> bairro = GeneratedColumn<String>(
      'bairro', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cidadeMeta = const VerificationMeta('cidade');
  @override
  late final GeneratedColumn<String> cidade = GeneratedColumn<String>(
      'cidade', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _cepMeta = const VerificationMeta('cep');
  @override
  late final GeneratedColumn<String> cep = GeneratedColumn<String>(
      'cep', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _referenciaMeta =
      const VerificationMeta('referencia');
  @override
  late final GeneratedColumn<String> referencia = GeneratedColumn<String>(
      'referencia', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
      'ativo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ativo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clienteId,
        nomeIdentificador,
        logradouro,
        numero,
        bairro,
        cidade,
        cep,
        referencia,
        ativo
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locais_entrega';
  @override
  VerificationContext validateIntegrity(Insertable<LocaisEntregaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cliente_id')) {
      context.handle(_clienteIdMeta,
          clienteId.isAcceptableOrUnknown(data['cliente_id']!, _clienteIdMeta));
    } else if (isInserting) {
      context.missing(_clienteIdMeta);
    }
    if (data.containsKey('nome_identificador')) {
      context.handle(
          _nomeIdentificadorMeta,
          nomeIdentificador.isAcceptableOrUnknown(
              data['nome_identificador']!, _nomeIdentificadorMeta));
    }
    if (data.containsKey('logradouro')) {
      context.handle(
          _logradouroMeta,
          logradouro.isAcceptableOrUnknown(
              data['logradouro']!, _logradouroMeta));
    } else if (isInserting) {
      context.missing(_logradouroMeta);
    }
    if (data.containsKey('numero')) {
      context.handle(_numeroMeta,
          numero.isAcceptableOrUnknown(data['numero']!, _numeroMeta));
    } else if (isInserting) {
      context.missing(_numeroMeta);
    }
    if (data.containsKey('bairro')) {
      context.handle(_bairroMeta,
          bairro.isAcceptableOrUnknown(data['bairro']!, _bairroMeta));
    } else if (isInserting) {
      context.missing(_bairroMeta);
    }
    if (data.containsKey('cidade')) {
      context.handle(_cidadeMeta,
          cidade.isAcceptableOrUnknown(data['cidade']!, _cidadeMeta));
    }
    if (data.containsKey('cep')) {
      context.handle(
          _cepMeta, cep.isAcceptableOrUnknown(data['cep']!, _cepMeta));
    }
    if (data.containsKey('referencia')) {
      context.handle(
          _referenciaMeta,
          referencia.isAcceptableOrUnknown(
              data['referencia']!, _referenciaMeta));
    }
    if (data.containsKey('ativo')) {
      context.handle(
          _ativoMeta, ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocaisEntregaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocaisEntregaData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      clienteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cliente_id'])!,
      nomeIdentificador: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}nome_identificador'])!,
      logradouro: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logradouro'])!,
      numero: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}numero'])!,
      bairro: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bairro'])!,
      cidade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cidade'])!,
      cep: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cep'])!,
      referencia: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}referencia'])!,
      ativo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ativo'])!,
    );
  }

  @override
  $LocaisEntregaTable createAlias(String alias) {
    return $LocaisEntregaTable(attachedDatabase, alias);
  }
}

class LocaisEntregaData extends DataClass
    implements Insertable<LocaisEntregaData> {
  final int id;
  final int clienteId;
  final String nomeIdentificador;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String cep;
  final String referencia;
  final bool ativo;
  const LocaisEntregaData(
      {required this.id,
      required this.clienteId,
      required this.nomeIdentificador,
      required this.logradouro,
      required this.numero,
      required this.bairro,
      required this.cidade,
      required this.cep,
      required this.referencia,
      required this.ativo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cliente_id'] = Variable<int>(clienteId);
    map['nome_identificador'] = Variable<String>(nomeIdentificador);
    map['logradouro'] = Variable<String>(logradouro);
    map['numero'] = Variable<String>(numero);
    map['bairro'] = Variable<String>(bairro);
    map['cidade'] = Variable<String>(cidade);
    map['cep'] = Variable<String>(cep);
    map['referencia'] = Variable<String>(referencia);
    map['ativo'] = Variable<bool>(ativo);
    return map;
  }

  LocaisEntregaCompanion toCompanion(bool nullToAbsent) {
    return LocaisEntregaCompanion(
      id: Value(id),
      clienteId: Value(clienteId),
      nomeIdentificador: Value(nomeIdentificador),
      logradouro: Value(logradouro),
      numero: Value(numero),
      bairro: Value(bairro),
      cidade: Value(cidade),
      cep: Value(cep),
      referencia: Value(referencia),
      ativo: Value(ativo),
    );
  }

  factory LocaisEntregaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocaisEntregaData(
      id: serializer.fromJson<int>(json['id']),
      clienteId: serializer.fromJson<int>(json['clienteId']),
      nomeIdentificador: serializer.fromJson<String>(json['nomeIdentificador']),
      logradouro: serializer.fromJson<String>(json['logradouro']),
      numero: serializer.fromJson<String>(json['numero']),
      bairro: serializer.fromJson<String>(json['bairro']),
      cidade: serializer.fromJson<String>(json['cidade']),
      cep: serializer.fromJson<String>(json['cep']),
      referencia: serializer.fromJson<String>(json['referencia']),
      ativo: serializer.fromJson<bool>(json['ativo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clienteId': serializer.toJson<int>(clienteId),
      'nomeIdentificador': serializer.toJson<String>(nomeIdentificador),
      'logradouro': serializer.toJson<String>(logradouro),
      'numero': serializer.toJson<String>(numero),
      'bairro': serializer.toJson<String>(bairro),
      'cidade': serializer.toJson<String>(cidade),
      'cep': serializer.toJson<String>(cep),
      'referencia': serializer.toJson<String>(referencia),
      'ativo': serializer.toJson<bool>(ativo),
    };
  }

  LocaisEntregaData copyWith(
          {int? id,
          int? clienteId,
          String? nomeIdentificador,
          String? logradouro,
          String? numero,
          String? bairro,
          String? cidade,
          String? cep,
          String? referencia,
          bool? ativo}) =>
      LocaisEntregaData(
        id: id ?? this.id,
        clienteId: clienteId ?? this.clienteId,
        nomeIdentificador: nomeIdentificador ?? this.nomeIdentificador,
        logradouro: logradouro ?? this.logradouro,
        numero: numero ?? this.numero,
        bairro: bairro ?? this.bairro,
        cidade: cidade ?? this.cidade,
        cep: cep ?? this.cep,
        referencia: referencia ?? this.referencia,
        ativo: ativo ?? this.ativo,
      );
  LocaisEntregaData copyWithCompanion(LocaisEntregaCompanion data) {
    return LocaisEntregaData(
      id: data.id.present ? data.id.value : this.id,
      clienteId: data.clienteId.present ? data.clienteId.value : this.clienteId,
      nomeIdentificador: data.nomeIdentificador.present
          ? data.nomeIdentificador.value
          : this.nomeIdentificador,
      logradouro:
          data.logradouro.present ? data.logradouro.value : this.logradouro,
      numero: data.numero.present ? data.numero.value : this.numero,
      bairro: data.bairro.present ? data.bairro.value : this.bairro,
      cidade: data.cidade.present ? data.cidade.value : this.cidade,
      cep: data.cep.present ? data.cep.value : this.cep,
      referencia:
          data.referencia.present ? data.referencia.value : this.referencia,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocaisEntregaData(')
          ..write('id: $id, ')
          ..write('clienteId: $clienteId, ')
          ..write('nomeIdentificador: $nomeIdentificador, ')
          ..write('logradouro: $logradouro, ')
          ..write('numero: $numero, ')
          ..write('bairro: $bairro, ')
          ..write('cidade: $cidade, ')
          ..write('cep: $cep, ')
          ..write('referencia: $referencia, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, clienteId, nomeIdentificador, logradouro,
      numero, bairro, cidade, cep, referencia, ativo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocaisEntregaData &&
          other.id == this.id &&
          other.clienteId == this.clienteId &&
          other.nomeIdentificador == this.nomeIdentificador &&
          other.logradouro == this.logradouro &&
          other.numero == this.numero &&
          other.bairro == this.bairro &&
          other.cidade == this.cidade &&
          other.cep == this.cep &&
          other.referencia == this.referencia &&
          other.ativo == this.ativo);
}

class LocaisEntregaCompanion extends UpdateCompanion<LocaisEntregaData> {
  final Value<int> id;
  final Value<int> clienteId;
  final Value<String> nomeIdentificador;
  final Value<String> logradouro;
  final Value<String> numero;
  final Value<String> bairro;
  final Value<String> cidade;
  final Value<String> cep;
  final Value<String> referencia;
  final Value<bool> ativo;
  const LocaisEntregaCompanion({
    this.id = const Value.absent(),
    this.clienteId = const Value.absent(),
    this.nomeIdentificador = const Value.absent(),
    this.logradouro = const Value.absent(),
    this.numero = const Value.absent(),
    this.bairro = const Value.absent(),
    this.cidade = const Value.absent(),
    this.cep = const Value.absent(),
    this.referencia = const Value.absent(),
    this.ativo = const Value.absent(),
  });
  LocaisEntregaCompanion.insert({
    this.id = const Value.absent(),
    required int clienteId,
    this.nomeIdentificador = const Value.absent(),
    required String logradouro,
    required String numero,
    required String bairro,
    this.cidade = const Value.absent(),
    this.cep = const Value.absent(),
    this.referencia = const Value.absent(),
    this.ativo = const Value.absent(),
  })  : clienteId = Value(clienteId),
        logradouro = Value(logradouro),
        numero = Value(numero),
        bairro = Value(bairro);
  static Insertable<LocaisEntregaData> custom({
    Expression<int>? id,
    Expression<int>? clienteId,
    Expression<String>? nomeIdentificador,
    Expression<String>? logradouro,
    Expression<String>? numero,
    Expression<String>? bairro,
    Expression<String>? cidade,
    Expression<String>? cep,
    Expression<String>? referencia,
    Expression<bool>? ativo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clienteId != null) 'cliente_id': clienteId,
      if (nomeIdentificador != null) 'nome_identificador': nomeIdentificador,
      if (logradouro != null) 'logradouro': logradouro,
      if (numero != null) 'numero': numero,
      if (bairro != null) 'bairro': bairro,
      if (cidade != null) 'cidade': cidade,
      if (cep != null) 'cep': cep,
      if (referencia != null) 'referencia': referencia,
      if (ativo != null) 'ativo': ativo,
    });
  }

  LocaisEntregaCompanion copyWith(
      {Value<int>? id,
      Value<int>? clienteId,
      Value<String>? nomeIdentificador,
      Value<String>? logradouro,
      Value<String>? numero,
      Value<String>? bairro,
      Value<String>? cidade,
      Value<String>? cep,
      Value<String>? referencia,
      Value<bool>? ativo}) {
    return LocaisEntregaCompanion(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      nomeIdentificador: nomeIdentificador ?? this.nomeIdentificador,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      cep: cep ?? this.cep,
      referencia: referencia ?? this.referencia,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clienteId.present) {
      map['cliente_id'] = Variable<int>(clienteId.value);
    }
    if (nomeIdentificador.present) {
      map['nome_identificador'] = Variable<String>(nomeIdentificador.value);
    }
    if (logradouro.present) {
      map['logradouro'] = Variable<String>(logradouro.value);
    }
    if (numero.present) {
      map['numero'] = Variable<String>(numero.value);
    }
    if (bairro.present) {
      map['bairro'] = Variable<String>(bairro.value);
    }
    if (cidade.present) {
      map['cidade'] = Variable<String>(cidade.value);
    }
    if (cep.present) {
      map['cep'] = Variable<String>(cep.value);
    }
    if (referencia.present) {
      map['referencia'] = Variable<String>(referencia.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocaisEntregaCompanion(')
          ..write('id: $id, ')
          ..write('clienteId: $clienteId, ')
          ..write('nomeIdentificador: $nomeIdentificador, ')
          ..write('logradouro: $logradouro, ')
          ..write('numero: $numero, ')
          ..write('bairro: $bairro, ')
          ..write('cidade: $cidade, ')
          ..write('cep: $cep, ')
          ..write('referencia: $referencia, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }
}

class $OrigensPedidoTable extends OrigensPedido
    with TableInfo<$OrigensPedidoTable, OrigensPedidoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrigensPedidoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _iconeMeta = const VerificationMeta('icone');
  @override
  late final GeneratedColumn<String> icone = GeneratedColumn<String>(
      'icone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
      'ativo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ativo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [id, nome, icone, ativo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'origens_pedido';
  @override
  VerificationContext validateIntegrity(Insertable<OrigensPedidoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('icone')) {
      context.handle(
          _iconeMeta, icone.isAcceptableOrUnknown(data['icone']!, _iconeMeta));
    }
    if (data.containsKey('ativo')) {
      context.handle(
          _ativoMeta, ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrigensPedidoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrigensPedidoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      icone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icone']),
      ativo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ativo'])!,
    );
  }

  @override
  $OrigensPedidoTable createAlias(String alias) {
    return $OrigensPedidoTable(attachedDatabase, alias);
  }
}

class OrigensPedidoData extends DataClass
    implements Insertable<OrigensPedidoData> {
  final int id;
  final String nome;
  final String? icone;
  final bool ativo;
  const OrigensPedidoData(
      {required this.id, required this.nome, this.icone, required this.ativo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || icone != null) {
      map['icone'] = Variable<String>(icone);
    }
    map['ativo'] = Variable<bool>(ativo);
    return map;
  }

  OrigensPedidoCompanion toCompanion(bool nullToAbsent) {
    return OrigensPedidoCompanion(
      id: Value(id),
      nome: Value(nome),
      icone:
          icone == null && nullToAbsent ? const Value.absent() : Value(icone),
      ativo: Value(ativo),
    );
  }

  factory OrigensPedidoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrigensPedidoData(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      icone: serializer.fromJson<String?>(json['icone']),
      ativo: serializer.fromJson<bool>(json['ativo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'icone': serializer.toJson<String?>(icone),
      'ativo': serializer.toJson<bool>(ativo),
    };
  }

  OrigensPedidoData copyWith(
          {int? id,
          String? nome,
          Value<String?> icone = const Value.absent(),
          bool? ativo}) =>
      OrigensPedidoData(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        icone: icone.present ? icone.value : this.icone,
        ativo: ativo ?? this.ativo,
      );
  OrigensPedidoData copyWithCompanion(OrigensPedidoCompanion data) {
    return OrigensPedidoData(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      icone: data.icone.present ? data.icone.value : this.icone,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrigensPedidoData(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('icone: $icone, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, icone, ativo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrigensPedidoData &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.icone == this.icone &&
          other.ativo == this.ativo);
}

class OrigensPedidoCompanion extends UpdateCompanion<OrigensPedidoData> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String?> icone;
  final Value<bool> ativo;
  const OrigensPedidoCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.icone = const Value.absent(),
    this.ativo = const Value.absent(),
  });
  OrigensPedidoCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    this.icone = const Value.absent(),
    this.ativo = const Value.absent(),
  }) : nome = Value(nome);
  static Insertable<OrigensPedidoData> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? icone,
    Expression<bool>? ativo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (icone != null) 'icone': icone,
      if (ativo != null) 'ativo': ativo,
    });
  }

  OrigensPedidoCompanion copyWith(
      {Value<int>? id,
      Value<String>? nome,
      Value<String?>? icone,
      Value<bool>? ativo}) {
    return OrigensPedidoCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      icone: icone ?? this.icone,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (icone.present) {
      map['icone'] = Variable<String>(icone.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrigensPedidoCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('icone: $icone, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }
}

class $PrioridadesPedidoTable extends PrioridadesPedido
    with TableInfo<$PrioridadesPedidoTable, PrioridadesPedidoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrioridadesPedidoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _corMeta = const VerificationMeta('cor');
  @override
  late final GeneratedColumn<String> cor = GeneratedColumn<String>(
      'cor', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconeMeta = const VerificationMeta('icone');
  @override
  late final GeneratedColumn<String> icone = GeneratedColumn<String>(
      'icone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ordemMeta = const VerificationMeta('ordem');
  @override
  late final GeneratedColumn<int> ordem = GeneratedColumn<int>(
      'ordem', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, nome, cor, icone, ordem];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prioridades_pedido';
  @override
  VerificationContext validateIntegrity(
      Insertable<PrioridadesPedidoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('cor')) {
      context.handle(
          _corMeta, cor.isAcceptableOrUnknown(data['cor']!, _corMeta));
    } else if (isInserting) {
      context.missing(_corMeta);
    }
    if (data.containsKey('icone')) {
      context.handle(
          _iconeMeta, icone.isAcceptableOrUnknown(data['icone']!, _iconeMeta));
    }
    if (data.containsKey('ordem')) {
      context.handle(
          _ordemMeta, ordem.isAcceptableOrUnknown(data['ordem']!, _ordemMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrioridadesPedidoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrioridadesPedidoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      cor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cor'])!,
      icone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icone']),
      ordem: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordem'])!,
    );
  }

  @override
  $PrioridadesPedidoTable createAlias(String alias) {
    return $PrioridadesPedidoTable(attachedDatabase, alias);
  }
}

class PrioridadesPedidoData extends DataClass
    implements Insertable<PrioridadesPedidoData> {
  final int id;
  final String nome;
  final String cor;
  final String? icone;
  final int ordem;
  const PrioridadesPedidoData(
      {required this.id,
      required this.nome,
      required this.cor,
      this.icone,
      required this.ordem});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['cor'] = Variable<String>(cor);
    if (!nullToAbsent || icone != null) {
      map['icone'] = Variable<String>(icone);
    }
    map['ordem'] = Variable<int>(ordem);
    return map;
  }

  PrioridadesPedidoCompanion toCompanion(bool nullToAbsent) {
    return PrioridadesPedidoCompanion(
      id: Value(id),
      nome: Value(nome),
      cor: Value(cor),
      icone:
          icone == null && nullToAbsent ? const Value.absent() : Value(icone),
      ordem: Value(ordem),
    );
  }

  factory PrioridadesPedidoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrioridadesPedidoData(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      cor: serializer.fromJson<String>(json['cor']),
      icone: serializer.fromJson<String?>(json['icone']),
      ordem: serializer.fromJson<int>(json['ordem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'cor': serializer.toJson<String>(cor),
      'icone': serializer.toJson<String?>(icone),
      'ordem': serializer.toJson<int>(ordem),
    };
  }

  PrioridadesPedidoData copyWith(
          {int? id,
          String? nome,
          String? cor,
          Value<String?> icone = const Value.absent(),
          int? ordem}) =>
      PrioridadesPedidoData(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        cor: cor ?? this.cor,
        icone: icone.present ? icone.value : this.icone,
        ordem: ordem ?? this.ordem,
      );
  PrioridadesPedidoData copyWithCompanion(PrioridadesPedidoCompanion data) {
    return PrioridadesPedidoData(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      cor: data.cor.present ? data.cor.value : this.cor,
      icone: data.icone.present ? data.icone.value : this.icone,
      ordem: data.ordem.present ? data.ordem.value : this.ordem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrioridadesPedidoData(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('cor: $cor, ')
          ..write('icone: $icone, ')
          ..write('ordem: $ordem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, cor, icone, ordem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrioridadesPedidoData &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.cor == this.cor &&
          other.icone == this.icone &&
          other.ordem == this.ordem);
}

class PrioridadesPedidoCompanion
    extends UpdateCompanion<PrioridadesPedidoData> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String> cor;
  final Value<String?> icone;
  final Value<int> ordem;
  const PrioridadesPedidoCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.cor = const Value.absent(),
    this.icone = const Value.absent(),
    this.ordem = const Value.absent(),
  });
  PrioridadesPedidoCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    required String cor,
    this.icone = const Value.absent(),
    this.ordem = const Value.absent(),
  })  : nome = Value(nome),
        cor = Value(cor);
  static Insertable<PrioridadesPedidoData> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? cor,
    Expression<String>? icone,
    Expression<int>? ordem,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (cor != null) 'cor': cor,
      if (icone != null) 'icone': icone,
      if (ordem != null) 'ordem': ordem,
    });
  }

  PrioridadesPedidoCompanion copyWith(
      {Value<int>? id,
      Value<String>? nome,
      Value<String>? cor,
      Value<String?>? icone,
      Value<int>? ordem}) {
    return PrioridadesPedidoCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
      icone: icone ?? this.icone,
      ordem: ordem ?? this.ordem,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (cor.present) {
      map['cor'] = Variable<String>(cor.value);
    }
    if (icone.present) {
      map['icone'] = Variable<String>(icone.value);
    }
    if (ordem.present) {
      map['ordem'] = Variable<int>(ordem.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrioridadesPedidoCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('cor: $cor, ')
          ..write('icone: $icone, ')
          ..write('ordem: $ordem')
          ..write(')'))
        .toString();
  }
}

class $PedidosTable extends Pedidos with TableInfo<$PedidosTable, Pedido> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PedidosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _numeroMeta = const VerificationMeta('numero');
  @override
  late final GeneratedColumn<int> numero = GeneratedColumn<int>(
      'numero', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _clienteIdMeta =
      const VerificationMeta('clienteId');
  @override
  late final GeneratedColumn<int> clienteId = GeneratedColumn<int>(
      'cliente_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES clientes (id)'));
  static const VerificationMeta _clienteNomeMeta =
      const VerificationMeta('clienteNome');
  @override
  late final GeneratedColumn<String> clienteNome = GeneratedColumn<String>(
      'cliente_nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clienteTelefoneMeta =
      const VerificationMeta('clienteTelefone');
  @override
  late final GeneratedColumn<String> clienteTelefone = GeneratedColumn<String>(
      'cliente_telefone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _dataEntregaMeta =
      const VerificationMeta('dataEntrega');
  @override
  late final GeneratedColumn<DateTime> dataEntrega = GeneratedColumn<DateTime>(
      'data_entrega', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _tipoEntregaMeta =
      const VerificationMeta('tipoEntrega');
  @override
  late final GeneratedColumn<String> tipoEntrega = GeneratedColumn<String>(
      'tipo_entrega', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _formaPagamentoMeta =
      const VerificationMeta('formaPagamento');
  @override
  late final GeneratedColumn<String> formaPagamento = GeneratedColumn<String>(
      'forma_pagamento', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _trocoParaCentavosMeta =
      const VerificationMeta('trocoParaCentavos');
  @override
  late final GeneratedColumn<int> trocoParaCentavos = GeneratedColumn<int>(
      'troco_para_centavos', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _observacoesMeta =
      const VerificationMeta('observacoes');
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
      'observacoes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _subtotalCentavosMeta =
      const VerificationMeta('subtotalCentavos');
  @override
  late final GeneratedColumn<int> subtotalCentavos = GeneratedColumn<int>(
      'subtotal_centavos', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _taxaEntregaCentavosMeta =
      const VerificationMeta('taxaEntregaCentavos');
  @override
  late final GeneratedColumn<int> taxaEntregaCentavos = GeneratedColumn<int>(
      'taxa_entrega_centavos', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalCentavosMeta =
      const VerificationMeta('totalCentavos');
  @override
  late final GeneratedColumn<int> totalCentavos = GeneratedColumn<int>(
      'total_centavos', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Pendente'));
  static const VerificationMeta _versaoMeta = const VerificationMeta('versao');
  @override
  late final GeneratedColumn<int> versao = GeneratedColumn<int>(
      'versao', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _prioridadeMeta =
      const VerificationMeta('prioridade');
  @override
  late final GeneratedColumn<String> prioridade = GeneratedColumn<String>(
      'prioridade', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Normal'));
  static const VerificationMeta _pixConfirmadoMeta =
      const VerificationMeta('pixConfirmado');
  @override
  late final GeneratedColumn<bool> pixConfirmado = GeneratedColumn<bool>(
      'pix_confirmado', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pix_confirmado" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pixConfirmadoEmMeta =
      const VerificationMeta('pixConfirmadoEm');
  @override
  late final GeneratedColumn<DateTime> pixConfirmadoEm =
      GeneratedColumn<DateTime>('pix_confirmado_em', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _criadoEmMeta =
      const VerificationMeta('criadoEm');
  @override
  late final GeneratedColumn<DateTime> criadoEm = GeneratedColumn<DateTime>(
      'criado_em', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _comprovantePixMeta =
      const VerificationMeta('comprovantePix');
  @override
  late final GeneratedColumn<String> comprovantePix = GeneratedColumn<String>(
      'comprovante_pix', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _origemIdMeta =
      const VerificationMeta('origemId');
  @override
  late final GeneratedColumn<int> origemId = GeneratedColumn<int>(
      'origem_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES origens_pedido (id)'));
  static const VerificationMeta _prioridadeIdMeta =
      const VerificationMeta('prioridadeId');
  @override
  late final GeneratedColumn<int> prioridadeId = GeneratedColumn<int>(
      'prioridade_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES prioridades_pedido (id)'));
  static const VerificationMeta _dataProducaoMeta =
      const VerificationMeta('dataProducao');
  @override
  late final GeneratedColumn<DateTime> dataProducao = GeneratedColumn<DateTime>(
      'data_producao', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusFinanceiroMeta =
      const VerificationMeta('statusFinanceiro');
  @override
  late final GeneratedColumn<String> statusFinanceiro = GeneratedColumn<String>(
      'status_financeiro', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Pendente'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        numero,
        clienteId,
        clienteNome,
        clienteTelefone,
        dataEntrega,
        tipoEntrega,
        formaPagamento,
        trocoParaCentavos,
        observacoes,
        subtotalCentavos,
        taxaEntregaCentavos,
        totalCentavos,
        status,
        versao,
        prioridade,
        pixConfirmado,
        pixConfirmadoEm,
        criadoEm,
        comprovantePix,
        origemId,
        prioridadeId,
        dataProducao,
        statusFinanceiro
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pedidos';
  @override
  VerificationContext validateIntegrity(Insertable<Pedido> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('numero')) {
      context.handle(_numeroMeta,
          numero.isAcceptableOrUnknown(data['numero']!, _numeroMeta));
    } else if (isInserting) {
      context.missing(_numeroMeta);
    }
    if (data.containsKey('cliente_id')) {
      context.handle(_clienteIdMeta,
          clienteId.isAcceptableOrUnknown(data['cliente_id']!, _clienteIdMeta));
    } else if (isInserting) {
      context.missing(_clienteIdMeta);
    }
    if (data.containsKey('cliente_nome')) {
      context.handle(
          _clienteNomeMeta,
          clienteNome.isAcceptableOrUnknown(
              data['cliente_nome']!, _clienteNomeMeta));
    } else if (isInserting) {
      context.missing(_clienteNomeMeta);
    }
    if (data.containsKey('cliente_telefone')) {
      context.handle(
          _clienteTelefoneMeta,
          clienteTelefone.isAcceptableOrUnknown(
              data['cliente_telefone']!, _clienteTelefoneMeta));
    }
    if (data.containsKey('data_entrega')) {
      context.handle(
          _dataEntregaMeta,
          dataEntrega.isAcceptableOrUnknown(
              data['data_entrega']!, _dataEntregaMeta));
    } else if (isInserting) {
      context.missing(_dataEntregaMeta);
    }
    if (data.containsKey('tipo_entrega')) {
      context.handle(
          _tipoEntregaMeta,
          tipoEntrega.isAcceptableOrUnknown(
              data['tipo_entrega']!, _tipoEntregaMeta));
    } else if (isInserting) {
      context.missing(_tipoEntregaMeta);
    }
    if (data.containsKey('forma_pagamento')) {
      context.handle(
          _formaPagamentoMeta,
          formaPagamento.isAcceptableOrUnknown(
              data['forma_pagamento']!, _formaPagamentoMeta));
    } else if (isInserting) {
      context.missing(_formaPagamentoMeta);
    }
    if (data.containsKey('troco_para_centavos')) {
      context.handle(
          _trocoParaCentavosMeta,
          trocoParaCentavos.isAcceptableOrUnknown(
              data['troco_para_centavos']!, _trocoParaCentavosMeta));
    }
    if (data.containsKey('observacoes')) {
      context.handle(
          _observacoesMeta,
          observacoes.isAcceptableOrUnknown(
              data['observacoes']!, _observacoesMeta));
    }
    if (data.containsKey('subtotal_centavos')) {
      context.handle(
          _subtotalCentavosMeta,
          subtotalCentavos.isAcceptableOrUnknown(
              data['subtotal_centavos']!, _subtotalCentavosMeta));
    } else if (isInserting) {
      context.missing(_subtotalCentavosMeta);
    }
    if (data.containsKey('taxa_entrega_centavos')) {
      context.handle(
          _taxaEntregaCentavosMeta,
          taxaEntregaCentavos.isAcceptableOrUnknown(
              data['taxa_entrega_centavos']!, _taxaEntregaCentavosMeta));
    }
    if (data.containsKey('total_centavos')) {
      context.handle(
          _totalCentavosMeta,
          totalCentavos.isAcceptableOrUnknown(
              data['total_centavos']!, _totalCentavosMeta));
    } else if (isInserting) {
      context.missing(_totalCentavosMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('versao')) {
      context.handle(_versaoMeta,
          versao.isAcceptableOrUnknown(data['versao']!, _versaoMeta));
    }
    if (data.containsKey('prioridade')) {
      context.handle(
          _prioridadeMeta,
          prioridade.isAcceptableOrUnknown(
              data['prioridade']!, _prioridadeMeta));
    }
    if (data.containsKey('pix_confirmado')) {
      context.handle(
          _pixConfirmadoMeta,
          pixConfirmado.isAcceptableOrUnknown(
              data['pix_confirmado']!, _pixConfirmadoMeta));
    }
    if (data.containsKey('pix_confirmado_em')) {
      context.handle(
          _pixConfirmadoEmMeta,
          pixConfirmadoEm.isAcceptableOrUnknown(
              data['pix_confirmado_em']!, _pixConfirmadoEmMeta));
    }
    if (data.containsKey('criado_em')) {
      context.handle(_criadoEmMeta,
          criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta));
    }
    if (data.containsKey('comprovante_pix')) {
      context.handle(
          _comprovantePixMeta,
          comprovantePix.isAcceptableOrUnknown(
              data['comprovante_pix']!, _comprovantePixMeta));
    }
    if (data.containsKey('origem_id')) {
      context.handle(_origemIdMeta,
          origemId.isAcceptableOrUnknown(data['origem_id']!, _origemIdMeta));
    }
    if (data.containsKey('prioridade_id')) {
      context.handle(
          _prioridadeIdMeta,
          prioridadeId.isAcceptableOrUnknown(
              data['prioridade_id']!, _prioridadeIdMeta));
    }
    if (data.containsKey('data_producao')) {
      context.handle(
          _dataProducaoMeta,
          dataProducao.isAcceptableOrUnknown(
              data['data_producao']!, _dataProducaoMeta));
    }
    if (data.containsKey('status_financeiro')) {
      context.handle(
          _statusFinanceiroMeta,
          statusFinanceiro.isAcceptableOrUnknown(
              data['status_financeiro']!, _statusFinanceiroMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pedido map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pedido(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      numero: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}numero'])!,
      clienteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cliente_id'])!,
      clienteNome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cliente_nome'])!,
      clienteTelefone: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cliente_telefone'])!,
      dataEntrega: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}data_entrega'])!,
      tipoEntrega: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo_entrega'])!,
      formaPagamento: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}forma_pagamento'])!,
      trocoParaCentavos: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}troco_para_centavos']),
      observacoes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacoes'])!,
      subtotalCentavos: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subtotal_centavos'])!,
      taxaEntregaCentavos: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}taxa_entrega_centavos'])!,
      totalCentavos: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_centavos'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      versao: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}versao'])!,
      prioridade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prioridade'])!,
      pixConfirmado: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pix_confirmado'])!,
      pixConfirmadoEm: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}pix_confirmado_em']),
      criadoEm: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}criado_em'])!,
      comprovantePix: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}comprovante_pix']),
      origemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}origem_id']),
      prioridadeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}prioridade_id']),
      dataProducao: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}data_producao']),
      statusFinanceiro: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}status_financeiro'])!,
    );
  }

  @override
  $PedidosTable createAlias(String alias) {
    return $PedidosTable(attachedDatabase, alias);
  }
}

class Pedido extends DataClass implements Insertable<Pedido> {
  final int id;
  final int numero;
  final int clienteId;
  final String clienteNome;
  final String clienteTelefone;
  final DateTime dataEntrega;
  final String tipoEntrega;
  final String formaPagamento;
  final int? trocoParaCentavos;
  final String observacoes;
  final int subtotalCentavos;
  final int taxaEntregaCentavos;
  final int totalCentavos;
  final String status;
  final int versao;
  final String prioridade;
  final bool pixConfirmado;
  final DateTime? pixConfirmadoEm;
  final DateTime criadoEm;
  final String? comprovantePix;
  final int? origemId;
  final int? prioridadeId;
  final DateTime? dataProducao;
  final String statusFinanceiro;
  const Pedido(
      {required this.id,
      required this.numero,
      required this.clienteId,
      required this.clienteNome,
      required this.clienteTelefone,
      required this.dataEntrega,
      required this.tipoEntrega,
      required this.formaPagamento,
      this.trocoParaCentavos,
      required this.observacoes,
      required this.subtotalCentavos,
      required this.taxaEntregaCentavos,
      required this.totalCentavos,
      required this.status,
      required this.versao,
      required this.prioridade,
      required this.pixConfirmado,
      this.pixConfirmadoEm,
      required this.criadoEm,
      this.comprovantePix,
      this.origemId,
      this.prioridadeId,
      this.dataProducao,
      required this.statusFinanceiro});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['numero'] = Variable<int>(numero);
    map['cliente_id'] = Variable<int>(clienteId);
    map['cliente_nome'] = Variable<String>(clienteNome);
    map['cliente_telefone'] = Variable<String>(clienteTelefone);
    map['data_entrega'] = Variable<DateTime>(dataEntrega);
    map['tipo_entrega'] = Variable<String>(tipoEntrega);
    map['forma_pagamento'] = Variable<String>(formaPagamento);
    if (!nullToAbsent || trocoParaCentavos != null) {
      map['troco_para_centavos'] = Variable<int>(trocoParaCentavos);
    }
    map['observacoes'] = Variable<String>(observacoes);
    map['subtotal_centavos'] = Variable<int>(subtotalCentavos);
    map['taxa_entrega_centavos'] = Variable<int>(taxaEntregaCentavos);
    map['total_centavos'] = Variable<int>(totalCentavos);
    map['status'] = Variable<String>(status);
    map['versao'] = Variable<int>(versao);
    map['prioridade'] = Variable<String>(prioridade);
    map['pix_confirmado'] = Variable<bool>(pixConfirmado);
    if (!nullToAbsent || pixConfirmadoEm != null) {
      map['pix_confirmado_em'] = Variable<DateTime>(pixConfirmadoEm);
    }
    map['criado_em'] = Variable<DateTime>(criadoEm);
    if (!nullToAbsent || comprovantePix != null) {
      map['comprovante_pix'] = Variable<String>(comprovantePix);
    }
    if (!nullToAbsent || origemId != null) {
      map['origem_id'] = Variable<int>(origemId);
    }
    if (!nullToAbsent || prioridadeId != null) {
      map['prioridade_id'] = Variable<int>(prioridadeId);
    }
    if (!nullToAbsent || dataProducao != null) {
      map['data_producao'] = Variable<DateTime>(dataProducao);
    }
    map['status_financeiro'] = Variable<String>(statusFinanceiro);
    return map;
  }

  PedidosCompanion toCompanion(bool nullToAbsent) {
    return PedidosCompanion(
      id: Value(id),
      numero: Value(numero),
      clienteId: Value(clienteId),
      clienteNome: Value(clienteNome),
      clienteTelefone: Value(clienteTelefone),
      dataEntrega: Value(dataEntrega),
      tipoEntrega: Value(tipoEntrega),
      formaPagamento: Value(formaPagamento),
      trocoParaCentavos: trocoParaCentavos == null && nullToAbsent
          ? const Value.absent()
          : Value(trocoParaCentavos),
      observacoes: Value(observacoes),
      subtotalCentavos: Value(subtotalCentavos),
      taxaEntregaCentavos: Value(taxaEntregaCentavos),
      totalCentavos: Value(totalCentavos),
      status: Value(status),
      versao: Value(versao),
      prioridade: Value(prioridade),
      pixConfirmado: Value(pixConfirmado),
      pixConfirmadoEm: pixConfirmadoEm == null && nullToAbsent
          ? const Value.absent()
          : Value(pixConfirmadoEm),
      criadoEm: Value(criadoEm),
      comprovantePix: comprovantePix == null && nullToAbsent
          ? const Value.absent()
          : Value(comprovantePix),
      origemId: origemId == null && nullToAbsent
          ? const Value.absent()
          : Value(origemId),
      prioridadeId: prioridadeId == null && nullToAbsent
          ? const Value.absent()
          : Value(prioridadeId),
      dataProducao: dataProducao == null && nullToAbsent
          ? const Value.absent()
          : Value(dataProducao),
      statusFinanceiro: Value(statusFinanceiro),
    );
  }

  factory Pedido.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pedido(
      id: serializer.fromJson<int>(json['id']),
      numero: serializer.fromJson<int>(json['numero']),
      clienteId: serializer.fromJson<int>(json['clienteId']),
      clienteNome: serializer.fromJson<String>(json['clienteNome']),
      clienteTelefone: serializer.fromJson<String>(json['clienteTelefone']),
      dataEntrega: serializer.fromJson<DateTime>(json['dataEntrega']),
      tipoEntrega: serializer.fromJson<String>(json['tipoEntrega']),
      formaPagamento: serializer.fromJson<String>(json['formaPagamento']),
      trocoParaCentavos: serializer.fromJson<int?>(json['trocoParaCentavos']),
      observacoes: serializer.fromJson<String>(json['observacoes']),
      subtotalCentavos: serializer.fromJson<int>(json['subtotalCentavos']),
      taxaEntregaCentavos:
          serializer.fromJson<int>(json['taxaEntregaCentavos']),
      totalCentavos: serializer.fromJson<int>(json['totalCentavos']),
      status: serializer.fromJson<String>(json['status']),
      versao: serializer.fromJson<int>(json['versao']),
      prioridade: serializer.fromJson<String>(json['prioridade']),
      pixConfirmado: serializer.fromJson<bool>(json['pixConfirmado']),
      pixConfirmadoEm: serializer.fromJson<DateTime?>(json['pixConfirmadoEm']),
      criadoEm: serializer.fromJson<DateTime>(json['criadoEm']),
      comprovantePix: serializer.fromJson<String?>(json['comprovantePix']),
      origemId: serializer.fromJson<int?>(json['origemId']),
      prioridadeId: serializer.fromJson<int?>(json['prioridadeId']),
      dataProducao: serializer.fromJson<DateTime?>(json['dataProducao']),
      statusFinanceiro: serializer.fromJson<String>(json['statusFinanceiro']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'numero': serializer.toJson<int>(numero),
      'clienteId': serializer.toJson<int>(clienteId),
      'clienteNome': serializer.toJson<String>(clienteNome),
      'clienteTelefone': serializer.toJson<String>(clienteTelefone),
      'dataEntrega': serializer.toJson<DateTime>(dataEntrega),
      'tipoEntrega': serializer.toJson<String>(tipoEntrega),
      'formaPagamento': serializer.toJson<String>(formaPagamento),
      'trocoParaCentavos': serializer.toJson<int?>(trocoParaCentavos),
      'observacoes': serializer.toJson<String>(observacoes),
      'subtotalCentavos': serializer.toJson<int>(subtotalCentavos),
      'taxaEntregaCentavos': serializer.toJson<int>(taxaEntregaCentavos),
      'totalCentavos': serializer.toJson<int>(totalCentavos),
      'status': serializer.toJson<String>(status),
      'versao': serializer.toJson<int>(versao),
      'prioridade': serializer.toJson<String>(prioridade),
      'pixConfirmado': serializer.toJson<bool>(pixConfirmado),
      'pixConfirmadoEm': serializer.toJson<DateTime?>(pixConfirmadoEm),
      'criadoEm': serializer.toJson<DateTime>(criadoEm),
      'comprovantePix': serializer.toJson<String?>(comprovantePix),
      'origemId': serializer.toJson<int?>(origemId),
      'prioridadeId': serializer.toJson<int?>(prioridadeId),
      'dataProducao': serializer.toJson<DateTime?>(dataProducao),
      'statusFinanceiro': serializer.toJson<String>(statusFinanceiro),
    };
  }

  Pedido copyWith(
          {int? id,
          int? numero,
          int? clienteId,
          String? clienteNome,
          String? clienteTelefone,
          DateTime? dataEntrega,
          String? tipoEntrega,
          String? formaPagamento,
          Value<int?> trocoParaCentavos = const Value.absent(),
          String? observacoes,
          int? subtotalCentavos,
          int? taxaEntregaCentavos,
          int? totalCentavos,
          String? status,
          int? versao,
          String? prioridade,
          bool? pixConfirmado,
          Value<DateTime?> pixConfirmadoEm = const Value.absent(),
          DateTime? criadoEm,
          Value<String?> comprovantePix = const Value.absent(),
          Value<int?> origemId = const Value.absent(),
          Value<int?> prioridadeId = const Value.absent(),
          Value<DateTime?> dataProducao = const Value.absent(),
          String? statusFinanceiro}) =>
      Pedido(
        id: id ?? this.id,
        numero: numero ?? this.numero,
        clienteId: clienteId ?? this.clienteId,
        clienteNome: clienteNome ?? this.clienteNome,
        clienteTelefone: clienteTelefone ?? this.clienteTelefone,
        dataEntrega: dataEntrega ?? this.dataEntrega,
        tipoEntrega: tipoEntrega ?? this.tipoEntrega,
        formaPagamento: formaPagamento ?? this.formaPagamento,
        trocoParaCentavos: trocoParaCentavos.present
            ? trocoParaCentavos.value
            : this.trocoParaCentavos,
        observacoes: observacoes ?? this.observacoes,
        subtotalCentavos: subtotalCentavos ?? this.subtotalCentavos,
        taxaEntregaCentavos: taxaEntregaCentavos ?? this.taxaEntregaCentavos,
        totalCentavos: totalCentavos ?? this.totalCentavos,
        status: status ?? this.status,
        versao: versao ?? this.versao,
        prioridade: prioridade ?? this.prioridade,
        pixConfirmado: pixConfirmado ?? this.pixConfirmado,
        pixConfirmadoEm: pixConfirmadoEm.present
            ? pixConfirmadoEm.value
            : this.pixConfirmadoEm,
        criadoEm: criadoEm ?? this.criadoEm,
        comprovantePix:
            comprovantePix.present ? comprovantePix.value : this.comprovantePix,
        origemId: origemId.present ? origemId.value : this.origemId,
        prioridadeId:
            prioridadeId.present ? prioridadeId.value : this.prioridadeId,
        dataProducao:
            dataProducao.present ? dataProducao.value : this.dataProducao,
        statusFinanceiro: statusFinanceiro ?? this.statusFinanceiro,
      );
  Pedido copyWithCompanion(PedidosCompanion data) {
    return Pedido(
      id: data.id.present ? data.id.value : this.id,
      numero: data.numero.present ? data.numero.value : this.numero,
      clienteId: data.clienteId.present ? data.clienteId.value : this.clienteId,
      clienteNome:
          data.clienteNome.present ? data.clienteNome.value : this.clienteNome,
      clienteTelefone: data.clienteTelefone.present
          ? data.clienteTelefone.value
          : this.clienteTelefone,
      dataEntrega:
          data.dataEntrega.present ? data.dataEntrega.value : this.dataEntrega,
      tipoEntrega:
          data.tipoEntrega.present ? data.tipoEntrega.value : this.tipoEntrega,
      formaPagamento: data.formaPagamento.present
          ? data.formaPagamento.value
          : this.formaPagamento,
      trocoParaCentavos: data.trocoParaCentavos.present
          ? data.trocoParaCentavos.value
          : this.trocoParaCentavos,
      observacoes:
          data.observacoes.present ? data.observacoes.value : this.observacoes,
      subtotalCentavos: data.subtotalCentavos.present
          ? data.subtotalCentavos.value
          : this.subtotalCentavos,
      taxaEntregaCentavos: data.taxaEntregaCentavos.present
          ? data.taxaEntregaCentavos.value
          : this.taxaEntregaCentavos,
      totalCentavos: data.totalCentavos.present
          ? data.totalCentavos.value
          : this.totalCentavos,
      status: data.status.present ? data.status.value : this.status,
      versao: data.versao.present ? data.versao.value : this.versao,
      prioridade:
          data.prioridade.present ? data.prioridade.value : this.prioridade,
      pixConfirmado: data.pixConfirmado.present
          ? data.pixConfirmado.value
          : this.pixConfirmado,
      pixConfirmadoEm: data.pixConfirmadoEm.present
          ? data.pixConfirmadoEm.value
          : this.pixConfirmadoEm,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
      comprovantePix: data.comprovantePix.present
          ? data.comprovantePix.value
          : this.comprovantePix,
      origemId: data.origemId.present ? data.origemId.value : this.origemId,
      prioridadeId: data.prioridadeId.present
          ? data.prioridadeId.value
          : this.prioridadeId,
      dataProducao: data.dataProducao.present
          ? data.dataProducao.value
          : this.dataProducao,
      statusFinanceiro: data.statusFinanceiro.present
          ? data.statusFinanceiro.value
          : this.statusFinanceiro,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pedido(')
          ..write('id: $id, ')
          ..write('numero: $numero, ')
          ..write('clienteId: $clienteId, ')
          ..write('clienteNome: $clienteNome, ')
          ..write('clienteTelefone: $clienteTelefone, ')
          ..write('dataEntrega: $dataEntrega, ')
          ..write('tipoEntrega: $tipoEntrega, ')
          ..write('formaPagamento: $formaPagamento, ')
          ..write('trocoParaCentavos: $trocoParaCentavos, ')
          ..write('observacoes: $observacoes, ')
          ..write('subtotalCentavos: $subtotalCentavos, ')
          ..write('taxaEntregaCentavos: $taxaEntregaCentavos, ')
          ..write('totalCentavos: $totalCentavos, ')
          ..write('status: $status, ')
          ..write('versao: $versao, ')
          ..write('prioridade: $prioridade, ')
          ..write('pixConfirmado: $pixConfirmado, ')
          ..write('pixConfirmadoEm: $pixConfirmadoEm, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('comprovantePix: $comprovantePix, ')
          ..write('origemId: $origemId, ')
          ..write('prioridadeId: $prioridadeId, ')
          ..write('dataProducao: $dataProducao, ')
          ..write('statusFinanceiro: $statusFinanceiro')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        numero,
        clienteId,
        clienteNome,
        clienteTelefone,
        dataEntrega,
        tipoEntrega,
        formaPagamento,
        trocoParaCentavos,
        observacoes,
        subtotalCentavos,
        taxaEntregaCentavos,
        totalCentavos,
        status,
        versao,
        prioridade,
        pixConfirmado,
        pixConfirmadoEm,
        criadoEm,
        comprovantePix,
        origemId,
        prioridadeId,
        dataProducao,
        statusFinanceiro
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pedido &&
          other.id == this.id &&
          other.numero == this.numero &&
          other.clienteId == this.clienteId &&
          other.clienteNome == this.clienteNome &&
          other.clienteTelefone == this.clienteTelefone &&
          other.dataEntrega == this.dataEntrega &&
          other.tipoEntrega == this.tipoEntrega &&
          other.formaPagamento == this.formaPagamento &&
          other.trocoParaCentavos == this.trocoParaCentavos &&
          other.observacoes == this.observacoes &&
          other.subtotalCentavos == this.subtotalCentavos &&
          other.taxaEntregaCentavos == this.taxaEntregaCentavos &&
          other.totalCentavos == this.totalCentavos &&
          other.status == this.status &&
          other.versao == this.versao &&
          other.prioridade == this.prioridade &&
          other.pixConfirmado == this.pixConfirmado &&
          other.pixConfirmadoEm == this.pixConfirmadoEm &&
          other.criadoEm == this.criadoEm &&
          other.comprovantePix == this.comprovantePix &&
          other.origemId == this.origemId &&
          other.prioridadeId == this.prioridadeId &&
          other.dataProducao == this.dataProducao &&
          other.statusFinanceiro == this.statusFinanceiro);
}

class PedidosCompanion extends UpdateCompanion<Pedido> {
  final Value<int> id;
  final Value<int> numero;
  final Value<int> clienteId;
  final Value<String> clienteNome;
  final Value<String> clienteTelefone;
  final Value<DateTime> dataEntrega;
  final Value<String> tipoEntrega;
  final Value<String> formaPagamento;
  final Value<int?> trocoParaCentavos;
  final Value<String> observacoes;
  final Value<int> subtotalCentavos;
  final Value<int> taxaEntregaCentavos;
  final Value<int> totalCentavos;
  final Value<String> status;
  final Value<int> versao;
  final Value<String> prioridade;
  final Value<bool> pixConfirmado;
  final Value<DateTime?> pixConfirmadoEm;
  final Value<DateTime> criadoEm;
  final Value<String?> comprovantePix;
  final Value<int?> origemId;
  final Value<int?> prioridadeId;
  final Value<DateTime?> dataProducao;
  final Value<String> statusFinanceiro;
  const PedidosCompanion({
    this.id = const Value.absent(),
    this.numero = const Value.absent(),
    this.clienteId = const Value.absent(),
    this.clienteNome = const Value.absent(),
    this.clienteTelefone = const Value.absent(),
    this.dataEntrega = const Value.absent(),
    this.tipoEntrega = const Value.absent(),
    this.formaPagamento = const Value.absent(),
    this.trocoParaCentavos = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.subtotalCentavos = const Value.absent(),
    this.taxaEntregaCentavos = const Value.absent(),
    this.totalCentavos = const Value.absent(),
    this.status = const Value.absent(),
    this.versao = const Value.absent(),
    this.prioridade = const Value.absent(),
    this.pixConfirmado = const Value.absent(),
    this.pixConfirmadoEm = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.comprovantePix = const Value.absent(),
    this.origemId = const Value.absent(),
    this.prioridadeId = const Value.absent(),
    this.dataProducao = const Value.absent(),
    this.statusFinanceiro = const Value.absent(),
  });
  PedidosCompanion.insert({
    this.id = const Value.absent(),
    required int numero,
    required int clienteId,
    required String clienteNome,
    this.clienteTelefone = const Value.absent(),
    required DateTime dataEntrega,
    required String tipoEntrega,
    required String formaPagamento,
    this.trocoParaCentavos = const Value.absent(),
    this.observacoes = const Value.absent(),
    required int subtotalCentavos,
    this.taxaEntregaCentavos = const Value.absent(),
    required int totalCentavos,
    this.status = const Value.absent(),
    this.versao = const Value.absent(),
    this.prioridade = const Value.absent(),
    this.pixConfirmado = const Value.absent(),
    this.pixConfirmadoEm = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.comprovantePix = const Value.absent(),
    this.origemId = const Value.absent(),
    this.prioridadeId = const Value.absent(),
    this.dataProducao = const Value.absent(),
    this.statusFinanceiro = const Value.absent(),
  })  : numero = Value(numero),
        clienteId = Value(clienteId),
        clienteNome = Value(clienteNome),
        dataEntrega = Value(dataEntrega),
        tipoEntrega = Value(tipoEntrega),
        formaPagamento = Value(formaPagamento),
        subtotalCentavos = Value(subtotalCentavos),
        totalCentavos = Value(totalCentavos);
  static Insertable<Pedido> custom({
    Expression<int>? id,
    Expression<int>? numero,
    Expression<int>? clienteId,
    Expression<String>? clienteNome,
    Expression<String>? clienteTelefone,
    Expression<DateTime>? dataEntrega,
    Expression<String>? tipoEntrega,
    Expression<String>? formaPagamento,
    Expression<int>? trocoParaCentavos,
    Expression<String>? observacoes,
    Expression<int>? subtotalCentavos,
    Expression<int>? taxaEntregaCentavos,
    Expression<int>? totalCentavos,
    Expression<String>? status,
    Expression<int>? versao,
    Expression<String>? prioridade,
    Expression<bool>? pixConfirmado,
    Expression<DateTime>? pixConfirmadoEm,
    Expression<DateTime>? criadoEm,
    Expression<String>? comprovantePix,
    Expression<int>? origemId,
    Expression<int>? prioridadeId,
    Expression<DateTime>? dataProducao,
    Expression<String>? statusFinanceiro,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (numero != null) 'numero': numero,
      if (clienteId != null) 'cliente_id': clienteId,
      if (clienteNome != null) 'cliente_nome': clienteNome,
      if (clienteTelefone != null) 'cliente_telefone': clienteTelefone,
      if (dataEntrega != null) 'data_entrega': dataEntrega,
      if (tipoEntrega != null) 'tipo_entrega': tipoEntrega,
      if (formaPagamento != null) 'forma_pagamento': formaPagamento,
      if (trocoParaCentavos != null) 'troco_para_centavos': trocoParaCentavos,
      if (observacoes != null) 'observacoes': observacoes,
      if (subtotalCentavos != null) 'subtotal_centavos': subtotalCentavos,
      if (taxaEntregaCentavos != null)
        'taxa_entrega_centavos': taxaEntregaCentavos,
      if (totalCentavos != null) 'total_centavos': totalCentavos,
      if (status != null) 'status': status,
      if (versao != null) 'versao': versao,
      if (prioridade != null) 'prioridade': prioridade,
      if (pixConfirmado != null) 'pix_confirmado': pixConfirmado,
      if (pixConfirmadoEm != null) 'pix_confirmado_em': pixConfirmadoEm,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (comprovantePix != null) 'comprovante_pix': comprovantePix,
      if (origemId != null) 'origem_id': origemId,
      if (prioridadeId != null) 'prioridade_id': prioridadeId,
      if (dataProducao != null) 'data_producao': dataProducao,
      if (statusFinanceiro != null) 'status_financeiro': statusFinanceiro,
    });
  }

  PedidosCompanion copyWith(
      {Value<int>? id,
      Value<int>? numero,
      Value<int>? clienteId,
      Value<String>? clienteNome,
      Value<String>? clienteTelefone,
      Value<DateTime>? dataEntrega,
      Value<String>? tipoEntrega,
      Value<String>? formaPagamento,
      Value<int?>? trocoParaCentavos,
      Value<String>? observacoes,
      Value<int>? subtotalCentavos,
      Value<int>? taxaEntregaCentavos,
      Value<int>? totalCentavos,
      Value<String>? status,
      Value<int>? versao,
      Value<String>? prioridade,
      Value<bool>? pixConfirmado,
      Value<DateTime?>? pixConfirmadoEm,
      Value<DateTime>? criadoEm,
      Value<String?>? comprovantePix,
      Value<int?>? origemId,
      Value<int?>? prioridadeId,
      Value<DateTime?>? dataProducao,
      Value<String>? statusFinanceiro}) {
    return PedidosCompanion(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteTelefone: clienteTelefone ?? this.clienteTelefone,
      dataEntrega: dataEntrega ?? this.dataEntrega,
      tipoEntrega: tipoEntrega ?? this.tipoEntrega,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      trocoParaCentavos: trocoParaCentavos ?? this.trocoParaCentavos,
      observacoes: observacoes ?? this.observacoes,
      subtotalCentavos: subtotalCentavos ?? this.subtotalCentavos,
      taxaEntregaCentavos: taxaEntregaCentavos ?? this.taxaEntregaCentavos,
      totalCentavos: totalCentavos ?? this.totalCentavos,
      status: status ?? this.status,
      versao: versao ?? this.versao,
      prioridade: prioridade ?? this.prioridade,
      pixConfirmado: pixConfirmado ?? this.pixConfirmado,
      pixConfirmadoEm: pixConfirmadoEm ?? this.pixConfirmadoEm,
      criadoEm: criadoEm ?? this.criadoEm,
      comprovantePix: comprovantePix ?? this.comprovantePix,
      origemId: origemId ?? this.origemId,
      prioridadeId: prioridadeId ?? this.prioridadeId,
      dataProducao: dataProducao ?? this.dataProducao,
      statusFinanceiro: statusFinanceiro ?? this.statusFinanceiro,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (numero.present) {
      map['numero'] = Variable<int>(numero.value);
    }
    if (clienteId.present) {
      map['cliente_id'] = Variable<int>(clienteId.value);
    }
    if (clienteNome.present) {
      map['cliente_nome'] = Variable<String>(clienteNome.value);
    }
    if (clienteTelefone.present) {
      map['cliente_telefone'] = Variable<String>(clienteTelefone.value);
    }
    if (dataEntrega.present) {
      map['data_entrega'] = Variable<DateTime>(dataEntrega.value);
    }
    if (tipoEntrega.present) {
      map['tipo_entrega'] = Variable<String>(tipoEntrega.value);
    }
    if (formaPagamento.present) {
      map['forma_pagamento'] = Variable<String>(formaPagamento.value);
    }
    if (trocoParaCentavos.present) {
      map['troco_para_centavos'] = Variable<int>(trocoParaCentavos.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    if (subtotalCentavos.present) {
      map['subtotal_centavos'] = Variable<int>(subtotalCentavos.value);
    }
    if (taxaEntregaCentavos.present) {
      map['taxa_entrega_centavos'] = Variable<int>(taxaEntregaCentavos.value);
    }
    if (totalCentavos.present) {
      map['total_centavos'] = Variable<int>(totalCentavos.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (versao.present) {
      map['versao'] = Variable<int>(versao.value);
    }
    if (prioridade.present) {
      map['prioridade'] = Variable<String>(prioridade.value);
    }
    if (pixConfirmado.present) {
      map['pix_confirmado'] = Variable<bool>(pixConfirmado.value);
    }
    if (pixConfirmadoEm.present) {
      map['pix_confirmado_em'] = Variable<DateTime>(pixConfirmadoEm.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<DateTime>(criadoEm.value);
    }
    if (comprovantePix.present) {
      map['comprovante_pix'] = Variable<String>(comprovantePix.value);
    }
    if (origemId.present) {
      map['origem_id'] = Variable<int>(origemId.value);
    }
    if (prioridadeId.present) {
      map['prioridade_id'] = Variable<int>(prioridadeId.value);
    }
    if (dataProducao.present) {
      map['data_producao'] = Variable<DateTime>(dataProducao.value);
    }
    if (statusFinanceiro.present) {
      map['status_financeiro'] = Variable<String>(statusFinanceiro.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PedidosCompanion(')
          ..write('id: $id, ')
          ..write('numero: $numero, ')
          ..write('clienteId: $clienteId, ')
          ..write('clienteNome: $clienteNome, ')
          ..write('clienteTelefone: $clienteTelefone, ')
          ..write('dataEntrega: $dataEntrega, ')
          ..write('tipoEntrega: $tipoEntrega, ')
          ..write('formaPagamento: $formaPagamento, ')
          ..write('trocoParaCentavos: $trocoParaCentavos, ')
          ..write('observacoes: $observacoes, ')
          ..write('subtotalCentavos: $subtotalCentavos, ')
          ..write('taxaEntregaCentavos: $taxaEntregaCentavos, ')
          ..write('totalCentavos: $totalCentavos, ')
          ..write('status: $status, ')
          ..write('versao: $versao, ')
          ..write('prioridade: $prioridade, ')
          ..write('pixConfirmado: $pixConfirmado, ')
          ..write('pixConfirmadoEm: $pixConfirmadoEm, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('comprovantePix: $comprovantePix, ')
          ..write('origemId: $origemId, ')
          ..write('prioridadeId: $prioridadeId, ')
          ..write('dataProducao: $dataProducao, ')
          ..write('statusFinanceiro: $statusFinanceiro')
          ..write(')'))
        .toString();
  }
}

class $ItensPedidoTable extends ItensPedido
    with TableInfo<$ItensPedidoTable, ItensPedidoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItensPedidoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pedidoIdMeta =
      const VerificationMeta('pedidoId');
  @override
  late final GeneratedColumn<int> pedidoId = GeneratedColumn<int>(
      'pedido_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pedidos (id) ON DELETE CASCADE'));
  static const VerificationMeta _produtoIdMeta =
      const VerificationMeta('produtoId');
  @override
  late final GeneratedColumn<int> produtoId = GeneratedColumn<int>(
      'produto_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES produtos (id)'));
  static const VerificationMeta _produtoNomeMeta =
      const VerificationMeta('produtoNome');
  @override
  late final GeneratedColumn<String> produtoNome = GeneratedColumn<String>(
      'produto_nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantidadeMeta =
      const VerificationMeta('quantidade');
  @override
  late final GeneratedColumn<int> quantidade = GeneratedColumn<int>(
      'quantidade', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _valorUnitarioCentavosMeta =
      const VerificationMeta('valorUnitarioCentavos');
  @override
  late final GeneratedColumn<int> valorUnitarioCentavos = GeneratedColumn<int>(
      'valor_unitario_centavos', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _valorTotalCentavosMeta =
      const VerificationMeta('valorTotalCentavos');
  @override
  late final GeneratedColumn<int> valorTotalCentavos = GeneratedColumn<int>(
      'valor_total_centavos', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pedidoId,
        produtoId,
        produtoNome,
        quantidade,
        valorUnitarioCentavos,
        valorTotalCentavos
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'itens_pedido';
  @override
  VerificationContext validateIntegrity(Insertable<ItensPedidoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pedido_id')) {
      context.handle(_pedidoIdMeta,
          pedidoId.isAcceptableOrUnknown(data['pedido_id']!, _pedidoIdMeta));
    } else if (isInserting) {
      context.missing(_pedidoIdMeta);
    }
    if (data.containsKey('produto_id')) {
      context.handle(_produtoIdMeta,
          produtoId.isAcceptableOrUnknown(data['produto_id']!, _produtoIdMeta));
    } else if (isInserting) {
      context.missing(_produtoIdMeta);
    }
    if (data.containsKey('produto_nome')) {
      context.handle(
          _produtoNomeMeta,
          produtoNome.isAcceptableOrUnknown(
              data['produto_nome']!, _produtoNomeMeta));
    } else if (isInserting) {
      context.missing(_produtoNomeMeta);
    }
    if (data.containsKey('quantidade')) {
      context.handle(
          _quantidadeMeta,
          quantidade.isAcceptableOrUnknown(
              data['quantidade']!, _quantidadeMeta));
    } else if (isInserting) {
      context.missing(_quantidadeMeta);
    }
    if (data.containsKey('valor_unitario_centavos')) {
      context.handle(
          _valorUnitarioCentavosMeta,
          valorUnitarioCentavos.isAcceptableOrUnknown(
              data['valor_unitario_centavos']!, _valorUnitarioCentavosMeta));
    } else if (isInserting) {
      context.missing(_valorUnitarioCentavosMeta);
    }
    if (data.containsKey('valor_total_centavos')) {
      context.handle(
          _valorTotalCentavosMeta,
          valorTotalCentavos.isAcceptableOrUnknown(
              data['valor_total_centavos']!, _valorTotalCentavosMeta));
    } else if (isInserting) {
      context.missing(_valorTotalCentavosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItensPedidoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItensPedidoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pedidoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pedido_id'])!,
      produtoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}produto_id'])!,
      produtoNome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}produto_nome'])!,
      quantidade: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantidade'])!,
      valorUnitarioCentavos: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}valor_unitario_centavos'])!,
      valorTotalCentavos: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}valor_total_centavos'])!,
    );
  }

  @override
  $ItensPedidoTable createAlias(String alias) {
    return $ItensPedidoTable(attachedDatabase, alias);
  }
}

class ItensPedidoData extends DataClass implements Insertable<ItensPedidoData> {
  final int id;
  final int pedidoId;
  final int produtoId;
  final String produtoNome;
  final int quantidade;
  final int valorUnitarioCentavos;
  final int valorTotalCentavos;
  const ItensPedidoData(
      {required this.id,
      required this.pedidoId,
      required this.produtoId,
      required this.produtoNome,
      required this.quantidade,
      required this.valorUnitarioCentavos,
      required this.valorTotalCentavos});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pedido_id'] = Variable<int>(pedidoId);
    map['produto_id'] = Variable<int>(produtoId);
    map['produto_nome'] = Variable<String>(produtoNome);
    map['quantidade'] = Variable<int>(quantidade);
    map['valor_unitario_centavos'] = Variable<int>(valorUnitarioCentavos);
    map['valor_total_centavos'] = Variable<int>(valorTotalCentavos);
    return map;
  }

  ItensPedidoCompanion toCompanion(bool nullToAbsent) {
    return ItensPedidoCompanion(
      id: Value(id),
      pedidoId: Value(pedidoId),
      produtoId: Value(produtoId),
      produtoNome: Value(produtoNome),
      quantidade: Value(quantidade),
      valorUnitarioCentavos: Value(valorUnitarioCentavos),
      valorTotalCentavos: Value(valorTotalCentavos),
    );
  }

  factory ItensPedidoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItensPedidoData(
      id: serializer.fromJson<int>(json['id']),
      pedidoId: serializer.fromJson<int>(json['pedidoId']),
      produtoId: serializer.fromJson<int>(json['produtoId']),
      produtoNome: serializer.fromJson<String>(json['produtoNome']),
      quantidade: serializer.fromJson<int>(json['quantidade']),
      valorUnitarioCentavos:
          serializer.fromJson<int>(json['valorUnitarioCentavos']),
      valorTotalCentavos: serializer.fromJson<int>(json['valorTotalCentavos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pedidoId': serializer.toJson<int>(pedidoId),
      'produtoId': serializer.toJson<int>(produtoId),
      'produtoNome': serializer.toJson<String>(produtoNome),
      'quantidade': serializer.toJson<int>(quantidade),
      'valorUnitarioCentavos': serializer.toJson<int>(valorUnitarioCentavos),
      'valorTotalCentavos': serializer.toJson<int>(valorTotalCentavos),
    };
  }

  ItensPedidoData copyWith(
          {int? id,
          int? pedidoId,
          int? produtoId,
          String? produtoNome,
          int? quantidade,
          int? valorUnitarioCentavos,
          int? valorTotalCentavos}) =>
      ItensPedidoData(
        id: id ?? this.id,
        pedidoId: pedidoId ?? this.pedidoId,
        produtoId: produtoId ?? this.produtoId,
        produtoNome: produtoNome ?? this.produtoNome,
        quantidade: quantidade ?? this.quantidade,
        valorUnitarioCentavos:
            valorUnitarioCentavos ?? this.valorUnitarioCentavos,
        valorTotalCentavos: valorTotalCentavos ?? this.valorTotalCentavos,
      );
  ItensPedidoData copyWithCompanion(ItensPedidoCompanion data) {
    return ItensPedidoData(
      id: data.id.present ? data.id.value : this.id,
      pedidoId: data.pedidoId.present ? data.pedidoId.value : this.pedidoId,
      produtoId: data.produtoId.present ? data.produtoId.value : this.produtoId,
      produtoNome:
          data.produtoNome.present ? data.produtoNome.value : this.produtoNome,
      quantidade:
          data.quantidade.present ? data.quantidade.value : this.quantidade,
      valorUnitarioCentavos: data.valorUnitarioCentavos.present
          ? data.valorUnitarioCentavos.value
          : this.valorUnitarioCentavos,
      valorTotalCentavos: data.valorTotalCentavos.present
          ? data.valorTotalCentavos.value
          : this.valorTotalCentavos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItensPedidoData(')
          ..write('id: $id, ')
          ..write('pedidoId: $pedidoId, ')
          ..write('produtoId: $produtoId, ')
          ..write('produtoNome: $produtoNome, ')
          ..write('quantidade: $quantidade, ')
          ..write('valorUnitarioCentavos: $valorUnitarioCentavos, ')
          ..write('valorTotalCentavos: $valorTotalCentavos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pedidoId, produtoId, produtoNome,
      quantidade, valorUnitarioCentavos, valorTotalCentavos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItensPedidoData &&
          other.id == this.id &&
          other.pedidoId == this.pedidoId &&
          other.produtoId == this.produtoId &&
          other.produtoNome == this.produtoNome &&
          other.quantidade == this.quantidade &&
          other.valorUnitarioCentavos == this.valorUnitarioCentavos &&
          other.valorTotalCentavos == this.valorTotalCentavos);
}

class ItensPedidoCompanion extends UpdateCompanion<ItensPedidoData> {
  final Value<int> id;
  final Value<int> pedidoId;
  final Value<int> produtoId;
  final Value<String> produtoNome;
  final Value<int> quantidade;
  final Value<int> valorUnitarioCentavos;
  final Value<int> valorTotalCentavos;
  const ItensPedidoCompanion({
    this.id = const Value.absent(),
    this.pedidoId = const Value.absent(),
    this.produtoId = const Value.absent(),
    this.produtoNome = const Value.absent(),
    this.quantidade = const Value.absent(),
    this.valorUnitarioCentavos = const Value.absent(),
    this.valorTotalCentavos = const Value.absent(),
  });
  ItensPedidoCompanion.insert({
    this.id = const Value.absent(),
    required int pedidoId,
    required int produtoId,
    required String produtoNome,
    required int quantidade,
    required int valorUnitarioCentavos,
    required int valorTotalCentavos,
  })  : pedidoId = Value(pedidoId),
        produtoId = Value(produtoId),
        produtoNome = Value(produtoNome),
        quantidade = Value(quantidade),
        valorUnitarioCentavos = Value(valorUnitarioCentavos),
        valorTotalCentavos = Value(valorTotalCentavos);
  static Insertable<ItensPedidoData> custom({
    Expression<int>? id,
    Expression<int>? pedidoId,
    Expression<int>? produtoId,
    Expression<String>? produtoNome,
    Expression<int>? quantidade,
    Expression<int>? valorUnitarioCentavos,
    Expression<int>? valorTotalCentavos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pedidoId != null) 'pedido_id': pedidoId,
      if (produtoId != null) 'produto_id': produtoId,
      if (produtoNome != null) 'produto_nome': produtoNome,
      if (quantidade != null) 'quantidade': quantidade,
      if (valorUnitarioCentavos != null)
        'valor_unitario_centavos': valorUnitarioCentavos,
      if (valorTotalCentavos != null)
        'valor_total_centavos': valorTotalCentavos,
    });
  }

  ItensPedidoCompanion copyWith(
      {Value<int>? id,
      Value<int>? pedidoId,
      Value<int>? produtoId,
      Value<String>? produtoNome,
      Value<int>? quantidade,
      Value<int>? valorUnitarioCentavos,
      Value<int>? valorTotalCentavos}) {
    return ItensPedidoCompanion(
      id: id ?? this.id,
      pedidoId: pedidoId ?? this.pedidoId,
      produtoId: produtoId ?? this.produtoId,
      produtoNome: produtoNome ?? this.produtoNome,
      quantidade: quantidade ?? this.quantidade,
      valorUnitarioCentavos:
          valorUnitarioCentavos ?? this.valorUnitarioCentavos,
      valorTotalCentavos: valorTotalCentavos ?? this.valorTotalCentavos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pedidoId.present) {
      map['pedido_id'] = Variable<int>(pedidoId.value);
    }
    if (produtoId.present) {
      map['produto_id'] = Variable<int>(produtoId.value);
    }
    if (produtoNome.present) {
      map['produto_nome'] = Variable<String>(produtoNome.value);
    }
    if (quantidade.present) {
      map['quantidade'] = Variable<int>(quantidade.value);
    }
    if (valorUnitarioCentavos.present) {
      map['valor_unitario_centavos'] =
          Variable<int>(valorUnitarioCentavos.value);
    }
    if (valorTotalCentavos.present) {
      map['valor_total_centavos'] = Variable<int>(valorTotalCentavos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItensPedidoCompanion(')
          ..write('id: $id, ')
          ..write('pedidoId: $pedidoId, ')
          ..write('produtoId: $produtoId, ')
          ..write('produtoNome: $produtoNome, ')
          ..write('quantidade: $quantidade, ')
          ..write('valorUnitarioCentavos: $valorUnitarioCentavos, ')
          ..write('valorTotalCentavos: $valorTotalCentavos')
          ..write(')'))
        .toString();
  }
}

class $EstoqueAtualTable extends EstoqueAtual
    with TableInfo<$EstoqueAtualTable, EstoqueAtualData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EstoqueAtualTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _produtoIdMeta =
      const VerificationMeta('produtoId');
  @override
  late final GeneratedColumn<int> produtoId = GeneratedColumn<int>(
      'produto_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES produtos (id) ON DELETE CASCADE'));
  static const VerificationMeta _saldoAtualMeta =
      const VerificationMeta('saldoAtual');
  @override
  late final GeneratedColumn<int> saldoAtual = GeneratedColumn<int>(
      'saldo_atual', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reservadoMeta =
      const VerificationMeta('reservado');
  @override
  late final GeneratedColumn<int> reservado = GeneratedColumn<int>(
      'reservado', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reservadoComercialMeta =
      const VerificationMeta('reservadoComercial');
  @override
  late final GeneratedColumn<int> reservadoComercial = GeneratedColumn<int>(
      'reservado_comercial', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reservadoOperacionalMeta =
      const VerificationMeta('reservadoOperacional');
  @override
  late final GeneratedColumn<int> reservadoOperacional = GeneratedColumn<int>(
      'reservado_operacional', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _estoqueMinimoMeta =
      const VerificationMeta('estoqueMinimo');
  @override
  late final GeneratedColumn<int> estoqueMinimo = GeneratedColumn<int>(
      'estoque_minimo', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _estoqueIdealMeta =
      const VerificationMeta('estoqueIdeal');
  @override
  late final GeneratedColumn<int> estoqueIdeal = GeneratedColumn<int>(
      'estoque_ideal', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _loteMinimoMeta =
      const VerificationMeta('loteMinimo');
  @override
  late final GeneratedColumn<int> loteMinimo = GeneratedColumn<int>(
      'lote_minimo', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _atualizadoEmMeta =
      const VerificationMeta('atualizadoEm');
  @override
  late final GeneratedColumn<DateTime> atualizadoEm = GeneratedColumn<DateTime>(
      'atualizado_em', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        produtoId,
        saldoAtual,
        reservado,
        reservadoComercial,
        reservadoOperacional,
        estoqueMinimo,
        estoqueIdeal,
        loteMinimo,
        atualizadoEm
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'estoque_atual';
  @override
  VerificationContext validateIntegrity(Insertable<EstoqueAtualData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('produto_id')) {
      context.handle(_produtoIdMeta,
          produtoId.isAcceptableOrUnknown(data['produto_id']!, _produtoIdMeta));
    }
    if (data.containsKey('saldo_atual')) {
      context.handle(
          _saldoAtualMeta,
          saldoAtual.isAcceptableOrUnknown(
              data['saldo_atual']!, _saldoAtualMeta));
    }
    if (data.containsKey('reservado')) {
      context.handle(_reservadoMeta,
          reservado.isAcceptableOrUnknown(data['reservado']!, _reservadoMeta));
    }
    if (data.containsKey('reservado_comercial')) {
      context.handle(
          _reservadoComercialMeta,
          reservadoComercial.isAcceptableOrUnknown(
              data['reservado_comercial']!, _reservadoComercialMeta));
    }
    if (data.containsKey('reservado_operacional')) {
      context.handle(
          _reservadoOperacionalMeta,
          reservadoOperacional.isAcceptableOrUnknown(
              data['reservado_operacional']!, _reservadoOperacionalMeta));
    }
    if (data.containsKey('estoque_minimo')) {
      context.handle(
          _estoqueMinimoMeta,
          estoqueMinimo.isAcceptableOrUnknown(
              data['estoque_minimo']!, _estoqueMinimoMeta));
    }
    if (data.containsKey('estoque_ideal')) {
      context.handle(
          _estoqueIdealMeta,
          estoqueIdeal.isAcceptableOrUnknown(
              data['estoque_ideal']!, _estoqueIdealMeta));
    }
    if (data.containsKey('lote_minimo')) {
      context.handle(
          _loteMinimoMeta,
          loteMinimo.isAcceptableOrUnknown(
              data['lote_minimo']!, _loteMinimoMeta));
    }
    if (data.containsKey('atualizado_em')) {
      context.handle(
          _atualizadoEmMeta,
          atualizadoEm.isAcceptableOrUnknown(
              data['atualizado_em']!, _atualizadoEmMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {produtoId};
  @override
  EstoqueAtualData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EstoqueAtualData(
      produtoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}produto_id'])!,
      saldoAtual: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}saldo_atual'])!,
      reservado: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reservado'])!,
      reservadoComercial: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}reservado_comercial'])!,
      reservadoOperacional: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}reservado_operacional'])!,
      estoqueMinimo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}estoque_minimo'])!,
      estoqueIdeal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}estoque_ideal'])!,
      loteMinimo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lote_minimo'])!,
      atualizadoEm: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}atualizado_em'])!,
    );
  }

  @override
  $EstoqueAtualTable createAlias(String alias) {
    return $EstoqueAtualTable(attachedDatabase, alias);
  }
}

class EstoqueAtualData extends DataClass
    implements Insertable<EstoqueAtualData> {
  final int produtoId;
  final int saldoAtual;
  final int reservado;
  final int reservadoComercial;
  final int reservadoOperacional;
  final int estoqueMinimo;
  final int estoqueIdeal;
  final int loteMinimo;
  final DateTime atualizadoEm;
  const EstoqueAtualData(
      {required this.produtoId,
      required this.saldoAtual,
      required this.reservado,
      required this.reservadoComercial,
      required this.reservadoOperacional,
      required this.estoqueMinimo,
      required this.estoqueIdeal,
      required this.loteMinimo,
      required this.atualizadoEm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['produto_id'] = Variable<int>(produtoId);
    map['saldo_atual'] = Variable<int>(saldoAtual);
    map['reservado'] = Variable<int>(reservado);
    map['reservado_comercial'] = Variable<int>(reservadoComercial);
    map['reservado_operacional'] = Variable<int>(reservadoOperacional);
    map['estoque_minimo'] = Variable<int>(estoqueMinimo);
    map['estoque_ideal'] = Variable<int>(estoqueIdeal);
    map['lote_minimo'] = Variable<int>(loteMinimo);
    map['atualizado_em'] = Variable<DateTime>(atualizadoEm);
    return map;
  }

  EstoqueAtualCompanion toCompanion(bool nullToAbsent) {
    return EstoqueAtualCompanion(
      produtoId: Value(produtoId),
      saldoAtual: Value(saldoAtual),
      reservado: Value(reservado),
      reservadoComercial: Value(reservadoComercial),
      reservadoOperacional: Value(reservadoOperacional),
      estoqueMinimo: Value(estoqueMinimo),
      estoqueIdeal: Value(estoqueIdeal),
      loteMinimo: Value(loteMinimo),
      atualizadoEm: Value(atualizadoEm),
    );
  }

  factory EstoqueAtualData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EstoqueAtualData(
      produtoId: serializer.fromJson<int>(json['produtoId']),
      saldoAtual: serializer.fromJson<int>(json['saldoAtual']),
      reservado: serializer.fromJson<int>(json['reservado']),
      reservadoComercial: serializer.fromJson<int>(json['reservadoComercial']),
      reservadoOperacional:
          serializer.fromJson<int>(json['reservadoOperacional']),
      estoqueMinimo: serializer.fromJson<int>(json['estoqueMinimo']),
      estoqueIdeal: serializer.fromJson<int>(json['estoqueIdeal']),
      loteMinimo: serializer.fromJson<int>(json['loteMinimo']),
      atualizadoEm: serializer.fromJson<DateTime>(json['atualizadoEm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'produtoId': serializer.toJson<int>(produtoId),
      'saldoAtual': serializer.toJson<int>(saldoAtual),
      'reservado': serializer.toJson<int>(reservado),
      'reservadoComercial': serializer.toJson<int>(reservadoComercial),
      'reservadoOperacional': serializer.toJson<int>(reservadoOperacional),
      'estoqueMinimo': serializer.toJson<int>(estoqueMinimo),
      'estoqueIdeal': serializer.toJson<int>(estoqueIdeal),
      'loteMinimo': serializer.toJson<int>(loteMinimo),
      'atualizadoEm': serializer.toJson<DateTime>(atualizadoEm),
    };
  }

  EstoqueAtualData copyWith(
          {int? produtoId,
          int? saldoAtual,
          int? reservado,
          int? reservadoComercial,
          int? reservadoOperacional,
          int? estoqueMinimo,
          int? estoqueIdeal,
          int? loteMinimo,
          DateTime? atualizadoEm}) =>
      EstoqueAtualData(
        produtoId: produtoId ?? this.produtoId,
        saldoAtual: saldoAtual ?? this.saldoAtual,
        reservado: reservado ?? this.reservado,
        reservadoComercial: reservadoComercial ?? this.reservadoComercial,
        reservadoOperacional: reservadoOperacional ?? this.reservadoOperacional,
        estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
        estoqueIdeal: estoqueIdeal ?? this.estoqueIdeal,
        loteMinimo: loteMinimo ?? this.loteMinimo,
        atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      );
  EstoqueAtualData copyWithCompanion(EstoqueAtualCompanion data) {
    return EstoqueAtualData(
      produtoId: data.produtoId.present ? data.produtoId.value : this.produtoId,
      saldoAtual:
          data.saldoAtual.present ? data.saldoAtual.value : this.saldoAtual,
      reservado: data.reservado.present ? data.reservado.value : this.reservado,
      reservadoComercial: data.reservadoComercial.present
          ? data.reservadoComercial.value
          : this.reservadoComercial,
      reservadoOperacional: data.reservadoOperacional.present
          ? data.reservadoOperacional.value
          : this.reservadoOperacional,
      estoqueMinimo: data.estoqueMinimo.present
          ? data.estoqueMinimo.value
          : this.estoqueMinimo,
      estoqueIdeal: data.estoqueIdeal.present
          ? data.estoqueIdeal.value
          : this.estoqueIdeal,
      loteMinimo:
          data.loteMinimo.present ? data.loteMinimo.value : this.loteMinimo,
      atualizadoEm: data.atualizadoEm.present
          ? data.atualizadoEm.value
          : this.atualizadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EstoqueAtualData(')
          ..write('produtoId: $produtoId, ')
          ..write('saldoAtual: $saldoAtual, ')
          ..write('reservado: $reservado, ')
          ..write('reservadoComercial: $reservadoComercial, ')
          ..write('reservadoOperacional: $reservadoOperacional, ')
          ..write('estoqueMinimo: $estoqueMinimo, ')
          ..write('estoqueIdeal: $estoqueIdeal, ')
          ..write('loteMinimo: $loteMinimo, ')
          ..write('atualizadoEm: $atualizadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      produtoId,
      saldoAtual,
      reservado,
      reservadoComercial,
      reservadoOperacional,
      estoqueMinimo,
      estoqueIdeal,
      loteMinimo,
      atualizadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EstoqueAtualData &&
          other.produtoId == this.produtoId &&
          other.saldoAtual == this.saldoAtual &&
          other.reservado == this.reservado &&
          other.reservadoComercial == this.reservadoComercial &&
          other.reservadoOperacional == this.reservadoOperacional &&
          other.estoqueMinimo == this.estoqueMinimo &&
          other.estoqueIdeal == this.estoqueIdeal &&
          other.loteMinimo == this.loteMinimo &&
          other.atualizadoEm == this.atualizadoEm);
}

class EstoqueAtualCompanion extends UpdateCompanion<EstoqueAtualData> {
  final Value<int> produtoId;
  final Value<int> saldoAtual;
  final Value<int> reservado;
  final Value<int> reservadoComercial;
  final Value<int> reservadoOperacional;
  final Value<int> estoqueMinimo;
  final Value<int> estoqueIdeal;
  final Value<int> loteMinimo;
  final Value<DateTime> atualizadoEm;
  const EstoqueAtualCompanion({
    this.produtoId = const Value.absent(),
    this.saldoAtual = const Value.absent(),
    this.reservado = const Value.absent(),
    this.reservadoComercial = const Value.absent(),
    this.reservadoOperacional = const Value.absent(),
    this.estoqueMinimo = const Value.absent(),
    this.estoqueIdeal = const Value.absent(),
    this.loteMinimo = const Value.absent(),
    this.atualizadoEm = const Value.absent(),
  });
  EstoqueAtualCompanion.insert({
    this.produtoId = const Value.absent(),
    this.saldoAtual = const Value.absent(),
    this.reservado = const Value.absent(),
    this.reservadoComercial = const Value.absent(),
    this.reservadoOperacional = const Value.absent(),
    this.estoqueMinimo = const Value.absent(),
    this.estoqueIdeal = const Value.absent(),
    this.loteMinimo = const Value.absent(),
    this.atualizadoEm = const Value.absent(),
  });
  static Insertable<EstoqueAtualData> custom({
    Expression<int>? produtoId,
    Expression<int>? saldoAtual,
    Expression<int>? reservado,
    Expression<int>? reservadoComercial,
    Expression<int>? reservadoOperacional,
    Expression<int>? estoqueMinimo,
    Expression<int>? estoqueIdeal,
    Expression<int>? loteMinimo,
    Expression<DateTime>? atualizadoEm,
  }) {
    return RawValuesInsertable({
      if (produtoId != null) 'produto_id': produtoId,
      if (saldoAtual != null) 'saldo_atual': saldoAtual,
      if (reservado != null) 'reservado': reservado,
      if (reservadoComercial != null) 'reservado_comercial': reservadoComercial,
      if (reservadoOperacional != null)
        'reservado_operacional': reservadoOperacional,
      if (estoqueMinimo != null) 'estoque_minimo': estoqueMinimo,
      if (estoqueIdeal != null) 'estoque_ideal': estoqueIdeal,
      if (loteMinimo != null) 'lote_minimo': loteMinimo,
      if (atualizadoEm != null) 'atualizado_em': atualizadoEm,
    });
  }

  EstoqueAtualCompanion copyWith(
      {Value<int>? produtoId,
      Value<int>? saldoAtual,
      Value<int>? reservado,
      Value<int>? reservadoComercial,
      Value<int>? reservadoOperacional,
      Value<int>? estoqueMinimo,
      Value<int>? estoqueIdeal,
      Value<int>? loteMinimo,
      Value<DateTime>? atualizadoEm}) {
    return EstoqueAtualCompanion(
      produtoId: produtoId ?? this.produtoId,
      saldoAtual: saldoAtual ?? this.saldoAtual,
      reservado: reservado ?? this.reservado,
      reservadoComercial: reservadoComercial ?? this.reservadoComercial,
      reservadoOperacional: reservadoOperacional ?? this.reservadoOperacional,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      estoqueIdeal: estoqueIdeal ?? this.estoqueIdeal,
      loteMinimo: loteMinimo ?? this.loteMinimo,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (produtoId.present) {
      map['produto_id'] = Variable<int>(produtoId.value);
    }
    if (saldoAtual.present) {
      map['saldo_atual'] = Variable<int>(saldoAtual.value);
    }
    if (reservado.present) {
      map['reservado'] = Variable<int>(reservado.value);
    }
    if (reservadoComercial.present) {
      map['reservado_comercial'] = Variable<int>(reservadoComercial.value);
    }
    if (reservadoOperacional.present) {
      map['reservado_operacional'] = Variable<int>(reservadoOperacional.value);
    }
    if (estoqueMinimo.present) {
      map['estoque_minimo'] = Variable<int>(estoqueMinimo.value);
    }
    if (estoqueIdeal.present) {
      map['estoque_ideal'] = Variable<int>(estoqueIdeal.value);
    }
    if (loteMinimo.present) {
      map['lote_minimo'] = Variable<int>(loteMinimo.value);
    }
    if (atualizadoEm.present) {
      map['atualizado_em'] = Variable<DateTime>(atualizadoEm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EstoqueAtualCompanion(')
          ..write('produtoId: $produtoId, ')
          ..write('saldoAtual: $saldoAtual, ')
          ..write('reservado: $reservado, ')
          ..write('reservadoComercial: $reservadoComercial, ')
          ..write('reservadoOperacional: $reservadoOperacional, ')
          ..write('estoqueMinimo: $estoqueMinimo, ')
          ..write('estoqueIdeal: $estoqueIdeal, ')
          ..write('loteMinimo: $loteMinimo, ')
          ..write('atualizadoEm: $atualizadoEm')
          ..write(')'))
        .toString();
  }
}

class $MovimentacoesEstoqueTable extends MovimentacoesEstoque
    with TableInfo<$MovimentacoesEstoqueTable, MovimentacoesEstoqueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimentacoesEstoqueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _produtoIdMeta =
      const VerificationMeta('produtoId');
  @override
  late final GeneratedColumn<int> produtoId = GeneratedColumn<int>(
      'produto_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES produtos (id)'));
  static const VerificationMeta _tipoMovimentacaoMeta =
      const VerificationMeta('tipoMovimentacao');
  @override
  late final GeneratedColumn<String> tipoMovimentacao = GeneratedColumn<String>(
      'tipo_movimentacao', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantidadeMeta =
      const VerificationMeta('quantidade');
  @override
  late final GeneratedColumn<int> quantidade = GeneratedColumn<int>(
      'quantidade', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _saldoAnteriorMeta =
      const VerificationMeta('saldoAnterior');
  @override
  late final GeneratedColumn<int> saldoAnterior = GeneratedColumn<int>(
      'saldo_anterior', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _saldoNovoMeta =
      const VerificationMeta('saldoNovo');
  @override
  late final GeneratedColumn<int> saldoNovo = GeneratedColumn<int>(
      'saldo_novo', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  @override
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
      'motivo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _pedidoIdMeta =
      const VerificationMeta('pedidoId');
  @override
  late final GeneratedColumn<int> pedidoId = GeneratedColumn<int>(
      'pedido_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES pedidos (id)'));
  static const VerificationMeta _criadoEmMeta =
      const VerificationMeta('criadoEm');
  @override
  late final GeneratedColumn<DateTime> criadoEm = GeneratedColumn<DateTime>(
      'criado_em', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        produtoId,
        tipoMovimentacao,
        quantidade,
        saldoAnterior,
        saldoNovo,
        motivo,
        pedidoId,
        criadoEm
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimentacoes_estoque';
  @override
  VerificationContext validateIntegrity(
      Insertable<MovimentacoesEstoqueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('produto_id')) {
      context.handle(_produtoIdMeta,
          produtoId.isAcceptableOrUnknown(data['produto_id']!, _produtoIdMeta));
    } else if (isInserting) {
      context.missing(_produtoIdMeta);
    }
    if (data.containsKey('tipo_movimentacao')) {
      context.handle(
          _tipoMovimentacaoMeta,
          tipoMovimentacao.isAcceptableOrUnknown(
              data['tipo_movimentacao']!, _tipoMovimentacaoMeta));
    } else if (isInserting) {
      context.missing(_tipoMovimentacaoMeta);
    }
    if (data.containsKey('quantidade')) {
      context.handle(
          _quantidadeMeta,
          quantidade.isAcceptableOrUnknown(
              data['quantidade']!, _quantidadeMeta));
    } else if (isInserting) {
      context.missing(_quantidadeMeta);
    }
    if (data.containsKey('saldo_anterior')) {
      context.handle(
          _saldoAnteriorMeta,
          saldoAnterior.isAcceptableOrUnknown(
              data['saldo_anterior']!, _saldoAnteriorMeta));
    } else if (isInserting) {
      context.missing(_saldoAnteriorMeta);
    }
    if (data.containsKey('saldo_novo')) {
      context.handle(_saldoNovoMeta,
          saldoNovo.isAcceptableOrUnknown(data['saldo_novo']!, _saldoNovoMeta));
    } else if (isInserting) {
      context.missing(_saldoNovoMeta);
    }
    if (data.containsKey('motivo')) {
      context.handle(_motivoMeta,
          motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta));
    }
    if (data.containsKey('pedido_id')) {
      context.handle(_pedidoIdMeta,
          pedidoId.isAcceptableOrUnknown(data['pedido_id']!, _pedidoIdMeta));
    }
    if (data.containsKey('criado_em')) {
      context.handle(_criadoEmMeta,
          criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovimentacoesEstoqueData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovimentacoesEstoqueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      produtoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}produto_id'])!,
      tipoMovimentacao: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}tipo_movimentacao'])!,
      quantidade: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantidade'])!,
      saldoAnterior: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}saldo_anterior'])!,
      saldoNovo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}saldo_novo'])!,
      motivo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motivo'])!,
      pedidoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pedido_id']),
      criadoEm: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}criado_em'])!,
    );
  }

  @override
  $MovimentacoesEstoqueTable createAlias(String alias) {
    return $MovimentacoesEstoqueTable(attachedDatabase, alias);
  }
}

class MovimentacoesEstoqueData extends DataClass
    implements Insertable<MovimentacoesEstoqueData> {
  final int id;
  final int produtoId;
  final String tipoMovimentacao;
  final int quantidade;
  final int saldoAnterior;
  final int saldoNovo;
  final String motivo;
  final int? pedidoId;
  final DateTime criadoEm;
  const MovimentacoesEstoqueData(
      {required this.id,
      required this.produtoId,
      required this.tipoMovimentacao,
      required this.quantidade,
      required this.saldoAnterior,
      required this.saldoNovo,
      required this.motivo,
      this.pedidoId,
      required this.criadoEm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['produto_id'] = Variable<int>(produtoId);
    map['tipo_movimentacao'] = Variable<String>(tipoMovimentacao);
    map['quantidade'] = Variable<int>(quantidade);
    map['saldo_anterior'] = Variable<int>(saldoAnterior);
    map['saldo_novo'] = Variable<int>(saldoNovo);
    map['motivo'] = Variable<String>(motivo);
    if (!nullToAbsent || pedidoId != null) {
      map['pedido_id'] = Variable<int>(pedidoId);
    }
    map['criado_em'] = Variable<DateTime>(criadoEm);
    return map;
  }

  MovimentacoesEstoqueCompanion toCompanion(bool nullToAbsent) {
    return MovimentacoesEstoqueCompanion(
      id: Value(id),
      produtoId: Value(produtoId),
      tipoMovimentacao: Value(tipoMovimentacao),
      quantidade: Value(quantidade),
      saldoAnterior: Value(saldoAnterior),
      saldoNovo: Value(saldoNovo),
      motivo: Value(motivo),
      pedidoId: pedidoId == null && nullToAbsent
          ? const Value.absent()
          : Value(pedidoId),
      criadoEm: Value(criadoEm),
    );
  }

  factory MovimentacoesEstoqueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovimentacoesEstoqueData(
      id: serializer.fromJson<int>(json['id']),
      produtoId: serializer.fromJson<int>(json['produtoId']),
      tipoMovimentacao: serializer.fromJson<String>(json['tipoMovimentacao']),
      quantidade: serializer.fromJson<int>(json['quantidade']),
      saldoAnterior: serializer.fromJson<int>(json['saldoAnterior']),
      saldoNovo: serializer.fromJson<int>(json['saldoNovo']),
      motivo: serializer.fromJson<String>(json['motivo']),
      pedidoId: serializer.fromJson<int?>(json['pedidoId']),
      criadoEm: serializer.fromJson<DateTime>(json['criadoEm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'produtoId': serializer.toJson<int>(produtoId),
      'tipoMovimentacao': serializer.toJson<String>(tipoMovimentacao),
      'quantidade': serializer.toJson<int>(quantidade),
      'saldoAnterior': serializer.toJson<int>(saldoAnterior),
      'saldoNovo': serializer.toJson<int>(saldoNovo),
      'motivo': serializer.toJson<String>(motivo),
      'pedidoId': serializer.toJson<int?>(pedidoId),
      'criadoEm': serializer.toJson<DateTime>(criadoEm),
    };
  }

  MovimentacoesEstoqueData copyWith(
          {int? id,
          int? produtoId,
          String? tipoMovimentacao,
          int? quantidade,
          int? saldoAnterior,
          int? saldoNovo,
          String? motivo,
          Value<int?> pedidoId = const Value.absent(),
          DateTime? criadoEm}) =>
      MovimentacoesEstoqueData(
        id: id ?? this.id,
        produtoId: produtoId ?? this.produtoId,
        tipoMovimentacao: tipoMovimentacao ?? this.tipoMovimentacao,
        quantidade: quantidade ?? this.quantidade,
        saldoAnterior: saldoAnterior ?? this.saldoAnterior,
        saldoNovo: saldoNovo ?? this.saldoNovo,
        motivo: motivo ?? this.motivo,
        pedidoId: pedidoId.present ? pedidoId.value : this.pedidoId,
        criadoEm: criadoEm ?? this.criadoEm,
      );
  MovimentacoesEstoqueData copyWithCompanion(
      MovimentacoesEstoqueCompanion data) {
    return MovimentacoesEstoqueData(
      id: data.id.present ? data.id.value : this.id,
      produtoId: data.produtoId.present ? data.produtoId.value : this.produtoId,
      tipoMovimentacao: data.tipoMovimentacao.present
          ? data.tipoMovimentacao.value
          : this.tipoMovimentacao,
      quantidade:
          data.quantidade.present ? data.quantidade.value : this.quantidade,
      saldoAnterior: data.saldoAnterior.present
          ? data.saldoAnterior.value
          : this.saldoAnterior,
      saldoNovo: data.saldoNovo.present ? data.saldoNovo.value : this.saldoNovo,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      pedidoId: data.pedidoId.present ? data.pedidoId.value : this.pedidoId,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovimentacoesEstoqueData(')
          ..write('id: $id, ')
          ..write('produtoId: $produtoId, ')
          ..write('tipoMovimentacao: $tipoMovimentacao, ')
          ..write('quantidade: $quantidade, ')
          ..write('saldoAnterior: $saldoAnterior, ')
          ..write('saldoNovo: $saldoNovo, ')
          ..write('motivo: $motivo, ')
          ..write('pedidoId: $pedidoId, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, produtoId, tipoMovimentacao, quantidade,
      saldoAnterior, saldoNovo, motivo, pedidoId, criadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovimentacoesEstoqueData &&
          other.id == this.id &&
          other.produtoId == this.produtoId &&
          other.tipoMovimentacao == this.tipoMovimentacao &&
          other.quantidade == this.quantidade &&
          other.saldoAnterior == this.saldoAnterior &&
          other.saldoNovo == this.saldoNovo &&
          other.motivo == this.motivo &&
          other.pedidoId == this.pedidoId &&
          other.criadoEm == this.criadoEm);
}

class MovimentacoesEstoqueCompanion
    extends UpdateCompanion<MovimentacoesEstoqueData> {
  final Value<int> id;
  final Value<int> produtoId;
  final Value<String> tipoMovimentacao;
  final Value<int> quantidade;
  final Value<int> saldoAnterior;
  final Value<int> saldoNovo;
  final Value<String> motivo;
  final Value<int?> pedidoId;
  final Value<DateTime> criadoEm;
  const MovimentacoesEstoqueCompanion({
    this.id = const Value.absent(),
    this.produtoId = const Value.absent(),
    this.tipoMovimentacao = const Value.absent(),
    this.quantidade = const Value.absent(),
    this.saldoAnterior = const Value.absent(),
    this.saldoNovo = const Value.absent(),
    this.motivo = const Value.absent(),
    this.pedidoId = const Value.absent(),
    this.criadoEm = const Value.absent(),
  });
  MovimentacoesEstoqueCompanion.insert({
    this.id = const Value.absent(),
    required int produtoId,
    required String tipoMovimentacao,
    required int quantidade,
    required int saldoAnterior,
    required int saldoNovo,
    this.motivo = const Value.absent(),
    this.pedidoId = const Value.absent(),
    this.criadoEm = const Value.absent(),
  })  : produtoId = Value(produtoId),
        tipoMovimentacao = Value(tipoMovimentacao),
        quantidade = Value(quantidade),
        saldoAnterior = Value(saldoAnterior),
        saldoNovo = Value(saldoNovo);
  static Insertable<MovimentacoesEstoqueData> custom({
    Expression<int>? id,
    Expression<int>? produtoId,
    Expression<String>? tipoMovimentacao,
    Expression<int>? quantidade,
    Expression<int>? saldoAnterior,
    Expression<int>? saldoNovo,
    Expression<String>? motivo,
    Expression<int>? pedidoId,
    Expression<DateTime>? criadoEm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (produtoId != null) 'produto_id': produtoId,
      if (tipoMovimentacao != null) 'tipo_movimentacao': tipoMovimentacao,
      if (quantidade != null) 'quantidade': quantidade,
      if (saldoAnterior != null) 'saldo_anterior': saldoAnterior,
      if (saldoNovo != null) 'saldo_novo': saldoNovo,
      if (motivo != null) 'motivo': motivo,
      if (pedidoId != null) 'pedido_id': pedidoId,
      if (criadoEm != null) 'criado_em': criadoEm,
    });
  }

  MovimentacoesEstoqueCompanion copyWith(
      {Value<int>? id,
      Value<int>? produtoId,
      Value<String>? tipoMovimentacao,
      Value<int>? quantidade,
      Value<int>? saldoAnterior,
      Value<int>? saldoNovo,
      Value<String>? motivo,
      Value<int?>? pedidoId,
      Value<DateTime>? criadoEm}) {
    return MovimentacoesEstoqueCompanion(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      tipoMovimentacao: tipoMovimentacao ?? this.tipoMovimentacao,
      quantidade: quantidade ?? this.quantidade,
      saldoAnterior: saldoAnterior ?? this.saldoAnterior,
      saldoNovo: saldoNovo ?? this.saldoNovo,
      motivo: motivo ?? this.motivo,
      pedidoId: pedidoId ?? this.pedidoId,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (produtoId.present) {
      map['produto_id'] = Variable<int>(produtoId.value);
    }
    if (tipoMovimentacao.present) {
      map['tipo_movimentacao'] = Variable<String>(tipoMovimentacao.value);
    }
    if (quantidade.present) {
      map['quantidade'] = Variable<int>(quantidade.value);
    }
    if (saldoAnterior.present) {
      map['saldo_anterior'] = Variable<int>(saldoAnterior.value);
    }
    if (saldoNovo.present) {
      map['saldo_novo'] = Variable<int>(saldoNovo.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (pedidoId.present) {
      map['pedido_id'] = Variable<int>(pedidoId.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<DateTime>(criadoEm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimentacoesEstoqueCompanion(')
          ..write('id: $id, ')
          ..write('produtoId: $produtoId, ')
          ..write('tipoMovimentacao: $tipoMovimentacao, ')
          ..write('quantidade: $quantidade, ')
          ..write('saldoAnterior: $saldoAnterior, ')
          ..write('saldoNovo: $saldoNovo, ')
          ..write('motivo: $motivo, ')
          ..write('pedidoId: $pedidoId, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }
}

class $ConfiguracoesEmpresaTable extends ConfiguracoesEmpresa
    with TableInfo<$ConfiguracoesEmpresaTable, ConfiguracoesEmpresaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfiguracoesEmpresaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _empresaMeta =
      const VerificationMeta('empresa');
  @override
  late final GeneratedColumn<String> empresa = GeneratedColumn<String>(
      'empresa', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Minha Salgaderia'));
  static const VerificationMeta _telefoneMeta =
      const VerificationMeta('telefone');
  @override
  late final GeneratedColumn<String> telefone = GeneratedColumn<String>(
      'telefone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _enderecoMeta =
      const VerificationMeta('endereco');
  @override
  late final GeneratedColumn<String> endereco = GeneratedColumn<String>(
      'endereco', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _rodapeMeta = const VerificationMeta('rodape');
  @override
  late final GeneratedColumn<String> rodape = GeneratedColumn<String>(
      'rodape', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Obrigado pela preferência!'));
  static const VerificationMeta _impressoraMeta =
      const VerificationMeta('impressora');
  @override
  late final GeneratedColumn<String> impressora = GeneratedColumn<String>(
      'impressora', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _taxaPadraoMeta =
      const VerificationMeta('taxaPadrao');
  @override
  late final GeneratedColumn<int> taxaPadrao = GeneratedColumn<int>(
      'taxa_padrao', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _larguraMeta =
      const VerificationMeta('largura');
  @override
  late final GeneratedColumn<int> largura = GeneratedColumn<int>(
      'largura', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(80));
  static const VerificationMeta _horizonteOperacionalMeta =
      const VerificationMeta('horizonteOperacional');
  @override
  late final GeneratedColumn<String> horizonteOperacional =
      GeneratedColumn<String>('horizonte_operacional', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('Hoje + Amanhã'));
  static const VerificationMeta _razaoSocialMeta =
      const VerificationMeta('razaoSocial');
  @override
  late final GeneratedColumn<String> razaoSocial = GeneratedColumn<String>(
      'razao_social', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _whatsappMeta =
      const VerificationMeta('whatsapp');
  @override
  late final GeneratedColumn<String> whatsapp = GeneratedColumn<String>(
      'whatsapp', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _instagramMeta =
      const VerificationMeta('instagram');
  @override
  late final GeneratedColumn<String> instagram = GeneratedColumn<String>(
      'instagram', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _logoPathMeta =
      const VerificationMeta('logoPath');
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
      'logo_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _habilitarPixMeta =
      const VerificationMeta('habilitarPix');
  @override
  late final GeneratedColumn<bool> habilitarPix = GeneratedColumn<bool>(
      'habilitar_pix', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("habilitar_pix" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pixTipoChaveMeta =
      const VerificationMeta('pixTipoChave');
  @override
  late final GeneratedColumn<String> pixTipoChave = GeneratedColumn<String>(
      'pix_tipo_chave', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CPF'));
  static const VerificationMeta _pixChaveMeta =
      const VerificationMeta('pixChave');
  @override
  late final GeneratedColumn<String> pixChave = GeneratedColumn<String>(
      'pix_chave', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _pixFavorecidoMeta =
      const VerificationMeta('pixFavorecido');
  @override
  late final GeneratedColumn<String> pixFavorecido = GeneratedColumn<String>(
      'pix_favorecido', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _pixBancoMeta =
      const VerificationMeta('pixBanco');
  @override
  late final GeneratedColumn<String> pixBanco = GeneratedColumn<String>(
      'pix_banco', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _pixCidadeMeta =
      const VerificationMeta('pixCidade');
  @override
  late final GeneratedColumn<String> pixCidade = GeneratedColumn<String>(
      'pix_cidade', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Sorocaba'));
  static const VerificationMeta _pixMensagemMeta =
      const VerificationMeta('pixMensagem');
  @override
  late final GeneratedColumn<String> pixMensagem = GeneratedColumn<String>(
      'pix_mensagem', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Envie o comprovante após o pagamento'));
  static const VerificationMeta _pixImprimirQrCodeMeta =
      const VerificationMeta('pixImprimirQrCode');
  @override
  late final GeneratedColumn<bool> pixImprimirQrCode = GeneratedColumn<bool>(
      'pix_imprimir_qr_code', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pix_imprimir_qr_code" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _pixImprimirCopiaColaMeta =
      const VerificationMeta('pixImprimirCopiaCola');
  @override
  late final GeneratedColumn<bool> pixImprimirCopiaCola = GeneratedColumn<bool>(
      'pix_imprimir_copia_cola', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pix_imprimir_copia_cola" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _pixGerarQrCodeAutoMeta =
      const VerificationMeta('pixGerarQrCodeAuto');
  @override
  late final GeneratedColumn<bool> pixGerarQrCodeAuto = GeneratedColumn<bool>(
      'pix_gerar_qr_code_auto', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pix_gerar_qr_code_auto" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        empresa,
        telefone,
        endereco,
        rodape,
        impressora,
        taxaPadrao,
        largura,
        horizonteOperacional,
        razaoSocial,
        whatsapp,
        instagram,
        logoPath,
        habilitarPix,
        pixTipoChave,
        pixChave,
        pixFavorecido,
        pixBanco,
        pixCidade,
        pixMensagem,
        pixImprimirQrCode,
        pixImprimirCopiaCola,
        pixGerarQrCodeAuto
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'configuracoes_empresa';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConfiguracoesEmpresaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('empresa')) {
      context.handle(_empresaMeta,
          empresa.isAcceptableOrUnknown(data['empresa']!, _empresaMeta));
    }
    if (data.containsKey('telefone')) {
      context.handle(_telefoneMeta,
          telefone.isAcceptableOrUnknown(data['telefone']!, _telefoneMeta));
    }
    if (data.containsKey('endereco')) {
      context.handle(_enderecoMeta,
          endereco.isAcceptableOrUnknown(data['endereco']!, _enderecoMeta));
    }
    if (data.containsKey('rodape')) {
      context.handle(_rodapeMeta,
          rodape.isAcceptableOrUnknown(data['rodape']!, _rodapeMeta));
    }
    if (data.containsKey('impressora')) {
      context.handle(
          _impressoraMeta,
          impressora.isAcceptableOrUnknown(
              data['impressora']!, _impressoraMeta));
    }
    if (data.containsKey('taxa_padrao')) {
      context.handle(
          _taxaPadraoMeta,
          taxaPadrao.isAcceptableOrUnknown(
              data['taxa_padrao']!, _taxaPadraoMeta));
    }
    if (data.containsKey('largura')) {
      context.handle(_larguraMeta,
          largura.isAcceptableOrUnknown(data['largura']!, _larguraMeta));
    }
    if (data.containsKey('horizonte_operacional')) {
      context.handle(
          _horizonteOperacionalMeta,
          horizonteOperacional.isAcceptableOrUnknown(
              data['horizonte_operacional']!, _horizonteOperacionalMeta));
    }
    if (data.containsKey('razao_social')) {
      context.handle(
          _razaoSocialMeta,
          razaoSocial.isAcceptableOrUnknown(
              data['razao_social']!, _razaoSocialMeta));
    }
    if (data.containsKey('whatsapp')) {
      context.handle(_whatsappMeta,
          whatsapp.isAcceptableOrUnknown(data['whatsapp']!, _whatsappMeta));
    }
    if (data.containsKey('instagram')) {
      context.handle(_instagramMeta,
          instagram.isAcceptableOrUnknown(data['instagram']!, _instagramMeta));
    }
    if (data.containsKey('logo_path')) {
      context.handle(_logoPathMeta,
          logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta));
    }
    if (data.containsKey('habilitar_pix')) {
      context.handle(
          _habilitarPixMeta,
          habilitarPix.isAcceptableOrUnknown(
              data['habilitar_pix']!, _habilitarPixMeta));
    }
    if (data.containsKey('pix_tipo_chave')) {
      context.handle(
          _pixTipoChaveMeta,
          pixTipoChave.isAcceptableOrUnknown(
              data['pix_tipo_chave']!, _pixTipoChaveMeta));
    }
    if (data.containsKey('pix_chave')) {
      context.handle(_pixChaveMeta,
          pixChave.isAcceptableOrUnknown(data['pix_chave']!, _pixChaveMeta));
    }
    if (data.containsKey('pix_favorecido')) {
      context.handle(
          _pixFavorecidoMeta,
          pixFavorecido.isAcceptableOrUnknown(
              data['pix_favorecido']!, _pixFavorecidoMeta));
    }
    if (data.containsKey('pix_banco')) {
      context.handle(_pixBancoMeta,
          pixBanco.isAcceptableOrUnknown(data['pix_banco']!, _pixBancoMeta));
    }
    if (data.containsKey('pix_cidade')) {
      context.handle(_pixCidadeMeta,
          pixCidade.isAcceptableOrUnknown(data['pix_cidade']!, _pixCidadeMeta));
    }
    if (data.containsKey('pix_mensagem')) {
      context.handle(
          _pixMensagemMeta,
          pixMensagem.isAcceptableOrUnknown(
              data['pix_mensagem']!, _pixMensagemMeta));
    }
    if (data.containsKey('pix_imprimir_qr_code')) {
      context.handle(
          _pixImprimirQrCodeMeta,
          pixImprimirQrCode.isAcceptableOrUnknown(
              data['pix_imprimir_qr_code']!, _pixImprimirQrCodeMeta));
    }
    if (data.containsKey('pix_imprimir_copia_cola')) {
      context.handle(
          _pixImprimirCopiaColaMeta,
          pixImprimirCopiaCola.isAcceptableOrUnknown(
              data['pix_imprimir_copia_cola']!, _pixImprimirCopiaColaMeta));
    }
    if (data.containsKey('pix_gerar_qr_code_auto')) {
      context.handle(
          _pixGerarQrCodeAutoMeta,
          pixGerarQrCodeAuto.isAcceptableOrUnknown(
              data['pix_gerar_qr_code_auto']!, _pixGerarQrCodeAutoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfiguracoesEmpresaData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfiguracoesEmpresaData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      empresa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}empresa'])!,
      telefone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}telefone'])!,
      endereco: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}endereco'])!,
      rodape: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rodape'])!,
      impressora: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}impressora'])!,
      taxaPadrao: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}taxa_padrao'])!,
      largura: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}largura'])!,
      horizonteOperacional: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}horizonte_operacional'])!,
      razaoSocial: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}razao_social'])!,
      whatsapp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}whatsapp'])!,
      instagram: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instagram'])!,
      logoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo_path'])!,
      habilitarPix: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}habilitar_pix'])!,
      pixTipoChave: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pix_tipo_chave'])!,
      pixChave: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pix_chave'])!,
      pixFavorecido: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pix_favorecido'])!,
      pixBanco: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pix_banco'])!,
      pixCidade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pix_cidade'])!,
      pixMensagem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pix_mensagem'])!,
      pixImprimirQrCode: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}pix_imprimir_qr_code'])!,
      pixImprimirCopiaCola: attachedDatabase.typeMapping.read(DriftSqlType.bool,
          data['${effectivePrefix}pix_imprimir_copia_cola'])!,
      pixGerarQrCodeAuto: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}pix_gerar_qr_code_auto'])!,
    );
  }

  @override
  $ConfiguracoesEmpresaTable createAlias(String alias) {
    return $ConfiguracoesEmpresaTable(attachedDatabase, alias);
  }
}

class ConfiguracoesEmpresaData extends DataClass
    implements Insertable<ConfiguracoesEmpresaData> {
  final int id;
  final String empresa;
  final String telefone;
  final String endereco;
  final String rodape;
  final String impressora;
  final int taxaPadrao;
  final int largura;
  final String horizonteOperacional;
  final String razaoSocial;
  final String whatsapp;
  final String instagram;
  final String logoPath;
  final bool habilitarPix;
  final String pixTipoChave;
  final String pixChave;
  final String pixFavorecido;
  final String pixBanco;
  final String pixCidade;
  final String pixMensagem;
  final bool pixImprimirQrCode;
  final bool pixImprimirCopiaCola;
  final bool pixGerarQrCodeAuto;
  const ConfiguracoesEmpresaData(
      {required this.id,
      required this.empresa,
      required this.telefone,
      required this.endereco,
      required this.rodape,
      required this.impressora,
      required this.taxaPadrao,
      required this.largura,
      required this.horizonteOperacional,
      required this.razaoSocial,
      required this.whatsapp,
      required this.instagram,
      required this.logoPath,
      required this.habilitarPix,
      required this.pixTipoChave,
      required this.pixChave,
      required this.pixFavorecido,
      required this.pixBanco,
      required this.pixCidade,
      required this.pixMensagem,
      required this.pixImprimirQrCode,
      required this.pixImprimirCopiaCola,
      required this.pixGerarQrCodeAuto});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['empresa'] = Variable<String>(empresa);
    map['telefone'] = Variable<String>(telefone);
    map['endereco'] = Variable<String>(endereco);
    map['rodape'] = Variable<String>(rodape);
    map['impressora'] = Variable<String>(impressora);
    map['taxa_padrao'] = Variable<int>(taxaPadrao);
    map['largura'] = Variable<int>(largura);
    map['horizonte_operacional'] = Variable<String>(horizonteOperacional);
    map['razao_social'] = Variable<String>(razaoSocial);
    map['whatsapp'] = Variable<String>(whatsapp);
    map['instagram'] = Variable<String>(instagram);
    map['logo_path'] = Variable<String>(logoPath);
    map['habilitar_pix'] = Variable<bool>(habilitarPix);
    map['pix_tipo_chave'] = Variable<String>(pixTipoChave);
    map['pix_chave'] = Variable<String>(pixChave);
    map['pix_favorecido'] = Variable<String>(pixFavorecido);
    map['pix_banco'] = Variable<String>(pixBanco);
    map['pix_cidade'] = Variable<String>(pixCidade);
    map['pix_mensagem'] = Variable<String>(pixMensagem);
    map['pix_imprimir_qr_code'] = Variable<bool>(pixImprimirQrCode);
    map['pix_imprimir_copia_cola'] = Variable<bool>(pixImprimirCopiaCola);
    map['pix_gerar_qr_code_auto'] = Variable<bool>(pixGerarQrCodeAuto);
    return map;
  }

  ConfiguracoesEmpresaCompanion toCompanion(bool nullToAbsent) {
    return ConfiguracoesEmpresaCompanion(
      id: Value(id),
      empresa: Value(empresa),
      telefone: Value(telefone),
      endereco: Value(endereco),
      rodape: Value(rodape),
      impressora: Value(impressora),
      taxaPadrao: Value(taxaPadrao),
      largura: Value(largura),
      horizonteOperacional: Value(horizonteOperacional),
      razaoSocial: Value(razaoSocial),
      whatsapp: Value(whatsapp),
      instagram: Value(instagram),
      logoPath: Value(logoPath),
      habilitarPix: Value(habilitarPix),
      pixTipoChave: Value(pixTipoChave),
      pixChave: Value(pixChave),
      pixFavorecido: Value(pixFavorecido),
      pixBanco: Value(pixBanco),
      pixCidade: Value(pixCidade),
      pixMensagem: Value(pixMensagem),
      pixImprimirQrCode: Value(pixImprimirQrCode),
      pixImprimirCopiaCola: Value(pixImprimirCopiaCola),
      pixGerarQrCodeAuto: Value(pixGerarQrCodeAuto),
    );
  }

  factory ConfiguracoesEmpresaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfiguracoesEmpresaData(
      id: serializer.fromJson<int>(json['id']),
      empresa: serializer.fromJson<String>(json['empresa']),
      telefone: serializer.fromJson<String>(json['telefone']),
      endereco: serializer.fromJson<String>(json['endereco']),
      rodape: serializer.fromJson<String>(json['rodape']),
      impressora: serializer.fromJson<String>(json['impressora']),
      taxaPadrao: serializer.fromJson<int>(json['taxaPadrao']),
      largura: serializer.fromJson<int>(json['largura']),
      horizonteOperacional:
          serializer.fromJson<String>(json['horizonteOperacional']),
      razaoSocial: serializer.fromJson<String>(json['razaoSocial']),
      whatsapp: serializer.fromJson<String>(json['whatsapp']),
      instagram: serializer.fromJson<String>(json['instagram']),
      logoPath: serializer.fromJson<String>(json['logoPath']),
      habilitarPix: serializer.fromJson<bool>(json['habilitarPix']),
      pixTipoChave: serializer.fromJson<String>(json['pixTipoChave']),
      pixChave: serializer.fromJson<String>(json['pixChave']),
      pixFavorecido: serializer.fromJson<String>(json['pixFavorecido']),
      pixBanco: serializer.fromJson<String>(json['pixBanco']),
      pixCidade: serializer.fromJson<String>(json['pixCidade']),
      pixMensagem: serializer.fromJson<String>(json['pixMensagem']),
      pixImprimirQrCode: serializer.fromJson<bool>(json['pixImprimirQrCode']),
      pixImprimirCopiaCola:
          serializer.fromJson<bool>(json['pixImprimirCopiaCola']),
      pixGerarQrCodeAuto: serializer.fromJson<bool>(json['pixGerarQrCodeAuto']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'empresa': serializer.toJson<String>(empresa),
      'telefone': serializer.toJson<String>(telefone),
      'endereco': serializer.toJson<String>(endereco),
      'rodape': serializer.toJson<String>(rodape),
      'impressora': serializer.toJson<String>(impressora),
      'taxaPadrao': serializer.toJson<int>(taxaPadrao),
      'largura': serializer.toJson<int>(largura),
      'horizonteOperacional': serializer.toJson<String>(horizonteOperacional),
      'razaoSocial': serializer.toJson<String>(razaoSocial),
      'whatsapp': serializer.toJson<String>(whatsapp),
      'instagram': serializer.toJson<String>(instagram),
      'logoPath': serializer.toJson<String>(logoPath),
      'habilitarPix': serializer.toJson<bool>(habilitarPix),
      'pixTipoChave': serializer.toJson<String>(pixTipoChave),
      'pixChave': serializer.toJson<String>(pixChave),
      'pixFavorecido': serializer.toJson<String>(pixFavorecido),
      'pixBanco': serializer.toJson<String>(pixBanco),
      'pixCidade': serializer.toJson<String>(pixCidade),
      'pixMensagem': serializer.toJson<String>(pixMensagem),
      'pixImprimirQrCode': serializer.toJson<bool>(pixImprimirQrCode),
      'pixImprimirCopiaCola': serializer.toJson<bool>(pixImprimirCopiaCola),
      'pixGerarQrCodeAuto': serializer.toJson<bool>(pixGerarQrCodeAuto),
    };
  }

  ConfiguracoesEmpresaData copyWith(
          {int? id,
          String? empresa,
          String? telefone,
          String? endereco,
          String? rodape,
          String? impressora,
          int? taxaPadrao,
          int? largura,
          String? horizonteOperacional,
          String? razaoSocial,
          String? whatsapp,
          String? instagram,
          String? logoPath,
          bool? habilitarPix,
          String? pixTipoChave,
          String? pixChave,
          String? pixFavorecido,
          String? pixBanco,
          String? pixCidade,
          String? pixMensagem,
          bool? pixImprimirQrCode,
          bool? pixImprimirCopiaCola,
          bool? pixGerarQrCodeAuto}) =>
      ConfiguracoesEmpresaData(
        id: id ?? this.id,
        empresa: empresa ?? this.empresa,
        telefone: telefone ?? this.telefone,
        endereco: endereco ?? this.endereco,
        rodape: rodape ?? this.rodape,
        impressora: impressora ?? this.impressora,
        taxaPadrao: taxaPadrao ?? this.taxaPadrao,
        largura: largura ?? this.largura,
        horizonteOperacional: horizonteOperacional ?? this.horizonteOperacional,
        razaoSocial: razaoSocial ?? this.razaoSocial,
        whatsapp: whatsapp ?? this.whatsapp,
        instagram: instagram ?? this.instagram,
        logoPath: logoPath ?? this.logoPath,
        habilitarPix: habilitarPix ?? this.habilitarPix,
        pixTipoChave: pixTipoChave ?? this.pixTipoChave,
        pixChave: pixChave ?? this.pixChave,
        pixFavorecido: pixFavorecido ?? this.pixFavorecido,
        pixBanco: pixBanco ?? this.pixBanco,
        pixCidade: pixCidade ?? this.pixCidade,
        pixMensagem: pixMensagem ?? this.pixMensagem,
        pixImprimirQrCode: pixImprimirQrCode ?? this.pixImprimirQrCode,
        pixImprimirCopiaCola: pixImprimirCopiaCola ?? this.pixImprimirCopiaCola,
        pixGerarQrCodeAuto: pixGerarQrCodeAuto ?? this.pixGerarQrCodeAuto,
      );
  ConfiguracoesEmpresaData copyWithCompanion(
      ConfiguracoesEmpresaCompanion data) {
    return ConfiguracoesEmpresaData(
      id: data.id.present ? data.id.value : this.id,
      empresa: data.empresa.present ? data.empresa.value : this.empresa,
      telefone: data.telefone.present ? data.telefone.value : this.telefone,
      endereco: data.endereco.present ? data.endereco.value : this.endereco,
      rodape: data.rodape.present ? data.rodape.value : this.rodape,
      impressora:
          data.impressora.present ? data.impressora.value : this.impressora,
      taxaPadrao:
          data.taxaPadrao.present ? data.taxaPadrao.value : this.taxaPadrao,
      largura: data.largura.present ? data.largura.value : this.largura,
      horizonteOperacional: data.horizonteOperacional.present
          ? data.horizonteOperacional.value
          : this.horizonteOperacional,
      razaoSocial:
          data.razaoSocial.present ? data.razaoSocial.value : this.razaoSocial,
      whatsapp: data.whatsapp.present ? data.whatsapp.value : this.whatsapp,
      instagram: data.instagram.present ? data.instagram.value : this.instagram,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      habilitarPix: data.habilitarPix.present
          ? data.habilitarPix.value
          : this.habilitarPix,
      pixTipoChave: data.pixTipoChave.present
          ? data.pixTipoChave.value
          : this.pixTipoChave,
      pixChave: data.pixChave.present ? data.pixChave.value : this.pixChave,
      pixFavorecido: data.pixFavorecido.present
          ? data.pixFavorecido.value
          : this.pixFavorecido,
      pixBanco: data.pixBanco.present ? data.pixBanco.value : this.pixBanco,
      pixCidade: data.pixCidade.present ? data.pixCidade.value : this.pixCidade,
      pixMensagem:
          data.pixMensagem.present ? data.pixMensagem.value : this.pixMensagem,
      pixImprimirQrCode: data.pixImprimirQrCode.present
          ? data.pixImprimirQrCode.value
          : this.pixImprimirQrCode,
      pixImprimirCopiaCola: data.pixImprimirCopiaCola.present
          ? data.pixImprimirCopiaCola.value
          : this.pixImprimirCopiaCola,
      pixGerarQrCodeAuto: data.pixGerarQrCodeAuto.present
          ? data.pixGerarQrCodeAuto.value
          : this.pixGerarQrCodeAuto,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfiguracoesEmpresaData(')
          ..write('id: $id, ')
          ..write('empresa: $empresa, ')
          ..write('telefone: $telefone, ')
          ..write('endereco: $endereco, ')
          ..write('rodape: $rodape, ')
          ..write('impressora: $impressora, ')
          ..write('taxaPadrao: $taxaPadrao, ')
          ..write('largura: $largura, ')
          ..write('horizonteOperacional: $horizonteOperacional, ')
          ..write('razaoSocial: $razaoSocial, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('instagram: $instagram, ')
          ..write('logoPath: $logoPath, ')
          ..write('habilitarPix: $habilitarPix, ')
          ..write('pixTipoChave: $pixTipoChave, ')
          ..write('pixChave: $pixChave, ')
          ..write('pixFavorecido: $pixFavorecido, ')
          ..write('pixBanco: $pixBanco, ')
          ..write('pixCidade: $pixCidade, ')
          ..write('pixMensagem: $pixMensagem, ')
          ..write('pixImprimirQrCode: $pixImprimirQrCode, ')
          ..write('pixImprimirCopiaCola: $pixImprimirCopiaCola, ')
          ..write('pixGerarQrCodeAuto: $pixGerarQrCodeAuto')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        empresa,
        telefone,
        endereco,
        rodape,
        impressora,
        taxaPadrao,
        largura,
        horizonteOperacional,
        razaoSocial,
        whatsapp,
        instagram,
        logoPath,
        habilitarPix,
        pixTipoChave,
        pixChave,
        pixFavorecido,
        pixBanco,
        pixCidade,
        pixMensagem,
        pixImprimirQrCode,
        pixImprimirCopiaCola,
        pixGerarQrCodeAuto
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfiguracoesEmpresaData &&
          other.id == this.id &&
          other.empresa == this.empresa &&
          other.telefone == this.telefone &&
          other.endereco == this.endereco &&
          other.rodape == this.rodape &&
          other.impressora == this.impressora &&
          other.taxaPadrao == this.taxaPadrao &&
          other.largura == this.largura &&
          other.horizonteOperacional == this.horizonteOperacional &&
          other.razaoSocial == this.razaoSocial &&
          other.whatsapp == this.whatsapp &&
          other.instagram == this.instagram &&
          other.logoPath == this.logoPath &&
          other.habilitarPix == this.habilitarPix &&
          other.pixTipoChave == this.pixTipoChave &&
          other.pixChave == this.pixChave &&
          other.pixFavorecido == this.pixFavorecido &&
          other.pixBanco == this.pixBanco &&
          other.pixCidade == this.pixCidade &&
          other.pixMensagem == this.pixMensagem &&
          other.pixImprimirQrCode == this.pixImprimirQrCode &&
          other.pixImprimirCopiaCola == this.pixImprimirCopiaCola &&
          other.pixGerarQrCodeAuto == this.pixGerarQrCodeAuto);
}

class ConfiguracoesEmpresaCompanion
    extends UpdateCompanion<ConfiguracoesEmpresaData> {
  final Value<int> id;
  final Value<String> empresa;
  final Value<String> telefone;
  final Value<String> endereco;
  final Value<String> rodape;
  final Value<String> impressora;
  final Value<int> taxaPadrao;
  final Value<int> largura;
  final Value<String> horizonteOperacional;
  final Value<String> razaoSocial;
  final Value<String> whatsapp;
  final Value<String> instagram;
  final Value<String> logoPath;
  final Value<bool> habilitarPix;
  final Value<String> pixTipoChave;
  final Value<String> pixChave;
  final Value<String> pixFavorecido;
  final Value<String> pixBanco;
  final Value<String> pixCidade;
  final Value<String> pixMensagem;
  final Value<bool> pixImprimirQrCode;
  final Value<bool> pixImprimirCopiaCola;
  final Value<bool> pixGerarQrCodeAuto;
  const ConfiguracoesEmpresaCompanion({
    this.id = const Value.absent(),
    this.empresa = const Value.absent(),
    this.telefone = const Value.absent(),
    this.endereco = const Value.absent(),
    this.rodape = const Value.absent(),
    this.impressora = const Value.absent(),
    this.taxaPadrao = const Value.absent(),
    this.largura = const Value.absent(),
    this.horizonteOperacional = const Value.absent(),
    this.razaoSocial = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.instagram = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.habilitarPix = const Value.absent(),
    this.pixTipoChave = const Value.absent(),
    this.pixChave = const Value.absent(),
    this.pixFavorecido = const Value.absent(),
    this.pixBanco = const Value.absent(),
    this.pixCidade = const Value.absent(),
    this.pixMensagem = const Value.absent(),
    this.pixImprimirQrCode = const Value.absent(),
    this.pixImprimirCopiaCola = const Value.absent(),
    this.pixGerarQrCodeAuto = const Value.absent(),
  });
  ConfiguracoesEmpresaCompanion.insert({
    this.id = const Value.absent(),
    this.empresa = const Value.absent(),
    this.telefone = const Value.absent(),
    this.endereco = const Value.absent(),
    this.rodape = const Value.absent(),
    this.impressora = const Value.absent(),
    this.taxaPadrao = const Value.absent(),
    this.largura = const Value.absent(),
    this.horizonteOperacional = const Value.absent(),
    this.razaoSocial = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.instagram = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.habilitarPix = const Value.absent(),
    this.pixTipoChave = const Value.absent(),
    this.pixChave = const Value.absent(),
    this.pixFavorecido = const Value.absent(),
    this.pixBanco = const Value.absent(),
    this.pixCidade = const Value.absent(),
    this.pixMensagem = const Value.absent(),
    this.pixImprimirQrCode = const Value.absent(),
    this.pixImprimirCopiaCola = const Value.absent(),
    this.pixGerarQrCodeAuto = const Value.absent(),
  });
  static Insertable<ConfiguracoesEmpresaData> custom({
    Expression<int>? id,
    Expression<String>? empresa,
    Expression<String>? telefone,
    Expression<String>? endereco,
    Expression<String>? rodape,
    Expression<String>? impressora,
    Expression<int>? taxaPadrao,
    Expression<int>? largura,
    Expression<String>? horizonteOperacional,
    Expression<String>? razaoSocial,
    Expression<String>? whatsapp,
    Expression<String>? instagram,
    Expression<String>? logoPath,
    Expression<bool>? habilitarPix,
    Expression<String>? pixTipoChave,
    Expression<String>? pixChave,
    Expression<String>? pixFavorecido,
    Expression<String>? pixBanco,
    Expression<String>? pixCidade,
    Expression<String>? pixMensagem,
    Expression<bool>? pixImprimirQrCode,
    Expression<bool>? pixImprimirCopiaCola,
    Expression<bool>? pixGerarQrCodeAuto,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresa != null) 'empresa': empresa,
      if (telefone != null) 'telefone': telefone,
      if (endereco != null) 'endereco': endereco,
      if (rodape != null) 'rodape': rodape,
      if (impressora != null) 'impressora': impressora,
      if (taxaPadrao != null) 'taxa_padrao': taxaPadrao,
      if (largura != null) 'largura': largura,
      if (horizonteOperacional != null)
        'horizonte_operacional': horizonteOperacional,
      if (razaoSocial != null) 'razao_social': razaoSocial,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (instagram != null) 'instagram': instagram,
      if (logoPath != null) 'logo_path': logoPath,
      if (habilitarPix != null) 'habilitar_pix': habilitarPix,
      if (pixTipoChave != null) 'pix_tipo_chave': pixTipoChave,
      if (pixChave != null) 'pix_chave': pixChave,
      if (pixFavorecido != null) 'pix_favorecido': pixFavorecido,
      if (pixBanco != null) 'pix_banco': pixBanco,
      if (pixCidade != null) 'pix_cidade': pixCidade,
      if (pixMensagem != null) 'pix_mensagem': pixMensagem,
      if (pixImprimirQrCode != null) 'pix_imprimir_qr_code': pixImprimirQrCode,
      if (pixImprimirCopiaCola != null)
        'pix_imprimir_copia_cola': pixImprimirCopiaCola,
      if (pixGerarQrCodeAuto != null)
        'pix_gerar_qr_code_auto': pixGerarQrCodeAuto,
    });
  }

  ConfiguracoesEmpresaCompanion copyWith(
      {Value<int>? id,
      Value<String>? empresa,
      Value<String>? telefone,
      Value<String>? endereco,
      Value<String>? rodape,
      Value<String>? impressora,
      Value<int>? taxaPadrao,
      Value<int>? largura,
      Value<String>? horizonteOperacional,
      Value<String>? razaoSocial,
      Value<String>? whatsapp,
      Value<String>? instagram,
      Value<String>? logoPath,
      Value<bool>? habilitarPix,
      Value<String>? pixTipoChave,
      Value<String>? pixChave,
      Value<String>? pixFavorecido,
      Value<String>? pixBanco,
      Value<String>? pixCidade,
      Value<String>? pixMensagem,
      Value<bool>? pixImprimirQrCode,
      Value<bool>? pixImprimirCopiaCola,
      Value<bool>? pixGerarQrCodeAuto}) {
    return ConfiguracoesEmpresaCompanion(
      id: id ?? this.id,
      empresa: empresa ?? this.empresa,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      rodape: rodape ?? this.rodape,
      impressora: impressora ?? this.impressora,
      taxaPadrao: taxaPadrao ?? this.taxaPadrao,
      largura: largura ?? this.largura,
      horizonteOperacional: horizonteOperacional ?? this.horizonteOperacional,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      whatsapp: whatsapp ?? this.whatsapp,
      instagram: instagram ?? this.instagram,
      logoPath: logoPath ?? this.logoPath,
      habilitarPix: habilitarPix ?? this.habilitarPix,
      pixTipoChave: pixTipoChave ?? this.pixTipoChave,
      pixChave: pixChave ?? this.pixChave,
      pixFavorecido: pixFavorecido ?? this.pixFavorecido,
      pixBanco: pixBanco ?? this.pixBanco,
      pixCidade: pixCidade ?? this.pixCidade,
      pixMensagem: pixMensagem ?? this.pixMensagem,
      pixImprimirQrCode: pixImprimirQrCode ?? this.pixImprimirQrCode,
      pixImprimirCopiaCola: pixImprimirCopiaCola ?? this.pixImprimirCopiaCola,
      pixGerarQrCodeAuto: pixGerarQrCodeAuto ?? this.pixGerarQrCodeAuto,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (empresa.present) {
      map['empresa'] = Variable<String>(empresa.value);
    }
    if (telefone.present) {
      map['telefone'] = Variable<String>(telefone.value);
    }
    if (endereco.present) {
      map['endereco'] = Variable<String>(endereco.value);
    }
    if (rodape.present) {
      map['rodape'] = Variable<String>(rodape.value);
    }
    if (impressora.present) {
      map['impressora'] = Variable<String>(impressora.value);
    }
    if (taxaPadrao.present) {
      map['taxa_padrao'] = Variable<int>(taxaPadrao.value);
    }
    if (largura.present) {
      map['largura'] = Variable<int>(largura.value);
    }
    if (horizonteOperacional.present) {
      map['horizonte_operacional'] =
          Variable<String>(horizonteOperacional.value);
    }
    if (razaoSocial.present) {
      map['razao_social'] = Variable<String>(razaoSocial.value);
    }
    if (whatsapp.present) {
      map['whatsapp'] = Variable<String>(whatsapp.value);
    }
    if (instagram.present) {
      map['instagram'] = Variable<String>(instagram.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (habilitarPix.present) {
      map['habilitar_pix'] = Variable<bool>(habilitarPix.value);
    }
    if (pixTipoChave.present) {
      map['pix_tipo_chave'] = Variable<String>(pixTipoChave.value);
    }
    if (pixChave.present) {
      map['pix_chave'] = Variable<String>(pixChave.value);
    }
    if (pixFavorecido.present) {
      map['pix_favorecido'] = Variable<String>(pixFavorecido.value);
    }
    if (pixBanco.present) {
      map['pix_banco'] = Variable<String>(pixBanco.value);
    }
    if (pixCidade.present) {
      map['pix_cidade'] = Variable<String>(pixCidade.value);
    }
    if (pixMensagem.present) {
      map['pix_mensagem'] = Variable<String>(pixMensagem.value);
    }
    if (pixImprimirQrCode.present) {
      map['pix_imprimir_qr_code'] = Variable<bool>(pixImprimirQrCode.value);
    }
    if (pixImprimirCopiaCola.present) {
      map['pix_imprimir_copia_cola'] =
          Variable<bool>(pixImprimirCopiaCola.value);
    }
    if (pixGerarQrCodeAuto.present) {
      map['pix_gerar_qr_code_auto'] = Variable<bool>(pixGerarQrCodeAuto.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfiguracoesEmpresaCompanion(')
          ..write('id: $id, ')
          ..write('empresa: $empresa, ')
          ..write('telefone: $telefone, ')
          ..write('endereco: $endereco, ')
          ..write('rodape: $rodape, ')
          ..write('impressora: $impressora, ')
          ..write('taxaPadrao: $taxaPadrao, ')
          ..write('largura: $largura, ')
          ..write('horizonteOperacional: $horizonteOperacional, ')
          ..write('razaoSocial: $razaoSocial, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('instagram: $instagram, ')
          ..write('logoPath: $logoPath, ')
          ..write('habilitarPix: $habilitarPix, ')
          ..write('pixTipoChave: $pixTipoChave, ')
          ..write('pixChave: $pixChave, ')
          ..write('pixFavorecido: $pixFavorecido, ')
          ..write('pixBanco: $pixBanco, ')
          ..write('pixCidade: $pixCidade, ')
          ..write('pixMensagem: $pixMensagem, ')
          ..write('pixImprimirQrCode: $pixImprimirQrCode, ')
          ..write('pixImprimirCopiaCola: $pixImprimirCopiaCola, ')
          ..write('pixGerarQrCodeAuto: $pixGerarQrCodeAuto')
          ..write(')'))
        .toString();
  }
}

class $EventosPedidoTable extends EventosPedido
    with TableInfo<$EventosPedidoTable, EventosPedidoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventosPedidoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pedidoIdMeta =
      const VerificationMeta('pedidoId');
  @override
  late final GeneratedColumn<int> pedidoId = GeneratedColumn<int>(
      'pedido_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pedidos (id) ON DELETE CASCADE'));
  static const VerificationMeta _tipoEventoMeta =
      const VerificationMeta('tipoEvento');
  @override
  late final GeneratedColumn<String> tipoEvento = GeneratedColumn<String>(
      'tipo_evento', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
      'titulo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descricaoMeta =
      const VerificationMeta('descricao');
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
      'descricao', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _usuarioIdMeta =
      const VerificationMeta('usuarioId');
  @override
  late final GeneratedColumn<int> usuarioId = GeneratedColumn<int>(
      'usuario_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _usuarioNomeMeta =
      const VerificationMeta('usuarioNome');
  @override
  late final GeneratedColumn<String> usuarioNome = GeneratedColumn<String>(
      'usuario_nome', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Operador'));
  static const VerificationMeta _versaoMeta = const VerificationMeta('versao');
  @override
  late final GeneratedColumn<int> versao = GeneratedColumn<int>(
      'versao', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _criadoEmMeta =
      const VerificationMeta('criadoEm');
  @override
  late final GeneratedColumn<DateTime> criadoEm = GeneratedColumn<DateTime>(
      'criado_em', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pedidoId,
        tipoEvento,
        titulo,
        descricao,
        usuarioId,
        usuarioNome,
        versao,
        criadoEm
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eventos_pedido';
  @override
  VerificationContext validateIntegrity(Insertable<EventosPedidoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pedido_id')) {
      context.handle(_pedidoIdMeta,
          pedidoId.isAcceptableOrUnknown(data['pedido_id']!, _pedidoIdMeta));
    } else if (isInserting) {
      context.missing(_pedidoIdMeta);
    }
    if (data.containsKey('tipo_evento')) {
      context.handle(
          _tipoEventoMeta,
          tipoEvento.isAcceptableOrUnknown(
              data['tipo_evento']!, _tipoEventoMeta));
    } else if (isInserting) {
      context.missing(_tipoEventoMeta);
    }
    if (data.containsKey('titulo')) {
      context.handle(_tituloMeta,
          titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta));
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(_descricaoMeta,
          descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta));
    }
    if (data.containsKey('usuario_id')) {
      context.handle(_usuarioIdMeta,
          usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta));
    }
    if (data.containsKey('usuario_nome')) {
      context.handle(
          _usuarioNomeMeta,
          usuarioNome.isAcceptableOrUnknown(
              data['usuario_nome']!, _usuarioNomeMeta));
    }
    if (data.containsKey('versao')) {
      context.handle(_versaoMeta,
          versao.isAcceptableOrUnknown(data['versao']!, _versaoMeta));
    }
    if (data.containsKey('criado_em')) {
      context.handle(_criadoEmMeta,
          criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventosPedidoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventosPedidoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pedidoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pedido_id'])!,
      tipoEvento: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo_evento'])!,
      titulo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}titulo'])!,
      descricao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descricao'])!,
      usuarioId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usuario_id']),
      usuarioNome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}usuario_nome'])!,
      versao: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}versao'])!,
      criadoEm: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}criado_em'])!,
    );
  }

  @override
  $EventosPedidoTable createAlias(String alias) {
    return $EventosPedidoTable(attachedDatabase, alias);
  }
}

class EventosPedidoData extends DataClass
    implements Insertable<EventosPedidoData> {
  final int id;
  final int pedidoId;
  final String tipoEvento;
  final String titulo;
  final String descricao;
  final int? usuarioId;
  final String usuarioNome;
  final int versao;
  final DateTime criadoEm;
  const EventosPedidoData(
      {required this.id,
      required this.pedidoId,
      required this.tipoEvento,
      required this.titulo,
      required this.descricao,
      this.usuarioId,
      required this.usuarioNome,
      required this.versao,
      required this.criadoEm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pedido_id'] = Variable<int>(pedidoId);
    map['tipo_evento'] = Variable<String>(tipoEvento);
    map['titulo'] = Variable<String>(titulo);
    map['descricao'] = Variable<String>(descricao);
    if (!nullToAbsent || usuarioId != null) {
      map['usuario_id'] = Variable<int>(usuarioId);
    }
    map['usuario_nome'] = Variable<String>(usuarioNome);
    map['versao'] = Variable<int>(versao);
    map['criado_em'] = Variable<DateTime>(criadoEm);
    return map;
  }

  EventosPedidoCompanion toCompanion(bool nullToAbsent) {
    return EventosPedidoCompanion(
      id: Value(id),
      pedidoId: Value(pedidoId),
      tipoEvento: Value(tipoEvento),
      titulo: Value(titulo),
      descricao: Value(descricao),
      usuarioId: usuarioId == null && nullToAbsent
          ? const Value.absent()
          : Value(usuarioId),
      usuarioNome: Value(usuarioNome),
      versao: Value(versao),
      criadoEm: Value(criadoEm),
    );
  }

  factory EventosPedidoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventosPedidoData(
      id: serializer.fromJson<int>(json['id']),
      pedidoId: serializer.fromJson<int>(json['pedidoId']),
      tipoEvento: serializer.fromJson<String>(json['tipoEvento']),
      titulo: serializer.fromJson<String>(json['titulo']),
      descricao: serializer.fromJson<String>(json['descricao']),
      usuarioId: serializer.fromJson<int?>(json['usuarioId']),
      usuarioNome: serializer.fromJson<String>(json['usuarioNome']),
      versao: serializer.fromJson<int>(json['versao']),
      criadoEm: serializer.fromJson<DateTime>(json['criadoEm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pedidoId': serializer.toJson<int>(pedidoId),
      'tipoEvento': serializer.toJson<String>(tipoEvento),
      'titulo': serializer.toJson<String>(titulo),
      'descricao': serializer.toJson<String>(descricao),
      'usuarioId': serializer.toJson<int?>(usuarioId),
      'usuarioNome': serializer.toJson<String>(usuarioNome),
      'versao': serializer.toJson<int>(versao),
      'criadoEm': serializer.toJson<DateTime>(criadoEm),
    };
  }

  EventosPedidoData copyWith(
          {int? id,
          int? pedidoId,
          String? tipoEvento,
          String? titulo,
          String? descricao,
          Value<int?> usuarioId = const Value.absent(),
          String? usuarioNome,
          int? versao,
          DateTime? criadoEm}) =>
      EventosPedidoData(
        id: id ?? this.id,
        pedidoId: pedidoId ?? this.pedidoId,
        tipoEvento: tipoEvento ?? this.tipoEvento,
        titulo: titulo ?? this.titulo,
        descricao: descricao ?? this.descricao,
        usuarioId: usuarioId.present ? usuarioId.value : this.usuarioId,
        usuarioNome: usuarioNome ?? this.usuarioNome,
        versao: versao ?? this.versao,
        criadoEm: criadoEm ?? this.criadoEm,
      );
  EventosPedidoData copyWithCompanion(EventosPedidoCompanion data) {
    return EventosPedidoData(
      id: data.id.present ? data.id.value : this.id,
      pedidoId: data.pedidoId.present ? data.pedidoId.value : this.pedidoId,
      tipoEvento:
          data.tipoEvento.present ? data.tipoEvento.value : this.tipoEvento,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      usuarioNome:
          data.usuarioNome.present ? data.usuarioNome.value : this.usuarioNome,
      versao: data.versao.present ? data.versao.value : this.versao,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventosPedidoData(')
          ..write('id: $id, ')
          ..write('pedidoId: $pedidoId, ')
          ..write('tipoEvento: $tipoEvento, ')
          ..write('titulo: $titulo, ')
          ..write('descricao: $descricao, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('usuarioNome: $usuarioNome, ')
          ..write('versao: $versao, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pedidoId, tipoEvento, titulo, descricao,
      usuarioId, usuarioNome, versao, criadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventosPedidoData &&
          other.id == this.id &&
          other.pedidoId == this.pedidoId &&
          other.tipoEvento == this.tipoEvento &&
          other.titulo == this.titulo &&
          other.descricao == this.descricao &&
          other.usuarioId == this.usuarioId &&
          other.usuarioNome == this.usuarioNome &&
          other.versao == this.versao &&
          other.criadoEm == this.criadoEm);
}

class EventosPedidoCompanion extends UpdateCompanion<EventosPedidoData> {
  final Value<int> id;
  final Value<int> pedidoId;
  final Value<String> tipoEvento;
  final Value<String> titulo;
  final Value<String> descricao;
  final Value<int?> usuarioId;
  final Value<String> usuarioNome;
  final Value<int> versao;
  final Value<DateTime> criadoEm;
  const EventosPedidoCompanion({
    this.id = const Value.absent(),
    this.pedidoId = const Value.absent(),
    this.tipoEvento = const Value.absent(),
    this.titulo = const Value.absent(),
    this.descricao = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.usuarioNome = const Value.absent(),
    this.versao = const Value.absent(),
    this.criadoEm = const Value.absent(),
  });
  EventosPedidoCompanion.insert({
    this.id = const Value.absent(),
    required int pedidoId,
    required String tipoEvento,
    required String titulo,
    this.descricao = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.usuarioNome = const Value.absent(),
    this.versao = const Value.absent(),
    this.criadoEm = const Value.absent(),
  })  : pedidoId = Value(pedidoId),
        tipoEvento = Value(tipoEvento),
        titulo = Value(titulo);
  static Insertable<EventosPedidoData> custom({
    Expression<int>? id,
    Expression<int>? pedidoId,
    Expression<String>? tipoEvento,
    Expression<String>? titulo,
    Expression<String>? descricao,
    Expression<int>? usuarioId,
    Expression<String>? usuarioNome,
    Expression<int>? versao,
    Expression<DateTime>? criadoEm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pedidoId != null) 'pedido_id': pedidoId,
      if (tipoEvento != null) 'tipo_evento': tipoEvento,
      if (titulo != null) 'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (usuarioNome != null) 'usuario_nome': usuarioNome,
      if (versao != null) 'versao': versao,
      if (criadoEm != null) 'criado_em': criadoEm,
    });
  }

  EventosPedidoCompanion copyWith(
      {Value<int>? id,
      Value<int>? pedidoId,
      Value<String>? tipoEvento,
      Value<String>? titulo,
      Value<String>? descricao,
      Value<int?>? usuarioId,
      Value<String>? usuarioNome,
      Value<int>? versao,
      Value<DateTime>? criadoEm}) {
    return EventosPedidoCompanion(
      id: id ?? this.id,
      pedidoId: pedidoId ?? this.pedidoId,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      versao: versao ?? this.versao,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pedidoId.present) {
      map['pedido_id'] = Variable<int>(pedidoId.value);
    }
    if (tipoEvento.present) {
      map['tipo_evento'] = Variable<String>(tipoEvento.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<int>(usuarioId.value);
    }
    if (usuarioNome.present) {
      map['usuario_nome'] = Variable<String>(usuarioNome.value);
    }
    if (versao.present) {
      map['versao'] = Variable<int>(versao.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<DateTime>(criadoEm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventosPedidoCompanion(')
          ..write('id: $id, ')
          ..write('pedidoId: $pedidoId, ')
          ..write('tipoEvento: $tipoEvento, ')
          ..write('titulo: $titulo, ')
          ..write('descricao: $descricao, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('usuarioNome: $usuarioNome, ')
          ..write('versao: $versao, ')
          ..write('criadoEm: $criadoEm')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GruposPrecoTable gruposPreco = $GruposPrecoTable(this);
  late final $ProdutosTable produtos = $ProdutosTable(this);
  late final $FaixasPrecoTable faixasPreco = $FaixasPrecoTable(this);
  late final $ClientesTable clientes = $ClientesTable(this);
  late final $LocaisEntregaTable locaisEntrega = $LocaisEntregaTable(this);
  late final $OrigensPedidoTable origensPedido = $OrigensPedidoTable(this);
  late final $PrioridadesPedidoTable prioridadesPedido =
      $PrioridadesPedidoTable(this);
  late final $PedidosTable pedidos = $PedidosTable(this);
  late final $ItensPedidoTable itensPedido = $ItensPedidoTable(this);
  late final $EstoqueAtualTable estoqueAtual = $EstoqueAtualTable(this);
  late final $MovimentacoesEstoqueTable movimentacoesEstoque =
      $MovimentacoesEstoqueTable(this);
  late final $ConfiguracoesEmpresaTable configuracoesEmpresa =
      $ConfiguracoesEmpresaTable(this);
  late final $EventosPedidoTable eventosPedido = $EventosPedidoTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        gruposPreco,
        produtos,
        faixasPreco,
        clientes,
        locaisEntrega,
        origensPedido,
        prioridadesPedido,
        pedidos,
        itensPedido,
        estoqueAtual,
        movimentacoesEstoque,
        configuracoesEmpresa,
        eventosPedido
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('produtos',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('faixas_preco', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('grupos_preco',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('faixas_preco', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('clientes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('locais_entrega', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('pedidos',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('itens_pedido', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('produtos',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('estoque_atual', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('pedidos',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('eventos_pedido', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$GruposPrecoTableCreateCompanionBuilder = GruposPrecoCompanion
    Function({
  Value<int> id,
  required String nome,
  Value<String> descricao,
  Value<bool> ativo,
});
typedef $$GruposPrecoTableUpdateCompanionBuilder = GruposPrecoCompanion
    Function({
  Value<int> id,
  Value<String> nome,
  Value<String> descricao,
  Value<bool> ativo,
});

final class $$GruposPrecoTableReferences
    extends BaseReferences<_$AppDatabase, $GruposPrecoTable, GruposPrecoData> {
  $$GruposPrecoTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProdutosTable, List<Produto>> _produtosRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.produtos,
          aliasName: $_aliasNameGenerator(
              db.gruposPreco.id, db.produtos.grupoPrecoId));

  $$ProdutosTableProcessedTableManager get produtosRefs {
    final manager = $$ProdutosTableTableManager($_db, $_db.produtos)
        .filter((f) => f.grupoPrecoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_produtosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FaixasPrecoTable, List<FaixasPrecoData>>
      _faixasPrecoRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.faixasPreco,
              aliasName: $_aliasNameGenerator(
                  db.gruposPreco.id, db.faixasPreco.grupoPrecoId));

  $$FaixasPrecoTableProcessedTableManager get faixasPrecoRefs {
    final manager = $$FaixasPrecoTableTableManager($_db, $_db.faixasPreco)
        .filter((f) => f.grupoPrecoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_faixasPrecoRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GruposPrecoTableFilterComposer
    extends Composer<_$AppDatabase, $GruposPrecoTable> {
  $$GruposPrecoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnFilters(column));

  Expression<bool> produtosRefs(
      Expression<bool> Function($$ProdutosTableFilterComposer f) f) {
    final $$ProdutosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.grupoPrecoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableFilterComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> faixasPrecoRefs(
      Expression<bool> Function($$FaixasPrecoTableFilterComposer f) f) {
    final $$FaixasPrecoTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.faixasPreco,
        getReferencedColumn: (t) => t.grupoPrecoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FaixasPrecoTableFilterComposer(
              $db: $db,
              $table: $db.faixasPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GruposPrecoTableOrderingComposer
    extends Composer<_$AppDatabase, $GruposPrecoTable> {
  $$GruposPrecoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnOrderings(column));
}

class $$GruposPrecoTableAnnotationComposer
    extends Composer<_$AppDatabase, $GruposPrecoTable> {
  $$GruposPrecoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  Expression<T> produtosRefs<T extends Object>(
      Expression<T> Function($$ProdutosTableAnnotationComposer a) f) {
    final $$ProdutosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.grupoPrecoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableAnnotationComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> faixasPrecoRefs<T extends Object>(
      Expression<T> Function($$FaixasPrecoTableAnnotationComposer a) f) {
    final $$FaixasPrecoTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.faixasPreco,
        getReferencedColumn: (t) => t.grupoPrecoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FaixasPrecoTableAnnotationComposer(
              $db: $db,
              $table: $db.faixasPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GruposPrecoTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GruposPrecoTable,
    GruposPrecoData,
    $$GruposPrecoTableFilterComposer,
    $$GruposPrecoTableOrderingComposer,
    $$GruposPrecoTableAnnotationComposer,
    $$GruposPrecoTableCreateCompanionBuilder,
    $$GruposPrecoTableUpdateCompanionBuilder,
    (GruposPrecoData, $$GruposPrecoTableReferences),
    GruposPrecoData,
    PrefetchHooks Function({bool produtosRefs, bool faixasPrecoRefs})> {
  $$GruposPrecoTableTableManager(_$AppDatabase db, $GruposPrecoTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GruposPrecoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GruposPrecoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GruposPrecoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String> descricao = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              GruposPrecoCompanion(
            id: id,
            nome: nome,
            descricao: descricao,
            ativo: ativo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
            Value<String> descricao = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              GruposPrecoCompanion.insert(
            id: id,
            nome: nome,
            descricao: descricao,
            ativo: ativo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GruposPrecoTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {produtosRefs = false, faixasPrecoRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (produtosRefs) db.produtos,
                if (faixasPrecoRefs) db.faixasPreco
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (produtosRefs)
                    await $_getPrefetchedData<GruposPrecoData,
                            $GruposPrecoTable, Produto>(
                        currentTable: table,
                        referencedTable:
                            $$GruposPrecoTableReferences._produtosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GruposPrecoTableReferences(db, table, p0)
                                .produtosRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.grupoPrecoId == item.id),
                        typedResults: items),
                  if (faixasPrecoRefs)
                    await $_getPrefetchedData<GruposPrecoData,
                            $GruposPrecoTable, FaixasPrecoData>(
                        currentTable: table,
                        referencedTable: $$GruposPrecoTableReferences
                            ._faixasPrecoRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GruposPrecoTableReferences(db, table, p0)
                                .faixasPrecoRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.grupoPrecoId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$GruposPrecoTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GruposPrecoTable,
    GruposPrecoData,
    $$GruposPrecoTableFilterComposer,
    $$GruposPrecoTableOrderingComposer,
    $$GruposPrecoTableAnnotationComposer,
    $$GruposPrecoTableCreateCompanionBuilder,
    $$GruposPrecoTableUpdateCompanionBuilder,
    (GruposPrecoData, $$GruposPrecoTableReferences),
    GruposPrecoData,
    PrefetchHooks Function({bool produtosRefs, bool faixasPrecoRefs})>;
typedef $$ProdutosTableCreateCompanionBuilder = ProdutosCompanion Function({
  Value<int> id,
  required String nome,
  Value<String> categoria,
  Value<int?> grupoPrecoId,
  Value<int> tempoMedioMinutos,
  Value<bool> controlaEstoque,
  Value<int> ordemProducao,
  Value<bool> ativo,
});
typedef $$ProdutosTableUpdateCompanionBuilder = ProdutosCompanion Function({
  Value<int> id,
  Value<String> nome,
  Value<String> categoria,
  Value<int?> grupoPrecoId,
  Value<int> tempoMedioMinutos,
  Value<bool> controlaEstoque,
  Value<int> ordemProducao,
  Value<bool> ativo,
});

final class $$ProdutosTableReferences
    extends BaseReferences<_$AppDatabase, $ProdutosTable, Produto> {
  $$ProdutosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GruposPrecoTable _grupoPrecoIdTable(_$AppDatabase db) =>
      db.gruposPreco.createAlias(
          $_aliasNameGenerator(db.produtos.grupoPrecoId, db.gruposPreco.id));

  $$GruposPrecoTableProcessedTableManager? get grupoPrecoId {
    final $_column = $_itemColumn<int>('grupo_preco_id');
    if ($_column == null) return null;
    final manager = $$GruposPrecoTableTableManager($_db, $_db.gruposPreco)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_grupoPrecoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$FaixasPrecoTable, List<FaixasPrecoData>>
      _faixasPrecoRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.faixasPreco,
          aliasName:
              $_aliasNameGenerator(db.produtos.id, db.faixasPreco.produtoId));

  $$FaixasPrecoTableProcessedTableManager get faixasPrecoRefs {
    final manager = $$FaixasPrecoTableTableManager($_db, $_db.faixasPreco)
        .filter((f) => f.produtoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_faixasPrecoRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ItensPedidoTable, List<ItensPedidoData>>
      _itensPedidoRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.itensPedido,
          aliasName:
              $_aliasNameGenerator(db.produtos.id, db.itensPedido.produtoId));

  $$ItensPedidoTableProcessedTableManager get itensPedidoRefs {
    final manager = $$ItensPedidoTableTableManager($_db, $_db.itensPedido)
        .filter((f) => f.produtoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itensPedidoRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EstoqueAtualTable, List<EstoqueAtualData>>
      _estoqueAtualRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.estoqueAtual,
          aliasName:
              $_aliasNameGenerator(db.produtos.id, db.estoqueAtual.produtoId));

  $$EstoqueAtualTableProcessedTableManager get estoqueAtualRefs {
    final manager = $$EstoqueAtualTableTableManager($_db, $_db.estoqueAtual)
        .filter((f) => f.produtoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_estoqueAtualRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MovimentacoesEstoqueTable,
      List<MovimentacoesEstoqueData>> _movimentacoesEstoqueRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.movimentacoesEstoque,
          aliasName: $_aliasNameGenerator(
              db.produtos.id, db.movimentacoesEstoque.produtoId));

  $$MovimentacoesEstoqueTableProcessedTableManager
      get movimentacoesEstoqueRefs {
    final manager =
        $$MovimentacoesEstoqueTableTableManager($_db, $_db.movimentacoesEstoque)
            .filter((f) => f.produtoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_movimentacoesEstoqueRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProdutosTableFilterComposer
    extends Composer<_$AppDatabase, $ProdutosTable> {
  $$ProdutosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoria => $composableBuilder(
      column: $table.categoria, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tempoMedioMinutos => $composableBuilder(
      column: $table.tempoMedioMinutos,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get controlaEstoque => $composableBuilder(
      column: $table.controlaEstoque,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ordemProducao => $composableBuilder(
      column: $table.ordemProducao, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnFilters(column));

  $$GruposPrecoTableFilterComposer get grupoPrecoId {
    final $$GruposPrecoTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.grupoPrecoId,
        referencedTable: $db.gruposPreco,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GruposPrecoTableFilterComposer(
              $db: $db,
              $table: $db.gruposPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> faixasPrecoRefs(
      Expression<bool> Function($$FaixasPrecoTableFilterComposer f) f) {
    final $$FaixasPrecoTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.faixasPreco,
        getReferencedColumn: (t) => t.produtoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FaixasPrecoTableFilterComposer(
              $db: $db,
              $table: $db.faixasPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> itensPedidoRefs(
      Expression<bool> Function($$ItensPedidoTableFilterComposer f) f) {
    final $$ItensPedidoTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensPedido,
        getReferencedColumn: (t) => t.produtoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensPedidoTableFilterComposer(
              $db: $db,
              $table: $db.itensPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> estoqueAtualRefs(
      Expression<bool> Function($$EstoqueAtualTableFilterComposer f) f) {
    final $$EstoqueAtualTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.estoqueAtual,
        getReferencedColumn: (t) => t.produtoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EstoqueAtualTableFilterComposer(
              $db: $db,
              $table: $db.estoqueAtual,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> movimentacoesEstoqueRefs(
      Expression<bool> Function($$MovimentacoesEstoqueTableFilterComposer f)
          f) {
    final $$MovimentacoesEstoqueTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.movimentacoesEstoque,
        getReferencedColumn: (t) => t.produtoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MovimentacoesEstoqueTableFilterComposer(
              $db: $db,
              $table: $db.movimentacoesEstoque,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProdutosTableOrderingComposer
    extends Composer<_$AppDatabase, $ProdutosTable> {
  $$ProdutosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoria => $composableBuilder(
      column: $table.categoria, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tempoMedioMinutos => $composableBuilder(
      column: $table.tempoMedioMinutos,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get controlaEstoque => $composableBuilder(
      column: $table.controlaEstoque,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ordemProducao => $composableBuilder(
      column: $table.ordemProducao,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnOrderings(column));

  $$GruposPrecoTableOrderingComposer get grupoPrecoId {
    final $$GruposPrecoTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.grupoPrecoId,
        referencedTable: $db.gruposPreco,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GruposPrecoTableOrderingComposer(
              $db: $db,
              $table: $db.gruposPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProdutosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProdutosTable> {
  $$ProdutosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<int> get tempoMedioMinutos => $composableBuilder(
      column: $table.tempoMedioMinutos, builder: (column) => column);

  GeneratedColumn<bool> get controlaEstoque => $composableBuilder(
      column: $table.controlaEstoque, builder: (column) => column);

  GeneratedColumn<int> get ordemProducao => $composableBuilder(
      column: $table.ordemProducao, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  $$GruposPrecoTableAnnotationComposer get grupoPrecoId {
    final $$GruposPrecoTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.grupoPrecoId,
        referencedTable: $db.gruposPreco,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GruposPrecoTableAnnotationComposer(
              $db: $db,
              $table: $db.gruposPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> faixasPrecoRefs<T extends Object>(
      Expression<T> Function($$FaixasPrecoTableAnnotationComposer a) f) {
    final $$FaixasPrecoTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.faixasPreco,
        getReferencedColumn: (t) => t.produtoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FaixasPrecoTableAnnotationComposer(
              $db: $db,
              $table: $db.faixasPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> itensPedidoRefs<T extends Object>(
      Expression<T> Function($$ItensPedidoTableAnnotationComposer a) f) {
    final $$ItensPedidoTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensPedido,
        getReferencedColumn: (t) => t.produtoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensPedidoTableAnnotationComposer(
              $db: $db,
              $table: $db.itensPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> estoqueAtualRefs<T extends Object>(
      Expression<T> Function($$EstoqueAtualTableAnnotationComposer a) f) {
    final $$EstoqueAtualTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.estoqueAtual,
        getReferencedColumn: (t) => t.produtoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EstoqueAtualTableAnnotationComposer(
              $db: $db,
              $table: $db.estoqueAtual,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> movimentacoesEstoqueRefs<T extends Object>(
      Expression<T> Function($$MovimentacoesEstoqueTableAnnotationComposer a)
          f) {
    final $$MovimentacoesEstoqueTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.movimentacoesEstoque,
            getReferencedColumn: (t) => t.produtoId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$MovimentacoesEstoqueTableAnnotationComposer(
                  $db: $db,
                  $table: $db.movimentacoesEstoque,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ProdutosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProdutosTable,
    Produto,
    $$ProdutosTableFilterComposer,
    $$ProdutosTableOrderingComposer,
    $$ProdutosTableAnnotationComposer,
    $$ProdutosTableCreateCompanionBuilder,
    $$ProdutosTableUpdateCompanionBuilder,
    (Produto, $$ProdutosTableReferences),
    Produto,
    PrefetchHooks Function(
        {bool grupoPrecoId,
        bool faixasPrecoRefs,
        bool itensPedidoRefs,
        bool estoqueAtualRefs,
        bool movimentacoesEstoqueRefs})> {
  $$ProdutosTableTableManager(_$AppDatabase db, $ProdutosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProdutosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProdutosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProdutosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String> categoria = const Value.absent(),
            Value<int?> grupoPrecoId = const Value.absent(),
            Value<int> tempoMedioMinutos = const Value.absent(),
            Value<bool> controlaEstoque = const Value.absent(),
            Value<int> ordemProducao = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              ProdutosCompanion(
            id: id,
            nome: nome,
            categoria: categoria,
            grupoPrecoId: grupoPrecoId,
            tempoMedioMinutos: tempoMedioMinutos,
            controlaEstoque: controlaEstoque,
            ordemProducao: ordemProducao,
            ativo: ativo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
            Value<String> categoria = const Value.absent(),
            Value<int?> grupoPrecoId = const Value.absent(),
            Value<int> tempoMedioMinutos = const Value.absent(),
            Value<bool> controlaEstoque = const Value.absent(),
            Value<int> ordemProducao = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              ProdutosCompanion.insert(
            id: id,
            nome: nome,
            categoria: categoria,
            grupoPrecoId: grupoPrecoId,
            tempoMedioMinutos: tempoMedioMinutos,
            controlaEstoque: controlaEstoque,
            ordemProducao: ordemProducao,
            ativo: ativo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProdutosTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {grupoPrecoId = false,
              faixasPrecoRefs = false,
              itensPedidoRefs = false,
              estoqueAtualRefs = false,
              movimentacoesEstoqueRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (faixasPrecoRefs) db.faixasPreco,
                if (itensPedidoRefs) db.itensPedido,
                if (estoqueAtualRefs) db.estoqueAtual,
                if (movimentacoesEstoqueRefs) db.movimentacoesEstoque
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (grupoPrecoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.grupoPrecoId,
                    referencedTable:
                        $$ProdutosTableReferences._grupoPrecoIdTable(db),
                    referencedColumn:
                        $$ProdutosTableReferences._grupoPrecoIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (faixasPrecoRefs)
                    await $_getPrefetchedData<Produto, $ProdutosTable,
                            FaixasPrecoData>(
                        currentTable: table,
                        referencedTable:
                            $$ProdutosTableReferences._faixasPrecoRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProdutosTableReferences(db, table, p0)
                                .faixasPrecoRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.produtoId == item.id),
                        typedResults: items),
                  if (itensPedidoRefs)
                    await $_getPrefetchedData<Produto, $ProdutosTable,
                            ItensPedidoData>(
                        currentTable: table,
                        referencedTable:
                            $$ProdutosTableReferences._itensPedidoRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProdutosTableReferences(db, table, p0)
                                .itensPedidoRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.produtoId == item.id),
                        typedResults: items),
                  if (estoqueAtualRefs)
                    await $_getPrefetchedData<Produto, $ProdutosTable,
                            EstoqueAtualData>(
                        currentTable: table,
                        referencedTable: $$ProdutosTableReferences
                            ._estoqueAtualRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProdutosTableReferences(db, table, p0)
                                .estoqueAtualRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.produtoId == item.id),
                        typedResults: items),
                  if (movimentacoesEstoqueRefs)
                    await $_getPrefetchedData<Produto, $ProdutosTable, MovimentacoesEstoqueData>(
                        currentTable: table,
                        referencedTable: $$ProdutosTableReferences
                            ._movimentacoesEstoqueRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProdutosTableReferences(db, table, p0)
                                .movimentacoesEstoqueRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.produtoId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProdutosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProdutosTable,
    Produto,
    $$ProdutosTableFilterComposer,
    $$ProdutosTableOrderingComposer,
    $$ProdutosTableAnnotationComposer,
    $$ProdutosTableCreateCompanionBuilder,
    $$ProdutosTableUpdateCompanionBuilder,
    (Produto, $$ProdutosTableReferences),
    Produto,
    PrefetchHooks Function(
        {bool grupoPrecoId,
        bool faixasPrecoRefs,
        bool itensPedidoRefs,
        bool estoqueAtualRefs,
        bool movimentacoesEstoqueRefs})>;
typedef $$FaixasPrecoTableCreateCompanionBuilder = FaixasPrecoCompanion
    Function({
  Value<int> id,
  Value<int?> produtoId,
  Value<int?> grupoPrecoId,
  required int quantidadeMinima,
  Value<int?> quantidadeMaxima,
  required int valorUnitarioCentavos,
});
typedef $$FaixasPrecoTableUpdateCompanionBuilder = FaixasPrecoCompanion
    Function({
  Value<int> id,
  Value<int?> produtoId,
  Value<int?> grupoPrecoId,
  Value<int> quantidadeMinima,
  Value<int?> quantidadeMaxima,
  Value<int> valorUnitarioCentavos,
});

final class $$FaixasPrecoTableReferences
    extends BaseReferences<_$AppDatabase, $FaixasPrecoTable, FaixasPrecoData> {
  $$FaixasPrecoTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProdutosTable _produtoIdTable(_$AppDatabase db) =>
      db.produtos.createAlias(
          $_aliasNameGenerator(db.faixasPreco.produtoId, db.produtos.id));

  $$ProdutosTableProcessedTableManager? get produtoId {
    final $_column = $_itemColumn<int>('produto_id');
    if ($_column == null) return null;
    final manager = $$ProdutosTableTableManager($_db, $_db.produtos)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_produtoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $GruposPrecoTable _grupoPrecoIdTable(_$AppDatabase db) =>
      db.gruposPreco.createAlias(
          $_aliasNameGenerator(db.faixasPreco.grupoPrecoId, db.gruposPreco.id));

  $$GruposPrecoTableProcessedTableManager? get grupoPrecoId {
    final $_column = $_itemColumn<int>('grupo_preco_id');
    if ($_column == null) return null;
    final manager = $$GruposPrecoTableTableManager($_db, $_db.gruposPreco)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_grupoPrecoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FaixasPrecoTableFilterComposer
    extends Composer<_$AppDatabase, $FaixasPrecoTable> {
  $$FaixasPrecoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantidadeMinima => $composableBuilder(
      column: $table.quantidadeMinima,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantidadeMaxima => $composableBuilder(
      column: $table.quantidadeMaxima,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get valorUnitarioCentavos => $composableBuilder(
      column: $table.valorUnitarioCentavos,
      builder: (column) => ColumnFilters(column));

  $$ProdutosTableFilterComposer get produtoId {
    final $$ProdutosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableFilterComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GruposPrecoTableFilterComposer get grupoPrecoId {
    final $$GruposPrecoTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.grupoPrecoId,
        referencedTable: $db.gruposPreco,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GruposPrecoTableFilterComposer(
              $db: $db,
              $table: $db.gruposPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FaixasPrecoTableOrderingComposer
    extends Composer<_$AppDatabase, $FaixasPrecoTable> {
  $$FaixasPrecoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantidadeMinima => $composableBuilder(
      column: $table.quantidadeMinima,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantidadeMaxima => $composableBuilder(
      column: $table.quantidadeMaxima,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get valorUnitarioCentavos => $composableBuilder(
      column: $table.valorUnitarioCentavos,
      builder: (column) => ColumnOrderings(column));

  $$ProdutosTableOrderingComposer get produtoId {
    final $$ProdutosTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableOrderingComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GruposPrecoTableOrderingComposer get grupoPrecoId {
    final $$GruposPrecoTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.grupoPrecoId,
        referencedTable: $db.gruposPreco,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GruposPrecoTableOrderingComposer(
              $db: $db,
              $table: $db.gruposPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FaixasPrecoTableAnnotationComposer
    extends Composer<_$AppDatabase, $FaixasPrecoTable> {
  $$FaixasPrecoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get quantidadeMinima => $composableBuilder(
      column: $table.quantidadeMinima, builder: (column) => column);

  GeneratedColumn<int> get quantidadeMaxima => $composableBuilder(
      column: $table.quantidadeMaxima, builder: (column) => column);

  GeneratedColumn<int> get valorUnitarioCentavos => $composableBuilder(
      column: $table.valorUnitarioCentavos, builder: (column) => column);

  $$ProdutosTableAnnotationComposer get produtoId {
    final $$ProdutosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableAnnotationComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GruposPrecoTableAnnotationComposer get grupoPrecoId {
    final $$GruposPrecoTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.grupoPrecoId,
        referencedTable: $db.gruposPreco,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GruposPrecoTableAnnotationComposer(
              $db: $db,
              $table: $db.gruposPreco,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FaixasPrecoTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FaixasPrecoTable,
    FaixasPrecoData,
    $$FaixasPrecoTableFilterComposer,
    $$FaixasPrecoTableOrderingComposer,
    $$FaixasPrecoTableAnnotationComposer,
    $$FaixasPrecoTableCreateCompanionBuilder,
    $$FaixasPrecoTableUpdateCompanionBuilder,
    (FaixasPrecoData, $$FaixasPrecoTableReferences),
    FaixasPrecoData,
    PrefetchHooks Function({bool produtoId, bool grupoPrecoId})> {
  $$FaixasPrecoTableTableManager(_$AppDatabase db, $FaixasPrecoTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FaixasPrecoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FaixasPrecoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FaixasPrecoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> produtoId = const Value.absent(),
            Value<int?> grupoPrecoId = const Value.absent(),
            Value<int> quantidadeMinima = const Value.absent(),
            Value<int?> quantidadeMaxima = const Value.absent(),
            Value<int> valorUnitarioCentavos = const Value.absent(),
          }) =>
              FaixasPrecoCompanion(
            id: id,
            produtoId: produtoId,
            grupoPrecoId: grupoPrecoId,
            quantidadeMinima: quantidadeMinima,
            quantidadeMaxima: quantidadeMaxima,
            valorUnitarioCentavos: valorUnitarioCentavos,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> produtoId = const Value.absent(),
            Value<int?> grupoPrecoId = const Value.absent(),
            required int quantidadeMinima,
            Value<int?> quantidadeMaxima = const Value.absent(),
            required int valorUnitarioCentavos,
          }) =>
              FaixasPrecoCompanion.insert(
            id: id,
            produtoId: produtoId,
            grupoPrecoId: grupoPrecoId,
            quantidadeMinima: quantidadeMinima,
            quantidadeMaxima: quantidadeMaxima,
            valorUnitarioCentavos: valorUnitarioCentavos,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FaixasPrecoTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({produtoId = false, grupoPrecoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (produtoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.produtoId,
                    referencedTable:
                        $$FaixasPrecoTableReferences._produtoIdTable(db),
                    referencedColumn:
                        $$FaixasPrecoTableReferences._produtoIdTable(db).id,
                  ) as T;
                }
                if (grupoPrecoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.grupoPrecoId,
                    referencedTable:
                        $$FaixasPrecoTableReferences._grupoPrecoIdTable(db),
                    referencedColumn:
                        $$FaixasPrecoTableReferences._grupoPrecoIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FaixasPrecoTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FaixasPrecoTable,
    FaixasPrecoData,
    $$FaixasPrecoTableFilterComposer,
    $$FaixasPrecoTableOrderingComposer,
    $$FaixasPrecoTableAnnotationComposer,
    $$FaixasPrecoTableCreateCompanionBuilder,
    $$FaixasPrecoTableUpdateCompanionBuilder,
    (FaixasPrecoData, $$FaixasPrecoTableReferences),
    FaixasPrecoData,
    PrefetchHooks Function({bool produtoId, bool grupoPrecoId})>;
typedef $$ClientesTableCreateCompanionBuilder = ClientesCompanion Function({
  Value<int> id,
  required String nome,
  Value<String> telefone,
  Value<String> logradouro,
  Value<String> numero,
  Value<String> bairro,
  Value<String> cidade,
  Value<String> cep,
  Value<String> referencia,
  Value<String> observacoes,
  Value<bool> ativo,
});
typedef $$ClientesTableUpdateCompanionBuilder = ClientesCompanion Function({
  Value<int> id,
  Value<String> nome,
  Value<String> telefone,
  Value<String> logradouro,
  Value<String> numero,
  Value<String> bairro,
  Value<String> cidade,
  Value<String> cep,
  Value<String> referencia,
  Value<String> observacoes,
  Value<bool> ativo,
});

final class $$ClientesTableReferences
    extends BaseReferences<_$AppDatabase, $ClientesTable, Cliente> {
  $$ClientesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocaisEntregaTable, List<LocaisEntregaData>>
      _locaisEntregaRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.locaisEntrega,
              aliasName: $_aliasNameGenerator(
                  db.clientes.id, db.locaisEntrega.clienteId));

  $$LocaisEntregaTableProcessedTableManager get locaisEntregaRefs {
    final manager = $$LocaisEntregaTableTableManager($_db, $_db.locaisEntrega)
        .filter((f) => f.clienteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_locaisEntregaRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PedidosTable, List<Pedido>> _pedidosRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.pedidos,
          aliasName:
              $_aliasNameGenerator(db.clientes.id, db.pedidos.clienteId));

  $$PedidosTableProcessedTableManager get pedidosRefs {
    final manager = $$PedidosTableTableManager($_db, $_db.pedidos)
        .filter((f) => f.clienteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pedidosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ClientesTableFilterComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get telefone => $composableBuilder(
      column: $table.telefone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logradouro => $composableBuilder(
      column: $table.logradouro, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get numero => $composableBuilder(
      column: $table.numero, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bairro => $composableBuilder(
      column: $table.bairro, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cidade => $composableBuilder(
      column: $table.cidade, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cep => $composableBuilder(
      column: $table.cep, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referencia => $composableBuilder(
      column: $table.referencia, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnFilters(column));

  Expression<bool> locaisEntregaRefs(
      Expression<bool> Function($$LocaisEntregaTableFilterComposer f) f) {
    final $$LocaisEntregaTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.locaisEntrega,
        getReferencedColumn: (t) => t.clienteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocaisEntregaTableFilterComposer(
              $db: $db,
              $table: $db.locaisEntrega,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> pedidosRefs(
      Expression<bool> Function($$PedidosTableFilterComposer f) f) {
    final $$PedidosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.clienteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableFilterComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ClientesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get telefone => $composableBuilder(
      column: $table.telefone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logradouro => $composableBuilder(
      column: $table.logradouro, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get numero => $composableBuilder(
      column: $table.numero, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bairro => $composableBuilder(
      column: $table.bairro, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cidade => $composableBuilder(
      column: $table.cidade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cep => $composableBuilder(
      column: $table.cep, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referencia => $composableBuilder(
      column: $table.referencia, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnOrderings(column));
}

class $$ClientesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get telefone =>
      $composableBuilder(column: $table.telefone, builder: (column) => column);

  GeneratedColumn<String> get logradouro => $composableBuilder(
      column: $table.logradouro, builder: (column) => column);

  GeneratedColumn<String> get numero =>
      $composableBuilder(column: $table.numero, builder: (column) => column);

  GeneratedColumn<String> get bairro =>
      $composableBuilder(column: $table.bairro, builder: (column) => column);

  GeneratedColumn<String> get cidade =>
      $composableBuilder(column: $table.cidade, builder: (column) => column);

  GeneratedColumn<String> get cep =>
      $composableBuilder(column: $table.cep, builder: (column) => column);

  GeneratedColumn<String> get referencia => $composableBuilder(
      column: $table.referencia, builder: (column) => column);

  GeneratedColumn<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  Expression<T> locaisEntregaRefs<T extends Object>(
      Expression<T> Function($$LocaisEntregaTableAnnotationComposer a) f) {
    final $$LocaisEntregaTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.locaisEntrega,
        getReferencedColumn: (t) => t.clienteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocaisEntregaTableAnnotationComposer(
              $db: $db,
              $table: $db.locaisEntrega,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> pedidosRefs<T extends Object>(
      Expression<T> Function($$PedidosTableAnnotationComposer a) f) {
    final $$PedidosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.clienteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableAnnotationComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ClientesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClientesTable,
    Cliente,
    $$ClientesTableFilterComposer,
    $$ClientesTableOrderingComposer,
    $$ClientesTableAnnotationComposer,
    $$ClientesTableCreateCompanionBuilder,
    $$ClientesTableUpdateCompanionBuilder,
    (Cliente, $$ClientesTableReferences),
    Cliente,
    PrefetchHooks Function({bool locaisEntregaRefs, bool pedidosRefs})> {
  $$ClientesTableTableManager(_$AppDatabase db, $ClientesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String> telefone = const Value.absent(),
            Value<String> logradouro = const Value.absent(),
            Value<String> numero = const Value.absent(),
            Value<String> bairro = const Value.absent(),
            Value<String> cidade = const Value.absent(),
            Value<String> cep = const Value.absent(),
            Value<String> referencia = const Value.absent(),
            Value<String> observacoes = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              ClientesCompanion(
            id: id,
            nome: nome,
            telefone: telefone,
            logradouro: logradouro,
            numero: numero,
            bairro: bairro,
            cidade: cidade,
            cep: cep,
            referencia: referencia,
            observacoes: observacoes,
            ativo: ativo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
            Value<String> telefone = const Value.absent(),
            Value<String> logradouro = const Value.absent(),
            Value<String> numero = const Value.absent(),
            Value<String> bairro = const Value.absent(),
            Value<String> cidade = const Value.absent(),
            Value<String> cep = const Value.absent(),
            Value<String> referencia = const Value.absent(),
            Value<String> observacoes = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              ClientesCompanion.insert(
            id: id,
            nome: nome,
            telefone: telefone,
            logradouro: logradouro,
            numero: numero,
            bairro: bairro,
            cidade: cidade,
            cep: cep,
            referencia: referencia,
            observacoes: observacoes,
            ativo: ativo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ClientesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {locaisEntregaRefs = false, pedidosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (locaisEntregaRefs) db.locaisEntrega,
                if (pedidosRefs) db.pedidos
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (locaisEntregaRefs)
                    await $_getPrefetchedData<Cliente, $ClientesTable,
                            LocaisEntregaData>(
                        currentTable: table,
                        referencedTable: $$ClientesTableReferences
                            ._locaisEntregaRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClientesTableReferences(db, table, p0)
                                .locaisEntregaRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.clienteId == item.id),
                        typedResults: items),
                  if (pedidosRefs)
                    await $_getPrefetchedData<Cliente, $ClientesTable, Pedido>(
                        currentTable: table,
                        referencedTable:
                            $$ClientesTableReferences._pedidosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClientesTableReferences(db, table, p0)
                                .pedidosRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.clienteId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ClientesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClientesTable,
    Cliente,
    $$ClientesTableFilterComposer,
    $$ClientesTableOrderingComposer,
    $$ClientesTableAnnotationComposer,
    $$ClientesTableCreateCompanionBuilder,
    $$ClientesTableUpdateCompanionBuilder,
    (Cliente, $$ClientesTableReferences),
    Cliente,
    PrefetchHooks Function({bool locaisEntregaRefs, bool pedidosRefs})>;
typedef $$LocaisEntregaTableCreateCompanionBuilder = LocaisEntregaCompanion
    Function({
  Value<int> id,
  required int clienteId,
  Value<String> nomeIdentificador,
  required String logradouro,
  required String numero,
  required String bairro,
  Value<String> cidade,
  Value<String> cep,
  Value<String> referencia,
  Value<bool> ativo,
});
typedef $$LocaisEntregaTableUpdateCompanionBuilder = LocaisEntregaCompanion
    Function({
  Value<int> id,
  Value<int> clienteId,
  Value<String> nomeIdentificador,
  Value<String> logradouro,
  Value<String> numero,
  Value<String> bairro,
  Value<String> cidade,
  Value<String> cep,
  Value<String> referencia,
  Value<bool> ativo,
});

final class $$LocaisEntregaTableReferences extends BaseReferences<_$AppDatabase,
    $LocaisEntregaTable, LocaisEntregaData> {
  $$LocaisEntregaTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ClientesTable _clienteIdTable(_$AppDatabase db) =>
      db.clientes.createAlias(
          $_aliasNameGenerator(db.locaisEntrega.clienteId, db.clientes.id));

  $$ClientesTableProcessedTableManager get clienteId {
    final $_column = $_itemColumn<int>('cliente_id')!;

    final manager = $$ClientesTableTableManager($_db, $_db.clientes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clienteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocaisEntregaTableFilterComposer
    extends Composer<_$AppDatabase, $LocaisEntregaTable> {
  $$LocaisEntregaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nomeIdentificador => $composableBuilder(
      column: $table.nomeIdentificador,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logradouro => $composableBuilder(
      column: $table.logradouro, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get numero => $composableBuilder(
      column: $table.numero, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bairro => $composableBuilder(
      column: $table.bairro, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cidade => $composableBuilder(
      column: $table.cidade, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cep => $composableBuilder(
      column: $table.cep, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referencia => $composableBuilder(
      column: $table.referencia, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnFilters(column));

  $$ClientesTableFilterComposer get clienteId {
    final $$ClientesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clienteId,
        referencedTable: $db.clientes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientesTableFilterComposer(
              $db: $db,
              $table: $db.clientes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocaisEntregaTableOrderingComposer
    extends Composer<_$AppDatabase, $LocaisEntregaTable> {
  $$LocaisEntregaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nomeIdentificador => $composableBuilder(
      column: $table.nomeIdentificador,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logradouro => $composableBuilder(
      column: $table.logradouro, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get numero => $composableBuilder(
      column: $table.numero, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bairro => $composableBuilder(
      column: $table.bairro, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cidade => $composableBuilder(
      column: $table.cidade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cep => $composableBuilder(
      column: $table.cep, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referencia => $composableBuilder(
      column: $table.referencia, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnOrderings(column));

  $$ClientesTableOrderingComposer get clienteId {
    final $$ClientesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clienteId,
        referencedTable: $db.clientes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientesTableOrderingComposer(
              $db: $db,
              $table: $db.clientes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocaisEntregaTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocaisEntregaTable> {
  $$LocaisEntregaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nomeIdentificador => $composableBuilder(
      column: $table.nomeIdentificador, builder: (column) => column);

  GeneratedColumn<String> get logradouro => $composableBuilder(
      column: $table.logradouro, builder: (column) => column);

  GeneratedColumn<String> get numero =>
      $composableBuilder(column: $table.numero, builder: (column) => column);

  GeneratedColumn<String> get bairro =>
      $composableBuilder(column: $table.bairro, builder: (column) => column);

  GeneratedColumn<String> get cidade =>
      $composableBuilder(column: $table.cidade, builder: (column) => column);

  GeneratedColumn<String> get cep =>
      $composableBuilder(column: $table.cep, builder: (column) => column);

  GeneratedColumn<String> get referencia => $composableBuilder(
      column: $table.referencia, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  $$ClientesTableAnnotationComposer get clienteId {
    final $$ClientesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clienteId,
        referencedTable: $db.clientes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientesTableAnnotationComposer(
              $db: $db,
              $table: $db.clientes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocaisEntregaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocaisEntregaTable,
    LocaisEntregaData,
    $$LocaisEntregaTableFilterComposer,
    $$LocaisEntregaTableOrderingComposer,
    $$LocaisEntregaTableAnnotationComposer,
    $$LocaisEntregaTableCreateCompanionBuilder,
    $$LocaisEntregaTableUpdateCompanionBuilder,
    (LocaisEntregaData, $$LocaisEntregaTableReferences),
    LocaisEntregaData,
    PrefetchHooks Function({bool clienteId})> {
  $$LocaisEntregaTableTableManager(_$AppDatabase db, $LocaisEntregaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocaisEntregaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocaisEntregaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocaisEntregaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> clienteId = const Value.absent(),
            Value<String> nomeIdentificador = const Value.absent(),
            Value<String> logradouro = const Value.absent(),
            Value<String> numero = const Value.absent(),
            Value<String> bairro = const Value.absent(),
            Value<String> cidade = const Value.absent(),
            Value<String> cep = const Value.absent(),
            Value<String> referencia = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              LocaisEntregaCompanion(
            id: id,
            clienteId: clienteId,
            nomeIdentificador: nomeIdentificador,
            logradouro: logradouro,
            numero: numero,
            bairro: bairro,
            cidade: cidade,
            cep: cep,
            referencia: referencia,
            ativo: ativo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int clienteId,
            Value<String> nomeIdentificador = const Value.absent(),
            required String logradouro,
            required String numero,
            required String bairro,
            Value<String> cidade = const Value.absent(),
            Value<String> cep = const Value.absent(),
            Value<String> referencia = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              LocaisEntregaCompanion.insert(
            id: id,
            clienteId: clienteId,
            nomeIdentificador: nomeIdentificador,
            logradouro: logradouro,
            numero: numero,
            bairro: bairro,
            cidade: cidade,
            cep: cep,
            referencia: referencia,
            ativo: ativo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocaisEntregaTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({clienteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (clienteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.clienteId,
                    referencedTable:
                        $$LocaisEntregaTableReferences._clienteIdTable(db),
                    referencedColumn:
                        $$LocaisEntregaTableReferences._clienteIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocaisEntregaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocaisEntregaTable,
    LocaisEntregaData,
    $$LocaisEntregaTableFilterComposer,
    $$LocaisEntregaTableOrderingComposer,
    $$LocaisEntregaTableAnnotationComposer,
    $$LocaisEntregaTableCreateCompanionBuilder,
    $$LocaisEntregaTableUpdateCompanionBuilder,
    (LocaisEntregaData, $$LocaisEntregaTableReferences),
    LocaisEntregaData,
    PrefetchHooks Function({bool clienteId})>;
typedef $$OrigensPedidoTableCreateCompanionBuilder = OrigensPedidoCompanion
    Function({
  Value<int> id,
  required String nome,
  Value<String?> icone,
  Value<bool> ativo,
});
typedef $$OrigensPedidoTableUpdateCompanionBuilder = OrigensPedidoCompanion
    Function({
  Value<int> id,
  Value<String> nome,
  Value<String?> icone,
  Value<bool> ativo,
});

final class $$OrigensPedidoTableReferences extends BaseReferences<_$AppDatabase,
    $OrigensPedidoTable, OrigensPedidoData> {
  $$OrigensPedidoTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PedidosTable, List<Pedido>> _pedidosRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.pedidos,
          aliasName:
              $_aliasNameGenerator(db.origensPedido.id, db.pedidos.origemId));

  $$PedidosTableProcessedTableManager get pedidosRefs {
    final manager = $$PedidosTableTableManager($_db, $_db.pedidos)
        .filter((f) => f.origemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pedidosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OrigensPedidoTableFilterComposer
    extends Composer<_$AppDatabase, $OrigensPedidoTable> {
  $$OrigensPedidoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icone => $composableBuilder(
      column: $table.icone, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnFilters(column));

  Expression<bool> pedidosRefs(
      Expression<bool> Function($$PedidosTableFilterComposer f) f) {
    final $$PedidosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.origemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableFilterComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrigensPedidoTableOrderingComposer
    extends Composer<_$AppDatabase, $OrigensPedidoTable> {
  $$OrigensPedidoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icone => $composableBuilder(
      column: $table.icone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnOrderings(column));
}

class $$OrigensPedidoTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrigensPedidoTable> {
  $$OrigensPedidoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get icone =>
      $composableBuilder(column: $table.icone, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  Expression<T> pedidosRefs<T extends Object>(
      Expression<T> Function($$PedidosTableAnnotationComposer a) f) {
    final $$PedidosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.origemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableAnnotationComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrigensPedidoTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrigensPedidoTable,
    OrigensPedidoData,
    $$OrigensPedidoTableFilterComposer,
    $$OrigensPedidoTableOrderingComposer,
    $$OrigensPedidoTableAnnotationComposer,
    $$OrigensPedidoTableCreateCompanionBuilder,
    $$OrigensPedidoTableUpdateCompanionBuilder,
    (OrigensPedidoData, $$OrigensPedidoTableReferences),
    OrigensPedidoData,
    PrefetchHooks Function({bool pedidosRefs})> {
  $$OrigensPedidoTableTableManager(_$AppDatabase db, $OrigensPedidoTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrigensPedidoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrigensPedidoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrigensPedidoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String?> icone = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              OrigensPedidoCompanion(
            id: id,
            nome: nome,
            icone: icone,
            ativo: ativo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
            Value<String?> icone = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              OrigensPedidoCompanion.insert(
            id: id,
            nome: nome,
            icone: icone,
            ativo: ativo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$OrigensPedidoTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({pedidosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (pedidosRefs) db.pedidos],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pedidosRefs)
                    await $_getPrefetchedData<OrigensPedidoData, $OrigensPedidoTable,
                            Pedido>(
                        currentTable: table,
                        referencedTable: $$OrigensPedidoTableReferences
                            ._pedidosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrigensPedidoTableReferences(db, table, p0)
                                .pedidosRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.origemId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OrigensPedidoTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrigensPedidoTable,
    OrigensPedidoData,
    $$OrigensPedidoTableFilterComposer,
    $$OrigensPedidoTableOrderingComposer,
    $$OrigensPedidoTableAnnotationComposer,
    $$OrigensPedidoTableCreateCompanionBuilder,
    $$OrigensPedidoTableUpdateCompanionBuilder,
    (OrigensPedidoData, $$OrigensPedidoTableReferences),
    OrigensPedidoData,
    PrefetchHooks Function({bool pedidosRefs})>;
typedef $$PrioridadesPedidoTableCreateCompanionBuilder
    = PrioridadesPedidoCompanion Function({
  Value<int> id,
  required String nome,
  required String cor,
  Value<String?> icone,
  Value<int> ordem,
});
typedef $$PrioridadesPedidoTableUpdateCompanionBuilder
    = PrioridadesPedidoCompanion Function({
  Value<int> id,
  Value<String> nome,
  Value<String> cor,
  Value<String?> icone,
  Value<int> ordem,
});

final class $$PrioridadesPedidoTableReferences extends BaseReferences<
    _$AppDatabase, $PrioridadesPedidoTable, PrioridadesPedidoData> {
  $$PrioridadesPedidoTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PedidosTable, List<Pedido>> _pedidosRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.pedidos,
          aliasName: $_aliasNameGenerator(
              db.prioridadesPedido.id, db.pedidos.prioridadeId));

  $$PedidosTableProcessedTableManager get pedidosRefs {
    final manager = $$PedidosTableTableManager($_db, $_db.pedidos)
        .filter((f) => f.prioridadeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pedidosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PrioridadesPedidoTableFilterComposer
    extends Composer<_$AppDatabase, $PrioridadesPedidoTable> {
  $$PrioridadesPedidoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cor => $composableBuilder(
      column: $table.cor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icone => $composableBuilder(
      column: $table.icone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ordem => $composableBuilder(
      column: $table.ordem, builder: (column) => ColumnFilters(column));

  Expression<bool> pedidosRefs(
      Expression<bool> Function($$PedidosTableFilterComposer f) f) {
    final $$PedidosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.prioridadeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableFilterComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PrioridadesPedidoTableOrderingComposer
    extends Composer<_$AppDatabase, $PrioridadesPedidoTable> {
  $$PrioridadesPedidoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cor => $composableBuilder(
      column: $table.cor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icone => $composableBuilder(
      column: $table.icone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ordem => $composableBuilder(
      column: $table.ordem, builder: (column) => ColumnOrderings(column));
}

class $$PrioridadesPedidoTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrioridadesPedidoTable> {
  $$PrioridadesPedidoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get cor =>
      $composableBuilder(column: $table.cor, builder: (column) => column);

  GeneratedColumn<String> get icone =>
      $composableBuilder(column: $table.icone, builder: (column) => column);

  GeneratedColumn<int> get ordem =>
      $composableBuilder(column: $table.ordem, builder: (column) => column);

  Expression<T> pedidosRefs<T extends Object>(
      Expression<T> Function($$PedidosTableAnnotationComposer a) f) {
    final $$PedidosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.prioridadeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableAnnotationComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PrioridadesPedidoTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrioridadesPedidoTable,
    PrioridadesPedidoData,
    $$PrioridadesPedidoTableFilterComposer,
    $$PrioridadesPedidoTableOrderingComposer,
    $$PrioridadesPedidoTableAnnotationComposer,
    $$PrioridadesPedidoTableCreateCompanionBuilder,
    $$PrioridadesPedidoTableUpdateCompanionBuilder,
    (PrioridadesPedidoData, $$PrioridadesPedidoTableReferences),
    PrioridadesPedidoData,
    PrefetchHooks Function({bool pedidosRefs})> {
  $$PrioridadesPedidoTableTableManager(
      _$AppDatabase db, $PrioridadesPedidoTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrioridadesPedidoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrioridadesPedidoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrioridadesPedidoTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String> cor = const Value.absent(),
            Value<String?> icone = const Value.absent(),
            Value<int> ordem = const Value.absent(),
          }) =>
              PrioridadesPedidoCompanion(
            id: id,
            nome: nome,
            cor: cor,
            icone: icone,
            ordem: ordem,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
            required String cor,
            Value<String?> icone = const Value.absent(),
            Value<int> ordem = const Value.absent(),
          }) =>
              PrioridadesPedidoCompanion.insert(
            id: id,
            nome: nome,
            cor: cor,
            icone: icone,
            ordem: ordem,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PrioridadesPedidoTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({pedidosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (pedidosRefs) db.pedidos],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pedidosRefs)
                    await $_getPrefetchedData<PrioridadesPedidoData,
                            $PrioridadesPedidoTable, Pedido>(
                        currentTable: table,
                        referencedTable: $$PrioridadesPedidoTableReferences
                            ._pedidosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PrioridadesPedidoTableReferences(db, table, p0)
                                .pedidosRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.prioridadeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PrioridadesPedidoTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PrioridadesPedidoTable,
    PrioridadesPedidoData,
    $$PrioridadesPedidoTableFilterComposer,
    $$PrioridadesPedidoTableOrderingComposer,
    $$PrioridadesPedidoTableAnnotationComposer,
    $$PrioridadesPedidoTableCreateCompanionBuilder,
    $$PrioridadesPedidoTableUpdateCompanionBuilder,
    (PrioridadesPedidoData, $$PrioridadesPedidoTableReferences),
    PrioridadesPedidoData,
    PrefetchHooks Function({bool pedidosRefs})>;
typedef $$PedidosTableCreateCompanionBuilder = PedidosCompanion Function({
  Value<int> id,
  required int numero,
  required int clienteId,
  required String clienteNome,
  Value<String> clienteTelefone,
  required DateTime dataEntrega,
  required String tipoEntrega,
  required String formaPagamento,
  Value<int?> trocoParaCentavos,
  Value<String> observacoes,
  required int subtotalCentavos,
  Value<int> taxaEntregaCentavos,
  required int totalCentavos,
  Value<String> status,
  Value<int> versao,
  Value<String> prioridade,
  Value<bool> pixConfirmado,
  Value<DateTime?> pixConfirmadoEm,
  Value<DateTime> criadoEm,
  Value<String?> comprovantePix,
  Value<int?> origemId,
  Value<int?> prioridadeId,
  Value<DateTime?> dataProducao,
  Value<String> statusFinanceiro,
});
typedef $$PedidosTableUpdateCompanionBuilder = PedidosCompanion Function({
  Value<int> id,
  Value<int> numero,
  Value<int> clienteId,
  Value<String> clienteNome,
  Value<String> clienteTelefone,
  Value<DateTime> dataEntrega,
  Value<String> tipoEntrega,
  Value<String> formaPagamento,
  Value<int?> trocoParaCentavos,
  Value<String> observacoes,
  Value<int> subtotalCentavos,
  Value<int> taxaEntregaCentavos,
  Value<int> totalCentavos,
  Value<String> status,
  Value<int> versao,
  Value<String> prioridade,
  Value<bool> pixConfirmado,
  Value<DateTime?> pixConfirmadoEm,
  Value<DateTime> criadoEm,
  Value<String?> comprovantePix,
  Value<int?> origemId,
  Value<int?> prioridadeId,
  Value<DateTime?> dataProducao,
  Value<String> statusFinanceiro,
});

final class $$PedidosTableReferences
    extends BaseReferences<_$AppDatabase, $PedidosTable, Pedido> {
  $$PedidosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClientesTable _clienteIdTable(_$AppDatabase db) => db.clientes
      .createAlias($_aliasNameGenerator(db.pedidos.clienteId, db.clientes.id));

  $$ClientesTableProcessedTableManager get clienteId {
    final $_column = $_itemColumn<int>('cliente_id')!;

    final manager = $$ClientesTableTableManager($_db, $_db.clientes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clienteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $OrigensPedidoTable _origemIdTable(_$AppDatabase db) =>
      db.origensPedido.createAlias(
          $_aliasNameGenerator(db.pedidos.origemId, db.origensPedido.id));

  $$OrigensPedidoTableProcessedTableManager? get origemId {
    final $_column = $_itemColumn<int>('origem_id');
    if ($_column == null) return null;
    final manager = $$OrigensPedidoTableTableManager($_db, $_db.origensPedido)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_origemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PrioridadesPedidoTable _prioridadeIdTable(_$AppDatabase db) =>
      db.prioridadesPedido.createAlias($_aliasNameGenerator(
          db.pedidos.prioridadeId, db.prioridadesPedido.id));

  $$PrioridadesPedidoTableProcessedTableManager? get prioridadeId {
    final $_column = $_itemColumn<int>('prioridade_id');
    if ($_column == null) return null;
    final manager =
        $$PrioridadesPedidoTableTableManager($_db, $_db.prioridadesPedido)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_prioridadeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ItensPedidoTable, List<ItensPedidoData>>
      _itensPedidoRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.itensPedido,
              aliasName:
                  $_aliasNameGenerator(db.pedidos.id, db.itensPedido.pedidoId));

  $$ItensPedidoTableProcessedTableManager get itensPedidoRefs {
    final manager = $$ItensPedidoTableTableManager($_db, $_db.itensPedido)
        .filter((f) => f.pedidoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itensPedidoRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MovimentacoesEstoqueTable,
      List<MovimentacoesEstoqueData>> _movimentacoesEstoqueRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.movimentacoesEstoque,
          aliasName: $_aliasNameGenerator(
              db.pedidos.id, db.movimentacoesEstoque.pedidoId));

  $$MovimentacoesEstoqueTableProcessedTableManager
      get movimentacoesEstoqueRefs {
    final manager =
        $$MovimentacoesEstoqueTableTableManager($_db, $_db.movimentacoesEstoque)
            .filter((f) => f.pedidoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_movimentacoesEstoqueRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EventosPedidoTable, List<EventosPedidoData>>
      _eventosPedidoRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.eventosPedido,
              aliasName: $_aliasNameGenerator(
                  db.pedidos.id, db.eventosPedido.pedidoId));

  $$EventosPedidoTableProcessedTableManager get eventosPedidoRefs {
    final manager = $$EventosPedidoTableTableManager($_db, $_db.eventosPedido)
        .filter((f) => f.pedidoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventosPedidoRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PedidosTableFilterComposer
    extends Composer<_$AppDatabase, $PedidosTable> {
  $$PedidosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numero => $composableBuilder(
      column: $table.numero, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clienteNome => $composableBuilder(
      column: $table.clienteNome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clienteTelefone => $composableBuilder(
      column: $table.clienteTelefone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dataEntrega => $composableBuilder(
      column: $table.dataEntrega, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoEntrega => $composableBuilder(
      column: $table.tipoEntrega, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formaPagamento => $composableBuilder(
      column: $table.formaPagamento,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trocoParaCentavos => $composableBuilder(
      column: $table.trocoParaCentavos,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get subtotalCentavos => $composableBuilder(
      column: $table.subtotalCentavos,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taxaEntregaCentavos => $composableBuilder(
      column: $table.taxaEntregaCentavos,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCentavos => $composableBuilder(
      column: $table.totalCentavos, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get versao => $composableBuilder(
      column: $table.versao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prioridade => $composableBuilder(
      column: $table.prioridade, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pixConfirmado => $composableBuilder(
      column: $table.pixConfirmado, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pixConfirmadoEm => $composableBuilder(
      column: $table.pixConfirmadoEm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get comprovantePix => $composableBuilder(
      column: $table.comprovantePix,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dataProducao => $composableBuilder(
      column: $table.dataProducao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statusFinanceiro => $composableBuilder(
      column: $table.statusFinanceiro,
      builder: (column) => ColumnFilters(column));

  $$ClientesTableFilterComposer get clienteId {
    final $$ClientesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clienteId,
        referencedTable: $db.clientes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientesTableFilterComposer(
              $db: $db,
              $table: $db.clientes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrigensPedidoTableFilterComposer get origemId {
    final $$OrigensPedidoTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.origemId,
        referencedTable: $db.origensPedido,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrigensPedidoTableFilterComposer(
              $db: $db,
              $table: $db.origensPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PrioridadesPedidoTableFilterComposer get prioridadeId {
    final $$PrioridadesPedidoTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.prioridadeId,
        referencedTable: $db.prioridadesPedido,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrioridadesPedidoTableFilterComposer(
              $db: $db,
              $table: $db.prioridadesPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> itensPedidoRefs(
      Expression<bool> Function($$ItensPedidoTableFilterComposer f) f) {
    final $$ItensPedidoTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensPedido,
        getReferencedColumn: (t) => t.pedidoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensPedidoTableFilterComposer(
              $db: $db,
              $table: $db.itensPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> movimentacoesEstoqueRefs(
      Expression<bool> Function($$MovimentacoesEstoqueTableFilterComposer f)
          f) {
    final $$MovimentacoesEstoqueTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.movimentacoesEstoque,
        getReferencedColumn: (t) => t.pedidoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MovimentacoesEstoqueTableFilterComposer(
              $db: $db,
              $table: $db.movimentacoesEstoque,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> eventosPedidoRefs(
      Expression<bool> Function($$EventosPedidoTableFilterComposer f) f) {
    final $$EventosPedidoTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.eventosPedido,
        getReferencedColumn: (t) => t.pedidoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventosPedidoTableFilterComposer(
              $db: $db,
              $table: $db.eventosPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PedidosTableOrderingComposer
    extends Composer<_$AppDatabase, $PedidosTable> {
  $$PedidosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numero => $composableBuilder(
      column: $table.numero, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clienteNome => $composableBuilder(
      column: $table.clienteNome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clienteTelefone => $composableBuilder(
      column: $table.clienteTelefone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dataEntrega => $composableBuilder(
      column: $table.dataEntrega, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoEntrega => $composableBuilder(
      column: $table.tipoEntrega, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formaPagamento => $composableBuilder(
      column: $table.formaPagamento,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trocoParaCentavos => $composableBuilder(
      column: $table.trocoParaCentavos,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get subtotalCentavos => $composableBuilder(
      column: $table.subtotalCentavos,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taxaEntregaCentavos => $composableBuilder(
      column: $table.taxaEntregaCentavos,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCentavos => $composableBuilder(
      column: $table.totalCentavos,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get versao => $composableBuilder(
      column: $table.versao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prioridade => $composableBuilder(
      column: $table.prioridade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pixConfirmado => $composableBuilder(
      column: $table.pixConfirmado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pixConfirmadoEm => $composableBuilder(
      column: $table.pixConfirmadoEm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get comprovantePix => $composableBuilder(
      column: $table.comprovantePix,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dataProducao => $composableBuilder(
      column: $table.dataProducao,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statusFinanceiro => $composableBuilder(
      column: $table.statusFinanceiro,
      builder: (column) => ColumnOrderings(column));

  $$ClientesTableOrderingComposer get clienteId {
    final $$ClientesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clienteId,
        referencedTable: $db.clientes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientesTableOrderingComposer(
              $db: $db,
              $table: $db.clientes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrigensPedidoTableOrderingComposer get origemId {
    final $$OrigensPedidoTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.origemId,
        referencedTable: $db.origensPedido,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrigensPedidoTableOrderingComposer(
              $db: $db,
              $table: $db.origensPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PrioridadesPedidoTableOrderingComposer get prioridadeId {
    final $$PrioridadesPedidoTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.prioridadeId,
        referencedTable: $db.prioridadesPedido,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrioridadesPedidoTableOrderingComposer(
              $db: $db,
              $table: $db.prioridadesPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PedidosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PedidosTable> {
  $$PedidosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get numero =>
      $composableBuilder(column: $table.numero, builder: (column) => column);

  GeneratedColumn<String> get clienteNome => $composableBuilder(
      column: $table.clienteNome, builder: (column) => column);

  GeneratedColumn<String> get clienteTelefone => $composableBuilder(
      column: $table.clienteTelefone, builder: (column) => column);

  GeneratedColumn<DateTime> get dataEntrega => $composableBuilder(
      column: $table.dataEntrega, builder: (column) => column);

  GeneratedColumn<String> get tipoEntrega => $composableBuilder(
      column: $table.tipoEntrega, builder: (column) => column);

  GeneratedColumn<String> get formaPagamento => $composableBuilder(
      column: $table.formaPagamento, builder: (column) => column);

  GeneratedColumn<int> get trocoParaCentavos => $composableBuilder(
      column: $table.trocoParaCentavos, builder: (column) => column);

  GeneratedColumn<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => column);

  GeneratedColumn<int> get subtotalCentavos => $composableBuilder(
      column: $table.subtotalCentavos, builder: (column) => column);

  GeneratedColumn<int> get taxaEntregaCentavos => $composableBuilder(
      column: $table.taxaEntregaCentavos, builder: (column) => column);

  GeneratedColumn<int> get totalCentavos => $composableBuilder(
      column: $table.totalCentavos, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get versao =>
      $composableBuilder(column: $table.versao, builder: (column) => column);

  GeneratedColumn<String> get prioridade => $composableBuilder(
      column: $table.prioridade, builder: (column) => column);

  GeneratedColumn<bool> get pixConfirmado => $composableBuilder(
      column: $table.pixConfirmado, builder: (column) => column);

  GeneratedColumn<DateTime> get pixConfirmadoEm => $composableBuilder(
      column: $table.pixConfirmadoEm, builder: (column) => column);

  GeneratedColumn<DateTime> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  GeneratedColumn<String> get comprovantePix => $composableBuilder(
      column: $table.comprovantePix, builder: (column) => column);

  GeneratedColumn<DateTime> get dataProducao => $composableBuilder(
      column: $table.dataProducao, builder: (column) => column);

  GeneratedColumn<String> get statusFinanceiro => $composableBuilder(
      column: $table.statusFinanceiro, builder: (column) => column);

  $$ClientesTableAnnotationComposer get clienteId {
    final $$ClientesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clienteId,
        referencedTable: $db.clientes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientesTableAnnotationComposer(
              $db: $db,
              $table: $db.clientes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrigensPedidoTableAnnotationComposer get origemId {
    final $$OrigensPedidoTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.origemId,
        referencedTable: $db.origensPedido,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrigensPedidoTableAnnotationComposer(
              $db: $db,
              $table: $db.origensPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PrioridadesPedidoTableAnnotationComposer get prioridadeId {
    final $$PrioridadesPedidoTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.prioridadeId,
            referencedTable: $db.prioridadesPedido,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PrioridadesPedidoTableAnnotationComposer(
                  $db: $db,
                  $table: $db.prioridadesPedido,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  Expression<T> itensPedidoRefs<T extends Object>(
      Expression<T> Function($$ItensPedidoTableAnnotationComposer a) f) {
    final $$ItensPedidoTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensPedido,
        getReferencedColumn: (t) => t.pedidoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensPedidoTableAnnotationComposer(
              $db: $db,
              $table: $db.itensPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> movimentacoesEstoqueRefs<T extends Object>(
      Expression<T> Function($$MovimentacoesEstoqueTableAnnotationComposer a)
          f) {
    final $$MovimentacoesEstoqueTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.movimentacoesEstoque,
            getReferencedColumn: (t) => t.pedidoId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$MovimentacoesEstoqueTableAnnotationComposer(
                  $db: $db,
                  $table: $db.movimentacoesEstoque,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> eventosPedidoRefs<T extends Object>(
      Expression<T> Function($$EventosPedidoTableAnnotationComposer a) f) {
    final $$EventosPedidoTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.eventosPedido,
        getReferencedColumn: (t) => t.pedidoId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventosPedidoTableAnnotationComposer(
              $db: $db,
              $table: $db.eventosPedido,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PedidosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PedidosTable,
    Pedido,
    $$PedidosTableFilterComposer,
    $$PedidosTableOrderingComposer,
    $$PedidosTableAnnotationComposer,
    $$PedidosTableCreateCompanionBuilder,
    $$PedidosTableUpdateCompanionBuilder,
    (Pedido, $$PedidosTableReferences),
    Pedido,
    PrefetchHooks Function(
        {bool clienteId,
        bool origemId,
        bool prioridadeId,
        bool itensPedidoRefs,
        bool movimentacoesEstoqueRefs,
        bool eventosPedidoRefs})> {
  $$PedidosTableTableManager(_$AppDatabase db, $PedidosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PedidosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PedidosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PedidosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> numero = const Value.absent(),
            Value<int> clienteId = const Value.absent(),
            Value<String> clienteNome = const Value.absent(),
            Value<String> clienteTelefone = const Value.absent(),
            Value<DateTime> dataEntrega = const Value.absent(),
            Value<String> tipoEntrega = const Value.absent(),
            Value<String> formaPagamento = const Value.absent(),
            Value<int?> trocoParaCentavos = const Value.absent(),
            Value<String> observacoes = const Value.absent(),
            Value<int> subtotalCentavos = const Value.absent(),
            Value<int> taxaEntregaCentavos = const Value.absent(),
            Value<int> totalCentavos = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> versao = const Value.absent(),
            Value<String> prioridade = const Value.absent(),
            Value<bool> pixConfirmado = const Value.absent(),
            Value<DateTime?> pixConfirmadoEm = const Value.absent(),
            Value<DateTime> criadoEm = const Value.absent(),
            Value<String?> comprovantePix = const Value.absent(),
            Value<int?> origemId = const Value.absent(),
            Value<int?> prioridadeId = const Value.absent(),
            Value<DateTime?> dataProducao = const Value.absent(),
            Value<String> statusFinanceiro = const Value.absent(),
          }) =>
              PedidosCompanion(
            id: id,
            numero: numero,
            clienteId: clienteId,
            clienteNome: clienteNome,
            clienteTelefone: clienteTelefone,
            dataEntrega: dataEntrega,
            tipoEntrega: tipoEntrega,
            formaPagamento: formaPagamento,
            trocoParaCentavos: trocoParaCentavos,
            observacoes: observacoes,
            subtotalCentavos: subtotalCentavos,
            taxaEntregaCentavos: taxaEntregaCentavos,
            totalCentavos: totalCentavos,
            status: status,
            versao: versao,
            prioridade: prioridade,
            pixConfirmado: pixConfirmado,
            pixConfirmadoEm: pixConfirmadoEm,
            criadoEm: criadoEm,
            comprovantePix: comprovantePix,
            origemId: origemId,
            prioridadeId: prioridadeId,
            dataProducao: dataProducao,
            statusFinanceiro: statusFinanceiro,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int numero,
            required int clienteId,
            required String clienteNome,
            Value<String> clienteTelefone = const Value.absent(),
            required DateTime dataEntrega,
            required String tipoEntrega,
            required String formaPagamento,
            Value<int?> trocoParaCentavos = const Value.absent(),
            Value<String> observacoes = const Value.absent(),
            required int subtotalCentavos,
            Value<int> taxaEntregaCentavos = const Value.absent(),
            required int totalCentavos,
            Value<String> status = const Value.absent(),
            Value<int> versao = const Value.absent(),
            Value<String> prioridade = const Value.absent(),
            Value<bool> pixConfirmado = const Value.absent(),
            Value<DateTime?> pixConfirmadoEm = const Value.absent(),
            Value<DateTime> criadoEm = const Value.absent(),
            Value<String?> comprovantePix = const Value.absent(),
            Value<int?> origemId = const Value.absent(),
            Value<int?> prioridadeId = const Value.absent(),
            Value<DateTime?> dataProducao = const Value.absent(),
            Value<String> statusFinanceiro = const Value.absent(),
          }) =>
              PedidosCompanion.insert(
            id: id,
            numero: numero,
            clienteId: clienteId,
            clienteNome: clienteNome,
            clienteTelefone: clienteTelefone,
            dataEntrega: dataEntrega,
            tipoEntrega: tipoEntrega,
            formaPagamento: formaPagamento,
            trocoParaCentavos: trocoParaCentavos,
            observacoes: observacoes,
            subtotalCentavos: subtotalCentavos,
            taxaEntregaCentavos: taxaEntregaCentavos,
            totalCentavos: totalCentavos,
            status: status,
            versao: versao,
            prioridade: prioridade,
            pixConfirmado: pixConfirmado,
            pixConfirmadoEm: pixConfirmadoEm,
            criadoEm: criadoEm,
            comprovantePix: comprovantePix,
            origemId: origemId,
            prioridadeId: prioridadeId,
            dataProducao: dataProducao,
            statusFinanceiro: statusFinanceiro,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PedidosTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {clienteId = false,
              origemId = false,
              prioridadeId = false,
              itensPedidoRefs = false,
              movimentacoesEstoqueRefs = false,
              eventosPedidoRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (itensPedidoRefs) db.itensPedido,
                if (movimentacoesEstoqueRefs) db.movimentacoesEstoque,
                if (eventosPedidoRefs) db.eventosPedido
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (clienteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.clienteId,
                    referencedTable:
                        $$PedidosTableReferences._clienteIdTable(db),
                    referencedColumn:
                        $$PedidosTableReferences._clienteIdTable(db).id,
                  ) as T;
                }
                if (origemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.origemId,
                    referencedTable:
                        $$PedidosTableReferences._origemIdTable(db),
                    referencedColumn:
                        $$PedidosTableReferences._origemIdTable(db).id,
                  ) as T;
                }
                if (prioridadeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.prioridadeId,
                    referencedTable:
                        $$PedidosTableReferences._prioridadeIdTable(db),
                    referencedColumn:
                        $$PedidosTableReferences._prioridadeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itensPedidoRefs)
                    await $_getPrefetchedData<Pedido, $PedidosTable,
                            ItensPedidoData>(
                        currentTable: table,
                        referencedTable:
                            $$PedidosTableReferences._itensPedidoRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PedidosTableReferences(db, table, p0)
                                .itensPedidoRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.pedidoId == item.id),
                        typedResults: items),
                  if (movimentacoesEstoqueRefs)
                    await $_getPrefetchedData<Pedido, $PedidosTable,
                            MovimentacoesEstoqueData>(
                        currentTable: table,
                        referencedTable: $$PedidosTableReferences
                            ._movimentacoesEstoqueRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PedidosTableReferences(db, table, p0)
                                .movimentacoesEstoqueRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.pedidoId == item.id),
                        typedResults: items),
                  if (eventosPedidoRefs)
                    await $_getPrefetchedData<Pedido, $PedidosTable,
                            EventosPedidoData>(
                        currentTable: table,
                        referencedTable: $$PedidosTableReferences
                            ._eventosPedidoRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PedidosTableReferences(db, table, p0)
                                .eventosPedidoRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.pedidoId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PedidosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PedidosTable,
    Pedido,
    $$PedidosTableFilterComposer,
    $$PedidosTableOrderingComposer,
    $$PedidosTableAnnotationComposer,
    $$PedidosTableCreateCompanionBuilder,
    $$PedidosTableUpdateCompanionBuilder,
    (Pedido, $$PedidosTableReferences),
    Pedido,
    PrefetchHooks Function(
        {bool clienteId,
        bool origemId,
        bool prioridadeId,
        bool itensPedidoRefs,
        bool movimentacoesEstoqueRefs,
        bool eventosPedidoRefs})>;
typedef $$ItensPedidoTableCreateCompanionBuilder = ItensPedidoCompanion
    Function({
  Value<int> id,
  required int pedidoId,
  required int produtoId,
  required String produtoNome,
  required int quantidade,
  required int valorUnitarioCentavos,
  required int valorTotalCentavos,
});
typedef $$ItensPedidoTableUpdateCompanionBuilder = ItensPedidoCompanion
    Function({
  Value<int> id,
  Value<int> pedidoId,
  Value<int> produtoId,
  Value<String> produtoNome,
  Value<int> quantidade,
  Value<int> valorUnitarioCentavos,
  Value<int> valorTotalCentavos,
});

final class $$ItensPedidoTableReferences
    extends BaseReferences<_$AppDatabase, $ItensPedidoTable, ItensPedidoData> {
  $$ItensPedidoTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PedidosTable _pedidoIdTable(_$AppDatabase db) =>
      db.pedidos.createAlias(
          $_aliasNameGenerator(db.itensPedido.pedidoId, db.pedidos.id));

  $$PedidosTableProcessedTableManager get pedidoId {
    final $_column = $_itemColumn<int>('pedido_id')!;

    final manager = $$PedidosTableTableManager($_db, $_db.pedidos)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pedidoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProdutosTable _produtoIdTable(_$AppDatabase db) =>
      db.produtos.createAlias(
          $_aliasNameGenerator(db.itensPedido.produtoId, db.produtos.id));

  $$ProdutosTableProcessedTableManager get produtoId {
    final $_column = $_itemColumn<int>('produto_id')!;

    final manager = $$ProdutosTableTableManager($_db, $_db.produtos)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_produtoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ItensPedidoTableFilterComposer
    extends Composer<_$AppDatabase, $ItensPedidoTable> {
  $$ItensPedidoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get produtoNome => $composableBuilder(
      column: $table.produtoNome, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantidade => $composableBuilder(
      column: $table.quantidade, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get valorUnitarioCentavos => $composableBuilder(
      column: $table.valorUnitarioCentavos,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get valorTotalCentavos => $composableBuilder(
      column: $table.valorTotalCentavos,
      builder: (column) => ColumnFilters(column));

  $$PedidosTableFilterComposer get pedidoId {
    final $$PedidosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pedidoId,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableFilterComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProdutosTableFilterComposer get produtoId {
    final $$ProdutosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableFilterComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensPedidoTableOrderingComposer
    extends Composer<_$AppDatabase, $ItensPedidoTable> {
  $$ItensPedidoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get produtoNome => $composableBuilder(
      column: $table.produtoNome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantidade => $composableBuilder(
      column: $table.quantidade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get valorUnitarioCentavos => $composableBuilder(
      column: $table.valorUnitarioCentavos,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get valorTotalCentavos => $composableBuilder(
      column: $table.valorTotalCentavos,
      builder: (column) => ColumnOrderings(column));

  $$PedidosTableOrderingComposer get pedidoId {
    final $$PedidosTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pedidoId,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableOrderingComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProdutosTableOrderingComposer get produtoId {
    final $$ProdutosTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableOrderingComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensPedidoTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItensPedidoTable> {
  $$ItensPedidoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get produtoNome => $composableBuilder(
      column: $table.produtoNome, builder: (column) => column);

  GeneratedColumn<int> get quantidade => $composableBuilder(
      column: $table.quantidade, builder: (column) => column);

  GeneratedColumn<int> get valorUnitarioCentavos => $composableBuilder(
      column: $table.valorUnitarioCentavos, builder: (column) => column);

  GeneratedColumn<int> get valorTotalCentavos => $composableBuilder(
      column: $table.valorTotalCentavos, builder: (column) => column);

  $$PedidosTableAnnotationComposer get pedidoId {
    final $$PedidosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pedidoId,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableAnnotationComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProdutosTableAnnotationComposer get produtoId {
    final $$ProdutosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableAnnotationComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensPedidoTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItensPedidoTable,
    ItensPedidoData,
    $$ItensPedidoTableFilterComposer,
    $$ItensPedidoTableOrderingComposer,
    $$ItensPedidoTableAnnotationComposer,
    $$ItensPedidoTableCreateCompanionBuilder,
    $$ItensPedidoTableUpdateCompanionBuilder,
    (ItensPedidoData, $$ItensPedidoTableReferences),
    ItensPedidoData,
    PrefetchHooks Function({bool pedidoId, bool produtoId})> {
  $$ItensPedidoTableTableManager(_$AppDatabase db, $ItensPedidoTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItensPedidoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItensPedidoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItensPedidoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> pedidoId = const Value.absent(),
            Value<int> produtoId = const Value.absent(),
            Value<String> produtoNome = const Value.absent(),
            Value<int> quantidade = const Value.absent(),
            Value<int> valorUnitarioCentavos = const Value.absent(),
            Value<int> valorTotalCentavos = const Value.absent(),
          }) =>
              ItensPedidoCompanion(
            id: id,
            pedidoId: pedidoId,
            produtoId: produtoId,
            produtoNome: produtoNome,
            quantidade: quantidade,
            valorUnitarioCentavos: valorUnitarioCentavos,
            valorTotalCentavos: valorTotalCentavos,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int pedidoId,
            required int produtoId,
            required String produtoNome,
            required int quantidade,
            required int valorUnitarioCentavos,
            required int valorTotalCentavos,
          }) =>
              ItensPedidoCompanion.insert(
            id: id,
            pedidoId: pedidoId,
            produtoId: produtoId,
            produtoNome: produtoNome,
            quantidade: quantidade,
            valorUnitarioCentavos: valorUnitarioCentavos,
            valorTotalCentavos: valorTotalCentavos,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ItensPedidoTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({pedidoId = false, produtoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (pedidoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pedidoId,
                    referencedTable:
                        $$ItensPedidoTableReferences._pedidoIdTable(db),
                    referencedColumn:
                        $$ItensPedidoTableReferences._pedidoIdTable(db).id,
                  ) as T;
                }
                if (produtoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.produtoId,
                    referencedTable:
                        $$ItensPedidoTableReferences._produtoIdTable(db),
                    referencedColumn:
                        $$ItensPedidoTableReferences._produtoIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ItensPedidoTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItensPedidoTable,
    ItensPedidoData,
    $$ItensPedidoTableFilterComposer,
    $$ItensPedidoTableOrderingComposer,
    $$ItensPedidoTableAnnotationComposer,
    $$ItensPedidoTableCreateCompanionBuilder,
    $$ItensPedidoTableUpdateCompanionBuilder,
    (ItensPedidoData, $$ItensPedidoTableReferences),
    ItensPedidoData,
    PrefetchHooks Function({bool pedidoId, bool produtoId})>;
typedef $$EstoqueAtualTableCreateCompanionBuilder = EstoqueAtualCompanion
    Function({
  Value<int> produtoId,
  Value<int> saldoAtual,
  Value<int> reservado,
  Value<int> reservadoComercial,
  Value<int> reservadoOperacional,
  Value<int> estoqueMinimo,
  Value<int> estoqueIdeal,
  Value<int> loteMinimo,
  Value<DateTime> atualizadoEm,
});
typedef $$EstoqueAtualTableUpdateCompanionBuilder = EstoqueAtualCompanion
    Function({
  Value<int> produtoId,
  Value<int> saldoAtual,
  Value<int> reservado,
  Value<int> reservadoComercial,
  Value<int> reservadoOperacional,
  Value<int> estoqueMinimo,
  Value<int> estoqueIdeal,
  Value<int> loteMinimo,
  Value<DateTime> atualizadoEm,
});

final class $$EstoqueAtualTableReferences extends BaseReferences<_$AppDatabase,
    $EstoqueAtualTable, EstoqueAtualData> {
  $$EstoqueAtualTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProdutosTable _produtoIdTable(_$AppDatabase db) =>
      db.produtos.createAlias(
          $_aliasNameGenerator(db.estoqueAtual.produtoId, db.produtos.id));

  $$ProdutosTableProcessedTableManager get produtoId {
    final $_column = $_itemColumn<int>('produto_id')!;

    final manager = $$ProdutosTableTableManager($_db, $_db.produtos)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_produtoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EstoqueAtualTableFilterComposer
    extends Composer<_$AppDatabase, $EstoqueAtualTable> {
  $$EstoqueAtualTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get saldoAtual => $composableBuilder(
      column: $table.saldoAtual, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reservado => $composableBuilder(
      column: $table.reservado, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reservadoComercial => $composableBuilder(
      column: $table.reservadoComercial,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reservadoOperacional => $composableBuilder(
      column: $table.reservadoOperacional,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estoqueMinimo => $composableBuilder(
      column: $table.estoqueMinimo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estoqueIdeal => $composableBuilder(
      column: $table.estoqueIdeal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get loteMinimo => $composableBuilder(
      column: $table.loteMinimo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get atualizadoEm => $composableBuilder(
      column: $table.atualizadoEm, builder: (column) => ColumnFilters(column));

  $$ProdutosTableFilterComposer get produtoId {
    final $$ProdutosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableFilterComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EstoqueAtualTableOrderingComposer
    extends Composer<_$AppDatabase, $EstoqueAtualTable> {
  $$EstoqueAtualTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get saldoAtual => $composableBuilder(
      column: $table.saldoAtual, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reservado => $composableBuilder(
      column: $table.reservado, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reservadoComercial => $composableBuilder(
      column: $table.reservadoComercial,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reservadoOperacional => $composableBuilder(
      column: $table.reservadoOperacional,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estoqueMinimo => $composableBuilder(
      column: $table.estoqueMinimo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estoqueIdeal => $composableBuilder(
      column: $table.estoqueIdeal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get loteMinimo => $composableBuilder(
      column: $table.loteMinimo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get atualizadoEm => $composableBuilder(
      column: $table.atualizadoEm,
      builder: (column) => ColumnOrderings(column));

  $$ProdutosTableOrderingComposer get produtoId {
    final $$ProdutosTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableOrderingComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EstoqueAtualTableAnnotationComposer
    extends Composer<_$AppDatabase, $EstoqueAtualTable> {
  $$EstoqueAtualTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get saldoAtual => $composableBuilder(
      column: $table.saldoAtual, builder: (column) => column);

  GeneratedColumn<int> get reservado =>
      $composableBuilder(column: $table.reservado, builder: (column) => column);

  GeneratedColumn<int> get reservadoComercial => $composableBuilder(
      column: $table.reservadoComercial, builder: (column) => column);

  GeneratedColumn<int> get reservadoOperacional => $composableBuilder(
      column: $table.reservadoOperacional, builder: (column) => column);

  GeneratedColumn<int> get estoqueMinimo => $composableBuilder(
      column: $table.estoqueMinimo, builder: (column) => column);

  GeneratedColumn<int> get estoqueIdeal => $composableBuilder(
      column: $table.estoqueIdeal, builder: (column) => column);

  GeneratedColumn<int> get loteMinimo => $composableBuilder(
      column: $table.loteMinimo, builder: (column) => column);

  GeneratedColumn<DateTime> get atualizadoEm => $composableBuilder(
      column: $table.atualizadoEm, builder: (column) => column);

  $$ProdutosTableAnnotationComposer get produtoId {
    final $$ProdutosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableAnnotationComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EstoqueAtualTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EstoqueAtualTable,
    EstoqueAtualData,
    $$EstoqueAtualTableFilterComposer,
    $$EstoqueAtualTableOrderingComposer,
    $$EstoqueAtualTableAnnotationComposer,
    $$EstoqueAtualTableCreateCompanionBuilder,
    $$EstoqueAtualTableUpdateCompanionBuilder,
    (EstoqueAtualData, $$EstoqueAtualTableReferences),
    EstoqueAtualData,
    PrefetchHooks Function({bool produtoId})> {
  $$EstoqueAtualTableTableManager(_$AppDatabase db, $EstoqueAtualTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EstoqueAtualTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EstoqueAtualTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EstoqueAtualTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> produtoId = const Value.absent(),
            Value<int> saldoAtual = const Value.absent(),
            Value<int> reservado = const Value.absent(),
            Value<int> reservadoComercial = const Value.absent(),
            Value<int> reservadoOperacional = const Value.absent(),
            Value<int> estoqueMinimo = const Value.absent(),
            Value<int> estoqueIdeal = const Value.absent(),
            Value<int> loteMinimo = const Value.absent(),
            Value<DateTime> atualizadoEm = const Value.absent(),
          }) =>
              EstoqueAtualCompanion(
            produtoId: produtoId,
            saldoAtual: saldoAtual,
            reservado: reservado,
            reservadoComercial: reservadoComercial,
            reservadoOperacional: reservadoOperacional,
            estoqueMinimo: estoqueMinimo,
            estoqueIdeal: estoqueIdeal,
            loteMinimo: loteMinimo,
            atualizadoEm: atualizadoEm,
          ),
          createCompanionCallback: ({
            Value<int> produtoId = const Value.absent(),
            Value<int> saldoAtual = const Value.absent(),
            Value<int> reservado = const Value.absent(),
            Value<int> reservadoComercial = const Value.absent(),
            Value<int> reservadoOperacional = const Value.absent(),
            Value<int> estoqueMinimo = const Value.absent(),
            Value<int> estoqueIdeal = const Value.absent(),
            Value<int> loteMinimo = const Value.absent(),
            Value<DateTime> atualizadoEm = const Value.absent(),
          }) =>
              EstoqueAtualCompanion.insert(
            produtoId: produtoId,
            saldoAtual: saldoAtual,
            reservado: reservado,
            reservadoComercial: reservadoComercial,
            reservadoOperacional: reservadoOperacional,
            estoqueMinimo: estoqueMinimo,
            estoqueIdeal: estoqueIdeal,
            loteMinimo: loteMinimo,
            atualizadoEm: atualizadoEm,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EstoqueAtualTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({produtoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (produtoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.produtoId,
                    referencedTable:
                        $$EstoqueAtualTableReferences._produtoIdTable(db),
                    referencedColumn:
                        $$EstoqueAtualTableReferences._produtoIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EstoqueAtualTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EstoqueAtualTable,
    EstoqueAtualData,
    $$EstoqueAtualTableFilterComposer,
    $$EstoqueAtualTableOrderingComposer,
    $$EstoqueAtualTableAnnotationComposer,
    $$EstoqueAtualTableCreateCompanionBuilder,
    $$EstoqueAtualTableUpdateCompanionBuilder,
    (EstoqueAtualData, $$EstoqueAtualTableReferences),
    EstoqueAtualData,
    PrefetchHooks Function({bool produtoId})>;
typedef $$MovimentacoesEstoqueTableCreateCompanionBuilder
    = MovimentacoesEstoqueCompanion Function({
  Value<int> id,
  required int produtoId,
  required String tipoMovimentacao,
  required int quantidade,
  required int saldoAnterior,
  required int saldoNovo,
  Value<String> motivo,
  Value<int?> pedidoId,
  Value<DateTime> criadoEm,
});
typedef $$MovimentacoesEstoqueTableUpdateCompanionBuilder
    = MovimentacoesEstoqueCompanion Function({
  Value<int> id,
  Value<int> produtoId,
  Value<String> tipoMovimentacao,
  Value<int> quantidade,
  Value<int> saldoAnterior,
  Value<int> saldoNovo,
  Value<String> motivo,
  Value<int?> pedidoId,
  Value<DateTime> criadoEm,
});

final class $$MovimentacoesEstoqueTableReferences extends BaseReferences<
    _$AppDatabase, $MovimentacoesEstoqueTable, MovimentacoesEstoqueData> {
  $$MovimentacoesEstoqueTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProdutosTable _produtoIdTable(_$AppDatabase db) =>
      db.produtos.createAlias($_aliasNameGenerator(
          db.movimentacoesEstoque.produtoId, db.produtos.id));

  $$ProdutosTableProcessedTableManager get produtoId {
    final $_column = $_itemColumn<int>('produto_id')!;

    final manager = $$ProdutosTableTableManager($_db, $_db.produtos)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_produtoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PedidosTable _pedidoIdTable(_$AppDatabase db) =>
      db.pedidos.createAlias($_aliasNameGenerator(
          db.movimentacoesEstoque.pedidoId, db.pedidos.id));

  $$PedidosTableProcessedTableManager? get pedidoId {
    final $_column = $_itemColumn<int>('pedido_id');
    if ($_column == null) return null;
    final manager = $$PedidosTableTableManager($_db, $_db.pedidos)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pedidoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MovimentacoesEstoqueTableFilterComposer
    extends Composer<_$AppDatabase, $MovimentacoesEstoqueTable> {
  $$MovimentacoesEstoqueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoMovimentacao => $composableBuilder(
      column: $table.tipoMovimentacao,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantidade => $composableBuilder(
      column: $table.quantidade, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get saldoAnterior => $composableBuilder(
      column: $table.saldoAnterior, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get saldoNovo => $composableBuilder(
      column: $table.saldoNovo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motivo => $composableBuilder(
      column: $table.motivo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnFilters(column));

  $$ProdutosTableFilterComposer get produtoId {
    final $$ProdutosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableFilterComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PedidosTableFilterComposer get pedidoId {
    final $$PedidosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pedidoId,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableFilterComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MovimentacoesEstoqueTableOrderingComposer
    extends Composer<_$AppDatabase, $MovimentacoesEstoqueTable> {
  $$MovimentacoesEstoqueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoMovimentacao => $composableBuilder(
      column: $table.tipoMovimentacao,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantidade => $composableBuilder(
      column: $table.quantidade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get saldoAnterior => $composableBuilder(
      column: $table.saldoAnterior,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get saldoNovo => $composableBuilder(
      column: $table.saldoNovo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motivo => $composableBuilder(
      column: $table.motivo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnOrderings(column));

  $$ProdutosTableOrderingComposer get produtoId {
    final $$ProdutosTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableOrderingComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PedidosTableOrderingComposer get pedidoId {
    final $$PedidosTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pedidoId,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableOrderingComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MovimentacoesEstoqueTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovimentacoesEstoqueTable> {
  $$MovimentacoesEstoqueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipoMovimentacao => $composableBuilder(
      column: $table.tipoMovimentacao, builder: (column) => column);

  GeneratedColumn<int> get quantidade => $composableBuilder(
      column: $table.quantidade, builder: (column) => column);

  GeneratedColumn<int> get saldoAnterior => $composableBuilder(
      column: $table.saldoAnterior, builder: (column) => column);

  GeneratedColumn<int> get saldoNovo =>
      $composableBuilder(column: $table.saldoNovo, builder: (column) => column);

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumn<DateTime> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  $$ProdutosTableAnnotationComposer get produtoId {
    final $$ProdutosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.produtoId,
        referencedTable: $db.produtos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProdutosTableAnnotationComposer(
              $db: $db,
              $table: $db.produtos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PedidosTableAnnotationComposer get pedidoId {
    final $$PedidosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pedidoId,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableAnnotationComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MovimentacoesEstoqueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MovimentacoesEstoqueTable,
    MovimentacoesEstoqueData,
    $$MovimentacoesEstoqueTableFilterComposer,
    $$MovimentacoesEstoqueTableOrderingComposer,
    $$MovimentacoesEstoqueTableAnnotationComposer,
    $$MovimentacoesEstoqueTableCreateCompanionBuilder,
    $$MovimentacoesEstoqueTableUpdateCompanionBuilder,
    (MovimentacoesEstoqueData, $$MovimentacoesEstoqueTableReferences),
    MovimentacoesEstoqueData,
    PrefetchHooks Function({bool produtoId, bool pedidoId})> {
  $$MovimentacoesEstoqueTableTableManager(
      _$AppDatabase db, $MovimentacoesEstoqueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimentacoesEstoqueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimentacoesEstoqueTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovimentacoesEstoqueTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> produtoId = const Value.absent(),
            Value<String> tipoMovimentacao = const Value.absent(),
            Value<int> quantidade = const Value.absent(),
            Value<int> saldoAnterior = const Value.absent(),
            Value<int> saldoNovo = const Value.absent(),
            Value<String> motivo = const Value.absent(),
            Value<int?> pedidoId = const Value.absent(),
            Value<DateTime> criadoEm = const Value.absent(),
          }) =>
              MovimentacoesEstoqueCompanion(
            id: id,
            produtoId: produtoId,
            tipoMovimentacao: tipoMovimentacao,
            quantidade: quantidade,
            saldoAnterior: saldoAnterior,
            saldoNovo: saldoNovo,
            motivo: motivo,
            pedidoId: pedidoId,
            criadoEm: criadoEm,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int produtoId,
            required String tipoMovimentacao,
            required int quantidade,
            required int saldoAnterior,
            required int saldoNovo,
            Value<String> motivo = const Value.absent(),
            Value<int?> pedidoId = const Value.absent(),
            Value<DateTime> criadoEm = const Value.absent(),
          }) =>
              MovimentacoesEstoqueCompanion.insert(
            id: id,
            produtoId: produtoId,
            tipoMovimentacao: tipoMovimentacao,
            quantidade: quantidade,
            saldoAnterior: saldoAnterior,
            saldoNovo: saldoNovo,
            motivo: motivo,
            pedidoId: pedidoId,
            criadoEm: criadoEm,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MovimentacoesEstoqueTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({produtoId = false, pedidoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (produtoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.produtoId,
                    referencedTable: $$MovimentacoesEstoqueTableReferences
                        ._produtoIdTable(db),
                    referencedColumn: $$MovimentacoesEstoqueTableReferences
                        ._produtoIdTable(db)
                        .id,
                  ) as T;
                }
                if (pedidoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pedidoId,
                    referencedTable: $$MovimentacoesEstoqueTableReferences
                        ._pedidoIdTable(db),
                    referencedColumn: $$MovimentacoesEstoqueTableReferences
                        ._pedidoIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MovimentacoesEstoqueTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $MovimentacoesEstoqueTable,
        MovimentacoesEstoqueData,
        $$MovimentacoesEstoqueTableFilterComposer,
        $$MovimentacoesEstoqueTableOrderingComposer,
        $$MovimentacoesEstoqueTableAnnotationComposer,
        $$MovimentacoesEstoqueTableCreateCompanionBuilder,
        $$MovimentacoesEstoqueTableUpdateCompanionBuilder,
        (MovimentacoesEstoqueData, $$MovimentacoesEstoqueTableReferences),
        MovimentacoesEstoqueData,
        PrefetchHooks Function({bool produtoId, bool pedidoId})>;
typedef $$ConfiguracoesEmpresaTableCreateCompanionBuilder
    = ConfiguracoesEmpresaCompanion Function({
  Value<int> id,
  Value<String> empresa,
  Value<String> telefone,
  Value<String> endereco,
  Value<String> rodape,
  Value<String> impressora,
  Value<int> taxaPadrao,
  Value<int> largura,
  Value<String> horizonteOperacional,
  Value<String> razaoSocial,
  Value<String> whatsapp,
  Value<String> instagram,
  Value<String> logoPath,
  Value<bool> habilitarPix,
  Value<String> pixTipoChave,
  Value<String> pixChave,
  Value<String> pixFavorecido,
  Value<String> pixBanco,
  Value<String> pixCidade,
  Value<String> pixMensagem,
  Value<bool> pixImprimirQrCode,
  Value<bool> pixImprimirCopiaCola,
  Value<bool> pixGerarQrCodeAuto,
});
typedef $$ConfiguracoesEmpresaTableUpdateCompanionBuilder
    = ConfiguracoesEmpresaCompanion Function({
  Value<int> id,
  Value<String> empresa,
  Value<String> telefone,
  Value<String> endereco,
  Value<String> rodape,
  Value<String> impressora,
  Value<int> taxaPadrao,
  Value<int> largura,
  Value<String> horizonteOperacional,
  Value<String> razaoSocial,
  Value<String> whatsapp,
  Value<String> instagram,
  Value<String> logoPath,
  Value<bool> habilitarPix,
  Value<String> pixTipoChave,
  Value<String> pixChave,
  Value<String> pixFavorecido,
  Value<String> pixBanco,
  Value<String> pixCidade,
  Value<String> pixMensagem,
  Value<bool> pixImprimirQrCode,
  Value<bool> pixImprimirCopiaCola,
  Value<bool> pixGerarQrCodeAuto,
});

class $$ConfiguracoesEmpresaTableFilterComposer
    extends Composer<_$AppDatabase, $ConfiguracoesEmpresaTable> {
  $$ConfiguracoesEmpresaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get empresa => $composableBuilder(
      column: $table.empresa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get telefone => $composableBuilder(
      column: $table.telefone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endereco => $composableBuilder(
      column: $table.endereco, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rodape => $composableBuilder(
      column: $table.rodape, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get impressora => $composableBuilder(
      column: $table.impressora, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taxaPadrao => $composableBuilder(
      column: $table.taxaPadrao, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get largura => $composableBuilder(
      column: $table.largura, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horizonteOperacional => $composableBuilder(
      column: $table.horizonteOperacional,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get razaoSocial => $composableBuilder(
      column: $table.razaoSocial, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get whatsapp => $composableBuilder(
      column: $table.whatsapp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instagram => $composableBuilder(
      column: $table.instagram, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logoPath => $composableBuilder(
      column: $table.logoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get habilitarPix => $composableBuilder(
      column: $table.habilitarPix, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pixTipoChave => $composableBuilder(
      column: $table.pixTipoChave, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pixChave => $composableBuilder(
      column: $table.pixChave, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pixFavorecido => $composableBuilder(
      column: $table.pixFavorecido, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pixBanco => $composableBuilder(
      column: $table.pixBanco, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pixCidade => $composableBuilder(
      column: $table.pixCidade, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pixMensagem => $composableBuilder(
      column: $table.pixMensagem, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pixImprimirQrCode => $composableBuilder(
      column: $table.pixImprimirQrCode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pixImprimirCopiaCola => $composableBuilder(
      column: $table.pixImprimirCopiaCola,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pixGerarQrCodeAuto => $composableBuilder(
      column: $table.pixGerarQrCodeAuto,
      builder: (column) => ColumnFilters(column));
}

class $$ConfiguracoesEmpresaTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfiguracoesEmpresaTable> {
  $$ConfiguracoesEmpresaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get empresa => $composableBuilder(
      column: $table.empresa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get telefone => $composableBuilder(
      column: $table.telefone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endereco => $composableBuilder(
      column: $table.endereco, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rodape => $composableBuilder(
      column: $table.rodape, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get impressora => $composableBuilder(
      column: $table.impressora, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taxaPadrao => $composableBuilder(
      column: $table.taxaPadrao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get largura => $composableBuilder(
      column: $table.largura, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horizonteOperacional => $composableBuilder(
      column: $table.horizonteOperacional,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get razaoSocial => $composableBuilder(
      column: $table.razaoSocial, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get whatsapp => $composableBuilder(
      column: $table.whatsapp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instagram => $composableBuilder(
      column: $table.instagram, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logoPath => $composableBuilder(
      column: $table.logoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get habilitarPix => $composableBuilder(
      column: $table.habilitarPix,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pixTipoChave => $composableBuilder(
      column: $table.pixTipoChave,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pixChave => $composableBuilder(
      column: $table.pixChave, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pixFavorecido => $composableBuilder(
      column: $table.pixFavorecido,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pixBanco => $composableBuilder(
      column: $table.pixBanco, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pixCidade => $composableBuilder(
      column: $table.pixCidade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pixMensagem => $composableBuilder(
      column: $table.pixMensagem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pixImprimirQrCode => $composableBuilder(
      column: $table.pixImprimirQrCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pixImprimirCopiaCola => $composableBuilder(
      column: $table.pixImprimirCopiaCola,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pixGerarQrCodeAuto => $composableBuilder(
      column: $table.pixGerarQrCodeAuto,
      builder: (column) => ColumnOrderings(column));
}

class $$ConfiguracoesEmpresaTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfiguracoesEmpresaTable> {
  $$ConfiguracoesEmpresaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get empresa =>
      $composableBuilder(column: $table.empresa, builder: (column) => column);

  GeneratedColumn<String> get telefone =>
      $composableBuilder(column: $table.telefone, builder: (column) => column);

  GeneratedColumn<String> get endereco =>
      $composableBuilder(column: $table.endereco, builder: (column) => column);

  GeneratedColumn<String> get rodape =>
      $composableBuilder(column: $table.rodape, builder: (column) => column);

  GeneratedColumn<String> get impressora => $composableBuilder(
      column: $table.impressora, builder: (column) => column);

  GeneratedColumn<int> get taxaPadrao => $composableBuilder(
      column: $table.taxaPadrao, builder: (column) => column);

  GeneratedColumn<int> get largura =>
      $composableBuilder(column: $table.largura, builder: (column) => column);

  GeneratedColumn<String> get horizonteOperacional => $composableBuilder(
      column: $table.horizonteOperacional, builder: (column) => column);

  GeneratedColumn<String> get razaoSocial => $composableBuilder(
      column: $table.razaoSocial, builder: (column) => column);

  GeneratedColumn<String> get whatsapp =>
      $composableBuilder(column: $table.whatsapp, builder: (column) => column);

  GeneratedColumn<String> get instagram =>
      $composableBuilder(column: $table.instagram, builder: (column) => column);

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<bool> get habilitarPix => $composableBuilder(
      column: $table.habilitarPix, builder: (column) => column);

  GeneratedColumn<String> get pixTipoChave => $composableBuilder(
      column: $table.pixTipoChave, builder: (column) => column);

  GeneratedColumn<String> get pixChave =>
      $composableBuilder(column: $table.pixChave, builder: (column) => column);

  GeneratedColumn<String> get pixFavorecido => $composableBuilder(
      column: $table.pixFavorecido, builder: (column) => column);

  GeneratedColumn<String> get pixBanco =>
      $composableBuilder(column: $table.pixBanco, builder: (column) => column);

  GeneratedColumn<String> get pixCidade =>
      $composableBuilder(column: $table.pixCidade, builder: (column) => column);

  GeneratedColumn<String> get pixMensagem => $composableBuilder(
      column: $table.pixMensagem, builder: (column) => column);

  GeneratedColumn<bool> get pixImprimirQrCode => $composableBuilder(
      column: $table.pixImprimirQrCode, builder: (column) => column);

  GeneratedColumn<bool> get pixImprimirCopiaCola => $composableBuilder(
      column: $table.pixImprimirCopiaCola, builder: (column) => column);

  GeneratedColumn<bool> get pixGerarQrCodeAuto => $composableBuilder(
      column: $table.pixGerarQrCodeAuto, builder: (column) => column);
}

class $$ConfiguracoesEmpresaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConfiguracoesEmpresaTable,
    ConfiguracoesEmpresaData,
    $$ConfiguracoesEmpresaTableFilterComposer,
    $$ConfiguracoesEmpresaTableOrderingComposer,
    $$ConfiguracoesEmpresaTableAnnotationComposer,
    $$ConfiguracoesEmpresaTableCreateCompanionBuilder,
    $$ConfiguracoesEmpresaTableUpdateCompanionBuilder,
    (
      ConfiguracoesEmpresaData,
      BaseReferences<_$AppDatabase, $ConfiguracoesEmpresaTable,
          ConfiguracoesEmpresaData>
    ),
    ConfiguracoesEmpresaData,
    PrefetchHooks Function()> {
  $$ConfiguracoesEmpresaTableTableManager(
      _$AppDatabase db, $ConfiguracoesEmpresaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfiguracoesEmpresaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfiguracoesEmpresaTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfiguracoesEmpresaTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> empresa = const Value.absent(),
            Value<String> telefone = const Value.absent(),
            Value<String> endereco = const Value.absent(),
            Value<String> rodape = const Value.absent(),
            Value<String> impressora = const Value.absent(),
            Value<int> taxaPadrao = const Value.absent(),
            Value<int> largura = const Value.absent(),
            Value<String> horizonteOperacional = const Value.absent(),
            Value<String> razaoSocial = const Value.absent(),
            Value<String> whatsapp = const Value.absent(),
            Value<String> instagram = const Value.absent(),
            Value<String> logoPath = const Value.absent(),
            Value<bool> habilitarPix = const Value.absent(),
            Value<String> pixTipoChave = const Value.absent(),
            Value<String> pixChave = const Value.absent(),
            Value<String> pixFavorecido = const Value.absent(),
            Value<String> pixBanco = const Value.absent(),
            Value<String> pixCidade = const Value.absent(),
            Value<String> pixMensagem = const Value.absent(),
            Value<bool> pixImprimirQrCode = const Value.absent(),
            Value<bool> pixImprimirCopiaCola = const Value.absent(),
            Value<bool> pixGerarQrCodeAuto = const Value.absent(),
          }) =>
              ConfiguracoesEmpresaCompanion(
            id: id,
            empresa: empresa,
            telefone: telefone,
            endereco: endereco,
            rodape: rodape,
            impressora: impressora,
            taxaPadrao: taxaPadrao,
            largura: largura,
            horizonteOperacional: horizonteOperacional,
            razaoSocial: razaoSocial,
            whatsapp: whatsapp,
            instagram: instagram,
            logoPath: logoPath,
            habilitarPix: habilitarPix,
            pixTipoChave: pixTipoChave,
            pixChave: pixChave,
            pixFavorecido: pixFavorecido,
            pixBanco: pixBanco,
            pixCidade: pixCidade,
            pixMensagem: pixMensagem,
            pixImprimirQrCode: pixImprimirQrCode,
            pixImprimirCopiaCola: pixImprimirCopiaCola,
            pixGerarQrCodeAuto: pixGerarQrCodeAuto,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> empresa = const Value.absent(),
            Value<String> telefone = const Value.absent(),
            Value<String> endereco = const Value.absent(),
            Value<String> rodape = const Value.absent(),
            Value<String> impressora = const Value.absent(),
            Value<int> taxaPadrao = const Value.absent(),
            Value<int> largura = const Value.absent(),
            Value<String> horizonteOperacional = const Value.absent(),
            Value<String> razaoSocial = const Value.absent(),
            Value<String> whatsapp = const Value.absent(),
            Value<String> instagram = const Value.absent(),
            Value<String> logoPath = const Value.absent(),
            Value<bool> habilitarPix = const Value.absent(),
            Value<String> pixTipoChave = const Value.absent(),
            Value<String> pixChave = const Value.absent(),
            Value<String> pixFavorecido = const Value.absent(),
            Value<String> pixBanco = const Value.absent(),
            Value<String> pixCidade = const Value.absent(),
            Value<String> pixMensagem = const Value.absent(),
            Value<bool> pixImprimirQrCode = const Value.absent(),
            Value<bool> pixImprimirCopiaCola = const Value.absent(),
            Value<bool> pixGerarQrCodeAuto = const Value.absent(),
          }) =>
              ConfiguracoesEmpresaCompanion.insert(
            id: id,
            empresa: empresa,
            telefone: telefone,
            endereco: endereco,
            rodape: rodape,
            impressora: impressora,
            taxaPadrao: taxaPadrao,
            largura: largura,
            horizonteOperacional: horizonteOperacional,
            razaoSocial: razaoSocial,
            whatsapp: whatsapp,
            instagram: instagram,
            logoPath: logoPath,
            habilitarPix: habilitarPix,
            pixTipoChave: pixTipoChave,
            pixChave: pixChave,
            pixFavorecido: pixFavorecido,
            pixBanco: pixBanco,
            pixCidade: pixCidade,
            pixMensagem: pixMensagem,
            pixImprimirQrCode: pixImprimirQrCode,
            pixImprimirCopiaCola: pixImprimirCopiaCola,
            pixGerarQrCodeAuto: pixGerarQrCodeAuto,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConfiguracoesEmpresaTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ConfiguracoesEmpresaTable,
        ConfiguracoesEmpresaData,
        $$ConfiguracoesEmpresaTableFilterComposer,
        $$ConfiguracoesEmpresaTableOrderingComposer,
        $$ConfiguracoesEmpresaTableAnnotationComposer,
        $$ConfiguracoesEmpresaTableCreateCompanionBuilder,
        $$ConfiguracoesEmpresaTableUpdateCompanionBuilder,
        (
          ConfiguracoesEmpresaData,
          BaseReferences<_$AppDatabase, $ConfiguracoesEmpresaTable,
              ConfiguracoesEmpresaData>
        ),
        ConfiguracoesEmpresaData,
        PrefetchHooks Function()>;
typedef $$EventosPedidoTableCreateCompanionBuilder = EventosPedidoCompanion
    Function({
  Value<int> id,
  required int pedidoId,
  required String tipoEvento,
  required String titulo,
  Value<String> descricao,
  Value<int?> usuarioId,
  Value<String> usuarioNome,
  Value<int> versao,
  Value<DateTime> criadoEm,
});
typedef $$EventosPedidoTableUpdateCompanionBuilder = EventosPedidoCompanion
    Function({
  Value<int> id,
  Value<int> pedidoId,
  Value<String> tipoEvento,
  Value<String> titulo,
  Value<String> descricao,
  Value<int?> usuarioId,
  Value<String> usuarioNome,
  Value<int> versao,
  Value<DateTime> criadoEm,
});

final class $$EventosPedidoTableReferences extends BaseReferences<_$AppDatabase,
    $EventosPedidoTable, EventosPedidoData> {
  $$EventosPedidoTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PedidosTable _pedidoIdTable(_$AppDatabase db) =>
      db.pedidos.createAlias(
          $_aliasNameGenerator(db.eventosPedido.pedidoId, db.pedidos.id));

  $$PedidosTableProcessedTableManager get pedidoId {
    final $_column = $_itemColumn<int>('pedido_id')!;

    final manager = $$PedidosTableTableManager($_db, $_db.pedidos)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pedidoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EventosPedidoTableFilterComposer
    extends Composer<_$AppDatabase, $EventosPedidoTable> {
  $$EventosPedidoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoEvento => $composableBuilder(
      column: $table.tipoEvento, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titulo => $composableBuilder(
      column: $table.titulo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usuarioId => $composableBuilder(
      column: $table.usuarioId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get usuarioNome => $composableBuilder(
      column: $table.usuarioNome, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get versao => $composableBuilder(
      column: $table.versao, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnFilters(column));

  $$PedidosTableFilterComposer get pedidoId {
    final $$PedidosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pedidoId,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableFilterComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventosPedidoTableOrderingComposer
    extends Composer<_$AppDatabase, $EventosPedidoTable> {
  $$EventosPedidoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoEvento => $composableBuilder(
      column: $table.tipoEvento, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titulo => $composableBuilder(
      column: $table.titulo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usuarioId => $composableBuilder(
      column: $table.usuarioId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get usuarioNome => $composableBuilder(
      column: $table.usuarioNome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get versao => $composableBuilder(
      column: $table.versao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnOrderings(column));

  $$PedidosTableOrderingComposer get pedidoId {
    final $$PedidosTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pedidoId,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableOrderingComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventosPedidoTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventosPedidoTable> {
  $$EventosPedidoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipoEvento => $composableBuilder(
      column: $table.tipoEvento, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<int> get usuarioId =>
      $composableBuilder(column: $table.usuarioId, builder: (column) => column);

  GeneratedColumn<String> get usuarioNome => $composableBuilder(
      column: $table.usuarioNome, builder: (column) => column);

  GeneratedColumn<int> get versao =>
      $composableBuilder(column: $table.versao, builder: (column) => column);

  GeneratedColumn<DateTime> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  $$PedidosTableAnnotationComposer get pedidoId {
    final $$PedidosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pedidoId,
        referencedTable: $db.pedidos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PedidosTableAnnotationComposer(
              $db: $db,
              $table: $db.pedidos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventosPedidoTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventosPedidoTable,
    EventosPedidoData,
    $$EventosPedidoTableFilterComposer,
    $$EventosPedidoTableOrderingComposer,
    $$EventosPedidoTableAnnotationComposer,
    $$EventosPedidoTableCreateCompanionBuilder,
    $$EventosPedidoTableUpdateCompanionBuilder,
    (EventosPedidoData, $$EventosPedidoTableReferences),
    EventosPedidoData,
    PrefetchHooks Function({bool pedidoId})> {
  $$EventosPedidoTableTableManager(_$AppDatabase db, $EventosPedidoTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventosPedidoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventosPedidoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventosPedidoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> pedidoId = const Value.absent(),
            Value<String> tipoEvento = const Value.absent(),
            Value<String> titulo = const Value.absent(),
            Value<String> descricao = const Value.absent(),
            Value<int?> usuarioId = const Value.absent(),
            Value<String> usuarioNome = const Value.absent(),
            Value<int> versao = const Value.absent(),
            Value<DateTime> criadoEm = const Value.absent(),
          }) =>
              EventosPedidoCompanion(
            id: id,
            pedidoId: pedidoId,
            tipoEvento: tipoEvento,
            titulo: titulo,
            descricao: descricao,
            usuarioId: usuarioId,
            usuarioNome: usuarioNome,
            versao: versao,
            criadoEm: criadoEm,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int pedidoId,
            required String tipoEvento,
            required String titulo,
            Value<String> descricao = const Value.absent(),
            Value<int?> usuarioId = const Value.absent(),
            Value<String> usuarioNome = const Value.absent(),
            Value<int> versao = const Value.absent(),
            Value<DateTime> criadoEm = const Value.absent(),
          }) =>
              EventosPedidoCompanion.insert(
            id: id,
            pedidoId: pedidoId,
            tipoEvento: tipoEvento,
            titulo: titulo,
            descricao: descricao,
            usuarioId: usuarioId,
            usuarioNome: usuarioNome,
            versao: versao,
            criadoEm: criadoEm,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EventosPedidoTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({pedidoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (pedidoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pedidoId,
                    referencedTable:
                        $$EventosPedidoTableReferences._pedidoIdTable(db),
                    referencedColumn:
                        $$EventosPedidoTableReferences._pedidoIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EventosPedidoTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventosPedidoTable,
    EventosPedidoData,
    $$EventosPedidoTableFilterComposer,
    $$EventosPedidoTableOrderingComposer,
    $$EventosPedidoTableAnnotationComposer,
    $$EventosPedidoTableCreateCompanionBuilder,
    $$EventosPedidoTableUpdateCompanionBuilder,
    (EventosPedidoData, $$EventosPedidoTableReferences),
    EventosPedidoData,
    PrefetchHooks Function({bool pedidoId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GruposPrecoTableTableManager get gruposPreco =>
      $$GruposPrecoTableTableManager(_db, _db.gruposPreco);
  $$ProdutosTableTableManager get produtos =>
      $$ProdutosTableTableManager(_db, _db.produtos);
  $$FaixasPrecoTableTableManager get faixasPreco =>
      $$FaixasPrecoTableTableManager(_db, _db.faixasPreco);
  $$ClientesTableTableManager get clientes =>
      $$ClientesTableTableManager(_db, _db.clientes);
  $$LocaisEntregaTableTableManager get locaisEntrega =>
      $$LocaisEntregaTableTableManager(_db, _db.locaisEntrega);
  $$OrigensPedidoTableTableManager get origensPedido =>
      $$OrigensPedidoTableTableManager(_db, _db.origensPedido);
  $$PrioridadesPedidoTableTableManager get prioridadesPedido =>
      $$PrioridadesPedidoTableTableManager(_db, _db.prioridadesPedido);
  $$PedidosTableTableManager get pedidos =>
      $$PedidosTableTableManager(_db, _db.pedidos);
  $$ItensPedidoTableTableManager get itensPedido =>
      $$ItensPedidoTableTableManager(_db, _db.itensPedido);
  $$EstoqueAtualTableTableManager get estoqueAtual =>
      $$EstoqueAtualTableTableManager(_db, _db.estoqueAtual);
  $$MovimentacoesEstoqueTableTableManager get movimentacoesEstoque =>
      $$MovimentacoesEstoqueTableTableManager(_db, _db.movimentacoesEstoque);
  $$ConfiguracoesEmpresaTableTableManager get configuracoesEmpresa =>
      $$ConfiguracoesEmpresaTableTableManager(_db, _db.configuracoesEmpresa);
  $$EventosPedidoTableTableManager get eventosPedido =>
      $$EventosPedidoTableTableManager(_db, _db.eventosPedido);
}
