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


require 'fileutils'

module Clame

  class FileSchemaItem

    attr_reader :filetype, :nobackup, :destination, :origin
    attr_accessor :userowner, :grpowner, :perms

    def initialize(filetype, nobackup, destination, origin,
                   userowner, grpowner, perms)

      @filetype = filetype
      @nobackup = nobackup
      @destination = destination
      @origin = origin
      @userowner = userowner
      @grpowner = grpowner
      @perms = perms

      # comprueba que el tipo de fichero está permitido. Debe ser uno de
      # FILETYPES
      check_filetype
      # Comprueba que los permisos de acceso sean correctos. Si no, se propaga
      # una excepción
      Clame.check_perms(@perms)
      # Comprueba que la ruta destino está normalizada
      check_normalized(destination)
      # Convierte @perms a un número. Se entiende que los permisos vienen en
      # octal
      @perms = Clame.canonic_perms(@perms)

    end

    # Un componente es igual a otro si y sólo si coinciden todos sus atributos
    def ==(other)
      self.instance_variables.all? do |i|
        self.instance_variable_get(i) == other.instance_variable_get(i)
      end
    end

    # métodos eql? y hash van unidos. Ver documentación de Object.hash
    # y Object.eql?
    def eql?(other)
      self == other
    end

    # el hash se define como el del array formado por todos los atributos
    # del objeto
    def hash
      self.instance_variables.collect{|i| self.instance_variable_get(i)}.hash
    end

    ## ¿La ruta destino es absoluta o relativa?
    def absolute?
      File.absolute_path(@destination) == @destination
    end


    # Determinar el usuario con el que se instalará el archivo. Si en el schema
    # no se indica usuario por defecto, se toma la máscara del proceso en curso
    def inst_owner!(defaults)
      @userowner ||= defaults.defuserowner rescue nil ||
        Etc.getpwuid(Process.euid).name
    end

    # Determinar el grupo con el que se instalará un archivo. Si en el schema
    # no se indica grupo por defecto, se toma la máscara del proceso en curso
    def inst_grp!(defaults)
      @grpowner ||= defaults.defgrpowner rescue nil ||
        Etc.getgrgid(Process.egid).name
    end

    # Los permisos de instalación de un schemaitem
    def inst_perm!(defaults)
      # Los permisos por defecto declarados en el schema
      @perms ||= defaults.defperms if defaults

      # Si todavía self.perms es nil, tomamos la máscara por defecto
      # del proceso actual
      unless @perms
        full_perms = (@filetype == FileType::DIRECTORY) ? 0o777 :  0o666
        @perms = full_perms ^ File.umask
      end

      @perms
    end


    # Establece los atributos mode, owner y group del objeto self,
    # y los devuelve en un array de 3 componentes: mode, owner, group
    def attr!(defaults)
      [inst_perm!(defaults), inst_owner!(defaults),
        inst_grp!(defaults)]
    end





    private
    # Comprueba destination es un nombre normalizado.
    # Por ejemplo dir/ no lo está
    def check_normalized(path)
      unless Pathname.new(path).cleanpath.to_path == path
        raise PathNotNormalized.new(path)
      end
    end


    # check if filetype is valid (registered in FILETYPES)
    def check_filetype
      unless FileType::FILETYPES.each_value.include?(@filetype)
        raise InvalidFileType.new(@filetype)
      end
    end

  end


  class DirSchemaItem < FileSchemaItem

    def initialize(dirname, userowner, grpowner, perms)
      super(FileType::DIRECTORY, nil, dirname, nil,
            userowner, grpowner, perms)
    end

  end


  class RegFileSchemaItem < FileSchemaItem

    attr_reader :digest
    def initialize(filedest, fileorig, nobackup, userowner, grpowner,
                   perms, digest=nil)

      super(FileType::REGFILE, nobackup, filedest, fileorig,
            userowner, grpowner, perms)

      @digest = nil

    end

    # En este procedimiento añadiamos un archivo regular a un zip previamente
    # creado.
    # Comprobamos que el archivo origen existe, y que es un archivo regular. En
    # caso afirmativo, se extrae hash sha256 del mismo y se añade al archivo
    # zip_file, dentro del directorio dest_dir.  Por último, se fija el sha256
    # del archivo al atributo digest. Se devuelve el hash calculado
    # El nombre del procedimiento lleva una admiración porque se altera el objeto,
    # ya que el miembro @origin se asigna a nil.
    def add_to_zip!(dir_dest, zip_file)


      # Tiene que ser un fichero regular.
      FileTest.file?(@origin) or raise OriginNotValid.new(@origin)

      sha256 = Digest::SHA256.file(@origin).hexdigest

      # El lugar donde se escribirá el archivo dentro del zip
      file_dest = File.join(dir_dest, sha256)
      # Trasladar origin al zip, pero en la ruta marcada por file_dest
      zip_file.get_output_stream(file_dest){|f| IO.copy_stream(@origin, f)}

      # En ese instante, una vez que hemos añadido el archivo al zip, ya no es
      # necesario conservar el origen, así que se fija a nil.
      @origin = nil

      # Retorno
      @digest = sha256

    end

  end


  class PipeSchemaItem < FileSchemaItem

    def initialize(pipename, nobackup, userowner, grpowner, perms)
      super(FileType::PIPE, nobackup, pipename, nil,
            userowner, grpowner, perms)
    end

  end

  class SymLinkSchemaItem < FileSchemaItem

    # OJO, que destination es el destino del enlace, no el destino de
    # instalación: eso último es realmente symlinkname.
    attr_reader :symlinkname
    def initialize(symlinkname, destination, nobackup)
      @symlinkname = symlinkname
      # destino no puede ser nil
      raise SymLinkDestNil.new if destination.nil?

      super(FileType::SYMLINK, nobackup, symlinkname, destination,
            nil, nil, '0777')
    end

  end

  class HardLinkSchemaItem < FileSchemaItem

    # OJO, que destination es el destino del hardlink, no el destino de
    # instalación: eso último es realmente hardlinkname.
    attr_reader :hardlinkname
    def initialize(hardlinkname, destination, nobackup)
      @hardlinkname = hardlinkname
      # destino no puede ser nil
      raise HardLinkDestNil.new if destination.nil?

      super(FileType::HARDLINK, nobackup, hardlinkname, destination,
            nil, nil, nil)
    end

  end

end
