(local argparse (require :argparse))
(local taskpaper (require :taskpaper))
(local {:write write!} (require :taskpaper.filer))

(local {: parse_path : filter} (require :lister.things.traversal))

(local {: find_files} (require :lister.finding))

(local things (require :lister.things))
(local mutation (require :lister.things.mutation))
(local tagging (require :lister.things.tagging))

(local {: adopt! : prune!} mutation)
(local {: has-tag? : set-tag!} tagging)

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
  (.. (table.concat (table.pack ...) "\n\n") "\n\n"))

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
  (local {: tag
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
             (each [item (filter root #(has-tag? $1 tag))]
               (show item))
             (when show-filenames? (print))))

(lambda prune [dir {: tag :archive archive-name}]
  "Move all the things with `tag` under `dir` to the file `archive`."
  (print "pruning" tag archive-name)

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
      (print "writing changed file" file)
      (write! file)))

  (each-root [root dir]
             (when (not= root.name archive-name)
               (each [item (filter root #(has-tag? $1 tag))]
                 (print "moveable" (taskpaper.format item))
                 (append moveable item))))

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
              (help "Prune files by moving tagged (`done`, by default) items to the archive."))]
  (-> "archive"
      (prune:argument "The file to move pruned items into.")
      (: :args 1))

  (-> "-t --tag"
      (prune:option "Prune items with this tag.")
      (: :args 1)
      (: :default "done")))

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

(let [ft (parser:command
           "find-tagged ft"
           (help "Print the things with a given tag."))]
  (-> "tag"
      (ft:argument "The tag to check for.")
      (: :args 1))

  (-> "-f --show-filenames"
      (ft:option "Print tasks grouped by filename.")
      (: :args 0))
  (-> "-p --show-paths"
      (ft:option "Show path for each thing.")
      (: :args 0)))

(let [args (parser:parse)
      dir (. args :dir)]
  (match (. args :command)
    "find-tagged" (find_tagged dir args)
    "format" (format args)
    "list-files" (list_files dir)
    "list-projects" (list_projects dir args)
    "prune" (prune dir args)
    "show" (show args)))

