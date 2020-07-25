(import-macros {: append} :tools.belt_macros)

(local traversal (require :lister.things.traversal))

(lambda adopt! [new-parent new-child]
  "Makes `new-child` a child of `new-parent`."
  (when (not new-parent.children)
    (tset new-parent :children []))
  (append new-parent.children new-child)
  (tset new-child :parent new-parent))

(lambda append-at-path! [root path thing]
  "Appends `thing` as a child of the thing at `path` in `root`."

  (let [parent (root:lookup path)]
    (adopt! parent thing)))

(lambda index-of-child [parent child ?i]
  "Returns the index of `child` in `parent`'s children."

  (let [i (or ?i 1)]
    (when (and parent.children (>= (length parent.children) i))
      (if (= child (. parent.children i))
        i
        (index-of-child parent child (+ i 1))))))

(lambda remove-child-by-index! [parent index]
  "Removes the child at `index` in `parent`."

  (let [child (table.remove parent.children index)]
    (tset child :parent nil)

    ; Reset positional data on now-orphaned family tree.
    (traversal.unpopulate_paths child)

    ; Reset positional data on parent's children, which may have changed
    ; position after their sibling's removal.
    (traversal.populate_paths parent)

    child))

(lambda remove-at-path! [root path]
  "Removes the thing at `path` in `root`."
  (let [(parent [index]) (root:lookup path 1)]
    (remove-child-by-index! parent index)))

(lambda prune! [item]
  "Removes an item from its parent's children."
  (let [parent item.parent
        index (index-of-child parent item)]
    (remove-child-by-index! parent index)))

{: adopt!
 : append-at-path!
 : remove-at-path!
 : prune!}
