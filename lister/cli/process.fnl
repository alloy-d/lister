(import-macros {: append} :tools.belt_macros)
(local {: keys-sorted} (require :tools.belt))

(local taskpaper (require :taskpaper))
(local filer (require :taskpaper.filer))
(local things (require :lister.things))
(local mutation (require :lister.things.mutation))

(var actions nil)

;; TODO: move to toolbelt.
(lambda yes-or-no? [prompt]
  "Prints `prompt`. Gets a clear \"yes\" or \"no\" from input. Returns true or false."
  (io.write prompt)
  (io.write " [y/n] ")
  (let [input (io.read :l)]
    (if
      (= input :y) true
      (= input :n) false
      (yes-or-no? prompt))))

(lambda applicable-actions [target]
  (local result {})
  (each [key action (pairs actions)]
    (if
      (not action.applies-to?) (tset result key action)
      (action.applies-to? target) (tset result key action)))
  result)

(fn list-actions [target]
  (let [applicable (applicable-actions target)]
    (each [_ key (ipairs (keys-sorted applicable))]
      (print key (. applicable key :name) (. applicable key :desc))))
  (print)
  false)

(fn edit [target]
  (local editor (os.getenv :EDITOR))
  (when (not editor)
    (error "$EDITOR is unset"))

  (local filename (os.tmpname))

  (filer.write_to_file target filename
                       (table.concat
                         [";; vim: ft=taskpaper"
                          (string.format ";; editing chunk in %s" (table.concat target.lineage " -> "))]
                         "\n"))
  (os.execute (string.format "%s %s" editor filename))
  (let [replacement (taskpaper.load_file filename)]
    (print (taskpaper.format replacement))
    (let [ok? (yes-or-no? "Use this as replacement?")]
      (if ok?
        (do
          (os.remove filename)
          (mutation.replace! target replacement)
          (filer.write (things.root-of target))
          true)
        (do
          (os.remove filename)
          ;; TODO: would be nice if you could edit your thing again.
          false)))))

(set actions
  {:s {:name :skip
       :desc "process next thing in traversal order, which may be a child of this"}
   :q {:name :quit
       :desc "do nothing else; quit immediately"
       :perform (fn []
                  (print "Quitting.")
                  (os.exit 0))}
   :e {:name :edit
       :desc "open in $EDITOR and replace with results"
       :perform edit}
   :n {:name :next-project
       :desc "skip all remaining children of this project"
       :applies-to? #(= $1.kind :project)
       :perform (fn []
                  (print "lol, can't actually do this yet"))}
   :? {:name :help
       :desc "describe options"
       :perform list-actions}})

(lambda read-choice [target]
  (local choices (applicable-actions target))
  (local choice-keys (keys-sorted choices))

  (io.write
    (string.format "What would you like to do? [%s] "
                   (table.concat choice-keys ",")))

  (let [input (io.read :l)
        choice (. choices input)]
    (if choice
      (when choice.perform
        (let [continue? (choice.perform target)]
          (when (not continue?)
            (read-choice target))))
      (do
        (when input
          (print input "is not a valid choice." "Try again."))
        (read-choice target)))))

(lambda process [{: file}]
  (local tree (taskpaper.load_file file))

  (each [item (tree:crawl)]
    (print (taskpaper.format item))
    (read-choice item)))

process
