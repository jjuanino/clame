CREATE TABLE conflicts
(
    conflict_id         INTEGER                             NOT NULL
                        CONSTRAINT conflicts_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    patch_version_id    INTEGER                             NOT NULL
                        CONSTRAINT conflicts_patch_versions
                            REFERENCES patch_versions
                            ON DELETE CASCADE,
    conf_patch_id       INTEGER                             NOT NULL
                        CONSTRAINT conflicts_patches
                            REFERENCES patches
                            ON DELETE CASCADE,
    interval            BLOB                                NOT NULL,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL
);

/*
    ATENCIÓN: conf_patch_id (es decir, patch_name) se incluye en esta tabla
    para facilitar las búsquedas, pero es un campo dependiente de
    interval. El objeto ruby contenido en interval ya contiene el nombre del
    parche conflictivo
*/
CREATE INDEX conflicts_conf_patch_id_idx
    ON conflicts(conf_patch_id);
