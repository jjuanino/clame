CREATE TABLE input_vars
(
    input_var_id        INTEGER                             NOT NULL
                        CONSTRAINT input_vars_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    patch_version_id    INTEGER                             NOT NULL
                        CONSTRAINT input_vars_patch_versions
                            REFERENCES patch_versions
                            ON DELETE CASCADE,
    var_name            TEXT                                NOT NULL,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    var_value           TEXT                                    NULL,
                        CONSTRAINT input_vars_uk
                            UNIQUE(patch_version_id, var_name)
);
