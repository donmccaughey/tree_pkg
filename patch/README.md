# Patches to `tree`.

This directory contains patches to apply to `tree`.  The original makefile from
the `tree` distribution is stored in `Makefile.original`.

A patch file `Makefile.patch` is created by capturing the changes between the
original and modified files using the command:

    diff -u patch/Makefile.original dist/Makefile > patch/Makefile.patch

The changes can be re-applied to a new `tree` distribution using the command:

    patch dist/Makefile < patch/Makefile.patch

