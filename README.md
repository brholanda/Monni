# Monni

Aplicação móvel minimalista de controlo financeiro pessoal, em Flutter com armazenamento local SQLite.

## Funcionalidades

- **Entradas** — registo de título, valor e data.
- **Gastos** — registo de valor, categoria, descrição opcional e data.
- **Resumo Mensal** — total de entradas, total de gastos, saldo final, gastos agrupados por categoria e percentagem por categoria com gráfico circular e barras de proporção.
- Navegação por mês em todos os ecrãs, edição por toque e eliminação por deslize.
- Tema claro/escuro automático, Material 3, layout responsivo (Android e iOS).

## Como arrancar

O repositório contém apenas o código Dart e a configuração. Gere as pastas nativas e instale as dependências:

```bash
flutter create --platforms=android,ios --project-name monni .
flutter pub get
flutter run
```

O comando `flutter create` não substitui os ficheiros já existentes em `lib/` nem o `pubspec.yaml`.

## Estrutura

```
lib/
  main.dart                  # arranque e tema da app
  data/app_database.dart     # SQLite (sqflite): tabelas incomes e expenses
  models/                    # Income, Expense, MonthlySummary, categorias
  screens/                   # home, entradas, gastos, resumo e formulários
  widgets/                   # seletor de mês, estado vazio
  theme/app_theme.dart       # tema Material 3 e AppCard
  utils/formatters.dart      # moeda, datas e validação de valores
```

## Base de dados

Ficheiro `monni.db` no armazenamento privado da aplicação.

| incomes | expenses |
| --- | --- |
| id, title, amount, date | id, amount, category, description, date |

As datas são guardadas em ISO 8601 e os totais mensais são calculados em SQL com consultas parametrizadas.