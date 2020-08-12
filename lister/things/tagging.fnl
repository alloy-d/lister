;; Our tagging philosophy is not well thought out,
;; but it goes something like this:
;;
;; - Any thing can have any number of tags.
;;
;; - Tags are stored in a sequence, under the assumption that
;;   order is important in the source and should be preserved.
;;
;; - Each tag can have any number of values, but a thing cannot
;;   have more than one occurrence of a tag (by name).
;;
;; - Multi-part tag values are not a thing.
;;   That is, the tag represented by `@tag(a, b)` in taskpaper
;;   can be matched with (has-tag? :tag :a) and (has-tag? :tag :b),
;;   but *not* with something like (has-tag? :tag :a :b).
;;
;;   This is not an explicit decision that that *shouldn't* be
;;   possible, but without a use case, it's not clear what the
;;   semantics should be.
;;
;; In principle, tag operations are designed to look as if a thing has
;; a table where the keys are tag names and the values are sets of tag
;; values.  In practice, the backing data structures are not those, but
;; the mental model is worth having.
(import-macros {: append} :tools.belt_macros)

(lambda tag [name ...]
  "Makes a tag structure with the given tag `name` and `...` as values."
  {:name name
   :values (when (< 0 (select :# ...)) [...])})

;; TODO: move this to the toolbelt.
(fn find [seq test]
  "Returns two values:
  1. the index of the first element in `seq` that passes `test`
  2. that element"
  (fn check [index]
    (when (and seq (<= index (length seq)))
      (let [entry (. seq index)]
        (if (test entry)
          (values index entry)
          (check (+ 1 index))))))
  (check 1))

(fn find-tag [{: tags} tag-name]
  "Checks a given thing for the tag with `tag-name`.

  If not found, returns nil.
  If found, returns true and the table of values."

  (when tags
    (let [(_ tag) (find tags #(= $1.name tag-name))]
      (when tag (values true tag.values)))))

(lambda has-tag? [thing tag-name ?tag-value]
  "Does this thing have `tag-name`, optionally with `?tag-value`?"

  (fn contains-value? [vals index]
    "Does this list of values have the value we're looking for?"
    (if
      (not ?tag-value) true
      (not vals) false
      (> index (length vals)) false
      (= (. vals index) ?tag-value) true
      (contains-value? vals (+ 1 index))))

  (let [(tag vals) (find-tag thing tag-name)]
    (if tag
      (contains-value? vals 1)
      false)))

(lambda has-any-tag? [thing tag-names]
  "Does `thing` have at least one of the tags in `tag-names`?"
  (fn check-for-tag [index]
    (if
      (> index (length tag-names)) false
      (has-tag? thing (. tag-names index)) true
      (check-for-tag (+ 1 index))))

  (check-for-tag 1))

(lambda remove-tag! [thing tag-name]
  "Removes `tag` from `thing`."
  (let [(location _) (find thing.tags #(= $1.name tag-name))]
    (when location
      (table.remove thing.tags location))))

(lambda set-tag! [thing tag-name ...]
  "Adds `tag-name` to `thing` with the given values.
  If `thing` already has a tag with the given name, replaces its values."
  (let [(_ existing-tag) (find thing.tags #(= $1.name tag-name))]
    (if existing-tag
      (tset existing-tag :values [...])
      (append thing.tags (tag tag-name ...)))))

{: tag
 : find-tag
 : has-tag?
 : has-any-tag?

 : set-tag!
 : remove-tag!}
