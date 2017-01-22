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
    # Versión  major, minor de la librería marshal
    @mrs_vers = Marshal::MAJOR_VERSION.to_s + '.' + Marshal::MINOR_VERSION.to_s
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

      expected =
          '6a405c7059e662e2d40caef7bf752258a2ab8e9277df05b86e644d201592e5b8'


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

      expected =
        '6a405c7059e662e2d40caef7bf752258a2ab8e9277df05b86e644d201592e5b8'

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

      expected =
        '6a405c7059e662e2d40caef7bf752258a2ab8e9277df05b86e644d201592e5b8'

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

      expected =
        'b530ebef46f6c32725ef9e613365bdaec9b14124d7bbc54dac71dc2188b61600'

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


      expected =
        'b530ebef46f6c32725ef9e613365bdaec9b14124d7bbc54dac71dc2188b61600'

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
          ['09e42fe1a433eaa53e58a41bb7440f254145efd53dfa899167f9fed740c8fa3a',
            'c2dfb69d753038366dc8348976ec6f6fbc291b260c6d5348187e209d32265491']

      assert_equal(expected, hash_contents)

      expected =
          'c2dfb69d753038366dc8348976ec6f6fbc291b260c6d5348187e209d32265491'

      assert_equal(
        expected,
        Zip::File.open(zip_test) do |zipfile|
          zipfile.get_input_stream('patches/autoconf/2.a.0/contents') do |io|
            Digest::SHA256.hexdigest(io.read)
          end
        end
      )

      expected =
          '09e42fe1a433eaa53e58a41bb7440f254145efd53dfa899167f9fed740c8fa3a'

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
