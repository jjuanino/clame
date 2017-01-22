CREATE TABLE patch_scripts
(
    patch_script_id     INTEGER                             NOT NULL
                        CONSTRAINT patch_script_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    patch_version_id    INTEGER                             NOT NULL
                        CONSTRAINT patch_scripts_patch_versions_fk
                            REFERENCES patch_versions
                            ON DELETE CASCADE,
    script_type_id      INTEGER                             NOT NULL
                        CONSTRAINT patch_scripts_script_type_fk
                            REFERENCES script_types,
    digest_id           INTEGER                             NOT NULL
                        CONSTRAINT patch_scripts_digests_fk
                            REFERENCES digests,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL,
                        CONSTRAINT patch_script_uk
                            UNIQUE(patch_version_id, script_type_id)
);

CREATE INDEX ps_di_idx ON patch_scripts(digest_id);
CREATE INDEX ps_pv_idx ON patch_scripts(patch_version_id);
