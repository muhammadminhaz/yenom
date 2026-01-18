CREATE TABLE transactions (
                              id UUID PRIMARY KEY,
                              user_id UUID NOT NULL,
                              amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
                              currency VARCHAR(3) NOT NULL,
                              transaction_date DATE NOT NULL,
                              description VARCHAR(255) NOT NULL,
                              category VARCHAR(100),
                              merchant VARCHAR(100),
                              type VARCHAR(100) NOT NULL,
                              status VARCHAR(100) NOT NULL DEFAULT 'COMPLETED',
                              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              CONSTRAINT fk_user
                                  FOREIGN KEY(user_id)
                                      REFERENCES users(id)
                                      ON DELETE CASCADE
);

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
