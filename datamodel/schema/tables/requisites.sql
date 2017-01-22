CREATE TABLE requisites
(
    requisite_id        INTEGER                             NOT NULL
                        CONSTRAINT requisites_pk
                            PRIMARY KEY ASC AUTOINCREMENT,
    patch_version_id    INTEGER                             NOT NULL
                        CONSTRAINT requisites_patch_versions
                            REFERENCES patch_versions
                            ON DELETE CASCADE,
    req_patch_id        INTEGER                             NOT NULL
                        CONSTRAINT requisites_patches
                            REFERENCES patches
                            ON DELETE CASCADE,
    interval            BLOB                                NOT NULL,
    time_stamp          TEXT    DEFAULT CURRENT_TIMESTAMP   NOT NULL
);
 
/*
    ATENCIÓN: req_patch_id (es decir, patch_name) se incluye en esta tabla para
    facilitar las búsquedas, pero es un campo dependiente de interval. El
    objeto ruby contenido en interval ya contiene el nombre del parche
    dependiente
*/
CREATE INDEX requisites_req_patch_id_idx
    ON requisites(req_patch_id);
