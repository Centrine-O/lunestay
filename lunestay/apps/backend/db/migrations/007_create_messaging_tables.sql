-- Migration 007: Create conversations and messages tables

-- Conversation threads between host and guest about a listing
CREATE TABLE conversations (
    id               BIGSERIAL PRIMARY KEY,
    listing_id       BIGINT NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    host_id          BIGINT NOT NULL REFERENCES users(id),
    guest_id         BIGINT NOT NULL REFERENCES users(id),
    last_message_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (listing_id, host_id, guest_id)
);

-- Individual messages in a conversation
CREATE TABLE messages (
    id               BIGSERIAL PRIMARY KEY,
    conversation_id  BIGINT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id        BIGINT NOT NULL REFERENCES users(id),
    content          TEXT NOT NULL,
    read_at          TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_conversations_host_id ON conversations(host_id);
CREATE INDEX idx_conversations_guest_id ON conversations(guest_id);
CREATE INDEX idx_conversations_last_message_at ON conversations(last_message_at DESC);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_conversation_id_created_at ON messages(conversation_id, created_at);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);