
USE elevenlabs_bot;

INSERT INTO telegram_users (
    telegram_user_id,
    username,
    first_name,
    last_name
)
VALUES
    (1348125309, 'user_a_test', 'User', 'A'),
    (331131531, 'user_b_test', 'User', 'B'),
    (6181069057, 'user_c_test', 'User', 'C')
ON DUPLICATE KEY UPDATE
    username = VALUES(username),
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    updated_at = CURRENT_TIMESTAMP;


INSERT INTO elevenlabs_agents (
    elevenlabs_agent_id,
    display_name,
    owner_telegram_user_id
)
VALUES
    (
        'agent_9901krce0t58fb2vqy04526h1r22',
        '1_Test_Agent_Support',
        1348125309
    ),
    (
        'agent_9801krdrhww0fx4v7jnjm45fk261',
        '2_Test_Agent_Sales',
        1348125309
    ),
    (
        'agent_0601krccpj08e7k8x737csqm7xek',
        '3_Test_Agent_Support',
        331131531
    )
ON DUPLICATE KEY UPDATE
    display_name = VALUES(display_name),
    owner_telegram_user_id = VALUES(owner_telegram_user_id),
    is_active = 1,
    updated_at = CURRENT_TIMESTAMP;


INSERT INTO user_sessions (
    telegram_user_id,
    selected_elevenlabs_agent_id,
    current_action
)
VALUES
    (1348125309, NULL, 'idle'),
    (331131531, NULL, 'idle'),
    (6181069057, NULL, 'idle')
ON DUPLICATE KEY UPDATE
    current_action = 'idle',
    selected_elevenlabs_agent_id = NULL,
    updated_at = CURRENT_TIMESTAMP;