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

require 'digest'
require 'zip'


module Clame

# Objeto que representa un parche que puede ser construido. El constructor
# simplemente necesita un directorio donde resida el parche


  class PatchBuilder

    # Estructura básica del zip que se construye en esta clase:
    # install/
    # patches/
    #   patchname/
    #      version/
    #         corefile
    #         contents
    INSTALL_DIR = 'install'
    CORE_FILE = 'corefile'
    CONTENTS_FILE = 'contents'
    BASE_PATCHES = 'patches'

    # El constructor del objeto. Solo se inicializan la ruta donde se encuentra
    # el fuente del parche (@patchdir) y el core del mismo (@core). La
    # construcción del zip se realiza en el método privado de instancia build,
    # que se invoca a través del método de clase build
    def initialize(patchdir, options={})
      @options = options
      initial_vars = @options[:variables] || {}

      Clame.puts_check "syntax in (#{patchdir}) directory" do
        @patchdir = patchdir.to_s
        File.directory?(@patchdir) or raise DirectoryNotExist.new(@patchdir)

        @core = Core.new(patchdir, initial_vars)
      end

      Clame.puts_info "Building patch (#{@core.info.patch_name}), version " +
          "(#{@core.info.patch_version})"

    end

    # Este procedimiento devuelve un array con los hash del contents de cada
    # parche. Se trata de un procedimiento de clase, que invoca repetidamente al
    # procedimiento de instancia por cada parche.
    # patchdirs es un array de rutas donde existen parches a ser construidos.
    def self.build(patchdirs, zip_path, options={quiet: true})

      # El archivo zip_path no puede existir
      raise PatchZipFileExists.new(zip_path) if File.exist?(zip_path)

      patchdirs.collect do |patchdir|
        begin
          self.new(patchdir, options).build(zip_path)
        rescue
          # En caso de error, eliminamos el zip construido.
          FileUtils.rm(zip_path) if File.exist?(zip_path)
          raise
        end
      end

    end


    # Construye el parche.
    # Cada archivo regular mencionado en el schema debe estar en su sitio. En
    # caso afirmativo, se copia al zip de instalación
    # zip_path -> El archivo zip donde se construirá el parche
    def build(zip_path)

      # comprobaciones previas para determinar si es posible construir el
      # parche
      check_build

      # La variable contents fichero de texto plano que guarda el contenido del
      # parche en el siguiente formato:
      #
      # patches/patchname/version/corefile            sha256Digest
      # patches/patchname/version/contents            sha256Digest
      # install/sha256_1
      # install/sha256_2
      # ................
      # install/sha256_N
      contents = []

      Dir.chdir(@patchdir) do

        Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|

          # Recorremos todos los archivos regulares indicados en el schema, y
          # los incluimos en el zip, dentro de la carpeta INSTALL_DIR. El
          # método add_to_zip! devuelve el digest del archivo añadido
          @core.schema.regfiles.each do |regfile|

            unless FileTest.file?(regfile.origin)
              raise OriginNotValid.new(regfile.origin)
            end

            orig = File.realpath(regfile.origin)
            size = File.stat(orig).size.to_kib

            # después de esta llamada, origin ya no es un atributo válido
            Clame.puts_task("Add (#{orig})", "Done: #{size} KiB") do
              file_digest = regfile.add_to_zip!(INSTALL_DIR, zip_file)
              contents << File.join(INSTALL_DIR, file_digest)
            end

          end

          # llevamos el archivo legal a INSTALL_DIR dentro del zip si existe
          if @core.legal
            legal_dest = File.join(INSTALL_DIR, @core.legal)

            Clame.puts_task(
              "Add (legal)", "Done: #{@core.legal.size.to_kib} KiB"
            ) do
              zip_file.get_output_stream(legal_dest) do |f|
                IO.copy_stream(Core::LEGAL, f)
              end
            end

            contents << legal_dest

          end

          # llevamos los scripts_install a INSTALL_DIR dentro del zip
          @core.scripts_install.each_pair do |script_file, script_digest|
            script_dest = File.join(INSTALL_DIR, script_digest)

            Clame.puts_task(
              "Add (#{script_file})",
              "Done: #{File.stat(script_file).size.to_kib} KiB"
            ) do
              zip_file.get_output_stream(script_dest) do |f|
                IO.copy_stream(script_file, f)
              end
            end

            contents << script_dest

          end

          # llevamos los extra_files a INSTALL_DIR dentro del zip
          @core.extra_files.each_pair do |extra_file, extra_file_digest|
            extra_file_dest = File.join(INSTALL_DIR, extra_file_digest)

            Clame.puts_task("Add (#{extra_file})",
              "Done: #{File.stat(extra_file).size.to_kib} KiB"
            ) do
              zip_file.get_output_stream(extra_file_dest) do |f|
                IO.copy_stream(extra_file, f)
              end
            end

            contents << extra_file_dest

          end

          # Ejecutar los marshaling al corefile
          core_file = File.join(
            BASE_PATCHES, @core.info.patch_name,
            @core.info.patch_version, CORE_FILE
          )


          # Antes de escribir el core en el zip, eliminamos las variables del
          # info que no son necesarias para la fase de instalación (por ejemplo,
          # BASECLAME)
          @core.info.cleanout_vars
          Clame.puts_task("Add (#{CORE_FILE})") do |msg_end|
            zip_file.get_output_stream(core_file) do |f|
              mrs = Marshal.dump(@core)
              f.write mrs
              contents << [core_file, Digest::SHA256.hexdigest(mrs)].join("\t")
              msg_end.replace("Done: #{mrs.size.to_kib} KiB")
            end
          end

          # ordenamos el contents
          contents.sort!
          # convertimos a un string, sin olvidar poner el retorno de carro a la
          # última línea, porque en definitiva el contents va a ser un fichero
          # de texto plano
          contents = contents.join("\n") + "\n"

          # Añadir el contents al zip
          Clame.puts_task(
            "Add (#{CONTENTS_FILE})",
            "Done: #{contents.size.to_kib} KiB"
          ) do
            contents_file = File.join(
              BASE_PATCHES, @core.info.patch_name,
              @core.info.patch_version, CONTENTS_FILE
            )
            zip_file.get_output_stream(contents_file){|f| f.write contents}
          end


        end # Zip::File.open

      end # Dir.chdir

      Clame.puts_info "Patch (#{@core.info.patch_name}), " +
        "version (#{@core.info.patch_version}) successfully added " +
        "to (#{zip_path})\n\n"


      # Retorno: el digest del archivo contents, que unívocamente representa
      # este parche
      Digest::SHA256.hexdigest(contents)

    end



    private

    def check_build
      Clame.puts_check "relative paths" do |msg_end|
        # comprueba si hay alguna ruta relativa indicada en el schema. En ese
        # caso, se tiene que señalar la variable PREFIX en el info
        unless @core.info.each_varname.include?('PREFIX')
          relative_paths = @core.schema.each_destination.find_all do |f|
            f !~ /\A#{File::SEPARATOR}/
          end

          unless relative_paths.empty?
            unless @options[:ignore_miss_prefix]
              raise SchemaRelativePaths.new(relative_paths)
            else
              msg_end.replace 'Failed (but ignored by user)'
            end
          end
        end
      end

      # comprueba si prefix es una ruta absoluta, en caso de que se haya
      # indicado
      if (prefix = @core.info['PREFIX'])
        Clame.puts_check "(#{prefix}) is an absolute path" do
          if File.absolute_path(prefix, File::SEPARATOR) != prefix
            raise PrefixNotAbsolutePath.new(
              File.absolute_path(prefix, File::SEPARATOR),
              prefix
            )
          end
        end
      end

    end # def check_build

  end # class PatchBuilder

end # module Clame
