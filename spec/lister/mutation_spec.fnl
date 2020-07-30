(import-macros {: context : test} :spec.busted_macros)

(local taskpaper (require :taskpaper))
(local things (require :lister.things))
(local mutation (require :lister.things.mutation))

(local examples (require :spec.taskpaper.examples))

(local {: assert-basically-same} (require :spec.helpers))
(local {:assert_subtable assert-subtable} (require :spec.taskpaper.helpers))

(macro example-chunk []
  `(taskpaper.parse examples.chunk))

(macro appendable-item []
  `(things.task {:name "test appending"}))

(context "mutation"
  (context "by direct adoption"
    (test "appends"
      (let [chunk (example-chunk)
            project-path ::3
            project (chunk:lookup project-path)
            new-item (appendable-item)
            initial-children-count (length project.children)]

        (mutation.adopt! project new-item)

        (assert.equal (+ 1 initial-children-count) (length project.children)
                      "project has one additional child")
        (assert.same new-item (. project.children (length project.children))
                     "the new item is the project's additional child")
        (assert.same project new-item.parent
                     "the new item's parent is the project")))

    (context "when given a root"
      (fn test-adopting-root [children]
        (test "adopts its children"
          (let [chunk (example-chunk)
                project-path ::3
                project (chunk:lookup project-path)
                last-index (length project.children)
                new-item (things.root {:children children})]
            (mutation.adopt! project new-item)
            (each [i child (ipairs children)]
              (let [expected-index (+ last-index i)]
                (assert.equal (. project.children expected-index) child))))))

      (context "with no children"
        (test-adopting-root []))
      (context "with one child"
        (test-adopting-root [(appendable-item)]))
      (context "with many children"
        (test-adopting-root [(appendable-item) (appendable-item) (appendable-item)])))

    (test "maintains original items"
      (let [chunk (example-chunk)
            project (chunk:lookup ::3)]
        (mutation.adopt! project (appendable-item))
        (assert-subtable examples.chunk_parsed chunk.children))))

  (context "by appending via root"
    (test "appends"
      (let [chunk (example-chunk)
            project-path ::3
            project (chunk:lookup project-path)
            new-item (appendable-item)
            initial-children-count (length project.children)]

        (mutation.append-at-path! chunk project-path new-item)

        (assert.equal (+ 1 initial-children-count) (length project.children)
                      "project has one additional child")
        (assert.same new-item (. project.children (length project.children))
                     "the new item is the project's additional child")
        (assert.same project new-item.parent
                     "the new item's parent is the project")))

    (test "maintains original items"
      (let [chunk (example-chunk)
            project-path ::3]
        (mutation.append-at-path! chunk project-path (appendable-item))
        (assert-subtable examples.chunk_parsed chunk.children))))

  (context "by removal"
    (context "by path via root"
      (test "removes the expected item"
        (local chunk (example-chunk))

        (mutation.remove-at-path! chunk ::1)
        (assert.same :task (. chunk :children 1 :kind))
        (assert.same :project (. chunk :children 2 :kind))

        (let [second-thing-name (. (chunk:lookup ::2:2) :name)
              third-thing-name (. (chunk:lookup ::2:3) :name)]
          (mutation.remove-at-path! chunk ::2:2)

          (let [new-second-thing (chunk:lookup ::2:2)]
            (assert.not_equal second-thing-name new-second-thing.name)
            (assert.equal third-thing-name new-second-thing.name))))

      (test "keeps the affected table as a sequence"
        (let [chunk (example-chunk)
              project (chunk:lookup ::3)
              initial-children-count (length project.children)]
          (mutation.remove-at-path! chunk ::3:2)

          (assert.equal (- initial-children-count 1) (length project.children)
                        "project has one fewer child")
          (for [i 1 (length project.children)]
            (assert.not_equal nil (. project.children i) "no child is nil")))))

    (context "by pruning"
      (test "removes the expected item"
        (let [chunk (example-chunk)
              project (. chunk.children 3)
              item (. project.children 2)]
          (mutation.prune! item)

          (each [_ child (ipairs project.children)]
            (assert.not_equal item child))))))

  (context "by replacement"
    (test "replaces one item with another"
      (let [chunk (example-chunk)
            item (. chunk.children 3)
            replacement (things.note {:text "I am a replacement!"})]
        (mutation.replace! item replacement)

        (assert.same (. chunk.children 3) replacement
                     "replacement is present")
        (assert.same chunk (. chunk.children 3 :parent)
                     "replacement knows its new parent")

        (each [_ child (ipairs chunk.children)]
          (assert.not_same item child "replaced item is not present"))))

    (context "when replacement is a root"
      (lambda test-replacement-with-root [children ?behavior]
        (test (or ?behavior "splices its children in")
          (let [pristine-chunk (example-chunk)
                chunk (example-chunk)
                replaced-item-index 3
                replaced-item (. chunk.children replaced-item-index)
                replacement (things.root {:children children})]

            (mutation.replace! replaced-item replacement)

            (for [index 1 (- replaced-item-index 1)]
              (assert-basically-same
                (. pristine-chunk.children index)
                (. chunk.children index)))

            (assert.same (+ (length pristine-chunk.children)
                            (length children) -1)
                         (length chunk.children))

            (each [i child (ipairs replacement.children)]
              (let [new-index (+ i (- replaced-item-index 1))
                    via-new-index (. chunk.children new-index)]
                (assert.same child via-new-index)
                (assert.same chunk via-new-index.parent)))

            (for [index (+ replaced-item-index 1) (length pristine-chunk.children)]
              (let [adjusted-index (+ index (length replacement.children) -1)]
                (assert-basically-same
                  (. pristine-chunk.children index)
                  (. chunk.children adjusted-index)
                  "all following children are preserved"))))))

      (context "with no children"
        (test-replacement-with-root [] "effectively removes item"))
      (context "with one child"
        (test-replacement-with-root [(appendable-item)]))
      (context "with many children"
        (test-replacement-with-root (. (example-chunk) :children))))))
