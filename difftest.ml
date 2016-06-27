open Filename

(* Globals oh-no *)
let expected_dir = "expected/"
let test_dir = ref "./test-cases/"
let bean_exec = ref "./bean"
let ask_update = ref false

(** Represent the results of running a diff test *)
type test_result =
  | Success | Mismatch of string | NoExpected | NoOut


(** Replace suffix of the filename [file]. *)
let replace_suffix file suff_old suff_new =
  if check_suffix file suff_old
  then (chop_suffix file suff_old) ^ suff_new
  else file ^ suff_new


(** Helper to check for null list *)
let null_list = function
  | _ :: _ -> false
  | _ -> true


(** Pad with ANSI escape sequences to color [str] green on terminal. *)
let color_green str = "[32m" ^ str ^ "[39m"


(** Pad with ANSI escape sequences to color [str] red on terminal. *)
let color_red str = "[31m" ^ str ^ "[39m"


(** Bold ANSI escape sequence *)
let bold str = "\x1b[1m" ^ str ^ "\x1b[0m"


let success () = print_string (color_green ".")


let failure () = print_string (color_red "X")


(** Header printing *)
let wrap_with char str =
  (String.make 70 char) ^ "\n" ^ str  ^ "\n" ^ (String.make 70 char)


(** Get valid bean source code files from the [test_dir]. *)
let get_test_files test_dir =
  let add_test_dir x = test_dir ^ x in
  let all_files = Array.to_list (Sys.readdir test_dir) in
  let is_bean f = check_suffix f ".bean" in
  List.map add_test_dir (List.filter is_bean all_files)


(** Check and return the expected output file in the expected dir
    for the given [test_file], if it exists. *)
let expected_output_for test_file =
  if check_suffix test_file ".bean"
  then
    let only_file = replace_suffix (basename test_file) ".bean" ".exp" in
    let expected = (dirname test_file) ^ "/" ^ expected_dir ^ only_file in
    if Sys.file_exists expected
    then Some expected
    else None
  else None


(** Compile the given bean [test_file], creating a .out file for the
    test, iff the compilation exits normally. *)
let compile_test bean_exec test_file =
  let out_file = (dirname test_file) ^ "/" ^
                 (replace_suffix (basename test_file) ".bean" ".out") in
  let compileCommand = bean_exec ^ " " ^ test_file ^ " >" ^ out_file in
  if (Sys.command compileCommand) == 0
  then Some out_file
  else None


(** In the absence of Core, flush an in_channel as a list of lines. *)
let channel_output inch =
  let lines = ref [] in
  try
    while true; do
      lines := input_line inch :: !lines
    done; !lines
  with End_of_file ->
    close_in inch;
    List.rev !lines


(** Run the Unix diff on given files, resulting in a Success (matching) or
    a MisMatch. *)
let diff file1 file2 =
  (* let call_diff = "dwdiff -3 -c -d '()<>~!@:?.%#' " in *)
  let call_diff = "diff -w " in
  let diffOut = Unix.open_process_in (call_diff ^ file1 ^ " " ^ file2) in
  match channel_output diffOut with
  | [] -> Success
  | diffs -> Mismatch (String.concat "\n" diffs)


(** Compile the test file, collect result in .out version, and diff with
    the expected output to generate a test_result *)
let run_test bean_exec test_file =
  match compile_test bean_exec test_file with
  | Some output ->
    (match expected_output_for test_file with
     | Some expected ->
       let df = diff expected output in
       (match df with
        | Success -> success ()
        | _ -> failure ());
       (test_file, df)
     | None -> failure (); (test_file, NoExpected))
  | None -> failure (); (test_file, NoOut)


(** Pretty printing test result. *)
let print_test ?(oneline=false) (test_file, result) =
  Printf.printf ("%% \x1b[1mTEST:\x1b[0m %-30s --> ") (basename test_file);
  (match result with
   | Success -> print_endline (color_green "SUCCESS")
   | Mismatch (diff_result) ->
     print_endline (color_red "MISMATCH") ;
     if (oneline = false)
     then (print_endline (wrap_with '-' diff_result) ; print_endline "")
   | NoExpected -> print_endline (color_red "MISSING Expected output")
   | NoOut -> print_endline (color_red "ERROR in compilation."))


(** Write the [tests] results to a [error_file] ellaborating on the errors. *)
let write_error_file error_file tests =
  let error_repr (test_file, result) =
    (match result with
     | Mismatch diff_result ->
       (Printf.sprintf "%s --- MISMATCH\n" test_file) ^ diff_result
     | NoExpected -> Printf.sprintf "%s --- NO EXPECTED FILE FOUND" test_file
     | NoOut -> Printf.sprintf "%s --- COMPILATION ERROR" test_file
     | _ -> "")
    ^ "\n" ^ String.make 80 '=' ^ "\n\n" in
  let content = List.fold_left (^) "" (List.map error_repr tests) in
  let err_chan = open_out error_file in
  output_string err_chan content ;
  close_out err_chan


(** Copy the contents of [output] to [expected] to update the expected
    output. *)
let update_exp expected output =
  let copy_comm = "cp " ^ output ^ " " ^ expected in
  let cp_proc = Unix.open_process_in copy_comm in
  match Unix.close_process_in cp_proc with
  | Unix.WEXITED 0 -> print_endline "Updated expected output."
  | _ -> print_endline "Error: Could not update expected output."


(** Display a y/n prompt while displaying the difference in [output] and
    [expected] files, to update the expected output or not.
    REQUIRES dwdiff to be present on the system. *)
let update_prompt test_file =
  let output = replace_suffix test_file ".bean" ".out" in
  let only_file = replace_suffix (basename test_file) ".bean" ".exp" in
  let expected = (dirname test_file) ^ "/" ^ expected_dir ^ only_file in
  let call_diff = "dwdiff -c -d '()<>~!@:?.%#' " in
  let is_yes s = s = "y" || s = "Y" in

  (* If expected file does not exist, create an empty file. *)
  if not (Sys.file_exists expected)
  then (let ch = open_out expected in output_string ch ""; close_out ch);

  print_endline ("TEST: " ^ output ^ ":\n");
  (match diff expected output with
   | Mismatch _ ->
     begin
       let dw_chan = Unix.open_process_in
           (call_diff ^ expected ^ " " ^ output) in
       match channel_output dw_chan with
       | [] -> print_endline "ERROR in diff. "
       | cons -> (print_endline (String.concat "\n" cons);
                  print_endline "\nIs the green text ok? (y/n): ";
                  let ans = input_line stdin in
                  if is_yes ans then update_exp expected output)
     end
   | _ -> print_endline "Nothing to update.");
  print_endline ((String.make 70 '-') ^ "\n")



let test_is_error = function
  | (_,Success) -> false
  | _ -> true


(** Run the bean source code file tests. *)
let run_tests update test_dir bean_exec =
  print_endline (String.make 70 '-') ;
  let test_files = (get_test_files test_dir) in
  let results = List.map (run_test bean_exec) test_files in
  let error_results = List.filter test_is_error results in
  if null_list error_results
  then print_endline (color_green "...ALL TESTS PASSED!")
  else (print_endline (color_red "...SOME TESTS FAILED. See ERRS file.");
        write_error_file "ERRS" error_results) ;
  print_endline (String.make 70 '-') ;
  List.iter (print_test ~oneline:true) error_results;

  if update then
    List.iter (fun (f,_) -> update_prompt f) error_results


(** Accepted beantest arguments. *)
let (speclist:(Arg.key * Arg.spec * Arg.doc) list) =
  [("-t", Arg.String(fun str -> test_dir := str),
    " Folder containing test-cases. ") ;
   ("-e", Arg.String(fun str -> bean_exec := str),
    " The Bean executable. ") ;
   ("-u", Arg.Bool(fun opt -> ask_update := opt),
    " Whether expected files should be prompted to be updated. ")]

let main () =
  (* Parsing command line *)
  Arg.parse speclist
      (fun _ -> print_endline "Unrecognised parameter.")
      "beantest [-t] <test-cases folder> [-e] <compiler executable>" ;
  (* Precheck if the test directory and executable are valid *)
  if Sys.file_exists !bean_exec && Sys.file_exists !test_dir
  then run_tests !ask_update !test_dir !bean_exec
  else print_endline "Incorrect test-cases directory or bean exec."


let _ = main ()
