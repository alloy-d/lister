(fn context [desc ...]
  (assert (> (select :# ...) 0) "expected a body")
  `(describe ,desc (fn [] ,...)))

(fn test [desc ...]
  (if
    (> (select :# ...) 0)
    `(it ,desc (fn [] ,...))

    `(pending ,desc (fn []))))

;; FIXME: it's unclear if these work.
;; Busted seems to do a lot of magic around scope management, and
;; using these to manipulate variables around tests seems not to have
;; worked in my non-rigorous testing.
(fn before-each [...]
  (assert (> (select :# ...) 0) "expected a body")
  `(before_each (fn [] ,...)))

(fn after-each [...]
  (assert (> (select :# ...) 0) "expected a body")
  `(after_each (fn [] ,...)))

{: context
 : test

 : before-each
 : after-each}
