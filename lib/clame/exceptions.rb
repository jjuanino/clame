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

  class Error < RuntimeError

    # errors code start with 101

    INVALID_CONF_SETTING = 101
    INVALID_MASK_PERM = 103
    INVALID_FILE_TYPE = 104
    SYMLINK_DEST_NIL = 105
    DUPLICATE_DESTINATION = 106
    DUPLICATE_VAR_NAME = 107
    MANDATORY_VARS_NOT_FOUND = 108
    BAD_FORMAT_VARIABLE = 109
    DUPLICATE_REQUISITE = 110
    DUPLICATE_CONFLICT = 111
    REQUISITE_CANNOT_BE_CONFLICT = 112
    DUPLICATED_INPUT_VARIABLE = 113
    INFO_VAR_DUP_INPUT = 114
    ORIGIN_NOT_VALID = 115
    DIRECTORY_NOT_EXIST = 116
    FILE_NOT_EXIST = 117
    SCHEMA_RELATIVE_PATHS = 118
    DB_PATH_EXISTS = 119
    INVALID_DB = 120
    INVALID_DATABASE_VERSION = 121
    PATCH_ZIP_FILE_EXISTS = 122
    INVALID_ZIP_FILE = 123
    INTEGRITY_CHECK_FAIL = 124
    CONTAINER_ENTRY_NOT_EXIST = 125
    INVALID_CONTAINER_ENTRY = 126
    # NO USAR EL CÓDIGO 127
    PATCHNAME_VERSION_NOT_FOUND = 128
    NOT_ENOUGH_FS_FREE_SPACE = 129
    LEGAL_NOTICE_NOT_ACCEPTED = 133
    SCRIPT_INSTALL_EXECUTION_ERROR = 134
    USER_NOT_EXISTS = 135
    GROUP_NOT_EXISTS = 136
    PREFIX_NOT_EXISTS = 137
    PREFIX_NOT_ABSOLUTE_PATH = 138
    DEFAULT_USER_NOT_EXISTS = 139
    DEFAULT_GROUP_NOT_EXISTS = 140
    NOT_ROOM_ENOUGH_FOR_BACKUP = 141
    PATCH_ALREADY_INSTALLED = 142
    HIGHER_PATCH_VERSION_INSTALLED = 143
    REQUIREMENTS_NOT_SATISFIED = 144
    INSTALLED_CONFLICTS = 145
    SCRIPT_INSTALL_ANORMAL_EXIT = 146
    SCRIPT_INSTALL_SIGNAL_RECEIVED = 147
    HARD_LINK_DEST_NIL = 148
    INSTALL_WOULD_CONFLICT = 149
    PATCH_NOT_EXIST = 150
    REQUIREMENTS_WOULD_BE_BROKEN = 151
    UNINSTALL_ERROR = 152
    PROCESS_ID_NOT_MATCH = 153
    CONTENTS_FILE_NOT_EXISTS = 154
    PATH_NOT_NORMALIZED = 155
    PATCH_NAME_NOT_EXISTS_IN_ZIP = 156


    attr_reader :coderr, :texterr
    def initialize(coderr, texterr=nil)
      @coderr = coderr
      @texterr = texterr.to_s
    end

    def to_s
      "\nCLAME_ERROR #@coderr: #@texterr"
    end

  end # class Error


  class InvalidConfSetting < Error

    def initialize(confsetting)
      texterr = "Invalid configuration setting: (#{confsetting})"
      super(INVALID_CONF_SETTING, texterr)
    end

  end


  class InvalidFileType < Error

    attr_reader :filetype

    def initialize(filetype)

      @filetype = filetype

      texterr = "Invalid file type (#{filetype})"
      super(INVALID_FILE_TYPE, texterr)
    end

  end


  class InvalidMaskPerm < Error

    attr_reader :mask

    def initialize(mask)

      @mask = mask

      texterr = "Invalid permission mask (#{mask})"
      super(INVALID_MASK_PERM, texterr)
    end

  end


  class SymLinkDestNil < Error
    def initialize
      texterr = "Destination symbolic link must be defined"
      super(SYMLINK_DEST_NIL, texterr)
    end

  end


  class DuplicateDestination < Error
    def initialize(destination)
      texterr = "Duplicate destination pathname (#{destination})"
      super(DUPLICATE_DESTINATION, texterr)
    end
  end


  class DuplicateVarName < Error
    def initialize(varname)
      texterr = "Duplicate variable name declaration (#{varname})"
      super(DUPLICATE_VAR_NAME, texterr)
    end
  end


  class MandatoryVarsNotFound < Error
    def initialize(vars)
      texterr = "The following mandatory variables has not been initialized: (" +
        vars.join(',') + ")"
      super(MANDATORY_VARS_NOT_FOUND, texterr)
    end

  end


  class BadFormatVariable < Error
    def initialize(mand_var)
      texterr = "The following variable has not the proper format: (#{mand_var})"
      super(BAD_FORMAT_VARIABLE, texterr)
    end
  end


  class DuplicateRequisite < Error

    def initialize(requisite)
      texterr = "Duplicate requisite (#{requisite})"
      super(DUPLICATE_REQUISITE, texterr)
    end

  end


  class DuplicateConflict < Error
    def initialize(conflict)
      texterr = "Duplicate conflict (#{conflict})"
      super(DUPLICATE_CONFLICT, texterr)
    end

  end


  class RequisiteCannotBeConflict < Error
    def initialize(req_and_conf)
      texterr = "Requisite (#{req_and_conf}) appears also as conflict"
      super(REQUISITE_CANNOT_BE_CONFLICT, texterr)
    end

  end


  class DuplicatedInputVariable < Error
    def initialize(input_var)
      texterr = "Duplicated input variable (#{input_var})"
      super(DUPLICATED_INPUT_VARIABLE, texterr)
    end
  end


  class InfoVarDupInput < Error
    def initialize(infovar)
      texterr = "Info variable (#{infovar}) cannot be used in input"
      super(INFO_VAR_DUP_INPUT, texterr)
    end

  end


  class OriginNotValid < Error
    def initialize(origin)
      texterr = "Origin file (#{origin}) does not exist or is not a regular " +
        "file"
      super(ORIGIN_NOT_VALID, texterr)
    end

  end


  class DirectoryNotExist < Error
    def initialize(dirname)
      texterr = "Directory (#{dirname}) does not exist"
      super(DIRECTORY_NOT_EXIST, texterr)
    end
  end


  class FileNotExist < Error

    def initialize(file)
      texterr = "File (#{file}) does not exist"
      super(FILE_NOT_EXIST, texterr)
    end

  end


  class IO_Error < Error

    def initialize(file, io_exception)
      raise io_exception, "Error opening file (#{file})"
    end

  end


  class SchemaRelativePaths < Error

    def initialize(relative_paths)
      texterr = "The following are relative paths but no PREFIX was set:\n" +
        relative_paths.collect{|p| "\t" + p}.join("\n")
      super(SCHEMA_RELATIVE_PATHS, texterr)
    end

  end


  class DbPathExists < Error

    def initialize(db_file)
      text_err = "File (#{db_file}) exists"
      super(DB_PATH_EXISTS, text_err)
    end

  end


  class InvalidDB < Error

    def initialize(db_file, error)
      text_err = "Invalid clame database: (#{error})"
      super(INVALID_DB, text_err)
    end

  end


  class InvalidDatabaseVersion < Error

    def initialize(min_version, actual_version)
      text_err = "Invalid database version. At least (#{min_version}) is " +
        "required but (#{actual_version}) is the current one"
      super(INVALID_DATABASE_VERSION, text_err)
    end

  end


  class PatchZipFileExists < Error

    def initialize(zip_file)
      text_err = "File (#{zip_file}) already exists"
      super(PATCH_ZIP_FILE_EXISTS, text_err)
    end

  end


  class InvalidZipFile < Error
    def initialize(file)
      text_err = "File (#{file}) is invalid or does not exist"
      super(INVALID_ZIP_FILE, text_err)
    end

  end


  class IntegrityCheckFail < Error
    def initialize(entry, invalid_hash)
      text_err = "Entry (#{entry}) has not (#{invalid_hash}) digest"
      super(INTEGRITY_CHECK_FAIL, text_err)
    end
  end


  class ContainerEntryNotExist < Error
    def initialize(entry)
      text_err = "Entry (#{entry}) does not exist"
      super(CONTAINER_ENTRY_NOT_EXIST, text_err)
    end
  end


  class InvalidContainerEntry < Error
    def initialize(entry)
      text_err = "Entry (#{entry}) is not valid"
      super(INVALID_CONTAINER_ENTRY, text_err)
    end
  end


  class ContentsFileNotExists < Error
    def initialize(patch_name, version)
      text_err = "Contents file " +
        " (#{File.join(patch_name, version, PatchBuilder::CONTENTS_FILE)})" +
        " does not exist"
      super(CONTENTS_FILE_NOT_EXISTS, text_err)
    end
  end


  class PatchNameVersionNotFound < Error
    def initialize(patch_name, version)
      text_err = "Patch name (#{patch_name}), version (#{version})" +
        " not found in zip file"
      super(PATCHNAME_VERSION_NOT_FOUND, text_err)
    end

  end


  class NotEnoughFsFreeSpace < Error
    def initialize(not_free_space_fs)
      text_err = "There is not enough free space in the following file " +
        "systems\n\n" +
        sprintf(
          "%12s\t%12s\t%15s",
          "Filesystem", "KiB avail", "KiB required\n") +
        not_free_space_fs.collect do |fs, kib_required|
          sprintf(
            "%12s\t%12d\t%14d",
            fs, Fs.free_space[fs], kib_required
          )
        end.join("\n")

      super(NOT_ENOUGH_FS_FREE_SPACE, text_err)
    end

  end


  class LegalNoticeNotAccepted < Error
    def initialize
      text_err = 'You have not accepted the legal notice. Aborting.'
      super(LEGAL_NOTICE_NOT_ACCEPTED, text_err)
    end
  end


  class ScriptInstallExecutionError < Error
    def initialize(script, exitstatus)
      text_err = "Error executing #{script}. Exit status (#{exitstatus})"
      super(SCRIPT_INSTALL_EXECUTION_ERROR, text_err)
    end
  end


  class UserNotExists < Error
    def initialize(owner, schemaitems)
      text_err = "Username (#{owner}) does not exist\nAffected paths:\n" +
        schemaitems.collect{|s| "\t" + s.destination}.join("\n")
      super(USER_NOT_EXISTS, text_err)
    end
  end


  class GroupNotExists < Error
    def initialize(group, schemaitems)
      text_err = "Groupname (#{group}) does not exist\nAffected paths:\n" +
        schemaitems.collect{|s| "\t" + s.destination}.join("\n")
      super(GROUP_NOT_EXISTS, text_err)
    end
  end


  class PrefixNotExists < Error
    def initialize(basedir)
      text_err = "Prefix (#{basedir}) does not exist or is not a directory"
      super(PREFIX_NOT_EXISTS, text_err)
    end
  end


  class PrefixNotAbsolutePath < Error
    def initialize(absolute_prefix, prefix)
      text_err = "Prefix (#{prefix}) does is not an absolute path or does\n" +
        "not match with its canonical path (#{absolute_prefix})"
      super(PREFIX_NOT_ABSOLUTE_PATH, text_err)
    end

  end


  class DefaultUserNotExists < Error
    def initialize(owner)
      text_err = "Default username (#{owner}) does not exist"
      super(DEFAULT_USER_NOT_EXISTS, text_err)
    end
  end


  class DefaultGroupNotExists < Error
    def initialize(group)
      text_err = "Group name (#{group}) does not exist"
      super(DEFAULT_GROUP_NOT_EXISTS, text_err)
    end
  end


  class NotRoomEnoughForBackup < Error
    def initialize(patch_name, version, backup_fs)
      text_err = "Not enough free space in backup file system " +
        "(#{backup_fs}) to install (#{patch_name}), version (#{version})"
      super(NOT_ROOM_ENOUGH_FOR_BACKUP, text_err)
    end
  end


  class PatchAlreadyInstalled < Error
    def initialize(patch_name, version, status)
      text_err = "Patch name (#{patch_name}), version (#{version}) " +
        "is already installed with status (#{status})"
      super(PATCH_ALREADY_INSTALLED, text_err)
    end

  end


  class HigherPatchVersionInstalled < Error
    def initialize(patch_name, version,
                   max_version_installed, action='install')
      text_err = "Patch name (#{patch_name}), " +
        "version (#{version}) cannot be #{action}ed: a higher " +
        "version (#{max_version_installed}) is currently installed"
      super(HIGHER_PATCH_VERSION_INSTALLED, text_err)
    end
  end


  class RequirementsNotSatisfied < Error
    def initialize(failed_reqs)
      # failed_reqs es un array de intervalos, donde el extremo
      # del intervalo es un objeto de tipo PatchVersion
      text_err = "The following requirements are not satisfied: " +
        failed_reqs.collect do |int|
          "#{int.extreme.patchname} #{int.operator} #{int.extreme.version}"
        end.join(', ')
      super(REQUIREMENTS_NOT_SATISFIED, text_err)
    end
  end


  # Los conflictos de un parche están instalados.
  class InstalledConflicts < Error
    def initialize(inst_conflicts)
      # inst_conflicts es un array de parches instalados que provocan
      # conflicto
      text_err = "The following installed patches cause conflict: " +
        inst_conflicts.collect do |patch|
          "#{patch.patchname} #{patch.version}"
        end.join(', ')
      super(INSTALLED_CONFLICTS, text_err)
    end
  end


  # La instalación de un parche provocaría un conflicto con otros ya
  # instalados
  class InstallWouldConflict < Error

    def initialize(conflict_patches)
      # conflict_patches es un array de parches instalados que provocan
      # conflicto

      text_err = conflict_patches.collect do |conflict_patch|
        patch_name = conflict_patch[:patch_name]
        patch_version = conflict_patch[:version]
        interval = conflict_patch[:interval]

        "#{patch_name} #{patch_version} cause conflict with " + interval.to_s
      end.join("\n")

      super(INSTALL_WOULD_CONFLICT, text_err)
    end

  end


  class ScriptInstallAnormalExit < Error
    def initialize(script, error)
      text_err = "Error executing #{script}: (#{error})"
      super(SCRIPT_INSTALL_ANORMAL_EXIT, text_err)
    end
  end


  class ScriptInstallSignalReceived < Error
    def initialize(script, error)
      text_err = "#{script} ended with signal #{error}"
      super(SCRIPT_INSTALL_SIGNAL_RECEIVED, text_err)
    end
  end


  class HardLinkDestNil < Error
    def initialize
      texterr = "Destination hard link must be defined"
      super(HARD_LINK_DEST_NIL, texterr)
    end

  end


  class PatchNotExist < Error
    def initialize(patch_name, version)
      texterr = "Patch name (#{patch_name}), version (#{version}) does " +
        "not exist"
      super(PATCH_NOT_EXIST, texterr)
    end
  end


  class RequirementsWouldBeBroken < Error

    # broken_deps es un array, donde cada componente es un hash de esta forma:
    # {patch_name, version, interval}
    # (patch_name, version) es un parche que tiene a interval como dependencia
    # interval es un interval que contiene self
    def initialize(broken_deps)

      text_err = "The following requirements would be broken\n" +
        broken_deps.collect do |dep|
          interval = dep[:interval]

          "Patch (#{dep[:patch_name]}), version (#{dep[:version]}) depends " +
            "on (#{interval})"
        end.join("\n")

      super(REQUIREMENTS_WOULD_BE_BROKEN, text_err)

    end

  end


  class UninstallError < Error
    # Error de desinstalación.
    def initialize(msg)
      text_err = mgs
      super(UNINSTALL_ERROR, text_err)
    end
  end


  class ProcessIDNotMatch < Error
    def initialize(inst_uid, uninst_uid)
      text_err = "User id of installation (#{inst_uid}) is not the " +
        "same as uninstallation: (#{uninst_uid})."
      super(PROCESS_ID_NOT_MATCH, text_err)
    end
  end


  class PathNotNormalized < Error
    attr_reader :path
    def initialize(path)
      @path = path
      text_err = "Path name (#{path}) is not normalized."
      super(PATH_NOT_NORMALIZED, text_err)
    end
  end


  class PatchNameNotExistInZip < Error
    attr_reader :patch_name
    def initialize(patch_name, zip_file)
      @patch_name = patch_name
      @zip_file = zip_file
      text_err = "Patch name (#{patch_name}) does not exist in (#{zip_file})"
      super(PATCH_NAME_NOT_EXISTS_IN_ZIP, text_err)
    end
  end


end # module Clame



module Clame

  module SyntaxError

    class SyntaxError < Error

      # syntax errors codes start with 501
      INVALID_LINE_FORMAT = 501
      DUPLICATE_NOTDIR_DEFAULTS = 502
      DUPLICATE_DIR_DEFAULTS = 503
      INVALID_FILE_TYPE = 504
      INVALID_MASK_PERM = 505
      SYMLINK_DEST_NIL = 506
      PATH_NOT_NORMALIZED = 507
      HARD_LINK_DEST_NIL = 508

      def initialize(coderror, syntax_err_text, line, lineno,
                     suggestion, file_name='schema')

        texterr = "Syntax error at line #{lineno} in #{file_name}" +
          " file:\n<<#{line}>>\n#{syntax_err_text}\nSuggestion: #{suggestion}"
        super(coderror, texterr)

      end

    end


    class InvalidLineFormat < SyntaxError

      def initialize(file_name, line, lineno)
        super(INVALID_LINE_FORMAT, "Invalid line format", line, lineno,
              'Check the syntax', file_name)
      end

    end


    class DuplicateNotDirDefaults < SyntaxError

      def initialize(line, lineno)
        super(DUPLICATE_NOTDIR_DEFAULTS, "Duplicate defaults for not dirs",
              line, lineno,
              "Check that the notdirdefaults token appears only once in the schema file")

      end

    end


    class DuplicateDirDefaults < SyntaxError

      def initialize(line, lineno)
        super(DUPLICATE_DIR_DEFAULTS, "Duplicate defaults for directories",
              line, lineno,
              "Check that the dirdefaults token appears only once in the " +
              "schema file")

      end

    end

    class InvalidFileType < SyntaxError
      def initialize(filetype, line, lineno)

        super(INVALID_FILE_TYPE,
              "Invalid file type (#{filetype})",
              line, lineno,
              "Only (#{FileType::FILETYPES.each_value.collect do |v|
                v[:short_name]
              end.join(', ')}) are allowed")
      end

    end


    class InvalidMaskPerm < SyntaxError

      def initialize(mask, line, lineno)

        super(INVALID_MASK_PERM,
              "Invalid permission mask (#{mask})",
              line, lineno,
              "Only octal numbers from 0000 to 7777 are allowed")
      end
    end


    class SymLinkDestNil < SyntaxError
      def initialize(line, lineno)
        super(SYMLINK_DEST_NIL,
              "Destination symbolic link must be defined",
              line, lineno,
              "Give a destination to symbolic link")
      end

    end

    class PathNotNormalized < SyntaxError
      def initialize(path, line, lineno)
        super(PATH_NOT_NORMALIZED,
              "Path name (#{path}) is not normalized.",
              line, lineno,
              "Provide a canonical path (e.g, not finished with slash)")
      end
    end

    class HardLinkDestNil < SyntaxError
      def initialize(line,lineno)
        super(HARD_LINK_DEST_NIL,
              "Destination hard link must be defined",
              line, lineno,
              'Provide a hard link destination')
      end
    end

  end # module SyntaxError

end # module Clame


#
# Errores internos de la aplicación
#

module Clame

  class InternalError < RuntimeError

    # Internal errors codes start with 701
    INVALID_OPERATOR = 701
    INVALID_PATCH_NAME = 702
    INVALID_PATCH_VERSION = 703
    INVALID_PATHNAME = 705

    def initialize(coderror, texterr)
      @coderror = coderror
      @texterr = texterr
    end

    def to_s
      "CLAME_INTERNAL_ERROR #@coderror: #@texterr"
    end
  end


  class InvalidOperator < InternalError

    def initialize(operator)
      super(INVALID_OPERATOR,
            "Operator (#{operator}) is not valid")
    end

  end


  class InvalidPatchName < InternalError

    def initialize(patch_name)
      super(INVALID_PATCH_NAME,
            "Patch name (#{patch_name}) is invalid")
    end

  end


  class InvalidPatchVersion < InternalError

    def initialize(patch_name)
      super(INVALID_PATCH_VERSION,
            "Patch version (#{patch_name}) is invalid")
    end

  end


  class InvalidPathname < InternalError
    def initialize(pathname)
      super(INVALID_PATHNAME,
            "(#{pathname.to_s}) is a relative path. Cannot call pathname.parents")
    end

  end


end # module Clame
