# Test derived from package docs: https://github.com/toumorokoshi/deepmerge/blob/master/README.rst

from deepmerge import Merger, always_merger

# Generic strategy
base = {"foo": ["bar"]}
next = {"foo": ["baz"]}

expected_result = {'foo': ['bar', 'baz']}
result = always_merger.merge(base, next)

assert expected_result == result

my_merger = Merger(
    # pass in a list of tuple, with the
    # strategies you are looking to apply
    # to each type.
    [
        (list, ["append"]),
        (dict, ["merge"]),
        (set, ["union"])
    ],
    # next, choose the fallback strategies,
    # applied to all other types:
    ["override"],
    # finally, choose the strategies in
    # the case where the types conflict:
    ["override"]
)
base = {"foo": ["bar"]}
next = {"bar": "baz"}
my_merger.merge(base, next)

assert base == {"foo": ["bar"], "bar": "baz"}
