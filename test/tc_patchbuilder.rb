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
require 'digest'

class TestPatchBuilder < Test::Unit::TestCase

  include Clame

  PATH_CURRENT_DIR = Pathname.new(CURRENT_DIR)

  def setup
    @tempdir = Dir.mktmpdir
    Factory.bootstrap_conf
    CONF_SETTINGS[:log_file] = File.join(@tempdir, 'clame.log')
    CONF_SETTINGS[:database_path] = File.join(@tempdir, 'clame.db')
    CONF_SETTINGS[:backup_dir_install] = File.join(@tempdir, 'save')
    CONF_SETTINGS[:baseclame] = 'BASEDIR'
    Dir.mkdir(CONF_SETTINGS[:backup_dir_install])
    Factory.bootstrap_logger
    Factory.bootstrap_database
  end


  def teardown
    # esto es una ñapa para que se eliminen los archivos temporales que
    # permanecen después de construir el zip. A veces fallan los test por
    # esto
    GC.start
    FileUtils.remove_entry_secure(@tempdir)
    GC.start
  end

  def test_origin_not_valid
    Dir.chdir(File.join(PATH_CURRENT_DIR)) do
      zip_test = File.join(@tempdir, 'tee_96.zip')
      assert_raise(OriginNotValid) do
        PatchBuilder.new(
          'tc_patchbuilder/tee_96', {ignore_miss_prefix: true}
        ).build(zip_test)
      end
    end
  end


  def test_missing_prefix
    Dir.chdir(File.join(PATH_CURRENT_DIR)) do
      zip_test = File.join(@tempdir, 'tee_95.zip')
      assert_nothing_raised do
        PatchBuilder.new('tc_patchbuilder/tee_95',
                        {ignore_miss_prefix: true}).build(zip_test)
      end

      assert_raise(SchemaRelativePaths) do
        PatchBuilder.new('tc_patchbuilder/tee_95').build(zip_test)
      end

    end
  end


  def test_build_bison_1
    Dir.chdir(File.join(PATH_CURRENT_DIR)) do
      zip_test = File.join(@tempdir, 'test_build_bison_1.zip')
      hash_contents = PatchBuilder.build(['tc_patchbuilder/bison'], zip_test)

      expected = \
        case RUBY_VERSION
        when "2.1.5" then '01c34d027b307473720b1b94f1fe8ca5e9814a785a965db0816a557f1c901c30'
        when "2.2.6" then '6a405c7059e662e2d40caef7bf752258a2ab8e9277df05b86e644d201592e5b8'
        end

      assert_equal([expected], hash_contents)

      assert_equal(
        expected,
        Zip::File.open(zip_test) do |zipfile|
          zipfile.get_input_stream('patches/bison/2.4.3/contents') do |io|
            Digest::SHA256.hexdigest(io.read)
          end
        end
      )
    end
  end

  def test_build_bison_2
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      zip_test = File.join(@tempdir, 'test_build_bison_2.zip')
      hash_contents = PatchBuilder.new('bison').build(zip_test)

      expected = \
        case RUBY_VERSION
        when "2.1.5" then '01c34d027b307473720b1b94f1fe8ca5e9814a785a965db0816a557f1c901c30'
        when "2.2.6" then '6a405c7059e662e2d40caef7bf752258a2ab8e9277df05b86e644d201592e5b8'
        end

      assert_equal(expected, hash_contents)

      assert_equal(
        expected,
        Zip::File.open(zip_test) do |zipfile|
          zipfile.get_input_stream('patches/bison/2.4.3/contents') do |io|
            Digest::SHA256.hexdigest(io.read)
          end
        end
      )
    end
  end

  def test_build_bison_3
    Dir.chdir(File.join(PATH_CURRENT_DIR,'tc_patchbuilder','bison')) do
      zip_test = File.join(@tempdir, 'test_build_bison_3.zip')
      hash_contents = PatchBuilder.new('.').build(zip_test)

      expected = \
        case RUBY_VERSION
        when "2.1.5" then '01c34d027b307473720b1b94f1fe8ca5e9814a785a965db0816a557f1c901c30'
        when "2.2.6" then '6a405c7059e662e2d40caef7bf752258a2ab8e9277df05b86e644d201592e5b8'
        end

      assert_equal(expected, hash_contents)

      assert_equal(
        expected,
        Zip::File.open(zip_test) do |zipfile|
          zipfile.get_input_stream('patches/bison/2.4.3/contents') do |io|
            Digest::SHA256.hexdigest(io.read)
          end
        end
      )
    end
  end


  def test_build_autoconf_1
    Dir.chdir(File.join(PATH_CURRENT_DIR,'tc_patchbuilder','autoconf')) do
      zip_test = File.join(@tempdir, 'test_build_autoconf_1.zip')
      hash_contents = PatchBuilder.new('.').build(zip_test)

      expected = \
        case RUBY_VERSION
        when "2.2.6" then 'b530ebef46f6c32725ef9e613365bdaec9b14124d7bbc54dac71dc2188b61600'
        when "2.1.5" then 'e63c0274ec64395665a27ae23289f102a84cb12e3b74f6e502f51706096170e7'
        end

      assert_equal(expected, hash_contents)

      assert_equal(
        expected,
        Zip::File.open(zip_test) do |zipfile|
          zipfile.get_input_stream('patches/autoconf/2.a.0/contents') do |io|
            Digest::SHA256.hexdigest(io.read)
          end
        end
      )
    end

  end


  def test_build_autoconf_2
    Dir.chdir(File.join(PATH_CURRENT_DIR,'tc_patchbuilder')) do
      zip_test = File.join(@tempdir, 'test_build_autoconf_2.zip')
      hash_contents = PatchBuilder.new('autoconf').build(zip_test)

      expected = \
        case RUBY_VERSION
        when "2.2.6" then 'b530ebef46f6c32725ef9e613365bdaec9b14124d7bbc54dac71dc2188b61600'
        when "2.1.5" then 'e63c0274ec64395665a27ae23289f102a84cb12e3b74f6e502f51706096170e7'
        end

      assert_equal(expected, hash_contents)

      assert_equal(
        expected,
        Zip::File.open(zip_test) do |zipfile|
          zipfile.get_input_stream('patches/autoconf/2.a.0/contents') do |io|
            Digest::SHA256.hexdigest(io.read)
          end
        end
      )
    end

  end



  def test_bison_not_build
    test_zip = File.join(@tempdir, 'test_bison_not_build.zip')
    Dir.chdir(File.join(PATH_CURRENT_DIR,'tc_patchbuilder')) do
      assert_raise(SchemaRelativePaths) do
        PatchBuilder.new('bison_not_build').build(test_zip)
      end
      assert_raise(PrefixNotAbsolutePath) do
        PatchBuilder.new(
          'bison_not_build',
          {variables: {'PREFIX' => '/invalid/..'}}
        ).build(test_zip)
      end
      assert_raise(PrefixNotAbsolutePath) do
        PatchBuilder.new(
          'bison_not_build',
          {variables: {'PREFIX' => '/invalid/'}}
        ).build(test_zip)
      end
    end

  end

  def test_zip_file_exists
    test_zip = File.join(@tempdir, 'test_zip_file_exists.zip')
    assert_raise(PatchZipFileExists) do
      Dir.chdir(File.join(PATH_CURRENT_DIR)) do
        File.open(test_zip,'w'){}
        PatchBuilder.build(['tc_patchbuilder/bison'], test_zip)
      end
    end

  end


  def test_zip_global
    Dir.chdir(File.join(PATH_CURRENT_DIR,'tc_patchbuilder')) do
      zip_test = File.join(@tempdir, 'test_zip_global.zip')
      hash_contents = PatchBuilder.build(
        ['bison', 'autoconf'], zip_test,
        {variables: {'VARNAME' => 'Var value'}, quiet: true}
      )

      expected =
        case RUBY_VERSION
        when "2.2.6"
          ['09e42fe1a433eaa53e58a41bb7440f254145efd53dfa899167f9fed740c8fa3a',
            'c2dfb69d753038366dc8348976ec6f6fbc291b260c6d5348187e209d32265491']
        when "2.1.5"
          ['29550237062d2c1044cff75515a321760ea4090742a75573683b7617d863b99a',
            'e014454451b38f73cba7a8bc5d21b95fc8d1f4970e025aafe9c3ea0c4973901c']
        end

      assert_equal(expected, hash_contents)

      expected =
        case RUBY_VERSION
        when "2.2.6" then 'c2dfb69d753038366dc8348976ec6f6fbc291b260c6d5348187e209d32265491'
        when "2.1.5" then 'e014454451b38f73cba7a8bc5d21b95fc8d1f4970e025aafe9c3ea0c4973901c'
        end


      assert_equal(
        expected,
        Zip::File.open(zip_test) do |zipfile|
          zipfile.get_input_stream('patches/autoconf/2.a.0/contents') do |io|
            Digest::SHA256.hexdigest(io.read)
          end
        end
      )

      expected =
        case RUBY_VERSION
        when "2.2.6" then '09e42fe1a433eaa53e58a41bb7440f254145efd53dfa899167f9fed740c8fa3a'
        when "2.1.5" then '29550237062d2c1044cff75515a321760ea4090742a75573683b7617d863b99a'
        end

      assert_equal(
        expected,
        Zip::File.open(zip_test) do |zipfile|
          zipfile.get_input_stream('patches/bison/2.4.3/contents') do |io|
            Digest::SHA256.hexdigest(io.read)
          end
        end
      )
    end
  end


end
