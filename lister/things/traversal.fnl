(import-macros {: append} :tools.belt_macros)

(lambda parse-path [path-string]
  "Turn a serialized path (separated by ':') into a sequence."
  (let [path []]
    (each [part (path-string:gmatch "[^:]+")]
      (append path (or (tonumber part) part)))
    path))

(lambda lineage-including-thing [thing]
  "Returns the lineage (sequence of named things' names) down to and including `thing`."
  (let [lineage (if thing.parent
                  (lineage-including-thing thing.parent)
                  [])]
    (when thing.name
      (append lineage thing.name))

    lineage))

(lambda update-paths! [thing]
  "Populate the cached `path` field on `thing` and its children."
  ;; General approach:
  ;;    1. if we don't know this thing's path, tell its parent to
  ;;       update its children's paths.
  ;;    2. populate this thing's children's paths.
  ;;
  ;; Eventually, we'll get down to a file, which has a file path.
  (when (not thing.path)
    (update-paths! thing.parent))

  (each [i child (ipairs thing.children)]
    (doto child
          (tset :path (.. thing.path ":" i))
          (tset :lineage (lineage-including-thing thing)))))

(lambda unset-paths! [thing]
  "Unpopulate a thing's path and its children's paths."
  (doto thing
        (tset :path nil)
        (tset :lineage nil))

  (when thing.children
    (each [_ child (ipairs thing.children)]
      (unset-paths! child))))

(lambda look-up [thing maybe-unparsed-path ?leave-untraversed-count]
  (local leave-untraversed-count (or ?leave-untraversed-count 0))
  (var path maybe-unparsed-path)

  (when (= (type maybe-unparsed-path) :string)
    (set path (parse-path maybe-unparsed-path)))

  (if
    (= (length path) leave-untraversed-count)
    (values thing path)

    (< (length path) leave-untraversed-count)
    (values nil nil
            (string.format "path is not long enough to leave %d steps untraversed" leave-untraversed-count))

    (look-up (. thing.children (. path 1))
             (table.move path 2 (length path) 1 {})
             leave-untraversed-count)))

(lambda crawler [thing]
  "Returns a function that yields thing and its descendants in depth-first order."
  (fn []
    (coroutine.yield thing)
    (when thing.children
      (each [_ child (ipairs thing.children)]
        ((crawler child))))))

(lambda crawl [thing]
  "Returns a function that returns thing and its descendants in depth-first order.
  Suitable for use as an iterator in a generic for."
  (let [co (coroutine.create (crawler thing))]
    (fn []
      (local (_ res) (coroutine.resume co))
      res)))

(lambda filtered [test iterator]
  "Takes an `iterator` (an iterator that takes nil arguments and
  produces one value, e.g. the result of `crawl`) and returns a similar
  function that returns only items from `iterator` that pass `test`."
  (fn []
    (do
      (var item (iterator))
      (while (and (not= nil item) (not (test item)))
        (set item (iterator)))
      item)))

(lambda filter [thing test]
  "Returns a function that returns whatever of thing and its descendents
  pass `test`, in depth-first order."
  (filtered test (crawl thing)))

{: crawl
 : filter
 : filtered
 : look-up
 : parse-path
 : update-paths!
 : unset-paths!}
