# The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import strutils, os, osproc, terminal, tables

template test_my_way*(suitename: string, inner: untyped) =
  ## Simple wrapper for when main and -d:testmyway, and imports nim's 
  ## standard unit testing module
  when is_main_module and defined(testmyway):
    import unittest
    suite suitename:
      inner

template test_my_way*(suitename: string, imports, inner: untyped) =
  ## Simple wrapper for when main and -d:testmyway, and imports nim's 
  ## standard unit testing module
  when is_main_module and defined(testmyway):
    import unittest
    imports
    suite suitename:
      inner

proc grab_sources(matches: string): TableRef[string, int] =
  result = new_table[string, int]()
  for file in walk_dir_rec(get_current_dir()):
    if file.contains(".nim"):
      if file.contains("/private/") or file.contains(".nimble"):
        continue
      if file.contains(matches):
        result[file] = 1

proc run_tests(sources: TableRef[string, int], extraflags: string, successful, failed: var int) =
  for source, code in sources.mpairs:
    var 
      exitcode = 0
      cmd = "nim c -d:testmyway " & extraflags & " --hints:off -r " & source
    styled_echo fgCyan, "testing " & source
    const opts = {poUsePath, poDaemon, poStdErrToStdOut, poEvalCommand}  
    var process = start_process(cmd, "", [], nil, opts)
    for line in process.lines:
      if line.len > 0:
        echo line
    exitcode = process.peek_exit_code()
    process.close()
    if exitcode == 0:
      styled_echo fgGreen, "\u2713\e", fgCyan, " done testing " & source
      successful.inc
      code = 0
    else:
      styled_echo fgRed, "\u2717\e", fgCyan, " done testing " & source
      failed.inc
      code = exitcode
    
proc print_test_results(sources: TableRef[string, int], successful, failed: var int) =
  var 
    length = sources.len
    i = 1
  styled_echo fgWhite, "\ntestmyway has finished running " & $length & " test(s)"
  for source, code in sources.mpairs:
    if code == 0:
      styled_echo fgWhite, $i & ". " & source, fgGreen, " successful"
    else:
      styled_echo fgWhite, $i & ". " & source, fgRed, " failed"
    i.inc
  styled_echo fgGreen, "\n" & $successful & "/" & $length & " test(s) were successful\n", fgRed, $failed & "/" & $length & " test(s) failed\n"

when is_main_module:
  proc main() =
    if param_count() == 0:
      styled_echo fgRed, "testmyway <matches> <any-extra-compiler-flags>"
      return
    var 
      matches = param_str(1)
      sources = grab_sources(matches)
    if sources.len == 0:
      styled_echo fgRed, "no testable nim files matching '" & matches & "' found"
      return
    
    var 
      extraflags = ""
      successful = 0
      failed = 0
    if param_count() > 2:
      for i in 3..param_count() - 1:
        extraflags.add(param_str(i))
    sources.run_tests(extraflags, successful, failed)
    sources.print_test_results(successful, failed)
  main()
