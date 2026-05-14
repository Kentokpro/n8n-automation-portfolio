
USE elevenlabs_bot;

CREATE TABLE IF NOT EXISTS telegram_users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    telegram_user_id BIGINT UNSIGNED NOT NULL,
    username VARCHAR(255) NULL,
    first_name VARCHAR(255) NULL,
    last_name VARCHAR(255) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_telegram_users_telegram_user_id (telegram_user_id),
    KEY idx_telegram_users_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS elevenlabs_agents (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    elevenlabs_agent_id VARCHAR(100) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    owner_telegram_user_id BIGINT UNSIGNED NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_elevenlabs_agents_agent_id (elevenlabs_agent_id),
    UNIQUE KEY uq_owner_agent (owner_telegram_user_id, elevenlabs_agent_id),
    KEY idx_elevenlabs_agents_owner (owner_telegram_user_id),
    KEY idx_elevenlabs_agents_is_active (is_active),

    CONSTRAINT fk_agents_owner
        FOREIGN KEY (owner_telegram_user_id)
        REFERENCES telegram_users (telegram_user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    telegram_user_id BIGINT UNSIGNED NOT NULL,
    selected_elevenlabs_agent_id VARCHAR(100) NULL,
    current_action ENUM(
        'idle',
        'awaiting_prompt',
        'awaiting_welcome_message',
        'awaiting_knowledge_base'
    ) NOT NULL DEFAULT 'idle',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_user_sessions_telegram_user_id (telegram_user_id),
    KEY idx_user_sessions_current_action (current_action),
    KEY idx_user_sessions_selected_agent (selected_elevenlabs_agent_id),

    CONSTRAINT fk_sessions_user
        FOREIGN KEY (telegram_user_id)
        REFERENCES telegram_users (telegram_user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_sessions_selected_owner_agent
        FOREIGN KEY (telegram_user_id, selected_elevenlabs_agent_id)
        REFERENCES elevenlabs_agents (owner_telegram_user_id, elevenlabs_agent_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS update_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    telegram_user_id BIGINT UNSIGNED NOT NULL,
    elevenlabs_agent_id VARCHAR(100) NOT NULL,
    action_type ENUM(
        'update_prompt',
        'update_welcome_message',
        'update_knowledge_base'
    ) NOT NULL,
    status ENUM(
        'success',
        'failed'
    ) NOT NULL,
    new_value_preview TEXT NULL,
    http_status_code INT NULL,
    error_message TEXT NULL,
    elevenlabs_response_json JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    KEY idx_update_logs_telegram_user_id (telegram_user_id),
    KEY idx_update_logs_agent_id (elevenlabs_agent_id),
    KEY idx_update_logs_action_status (action_type, status),
    KEY idx_update_logs_created_at (created_at),

    CONSTRAINT fk_update_logs_user
        FOREIGN KEY (telegram_user_id)
        REFERENCES telegram_users (telegram_user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_update_logs_owner_agent
        FOREIGN KEY (telegram_user_id, elevenlabs_agent_id)
        REFERENCES elevenlabs_agents (owner_telegram_user_id, elevenlabs_agent_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS telegram_payload_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    telegram_user_id BIGINT UNSIGNED NULL,
    update_type ENUM(
        'message',
        'callback_query',
        'unknown'
    ) NOT NULL DEFAULT 'unknown',
    raw_payload_json JSON NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    KEY idx_telegram_payload_logs_user_id (telegram_user_id),
    KEY idx_telegram_payload_logs_update_type (update_type),
    KEY idx_telegram_payload_logs_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;