(import-macros {: context : test} :spec.busted_macros)

(local taskpaper (require :taskpaper))
(local things (require :lister.things))
(local mutation (require :lister.things.mutation))

(local examples (require :spec.taskpaper.examples))

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
            (assert.not_equal item child)))))))
