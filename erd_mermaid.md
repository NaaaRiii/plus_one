erDiagram
    USERS {
        integer id PK
        string name
        string email
        string password_digest
        integer exp
        integer rank
        string remember_digest
        string activation_digest
        boolean activated
        datetime activated_at
        integer total_exp
        integer last_roulette_rank
        integer tickets
        integer title_index
        string current_title
        string cognito_sub
        datetime created_at
        datetime updated_at
    }
    GOALS {
        integer id PK
        integer user_id FK
        text content
        string title
        date deadline
        string small_goal
        boolean completed
        datetime created_at
        datetime updated_at
    }
    SMALL_GOALS {
        integer id PK
        integer goal_id FK
        text title
        string difficulty
        datetime deadline
        string task
        boolean completed
        datetime completed_time
        integer exp
        datetime created_at
        datetime updated_at
    }
    TASKS {
        integer id PK
        integer small_goal_id FK
        boolean completed
        text content
        datetime created_at
        datetime updated_at
    }
    ACTIVITIES {
        integer id PK
        integer user_id FK
        string goal_title
        string small_goal_title
        integer exp_gained
        integer small_goal_id FK
        integer goal_id FK
        float exp
        datetime completed_at
        datetime created_at
        datetime updated_at
    }
    ROULETTE_TEXTS {
        integer id PK
        integer number
        string text
        integer user_id FK
        datetime created_at
        datetime updated_at
    }
    <!--JWT_BLACKLISTS {
        integer id PK
        string jti
        string token
        datetime created_at
        datetime updated_at
    }
    SCHEMA_MIGRATIONS {
        string version PK
    }
    AR_INTERNAL_METADATA {
        string key PK
        string value
        datetime created_at
        datetime updated_at
    }-->

    USERS ||--o{ GOALS : "has"
    USERS ||--o{ ACTIVITIES : "performs"
    USERS ||--o{ ROULETTE_TEXTS : "owns"
    GOALS ||--o{ SMALL_GOALS : "contains"
    SMALL_GOALS ||--o{ TASKS : "has"
    SMALL_GOALS ||--o{ ACTIVITIES : "generates"
    GOALS ||--o{ ACTIVITIES : "generates"
