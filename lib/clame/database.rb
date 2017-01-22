# -*- coding: ISO-8859-15 -*-
#--
# vim: set ft=ruby sts=2 sw=2 ai et:
#
#
# Copyright (c) 2016 José García Juanino <jjuanino@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'zlib'

require 'sqlite3'

module Clame

  class Database

    SCHEMA_TABLES = %w(
      backed_up_files
      checkinstall_vars
      requisites
      conflicts
      digests
      file_types
      installed_files
      model_version
      patch_scripts
      patch_status
      patch_versions
      patches
      script_types
      input_vars
      info_vars
    )

    SCHEMA_INITIAL_DATA_LOAD = %w(
      model_version
      file_types
      script_types
      patch_status
    )

    MIN_VALID_VERSION = '0.0.1'


    attr_reader :db_file

    def initialize(db_file)

      @db_file = db_file

      # desplegamos el modelo de datos si la base de datos sqlite no está
      # desplegada
      @db_handle =
        unless File.file?(db_file)
          Clame.logger.warn "Database does not exist. Deploying the schema"
          deploy_database_model(db_file, CONF_SETTINGS[:deploy_schema_dir])
          # La versión de esta base de datos es la indicada en
          # MIN_VALID_VERSION
        else
          SQLite3::Database.new(db_file)
        end

      @db_handle.results_as_hash = true

      # Activar integridad referencial
      @db_handle.execute("PRAGMA foreign_keys = on") do |row|
        raise SQLite3::Exception.new(row[0]) unless row[0] == "ok"
      end

      # Esperamos si la BD está bloqueada antes de propagar el error "Database
      # is locked"
      @db_handle.busy_timeout = 60000 # 1 minuto

      # ejecutamos unas sencillas operaciones para asegurarmos de que es una
      # base de datos válida
      begin
        get_first_value('SELECT 1 FROM sqlite_master')
        get_first_value('SELECT version FROM model_version')
        get_first_value('SELECT patch_id FROM patches')
      rescue SQLite3::SQLException
        raise InvalidDB.new(db_file, $!.to_s)
      end

      # Destructor
      ObjectSpace.define_finalizer(self, self.class.finalize(@db_handle))

      # comprobamos que la versión de la base de datos es compatible
      # con esta versión de Clame
      check_database_version

    end


    # Destructor
    def self.finalize(db_handle)
      proc{db_handle.close}
    end

    # Ejecutar una consulta y recuperar el primer campo del primer resultado
    def get_first_value(*args)
      @db_handle.get_first_value(*args)
    end


    def get_model_version
      get_first_value('SELECT version FROM model_version')
    end

    def set_model_version(version)
      @db_handle.execute(
        %{INSERT INTO model_version(version) VALUES(:version)},
        :version => version
      )
    end


    # Recupera el estado de un parche
    def get_status(patch_name, version)
      get_first_value(
        %{SELECT s.patch_status
          FROM patches p, patch_versions v, patch_status s
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id
          AND v.version = :version
          AND s.patch_status_id = v.patch_status_id},
        :patch_name => patch_name,
        :version => version
      )
    end


    # Recupera el prefix de instalación de un parche
    def get_prefix(patch_name, version)
      get_first_value(
        %{SELECT v.prefix
          FROM patches p, patch_versions v
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id
          AND v.version = :version},
        :patch_name => patch_name,
        :version => version
      )
    end


    # Recupera los parches que dependen de de (patch_name, version).
    # Realmente, devolvemos un array de objetos de este estilo:
    #
    # { patch_version_id, interval }
    #
    # Cada componente del array muestra una dependencia de un parche
    # (patch_version) con un intervalo (interval). El intervalo contiene
    # a (patch_name, version).
    def get_dependent_patches(patch_name, version)

      current_patch = PatchVersion.new(patch_name, version)

      @db_handle.execute(
        %{SELECT p2.patch_name, v.version, r.interval
          FROM requisites r, patches p1, patch_versions v, patches p2
          WHERE p1.patch_name = :patch_name
          AND r.req_patch_id = p1.patch_id
          AND v.patch_version_id = r.patch_version_id
          AND p2.patch_id = v.patch_id},
          :patch_name => patch_name,
      ).find_all do |h|
        Marshal.load(h['interval']).include?(current_patch)
      end.collect do |h|
        {
          :patch_name => h['patch_name'],
          :version => h['version'],
          :interval => Marshal.load(h['interval']),
        }
      end
    end


    # Recuperar los parches instalados que caen dentro de interval
    def get_installed_patches(interval)
      patch_name = interval.extreme.patchname

      @db_handle.execute(
        %{SELECT v.version
          FROM patches p, patch_versions v
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id},
        :patch_name => patch_name,
      ).find_all do |h|
        interval.include?(
          PatchVersion.new(patch_name, h['version'])
        )
      end.collect{|h| h['version']}
    end


    # Comprueba si la versión de la base de datos es adecuada
    def check_database_version
      if (model_version = get_model_version)
        actual_version = PatchVersion.new('Clame', model_version)
      end
      min_version = PatchVersion.new('Clame', MIN_VALID_VERSION)

      if model_version
        unless min_version <= actual_version
          raise InvalidDatabaseVersion.new(
            min_version.version, actual_version.version
          )
        end
      else
        # No hay versión de base de datos registrada. Registramos
        # MIN_VALID_VERSION
        set_model_version(MIN_VALID_VERSION)
      end

    end

    # Establece el estado de un parche
    def set_status(patch_name, version, patch_status)
      @db_handle.execute(
        %{UPDATE patch_versions
            SET patch_status_id =
              (SELECT patch_status_id
               FROM patch_status
               WHERE patch_status = :patch_status)
            WHERE patch_id =
              (SELECT patch_id
               FROM patches
               WHERE patch_name = :patch_name)
            AND version = :version},
        :patch_name => patch_name,
        :version => version,
        :patch_status => patch_status
      )
    end

    # Registrar un parche: atributos básicos
    def register_patch_version(patch_name, version, short_desc, prefix, uid)

      # Si el parche está registrado, ignoramos el error
      begin
        @db_handle.execute(
          %{INSERT INTO patches(patch_name)
            VALUES(:patch_name)},
          :patch_name => patch_name
        )
      rescue SQLite3::ConstraintException
      end

      @db_handle.execute(
        %{INSERT INTO patch_versions(
            patch_id,
            version,
            short_desc,
            prefix,
            uid
          ) 
          SELECT
            patch_id,
            :version,
            :short_desc,
            :prefix,
            :uid
          FROM patches
          WHERE patch_name = :patch_name},
        :patch_name => patch_name,
        :version => version,
        :short_desc => short_desc,
        :prefix => prefix,
        :uid => uid,
      )

    end


    # Rollback del registro de un parche
    def unregister_patch_version(patch_name, version)

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.execute(
        %{DELETE
          FROM patch_versions
          WHERE patch_version_id = :patch_version_id},
        :patch_version_id => patch_version_id
      )
    end


    def register_checkinstall_vars(patch_name, version, *args)

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.transaction do |h|
        stmt_checkinstall_var = h.prepare(
          %{INSERT
            INTO checkinstall_vars(
              patch_version_id,
              var_name,
              var_value
            )
            VALUES(
              :patch_version_id,
              :var_name,
              :var_value
            )
          }
        )

        args.each_slice(2).each do |var_name, var_value|
          stmt_checkinstall_var.execute(
            :patch_version_id => patch_version_id,
            :var_name => var_name,
            :var_value => var_value
          )
        end
      end

    end



    def get_checkinstall_vars(patch_name, version)

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.execute(
        %{SELECT var_name, var_value
          FROM checkinstall_vars
          WHERE patch_version_id = :patch_version_id},
        :patch_version_id => patch_version_id
      )
    end

    def set_backup_info(patch_name, version, backup_info, basedir)

      zbackup_info = Zlib::Deflate.deflate(Marshal.dump(backup_info))

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.transaction do |h|
        stmt_digest = h.prepare(
          %{INSERT
            INTO digests(digest)
            VALUES(:digest)}
        )
        stmt_backed_up = h.prepare(
          %{INSERT
            INTO backed_up_files(
              patch_version_id,
              file_name,
              digest_id
            )
            SELECT
              :patch_version_id,
              :file_name,
              digest_id
            FROM digests
            WHERE digest = :digest}
        )

        h.execute(
          %{UPDATE patch_versions
            SET backup_info = :backup_mrs
            WHERE patch_id =
              (SELECT patch_id
              FROM patches
              WHERE patch_name = :patch_name)
            AND version = :version},
          :patch_name => patch_name,
          :version => version,
          :backup_mrs => zbackup_info
        )

        backup_info.regfiles_changed.each do |info|
          file_name = File.absolute_path(info[:new].destination, basedir)
          digest = info[:actual][:digest]

          # En este caso procesamos siempre ficheros regulares, así que digest
          # es NOT NULL
          stmt_digest.execute(:digest => digest) rescue SQLite3::ConstraintException

          stmt_backed_up.execute(
            :patch_version_id => patch_version_id,
            :file_name => file_name,
            :digest => digest
          )
        end
      end
    end


    def get_backup_info(patch_name, version)
      zbackup_info = get_first_value(
        %{SELECT backup_info
          FROM patches p, patch_versions v
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id
          AND v.version = :version},
        :patch_name => patch_name,
        :version => version
      )
      zbackup_info && Marshal.load(Zlib::Inflate.inflate(zbackup_info))
    end


    def get_versions_installed(patch_name)
      @db_handle.execute(
        %{SELECT version
          FROM patches p, patch_versions v
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id},
        :patch_name => patch_name
      ).collect{|h| h['version']}
    end


    def register_installed_files(core, basedir)

      patch_name = core.info.patch_name
      version = core.info.patch_version

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.transaction do |h|
        stmt_digest = h.prepare(
          %{INSERT
            INTO digests(digest)
            VALUES(:digest)}
        )
        stmt_installed_files = h.prepare(
          %{INSERT
            INTO installed_files(
              patch_version_id,
              file_name,
              file_type_id,
              digest_id
            )
            SELECT
              :patch_version_id,
              :file_name,
              t.file_type_id,
              d.digest_id
            FROM digests d, file_types t
            WHERE (:digest IS NOT NULL AND d.digest = :digest)
            AND t.file_type = :file_type
            UNION ALL
            SELECT
              :patch_version_id,
              :file_name,
              t.file_type_id,
              NULL
            FROM file_types t
            WHERE :digest IS NULL
            AND t.file_type = :file_type}
        )

        core.schema.each do |schemaitem|

          # Solo los archivos regulares tienen digest
          if schemaitem.filetype == FileType::REGFILE
            digest = schemaitem.digest
          end

          # Si no es un archivo regular, no hay que registrar el digest
          if digest
            # El digest ya puede estar registrado con anterioridad. En ese
            # caso, continuar normalmente
            stmt_digest.execute(:digest => digest) rescue SQLite3::ConstraintException
          end

          stmt_installed_files.execute(
            :patch_version_id => patch_version_id,
            :file_type => schemaitem.filetype,
            :file_name => File.absolute_path(schemaitem.destination, basedir),
            :digest => digest
          )
        end
      end

    end


    def register_requisites(core)

      # si no se han indicado dependencias en el parche, no hay nada que
      # registrar
      return unless (depend = core.depend)

      patch_name = core.info.patch_name
      version = core.info.patch_version

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.transaction do |h|
        stmt_deps = h.prepare(
          %{INSERT
            INTO requisites(
              patch_version_id,
              req_patch_id,
              interval
            )
            SELECT
              :patch_version_id,
              patch_id,
              :interval
            FROM patches
            WHERE patch_name = :patch_name}
        )

        depend.requisites.each do |req|
          # req es un Inverval
          # req.extreme es un PatchVersion
          stmt_deps.execute(
            patch_version_id: patch_version_id,
            patch_name: req.extreme.patchname,
            interval: Marshal.dump(req),
          )
        end

      end

    end

    def get_requisites(patch_name, version)
      @db_handle.execute(
        %{SELECT interval
          FROM patches p, patch_versions v, requisites r
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id
          AND v.version = :version
          AND r.patch_version_id = v.patch_version_id},
        :patch_name => patch_name,
        :version => version
      ).collect{|h| Marshal.load(h['interval'])}
    end

    def register_conflicts(core)

      # si en el parche no se han indicado conflictos, no hay nada que
      # registrar
      return unless (depend = core.depend)

      patch_name = core.info.patch_name
      version = core.info.patch_version

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.transaction do |h|

        # Para registrar un conflicto, el nombre del parche conflictivo tiene
        # que estar registrado previamente en la tabla patches
        #
        stmt_patches = h.prepare(
          %{INSERT
            INTO patches(patch_name)
            VALUES(:patch_name)}
        )

        stmt_conflicts = h.prepare(
          %{INSERT
            INTO conflicts(
              patch_version_id,
              conf_patch_id,
              interval
            )
            SELECT
              :patch_version_id,
              patch_id,
              :interval
            FROM patches
            WHERE patch_name = :patch_name}
        )

        depend.conflicts.each do |conf|
          # Intentamos registrar el parche conflictivo en la tabla patches,
          # pero no importa si ya está registrado
          stmt_patches.execute(
            patch_name: conf.extreme.patchname
          ) rescue SQLite3::ConstraintException

          # conf es un Inverval
          # conf.extreme es un PatchVersion
          stmt_conflicts.execute(
            patch_version_id: patch_version_id,
            patch_name: conf.extreme.patchname,
            interval: Marshal.dump(conf),
          )
        end

      end

    end


    def get_conflicts(patch_name, version)
      @db_handle.execute(
        %{SELECT interval
          FROM patches p, patch_versions v, conflicts c
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id
          AND v.version = :version
          AND c.patch_version_id = v.patch_version_id},
        :patch_name => patch_name,
        :version => version
      ).collect{|h| Marshal.load(h['interval'])}

    end


    # Recuperar los conflictos con los que podría chocar la instalación de una
    # versión de un parche (patch_name).
    def get_possible_conflicts(patch_name)

      conf_patch_id = get_first_value(
        %{SELECT patch_id
          FROM patches
          WHERE patch_name = :patch_name},
        :patch_name => patch_name
      )

      # Si el parche no está registrado, no devolvemos nada
      return [] unless conf_patch_id

      # Devolvemos una array. Cada componente del array es un hash con los
      # campos: PatchVersion, Interval.
      @db_handle.execute(
        %{SELECT p.patch_name, v.version, c.interval
          FROM conflicts c, patch_versions v, patches p
          WHERE c.conf_patch_id = :conf_patch_id
          AND v.patch_version_id = c.patch_version_id
          AND p.patch_id = v.patch_id},
        :conf_patch_id => conf_patch_id
      ).collect do |r|
        {
          :patch_name =>r['patch_name'],
          :version => r['version'],
          :interval => Marshal.load(r['interval'])
        }
      end
    end


    def register_install_scripts(packagedpatch)

      core = packagedpatch.get_core

      # si el parche no tiene scripts de instalación, no hay nada que registrar
      return if (scripts_install = core.scripts_install).empty?

      patch_name = core.info.patch_name
      version = core.info.patch_version

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.transaction do |h|

        stmt_digest_insert = h.prepare(
          %{INSERT
            INTO digests(
              digest,
              zcontent
            )
            VALUES(
              :digest,
              :zcontent
            )}
        )

        stmt_digest_update = h.prepare(
          %{UPDATE digests
            SET zcontent = :zcontent
            WHERE digest = :digest}
        )


        stmt_install_scripts = h.prepare(
          %{INSERT
            INTO patch_scripts(
              patch_version_id,
              script_type_id,
              digest_id
            )
            SELECT
              :patch_version_id,
              t.script_type_id,
              d.digest_id
            FROM digests d, script_types t
            WHERE d.digest = :digest
            AND t.script_name = :script_name}
        )

        scripts_install.each do |script, digest|

          # El contenido del script, comprimido
          zcontent =
            Zlib::Deflate.deflate(packagedpatch.content_script(script))

          begin
            stmt_digest_insert.execute(:digest => digest, :zcontent => zcontent)
          rescue SQLite3::ConstraintException
            # El digest ya está registrado. Actualizamos el contenido
            stmt_digest_update.execute(:digest => digest, :zcontent => zcontent)
          end

          stmt_install_scripts.execute(:patch_version_id => patch_version_id,
                                       :digest => digest,
                                       :script_name => script)

        end

      end

    end


    def get_install_script(patch_name, version, script_name)
      zret = get_first_value(
        %{SELECT d.zcontent
          FROM patches p,
              patch_versions v,
              patch_scripts s,
              script_types t,
              digests d
          WHERE p.patch_name = :patch_name
          AND t.script_name = :script_name
          AND v.patch_id = p.patch_id
          AND v.version = :version
          AND s.script_type_id = t.script_type_id
          AND s.patch_version_id = v.patch_version_id
          AND d.digest_id = s.digest_id},
        :patch_name => patch_name,
        :version => version,
        :script_name => script_name
      )

      # Si la consulta no devuelve nada, se devuelve nil en el procedimiento,
      # En caso contrario, devolvemos el contenido del script previamente
      # descomprimido
      zret && Zlib::Inflate.inflate(zret)
    end


    # Registrar variables/valores de input
    # vars es un hash de la forma :name => value
    def register_input_vars(core, vars)

      # Si no se han declarado variable input en el parche, no hay nada que
      # registrar
      return unless vars

      patch_name = core.info.patch_name
      version = core.info.patch_version

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.transaction do |h|
        stmt_input_vars = h.prepare(
          %{INSERT
            INTO input_vars(
              patch_version_id,
              var_name,
              var_value
            )
            VALUES(
              :patch_version_id,
              :var_name,
              :var_value
            )}
        )

        vars.each do |var_name, var_value|
          # En el caso de que manejemos una variable booleana
          # con valor true, registraremos la cadena true. Si por el contrario
          # la variable booleana tiene el valor false, registraremos un nil.
          # El resto de variables se registran con su propio valor
          var_value = var_value ? var_value.to_s : nil

          stmt_input_vars.execute(
            patch_version_id: patch_version_id,
            var_name: var_name,
            var_value: var_value,
          )
        end

      end

    end


    # Registrar variables/valores de info
    def register_info_vars(info)

      patch_name = info['PATCH_NAME']
      version = info['VERSION']

      patch_version_id = get_patch_version_id(patch_name, version)

      @db_handle.transaction do |h|
        stmt_info_vars = h.prepare(
          %{INSERT
            INTO info_vars(
              patch_version_id,
              var_name,
              var_value
            )
            VALUES(
              :patch_version_id,
              :var_name,
              :var_value
            )}
        )

        info.each do |var_name, var_value|
          stmt_info_vars.execute(
            patch_version_id: patch_version_id,
            var_name: var_name,
            var_value: var_value,
          )
        end

      end

    end


    # Recuperar las variables input de un parche ya registrado.  Observar que
    # si el valor de una variables es NULL en base de datos, el procedimiento
    # devolverá un nil en ese valor
    def get_input_vars(patch_name, version)
      @db_handle.execute(
        %{SELECT i.var_name, i.var_value
          FROM patches p,
               patch_versions v,
               input_vars i
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id
          AND v.version = :version
          AND i.patch_version_id = v.patch_version_id},
        :patch_name => patch_name,
        :version => version
      )
    end

    def get_info_vars(patch_name, version)
      @db_handle.execute(
        %{SELECT i.var_name, i.var_value
          FROM patches p,
               patch_versions v,
               info_vars i
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id
          AND v.version = :version
          AND i.patch_version_id = v.patch_version_id},
        :patch_name => patch_name,
        :version => version
      )
    end

    def get_patch_version_id(patch_name, version)
      get_first_value(
        %{SELECT patch_version_id
          FROM patches p, patch_versions v
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id
          AND v.version = :version},
        :patch_name => patch_name,
        :version => version
      )
    end


    def get_uid(patch_name, version)
      get_first_value(
        %{SELECT v.uid
          FROM patches p, patch_versions v
          WHERE p.patch_name = :patch_name
          AND v.patch_id = p.patch_id
          AND v.version = :version},
        :patch_name => patch_name,
        :version => version
      )
    end

    private

    def deploy_database_model(db_file, deploy_dir)
      # si la base de datos ya existe, damos un error
      raise DbPathExists.new(db_file) if File.exist?(db_file)

      db_handle = SQLite3::Database.new(db_file)

      begin
        # Si el directorio no existe, se producirá Errno:ENOENT
        Dir.chdir(deploy_dir) do
          create_tables(db_handle)
          data_load(db_handle)
        end
      rescue Errno::ENOENT
        raise DirectoryNotExist.new(deploy_dir)
      end

      return db_handle
    end


    def create_tables(handle)
      # creación de las tablas
      SCHEMA_TABLES.each do |table|
        Clame.logger.debug "Creating table #{table}"
        handle.execute_batch IO.read(File.join('tables', table + '.sql'))
      end
    end

    # carga inicial de constantes
    def data_load(handle)

      SCHEMA_INITIAL_DATA_LOAD.each do |table|

        Clame.logger.debug "Initial data load of table #{table}"

        input_file = File.join('initial_data_load', table)

        # las columnas son el primer campo que contenga exclusivamente letras
        # mayúsculas, un underscore o un punto y coma (;)
        header, header_position =
          IO.foreach(input_file).each_with_index.detect do |line,index|
            line =~ /\A[[:upper:]_;]+\Z/
          end

        header.gsub!(';',',')

        # Lanzamos todas las sentencias insert
        handle.execute_batch(
          IO.foreach(input_file).each_with_index.reject do |line,index|
            # ignoramos todas las líneas anteriores a la línea header
            line =~ /\A#/ || index <= header_position
          end.collect do |line, index|
            line.chomp!
            %{INSERT INTO #{table}(#{header})
              VALUES (#{line.split(';').collect{|c| "'#{c}'"}.join(',')});}
          end.join("\n")
        )
      end

    end


  end

end
