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

module Clame

  class Schema

    include Enumerable

    # regular expressions frequenty used in parse lines
    RE_PERM = '\d{3,4}' # 0755 0644 1755 755
    RE_OWNER = "(#{RE_NAME}):(#{RE_NAME})" # oracle:dba root:wheel

    attr_reader :variables, :notdirdefaults, :dirdefaults, :directories,
                :regfiles, :pipes, :symlinks, :hardlinks

    def initialize(io_stream, infovars={})

      @variables = infovars.dup
      @notdirdefaults = nil
      @dirdefaults = nil
      @directories = []
      @regfiles = []
      @pipes = []
      @symlinks = []
      @hardlinks = []

      io_stream.each_line do |line|
        parse(line, io_stream.lineno) unless line =~ IGNORED_LINES
      end

      # comprobamos si hay destinos duplicados
      Clame.check_dup_iterator(each_destination, DuplicateDestination)

    end

    #
    # Iteración sobre cada objeto instalable del schema
    #
    def each(&block)
      (@directories + @regfiles + @pipes + @symlinks + @hardlinks).each(&block)
    end

    # Interación sobre cada archivo destino
    def each_destination
      return to_enum(:each_destination) unless block_given?
      self.each{|p| yield p.destination}
    end



    private
    def parse(line, lineno)

      line.chomp!

      # Expandir las variables en curso, salvo que estemos en la asignación de
      # una variable, en cuyo caso la expansión se realizará en segunda parte
      # de la asignación
      line.expand!(@variables) unless line =~ RE_VAR_LINE

      case line
      # upper case is required
      # VARNAME = "VARVALUE"
      when RE_VAR_LINE
        # expandir solo parte de la asignación (nunca el nombre de la variable)
        varname, varvalue = $1, $2.expand(@variables)
        @variables[varname] = varvalue
      # notdirdefaults 0644 oracle:dba
      when /\Anotdirdefaults\s+(#{RE_PERM})\s+#{RE_OWNER}\s*\Z/
        defperms = $1
        defuserowner, defgrpowner = $2, $3

        # No se admiten dos notdirdefaults
        unless @notdirdefaults.nil?
          raise SyntaxError::DuplicateNotDirDefaults.new(line, lineno)
        end

        @notdirdefaults = NotDirDefaults.new(defperms,
                                             defuserowner,
                                             defgrpowner)
      # dirdefaults 0755 oracle:dba
      when /\Adirdefaults\s+(#{RE_PERM})\s+#{RE_OWNER}\s*\Z/
        defperms = $1
        defuserowner, defgrpowner = $2, $3

        # No se admiten dos dirdefaults
        unless @dirdefaults.nil?
          raise SyntaxError::DuplicateDirDefaults.new(line, lineno)
        end

        @dirdefaults = DirDefaults.new(defperms, defuserowner, defgrpowner)
      # Directory
      # d perm owner:group dirname
      when /\Ad((?:\s+)(#{RE_PERM}))?((?:\s+)#{RE_OWNER})?\s+(.+)\Z/
        perms = $2
        userowner, grpowner = $4, $5
        dirname = $6
        @directories << DirSchemaItem.new(dirname, userowner, grpowner, perms)
      # regular file
      # f! perm owner:group destination=origin
      when /\Af(!)?((?:\s+)(#{RE_PERM}))?((?:\s+)#{RE_OWNER})?\s+(.+)\Z/
        # nobackup es false o true, nunca nil.
        # También valdría nobackup = !!$1 (doble negación)
        nobackup = false^$1
        perms = $3
        userowner, grpowner = $5, $6
        # rompemos la cadena por el *primer* caracter =, a no ser que venga
        # escapado
        split_str = $7.split(/(?<!\\)=/)
        # colapsar la barra simple que precede a un =
        filedest = split_str[0].gsub(/\\(?==)/, '')
        fileorigin = split_str[1..-1].join

        # si no se ha especificado fileorigin, significa que
        # filedest=BASECLAME+filedest. Por el contrario, si se ha especicifado
        # fileorigin, pero no es una ruta absoluta, significa que
        # filedest=BASECLAME+fileorigin
        fileorigin =
          if fileorigin.length.zero?
            File.join(@variables[Info::BASECLAME] ,filedest)
          else
            if File.absolute_path(fileorigin) != fileorigin
              # path relativo
              File.join(@variables[Info::BASECLAME], fileorigin)
            end
          end

        @regfiles << RegFileSchemaItem.new(
          filedest, fileorigin, nobackup, userowner, grpowner, perms
        )
      # pipe
      # p! perms owner:group pipefile
      when /\Ap(!)?((?:\s+)(#{RE_PERM}))?((?:\s+)#{RE_OWNER})?\s+(.+)\Z/
        nobackup = false^$1
        perms = $3
        userowner, grpowner = $5, $6
        filedest = $7
        @pipes << PipeSchemaItem.new(filedest, nobackup, userowner,
                                     grpowner, perms)
      # symlink
      # s! dest=orig
      when /\As(!)?\s+(.+)\Z/
        nobackup = false^$1
        split_str = $2.split(/(?<!\\)=/)
        # colapsar la barra simple que precede a un =
        symlinkname = split_str[0].gsub(/\\(?==)/, '')
        destination = split_str[1..-1].join
        destination = nil if destination.length.zero?
        @symlinks << SymLinkSchemaItem.new(symlinkname, destination, nobackup)
      # hardlink
      # h! dest=orig
      when /\Ah(!)?\s+(.+)\Z/
        nobackup = false^$1
        split_str = $2.split(/(?<!\\)=/)
        # colapsar la barra simple que precede a un =
        hardlinkname = split_str[0].gsub(/\\(?==)/, '')
        destination = split_str[1..-1].join
        destination = nil if destination.length.zero?
        @hardlinks << HardLinkSchemaItem.new(hardlinkname, destination, nobackup)
      else
        # syntax error
        raise SyntaxError::InvalidLineFormat.new('schema', line, lineno)
      end

    rescue InvalidFileType
      raise SyntaxError::InvalidFileType.new($!.filetype, line, lineno)
    rescue InvalidMaskPerm
      raise SyntaxError::InvalidMaskPerm.new($!.mask, line, lineno)
    rescue SymLinkDestNil
      raise SyntaxError::SymLinkDestNil.new(line, lineno)
    rescue HardLinkDestNil
      raise SyntaxError::HardLinkDestNil.new(line, lineno)
    rescue PathNotNormalized
      raise SyntaxError::PathNotNormalized.new($!.path, line, lineno)
    end

  end

end
