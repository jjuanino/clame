CREATE TABLE patch_versions
(
    patch_version_id    INTEGER                             NOT NULL
                        CONSTRAINT patches_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    patch_id            INTEGER                             NOT NULL
                        CONSTRAINT patch_version_patches_fk
                            REFERENCES patches
                            ON DELETE CASCADE,
    version             TEXT                                NOT NULL,
    patch_status_id     INTEGER
                        CONSTRAINT patch_version_status_fk
                            REFERENCES patch_status,
    short_desc          TEXT                                NOT NULL,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    prefix              TEXT                                NOT NULL,
    uid                 INTEGER                             NOT NULL,
    backup_info         BLOB                                    NULL,
                        CONSTRAINT patch_versions_uk
                            UNIQUE(patch_id, version)
);
