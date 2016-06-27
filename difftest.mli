(** Diff testing tool.

    This tool runs a simple diff test. Test cases are all .bean source files in
    a given test directory. These test cases are compiled and the output of
    that compilation is diffed with the respective
    test-dir/expected/[testcase-name].exp to determine if the test was a
    success or not. In case of errors, a ERRS file is created containing a
    verbose diff result of all failed tests.

    The tool also contains functionality to update the expected cases on prompt
    if it is known that the diff results are correct.

    @author: Rishi <ashutoshrishi92@gmail.com>
*)

(** Represent the results of running a diff test *)
type test_result =
  | Success | Mismatch of string | NoExpected | NoOut

(** Accumulate the lines in a [in_channel]. *)
val channel_output : in_channel -> string list

(** [get_test_files dir] collects all the .bean files in the [dir]. *)
val get_test_files : string -> string list

(** [diff f1 f2] calls the `diff' Unix command on the files [f1] [f2]
    and interprets the exit value of the call as a [test_result]. *)
val diff : string -> string -> test_result

(** [run_tests test_dir bean_exec] interprets all .bean files in the
    [test_dir] as a test case and runs a diff test on them by diffing
    the output of compiling the test case with [bean_exec] with the expected
    output in the [test_dir]/expected directory. *)
val run_tests : bool -> string -> string -> unit
