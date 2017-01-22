CREATE TABLE patch_status
(
    patch_status_id     INTEGER                             NOT NULL
                        CONSTRAINT patch_status_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    patch_status        TEXT                                NOT NULL
                        CONSTRAINT patch_status_uk
                            UNIQUE,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    description         TEXT                                    NULL
);
