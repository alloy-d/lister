(import-macros {: context : test} :spec.busted_macros)

(local filer (require :taskpaper.filer))
(local things (require :lister.things))

(local {: assert_subtable} (require :spec.taskpaper.helpers))

(context "filing edge cases:"
  (test "parses an empty file"
    (local name (os.tmpname))

    (with-open [f (io.open name)]
      (f:write ""))

    (let [root (filer.load_file name)
          expected {:kind :file
                    :name name
                    :children []}]
      (assert_subtable expected root))

    (assert (os.remove name)))

  (test "writes an empty file"
    (let [name (os.tmpname)
          file (things.file {:name name})]
      (filer.write file)

      (with-open [f (io.open name)]
        (let [contents (f:read :a)]
          (assert.equal contents "")))

      (assert (os.remove name)))))
