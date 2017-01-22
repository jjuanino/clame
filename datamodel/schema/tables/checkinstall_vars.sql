CREATE TABLE checkinstall_vars
(
    checkinstall_var_id     INTEGER                             NOT NULL
                            CONSTRAINT checkinstall_vars_pk
                                PRIMARY KEY ASC AUTOINCREMENT,
    patch_version_id        INTEGER                             NOT NULL
                            CONSTRAINT checkinstall_vars_patch_version
                                REFERENCES patch_versions
                                ON DELETE CASCADE,
    var_name                TEXT                                NOT NULL,
    var_value               TEXT                                NOT NULL,
    time_stamp              TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL,
                            CONSTRAINT checkinstall_vars_uk
                            UNIQUE(patch_version_id, var_name)
);
