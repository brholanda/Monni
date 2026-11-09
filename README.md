# Monni

Aplicação móvel minimalista de controlo financeiro pessoal, em Flutter com armazenamento local SQLite.

## Funcionalidades

- **Entradas** — registo de título, valor e data.
- **Gastos** — registo de valor, categoria, descrição opcional e data.
- **Resumo Mensal** — total de entradas, total de gastos, saldo final, gastos agrupados por categoria e percentagem por categoria com gráfico circular e barras de proporção.
- Navegação por mês em todos os ecrãs, edição por toque e eliminação por deslize.
- Tema claro/escuro automático, Material 3, layout responsivo (Android e iOS).
- **Backup** — exportação e restauração de entradas, gastos, categorias e tamanho da fonte pelo menu principal.

## Backup e transferência

No menu principal, abra **Backup** e selecione **Exportar backup**. O aplicativo gera um arquivo `monni-backup-<data>.json` e abre o compartilhamento do sistema para enviá-lo ou guardá-lo, por exemplo, no Google Drive ou em Arquivos no iOS.

No outro celular, instale o Monni, disponibilize o arquivo e selecione **Backup > Restaurar backup**. Confira a data e a quantidade de registros antes de confirmar. A restauração substitui todos os dados atuais, não mescla registros. Exporte os dados atuais primeiro se precisar preservá-los.

O formato é versionado, tem limite de 20 MB e inclui todos os meses, categorias desativadas e o tamanho da fonte. Arquivos inválidos são rejeitados; uma falha na transação mantém os dados anteriores. O PIN e a configuração de biometria não são transferidos. O backup não é criptografado: compartilhe apenas com destinatários de confiança e mantenha-o em local seguro.

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