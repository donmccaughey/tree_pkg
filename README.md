tree 1.8.0 for macOS
====================

This project builds a signed macOS universal installer package for [`tree`][1], 
a recursive directory listing command. It contains the source distribution for 
`tree` 1.8.0.

[1]: http://mama.indstate.edu/users/ice/tree/ "tree"

## Building

The [`Makefile`][2] in the project root directory builds the installer package.
The following makefile variables can be set from the command line:

- `APP_SIGNING_ID`: The name of the 
    [Apple _Developer ID Application_ certificate][5] used to sign the 
    `nginx` executable.  The certificate must be installed on the build 
    machine's Keychain.  Defaults to "Developer ID Application: Donald 
    McCaughey" if not specified.
- `TMP`: The name of the directory for intermediate files.  Defaults to 
    "`./tmp`" if not specified.

[2]: https://github.com/donmccaughey/tree_pkg/blob/master/Makefile

To build and sign the executable and installer, run:

        $ make [APP_SIGNING_ID="<cert name>"]  [TMP="<build dir>"]

Intermediate files are generated in the temp directory; the installer 
package is written into the project root with the name `tree-1.8.0.pkg`.  

To remove all generated files (including the installer), run:

        $ make clean


## License

The installer and related scripts are copyright (c) 2021 Don McCaughey.
`tree` and the installer are distributed under the GNU General Public License, 
version 2. See the LICENSE file for details.

