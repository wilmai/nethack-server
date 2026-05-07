-- dgamelaunch sqlite schema.

CREATE TABLE dglusers (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE COLLATE NOCASE NOT NULL,
    email    TEXT,
    env      TEXT,
    password TEXT,
    flags    INTEGER DEFAULT 0
);
