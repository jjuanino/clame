CREATE TABLE installed_files
(
    installed_file_id   INTEGER                             NOT NULL
                        CONSTRAINT installed_files_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    patch_version_id    INTEGER                             NOT NULL
                        CONSTRAINT installed_files_patch_versions
                            REFERENCES patch_versions
                            ON DELETE CASCADE,
    file_name           TEXT                                NOT NULL,
    file_type_id        INTEGER                             NOT NULL
                        CONSTRAINT installed_files_file_types
                            REFERENCES file_types,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL,
    digest_id           INTEGER                                 NULL
                        CONSTRAINT installed_files_digest
                            REFERENCES digests,
                        CONSTRAINT installed_files_uk
                            UNIQUE(patch_version_id, file_name)
);
CREATE INDEX if_fn_idx ON installed_files(file_name);
CREATE INDEX if_di_idx ON installed_files(digest_id);
