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

require 'mkfifo'

module Clame

  # La clase InstalledPatch representa un parche ya instalado en el sistema.
  # El parche NO tiene que estar necesariamente en el estado "Correctamente
  # instalado"
  class InstalledPatch

    attr_reader :patch_name, :version

    def initialize(patch_name, version)
      @patch_name = patch_name
      @version = version

      # El parche debe figurar en la base de datos. En caso contrario, se
      # propagará una excepción
      unless Clame.database.get_patch_version_id(patch_name, version)
        raise PatchNotExist.new(patch_name, version)
      end


    end

    def prefix
      Clame.database.get_prefix(@patch_name, @version)
    end


    # #########################
    # Desinstalación del parche
    # #########################
    # La desinstalación del parche se compone de los siguientes pasos:
    # Comprobaciones:
    # * Comprobar si hay alguna versión del parche instalado. Si la hay,
    #   asegurarse de que la versión a desinstalar es superior a todas
    #   las instaladas.
    # * Comprobar si la desintalación rompería alguna dependencia
    # #### FIN COMPROBACIONES
    # * Cambio de estado a RUN_PREREMOVE. Se ejecuta el preremove.
    # * Cambio de estado a RUN_RESTORE: Se restaura el backup y se borran
    #   los ficheros nuevos que instaló el parche
    # * Cambio de estado a RUN_POSTREMOVE. Se ejecuta el postremove
    # * Se elimina el registro de la tabla patch_versions. Se deja en su sitio
    #   el registro de la tabla patches.

    # Durante la ejecución del preremove o postremove hay que atrapar la señal
    # TERM o INT, para dejar el estado del parche en ERROR_*.  En la ejecución
    # de cualquier script, se fija el stdin a /dev/null

    def uninstall(options={})

      ##############################
      # Establecer parámetros
      ##############################
      # ignorar requisitos: false por defecto
      ignore_reqs = options[:ignore_reqs]
      # ignorar si hay versiones superiores instaladas: por defecto false
      ignore_higher_versions = options[:ignore_hvers]
      # En caso de error en el restore, abortar. false por defecto
      abort_on_restore_error = options[:abort_on_restore_error]
      # Ignorar discrepancias entre el usuario que ejecuta la instalación y la
      # desinstalación. False por defecto
      ignore_unmatching_uid = options[:ignore_unmatching_uid]

      Clame.logger.debug "Uninstall options: #{options}"
      Clame.logger.info "Unstalling (#@patch_name), version (#@version)"
      Clame.puts_info "Unstalling (#@patch_name), version (#@version)"

      ##############################
      # INICIO DE LAS COMPROBACIONES
      ##############################


      # La ruta base donde se ha instalado el parche
      basedir = self.prefix

      # Comprobar que la versión a desinstalar es superior a todas las
      # actualmente instaladas

      Clame.puts_check "Version (#@version) is the highest of the patch "+
        "(#@patch_name)" do |msg_end|
        begin
          check_max_version_installed
        rescue HigherPatchVersionInstalled
          unless ignore_higher_versions
            raise
          else
            msg_end.replace('Failed (but ignored by user)')
          end
        end
      end

      # Comprobar si con la desinstalación se rompe alguna dependencia
      Clame.puts_check \
        "The unistallation will not break any dependency" do |msg_end|
        begin
          check_broken_requirements
        rescue RequirementsWouldBeBroken
          unless ignore_reqs
            raise
          else
            msg_end.replace('Failed (but ignored by user)')
          end
        end
      end

      # Si el usuario que está desinstalando no es root, recuperar el uid con
      # el que se instalo el parche. Si no coincide con el actual, tirar un
      # error
      Clame.puts_check 'Effective installation uid is the same ' +
        'as current one' do |msg_end|
        if (Process.euid != 0) && (self.uid != Process.euid)
          unless ignore_unmatching_uid
            raise ProcessIDNotMatch.new(self.uid, Process.euid)
          else
            msg_end.replace('Failed (but ignored by user)')
          end
        end
      end


      ##############################
      # FIN DE LAS COMPROBACIONES
      ##############################

      # Recuperar las variables input_responses
      input_responses = {}
      Clame.puts_task "Get input variables" do
        Clame.database.get_input_vars(
          @patch_name, @version
        ).each do |var_data|
          var_name = var_data['var_name']
          var_value = var_data['var_value']
          input_responses[var_name] = var_value
        end
      end

      # Recuperar las variables checkins_out_vars
      # Recogemos las variables exportadas en el checkinstall
      checkins_out_vars = {}
      Clame.puts_task "Get checkinstall variables" do
        Clame.database.get_checkinstall_vars(
          @patch_name, @version
        ).each do |var_data|
          var_name = var_data['var_name']
          var_value = var_data['var_value']
          checkins_out_vars[var_name] = var_value
        end
      end

      # Recuperar las variables de info_vars
      info = {}
      Clame.puts_task "Get info variables" do
        Clame.database.get_info_vars( @patch_name, @version).each do |var_data|
          var_name = var_data['var_name']
          var_value = var_data['var_value']
          info[var_name] = var_value
        end
      end

      # Ejecución del preremove
      preremove_content =
        Clame.database.get_install_script(
          @patch_name, @version, Core::PREREMOVE
        )

      if preremove_content
        Clame.logger.debug "Preremove execution"
        Clame.puts_info "Run preremove"
        self.status = ST_RUN_PREREMOVE
        begin
          Tempfile.open(Core::PREREMOVE) do |script_path|
            script_path.write(preremove_content)
            script_path.close
            Clame.exec_script(
              info, script_path.path,
              Core::PREREMOVE, basedir,
              input_responses, checkins_out_vars
            )
          end
        rescue SignalException, StandardError
          self.status = ST_ERROR_PREREMOVE
          Clame.logger.error "Error in preremove: #$!"
          raise
        end

      end # if preremove_content


      ## Restaurar el backup
      Clame.logger.debug "Restore backup"
      Clame.puts_info "Restore backup"
      self.status = ST_RUN_RESTORE
      begin
        do_restore(abort_on_restore_error)
      rescue
        self.status = ST_ERROR_RESTORE
        Clame.logger.error "Error doing restore: #$!"
        raise
      end

      ## ejecución del postremove
      postremove_content =
        Clame.database.get_install_script(
          @patch_name, @version, Core::POSTREMOVE
        )

      if postremove_content
        Clame.logger.debug "Postremove execution"
        Clame.puts_info "Run postremove"
        self.status = ST_RUN_POSTREMOVE
        begin
          Tempfile.open(Core::POSTREMOVE) do |script_path|
            script_path.write(postremove_content)
            script_path.close
            Clame.exec_script(
              info, script_path.path,
              Core::POSTREMOVE, basedir,
              input_responses, checkins_out_vars
            )
          end
        rescue SignalException, StandardError
          self.status = ST_ERROR_POSTREMOVE
          Clame.logger.error "Error in postremove: #$!"
          raise
        end
      end

      ## Eliminar el PatchVersion de la base de datos
      Clame.puts_task "Unregister patch (#@patch_name), version (#@version) " +
        "from database" do
        Clame.database.unregister_patch_version(@patch_name, @version)
      end

      Clame.logger.info \
        "(#@patch_name), version (#@version) succesfully uninstalled"

    end


    def status=(new_status)
      Clame.logger.debug "Set status of #@patch_name, " +
        "#@version: #{new_status}"
      Clame.database.set_status(@patch_name, @version, new_status)
    end


    def status
      Clame.database.get_status(@patch_name, @version)
    end


    def uid
      Clame.database.get_uid(@patch_name, @version)
    end



    private

    # Restaura los archivos de backup y elimina los archivos nuevos
    # que instaló este parche
    #
    # Procedimiento de restauración.
    # Recuperar la clase BackupPatch de la base de datos, e iterar sobre cada
    # fichero que contiene (sea regular o no). Para cada uno, realizamos las
    # siguientes operaciones:
    # 1- Si es un directorio, intentamos crearlo si no existe, con los
    #    atributos que tenía. Si existe, simplemente le ponemos los atributos.
    # 2- Si no es un directorio, borramos primero el archivo actual y en su
    #    lugar ponemos el backup, respetando los atributos anteriores. Aquí
    #    hay que distinguir los casos de ficheros regular y otro tipo, ya que
    #    en el caso de los ficheros regulares hay que tirar del backup
    #    guardado en la ruta apropiada.
    def do_restore(abort_on_error=false)

      # El objeto backup guardado.
      backup_obj = Clame.database.get_backup_info(@patch_name, @version)

      # Si no hay objeto backup, volvemos
      return unless backup_obj

      # Recorremos primero los directorios que existían antes de instalar el
      # parche. Los ordenamos por profundidad ascendente, y para cada uno de
      # ellos, restauramos los permisos.
      backup_obj.info_installed_paths.find_all do |info|
        info[:actual] && info[:actual][:stat].ftype == FileType::DIRECTORY
      end.sort_by do |info|
        Pathname.new(
          File.absolute_path(info[:new].destination, self.prefix)
        ).parents.to_a.length
      end.each do |info|
        dirname = File.absolute_path(info[:new].destination,  self.prefix)
        Clame.logger.debug "Restore directory #{dirname}"
        begin
          # Si la ruta actual existe y no es un directorio, avisamos
          # y continuamos con la siguiente iteración en caso permitido
          # (abort_on_error)
          if File.exist?(dirname) && !File.directory?(dirname)
            msg = "(#{dirname}) exists but it should be a directory"
            Clame.logger.warn msg
            raise UninstallError.new(msg) if abort_on_error
            next
          end

          # Para este directorio, intentamos reconstruir los atributos
          # antiguos. Si no existe, se intenta crear
          Clame.puts_task("Create directory #{dirname}") do
            Dir.mkdir(dirname) unless File.exist?(dirname)

            old_stat = info[:actual][:stat]

            File.utime(old_stat.atime, old_stat.mtime, dirname)
            File.chown(old_stat.uid, old_stat.gid, dirname)
            File.chmod(old_stat.mode, dirname)
          end


        rescue
          msg = "Error: " + $!.to_s
          Clame.logger.warn msg
          raise UninstallError.new(msg) if abort_on_error
          $stderr.puts msg
        end
      end

      # Recorremos los ficheros que o bien no existían antes de instalar el
      # parche o bien existían pero no eran directorios (es decir, los ficheros
      # no seleccionados en el paso anterior).
      # Caso 1: El fichero no existía previamente
      #   Aquí contemplamos dos casos: en su lugar se ha instalado un directorio,
      #   o el caso contrario. En el primer caso, pasamos a la siguiente iteración,
      #   y en el segundo, borramos sin más el archivo.
      # Caso 2: El fichero existía previamente.
      #   En este caso, no puede ser un directorio, así que restauramos el
      #   backup
      #
      backup_obj.info_installed_paths.find_all do |info|
        !info[:actual] || info[:actual][:stat].ftype != FileType::DIRECTORY
      end.each do |info|
        # Ruta absoluta al archivo
        path = File.absolute_path(info[:new].destination, self.prefix)

        # Caso 1: El fichero no existía previamente
        #   Aquí contemplamos dos casos: en su lugar se ha instalado un
        #   directorio, o el caso contrario (fichero regular, enlace simbólico,
        #   etc). En el primer caso, pasamos a la siguiente iteración (este caso
        #   sería posteriormente tratado ) y en el segundo, borramos sin más el
        #   archivo.
        unless info[:actual]
          next if info[:new].filetype == FileType::DIRECTORY
          Clame.logger.debug "Removing file #{path}"
          begin
            Clame.puts_task("Remove #{path}"){FileUtils.rm_f(path)}
          rescue
            msg = "Error: " + $!.to_s
            Clame.logger.warn msg
            raise UninstallError.new(msg) if abort_on_error
            $stderr.puts msg
          end
        else
          # Caso 2: El fichero existía previamente, y no es un directorio. Por
          # lo tanto, restauramos el backup. Observar que puede tratarse de un
          # fichero regular, un hardlink, un pipe, o un symlink.
          # Sin embargo, como se trata del atributo fstype de la clase stat,
          # no se distingue entre fichero regular y hardlink; en ambos casos
          # se trata de un fichero regular (old_ftype = FileType::REGFILE)
          Clame.logger.debug "Restore file #{path}"
          begin
            # Información del antiguo objeto
            old_digest = info[:actual][:digest]
            old_stat = info[:actual][:stat]
            old_ftype = old_stat.ftype
            # Sólo si se trata de un enlace simbólico
            old_link_dest = info[:actual][:link_dest]

            # Restauración del antiguo fichero
            case old_ftype
            when FileType::REGFILE
              Clame.puts_task( "Restore regular file (#{path})") do |msg_end|

                # El digest del fichero ahora mismo instalado, en caso
                # de ser un fichero regular. En otro caso, nil. Es necesario
                # conocer el digest porque en caso de que sea igual que el
                # antiguo, no existirá tal archivo en la zona de backup.
                new_digest = info[:new].digest rescue nil

                # Si el antiguo y nuevo fichero son iguales, no hay que
                # restaurar nada, tan solo reponer los permisos.
                # Observar que old_digest no puede ser nil, ya que se trata
                # de un fichero regular (old_ftype = FileType::REGFILE)
                if new_digest == old_digest
                  msg_end.replace 'Restoring only metadata'
                else
                  # Los ficheros son distintos. Restauramos desde el backup
                  backup_dir = CONF_SETTINGS[:backup_dir_install]
                  digest_prefix = old_digest[0, BackupPatch::LENGTH_BACKUP_DIR]
                  Clame.logger.debug "Restore #{old_digest} -> #{path}"
                  FileUtils.copy(
                    File.join(backup_dir, digest_prefix, old_digest),
                    path
                  )
                end

                File.utime(old_stat.atime, old_stat.mtime, path)
                File.chown(old_stat.uid, old_stat.gid, path)
                File.chmod(old_stat.mode, path)

              end

            when FileType::PIPE
              Clame.puts_task("Restore fifo (#{path})") do
                # Borramos el archivo antes de restaurar
                FileUtils.rm_f(path)
                File.mkfifo(path)
              end
            when FileType::SYMLINK
              Clame.puts_task "Restore symlink #{path} -> #{old_link_dest}" do
                # Borramos el archivo antes de restaurar
                FileUtils.rm_f(path)
                File.symlink(old_link_dest, path)
              end
            when FileType::HARDLINK
              # Esta sección de código no puede ejecutarse nunca, ya que un FileType
              # nunca puede ser de tipo hardlink (ver comentario en la clase FileType)
              # No es posible reconstruir un hardlink
              Clame.puts_info "Cannot restore hardlinks"
              Clame.logger.warn "Cannot restore hardlinks"
            end

          rescue
            msg = "Error: " + $!.to_s
            Clame.logger.warn msg
            raise UninstallError.new(msg) if abort_on_error
            $stderr.puts msg
          end
        end

      end

      # Queda un caso por tratar: el fichero no existía previamente y en su
      # lugar se ha instalado un directorio. En ese caso intentamos borrar ese
      # directorio
      backup_obj.info_installed_paths.find_all do |info|
        !info[:actual] && info[:new].filetype == FileType::DIRECTORY
      end.sort_by do |info|
        # Ordenamos por profundidad del directorio, descendente (por eso
        # ponemos el negativo delante)
        - Pathname.new(
          File.absolute_path(info[:new].destination, self.prefix)
        ).parents.to_a.length
      end.each do |info|
        dirname = File.absolute_path(info[:new].destination, self.prefix)
        begin
          Clame.logger.debug "Remove directory #{dirname}"
          Clame.puts_task("Remove directory #{dirname}"){Dir.rmdir(dirname)}
        rescue
          msg = "Error removing directory (#{dirname}): " + $!.to_s
          Clame.logger.warn msg
          raise UninstallError.new(msg) if abort_on_error
          $stderr.puts msg
        end
      end

    end

    # Comprueba si la desinstalación de este parche rompe alguna dependencia
    def check_broken_requirements

      # Recuperar todos los parches que podrían tener a éste que se va a
      # desinstalar como dependencia.
      #
      # La llamada a get_dependent_patches devuelve un array donde cada
      # componente es un hash de esta forma:
      # {patch_name, version, interval}
      # (patch_name, version) es un parche que tiene a interval como
      # dependencia, e interval es un Interval que contiene self
      deps =
        Clame.database.get_dependent_patches(@patch_name, @version)

      # Comprobar si cada interval contiene a algún otro parche además
      # del que se va a desinstalar. Si algún interval falla en esta
      # comprobación significa que no es posible desinstalar el parche en
      # cuestión, porque se rompería alguna dependencia

      broken_deps = deps.find_all do |dep|
        # Recuperar los parches instalados que caen en el intervalo. Si
        # exactamente hay 1, esa dependencia se rompería al desinstalar
        Clame.database.get_installed_patches(dep[:interval]).length == 1
      end

      unless broken_deps.empty?
        raise RequirementsWouldBeBroken.new(broken_deps)
      end

    end



    # Comprueba si hay alguna versión del parche instalada, y en ese
    # caso asegurar de que la versión máxima es igual a la que se pretende
    # desinstalar. Es decir, no se puede desinstalar un parche si hay alguna
    # versión superior instalada
    def check_max_version_installed
      # un array con las versiones actualmente instaladas
      versions_installed = Clame.database.get_versions_installed(@patch_name)
      # La versión máxima instalada. Hay que convertir previamente a objetos
      # PatchVersion para que pueda extraerse el máximo
      max_version_installed = versions_installed.collect do |version|
        PatchVersion.new(@patch_name, version)
      end.max

      version_to_uninstall = PatchVersion.new(@patch_name, @version)

      if version_to_uninstall < max_version_installed
        Clame.logger.warn "Version #{max_version_installed.version} " +
          "of patch #@patch_name is installed"

        raise HigherPatchVersionInstalled.new(@patch_name,
                                              version_to_uninstall.version,
                                              max_version_installed.version,
                                              'uninstall')
      end
    end


  end

end
