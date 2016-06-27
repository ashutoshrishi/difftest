# DiffTesting

This is a simple testing utility which using the `diff` tool. This tests the
stdout output of running an executable on an input file, by comparing it with
an expected output file. 


**NOTE:** Requires `diff` and `dwdiff`.


The executable specified is run on all the source files in the specified
`test-cases` directory, creating a `%.out` file for each test case. Every
test-case has it's expected output file `%.exp` in the `test-cases/expected`
directory. Both the `%.out` and `%.exp` files are *diffed* and the result of
this generates the test results. 


Diffing can be done using the usual `diff` tool or the better `dwdiff`
tool. `dwdiff` allows more flexibility in terms of ignoring the
whitespace. This option is hard-coded but should be opened up in the interface
down the road. 


Mismatches can be updated automatically on a prompt. If the `difftest` tool is
invoked to run an *update* it will use a coloured `dwdiff` output to ask if the
additions/deletions in the *expected* file is OK. On answering *yes* it will
update the *expected* file with the *output* file.


Currently `difftest` is very local and specific to testing the outputs of a toy
compiler, so a lot of the options are hard coded (like the file extensions it
considers as a test-cases and the invocation of the executable on these
files). 



# TODO
o Make `difftest` more versatile to every scenario by using a config file


