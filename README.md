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


## Todo

* [ ] Make popup window statusline not ugly.


## License

The MIT License
Copyright (c) 2016 Tommy Allen

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
