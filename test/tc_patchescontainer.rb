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
require 'tmpdir'


class TestPatchesContainer < Test::Unit::TestCase

  include Clame

  PATH_CURRENT_DIR = Pathname.new(CURRENT_DIR)

  def setup
    @tmpdir = Dir.mktmpdir
    CONF_SETTINGS[:log_file] = File.join(@tmpdir, 'clame.log')
    CONF_SETTINGS[:baseclame] = 'BASEDIR'
    Factory.bootstrap_logger

    initial_vars = {'MYVAR' => 'MYVALUE'}

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: initial_vars, quiet: true}
                        )
    end

    @container = PatchesContainer.new(File.join(@tmpdir, 'bison_autoconf.zip'))

  end

  def teardown
    # esto es una ñapa para que se eliminen los archivos temporales que
    # permanecen después de construir el zip. A veces fallan los test por
    # esto
    GC.start
    FileUtils.remove_entry_secure(@tmpdir)
  end


  def test_each_patch_names
    assert_equal %w(bison autoconf).to_set, @container.each_patch_names.to_set
  end

  def test_each
    assert_equal [%w(bison 2.4.3), %w(autoconf 2.a.0)].to_set,
      @container.to_set
  end


  def test_invalid_zip_file
    # corrompemos el zip, y así no lo podemos abrir de nuevo
    IO.write(File.join(@tmpdir, 'bison_autoconf.zip'), '0')

    assert_raise(InvalidZipFile) do
      PatchesContainer.new(File.join(@tmpdir, 'bison_autoconf.zip'))
    end

  end


end
