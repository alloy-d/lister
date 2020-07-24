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
(local traversal (require :lister.things.traversal))

(lambda rooted? [thing]
  "Is this thing a root?"
  (not thing.parent))

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

   :crawl traversal.crawl
   :lookup traversal.lookup
   :populate_paths traversal.populate_paths

   :append mutation.append
   :remove mutation.remove
   :prune mutation.prune
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

(lambda tag [name ...]
  {:name name
   :values (when (< 0 (select :# ...)) [...])})

(lambda root-of [thing]
  "Returns the root of the tree containing `thing`."

  (if (rooted? thing) thing
    (root-of thing.parent)))

(fn find-tag [{: tags} tag-name]
  "Checks a given thing for the tag with `tag-name`.

  If not found, returns nil.
  If found, returns true and the table of values."

  (lambda find [tags index]
    (when (and tags (<= index (length tags)))
      (let [tag (. tags index)]
        (if (= tag.name tag-name)
          (values true tag.values)
          (find tags (+ 1 index))))))

  (when tags
    (find tags 1)))

(lambda has-tag? [thing tag-name ?tag-value]
  "Does this thing have `tag-name`, optionally with `?tag-value`?"

  (fn contains-value? [vals index]
    "Does this list of values have the value we're looking for?"
    (if
      (not ?tag-value) true
      (not vals) false
      (> index (length vals)) false
      (= (. vals index) ?tag-value) true
      (contains-value? vals (+ 1 index))))

  (let [(tag vals) (find-tag thing tag-name)]
    (if tag
      (contains-value? vals 1)
      false)))

{: rooted?
 : named?
 : bless
 : has-tag?
 : find-tag
 : root-of

 : root
 : file
 : project
 : task
 : note

 : tag}
