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


class TestInstalledPatch < Test::Unit::TestCase

  include Clame

  PATH_CURRENT_DIR = Pathname.new(CURRENT_DIR)

  def setup
    @tmpdir = Dir.mktmpdir
    Factory.bootstrap_conf
    CONF_SETTINGS[:log_file] = File.join(@tmpdir, 'clame.log')
    CONF_SETTINGS[:database_path] = File.join(@tmpdir, 'clame.db')
    CONF_SETTINGS[:backup_dir_install] = File.join(@tmpdir, 'save')
    Dir.mkdir(CONF_SETTINGS[:backup_dir_install])
    Factory.bootstrap_logger
    Factory.bootstrap_database
    Fs.compute_free_space_per_fs
    Fs.get_mounted_fs

    @initial_vars = {'MYVAR' => 'MYVALUE'}

  end

  def teardown
    # Esto es una ñapa para que se eliminen los archivos temporales que
    # permanecen después de construir el zip. A veces fallan los test por esto
    GC.start
    FileUtils.remove_entry_secure(@tmpdir)
    GC.start
  end

  def test_patch_not_exist
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_backup),
                         File.join(@tmpdir, 'bison_backup.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    bison_backup = PackagedPatch.new(
      File.join(@tmpdir, 'bison_backup.zip'), 'bison', '2.4.3',
      {prefix: @tmpdir, ignore_reqs: true}
    )

    bison_backup.install

    assert_nothing_raised{InstalledPatch.new('bison', '2.4.3')}
    assert_raise(PatchNotExist){InstalledPatch.new('bison', '2.4.0')}
  end


  def test_uninstall_check_max_version_installed
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(alpha_10 alpha_11),
                         File.join(@tmpdir, 'alphas.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    alpha_10 = PackagedPatch.new(
      File.join(@tmpdir, 'alphas.zip'), 'alpha', '1.0', {prefix: @tmpdir}
    )

    alpha_11 = PackagedPatch.new(
      File.join(@tmpdir, 'alphas.zip'), 'alpha', '1.1', {prefix: @tmpdir}
    )

    alpha_10.install
    alpha_11.install

    assert_raise(HigherPatchVersionInstalled) do
      InstalledPatch.new('alpha', '1.0').uninstall
    end

    assert_nothing_raised do
      InstalledPatch.new('alpha', '1.1').uninstall
      InstalledPatch.new('alpha', '1.0').uninstall
    end

  end


  def test_uninstall_requirements_broken

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(beta_10 beta_15 gamma_10 gamma_19 gamma_23),
                         File.join(@tmpdir, 'greek.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    beta_10 = PackagedPatch.new(
      File.join(@tmpdir, 'greek.zip'), 'beta', '1.0', {prefix: @tmpdir}
    )
    beta_15 = PackagedPatch.new(
      File.join(@tmpdir, 'greek.zip'), 'beta', '1.5', {prefix: @tmpdir}
    )
    gamma_10 = PackagedPatch.new(
      File.join(@tmpdir, 'greek.zip'), 'gamma', '1.0', {prefix: @tmpdir}
    )
    gamma_19 = PackagedPatch.new(
      File.join(@tmpdir, 'greek.zip'), 'gamma', '1.9', {prefix: @tmpdir}
    )
    gamma_23 = PackagedPatch.new(
      File.join(@tmpdir, 'greek.zip'), 'gamma', '2.3', {prefix: @tmpdir}
    )


    beta_10.install
    beta_15.install
    gamma_10.install
    gamma_19.install
    gamma_23.install


    assert_raise(RequirementsWouldBeBroken) do
      InstalledPatch.new('beta', '1.5').uninstall
    end

    InstalledPatch.new('gamma', '2.3').uninstall
    assert_raise(RequirementsWouldBeBroken) do
      InstalledPatch.new('beta', '1.5').uninstall
    end

    assert_raise(RequirementsWouldBeBroken) do
      InstalledPatch.new('beta', '1.5').uninstall
    end

    assert_nothing_raised do
      InstalledPatch.new('gamma', '1.9').uninstall
    end

    assert_raise(RequirementsWouldBeBroken) do
      InstalledPatch.new('beta', '1.5').uninstall
    end

    InstalledPatch.new('gamma', '1.0').uninstall
    assert_nothing_raised do
      InstalledPatch.new('beta', '1.5').uninstall
    end

    assert_nothing_raised do
      InstalledPatch.new('beta', '1.0').uninstall
    end


    assert_raise(PatchNotExist) do
      InstalledPatch.new('gamma', '2.3')
    end
    assert_raise(PatchNotExist) do
      InstalledPatch.new('gamma', '1.9')
    end
    assert_raise(PatchNotExist) do
      InstalledPatch.new('gamma', '1.0')
    end
    assert_raise(PatchNotExist) do
      InstalledPatch.new('beta', '1.5')
    end
    assert_raise(PatchNotExist) do
      InstalledPatch.new('beta', '1.0')
    end

  end


  def test_uninstall_preremove

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(tee_91 tee_92), File.join(@tmpdir, 'tee.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    tee_91 = PackagedPatch.new(File.join(@tmpdir, 'tee.zip'), 'tee', '9.1')
    tee_92 = PackagedPatch.new(
      File.join(@tmpdir, 'tee.zip'), 'tee', '9.2', {prefix: @tmpdir}
    )
    tee_91.install
    tee_92.install

    assert_raise(ScriptInstallExecutionError) do
      InstalledPatch.new('tee', '9.1').uninstall(ignore_hvers: true)
    end

    assert_nothing_raised do
      InstalledPatch.new('tee', '9.2').uninstall
    end


  end


  def test_uninstall_postremove

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(tee_93 tee_94), File.join(@tmpdir, 'tee.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    tee_93 = PackagedPatch.new(File.join(@tmpdir, 'tee.zip'), 'tee', '9.3',
                               {prefix: @tmpdir})
    tee_94 = PackagedPatch.new(File.join(@tmpdir, 'tee.zip'), 'tee', '9.4',
                               {prefix: @tmpdir})
    tee_93.install
    tee_94.install

    assert_nothing_raised do
      InstalledPatch.new('tee', '9.3').uninstall(ignore_hvers: true)
    end

    assert_raise(ScriptInstallExecutionError) do
      InstalledPatch.new('tee', '9.4').uninstall
    end


  end


  def test_restore
    Dir.mkdir(File.join(@tmpdir, 'instdir'))
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_backup),
                         File.join(@tmpdir, 'bison_backup.zip'))
    end

    bison_backup = PackagedPatch.new(
      File.join(@tmpdir, 'bison_backup.zip'),
      'bison', '2.4.3',  {prefix: @tmpdir, ignore_reqs: true}
    )

    files = ['info/bison.info', 'share/examples/bison/calc++/stack.hh']

    FileUtils.mkdir_p(
      files.collect{|f| File.join(@tmpdir, 'instdir', File.dirname(f))}
    )

    files.each do |file|
      File.open(File.join(@tmpdir, 'instdir', file), 'w') do |f|
        f.puts "Content to force distinct digest"
      end
    end

    fork do
      $stdout.reopen File::NULL
      bison_backup.install
      InstalledPatch.new('bison', '2.4.3').uninstall(
        abort_on_restore_error: true
      )
    end

    Process.wait

    files.each do |file|
      assert_equal \
        "Content to force distinct digest\n",
        IO.read(File.join(@tmpdir, 'instdir', file))
    end

    expected =  ["info/", "share/", "share/examples/",
      "share/examples/bison/", "share/examples/bison/calc++/"]

    Dir.chdir File.join(@tmpdir, 'instdir') do
      assert_equal expected.to_set, Dir.glob('**/').to_set
    end
  end

end
