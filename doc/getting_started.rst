.. highlight:: none

Getting started
***************

.. include:: README.rst


.. _log-severity:

Configuration settings
======================

Each time you run clame, it needs to load the configuration settings. Clame
searchs for a readable file in the following paths:

#. ``CLAMECFG`` environment variable
#. ``$HOME/.clame/clamecfg.rb``
#. ``/usr/local/etc/clamecfg.rb``
#. ``/etc/clamecfg.rb``

Clame has a sane default configuration settings, but it is possible to
overwrite them by mean of some of the previous files. The list of possible
configuration options and its defaults is the following:

log_file (``$HOME/.clame/clame.log``)
    File where clame logs all its actions.

log_severity (``Logger::INFO``)
    Logging level. Allowed values are:

    - ``Logger::DEBUG``
    - ``Logger:INFO``
    - ``Logger::WARN``
    - ``Logger::ERROR``
    - ``Logger::FATAL``
    - ``Logger::UNKNOWN``
database_path (``$HOME/.clame/clame.db``)
    SQLite database file where clame keeps track of installed patches, mainly.
backup_dir_install (``$HOME/.clame/save``)
    Directory where clame saves the files it overwrites in each patch version.
    They are neccesary in order to be able to restore them when clame uninstall
    a specific version.

.. Parámetros internos. No mostrar
    max_retries_db (10)
        Maximum times number clame will try to open the SQLite before raise an error.
    sleep_time_db_lock (1)
        Time in seconds clame will pause until retry to open the SQLite database.
    deploy_schema_dir (Gem specific path)
        The path where clame find the database model and initial load files of your
        SQLite database. By default it searchs in the following path:
        ``<RUBY_GEM_PATH>/clame-<CLAME_VERSION>/datamodel/schema``. For example, if you are
        running ruby 2.2 in FreeBSD, this path will become to:
        ``/usr/local/lib/ruby/gems/2.2/gems/clame-0.0.1/datamodel/schema/``
    baseclame:  (``'../..'``)
        Default path where clame will find the files referenced in ``schema`` file.
        See `schema <#schema>`__ section for details.

    

Clame configuration file
------------------------

Clame configuration file is a ruby parseable command file with the following
format:

.. code-block:: ruby

    # encoding: ISO-8859-15
    
    #
    # Configuration file for Clame
    #
    
    module Clame
    
      CUSTOM_CONF_SETTINGS = ConfSettings[
        :log_severity => Logger::DEBUG,
        :log_file => '/var/log/clame.log',
        :baseclame => '../..',
        :database_path => '/var/db/clame.db',
        :backup_dir_install => '/backups-clame',
      ]

    end


Notice that clame defaults are fine in the vast majority of circumstances, and
no configuration file is really neccesary, except in `backup_dir_install` setting,
which could be set to a specific filesystem with room enough.


SQLite internal database
========================
The first time clame is run, the SQLite internal database will be created and
deployed if does not exist. If it exists previously, clame will make some
checks to ensure that it is a valid database. This database is critical to
clame; take a look at :ref:`clame-database` to get the full details.

