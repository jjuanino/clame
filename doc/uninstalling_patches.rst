.. highlight:: none

Uninstalling patches
********************

Command line
============
In order to uninstall a patch, you have to specify patch name and version:

.. code-block:: console

    $ clame remove foo 1.2


.. _initial-checks-uninstall:

Initial checks
==============
Previous to the unistallation, clame checks some things to ensure that nothing
will break.

* Version to uninstall is the highest

  Clame will not allow to uninstall a patch if it has not the highest version.
  For example, if *foo 1.2* and *foo 1.3* are both installed, you cannot
  uninstall *foo 1.2*. This check can be ignored.

* Uninstallation breaks any dependency

  Clame alerts when the uninstallation breaks any dependency. For example, if
  *foo 1.3* depends on *bar* (any version), and you are trying to uninstall the
  unique installed version of *bar*, clame will warn you. This check
  can be ignored.

* Effective uid is the right one

  If you are trying to uninstall a patch with a non root user, clame will
  ensure that this user is the same who installed the patch. This means that,
  if you install a patch with ``foo`` user, clame will warn you if you later
  try to uninstall as ``bar`` user. This check can be ignored.

The uninstallation stage
=========================
When clame passes the previous checks, it will uninstall the patch, by
following these steps.

Prepare the environment
^^^^^^^^^^^^^^^^^^^^^^^
By inspecting its internal database, clame retrieves the checkinstall, input
and info variables. They will make up the environment of the preremove and
postremove scripts.

Preremove
^^^^^^^^^
Clame runs the ``preremove`` script, if provided. If the returned exit code is
non zero, clame aborts the uninstallation. 

.. note::
    In preremove and postremove stages, clame will set standard input to
    ``/dev/null``. Standard output and error remains unchanged.

Restore the backup
^^^^^^^^^^^^^^^^^^
Clame will do the best effort to restore the files and directories to their
pristine status. This is a complex task, and sometimes will go wrong. However,
you can ignore these errors by using the ``-a`` command line flag.

Postremove
^^^^^^^^^^
Clame runs the postremove script, if provided. If the returned exit code is non
zero, clame aborts. You can retry the uninstallation later.


Unregister patch of internal database
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Clame unregisters the patch from its internal database. You cannot longer to
make any reference to this patch, as clame will know nothing about it.  After
that, clame returns the control to command line.
