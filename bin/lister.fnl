(local argparse (require :argparse))
(local taskpaper (require :taskpaper))
(local {:write write!} (require :taskpaper.filer))

(local {: parse-path : filter} (require :lister.things.traversal))

(local {: find_files} (require :lister.finding))

(local things (require :lister.things))
(local mutation (require :lister.things.mutation))
(local tagging (require :lister.things.tagging))

(local process (require :lister.cli.process))

(local {: adopt! : prune!} mutation)
(local {: has-tag? : has-any-tag? : set-tag!} tagging)

(local {: map : reverse : drop} (require :tools.belt))
(import-macros {: append} :tools.belt_macros)

(macro each-root [[root-sym dir] ...]
  (assert (> (select :# ...) 0) "body expected")
  `(let [files# (find_files ,dir)
         roots# (map taskpaper.load_file files#)]
     (each [,(sym :_) ,root-sym (ipairs roots#)]
       ,...)))

(lambda help [...]
  "Formats LINES as help text."
  (.. (table.concat (table.pack ...) "\n") "\n"))

(lambda format_single_file [file ?in_place]
  "Loads and pretty-prints a file.  If `?in_place` is true, overwrites file."
  (let [tree (taskpaper.load_file file)]
    (lambda write_in_place []
      (let [f (io.open file "w")]
        (f:write (taskpaper.format tree))
        (f:close)))
    (lambda write_to_stdout []
      (print (.. tree.name ":\n"))
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

(lambda find_tagged [dir args]
  "Print all the things tagged with `args.tag` under `dir`"
  (local {:tag tag-names
          :show_filenames show-filenames?
          :show_paths show-paths?} args)

  (fn show [thing]
    (let [showable []]
      (when show-paths?
        (append showable thing.path))
      (append showable (taskpaper.format thing (if show-filenames? 1 0)))

      (print (table.unpack showable))))

  (each-root [root dir]
    (when show-filenames?
      (print (.. root.name ":")))
    (each [item (filter root #(has-any-tag? $1 tag-names))]
      (show item))
    (when show-filenames? (print))))

(lambda prune [dir {:tag tag-names :archive archive-name :dry_run ?dry-run?}]
  "Move all the things with any of `tag-names` under `dir` to the file
  `archive`."

  (local archive (or (taskpaper.load_file archive-name)
                     (things.file {:name archive-name})))
  (local moveable [])
  (local changed {})

  (lambda changed! [file]
    "Mark `file` as changed, so we save it later."
    (tset changed file true))

  (lambda write-changed! []
    "Save the roots we've marked as changed."
    (each [file (pairs changed)]
      (write! file)))

  (each-root [root dir]
    (when (not= root.name archive-name)
      (each [item (filter root #(has-any-tag? $1 tag-names))]
        (if ?dry-run?
          (print "would archive" (taskpaper.format item))
          (append moveable item)))))

  (each [_ thing (ipairs moveable)]
    (changed! (things.root-of thing))
    (set-tag! thing :lister-archived-from
              (table.concat thing.lineage ", "))
    (prune! thing)
    (adopt! archive thing))

  (when (> (length moveable) 0)
    (let [(ok? err) (write! archive)]
      (if ok?
        (write-changed!)
        (do
          (io.stderr:write (string.format "Couldn't write archive file: %s\n\n" err))
          (io.stderr:write "Leaving other files unchanged.\n")
          (os.exit false))))))

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
      (each [item (filter root #(= $1.kind :project))]
        (print (fields item))))))

(lambda show [args]
  "Show thing(s) at `args.path`."
  (let [paths (map parse-path (. args :path))
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
        (if item
          (do
            (when show_lineage?
              (print (table.concat item.lineage " -> ") "\n"))
            (print (taskpaper.format item)))
          (io.stderr:write (string.format "'%s' not found\n"
                                          (table.concat path ":"))))))))

(local parser
  (-> (argparse)
      (: :name "lister")
      (: :description "List management.")
      (: :help_vertical_space 1)
      (: :command_target "command")))

(parser:group
  "Locating files"
  (->
    (parser:option
      "-d --dir"
      (help "Specifies where to search for files."
            "Used by commands that don't take specific file arguments."
            ""
            "By default, finds files matching *.taskpaper anywhere under the given directory."
            ""
            "If `fd` is on $PATH, it will be used for searching, with the following options:"
            "  - --no-ignore, so that you can taskpaper files in your VCS"
            "  - --hidden, so that you can have taskpaper files in hidden directories"
            ""
            "If ~/.lister-ignore exists, it will be given to fd as an ignore file."
            ""
            "If `fd` is not available, uses a naive invocation of `find`, with no filtering.")
      (os.getenv "HOME"))
    (: :argname "<root-dir>")))

(parser:group
  "Output flags"
  (parser:flag
    "-p --show-paths"
    (help "For commands where it makes sense, include the \"path\" in the output."
          ""
          "Paths are machine-readable locators for things where they are *right now*."
          "Any change to the contents of a file could invalidate its contents' paths."
          ""
          "Examples:"
          "- `~/todo.taskpaper:2` describes the second thing in ~/todo.taskpaper"
          "- `~/todo.taskpaper:2:1` describes the first thing in that thing, &c."))

  (parser:flag
    "-l --show-lineage"
    (help "For commands where it makes sense, include the \"lineage\" in the output."
          "Lineage is the human-sensible analog of path."
          ""
          "Lineage is helpful when a thing is presented without its context."
          ""
          "Lineage is presented differently depending on the command.  For example:"
          "- in `show`, lineage is shown like \"file -> project -> subproject:\""
          "- in `list-projects`, lineage is shown like \"subproject<-project<-file\""
          ""
          "This is done somewhat arbitrarily based on what seems most useful for each command.")))

(parser:group
  "Commands for finding things"

  (-> (parser:command
        "list-files lsf"
        (help "List the files that would be searched for projects and tasks.")))

  (let [lsp (parser:command
              "list-projects lsp"
              (help "List all projects."))]

    (-> "-h --show-header"
        (lsp:flag "Print a header as the first line."))
    lsp)

  (let [ft (parser:command
             "find-tagged ft"
             (help "Print the things with a given tag."))]
    (-> "tag"
        (ft:argument "The tag(s) to check for. If given multiple times, matches any given tag.")
        (: :args :+))

    (-> "-f --show-filenames"
        (ft:flag "Print tasks grouped by filename."))
    ft))

(parser:group
  "Commands for manipulating things"
  (let [prune (parser:command
                "prune"
                (help "Prune files by moving items to an archive file."
                      "Moves items tagged with `done` by default."
                      ""
                      "Considers files following the rules described in the top-level --dir option."
                      "Does *not* consider the given archive file (of course)."
                      ""
                      "If you use more than one archive file, consider using ~/.lister-ignore."))]
    (-> "archive"
        (prune:argument "The file to move pruned items into.")
        (: :args 1))

    (-> "-t --tag"
        (prune:option "Prune items with this tag. If given multiple times, matches any given tag.")
        (: :args :+)
        (: :default [:done :cancelled :moved]))

    (-> "--dry-run"
        (prune:flag "Just print items that would be moved."))
    prune)

  (let [process (parser:command
                  "process"
                  (help "Process a file."))]
    (-> "file"
        (process:argument "The file to process.")
        (: :args 1))
    process))

(parser:group
  "Commands for viewing things"
  (let [show (parser:command
               "show"
               (help "Show something (or some things), specified by path."
                     "See top-level `--show-paths` flag for more details."))]
    (-> "path"
        (show:argument "The path to the thing(s) to show.")
        (: :args :+))
    show)

  (let [fmt (parser:command
              "format fmt"
              (help "Print the given file(s) with automatic formatting."
                    "Writes to standard out by default, but can format the file in-place with -i."))]
    (-> "file"
        (fmt:argument "The taskpaper file to format.")
        (: :args :+))
    (-> "-i --in-place"
        (fmt:flag "Rewrite the file instead of printing to stdout."))
    fmt))

(parser:add_help_command)
(parser:add_complete_command "completion")

(lambda print-help []
  (print (parser:get_help)))

(let [(ok? args) (parser:pparse)
      dir (. args :dir)]
  (if ok?
    (match (. args :command)
      "find-tagged" (find_tagged dir args)
      "format" (format args)
      "list-files" (list_files dir)
      "list-projects" (list_projects dir args)
      "process" (process args)
      "prune" (prune dir args)
      "show" (show args))
    (do
      (print-help)
      (os.exit false))))
