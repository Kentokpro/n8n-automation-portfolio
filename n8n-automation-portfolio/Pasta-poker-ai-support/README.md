# Pasta Poker AI Support Manager

Production-grade AI support automation, построенная на **n8n**, **Telegram Bot API**, **AI-агентах**, **API OpenRouter**, **OCR** и **n8n Data Tables**.

Проект автоматизирует работу службы поддержки: принимает обращения игроков, классифицирует тип запроса, анализирует скриншоты, создаёт заявки, отправляет структурированные запросы во внутренний чат менеджеров, пересылает скриншоты при необходимости, ожидает ответы менеджеров и возвращает итоговый ответ игроку.

> В репозитории находится portfolio-версия production workflow.  
> Чувствительные данные, реальные Telegram chat ID, webhook ID, внутренние user ID, production identifiers, приватные данные и credentials удалены или заменены.

---

## Обзор проекта

**Pasta Poker AI Support Manager** — это AI-powered Telegram-система поддержки, которая автоматизирует значительную часть ручной работы оператора.

Система принимает запрос игрока в личном Telegram-боте, определяет тип обращения, собирает необходимые данные, анализирует скриншоты, создаёт и обновляет заявки, отправляет запрос во внутренний чат менеджеров, отслеживает ответы через Telegram reply-chain и возвращает результат игроку.

Workflow спроектирован как **AI orchestration system**, а не как обычный заскриптованный Telegram-бот с жёсткими сценариями.

---

## Бизнес-цель

Цель проекта — сократить ручную нагрузку на службу поддержки за счёт автоматизации следующих процессов:

- первая линия поддержки игроков;
- обработка проблем с доступом к аккаунту;
- обработка депозитов и выводов;
- анализ скриншотов;
- создание структурированных заявок;
- маршрутизация к ответственным менеджерам;
- сопоставление ответов из внутреннего Telegram-чата с заявками;
- автоматический follow-up игроку;
- передача нестандартных кейсов оператору.

---

## Основные возможности

- Telegram-бот поддержки для личных обращений игроков
- AI-классификация сценариев
- Multi-agent orchestration
- OCR-анализ скриншотов
- Ticket lifecycle management
- Поддержка нескольких активных заявок у одного игрока
- Reply-based ticket correlation
- Интеграция с внутренним чатом менеджеров
- Operator handoff flow
- Пересылка скриншотов менеджерам и оператору
- Безопасный fallback для неясных обращений
- Строгие JSON-контракты между AI-агентами и n8n-нодами
- Production-oriented error handling и уведомления разработчику

---

## Технологический стек

| Слой | Технология |
|---|---|
| Workflow orchestration | n8n |
| Messaging | Telegram Bot API |
| AI orchestration | n8n AI Agent nodes |
| LLM provider | OpenRouter |
| Models | GPT-4.1, GPT-4o, GPT-5 mini |
| OCR | Tesseract OCR + AI normalization |
| Database | n8n Data Tables |
| Runtime | VPS / Docker-based n8n environment |
| Error alerts | Telegram developer notifications |

---

## Краткое описание архитектуры

Workflow построен вокруг нескольких специализированных AI-агентов.

### A1 — Главный AI-оркестратор

A1 — это верхнеуровневый маршрутизатор.

Задачи:

- определить домен обращения;
- отправить сообщение в нужный сценарий;
- отделить проблемы с аккаунтом от депозитов/выводов;
- не принимать бизнес-решения;
- не выбирать конкретную заявку;
- не обновлять базу напрямую.

---

### SC1 Agent — Агент проблем с аккаунтом и доступом

Обрабатывает проблемы, связанные с аккаунтом игрока и входом в систему.

Поддерживаемые кейсы:

- подтверждение входа с нового устройства;
- проблемы доступа к аккаунту;
- security block / ban;
- invalid credentials / error 5028;
- required account verification;
- нестандартные проблемы аккаунта;
- неясные проблемы аккаунта, где нужны дополнительные данные.

Задачи:

- решить, создавать новую заявку или обновлять существующую;
- проверить наличие скриншота;
- извлечь website, login и password;
- записать смысловое описание проблемы в `problem_text`;
- решить, нужно ли отправлять запрос во внутренний чат менеджеров;
- решить, нужен ли handoff оператору.

---

### SC2 Agent — Агент депозитов и выводов

Обрабатывает запросы на deposit / withdraw по игровому аккаунту.

Обязательные поля:
- website;
- username;
- password;
- operation type: `deposit` или `withdraw`;
- amount.

Задачи:

- извлечь детали операции;
- не смешивать старые и новые финансовые заявки;
- определять дубли операций;
- создавать или обновлять заявки;
- подготавливать запрос для внутреннего менеджера.

---

### A2 — Диспетчер внутреннего чата менеджеров

A2 подготавливает чистое англоязычное сообщение для внутреннего чата менеджеров.

Задачи:

- проверить, готова ли заявка к отправке;
- преобразовать данные заявки в понятный текст для менеджеров;
- не раскрывать внутреннюю orchestration-логику;
- вернуть `send_it=true` только если все обязательные поля собраны.

---

### A3 — Оркестратор ответов менеджеров

A3 обрабатывает ответы из внутреннего чата менеджеров.

Задачи:

- работать только с Telegram reply-сообщениями;
- сопоставлять ответ менеджера с заявкой через `it_request_message_id` или `it_screenshot_message_id`;
- определять тип ответа:
  - финальный ответ игроку;
  - запрос уточнения у игрока;
  - необходимость уточнить у менеджера;
  - нерелевантное сообщение;
- переводить ответ на язык игрока;
- сохранять коды, ссылки, URL, домены и credentials без изменений;
- закрывать заявку после успешного решения.

Правило безопасности:

> A3 может отправить сообщение игроку только если заявка технически сопоставлена через надёжную reply-correlation.

---

### A4 — OCR Normalizer

A4 получает сырой OCR-текст и превращает его в полезный структурированный результат.

Задачи:

- очистить OCR-текст;
- убрать шум;
- сохранить исходный смысл;
- сформировать короткое описание скриншота;
- оценить confidence;
- определить язык скриншота.

---

## Основная логика workflow

```text
Telegram Trigger
  ↓
Ignore bot messages
  ↓
Normalize Telegram update
  ↓
Route by chat type
  ├── Private player chat
  │     ↓
  │   Load active tickets
  │     ↓
  │   Optional screenshot OCR
  │     ↓
  │   Build A1 context
  │     ↓
  │   A1 scenario routing
  │     ├── SC1 account/access issue
  │     ├── SC2 deposit/withdraw
  │     └── SC0 generic fallback
  │     ↓
  │   Create/update ticket
  │     ↓
  │   Send response to player
  │     ↓
  │   Optional dispatch to manager group
  │     ↓
  │   Optional operator handoff
  │
  └── Internal manager group
        ↓
      Reply filter
        ↓
      Find ticket by reply message ID
        ↓
      A3 manager reply processing
        ├── Send final answer to player
        ├── Ask player for clarification
        ├── Ask manager to clarify ticket
        └── Ignore irrelevant message
```

---

## Жизненный цикл заявки

Workflow использует ticket-based state machine.

Основные статусы:

| Status | Значение |
|---|---|
| `need_screenshot` | Для обработки нужен скриншот |
| `need_details` | Не хватает обязательных данных аккаунта или операции |
| `ready_for_it` | Заявка готова к отправке во внутренний чат менеджеров |
| `waiting_it_reply` | Запрос отправлен, workflow ожидает ответ менеджера |
| `waiting_player_details` | Менеджер запросил дополнительные данные у игрока |
| `manager_help` | Кейс передан живому оператору |
| `closed` | Заявка решена и закрыта |

---

## Модель данных

Workflow использует n8n Data Table `pasta_poker_tickets`.

Основные поля:

| Field | Назначение |
|---|---|
| `ticket_id` | Уникальный идентификатор заявки |
| `is_active` | Активна ли заявка |
| `status` | Текущий статус заявки |
| `scenario_key` | Тип сценария |
| `telegram_user_id` | Telegram ID игрока |
| `username` | Telegram username игрока или fallback name |
| `user_chat_id` | Chat ID для ответа игроку |
| `problem_text` | Смысловое описание проблемы |
| `user_lang` | Язык игрока |
| `has_screenshot` | Получен ли скриншот |
| `screenshot_file_id` | Telegram file ID скриншота |
| `details_website` | Сайт игрового аккаунта |
| `details_username` | Логин игрового аккаунта |
| `details_password` | Пароль игрового аккаунта |
| `details_amount` | Сумма депозита/вывода |
| `details_operation` | Deposit или withdraw |
| `details_complete` | Все ли обязательные данные собраны |
| `it_sent` | Отправлялась ли заявка во внутренний чат менеджеров |
| `it_request_message_id` | Message ID для reply-correlation |
| `it_screenshot_message_id` | Message ID скриншота для reply-correlation |
| `it_reply_text` | Краткое содержание ответа менеджера |
| `pending_user_action` | Ожидаемое действие от игрока |
| `pending_manager_request` | Запрос уточнения от менеджера |
| `last_bot_message_id` | Последнее сообщение бота для private reply tracking |
| `last_bot_prompt_kind` | Тип последнего prompt-сообщения бота |

---

## Поддерживаемые сценарии

### SC0 — Generic Fallback

Используется, когда сообщение невозможно уверенно классифицировать.

Примеры:

- пустое приветствие;
- неясное сообщение;
- нерелевантный текст;
- неоднозначный запрос без достаточного контекста.

Бот просит игрока понятнее описать проблему.

---

### SC1 — Проблемы аккаунта и доступа

Используется для проблем, связанных с аккаунтом и входом.

Поддерживаемые подтипы:

| Subtype | Описание |
|---|---|
| `new_device_confirm` | Игроку нужно подтверждение входа с нового устройства |
| `error_with_account_access` | Security block, ban или проблема доступа |
| `error_5028` | Invalid credentials / error 5028 |
| `verification_required` | Требуется подтверждение email или телефона |
| `nonstandard_account_issue` | Понятная, но нестандартная проблема аккаунта |
| `unknown` | Скриншот или сообщение недостаточно понятны |

Правила:

- Для SC1 требуется скриншот.
- Перед escalation нужны website, username и password.
- Некоторые подтипы отправляются во внутренний чат менеджеров.
- Некоторые кейсы передаются живому оператору.
- Unknown-кейсы не отправляются автоматически менеджерам.

---

### SC2 — Deposit / Withdraw

Используется для запросов на пополнение или вывод.

Обязательные данные:

```text
website
username
password
operation
amount
```

Правила:

- Скриншот не требуется.
- Operation должна быть `deposit` или `withdraw`.
- Новые операции нельзя склеивать со старыми активными тикетами, если signature отличается.
- Дубликаты операций определяются через website + username + operation + amount.

---

## Reply Correlation

Внутренний manager group flow основан на Telegram reply-chain.

Workflow сохраняет:

- `it_request_message_id`
- `it_screenshot_message_id`

Когда менеджер отвечает на исходное сообщение заявки или на скриншот, A3 может безопасно сопоставить ответ с правильной заявкой.

Это защищает систему от отправки ответа не тому игроку.

---

## Работа со скриншотами

Workflow поддерживает скриншоты от игроков.

Текущее поведение:

- определяет photo или document attachment;
- извлекает Telegram `file_id`;
- запускает OCR для текста скриншота;
- нормализует OCR-результат через AI-агента;
- сохраняет reference скриншота в заявке;
- пересылает скриншот во внутренний чат менеджеров или оператору, если это требуется.

В portfolio-версии скриншоты представлены только через placeholder file IDs.

---

## Надёжность

В workflow используются production-oriented reliability patterns:

- фильтрация сообщений от ботов;
- маршрутизация по типу чата;
- поиск активных заявок;
- поддержка нескольких активных заявок;
- reply-based checkpointing;
- отслеживание `last_bot_message_id`;
- отслеживание `pending_user_action`;
- retry на Telegram-отправках;
- error branches для критичных точек доставки;
- уведомления разработчику в Telegram;
- очистка текста перед отправкой HTML-formatted Telegram messages;
- строгие JSON-контракты для AI-агентов.

---

## Security Notes

Публичная portfolio-версия не содержит:

- реальные Telegram chat IDs;
- реальные webhook IDs;
- реальные operator IDs;
- реальные manager group IDs;
- реальные credentials игроков;
- production API keys;
- персональные данные;
- внутренние production identifiers.

Перед импортом workflow в реальный n8n instance нужно настроить переменные окружения или credentials:

```env
TELEGRAM_BOT_TOKEN=
OPENROUTER_API_KEY=
N8N_ENCRYPTION_KEY=
```

---

## AI Agent Contracts

Все агенты должны возвращать строгий JSON.

Workflow намеренно разделяет:

- routing;
- scenario business logic;
- manager dispatch;
- manager reply handling;
- OCR normalization.

Это снижает prompt drift, предотвращает перегрузку одного агента и упрощает отладку workflow.

---

## Почему такая архитектура

Проект избегает типичной ошибки — построения жёсткого Telegram decision tree.

Вместо этого workflow использует:

- deterministic n8n nodes для транспорта, routing, database operations и safety gates;
- AI agents для semantic classification и language-sensitive decision-making;
- strict JSON contracts для контроля AI-output;
- technical gates перед чувствительными действиями.

Итоговая hybrid architecture:

```text
n8n = reliable execution layer
AI agents = controlled semantic decision layer
Data Tables = workflow memory and ticket state
Telegram = user and manager interface
```

---

## Ключевые выводы из проекта:

1. AI не должен управлять всем подряд.
2. n8n должен выполнять, валидировать и маршрутизировать.
3. AI-агентам нужны строгие contracts.
4. Reply correlation безопаснее, чем угадывание по свободному тексту.
5. Несколько активных заявок требуют явной target selection logic.
6. Скриншоты нужно использовать как evidence, а не как сырой chat history.

---

## Ограничения

Ограничения текущей portfolio-версии:

- sanitized workflow не запустится без замены placeholders;
- схему n8n Data Table нужно воссоздать вручную;
- external database migration scripts не включены;
- automated test runner не включён;
- хранение скриншотов основано на Telegram file references;
- production secrets и chat IDs намеренно заменены.

---

## Структура репозитория

```text
pasta-poker-ai-support/
├── README.md
├── workflow/
│   ├── pasta-poker-ai-support.sanitized.workflow.json 
│   ├── Dep-poker-ai-support.json
│   ├── auto-notifications-on-requests.json
├── prompts/
│   ├── a1-orchestrator.md
│   ├── sc1-account-issue-agent.md
│   ├── sc2-deposit-withdraw-agent.md
│   ├── a2-italy-dispatcher.md
│   ├── a3-manager-reply-orchestrator.md
│   └── a4-ocr-normalizer.md
└── Screen/
    ├── Pasta-poker-ai-support.sanitized.workflow.png
    ├── Dep-poker-ai-support.png
    └── Auto-notifications-on-requests.png
```

---

## Статус

Частный проект завершён, запущен и работает.

В репозитории находится очищенная portfolio-версия для демонстрации архитектуры, подхода к AI-оркестрации и production automation.

---

