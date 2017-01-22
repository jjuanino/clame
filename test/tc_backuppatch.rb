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

class TestBackupPatch < Test::Unit::TestCase

  include Clame

  def setup
    @tmpdir = Dir.mktmpdir
    @instdir = Dir.mktmpdir
    Factory.bootstrap_conf
    CONF_SETTINGS[:log_file] = File.join(@tmpdir, 'clame.log')
    CONF_SETTINGS[:database_path] = File.join(@tmpdir, 'clame.db')
    CONF_SETTINGS[:backup_dir_install] = File.join(@tmpdir, 'save')
    CONF_SETTINGS[:baseclame] = 'BASEDIR'
    Dir.mkdir(CONF_SETTINGS[:backup_dir_install])
    Factory.bootstrap_logger
    Factory.bootstrap_database

    Fs.compute_free_space_per_fs

    Dir.chdir(File.join(CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_backup),
                         File.join(@tmpdir, 'bison_backup.zip'))
    end

    @bison_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_backup.zip'),
      'bison', '2.4.3',
      {prefix: @instdir, ignore_reqs: true}
    )

    @bison_core = Marshal.load(
      @bison_patch.container.read(
        File.join(
          PatchBuilder::BASE_PATCHES, 'bison', '2.4.3',
          PatchBuilder::CORE_FILE
        )
      )
    )


  end

  def teardown
    # esto es una ñapa para que se eliminen los archivos temporales que
    # permanecen después de construir el zip. A veces fallan los test por
    # esto
    GC.start
    [@tmpdir, @instdir].each{|d| FileUtils.remove_entry_secure(d)}
    GC.start
  end

  def test_compute_regfiles_changed

    files = ['info/bison.info', 'share/examples/bison/calc++/stack.hh']

    FileUtils.mkdir_p(
      files.collect{|f| File.join(@instdir, File.dirname(f))}
    )

    files.each do |file|
      File.open(File.join(@instdir, file), 'w') do |f|
        @bison_patch.extract_file(file, f)
        f << 'Extra content to force distinct digest'
      end
    end

    backup_bison = BackupPatch.new(@bison_core, @instdir, [])
    assert_equal(
      files.collect{|f| File.join(@instdir, f)}.sort,
      backup_bison.regfiles_changed.collect do |i|
        File.absolute_path(i[:new].destination, @instdir)
      end.sort
    )

    backup_bison = BackupPatch.new(@bison_core, @instdir, [files[0]])
    assert_equal(
      files.collect{|f| File.join(@instdir, f)}[1,1],
      backup_bison.regfiles_changed.collect do |i|
        File.absolute_path(i[:new].destination, @instdir)
      end
    )


  end


  def test_compute_changed_attributes

    files = %w(info/bison.info share/examples/bison/calc++/stack.hh)

    FileUtils.mkdir_p(
      files.collect{|f| File.join(@instdir, File.dirname(f))}
    )

    FileUtils.chmod 0755,
      files.collect{|f| File.join(@instdir, File.dirname(f))}

    files.each do |file|
      File.open(File.join(@instdir, file), 'w') do |f|
        @bison_patch.extract_file(file, f)
      end
      FileUtils.chmod 0664, File.join(@instdir, file)
    end

    backup_bison = BackupPatch.new(@bison_core, @instdir, [])

    assert_equal \
      %w(share info info/bison.info
         share/examples/bison/calc++
         share/examples/bison/calc++/stack.hh).sort,
      backup_bison.changed_attributes.collect{|i| i[:new].destination}.sort

  end


  def test_register

    @bison_patch.install

    files = ['info/bison.info', 'share/examples/bison/calc++/stack.hh']

    files.each do |file|
      File.open(File.join(@instdir, file), 'w') do |f|
        @bison_patch.extract_file(file, f)
        f << 'Extra content to force distinct digest'
      end
    end


    backup_bison = BackupPatch.new(@bison_core, @instdir, [])

    # Registramos en bd el backup
    backup_bison.register

    # Recuperar los ficheros guardados en la tabla backed_up_files,
    # y comprobar son los indicados en files
    db = SQLite3::Database.new(CONF_SETTINGS[:database_path])
    res = db.execute(
      %{SELECT b.file_name
        FROM patches p,
        patch_versions v,
        backed_up_files b
      WHERE p.patch_name = 'bison'
      AND v.patch_id = p.patch_id
      AND v.version = '2.4.3'
      AND b.patch_version_id = v.patch_version_id}
    ).collect{|row| row[0]}

    assert_equal(
      files.collect{|f| File.join(@instdir, f)}.to_set,
      res.to_set
    )

    # Recuperar los ficheros guardados en la tabla installed_files,
    # y comprobar son los indicados en el schema
    db = SQLite3::Database.new(CONF_SETTINGS[:database_path])
    res = db.execute(
      %{SELECT i.file_name, t.file_type, d.digest
        FROM patches p,
        patch_versions v,
        installed_files i LEFT JOIN digests d
        ON i.digest_id = d.digest_id,
        file_types t
      WHERE p.patch_name = 'bison'
      AND v.patch_id = p.patch_id
      AND v.version = '2.4.3'
      AND i.patch_version_id = v.patch_version_id
      AND t.file_type_id = i.file_type_id}
    ).collect{|row| row[0,3]}

    assert_equal(
      @bison_core.schema.collect do |item|
        digest = item.digest if (item.filetype == FileType::REGFILE)
        [File.absolute_path(item.destination, @instdir), item.filetype, digest]
      end.to_set,
      res.to_set
    )

  end

  # NOTE: este test no funciona correctamente en ZFS. Las razones son varias:
  # 1- Sys::Filesystem::Stat no devuelve el espacio usado o libre correctamente
  # 2- File.lstat no calcula correctamente el número de bloques que ocupa un
  #    fichero
  def test_check_room
    CONF_SETTINGS[:backup_dir_install] = Dir.tmpdir
    prefix = Dir.mktmpdir

    backup_fs = Sys::Filesystem.mount_point(
      CONF_SETTINGS[:backup_dir_install]
    )

    # mounted_fs tiene que ordenarse en modo inverso por profundidad
    Fs.mounted_fs = [backup_fs, '/']
    Fs.free_space = {backup_fs => 1, '/' => 3016}

    assert_nothing_raised do
      BackupPatch.new(@bison_core, @instdir, []).check_room
    end

    @bison_patch.install


    files = %w(info/bison.info share/examples/bison/calc++/stack.hh)
    files.each do |file|
      File.open(File.join(@instdir, file), 'w') do |f|
        @bison_patch.extract_file(file, f)
        f << 'Extra content to force distinct digest'
      end
    end

    Fs.free_space[backup_fs] = 1032
    assert_nothing_raised do
      BackupPatch.new(@bison_core, @instdir, []).check_room
    end


    # Despues de instalar, no hay espacio libre: se necesitan 1032 bloques
    # NOTA: Este test no se realiza en ZFS
    if Sys::Filesystem.stat(@instdir).filesystem_id.zero?
      omit("ZFS Filesystem. Skipping NotEnoughFsFreeSpace assertion")
    end
    Fs.free_space[backup_fs] = 1031
    assert_raise(NotEnoughFsFreeSpace) do
      BackupPatch.new(@bison_core, @instdir, []).check_room
    end


  ensure
    Dir.rmdir(prefix)
  end
end
