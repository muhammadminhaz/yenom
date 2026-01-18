CREATE TABLE users (
                       id UUID PRIMARY KEY,
                       username VARCHAR(30) NOT NULL UNIQUE,
                       email VARCHAR(255) NOT NULL UNIQUE,
                       password VARCHAR(255) NOT NULL,
                       role VARCHAR(50) NOT NULL DEFAULT 'USER',
                       first_name VARCHAR(50) NOT NULL,
                       last_name VARCHAR(50) NOT NULL,
                       city VARCHAR(100),
                       country VARCHAR(100),
                       continent VARCHAR(100),
                       created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
