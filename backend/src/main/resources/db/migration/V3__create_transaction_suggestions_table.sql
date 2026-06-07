CREATE TABLE transaction_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source VARCHAR(10) NOT NULL CHECK (source IN ('GMAIL', 'SMS')),
    raw_message TEXT NOT NULL,
    amount DECIMAL(10,2),
    currency VARCHAR(3),
    transaction_date DATE,
    description VARCHAR(255),
    category VARCHAR(100),
    type VARCHAR(10) CHECK (type IN ('INCOME', 'EXPENSE')),
    is_haram BOOLEAN DEFAULT FALSE,
    haram_reason VARCHAR(255),
    ai_confidence DECIMAL(3,2),
    status VARCHAR(10) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days')
);

CREATE INDEX idx_suggestions_user_status ON transaction_suggestions(user_id, status);
