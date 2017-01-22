CREATE TABLE digests
(
    digest_id       INTEGER                             NOT NULL
                    CONSTRAINT digests_pk
                        PRIMARY KEY ASC AUTOINCREMENT,
    digest          TEXT                                NOT NULL
                    CONSTRAINT digest_uk
                        UNIQUE,
    time_stamp      TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    zcontent        BLOB                                    NULL
);
