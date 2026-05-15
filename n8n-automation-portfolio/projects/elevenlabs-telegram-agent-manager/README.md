

## 🤖 ElevenLabs Telegram Bot Agent Manager

Production-oriented automation project для управления голосовыми агентами ElevenLabs через Telegram-бота, построенный на **n8n**, **MySQL**, **Telegram Bot API** и **ElevenLabs REST API**.

Система позволяет Telegram-пользователям безопасно просматривать и управлять только своими ElevenLabs agents, обновлять prompt агента, менять welcome message и создавать Knowledge Base content прямо из Telegram.

---

## 📌 Обзор

**ElevenLabs Telegram Agent Manager** — это автоматизированный backend-проект, который превращает Telegram в лёгкую панель управления для ElevenLabs voice agents.

Проект подходит для сценариев, где пользователям нужен простой интерфейс управления AI voice agents без прямого входа в ElevenLabs dashboard.

Основные возможности:

- Telegram-интерфейс для пользователей
- Безопасная модель владения user → agent
- MySQL для хранения пользователей, агентов, сессий и логов
- Интеграция с ElevenLabs API
- Обновление prompt агента
- Обновление welcome message
- Создание Knowledge Base document
- Логирование операций
- Логирование raw Telegram payload для отладки

---

## 🧩 Технологический стек

| Компонент | Технология |
|---|---|
| Платформа автоматизации | n8n |
| База данных | MySQL 8.4 |
| Интерфейс общения | Telegram Bot API |
| Платформа голосовых AI-агентов | ElevenLabs Conversational AI |
| API-интеграция | REST API через n8n HTTP Request nodes |
| Runtime | Docker Compose |
| Среда развёртывания | VPS |

---

## 🏗️ Архитектура

Telegram User
    ↓
Telegram Bot
    ↓
n8n Workflow
    ↓
MySQL
    ├── telegram_users
    ├── elevenlabs_agents
    ├── user_sessions
    ├── update_logs
    └── telegram_payload_logs
    ↓
ElevenLabs REST API
    ↓
ElevenLabs Voice Agents

##⚙️ Основная логика workflow

/start
  ↓
Главное меню
  ↓
Мои агенты
  ↓
Загрузка agents из MySQL по telegram_user_id
  ↓
Пользователь выбирает агента
  ↓
Проверка владения агентом в MySQL
  ↓
Сохранение выбранного агента в user_sessions
  ↓
Показ меню действий агента
  ↓
Пользователь выбирает действие:
  ├── Обновить prompt
  ├── Обновить welcome message
  └── Создать Knowledge Base document
  ↓
Бот ожидает новый текст
  ↓
Повторная проверка активной сессии и владения агентом
  ↓
REST API request в ElevenLabs
  ↓
Запись update log
  ↓
Сброс session state
  ↓
Сообщение об успехе в Telegram


## ✅ Возможности
👤 Управление Telegram-пользователями

Workflow извлекает и нормализует данные пользователя из входящих Telegram updates:

telegram_user_id
username
first_name
last_name
chat_id
message_text
callback_data

Эти данные используются для маршрутизации, проверки доступа, логирования и управления пользовательской сессией.


## 🤖 Список агентов

Пользователь может запросить список доступных ему ElevenLabs agents.

Список загружается из MySQL по текущему Telegram user ID.

Пример поведения:
User A	Видит 2 назначенных agents
User B	Видит 1 назначенного agent
User C	Не видит agents(нет агентов в базе)

Пользователь не может видеть agents, принадлежащие другим Telegram-пользователям.

## 🔐 Безопасность на основе владения агентом

Безопасность реализована на уровне базы данных и workflow.

Перед любой операцией с агентом workflow проверяет:
SELECT
    elevenlabs_agent_id,
    display_name
FROM elevenlabs_agents
WHERE elevenlabs_agent_id = :selected_agent_id
  AND owner_telegram_user_id = :telegram_user_id
  AND is_active = 1;

Это не позволяет пользователю получить доступ или изменить agent, который ему не принадлежит, даже если callback data будет изменён вручную.

Workflow не доверяет данным из Telegram-кнопок как источнику авторизации.

## 🧠 Управление сессиями

Текущее состояние пользователя хранится в таблице user_sessions.

Сессия отслеживает:
выбранный ElevenLabs agent
текущее действие
ожидает ли бот текст для prompt, welcome message или Knowledge Base content

Поддерживаемые состояния сессии:
idle
awaiting_prompt
awaiting_welcome_message
awaiting_knowledge_base

Это позволяет боту понимать, как обработать следующее текстовое сообщение пользователя.


## ✏️ Обновление prompt

Пользователь может обновить system prompt выбранного ElevenLabs agent прямо из Telegram.

Flow:
Выбор агента
→ Нажатие "Обновить prompt"
→ Отправка нового prompt text
→ Проверка владения агентом
→ PATCH ElevenLabs agent config
→ Запись лога
→ Сброс сессии

Тип запроса к ElevenLabs API:
PATCH /v1/convai/agents/{agent_id}

Пример payload:
{
  "conversation_config": {
    "agent": {
      "prompt": {
        "prompt": "You are a polite support agent. Answer briefly and clearly."
      }
    }
  },
  "version_description": "Prompt updated from Telegram bot"
}


## 👋 Обновление welcome message

Пользователь может обновить first message / welcome message выбранного ElevenLabs agent.

Flow:
Выбор агента
→ Нажатие "Обновить welcome message"
→ Отправка нового welcome text
→ Проверка владения агентом
→ PATCH ElevenLabs agent config
→ Запись лога
→ Сброс сессии

Пример payload:
{
  "conversation_config": {
    "agent": {
      "first_message": "Hello! How can I help you today?"
    }
  },
  "version_description": "Welcome message updated from Telegram bot"
}

## 📚 Создание Knowledge Base content

Пользователь может отправить текст из Telegram и создать новый ElevenLabs Knowledge Base document.

Flow:
Выбор агента
→ Нажатие "Обновить knowledge base"
→ Отправка текстового content
→ Проверка владения агентом
→ Создание Knowledge Base document в ElevenLabs
→ Запись лога
→ Сброс сессии

Тип запроса к ElevenLabs API:
POST /v1/convai/knowledge-base/text

Пример payload:
{
  "text": "This is a Knowledge Base document created from Telegram via n8n.",
  "name": "KB update - Agent Name - 2026-05-15T12:00:00.000Z"
}

## 🗄️ Структура базы данных

Проект использует MySQL как application database.

Файл структуры:
elevenlabs-bot-schema.sql

Файл seed-данных:
elevenlabs-bot-seed.sql

## 🧱 Таблицы
telegram_users

Хранит Telegram-пользователей, которым разрешено использовать бота.

Основные поля:
| Поле               | Описание             |
| ------------------ | -------------------- |
| `telegram_user_id` | Telegram user ID     |
| `username`         | Telegram username    |
| `first_name`       | Имя пользователя     |
| `last_name`        | Фамилия пользователя |
| `is_active`        | Статус пользователя  |

elevenlabs_agents
Хранит ElevenLabs agents и связь с владельцем в Telegram.

Основные поля:
| Поле                     | Описание                                  |
| ------------------------ | ----------------------------------------- |
| `elevenlabs_agent_id`    | ElevenLabs agent ID                       |
| `display_name`           | имя агента               |
| `owner_telegram_user_id` | Telegram user, которому принадлежит agent |
| `is_active`              | Статус доступности agent                  |

Безопасность строится на паре:
owner_telegram_user_id + elevenlabs_agent_id

user_sessions
Хранит текущее состояние взаимодействия для каждого Telegram-пользователя.

Основные поля:
| Поле                           | Описание                   |
| ------------------------------ | -------------------------- |
| `telegram_user_id`             | Текущий Telegram user      |
| `selected_elevenlabs_agent_id` | Выбранный agent            |
| `current_action`               | Текущее ожидаемое действие |

update_logs
Хранит операции обновления agents.

Основные поля:
| Поле                       | Описание                                |
| -------------------------- | --------------------------------------- |
| `telegram_user_id`         | Пользователь, который выполнил действие |
| `elevenlabs_agent_id`      | Целевой ElevenLabs agent                |
| `action_type`              | Тип обновления                          |
| `status`                   | success или failed                      |
| `new_value_preview`        | Превью отправленного текста             |
| `http_status_code`         | HTTP status API-ответа                  |
| `error_message`            | Детали ошибки, если есть                |
| `elevenlabs_response_json` | Сводка API-ответа                       |

Поддерживаемые типы действий:
update_prompt
update_welcome_message
update_knowledge_base
telegram_payload_logs

Хранит raw Telegram payloads для отладки и аудита.

Основные поля:
| Поле               | Описание                           |
| ------------------ | ---------------------------------- |
| `telegram_user_id` | Telegram user ID                   |
| `update_type`      | message / callback_query / unknown |
| `raw_payload_json` | Сырой Telegram update payload      |
| `created_at`       | Время создания записи              |

## 🧪 Seed-данные

Проект включает установленные seed-данные для Telegram-пользователей и ElevenLabs agents.
Пример распределения:
| User   |  Telegram ID  | Agents   |
| ------ |  -----------: | -------- |
| User A | (Telegram ID) | 2 agents |
| User B | (Telegram ID) | 1 agent  |
| User C | (Telegram ID) | 0 agents |

Это позволяет тестировать:

стандартный пользовательский доступ
владение несколькими agents
пользователя без agents
изоляцию доступа между пользователями

## 🔐 Модель безопасности

В проекте используется простая и надёжная модель доступа:

Telegram user ID → MySQL ownership check → разрешённая операция с agent

Принципы безопасности:
Пользователь видит только agents, назначенные его Telegram ID.
Пользователь может выбрать только agent, которым владеет.
Каждая операция обновления повторно проверяет владение agent.
Callback data не используется как доказательство права доступа.
API keys хранятся в n8n credentials, а не внутри workflow-кода.

## 🔑 Credentials

Workflow требует следующие credentials в n8n:
**Telegram API**

Используется для:
получения сообщений
получения callback queries
отправки сообщений от бота
отправки inline keyboard menus

**MySQL**

Пример подключения:
Host: mysql
Port: 3306
Database: elevenlabs_bot
User: elevenbot
Password: stored in environment / n8n credentials

**ElevenLabs**

Тип credential: HTTP Header Auth

Header: xi-api-key: <ELEVENLABS_API_KEY>

Используется для:
обновления agent configuration
создания Knowledge Base documents

##  🐳 Deployment Notes

Проект развёрнут через Docker Compose.

Рекомендуемая инфраструктура:
n8n
MySQL
Docker internal network
MySQL должен быть доступен только внутри Docker network.

## 🚀 Установка и запуск
1. Импортировать SQL schema
mysql -u root -p < sql/elevenlabs-bot-schema.sql

2. Импортировать seed-данные
mysql -u root -p < sql/elevenlabs-bot-seed.sql

3. Импортировать n8n workflow

В n8n:

Workflows
→ Import from file
→ Select elevenlabs-telegram-agent-manager.json

4. Настроить credentials

В n8n нужно настроить:
Telegram API
MySQL
ElevenLabs HTTP Header Auth




----------------------------------------------------------------------------------------------------------------

###English version:

## 🤖 ElevenLabs Telegram Bot Agent Manager

A production-oriented automation project for managing ElevenLabs voice agents via a Telegram bot built on **n8n**, **MySQL**, **Telegram Bot API** and **ElevenLabs REST API**.

The system allows Telegram users to securely view and manage only their ElevenLabs agents, update the agent's prompt, change the welcome message, and create Knowledge Base content directly from Telegram.

---

## 📌 Overview

**ElevenLabs Telegram Agent Manager** is an automated backend project that turns Telegram into a lightweight dashboard for ElevenLabs voice agents.

The project is suitable for scenarios where users need a simple AI voice agents management interface without directly logging into the ElevenLabs dashboard.

Main features:

- Telegram interface for users
- Secure ownership model of user → agent
- MySQL for storing users, agents, sessions, and logs
- Integration with the ElevenLabs API
- Updating the prompt agent
- Welcome message update
- Creation of a Knowledge Base document
- Logging of operations
- Logging of the raw Telegram payload for debugging

---

## 🧩 Technology stack

| Component | Technology |
|---|---|
| Automation platform | n8n |
| Database | MySQL 8.4 |
| Communication interface | Telegram Bot API |
| Platform for voice AI agents | ElevenLabs Conversational AI |
| API integration | REST API via n8n HTTP Request nodes |
| Runtime | Docker Compose |
| Deployment environment | VPS |

---

## 🏗️ Architecture

Telegram User
    ↓
Telegram Bot
    ↓
n8n Workflow
    ↓
MySQL
    ├── telegram_users
    ├── elevenlabs_agents
    ├── user_sessions
    ├── update_logs
    └── telegram_payload_logs
    ↓
ElevenLabs REST API
    ↓
ElevenLabs Voice Agents

##⚙️ The main logic of workflow

/start
  ↓
Main Menu
  ↓
My agents
↓
Downloading agents from MySQL by telegram_user_id
↓
The user selects an agent
  ↓
Agent ownership verification in MySQL

Saving the selected agent in user_sessions
  ↓
Showing the agent's action menu
  ↓
The user chooses an action:
├── Refresh prompt
  ─── Update welcome message
└── Create Knowledge Base document
  ↓
The bot is waiting for a new text

Re-checking the active session and agent ownership

REST API request in

ElevenLabs , update log entry
  , Session state reset

  ↓
Success message in Telegram


## ✅ Features
👤 Telegram User Management

Workflow extracts and normalizes user data from incoming Telegram updates:

telegram_user_id
username
first_name
last_name
chat_id
message_text
callback_data

This data is used for routing, access verification, logging, and user session management.


## 🤖 List of agents

The user can request a list of available ElevenLabs agents.

The list is loaded from MySQL using the current Telegram user ID.

Example of behavior:
User A Sees 2 assigned agents
User B Sees 1 assigned agent
User C does not see agents (there are no agents in the database)

The user cannot see agents belonging to other Telegram users.

Agent-based security

Security is implemented at the database and workflow levels.

Before any operation with the agent, workflow checks:
SELECT
    elevenlabs_agent_id,
    display_name
FROM elevenlabs_agents
WHERE elevenlabs_agent_id = :selected_agent_id
  AND owner_telegram_user_id = :telegram_user_id
  AND is_active = 1;

This prevents the user from accessing or changing an agent that does not belong to them, even if the callback data is changed manually.

Workflow does not trust data from Telegram buttons as an authorization source.

## 🧠 Session Management

The current user status is stored in the user_sessions table.

The session monitors:
the selected ElevenLabs agent
for the current action
, whether the bot is waiting for a text for prompt, welcome message or Knowledge Base content

Supported session states:
idle
awaiting_prompt
awaiting_welcome_message
awaiting_knowledge_base

This allows the bot to understand how to process the user's next text message.


## ✏️ Prompt update

The user can update the system prompt of the selected ElevenLabs agent directly from Telegram.

Flow:
Agent Selection
→ Clicking "Refresh prompt"
→ Sending a new prompt text
→ Verification of agent ownership
→ PATCH ElevenLabs agent config
→ Log entry
→ Session Reset

The type of request to the ElevenLabs API:
PATCH /v1/convai/agents/{agent_id}

Example payload:
{
"conversation_config": {
"agent": {
"prompt": {
"prompt": "You are a political support agent. Answer briefly and clearly."
      }
    }
  },
  "version_description": "Prompt updated from Telegram bot"
}


## 👋 Welcome message update

The user can update the first message / welcome message of the selected ElevenLabs agent.

Flow:
Agent Selection
→ Clicking "Update welcome message"
→ Sending a new welcome text
→ Verification of agent ownership
→ PATCH ElevenLabs agent config
→ Log entry
→ Session Reset

Example payload:
{
"conversation_config": {
"agent": {
"first_message": "Hello! How can I help you today?"
    }
  },
  "version_description": "Welcome message updated from Telegram bot"
}

Creating Knowledge Base content

The user can send a text from Telegram and create a new ElevenLabs Knowledge Base document.

Flow:
Agent Selection
→ Clicking "Update knowledge base"
→ Sending text content
→ Verification of agent ownership
→ Creating a Knowledge Base document in ElevenLabs
→ Log entry
→ Session Reset

The type of request to the ElevenLabs API:
POST /v1/convai/knowledge-base/text

Sample payload:
{
"text": "This is a Knowledge Base document created from Telegram via n8n.",
"name": "KB update - Agent Name - 2026-05-15T12:00:00.000Z"
}

## 🗄️ Database structure

The project uses MySQL as an application database.

Structure file:
elevenlabs-bot-schema.sql

Seed data file:
elevenlabs-bot-seed.sql

## 🧱 Tables
telegram_users

Stores Telegram users who are allowed to use the bot.

Main fields:
| Field | Description |
| ------------------ | -------------------- |
| ` telegram_user_id` | Telegram user ID |
| `username`         | Telegram username    |
| `first_name`       | User name |
| `last_name`        | User's last name |
| `is_active`        | User status |

elevenlabs_agents
Stores ElevenLabs agents and contact with the owner in Telegram.

Main fields:
| Field | Description |
| ------------------------ | ----------------------------------------- |
| `elevenlabs_agent_id`    | ElevenLabs agent ID                       |
| `display_name`           | agent's name |
| `owner_telegram_user_id` | Telegram user who owns the agent |
| `is_active`              | Agent availability status |

Security is based on a couple:
owner_telegram_user_id + elevenlabs_agent_id

user_sessions
Stores the current interaction status for each Telegram user.

Main fields:
| Field | Description |
| ------------------------------ | -------------------------- |
| `telegram_user_id` | Current Telegram user |
| `selected_elevenlabs_agent_id` | Selected agent |
| `current_action`               | Current expected action |

update_logs
Stores agents update operations.

Main fields:
| Field | Description |
| -------------------------- | --------------------------------------- |
| ` telegram_user_id` | The user who performed the action |
| `elevenlabs_agent_id` | Target ElevenLabs agent |
| `action_type` | Update type |
| `status`                   | success or failed |
| `new_value_preview`        | Preview of the sent text |
| `http_status_code' | HTTP status of the API response |
| `error_message`            | Error details, if any |
| `elevenlabs_response_json` | Summary of the API response |

Supported action types:
update_prompt
update_welcome_message
update_knowledge_base
telegram_payload_logs

Stores raw Telegram payloads for debugging and auditing.

Main fields:
| Field | Description |
| ------------------ | ---------------------------------- |
| `telegram_user_id` | Telegram user ID |
| `update_type`      | message / callback_query / unknown |
| `raw_payload_json` | Raw Telegram update payload |
| `created_at` | Record creation time |

, Seed data

The project includes installed seed data for Telegram users and ElevenLabs agents.
Example of distribution:
| User   |  Telegram ID  | Agents   |
| ------ |  -----------: | -------- |
| User A | (Telegram ID) | 2 agents |
| User B | (Telegram ID) | 1 agent  |
| User C | (Telegram ID) | 0 agents |

This allows you to test:

standard user access
ownership of multiple
user agents without agents
isolation of access between users

## 🔐 The security model

The project uses a simple and reliable access model.:

Telegram user ID → MySQL ownership check → allowed operation with agent

Security principles:
The user sees only the agents assigned to his Telegram ID.
The user can select only the agent he owns.
Each update operation re-verifies the ownership of the agent.
Callback data is not used as proof of access rights.
API keys are stored in n8n credentials, not inside the workflow code.

## 🔑 Credentials

Workflow requires the following credentials in n8n:
**Telegram API**

Used for:
receiving messages
receiving callback queries
sending messages from the bot
sending inline keyboard menus

**MySQL**

Connection example:
Host: mysql
Port: 3306
Database: elevenlabs_bot
User: elevenbot
Password: stored in environment / n8n credentials

**ElevenLabs**

Credential type: HTTP Header Auth

Header: xi-api-key: <ELEVENLABS_API_KEY>

Used for:
updating agent configuration
and creating Knowledge Base documents

##  🐳 Deployment Notes

The project is deployed via Docker Compose.

Recommended infrastructure:
n8n
MySQL
Docker internal network
MySQL should be available only inside the Docker network.

## 🚀 Installation and launch
1. Import SQL schema
mysql -u root -p < sql/elevenlabs-bot-schema.sql

2. Import
mysql -u root -p seed data < sql/elevenlabs-bot-seed.sql

3. Import n8n workflow

In n8n:

Workflows
→ Import from file
→ Select elevenlabs-telegram-agent-manager.json

4. Set up credentials

In n8n, you need to configure:
Telegram API
MySQL
ElevenLabs HTTP Header Auth






