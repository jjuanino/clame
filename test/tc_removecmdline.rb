# encoding: ISO-8859-15
# $Id$
# vim: set sts=2 sw=2 ai et:
#
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

require 'test/unit'

class TestRemoveCmdLine < Test::Unit::TestCase

  include Clame

  # Directorio actual
  PATH_CURRENT_DIR = Pathname.new(CURRENT_DIR)
  # El ejecutable clame
  CLAME_MAIN_BIN = PATH_CURRENT_DIR.parent.join('bin', 'clame')
  # El directorio base de los tests
  TEST_PATH_BASE = "#{PATH_CURRENT_DIR.parent}"


  def setup
    @tmpdir = Dir.mktmpdir

    # Generar el fichero de configuración
    File.open(File.join(@tmpdir, 'clamecfg.rb'), 'w') do |cfg|
      cfg.puts <<EOF
require 'logger'

require 'clame'

module Clame

  CUSTOM_CONF_SETTINGS = ConfSettings[
    :log_file => "#{File.join(@tmpdir,'clame.log')}",
    :log_severity => Logger::DEBUG,
    # database options
    :database_path => "#{File.join(@tmpdir,'clame.db')}",
    :max_retries_db => 10,
    :sleep_time_db_lock => 1,
    # directorio donde se encuentra el esquema de la base de datos
    :deploy_schema_dir => "#{TEST_PATH_BASE}/datamodel/schema",
    # directorio donde se realizan los backups de los archivos sobreescritos en
    # la instalación de los parches, de modo que luego sea posible desinstalarlo
    :backup_dir_install => "#{TEST_PATH_BASE}/runtime/save",
  ]

end
EOF

    end

  end # def setup


  def teardown
    FileUtils.remove_entry_secure(@tmpdir)
  end

  def test_remove
    env = {'RUBYLIB' => LIB_CLAME_DIR,
           'CLAMECFG' => "#{File.join(@tmpdir,'clamecfg.rb')}"}
    cmd_build = [CLAME_MAIN_BIN.to_s, 'build', '-q']
    cmd_install = [CLAME_MAIN_BIN.to_s, 'install', '-q']
    cmd_remove = [CLAME_MAIN_BIN.to_s, 'remove']
    dir = PATH_CURRENT_DIR.join('tc_patchbuilder', 'foo_401').to_s
    zip_path = File.join(@tmpdir, 'foo_401.zip')

    # Construir un paquete zip con un simple parche foo 4.0.1
    fork{exec(env, *(cmd_build), dir, zip_path)}
    Process.wait
    assert $?.exited? && $?.exitstatus.zero?,
      'Error al construir el paquete foo_401.zip'

    bad_cmds = [
      cmd_remove + %w(-k),
      cmd_remove + %w(-r arg -a),
      cmd_remove + %w(-a arg -u),
      cmd_remove + %w(-v arg -r),
      cmd_remove + %w(-rvauz),
      cmd_remove + %w(-irvau),
    ]

    bad_cmds.each do |bad_cmd|
      fork{exec(env, *bad_cmd, :err => File::NULL)}
      Process.wait
      assert ($?.exited? && $?.exitstatus==FAILURE),
        "Código de salida incorrecto: #{$?}: #{bad_cmd}"
    end

    good_flags = [
      %w(-r),
      %w(-v),
      %w(-u),
      %w(-rvau),
      %w(-h),
    ]

    good_flags.each do |good_flag|
      # Instalamos el parche, para poder desinstalarlo
      fork{exec(env, *(cmd_install), zip_path, 'foo', '4.0.1')}
      Process.wait

      fork do
        exec(env, *(cmd_remove), *(good_flag), 'foo', '4.0.1', :out => File::NULL)
      end
      Process.wait

      assert ($?.exited? && $?.exitstatus.zero?),
        "Código de salida incorrecto: #{$?}: #{good_flag}"
    end

  end # def test_remove



end # class TestRemoveCmdLine

