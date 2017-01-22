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

  class InstallCmdLine < ActionCmdLine

    # Itera sobre la totalidad de parches/versiones indicados en la línea de
    # comandos
    include Enumerable

    def initialize(options, args)
      super
      # Los argumentos enviados
      @zip_path, @patch_name, @version = @args

      # Si indican patch_name y version expresamente en la línea de comandos,
      # lo indicamos en la opción :explicity_pv
      # línea de comandos
      @options[:explicity_pv] = true if (@patch_name && @version)
    end # def initialize


    def run

      Clame.quiet = @options[:quiet]

      # Si no se indica un parche&versión específico en la línea de
      # comandos, escribimos por el terminal la lista de parches a instalar.
      # Si la flag :quiet está activa, no tiene sentido ejecutar este bloque,
      # así que también se omitiría
      unless @options[:explicity_pv] || @options[:quiet]
        Clame.puts_info "The following patches & versions will be installed:"
        each{|p,v| Clame.print "\tPatch name: (#{p}), Version: (#{v})\n"}
        Clame.ask_yes_no if @options[:prompt]
      end

      # Iteramos sobre cada parche enumerado en la línea de comandos, y
      # procedemos con la instalación
      each do |patch_name, version|

        Clame.puts_info "Installing (#{patch_name}), version (#{version}) " +
          "contained in (#{@zip_path})"

        packaged_patch = PackagedPatch.new(
          @zip_path, patch_name, version, @options
        )

        # se realizan validaciones previas a menos que se especifique la flag
        # -f
        unless @options[:force]
          packaged_patch.check_install
          # preguntamos si se desea continuar
          Clame.ask_yes_no if @options[:prompt]
        end

        # Instalación del parche
        packaged_patch.install

        Clame.puts_info "(#{patch_name}) patch, (#{version}) " +
          "version has been successfully installed\n"

      end

    end # def run


    # Iterar sobre todos los parches indicados en la línea de comandos
    def each
      return to_enum(:each) unless block_given?

      if @patch_name && @version
        # Indican patch_name y version. Los entregamos directamente
        yield @patch_name, @version
      elsif @patch_name
        # Indican patch_name pero no version. Recuperamos todas las versiones
        # del parche patch_name contenidas en el zip, pero antes comprobamos
        # que al menos hay alguno (es decir, que en la línea de comandos han
        # indicado un patch_name válido)
        if PatchesContainer.new(@zip_path).none?{|p,v| p == @patch_name}
          raise PatchNameNotExistInZip.new(@patch_name, @zip_path)
        end

        PatchesContainer.new(@zip_path).each do |p,v|
          yield p,v if p == @patch_name
        end
      else
        # No indican patch_name ni version. Recuperar todas las versiones de
        # todos los parches contenidos en el zip
        PatchesContainer.new(@zip_path).each{|p,v| yield p,v}
      end

    end # def each



  end # class InstallCmdLine

end # module Clame

