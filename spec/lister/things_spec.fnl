(import-macros {: context : test} :spec.busted_macros)

(local things (require :lister.things))
(local tagging (require :lister.things.tagging))

(context "lister things"
  (test "are made properly"
    (assert.same "root" (. (things.root {}) :kind))))

(fn sample-task []
  (things.task {:name "this is a task"
                :tags [(tagging.tag :tag)
                       (tagging.tag :tag-with-values :value-one :value-two)
                       (tagging.tag :third-tag)]}))

(context "tagging:"
  (context "when a thing has a tag"
    (test "has-tag? returns true"
      (assert.true (tagging.has-tag? (sample-task) :tag)))

    (test "find-tag returns true and nil"
      (let [(found vals) (tagging.find-tag (sample-task) :tag)]
        (assert.true found "first value is true")
        (assert.nil vals))))

  (context "when a thing does not have a tag"
    (test "has-tag? returns false"
      (assert.false (tagging.has-tag? (sample-task) :missing-tag)))
    (test "find-tag returns nil"
      (assert.nil (tagging.find-tag (sample-task) :missing-tag))))

  (context "when a thing has a tag with values"
    (test "has-tag? returns true when called with no value"
      (assert.true (tagging.has-tag? (sample-task) :tag-with-values)))
    (test "has-tag? returns true when called with an existent value"
      (assert.true (tagging.has-tag? (sample-task) :tag-with-values :value-two))
      (assert.true (tagging.has-tag? (sample-task) :tag-with-values :value-one)))
    (test "has-tag? returns false when called with a nonexistent value"
      (assert.false (tagging.has-tag? (sample-task) :tag-with-values :value-none)))

    (test "find-tag returns true and the values"
      (let [(result vals) (tagging.find-tag (sample-task) :tag-with-values)]
        (assert.true result)
        (assert.same [:value-one :value-two] vals))))

  (context "when a thing has no tags"
    (fn sample-task []
      (things.task {:name "this is a task with no tags"}))

    (test "has-tag? returns false"
      (assert.false (tagging.has-tag? (sample-task) :some-tag)))

    (test "find-tag returns nothing"
      (assert.nil (tagging.find-tag (sample-task) :some-tag)))))

(context "mutating tags"
  (context "by setting"
    (test "appends a new tag when one didn't exist"
      (let [thing (sample-task)]
        (tagging.set-tag! thing :new-tag :value-one :value-two)

        (assert.true (tagging.has-tag? thing :new-tag) "thing has new tag")
        (assert.true (tagging.has-tag? thing :new-tag :value-one)
                     "thing has new tag with first given value")
        (assert.true (tagging.has-tag? thing :new-tag :value-two))))

    (test "overwrites an existing tag with the same name"
      (let [thing (sample-task)]
        (tagging.set-tag! thing :tag-with-values :value-three :value-four)

        (assert.true (tagging.has-tag? thing :tag-with-values)
                     "thing still has tag")
        (assert.false (tagging.has-tag? thing :tag-with-values :value-one)
                      "thing no longer has value one")
        (assert.false (tagging.has-tag? thing :tag-with-values :value-two)
                      "thing no longer has value two")
        (assert.true (tagging.has-tag? thing :tag-with-values :value-three)
                     "thing has value three")
        (assert.true (tagging.has-tag? thing :tag-with-values :value-four)
                     "thing has value four")

        (each [i tag (ipairs thing.tags)]
          (when (= tag.name :tag-with-values)
            (assert.equal 2 i "overwritten tag retained position"))))))

  (context "by removing"
    (test "does nothing if no tag with the given name exists"
      (let [thing (sample-task)]
        (tagging.remove-tag! thing :frob)
        (assert.same (. (sample-task) :tags) thing.tags)))

    (test "removes a tag with the given name"
      (let [thing (sample-task)
            unchanged-thing (sample-task)]
        (tagging.remove-tag! thing :tag-with-values)

        (assert.false (tagging.has-tag? thing :tag-with-values)
                      "thing no longer has removed tag")
        (assert.same (. unchanged-thing :tags 1) (. thing :tags 1)
                     "first tag is preserved")
        (assert.same (. unchanged-thing :tags 3) (. thing :tags 2)
                     "last tag is preserved and moved up in sequence")))))
