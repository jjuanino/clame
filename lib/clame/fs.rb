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

require 'sys/filesystem'

module Clame

  # Clase que encapsula los sistemas de ficheros de un cierto host
  class Fs

    private_class_method :new

    def self.get_mounted_fs
      @@mounted_fs = Sys::Filesystem.mounts.collect do |mount|
        mount.mount_point
      end.sort_by{|m| m.split(File::SEPARATOR).size}.reverse
    end


    # Los filesystem montados en el sistema, ordenados por profundidad
    # Por ejemplo: ['/usr/local', '/usr', /var', '/']
    # Es necesario para determinar en qué file system se instalará
    # un cierto archivo de un parche.
    # Esta llamada inicializa @@mounted_fs
    self.get_mounted_fs

    @@free_space = {}

    def self.mounted_fs
      @@mounted_fs
    end

    def self.free_space
      @@free_space
    end

    # Espacio libre en cada filesystem, dispuesto en un hash, medido en KiB,
    # redondeado a la baja. Ojo, que Sys::Filesystem.stat(fs).blocks_available
    # mide bloques del sistema de ficheros, y cada uno tiene un tamaño de
    # Sys::Filesystem.stat(fs).fragment_size bytes
    def self.compute_free_space_per_fs
      # inicializamos el hash
      @@mounted_fs.each do |fs|
        @@free_space[fs] =
          (Sys::Filesystem.stat(fs).blocks_available *
            Sys::Filesystem.stat(fs).fragment_size).to_kib
      end

      @@free_space

    end

    # para facilitar los test, se permite establecer los fs
    # del sistema y su espacio libre
    def self.free_space=(new)
      @@free_space = new
    end

    def self.mounted_fs=(new)
      @@mounted_fs = new
    end

  end

end
