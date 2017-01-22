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

  # La finalidad de esta clase es recoger toda la información posible de la
  # clase File::Stat que sea útil para este proyecto. La clase File::Stat no
  # puede ser utilizada porque no es posible volcarla a un marshal (es una de
  # las limitaciones conocidas en ruby)

  class Stat

    attr_reader :mode, :uid, :gid, :atime, :mtime, :ctime, :ftype
    def initialize(mode, uid, gid, atime, mtime, ctime, ftype)
      # Solo nos interesan las últimas 4 posiciones de mode
      @mode = mode.to_s(8)[-4,4].oct
      @uid, @gid = uid, gid
      @atime, @mtime, @ctime = atime, mtime, ctime
      # ftype no conserva el valor de File::Stat, sino que el que se
      # corresponde con Clame::FileType
      @ftype = FileType::FILETYPES[FileType::FILETYPE_STAT.invert[ftype]]
    end
  end

end
