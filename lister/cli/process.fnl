(import-macros {: append} :tools.belt_macros)
(local {: keys-sorted} (require :tools.belt))

(local taskpaper (require :taskpaper))
(local filer (require :taskpaper.filer))
(local things (require :lister.things))
(local mutation (require :lister.things.mutation))
(local traversal (require :lister.things.traversal))

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

(lambda specialized-action [action target ?context]
  "Takes an action and returns an action whose `perform` field is
  partially applied to `target` and `?context`."
  (let [ret {}
        mt {:__index action}]
    (when action.perform
      (tset ret :perform (partial action.perform target ?context)))
    (setmetatable ret mt)
    ret))

(lambda applicable-actions [target ?context]
  (local result {})
  (each [key action (pairs actions)]
    (if
      (not action.applies-to?)
      (tset result key (specialized-action action target ?context))

      (action.applies-to? target)
      (tset result key (specialized-action action target ?context))))
  result)

(lambda save! [target]
  "Writes the file that contains `target`."
  (filer.write (things.root-of target)))

(lambda skip-thoroughly [item skip]
  "Marks `item` and its children as using the given `skip` function."
  (skip item)
  (when item.children
    (each [_ child (ipairs item.children)]
      (skip child))))

(lambda edit [target {: visited!}]
  (local editor (or (os.getenv :LISTER_EDITOR)
                    (os.getenv :EDITOR)))
  (when (not editor)
    (error "Neither $EDITOR nor $LISTER_EDITOR is set"))

  (local filename (os.tmpname))

  (filer.write_to_file target filename)
  (os.execute (string.format "%s %s" editor filename))
  (let [replacement (taskpaper.load_file filename)]
    (print (taskpaper.format replacement))
    (let [ok? (yes-or-no? "Use this as replacement?")]
      (if ok?
        (let [root (things.root-of target)]
          (os.remove filename)
          (skip-thoroughly replacement visited!)
          (mutation.replace! target replacement)
          (filer.write root)
          true)
        (do
          (os.remove filename)
          ;; TODO: might be nice if you could edit your thing again.
          ;; Let's see if this becomes a problem; in theory the edits
          ;; you make shouldn't be very large.
          false)))))

(lambda mark-done [target]
  (target:set-tag! :done (os.date "%Y-%m-%d"))
  (save! target))

(lambda skip-project [target {: visited!}]
  (skip-thoroughly target visited!)
  true)

(set actions
  {:n {:name :next
       :desc "process next thing in traversal order, which may be a child of this"}
   :q {:name :quit
       :desc "do nothing else; quit immediately"
       :perform (fn []
                  (print "Quitting.")
                  (os.exit 0))}
   :e {:name :edit
       :desc "open in $EDITOR and replace with results"
       :perform edit}
   :d {:name :done
       :desc "mark this as done"
       :applies-to? #(= $1.kind :task)
       :perform mark-done}
   :s {:name :skip
       :desc "skip all remaining children of this project"
       :applies-to? #(= $1.kind :project)
       :perform skip-project}})

(lambda explain [choices]
  "Prints an explanation of the given choices."
  (each [_ key (ipairs (keys-sorted choices))]
    (print key (. choices key :name) (. choices key :desc)))
  (print)
  false)

(lambda read-choice [choices]
  "Prompts the user to choose one of `choices`, then runs it if possible.

  `choices` is a table mapping single-character strings to choice tables.

  Something like:
      {:a {:name :choice-a
           :desc \"choose a\"
           :perform (fn [] (print \"you chose a!\"))}
       :b {:name :choice-b
           :desc \"choose b\"}}

  For this case, it would prompt the user:

      What would you like to do? [a,b,?]

  Where entering 'a' or 'b' calls the `perform` function associated with
  that choice, if any, and entering '?' will cause it to print a listing
  of the choices."
  (local choice-keys (keys-sorted choices))
  (table.insert choice-keys :?)

  (io.write
    (string.format "What would you like to do? [%s] "
                   (table.concat choice-keys ",")))

  (let [input (io.read :l)
        choice (. choices input)]
    (if
      choice
      (when choice.perform
        (let [continue? (choice.perform)]
          (when (not continue?)
            (read-choice choices))))

      (= input :?)
      (do
        (explain choices)
        (read-choice choices))

      (do
        (when input
          (print input "is not a valid choice." "Try again."))
        (read-choice choices)))))

(lambda process [{: file}]
  (local tree (taskpaper.load_file file))
  (local visitor (traversal.visitor tree))

  (each [item visitor.visit]
    (when (not (or (things.rooted? item)
                   (and (= item.kind :note)
                        item.parent
                        (= item.parent.kind :task))))
      (print (taskpaper.format item))
      (read-choice (applicable-actions item {:visited! visitor.visited!})))))

process
