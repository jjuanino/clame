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

require 'sys/filesystem'
require 'zip'

module Clame

  # Un objeto PatchesContainer es un archivo zip resultado de la construcción
  # de uno o varios parches con la clase PatchBuilder. El objetivo es extraer
  # limpiamente los parches incluidos en él.
  class PatchesContainer < Zip::File

    # Enumerar todos los parches,versiones contenidos
    include Enumerable

    def initialize(zip_path)
      super(zip_path)
    rescue Zip::Error
      Clame.logger.error "Error opening (#{zip_path}): #$!"
      raise InvalidZipFile.new(zip_path)
    end


    # El nombre de los parches que contiene el zip, ordenados alfabéticamente,
    # ignorando duplicidades.
    def each_patch_names(&block)
      collect{|p,v| p}.sort.uniq(&block)
    end


    # Los parches y versiones que contiene el zip, en una matriz de N filas y 2
    # columnas. Cada fila representa un parche concreto.
    def each
      return to_enum(:each) unless block_given?

      pattern =  "#{PatchBuilder::BASE_PATCHES}#{File::SEPARATOR}*" +
        "#{File::SEPARATOR}*#{File::SEPARATOR}#{PatchBuilder::CONTENTS_FILE}"

      self.glob(pattern) do |entry|
        # nos quedamos con los dos primeros elementos de
        # patch_name/version/contents Al final, lo que sale es una matriz de N
        # filas y dos columnas
        if entry.name =~ /#{PatchBuilder::BASE_PATCHES}#{File::SEPARATOR}
          (#{RE_NAME})#{File::SEPARATOR}
          (#{RE_VERSION})#{File::SEPARATOR}#{PatchBuilder::CONTENTS_FILE}/x
          # el nombre de los archivos del zip vienen codificados en binario. Lo
          # pasamos al encoding ASCII
          yield [$1, $2].collect{|s| s.force_encoding(Encoding::US_ASCII)}
        end
      end

    end

  end

end
