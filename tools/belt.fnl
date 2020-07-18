(import-macros {: append} :tools.belt_macros)

(lambda drop [n things]
  "Returns `things` without the first `n` items."
  (let [start (+ 1 n)
        end (length things)]
    (table.move things start end 1 [])))

(lambda lines [io-object]
  "Returns the lines from `io-object` as a sequence."
  (let [result []]
    (each [line (io-object:lines)]
      (append result line))
    result))

(lambda map [f things]
  "Returns the result of applying `f` to each entry in the sequence `things`."
  (let [result []]
    (each [_ thing (ipairs things)]
      (append result (f thing)))
    result))

(lambda reverse [sequence]
  "Returns a new sequence with the elements of `sequence` in reverse order."
  (let [reversed []
        n (length sequence)]
    (each [i item (ipairs sequence)]
      (tset reversed (- n (- i 1)) item))
    reversed))

{: drop
 : lines
 : map
 : reverse}
