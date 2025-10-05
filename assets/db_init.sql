PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS [Unit] (
    [id] INTEGER PRIMARY KEY AUTOINCREMENT,
    [name] TEXT NOT NULL
    [group_id] INTEGER,
    [FOREIGN KEY] (group_id) REFERENCES [Group](id) ON DELETE CASCADE

);

CREATE TABLE IF NOT EXISTS [Timing] (
    [id] INTEGER PRIMARY KEY AUTOINCREMENT,
    [date] TEXT NOT NULL,
    [time] TEXT NOT NULL,
    [description] TEXT,
    [unit_id] INTEGER NOT NULL,
    [group_id] INTEGER,
    [FOREIGN KEY] (unit_id) REFERENCES [Unit](id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS [Group] (
    [id] INTEGER PRIMARY KEY AUTOINCREMENT,
    [group_name] TEXT NOT NULL
);
