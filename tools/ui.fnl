(local {: keys-sorted} (require :tools.belt))

(lambda yes-or-no? [prompt]
  "Prints `prompt`. Gets a clear \"yes\" or \"no\" from input. Returns true or false."
  (io.write prompt)
  (io.write " [y/n] ")
  (let [input (io.read :l)]
    (if
      (= input :y) true
      (= input :n) false
      (yes-or-no? prompt))))

(lambda explain [choices]
  "Prints an explanation of the given choices."
  (each [_ key (ipairs (keys-sorted choices))]
    (print key (. choices key :name) (. choices key :desc)))
  (print)
  false)

(lambda read-choice [choices]
  "Prompts the user to choose one of `choices`, then runs it if possible.

  `choices` is a table mapping single-character strings to choice tables.

  Something like:
      {:a {:name :choice-a
           :desc \"choose a\"
           :perform (fn [] (print \"you chose a!\"))}
       :b {:name :choice-b
           :desc \"choose b\"}}

  For this case, it would prompt the user:

      What would you like to do? [a,b,?]

  Where entering 'a' or 'b' calls the `perform` function associated with
  that choice, if any, and entering '?' will cause it to print a listing
  of the choices."
  (local choice-keys (keys-sorted choices))
  (table.insert choice-keys :?)

  (io.write
    (string.format "What would you like to do? [%s] "
                   (table.concat choice-keys ",")))

  (let [input (io.read :l)
        choice (. choices input)]
    (if
      choice
      (when choice.perform
        (let [continue? (choice.perform)]
          (when (not continue?)
            (read-choice choices))))

      (= input :?)
      (do
        (explain choices)
        (read-choice choices))

      (do
        (when input
          (print input "is not a valid choice." "Try again."))
        (read-choice choices)))))

{: read-choice
 : yes-or-no?}
