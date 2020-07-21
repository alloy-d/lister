(import-macros {: context : test : before-each : after-each} :spec.busted_macros)

(local things (require :lister.things))

(context "lister things"
  (test "are made properly"
    (assert.same "root" (. (things.root {}) :kind))))

(fn sample-task []
  (things.task {:name "this is a task"
                :tags [(things.tag :tag)
                       (things.tag :tag-with-values :value-one :value-two)]}))

(context "tagging:"
  (context "when a thing has a tag"
    (test "has-tag? returns true"
      (assert.true (things.has-tag? (sample-task) :tag)))

    (test "find-tag returns true and nil"
      (let [result (table.pack (things.find-tag (sample-task) :tag))]
        (assert.true (. result 1) "first value is true")
        (assert.nil (. result 2)))))

  (context "when a thing does not have a tag"
    (test "has-tag? returns false"
      (assert.false (things.has-tag? (sample-task) :missing-tag)))
    (test "find-tag returns nil"
      (assert.nil (things.find-tag (sample-task) :missing-tag))))

  (context "when a thing has a tag with values"
    (test "has-tag? returns true when called with no value"
      (assert.true (things.has-tag? (sample-task) :tag-with-values)))
    (test "has-tag? returns true when called with an existent value"
      (assert.true (things.has-tag? (sample-task) :tag-with-values :value-two))
      (assert.true (things.has-tag? (sample-task) :tag-with-values :value-one)))
    (test "has-tag? returns false when called with a nonexistent value"
      (assert.false (things.has-tag? (sample-task) :tag-with-values :value-none)))

    (test "find-tag returns true and the values"
      (let [(result vals) (things.find-tag (sample-task) :tag-with-values)]
        (assert.true result)
        (assert.same [:value-one :value-two] vals))))

  (context "when a thing has no tags"
    (fn sample-task []
      (things.task {:name "this is a task with no tags"}))

    (test "has-tag? returns false"
      (assert.false (things.has-tag? (sample-task) :some-tag)))

    (test "find-tag returns nothing"
      (assert.nil (things.find-tag (sample-task) :some-tag)))))
