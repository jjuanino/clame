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


  class Core

    COREFILES = {
      :sch => 'schema',
      :inf => 'info',
      :inp => 'input',
      :dep => 'depend',
      :leg => 'legal',
    }
    SCHEMA = COREFILES[:sch]
    INFO = COREFILES[:inf]
    INPUT = COREFILES[:inp]
    DEPEND = COREFILES[:dep]
    LEGAL = COREFILES[:leg]


    PATCHSCRIPTS = {
      :che => 'checkinstall',
      :pre => 'preinstall',
      :pin => 'postinstall',
      :prr => 'preremove',
      :pos => 'postremove',
    }
    CHECKINSTALL = PATCHSCRIPTS[:che]
    PREINSTALL = PATCHSCRIPTS[:pre]
    POSTINSTALL = PATCHSCRIPTS[:pin]
    PREREMOVE = PATCHSCRIPTS[:prr]
    POSTREMOVE = PATCHSCRIPTS[:pos]


    EXTRA_FILES = {
      :readme => 'README',
      :readme_html => 'README.html',
    }
    README = EXTRA_FILES[:readme]
    README_HTML = EXTRA_FILES[:readme_html]


    attr_reader :info, :schema, :depend, :input, :legal, :scripts_install,
      :extra_files

    def initialize(patchdir, initial_vars={})
      File.directory?(patchdir) or raise DirectoryNotExist.new(@patchdir)

      Dir.chdir(patchdir) do
        @info = set_info(initial_vars)
        @schema = set_schema
        @depend = set_depend
        @input = set_input
        # el digest del archivo legal, si existe
        @legal = set_legal
        set_scripts # set @scripts_install
        set_extra_files # set @extra_files
      end

    end


    private
    def set_info(initial_vars)

      File.open(INFO){|info_io| Info.new(info_io, initial_vars)}

    rescue Errno::ENOENT
      raise FileNotExist.new(File.join(Dir.pwd,INFO))
    end



    def set_schema

      File.open(SCHEMA) do |schema_io|
        Schema.new(schema_io, @info.to_hash)
      end

    rescue Errno::ENOENT
      raise FileNotExist.new(File.join(Dir.pwd,SCHEMA))
    end


    def set_depend

      File.open(DEPEND) do |depend_io|
        Depend.new(depend_io)
      end

    rescue Errno::ENOENT
    end


    def set_input
      File.open(INPUT) do |input_io|
        Input.new(input_io)
      end

    rescue Errno::ENOENT
    end

    def set_legal
      # devuelve el sha256 si existe el archivo legal
      Digest::SHA256.file(LEGAL).hexdigest if FileTest.exist?(LEGAL)
    end

    def set_scripts
      # encontramos todos los scripts que existan, y los incluimos
      # en un hash, donde escribimos el digest
      @scripts_install = {}
      PATCHSCRIPTS.each_value do |script|
        if FileTest.exist?(script) && !FileTest.zero?(script)
          @scripts_install[script] = Digest::SHA256.file(script).hexdigest
        end
      end
    end

    def set_extra_files
      # encontramos todos los extra_files que existan, y los incluimos en un
      # hash, donde escribimos el digest
      @extra_files = {}
      EXTRA_FILES.each_value do |extra|
        if FileTest.exist?(extra) && !FileTest.zero?(extra)
          @extra_files[extra] = Digest::SHA256.file(extra).hexdigest
        end
      end
    end


    # Los procedimientos de marshal tienen que ser públicos
    def marshal_dump
      [@info, @schema, @depend, @input, @legal,
        @scripts_install, @extra_files]
    end

    def marshal_load(array)
      @info, @schema, @depend, @input, @legal,
        @scripts_install, @extra_files = array
    end

  end

end
