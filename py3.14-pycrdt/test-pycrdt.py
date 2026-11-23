from pycrdt import Array, Doc, Map, Text

text0 = Text("Hello")
array0 = Array([0, "foo"])
map0 = Map({"key0": "value0"})

doc = Doc()
doc["text0"] = text0
doc["array0"] = array0
doc["map0"] = map0

assert str(doc["text0"]) == "Hello"
assert doc["array0"][0] == 0
assert doc["map0"]["key0"] == "value0"

with doc.transaction():
    text0 += ", World!"
    array0.append("bar")
    map0["key1"] = "value1"

assert str(doc.get("text0", type=Text)) == "Hello, World!"
assert doc.get("array0", type=Array)[2] == "bar"
assert doc.get("map0", type=Map)["key1"] == "value1"
