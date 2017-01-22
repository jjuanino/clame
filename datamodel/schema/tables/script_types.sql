CREATE TABLE script_types
(
    script_type_id      INTEGER                             NOT NULL
                        CONSTRAINT script_types_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    script_name         TEXT                                NOT NULL
                        CONSTRAINT script_types_uk
                            UNIQUE,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL
);
