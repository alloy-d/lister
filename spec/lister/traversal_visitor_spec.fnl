(import-macros {: context : test} :spec.busted_macros)

(local traversal (require :lister.things.traversal))

(local taskpaper (require :taskpaper))
(local examples (require :spec.taskpaper.examples))

(local {: assert-basically-same} (require :spec.helpers))

(macro example-chunk []
  `(taskpaper.parse examples.chunk))

(context "visiting"
  (test "visits all items in depth-first-order"
    (let [chunk (example-chunk)
          crawler (traversal.crawl chunk)
          visitor (traversal.visitor chunk)]
      (each [thing visitor.visit]
        (assert.equal (crawler) thing))))

  (test "skips items that have been marked as visited"
    (let [chunk (example-chunk)
          visitor (traversal.visitor chunk)
          note (chunk:look-up ":3:4")]
      (visitor.visited! note)
      (each [thing visitor.visit]
        (assert.not_equal note thing "the note we marked is not returned"))))

  (test "skips a branch if its base has been marked as visited"
    ;; Even the root:
    (let [chunk (example-chunk)
          visitor (traversal.visitor chunk)]
      (visitor.visited! chunk)
      (assert.nil (visitor.visit) "visit returns nothing if the root is marked as visited"))

    (let [chunk (example-chunk)
          visitor (traversal.visitor chunk)
          subproject (chunk:look-up ":3:6")]
      (visitor.visited! subproject)
      (each [item visitor.visit]
        (assert.not_equal ":3:6" (string.sub item.path 1 4)
                          "visited item is not subproject or one of its children"))))

  (context "while mutating"
    (test "continues visitation as normal if an item is removed when seen"
      (let [chunk (example-chunk)
            crawler (traversal.crawl (example-chunk))
            visitor (traversal.visitor chunk)
            note-target (. chunk :children 2)
            task-target (. chunk :children 3 :children 1)]

        (each [item visitor.visit]
          (assert-basically-same (crawler) item)
          (when (or (= item note-target) (= item task-target))
            (item:prune!)))))

    (test "does not visit an item's children if it's removed when seen"
      (let [chunk (example-chunk)
            visitor (traversal.visitor chunk)
            project-target (. chunk.children 3)]

        (each [item visitor.visit]
          (when (= item project-target)
            (item:prune!))
          (assert.not_equal project-target item.parent
                            "children of target project are not visited"))))

    (test "continues visitation on the original tree if an item is moved when seen"
      (let [chunk (example-chunk)
            other-chunk (example-chunk)
            visitor (traversal.visitor chunk)
            target (. chunk.children 3)]

        (each [item visitor.visit]
          (assert.false (traversal.reachable? item other-chunk)
                        "visited item is not part of the tree the target was moved to")
          (when (= item target)
            (item:prune!)
            (other-chunk:adopt! item)
            (assert.false (traversal.reachable? item chunk)
                          "target item is no longer reachable from the visited tree")))))))
