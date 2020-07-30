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

(lambda reachable? [sought-thing starting-point]
  "Is `sought-thing` reachable from `starting-point`?"
  (let [get-thing (crawl starting-point)]
    (do
      (var a-thing (get-thing))
      (while (and a-thing (not= a-thing sought-thing))
        (set a-thing (get-thing)))
      (if a-thing true false))))

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

(lambda visitor [thing]
  "Returns a table that can be used to iterate over a tree while it's
  being mutated, with fine-grained control.

  The table contains two functions: `visit` and `visited!`.

  `visit` is suitable for using in a generic `for`; it will produce
  `thing` and its children in depth-first order.  It will exhaustively
  produce everything in the tree, even in spite of most kinds of
  mutations to the tree during the session.  The only kind of mutation
  that is *not* supported is changing the parent of an ancestor of the
  item most recently produced: this will work, but will result in an
  exhaustive traversal of the *new* family tree as well.

  Changing the *parent* field of the most recently produced item is OK
  and will not disrupt the traversal.

  Using the `visited!` function, you can mark an item as already
  visited, to prevent it being returned by `visit`.  Items are marked as
  visited when they are returned by `visit`.  If `visit` encounters an
  item that has been marked as visited, it will neither return it nor
  continue to its children.  Therefore, marking an item as visited
  *before* receiving it from `visit` is sufficient to prevent and or its
  children from ever being returned, but if you want to skip an item's
  children once you've received the item, you'll need to mark them all
  as visited."

  (local visited {})
  (local known-parents {})

  (lambda visited! [item]
    "Marks an item as visited."
    (tset visited item true))

  (lambda visited? [item]
    "Checks if we have already visited an item."
    (. visited item))

  (lambda unvisited? [item]
    (not (visited? item)))

  (lambda next-unvisited-child [item ?index]
    "Returns the next child of `item` that has not been visited."
    (local index (or ?index 1))
    (when (and item.children (>= (length item.children) index))
      (let [child (. item.children index)]
        (if
          (unvisited? child) child

          (next-unvisited-child item (+ index 1))))))

  (lambda next-unvisited [item ?parent]
    "Returns the next unvisited item after `item`.
    First checks children of `item`, then checks children of `?parent`,
    which defaults to `item.parent`.

    `?parent` is provided separately to handle the case where `item` has
    been (re)moved since we got to it.  However, we don't support the
    case where `?parent` has *also* been moved since we saw `item`."
    (local parent (or ?parent item.parent))
    (or
      (next-unvisited-child item)
      (when parent
        (next-unvisited parent))))

  (fn prepare-and-visit! [item]
    "Does the bookkeeping required for visiting `item`, then returns it."
    (when item
      (tset known-parents item item.parent)
      (visited! item)
      item))

  (fn visit [_ ?previous]
    (if
      (not ?previous)
      (when (not (visited? thing))
        ;; Start traversing if the root hasn't already been visited.
        ;; This would only happen if the root has been marked as visited
        ;; before visiting started.  Unclear if that would happen
        ;; outside of a test case.
        (prepare-and-visit! thing))

      (let [known-parent (. known-parents ?previous)
            up-next (next-unvisited
                      ;; If the previous thing is no longer part of the
                      ;; tree, don't bother with its children.
                      (if (reachable? ?previous thing) ?previous {})
                      known-parent)]
        (prepare-and-visit! up-next))))

  {:visited! visited!
   :visit visit})

{: crawl
 : filter
 : filtered
 : look-up
 : parse-path
 : reachable?
 : update-paths!
 : unset-paths!
 : visitor}
