# -*- coding: ISO-8859-15 -*-
#--
# vim: set sts=2 sw=2 ai et:
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

require 'pathname'

module Clame

  #
  # Clase que permite realizar un backup de todos los ficheros sobreescritos
  # por la instalación de un parche
  #
  # ignored_paths es un array de rutas que se ignorarán en el proceso de
  # backup
  class BackupPatch

    # Si un archivo de backup tiene la forma
    # 89a9cb0416968e04d7c81c3d7ad918c6f71241f7423cc6e5c818299ff64ee381
    # (por ejemplo)
    # entonces se copia a
    # 89a/89a9cb0416968e04d7c81c3d7ad918c6f71241f7423cc6e5c818299ff64ee381
    # LENGTH_BACKUP_DIR indica la longitud del la cadena "89a"
    LENGTH_BACKUP_DIR = 3

    attr_reader :ignored_paths, :info_installed_paths
    def initialize(core, basedir, ignored_paths)
      @core = core
      @basedir = basedir
      @ignored_paths = ignored_paths
      # transformamos cada ruta de ignored_paths en una ruta absoluta
      @ignored_paths.collect!{|path| File.absolute_path(path, @basedir)}
      # info_installed_paths es un array. Cada elemento del array es un hash
      # que contiene información sobre una ruta actualmente instalada e
      # información sobre la ruta a instalar. De esta manera tenemos la
      # información actual y la que se escribirá como resultado de la
      # instalación de este parche.
      @info_installed_paths = get_info_installed_paths
    end


    # Realiza el backup. No devuelve nada
    def make
      # Copiar los archivos que van a ser modificados al directorio de backup
      regfiles_changed.each do |info|
        #new, actual = info[:new], info[:actual]
        digest = info[:actual][:digest]

        backup_dir = CONF_SETTINGS[:backup_dir_install]
        orig = File.absolute_path(info[:new].destination,@basedir)
        dest_prefix = digest[0, LENGTH_BACKUP_DIR]
        dest = File.join(backup_dir, dest_prefix, digest)
        Dir.mkdir(File.join(backup_dir, dest_prefix)) rescue Errno::EEXIST
        Clame.logger.info "Doing backup: #{orig} -> #{dest}"

        Clame.puts_task(
          "Back up (#{orig})"
        ) do |msg_end|
          unless File.exist?(dest)
            FileUtils.copy(orig, dest)
            msg_end << \
              ". #{(File.stat(orig).blocks * Clame::BLOCK_SIZE).to_kib} KiB"
          else
            msg_end.replace "Not needed: backup already exists"
          end
        end

      end # regfiles.changed.each

    end # def make


    # Registra en la base de datos un marshal del objeto actual BackupPatch y
    # rellena la tabla backed_up_files
    def register
      patch_name = @core.info.patch_name
      patch_version = @core.info.patch_version
      Clame.database.set_backup_info(patch_name, patch_version, self, @basedir)
    end


    # Los procedimientos de marshal tienen que ser públicos
    def marshal_dump
      [@core, @basedir, @ignored_paths, @info_installed_paths]
    end


    def marshal_load(array)
      @core, @basedir, @ignored_paths, @info_installed_paths = array
    end


    # Comprobar si existe espacio suficiente para hacer un backup de los
    # archivos que ya existen, a excepción de los indicados en ignored_paths,
    # que no se realizará backup (pueden existir casos donde realmente no se
    # necesite hacer backup de algunos archivos que sobreescribe la
    # instalación, de ahí el sentido de ignored_paths)
    def check_room
      # El directorio donde se realizan los backups
      backup_fs = Sys::Filesystem.mount_point(
        CONF_SETTINGS[:backup_dir_install]
      )

      # Recuperamos todos los archivos regulares de los que sea necesario hacer
      # backup, y estimamos su tamaño.
      blocks_required = regfiles_changed.collect do |info|
        schemaitem = info[:new]
        # nos quedamos con las rutas de instalación absolutas e ignoramos las
        # rutas expresamente ignoradas
        File.absolute_path(schemaitem.destination, @basedir)
      end.to_set.subtract(@ignored_paths).collect do |path|
        # File::Stat.blocks es el número de bloques de tamaño 512b.
        File.lstat(path).blocks
        # sumamos todo
      end.inject(0,:+)

      # pasamos a bytes, y luego a KiB
      kib_required = (blocks_required * Clame::BLOCK_SIZE).to_kib

      if kib_required <= Fs.free_space[backup_fs]
        # devolvemos un hash con el espacio necesitado y el libre
        {:fs => backup_fs, :kib_free => Fs.free_space[backup_fs],
          :kib_required => kib_required}
      else
        raise NotEnoughFsFreeSpace.new([[backup_fs, kib_required]])
      end

    end


    # Un array con los objetos info que cumplen las siguientes condiciones:
    # 1- El archivo a instalar ya existe y es un archivo regular
    # 2- No está en la lista de ignorados
    # 3- El atributo nobackup no está activado
    # 4- El archivo a instalar no es un archivo regular o, en caso de serlo,
    #    tiene distinto contenido al actualmente instalado
    def regfiles_changed
      @info_installed_paths.find_all do |info|
        if info[:actual] && info[:actual][:stat].ftype == FileType::REGFILE
          # El origen y el destino tienen distinto digest, siendo el origen
          # también un archivo regular (si no lo es, el objeto también es
          # seleccionado)
          ( info[:new].filetype != FileType::REGFILE ) ||
          ( info[:actual][:digest] != info[:new].digest && !info[:new].nobackup )
        end
      end
    end


    # Un array con los schemaitems que cumplen las siguientes condiciones:
    # 1- El destino a instalar existe
    # 2- El fichero existente no es un enlace simbólico
    # 3- El tipo de fichero a instalar es del mismo tipo que el existente,
    #    teniendo en cuenta que un archivo ya instalado de tipo hardlink no se
    #    detecta como tal, sino como un fichero regular
    # 4- Sólo cambian alguno de los metadatos (permisos, propietario o grupo)
    # 5- No cambia el contenido en caso de ser un fichero regular
    def changed_attributes

      @info_installed_paths.find_all do |info|
        # El destino a instalar existe
        info[:actual]
      end.find_all do |info|
        filetype_act = info[:actual][:stat].ftype
        filetype_new = info[:new].filetype

        # No es un enlace simbólico y el fichero a instalar es del mismo tipo
        # que el existente, con el caso especial de hardlink
        if filetype_act == FileType::SYMLINK
          false
        else
          if filetype_new != FileType::HARDLINK
            filetype_act == filetype_new
          else
            # Es un hardlink, así que el fichero a ser instalado
            # o bien tiene que ser un fichero regular o un hardlink
            [FileType::HARDLINK, FileType::REGFILE].include?(filetype_new)
          end
        end
      end.find_all do |info|
        item = info[:new]
        stat_act = info[:actual][:stat]

        perms_new = item.perms
        owner_new = item.userowner
        grp_new = item.grpowner

        # Solo nos interesan las últimos 4 posiciones del campo mode.
        perms_act = stat_act.mode
        owner_act = Etc.getpwuid(stat_act.uid)[:name]
        grp_act = Etc.getgrgid(stat_act.gid)[:name]

        # ¿Cambia algún permiso, propietario o grupo?
        perms_new != perms_act || owner_new != owner_act || grp_new != grp_act
      end.find_all do |info|
        # No cambia el contenido en caso de ser un archivo regular
        if info[:new].filetype == FileType::REGFILE
          info[:actual][:digest] == info[:new].digest
        else
          true
        end
      end

    end


    private
    # Recorre la totalidad de objetos que se instalan en el schema, y para cada
    # uno determina el objeto que hay actualmente instalado, si existe. En ese
    # caso se extrae por un lado el objeto stat instalado y el digest (esto
    # último sólo si se trata de un archivo regular), y por otro lado el
    # schemaitem a instalar. Los archivos de ignored_paths no se tienen en
    # cuenta
    def get_info_installed_paths

      @core.schema.reject do |schemaitem|
        # Ignoramos todos los archivos señalados en @ignored_paths
        @ignored_paths.include?(File.absolute_path(schemaitem.destination,
                                                   @basedir))
      end.collect do |schemaitem|
        # Establecemos el permiso, usuario y grupo con el que se instalará este
        # archivo
        defaultsinstall =
          if schemaitem.filetype == FileType::DIRECTORY
            @core.schema.dirdefaults
          else
            @core.schema.notdirdefaults
          end

        schemaitem.inst_owner!(defaultsinstall)
        schemaitem.inst_grp!(defaultsinstall)
        schemaitem.inst_perm!(defaultsinstall)

        # En estos momentos sabemos con exactitud bajo qué usuario, grupo y
        # permiso se instalará el archivo, y en qué ruta
        inst_path = File.absolute_path(schemaitem.destination, @basedir)

        # Comprobamos si el elemento a instalar existe, y calculamos el objeto
        # stat. Si además se trata de un archivo regular, extraemos el digest.
        # Si es un enlace simbólico, recuperamos el destino.
        # Si el elemento a instalar no existe, los tres componentes se
        # establecen a nil
        stat, digest, link_dest =
          if File.exist?(inst_path)
            [
              File.lstat(inst_path),
              # ¿Es un archivo regular? Calculamos su digest
              if File.file?(inst_path)
                Digest::SHA256.file(inst_path).hexdigest
              end,
              # Si es un enlace simbólico, calculamos el destino
              if File.lstat(inst_path).symlink?
                File.readlink(inst_path)
              end,
            ]
          end
        # Retorno. El primer componente apunta al actual archivo instalado.
        # El segundo componente apunta al archivo que se instalará
        # Observar que no almacenamos el objeto File::Stat, sino el
        # Clame::Stat (a través del método pstat).
        # Si se trata de un enlace simbólico, se incluye el destino
        # Si stat es nil, significa que el archivo a instalar no existe,
        # y el hash de salida solo mantiene el componente :new (el primero
        # sería nil).
        {
          :actual =>
            stat && {
              :stat => stat.to_pstat,
              :digest => digest,
              :link_dest => link_dest,
            },
          :new => schemaitem,
        }
      end

    end
  end

end
