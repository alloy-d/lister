(local argparse (require :argparse))
(local taskpaper (require :taskpaper))
(local parse_path (. (require :lister.things.traversal) :parse_path))

(local {: find_files} (require :lister.finding))

(local {: map : reverse : drop} (require :tools.belt))
(import-macros {: append} :tools.belt_macros)

(lambda help [...]
  "Formats LINES as help text."
  (.. (table.concat (table.pack ...) "\n\n") "\n\n"))

(lambda format_single_file [file ?in_place]
  "Loads and pretty-prints a file.  If `?in_place` is true, overwrites file."
  (let [tree (taskpaper.load_file file)]
    (lambda write_in_place []
      (let [f (io.open file "w")]
        (f:write (taskpaper.format tree))
        (f:close)))
    (lambda write_to_stdout []
      (print (.. (. tree :path) ":\n"))
      (print (taskpaper.format tree 1))
      (print "\n"))

    (if ?in_place
      (write_in_place)
      (write_to_stdout))))

(lambda format [args]
  "Loads and pretty-prints each file in `args.file`."
  (let [files (. args :file)
        in_place (or (. args :in_place) false)]
    (each [_ file (ipairs files)]
      (format_single_file file in_place))))

(lambda list_files [dir]
  "Print all relevant files under `dir`."
  (each [_ file (ipairs (find_files dir))]
    (print file)))

(lambda list_projects [dir args]
  "Print all relevant projects under `dir`, along with any requested metadata."

  (lambda fields [project]
    (let [data []]
      (when (. args :show_paths)
        (append data (. project :path)))
      (append data (. project :name))
      (when (. args :show_lineage)
        (append data (table.concat (reverse (. project :lineage)) "<-")))
      (table.unpack data)))

  (let [files (find_files dir)
        roots (map taskpaper.load_file files)]
    (when (. args :show_header)
      (print (fields {:path "Path"
                      :name "Project"
                      :lineage ["Lineage"]})))

    (each [_ root (ipairs roots)]
      (each [item (root:crawl)]
        (when (= :project (. item :kind))
          (print (fields item)))))))

(lambda show [args]
  "Show thing(s) at `args.path`."
  (let [paths (map parse_path (. args :path))
        show_lineage? (. args :show_lineage)
        file_cache {}]

    (lambda load [filename]
      (when (not (. file_cache filename))
        (tset file_cache filename (taskpaper.load_file filename)))
      (. file_cache filename))

    (each [_ path (ipairs paths)]
      (let [file (load (. path 1))
            path_in_file (drop 1 path)
            item (file:lookup path_in_file)]
        (when show_lineage?
          (print (table.concat item.lineage " -> ") "\n"))
        (print (item:totaskpaper))))))

(local parser
  (-> (argparse)
      (: :name "lister")
      (: :description "List management.")
      (: :command_target "command")))

(parser:option
  "-d --dir"
  "The root directory to search within."
  (os.getenv "HOME"))

(-> (parser:command
      "list-files lsf"
      (help "List the files that would be searched for projects and tasks."
            "Uses $HOME by default, but can be changed with --dir.")))

(let [lsp (parser:command
            "list-projects lsp"
            (help "List all projects."))]
  (-> "-h --show-header"
      (lsp:option "Print a header as the first line.")
      (: :args 0))
  (-> "-p --show-paths"
      (lsp:option "Show paths in addition to project names.")
      (: :args 0))
  (-> "-l --show-lineage"
      (lsp:option "Also show lineage (human-readable paths).")
      (: :args 0)))

(let [prune (parser:command
              "prune"
              (help "Prune a file by moving done items to the archive."))]
  (-> "file"
      (prune:argument "The file(s) to prune.")
      (: :args :+)))

(let [show (parser:command
             "show"
             (help "Show something (or some things)."
                   "\"Something\" can be a file, or an item within a file, specified by its path."
                   "For example:"
                   "  `show ~/todo.taskpaper:2` will show the second thing in ~/todo.taskpaper"
                   "  `show ~/todo.taskpaper:2:1` will show the second thing in that thing, &c."))]
  (-> "path"
      (show:argument "The path to the thing(s) to show.")
      (: :args :+))
  (-> "-l --show-lineage"
      (show:option "Print lineage above each thing.")
      (: :args 0)))

(let [fmt (parser:command
            "format fmt"
            (help "Print the given file(s) with automatic formatting."
                  "Writes to standard out by default, but can format the file in-place with -i."))]
  (-> "file"
      (fmt:argument "The taskpaper file to format.")
      (: :args :+))
  (-> "-i --in-place"
      (fmt:option "Rewrite the file instead of printing to stdout.")
      (: :args 0)))

(let [args (parser:parse)
      dir (. args :dir)]
  (match (. args :command)
    "format" (format args)
    "list-files" (list_files dir)
    "list-projects" (list_projects dir args)
    "show" (show args)))

