# headlines.vim

With `headlines`, you can quickly edit the top of your source files without
losing your place in the current window.


## Usage

For filetypes that have a configured pattern, the `:Headlines` command will
toggle a popup window containing lines from the top of the buffer.

The default key map to toggle the headlines window is
`<localleader><localleader>`.

Saving in the popup window will write the changes back to the original buffer.
Closing the headlines window will save the original buffer to disk.  By
default, anything done in the popup window will result in a single undo block
in the original buffer.


## Features

* Displays only the top portion of your source code in a split window.  This
  isolation allows you to jump to the bottom of your globals/imports, find and
  replace, or perform other broad actions without affecting the rest of your
  source.
* Editing in the `headlines` window will not affect the original buffer's
  `jumplist`.
* The original buffer's position is maintained so you don't lose your place
  after you're finished.  If the lines you were editing prompted you to jump to
  the top, it should stay in view so you don't forget what were you doing.
* All changes in the `headlines` window will result in a single undo block in
  the original buffer.  This can be disabled so that an undo block is created
  on each `:write`.
* The cursor position in the `headlines` window is saved independently.


## License

MIT
