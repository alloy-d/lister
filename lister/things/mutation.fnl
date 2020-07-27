(import-macros {: append} :tools.belt_macros)

(local traversal (require :lister.things.traversal))

(macro reparent! [new-child new-parent]
  "Does the extra bookkeeping required to register `new-child` as a child of `new-parent`."
  `(tset ,new-child :parent ,new-parent))

(lambda adopt! [new-parent new-child]
  "Makes `new-child` a child of `new-parent`.
  If `new-child` is a root, instead adopts its children."
  (when (not new-parent.children)
    (tset new-parent :children []))

  (if (new-child:rooted?)
    (each [_ child (ipairs new-child.children)]
      (adopt! new-parent child))
    (do
      (append new-parent.children new-child)
      (reparent! new-child new-parent))))

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
    (traversal.unset-paths! child)

    ; Reset positional data on parent's children, which may have changed
    ; position after their sibling's removal.
    (traversal.update-paths! parent)

    child))

(lambda replace! [item new-item]
  "Replaces `item` in its parent's tree with `new-item`.
  If `new-item` is a root, splices its children in place of `item`."
  (let [parent item.parent
        index (index-of-child parent item)]
    (if (new-item:rooted?)
      (do
        ;; Move the following children to make room for the new ones.
        (table.move parent.children
                    (+ index 1)
                    (length parent.children)
                    (+ index (length new-item.children)))
        ;; Insert the new children.
        (each [i child (ipairs new-item.children)]
          (tset parent.children (+ index (- i 1)) child)
          (reparent! child parent))
        ;; Edge case: root was empty, and we have simply removed a child.
        (when (= 0 (length new-item.children))
          (table.remove parent.children)))
      (do
        (tset parent.children index new-item)
        (reparent! new-item parent)))))

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
 : replace!
 : prune!}
