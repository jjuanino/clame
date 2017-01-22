CREATE TABLE file_types
(
    file_type_id    INTEGER                             NOT NULL
                    CONSTRAINT file_types_pk
                        PRIMARY KEY ASC AUTOINCREMENT,
    file_type       TEXT                                NOT NULL
                    CONSTRAINT file_types_uk
                        UNIQUE,
    time_stamp      TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    description     TEXT                                    NULL
);
