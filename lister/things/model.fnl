;; The kinds of things we are concerned with are:
;;
;; - Files (or roots, which represent trees not backed by files).
;; - Projects, which group other things (except files).
;; - Tasks, which represent single things to do.
;; - Notes, which are just text.
;;
;; Every thing is part of a tree.
;;
;; Files and projects can contain any combination of projects, tasks,
;; and notes.  Tasks can contain notes.  Notes cannot contain any other
;; thing.
;;
;; A thing can have children.  In our model, any kind of thing can have
;; children except for notes.
;;
;; A thing can have a name.  In our model, projects, files, and tasks
;; have names (a task's name is the task), but notes probably don't.
;;
;; A thing can have tags, and a tag can have values associated with it.
;; In taskpaper, there is no way to associate a tag with anything but
;; a task, so although our model allows other things to have them, this
;; is unlikely to happen (at least as of this writing).

(local mutation (require :lister.things.mutation))
(local tagging (require :lister.things.tagging))
(local traversal (require :lister.things.traversal))

(lambda rooted? [thing]
  "Is this thing a root?"
  (or (= thing.kind :root)
      (= thing.kind :file)))

(lambda named? [thing]
  "Does this thing have a name?"
  (and thing.name true))

(fn index [thing key]
  "Provides some magic for accessing keys that need to be generated."
  (if (and (= key :lineage) (rooted? thing))
    []

    (and (= key :path) (rooted? thing))
    thing.name

    (or (= key :path) (= key :lineage))
    (do
      (traversal.populate_paths thing.parent)
      (. thing key))

    (. (getmetatable thing) key)))

(local thing-metatable
  {:__index index

   :rooted? rooted?

   :crawl traversal.crawl
   :lookup traversal.lookup
   :populate_paths traversal.populate_paths

   :adopt! mutation.adopt!
   :prune! mutation.prune!

   :has-tag? tagging.has-tag?
   :set-tag! tagging.set-tag!
   :remove-tag! tagging.remove-tag!
   })

(lambda bless [thing]
  "Sets the metatable for `thing` and returns it."
  (setmetatable thing thing-metatable)
  thing)

(macro defmaker [kind ...]
  (let [[tblsym] ...]
    `(lambda ,kind [,tblsym]
       ,(.. "Returns a " (tostring kind) " node from the given table.  Mutates its argument.")
       (assert (not (. ,tblsym :kind)) "given table already has a kind")
       ,(select 2 ...)
       (tset ,tblsym :kind ,(tostring kind))
       (bless ,tblsym))))

(defmaker root [tbl])

(defmaker file [tbl]
  (assert tbl.name "file must have a name"))

(defmaker project [tbl]
  (assert tbl.name "project must have a name"))

(defmaker task [tbl]
  (assert tbl.name "task must have a name"))

(defmaker note [tbl]
  (assert (not tbl.children) "note cannot have children"))

(lambda root-of [thing]
  "Returns the root of the tree containing `thing`."

  (if (rooted? thing) thing
    (root-of thing.parent)))

{: rooted?
 : named?
 : bless
 : root-of

 : root
 : file
 : project
 : task
 : note}

