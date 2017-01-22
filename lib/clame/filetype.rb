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

  class FileType

    private_class_method :new

    FILETYPES = {
      # directorio
      :d => 'd',
      # fichero regular
      :f => 'f',
      # pipe (o fifo)
      :p => 'p',
      # symlink
      :s => 's',
      # hardlink. Observar que no hay objeto File::Stat.ftype asociado,
      # a diferencia del symlink
      :h => 'h',
    }
    # equivalencia entre FILETYPES y File::Stat.ftype
    FILETYPE_STAT = {
      :d => 'directory',
      :f => 'file',
      :p => 'fifo',
      # symlink, NOT hardlink. Hardlink does not exist as valid file type
      :s => 'link',
    }

    DIRECTORY = FILETYPES[:d]
    REGFILE = FILETYPES[:f]
    PIPE = FILETYPES[:p]
    SYMLINK = FILETYPES[:s]
    HARDLINK = FILETYPES[:h]


  end
end
