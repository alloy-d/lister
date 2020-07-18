(lambda append [sequence item]
  `(tset ,sequence (+ 1 (length ,sequence)) ,item))

{: append}
