CREATE TABLE backed_up_files
(
    backed_up_file_id   INTEGER                             NOT NULL
                        CONSTRAINT backed_up_files_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    patch_version_id    INTEGER                             NOT NULL
                        CONSTRAINT backup_up_files_patch_versions
                            REFERENCES patch_versions
                            ON DELETE CASCADE,
    file_name           TEXT                                NOT NULL,
    digest_id           INTEGER                             NOT NULL
                        CONSTRAINT backup_up_files_digest
                            REFERENCES digests,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL,
                        CONSTRAINT backed_up_files_uk
                            UNIQUE(patch_version_id, file_name)
);

CREATE INDEX buf_fn_idx
    ON backed_up_files(file_name);
CREATE INDEX buf_di_idx
    ON backed_up_files(digest_id);
