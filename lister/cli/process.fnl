(import-macros {: append} :tools.belt_macros)
(local {: read-choice : yes-or-no?} (require :tools.ui))

(local taskpaper (require :taskpaper))
(local filer (require :taskpaper.filer))
(local things (require :lister.things))
(local mutation (require :lister.things.mutation))
(local traversal (require :lister.things.traversal))

;; Some helpers:
(lambda save! [target]
  "Writes the file that contains `target`."
  (filer.write (things.root-of target)))

(lambda skip-thoroughly [item skip]
  "Marks `item` and its children as using the given `skip` function."
  (skip item)
  (when item.children
    (each [_ child (ipairs item.children)]
      (skip child))))


;; Actions and action management:
(var actions nil)

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

(lambda edit [target {: visited!}]
  "Opens `target` in $LISTER_EDITOR or $EDITOR, and replaces it with the
  results.  Marks everything in the replacement as visited, so it will
  not be further processed.

  Saves the processed file after doing the replacement."
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
  "Marks an item as done.  Writes the processed file afterward."
  (target:set-tag! :done (os.date "%Y-%m-%d"))
  (save! target))

(lambda skip-project [target {: visited!}]
  "Marks a project and all its children as visited."
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
