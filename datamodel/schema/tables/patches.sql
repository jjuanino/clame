CREATE TABLE patches
(
    patch_id        INTEGER                             NOT NULL
                    CONSTRAINT patches_pk
                        PRIMARY KEY ASC AUTOINCREMENT,
    patch_name      TEXT                                NOT NULL
                    CONSTRAINT patches_uk
                        UNIQUE,
    time_stamp      TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL
);
