CREATE TABLE info_vars
(
    info_var_id         INTEGER                             NOT NULL
                        CONSTRAINT info_vars_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    patch_version_id    INTEGER                             NOT NULL
                        CONSTRAINT info_vars_patch_versions
                            REFERENCES patch_versions
                            ON DELETE CASCADE,
    var_name            TEXT                                NOT NULL,
    var_value           TEXT                                NOT NULL,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL
);

CREATE INDEX info_vars_patch_versions
    ON info_vars(patch_version_id);
