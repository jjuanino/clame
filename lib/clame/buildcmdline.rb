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

  class BuildCmdLine < ActionCmdLine

    def initialize(options, args)
      super
    end # def initialize


    def run

      Clame.quiet = @options[:quiet]

      # Tenemos >=2 argumentos. El último es el zip de salida
      zip_path=@args.last

      # Los directorios donde se encuentran los parches
      patchdirs = @args[0..-2]

      if File.exist?(zip_path)
        if @options[:force]
          Clame.logger.warn "Remove <<#{zip_path}>>"
          File.delete zip_path
        else
          raise PatchZipFileExists.new(zip_path)
        end
      end

      # Enviamos la ruta absoluta a zip_path, para tener determinada con
      # exactitud la ruta
      PatchBuilder.build(patchdirs, File.absolute_path(zip_path), @options)

      Clame.puts_info "Created (#{zip_path}, " +
        "#{(File.stat(zip_path).blocks * Clame::BLOCK_SIZE).to_kib} KiB)"

    end # def run

  end # class BuildCmdLine

end # module Clame
