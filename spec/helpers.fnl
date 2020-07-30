(local assert (require :luassert))

(lambda assert-basically-same [expected actual ?message]
        "Asserts, in a half-assed way, that two things are the same.
        The point: compare two things that differ in parent."
        (assert.same expected.kind actual.kind ?message)
        (assert.same expected.name actual.name ?message)
        (assert.same expected.lines actual.lines ?message))

{: assert-basically-same}
