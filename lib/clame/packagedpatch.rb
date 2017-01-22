# -*- coding: ISO-8859-15 -*-
#--
# vim: set sts=2 sw=2 ai et:
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

require 'stringio'
require 'termios'
require 'mkfifo'
require 'zip/filesystem'

module Clame

  # Objeto que representa un parche concreto contenido en un zip concreto (es
  # decir, en un PatchesContainer)
  class PackagedPatch

    # Iteración sobre cada archivo que instala el parche
    include Enumerable

    attr_reader :container, :patch_name, :version

    def initialize(zip_path, patch_name, version, options={quiet: true})

      @container = PatchesContainer.new(zip_path)
      @patch_name = patch_name
      @version = version
      @options = options

      # comprobamos que el nombre & version son válidos, pero sólo si los han
      # indicado expresamente en la línea de comandos
      if options[:explicity_pv]
        Clame.puts_check "(#{patch_name}) patch, (#{version}) version " +
          "is included in (#{zip_path})" do
          unless @container.include?([@patch_name, @version])
            raise PatchNameVersionNotFound.new(@patch_name, @version)
          end
        end
      end
    end

    # El objeto info asociado, visto como un hash
    def info
      get_core.info.to_hash
    end


    # Comprobar la integridad de un parche/version, comparando cada hash del
    # archivo contents con el real. No devuelve nada
    def check_integrity

      @container.file.foreach(
        File.join(
          PatchBuilder::BASE_PATCHES, @patch_name, @version,
          PatchBuilder::CONTENTS_FILE
        )
      ) do |entry|

        entry.chomp!

        case entry
        # install/sha256
        when /\A#{PatchBuilder::INSTALL_DIR}#{File::SEPARATOR}
          (#{REGEX_SHA256})\Z/x
          # comparar sha256 esperado y real
          compare_digest(entry, $1)
          Clame.logger.debug "Passed integrity check of (#{entry})"

        # patches/patch_name/version/corefile
        when /\A(#{PatchBuilder::BASE_PATCHES}#{File::SEPARATOR}
          #{@patch_name}#{File::SEPARATOR}
          #{@version}#{File::SEPARATOR}#{PatchBuilder::CORE_FILE})\t
          (#{REGEX_SHA256})\Z/x
          # comparar sha256 esperado y real
          compare_digest($1, $2)
          Clame.logger.debug "Passed integrity check of (#$1)"

        else
          # entrada inválida
          Clame.logger.error "Invalid entry (#{entry})"
          raise InvalidContainerEntry.new(entry)
        end

      end

      Clame.logger.info "Passed integrity check of patch " +
        "(#{@patch_name}), version (#{@version})"


    rescue Errno::ENOENT
      # el archivo contents no existe
      Clame.logger.error "Contents file does not exist: (" +
        File.join(
          PatchBuilder::BASE_PATCHES, @patch_name, @version,
          PatchBuilder::CONTENTS_FILE
        ) + ")"

      raise ContentsFileNotExists.new(@patch_name, @version)
    end


    # Itera sobre cada archivo que instala el schema
    def each(&block)
      get_core.schema.each(&block)
    end


    def extract_file(file_name, ios=$stdout)
      result =
        get_core.schema.regfiles.detect do |regfile_item|
          regfile_item.destination == file_name
        end

      # archivo no definido en el schema, o bien no es un fichero regular
      unless result
        Clame.logger.error "(#{file_name}) not declared in schema " +
          "or it is not a regular file"
        raise FileNotExist.new(file_name)
      end

      write_to_stream(
        File.join(PatchBuilder::INSTALL_DIR, result.digest), ios
      )
    end

    # comprobamos si el parche puede ser instalado
    # 1. ¿Existe la carpeta prefix?
    # 2. Comprobar que los hashs coinciden con los esperados
    # 3. ¿Hay espacio suficiente para hacer la instalación?
    # 4. ¿Hay espacio suficiente para guardar todos los backups?
    #
    # ignore_paths es una lista de rutas relativas o absolutas que van a ser
    # ignoradas en el backup. En caso de ser relativas, se trataría de rutas
    # relativas a basedir = prefix || info['PREFIX'] || File::SEPARATOR
    def check_install

      ignore_paths = @options[:ignore_paths] || []
      prefix = @options[:prefix]

      # basedir es el prefix con el que se instalará el parche. Tiene preferencia
      # el prefix enviado como argumento (por si queremos instalarlo en una
      # ruta alternativa), y en caso de que el argumento sea nil, intentamos
      # leer la variable PREFIX del archivo info.  Si tampoco se ha establecido
      # esta variable, se toma como basedir '/' como última opción.
      basedir = prefix || info['PREFIX'] || File::SEPARATOR

      # El basedir tiene que existir previamente. Observar que usamos realpath,
      # para que en caso de indicar un enlace simbólico, se compruebe si existe
      # el directorio apuntado.
      Clame.puts_check "(#{basedir}) directory prefix exists" do
        begin
          unless FileTest.directory?(File.realpath(basedir))
            raise PrefixNotExists.new(basedir)
          end
        rescue Errno::ENOENT
          raise PrefixNotExists.new(basedir)
        end
      end

      # integridad del archivo contents
      Clame.puts_check "integrity of the zip container patch" do
        check_integrity
      end

      # comprobar que hay espacio en los filesystems
      Clame.puts_check(
        "there is room enough to install the patch"
      ) do |msg_end|
        total_required = check_size_by_fs(basedir)
        msg_end.replace("Success: #{total_required} Kib required")
      end

      # Comprobar que hay espacio para hacer los backups de los archivos que se
      # sobreescribirán
      Clame.puts_check(
        "there is room enough to save the previous state"
      ) do |msg_end|
        begin
          space_bck_required =
            BackupPatch.new(get_core, basedir, ignore_paths).check_room
        rescue NotEnoughFsFreeSpace
          Clame.logger.error "Not enough free space in backup file system " +
            " to install (#{@patch_name}), version (#{@version})"
          raise NotRoomEnoughForBackup.new(@patch_name, @version,
                                          CONF_SETTINGS[:backup_dir_install])
        else
          # Ver funcion check_room para ver lo que devuelve la funcion
          # check_root
          msg_end.replace "Success: #{space_bck_required[:kib_required]} " +
          "KiB required, #{space_bck_required[:kib_free]} KiB free in " +
            "(#{space_bck_required[:fs]})"
        end
      end


    end # def check_install


    # Comprobar que existen los usuarios y grupos indicados en el schema. Puede
    # darse la siguiente circunstancia: no existe un usuario o grupo
    # referenciado en el schema, pero ese usuario o grupo se crea en el
    # preinstall. En general, esta comprobacion debería terminar con un warning
    # que el usuario debería confirmar
    def check_user_and_groups

      # Comprobamos que existan el usuario y grupo de los defaults.
      # Con el compact ignoramos los defaults no definidos en el schema
      # (en esos casos estarán definidos a nil)
      [get_core.schema.notdirdefaults,
        get_core.schema.dirdefaults].compact.each do |defaults|
        begin
          defuser = defaults.defuserowner
          Etc.getpwnam(defuser)
        rescue ArgumentError
          raise DefaultUserNotExists.new(defuser)
        end

        begin
          defgroup = defaults.defgrpowner
          Etc.getgrnam(defgroup)
        rescue ArgumentError
          raise DefaultGroupNotExists.new(defgroup)
        end
      end

      # agrupamos en el array schemaitems los archivos que se instalan bajo un
      # mismo usuario. Ignoramos aquellos archivos que no declaran propietario,
      # (schemaitem.userowner.nil?) ya que ello significa que se instalan con
      # el del usuario que ejecuta el proceso o con la máscara por defecto
      # Observar que los enlaces simbólicos no tienen propietario, así que para
      # ellos schemaitem.userowner.nil? es siempre true
      each.reject do |schemaitem|
        schemaitem.userowner.nil?
      end.group_by do |schemaitem|
        schemaitem.userowner
      end.each do |owner, schemaitems|
        # Para cada usuario, comprobamos que exista en el sistema donde se va a
        # instalar. En caso contrario, se propaga un error
        begin
          Etc.getpwnam(owner)
        rescue ArgumentError
          raise UserNotExists.new(owner, schemaitems)
        end
      end

      # agrupamos en el array schemaitems los archivos que se instalan bajo un
      # mismo grupo. Ignoramos aquellos archivos que no declaran grupo,
      # (schemaitem.grpowner.nil?) ya que ello significa que se instalan con
      # el del usuario que ejecuta el proceso
      # Observar que los enlaces simbólicos no tienen grupo, así que para
      # ellos schemaitem.grpowner.nil? es siempre true
      each.reject do |schemaitem|
        schemaitem.grpowner.nil?
      end.group_by do |schemaitem|
        schemaitem.grpowner
      end.each do |group, schemaitems|
        # para cada grupo, comprobamos que exista en el sistema donde se va a
        # instalar. En caso contrario, se propaga un error
        begin
          Etc.getgrnam(group)
        rescue ArgumentError
          raise GroupNotExists.new(group, schemaitems)
        end
      end

    end


    # Comprobar si hay espacio para instalar el parche. Devuelve los kilobytes
    # estimados que ocupará el parche una vez instalado
    def check_size_by_fs(prefix=nil)
      # El tamaño estimado que ocupará la instalación en cada filesystem.
      estimated_size_by_fs = estimated_size_by_fs(prefix)

      # Comprobamos si hay espacio libre en cada fs para realizar la instalación
      not_free_space_fs =
        estimated_size_by_fs.find_all do |fs, kib_required|
          Fs.free_space[fs] <= kib_required
        end

      if not_free_space_fs.empty?
        # devolvemos un array con los datos de cada fs
        estimated_size_by_fs.collect do |fs,kib_required|
          {:fs => fs, :kib_free => Fs.free_space[fs],
            :kib_required => kib_required}
        end
      else
        Clame.logger.error "Not enough free space in " +
          "(#{not_free_space_fs.first[0]}) to install " +
          "(#{@patch_name}), version (#{@version}). KiB required: " +
          "(#{not_free_space_fs.first[1]})"

        raise NotEnoughFsFreeSpace.new(not_free_space_fs)
      end

      # devolvemos el número de KiB necesarios para instalar el parche.
      # Redondear al alza
      estimated_size_by_fs.collect{|f,k| k}.inject(0,:+)
    end


    # Estimamos el número de KiB que ocupa la instalación del parche.
    def estimated_size_by_fs(prefix=nil)
      # La ruta base de instalación de aquellos ficheros que se han indicado
      # como rutas relativas en el esquema.
      basedir = prefix || info['PREFIX'] || File::SEPARATOR

      each.group_by do |schemaitem|
        # el directorio que mantiene al archivo schemaitem.destination
        File.dirname(schemaitem.destination)
      end.group_by do |dir, schemaitems|
        # Ojo, no vale usar Sys::Filesystem.mount_point, porque el archivo no
        # está instalado
        get_mount_point(File.join(basedir, dir))
        # el resultado es un hash que tiene como key un fs, y como valor una
        # matriz de 2 columnas y N filas. La primera columna es un directorio
        # (montado sobre el filesystem fs) y la segunda un array de schemaitems
        # que se hayan en ese directorio
      end.collect do |fs, matrix|
        # no nos interesa la primera columna de la matriz anterior
        [fs, matrix.collect{|m| m[1]}]
      end.collect do |fs, matrix|
        # convertimos la matriz de schemaitems en un array plano
        [fs, matrix.flatten]
      end.collect do |fs, schemaitems|
        # Para cada filesystem afectado, estimamos el número de bloques que
        # ocuparán la totalidad de archivos allí instalados
        schemaitems_kib = schemaitems.collect do |schemaitem|
          if schemaitem.filetype == FileType::REGFILE
            # Calculamos el tamaño en KiB
            ret_size = @container.file.size(
              File.join(PatchBuilder::INSTALL_DIR, schemaitem.digest)
            ).to_kib

            Clame.logger.debug "Computed size of <<#{schemaitem.digest}>>: " +
              "#{ret_size} KiB"
            ret_size
          else
            # Si un schemaitem no es un fichero regular, estimamos que ocupará
            # 1 bloque
            1
          end
          # Sumamos todo. Ojo, es necesario poner un 0, para que el resultado
          # sea 0 en el caso de que el array sea vacío.
        end.inject(0,:+)

        # devolvemos el filesytem, y el espacio estimado que ocuparía
        [fs, schemaitems_kib]
      end

      # El retorno es una matriz de N filas y dos columnas, de la forma:
      # [ fs1, kib_needed_1 ]
      #  .......................
      # [ fsN, kib_needed_N ]

    end # def estimated_size_by_fs


    # ######################
    # Instalación del parche.
    # ######################
    # ignore_paths es una lista de rutas que la instalación machacará
    # sin hacer previamente backup
    # La instalación del parche se compone de los siguientes pasos:
    # Comprobaciones:
    # * Comprobar si hay alguna versión del parche instalado. Si la hay,
    #   asegurarse de que la versión a instalar es superior a la máxima
    #   instalada.
    # * Comprobar si se satisfacen todas las dependencias
    # * Comprobar si hay algún parche conflictivo instalado
    # * Comprobar si la instalación de este parche provocaría un conflicto con
    #   otros ya instalado
    # #### FIN COMPROBACIONES
    # * Se vuelca al stdout el contenido del archivo legal.
    # * Fase de input: solicitud de todas las variables
    # * Fase de checkinstall.
    # * Se registra en la base de datos el parche y versión, con estado:
    #   RUN_PREINSTALL: Se ejecuta el preinstall
    # * Cambio de estado a RUN_SCHEMA: Se instalan los objetos del schema,
    #   haciendo backup de todo aquello que sea necesario, e ignorando las
    #   rutas indicadas en ignore_paths
    # * Cambio de estado a RUN_POSTINSTALL. Se ejecuta el postinstall
    # * Cambio de estado a INSTALLED.

    # Durante la ejecución de cualquier fase superior a checkinstall, hay que
    # atrapar la señal TERM o INT, para dejar el estado del parche en ERROR_*.
    # En la ejecución de cualquier script, se fija el stdin a /dev/null

    # Observar que no se realizan comprobaciones previas, ya que corresponden a
    # otra fase (por ejemplo, en algunos casos conviene no realizar ninguna
    # comprobación previa). Esto quiere decir que el método install no invocará
    # a check_install


    def install

      ##############################
      # Establecer parámetros
      ##############################
      # basedir: nil por defecto
      prefix = @options[:prefix]
      # ignorar requisitos: false por defecto
      ignore_reqs = @options[:ignore_reqs]
      # ignorar conflictos: false por defecto
      ignore_confs = @options[:ignore_confs]
      # rutas ignoradas: por defecto no hay rutas a ignorar
      ignore_paths = @options[:ignore_paths] || Array.new
      # ignorar si hay versiones superiores instaladas: por defecto false
      ignore_higher_versions = @options[:ignore_hvers]
      # ignorar si la instalación de este parche provoca algún conflicto con
      # otro ya instalado. Por defecto, es false
      ignore_installed_conflicts = @options[:ignore_installed_conflicts]

      ##############################
      # INICIO DE LAS COMPROBACIONES
      ##############################

      # Comprobar que el parche no esté ya instalado. Este error es severo
      # y no puede ser ignorado, ni siquiera con ignore_req=true
      Clame.puts_check "patch is not already installed" do
        check_patch_is_installed
      end

      # Comprobar que la versión a instalar es superior a todas las
      # actualmente instaladas
      unless ignore_higher_versions
        Clame.puts_check "version (#@version) is greather " +
            "than the whole of installed of (#@patch_name)" do |msg_end|
          begin
            max_version = check_max_version_installed
          rescue HigherPatchVersionInstalled
            raise unless ignore_higher_versions
          else
            msg_end.replace(
              max_version ?
                "Success: (#{max_version.version}) max version installed" :
                "Success: no version installed of #@patch_name"
            )
          end
        end
      end

      # Comprobar que todas las dependencias están instaladas
      Clame.puts_check "requirements" do |msg_end|
        begin
          check_requirements
        rescue RequirementsNotSatisfied
          unless ignore_reqs
            raise
          else
            msg_end.replace('Failed (but ignored by user)')
          end
        end
      end

      # Comprobar que no hay ningún conflicto instalado
      Clame.puts_check "conflicts" do |msg_end|
        begin
          check_conflicts
        rescue InstalledConflicts
          unless ignore_confs
            raise
          else
            msg_end.replace('Failed (but ignored by user)')
          end
        end
      end

      # Comprobar que no hay ningún parche instalado que provoque conflicto con
      # éste
      Clame.puts_check(
        "this patch will not cause conflict with other patch"
      ) do |msg_end|
        begin
          check_installed_conflicts
        rescue InstallWouldConflict
          unless ignore_installed_conflicts
            raise
          else
            msg_end.replace('Failed (but ignored by user)')
          end
        end
      end

      ##############################
      # FIN DE LAS COMPROBACIONES
      ##############################

      core = get_core

      # La ruta base de instalación de aquellos ficheros que se han indicado
      # como rutas relativas en el esquema.
      basedir = prefix || info['PREFIX'] || File::SEPARATOR

      Clame.puts_info "Setting installation prefix to (#{basedir})"

      Clame.logger.debug "Processing legal"
      manage_legal(core)

      # TODO: posibilidad de leer un fichero de respuestas.
      # input_responses es un hash de la forma var_name = var_value (o nil si
      # no hay input declarado en la estructura del parche). Estas variables se
      # registran en la tabla input_vars
      Clame.logger.debug "Processing input"
      input_responses = manage_input(core)

      # Registramos el parche en base de datos: nombre, versión, basedir
      # y descripción
      register_patch(basedir)

      # ejecución del checkinstall
      # TODO: si estamos ejecutando este proceso como root, cambiar a un
      # usuario que no tenga ningún permiso (¿nobody, nogroup?)
      # TODO: mirar por ejemplo en
      # http://www.garex.net/sun/packaging/scripts.html#checkinstall.


      if core.scripts_install[Core::CHECKINSTALL]
        Clame.puts_info "Run checkinstall"
        Clame.logger.debug "Checkinstall execution"
        begin
          Tempfile.open(Core::CHECKINSTALL) do |script_path|
            write_to_stream(
              File.join(PatchBuilder::INSTALL_DIR,
                        core.scripts_install[Core::CHECKINSTALL]),
              script_path
            )
            script_path.close
            Clame.exec_script(
              info, script_path.path,
              Core::CHECKINSTALL, basedir,
              input_responses
            )
          end
        rescue SignalException, StandardError
          # Si sucede un error, borramos el parche && version de la base de
          # datos
          unregister_patch
          raise
        end
      end

      # Recogemos las variables exportadas en el checkinstall
      checkins_out_vars = {}
      Clame.database.get_checkinstall_vars(
        @patch_name, @version
      ).each do |var_data|
        var_name = var_data['var_name']
        var_value = var_data['var_value']
        checkins_out_vars[var_name] = var_value
      end

      # Ejecución del preinstall
      if core.scripts_install[Core::PREINSTALL]
        Clame.puts_info "Run preinstall"
        Clame.logger.debug "Preinstall execution"
        set_status(ST_RUN_PREINSTALL)
        begin
          Tempfile.open(Core::PREINSTALL) do |script_path|
            @container.get_input_stream(
              File.join(PatchBuilder::INSTALL_DIR,
                        core.scripts_install[Core::PREINSTALL])
            ) do |file|
              IO.copy_stream(file, script_path)
            end
            script_path.close
            Clame.exec_script(
              info, script_path.path,
              Core::PREINSTALL, basedir,
              input_responses, checkins_out_vars
            )
          end
        rescue SignalException, StandardError
          set_status(ST_ERROR_PREINSTALL)
          Clame.logger.error "Error in preinstall: #$!"
          raise
        end
      end

      Clame.puts_check('exist schema defined user and groups') do
        begin
          check_user_and_groups
        rescue DefaultUserNotExists, DefaultGroupNotExists,
          UserNotExists, GroupNotExists
          raise
        end
      end


      # Realizar el backup
      Clame.logger.debug "Doing backup"
      set_status(ST_RUN_BACKUP)
      begin
        do_backup(core, basedir, ignore_paths)
      rescue SignalException, StandardError
        set_status(ST_ERROR_BACKUP)
        Clame.logger.error "Error doing backup: #$!"
        raise
      end

      # Instalar los componentes del schema
      Clame.logger.debug "Instalation schema"
      set_status(ST_RUN_SCHEMA)
      begin
        Clame.puts_info "Installing schema components"
        install_schema(core, basedir)
      rescue
        set_status(ST_ERROR_SCHEMA)
        Clame.logger.error "Error in schema installation: #$!"
        raise
      end

      # ejecución del postinstall
      if core.scripts_install[Core::POSTINSTALL]
        Clame.puts_info "Run postinstall"
        Clame.logger.debug "Postinstall execution"
        set_status(ST_RUN_POSTINSTALL)
        begin
          Tempfile.open(Core::POSTINSTALL) do |script_path|
            write_to_stream(
              File.join(PatchBuilder::INSTALL_DIR,
                        core.scripts_install[Core::POSTINSTALL]),
              script_path
            )
            script_path.close
            Clame.exec_script(
              info, script_path.path,
              Core::POSTINSTALL, basedir,
              input_responses, checkins_out_vars
            )
          end
        rescue SignalException, StandardError
          set_status(ST_ERROR_POSTINSTALL)
          Clame.logger.error "Error in postinstall: #$!"
          raise
        end
      end

      # Registrar los archivos que instala este parche
      Clame.logger.debug "Register installed files"
      set_status(ST_REGISTER_INSTALLED_FILES)
      begin
        Clame.puts_task "Register installed files" do
          Clame.database.register_installed_files(core, basedir)
        end
      rescue
        set_status(ST_ERROR_REGISTER_INSTALLED_FILES)
        Clame.logger.error "Error registering installed files: #$!"
        raise
      end

      # Registrar los scripts postinstall, preinstall, etc.
      Clame.logger.debug "Register install scripts"
      set_status(ST_REGISTER_INSTALL_SCRIPTS)
      begin
        # Recuperar los scripts de instalación, comprimidos.
        # Se los enviamos a la base de datos para que los registre
        Clame.puts_task "Register patch scripts" do
          Clame.database.register_install_scripts(self)
        end
      rescue
        set_status(ST_ERROR_REGISTER_INSTALL_SCRIPTS)
        Clame.logger.error "Error registering install scripts: #$!"
        raise
      end

      # Registrar requisitos
      Clame.logger.debug "Register requisites"
      set_status(ST_REGISTER_REQUISITES)
      begin
        Clame.puts_task "Register patch requisites" do
          Clame.database.register_requisites(core)
        end
      rescue
        set_status(ST_ERROR_REGISTER_REQUISITES)
        Clame.logger.error "Error registering requisites: #$!"
        raise
      end

      # Registrar conflictos.
      # El registro de un conflicto implica que tiene que estar registrado el
      # nombre del parche en la tabla patches
      Clame.logger.debug "Register conflicts"
      set_status(ST_REGISTER_CONFLICTS)
      begin
        Clame.puts_task "Register patch conflicts" do
          Clame.database.register_conflicts(core)
        end
      rescue
        set_status(ST_ERROR_REGISTER_CONFLICTS)
        Clame.logger.error "Error registering conflicts: #$!"
        raise
      end

      # Registrar las variables input
      Clame.logger.debug "Register input vars"
      set_status(ST_REGISTER_INPUT_VARS)
      begin
        Clame.puts_task "Register input variables" do
          Clame.database.register_input_vars(core, input_responses)
        end
      rescue
        set_status(ST_ERROR_REGISTER_INPUT_VARS)
        Clame.logger.error "Error registering input vars: #$!"
        raise
      end

      # Registrar las variables info
      Clame.logger.debug "Register info vars"
      set_status(ST_REGISTER_INFO_VARS)
      begin
        Clame.puts_task "Register info variables" do
          Clame.database.register_info_vars(info)
        end
      rescue
        set_status(ST_ERROR_REGISTER_INFO_VARS)
        Clame.logger.error "Error registering info vars: #$!"
        raise
      end


      # Parche correctamente instalado. Cambiar a estado ST_INSTALLED
      set_status(ST_INSTALLED)

    end # def install


    # Comprueba si hay alguna versión del parche instalada, y en ese
    # caso asegurar de que la versión máxima es inferior a la que se pretende
    # instalar. Devuelve la versión máxima instalada, o nil si no hay ninguna
    def check_max_version_installed
      # un array con las versiones actualmente instaladas
      versions_installed = Clame.database.get_versions_installed(@patch_name)
      # La versión máxima instalada. Hay que convertir previamente a objetos
      # PatchVersion para que pueda extraerse el máximo
      max_version_installed = versions_installed.collect do |version|
        PatchVersion.new(@patch_name, version)
      end.max

      # Si max_version_installed es null, significa que no hay ninguna versión
      # del parche instalada
      version_to_install = PatchVersion.new(@patch_name, @version)
      if max_version_installed
        if version_to_install <= max_version_installed
          Clame.logger.warn "Version #{max_version_installed.version} " +
            "of patch #@patch_name is already installed"

          raise HigherPatchVersionInstalled.new(@patch_name,
                                                version_to_install.version,
                                                max_version_installed.version)
        end
      else
        # Se trata de la primera instalación del parche
        Clame.logger.info "Installing first version " +
          "(#{version_to_install.version}) of patch (#@patch_name)"
      end

      return max_version_installed

    end


    def check_requirements

      return unless (depend = get_core.depend)

      failed_reqs = depend.requisites.reject do |req|
        # Cada requisito es un intervalo, tal y como se define en la clase
        # Interval
        # vers_installed son las versiones instaladas del parche al que se
        # refiere el requisito req
        vers_installed = Clame.database.get_versions_installed(
          req.extreme.patchname
        ).collect{|v| PatchVersion.new(req.extreme.patchname, v)}

        # Comprobar si alguno de las vers_installed satisface el requisito
        # actual
        vers_installed.any?{|v| req.include?(v)}
      end

      # Se devuelven en la excepción la totalidad de requisitos que no se
      # satisfacen
      unless failed_reqs.empty?
        Clame.logger.warn("The following requirements are not satisfied: " +
          failed_reqs.collect do |int|
            "#{int.extreme.patchname} #{int.operator} #{int.extreme.version}"
          end.join(', ')
        )
        raise RequirementsNotSatisfied.new(failed_reqs)
      end

    end


    def check_conflicts
      return unless (depend = get_core.depend)

      # Cada conflicto es un objeto de tipo Interval
      inst_conflicts = depend.conflicts.collect do |conf|
        vers_installed = Clame.database.get_versions_installed(
          conf.extreme.patchname
        ).collect{|v| PatchVersion.new(conf.extreme.patchname, v)}

        # Recuperamos los parches instalados que provocan conflicto
        vers_installed.find_all{|v| conf.include?(v)}
      end.flatten

      # inst_conflicts es un array con todos los parches que provocan conflicto
      # Se devuelven en la excepción la totalidad de los parches conflictivos
      unless inst_conflicts.empty?
        Clame.logger.warn(
          "The following conflicted patches are installed: " +
            inst_conflicts.collect do |patch|
              "#{patch.patchname} #{patch.version}"
            end.join(', ')
        )
        raise InstalledConflicts.new(inst_conflicts)
      end
    end


    def check_installed_conflicts
      version_to_install = PatchVersion.new(@patch_name, @version)
      # Recuperar los parches que pueden provocar conflicto con éste que
      # va a ser instalado, inspeccionando la tabla conflicts
      conflict_patches =
        Clame.database.get_possible_conflicts(
          @patch_name
        ).find_all do |conflict|
          # Comprobar si el parche a ser instalado cae en el intervalo
          conflict[:interval].include?(version_to_install)
        end

      # No hay conflictos, volvemos sin error
      return if conflict_patches.empty?

      # Hay conflictos: devolvemos un error
      raise InstallWouldConflict.new(conflict_patches)
    end


    # Comprueba si el parche está instalado
    def check_patch_is_installed
      status = Clame.database.get_status(@patch_name, @version)
      if status
        Clame.logger.error(
          "Patch name (#@patch_name), version (#@version) " +
          "is already installed with status (#{status})"
        )
        raise PatchAlreadyInstalled.new(@patch_name, @version, status)
      end
    end

    # El contenido de un script de instalación/desinstalación
    def content_script(script_name)
      script_file = get_core.scripts_install[script_name]

      return unless script_file

      StringIO.open(String.new, 'w+') do |strio|
        write_to_stream(File.join(PatchBuilder::INSTALL_DIR, script_file),
                        strio)
        strio.rewind
        strio.read
      end

    end


    def get_core
      Marshal.load(
        @container.read(
          File.join(
            PatchBuilder::BASE_PATCHES, @patch_name, @version,
            PatchBuilder::CORE_FILE
          )
        )
      )

    rescue Errno::ENOENT
      Clame.logger.error "Cannot find (" +
        File.join(
            PatchBuilder::BASE_PATCH, @patch_name, @version,
            PatchBuilder::CORE_FILE
        ) + ") in #{@container.name}"
      raise PatchNameVersionNotFound.new(@patch_name, @version)
    end



    private

    def write_to_stream(file_name, ios)
      @container.get_input_stream(file_name) do |file|
        IO.copy_stream(file, ios)
      end
    rescue Errno::ENOENT
      # entrada inexistente
      Clame.logger.error "Cannot find (#{file_name}) in #{@container.name}"
      raise ContainerEntryNotExist.new(file_name)
    end



    # Registro inicial del parche. El efective uid del proceso es necesario
    # registrarlo en bd para garantizar que la desinstalación se realiza bajo
    # el mismo usuario
    def register_patch(prefix)
      Clame.database.register_patch_version(
        @patch_name, @version, info[Info::DESCRIPTION], prefix, Process.euid
      )
    end

    # Rollback de registro: borrar el parche registrado en base de datos
    def unregister_patch
      Clame.database.unregister_patch_version(@patch_name, @version)
    end


    # Instala los componentes del schema
    def install_schema(core, basedir)

      notdirdefaults = core.schema.notdirdefaults
      dirdefaults = core.schema.dirdefaults

      # Instalación de los directorios
      core.schema.directories.each do |diritem|
        # Los permisos, usuario y grupo con el que se instalará este archivo
        mode, user, group = diritem.attr!(dirdefaults)
        destination = File.absolute_path(diritem.destination, basedir)

        # Creamos el directorio y todos los padres.
        # Los directorios padres que necesiten ser creados se crean con el
        # usuario, grupo y máscara del proceso en curso.
        Clame.puts_task "Create directory: #{mode.to_s(8)} " +
          "#{user}:#{group} (#{destination})" do
          FileUtils.mkdir_p destination
          FileUtils.chown user, group, destination
          FileUtils.chmod mode, destination
        end

      end

      # Archivos regulares
      core.schema.regfiles.each do |fileitem|
        # Los permisos, usuario y grupo con el que se instalará este archivo
        mode, user, group = fileitem.attr!(notdirdefaults)
        destination = File.absolute_path(fileitem.destination, basedir)

        FileUtils.rm_f(destination)

        # Creamos el directorio y todos los padres.
        # Los directorios padres que necesiten ser creados se crean con el
        # usuario, grupo y máscara del proceso en curso.
        FileUtils.mkdir_p File.dirname(destination)

        Clame.puts_task "Create regular file: #{mode.to_s(8)} " +
          "#{user}:#{group} (#{destination})" do
          Clame.logger.debug "Extracting regular file <<#{destination}>>"
          File.open(destination, 'w') do |dest|
            write_to_stream(
              File.join(PatchBuilder::INSTALL_DIR, fileitem.digest), dest
            )
          end
          FileUtils.chown user, group, destination
          FileUtils.chmod mode, destination
        end
      end # core.schema.regfiles.each

      # pipes
      core.schema.pipes.each do |fileitem|
        # Los permisos, usuario y grupo con el que se instalará este archivo
        mode, user, group = fileitem.attr!(notdirdefaults)
        destination = File.absolute_path(fileitem.destination, basedir)

        FileUtils.rm_f(destination)

        # Creamos el directorio y todos los padres.
        # Los directorios padres que necesiten ser creados se crean con el
        # usuario, grupo y máscara del proceso en curso.
        FileUtils.mkdir_p File.dirname(destination)

        Clame.puts_task "Create pipe: #{mode.to_s(8)} " +
          "#{user}:#{group} (#{destination})" do
          File.mkfifo(destination)
          FileUtils.chown user, group, destination
          FileUtils.chmod mode, destination
        end

      end # core.schema.pipes.each

      # Enlaces simbólicos
      core.schema.symlinks.each do |symlinkitem|
        symlinkname = File.absolute_path(symlinkitem.destination, basedir)
        FileUtils.rm_f(symlinkname)

        # Creamos el directorio y todos los padres.
        # Los directorios padres que necesiten ser creados se crean con el
        # usuario, grupo y máscara del proceso en curso.
        FileUtils.mkdir_p File.dirname(symlinkname)

        Clame.puts_task "Create symlink: (#{symlinkname}) -> " +
          "(#{symlinkitem.origin})" do
          FileUtils.symlink symlinkitem.origin, symlinkname
        end

      end

      # Hard links. Tienen que instalarse los últimos, para asegurar de que se
      # han instalado previamente el resto de ficheros que pudieran ser
      # referenciados por un hardlink
      core.schema.hardlinks.each do |hardlinkitem|
        hardlinkname = File.absolute_path(hardlinkitem.destination,  basedir)
        FileUtils.rm_f(hardlinkname)

        # Creamos el directorio y todos los padres.
        # Los directorios padres que necesiten ser creados se crean con el
        # usuario, grupo y máscara del proceso en curso.
        FileUtils.mkdir_p File.dirname(hardlinkname)

        # Si el destino del hardlink es una ruta relativa, la consideramos bajo
        # PREFIX. En caso constrario (ruta absoluta) la respetamos.

        dest = File.absolute_path(hardlinkitem.origin, basedir)
        Clame.puts_task "Hardlink: (#{hardlinkname}) -> (#{dest})" do
          FileUtils.ln dest, hardlinkname
        end

      end

    end # def install_schema


    def set_status(newstatus)
      Clame.logger.debug "Set status of #@patch_name, " +
        "#@version: #{newstatus}"
      Clame.database.set_status(@patch_name, @version, newstatus)
    end


    # Realiza un backup completo de todos los archivos que pueda sobreescribir
    # la instalación de este parche. No solo guarda un backup del contenido de
    # cada archivo regular, sino que guarda tambien todos los atributos
    # posibles
    def do_backup(core, basedir, ignore_paths)
      backup = BackupPatch.new(core, basedir, ignore_paths)
      # Hacer una copia de seguridad de los archivos que se sobreescriben
      backup.make
      # Registrar la información de backup en base de datos
      Clame.puts_info "Register info backup in clame database"
      backup.register
    end


    def manage_input(core)
      # Iterar sobre las variables input declaradas, y solicitar el dato que
      # corresponda. input_var es una matriz de 3 columnas: la primera columna
      # es el tipo de dato (password, normal o booleana), la segunda el nombre
      # de la variable, y la tercera la descripción de la variable
      # Las duplas [nbe_variable, valor] se almacenan en un hash, que es el que
      # se devuelve en el procedimiento

      # si no se ha declarado nada en el input, se devuelve nil
      return nil unless core.input

      $stdout.puts 'Please type the value for the following variables:'
      $stdout.puts "\n"

      # hash de retorno
      ret = {}

      core.input.normals.each do |normal_var|
        var_name, var_desc = normal_var
        $stdout.puts var_desc
        $stdout.print "#{var_name}> "
        # variable normal
        ret[var_name] = $stdin.gets.chomp
      end

      core.input.passwords.each do |password_var|
        var_name, var_desc = password_var
        # Se está solicitando un password. Imitamos el ejemplo de
        # gems/1.9/doc/ruby-termios-0.9.6/rdoc/Termios.html
        ret[var_name] = request_password(var_name, var_desc)
        print "\n"
      end

      core.input.booleans.each do |boolean_var|
        var_name, var_desc = boolean_var
        ret[var_name] = request_boolean(var_name, var_desc)
      end

      # retorno
      ret
    end


    def manage_legal(core)
      # si no se ha declarado nada en el legal, se devuelve nil
      return nil unless core.legal

      # ponemos una linea en blanco antes de escribir el texto, para aumentar
      # la legibilidad
      $stdout.puts
      write_to_stream(File.join(PatchBuilder::INSTALL_DIR, core.legal),
                      $stdout)
      # Si es necesario aceptar expresamente el contenido de legal, nos paramos
      # a pedir confirmación
      if info[Info::REQUIRE_ACCEPT_LEGAL]
        $stdout.puts 'Type YES to accept the legal terms'
        response = gets
        raise LegalNoticeNotAccepted.new unless response.chomp == 'YES'
      end

      # ponemos una linea en blanco después de escribir el texto, para aumentar
      # la legibilidad
      $stdout.puts

    end



    def request_password(var_name, var_desc)
      oldt = Termios.tcgetattr($stdin)
      newt = oldt.dup
      newt.lflag &= ~Termios::ECHO

      begin
        Termios.tcsetattr($stdin, Termios::TCSANOW, newt)
        $stdout.print var_desc
        begin
          $stdout.print "\n#{var_name} (PASSWORD)>"
          password = $stdin.gets.chomp
          $stdout.print "\nRetype password:"
          retyped_password = $stdin.gets.chomp
        end while(password != retyped_password)
      ensure
        Termios.tcsetattr($stdin, Termios::TCSANOW, oldt)
      end

      # retorno
      password

    end


    def request_boolean(var_name, var_desc)
      $stdout.puts var_desc
      $stdout.puts 'Please type y o n'
      begin
        $stdout.print "#{var_name} (BOOLEAN)> "
        var_value = $stdin.gets.chomp
      end while(var_value !~ /y|n/)

      # retorno. Será true o false
      var_value == 'y'
    end


    def compare_digest(entry, expected)
      Tempfile.open('tmpentry') do |tmpentry|
        write_to_stream(entry, tmpentry)
        tmpentry.close
        unless Digest::SHA256.file(tmpentry).hexdigest == expected
          Clame.logger.error "Integrity check failed in (#{entry}). " +
            "Expected digest was (#{expected})"
          raise IntegrityCheckFail.new(entry, expected)
        end
      end
    end


    def get_mount_point(pathname)
      # Esto funciona porque Fs.mounted_fs está ordenado por profundidad en
      # orden inverso.
      Fs.mounted_fs.detect{|fs| Pathname.new(pathname).subdir?(Pathname.new(fs))}
    end

  end

end
