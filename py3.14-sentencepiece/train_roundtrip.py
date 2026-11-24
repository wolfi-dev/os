"""Train a tiny model offline and round-trip text through it.

Training and encoding go through the bundled abseil flat_hash_map code that
fix-bundled-absl-gcc16.patch changes, so a bad patch shows up here.
"""

import os
import tempfile

import sentencepiece as spm

words = (
    "the quick brown fox jumps over the lazy dog while a small cat sleeps "
    "on a warm mat near the open window and birds sing in the tall green trees"
).split()

# A few dozen deterministic lines built from the word list.
corpus = [" ".join(words[i:] + words[:i]) for i in range(len(words))]

tmp = tempfile.mkdtemp()
corpus_path = os.path.join(tmp, "corpus.txt")
with open(corpus_path, "w", encoding="utf-8") as f:
    f.write("\n".join(corpus) + "\n")

vocab_size = 40
prefix = os.path.join(tmp, "m")
spm.SentencePieceTrainer.train(
    input=corpus_path,
    model_prefix=prefix,
    vocab_size=vocab_size,
    model_type="unigram",
    character_coverage=1.0,
    num_threads=1,
)

sp = spm.SentencePieceProcessor(model_file=prefix + ".model")
assert sp.get_piece_size() == vocab_size, sp.get_piece_size()

# minimum: empty input and a single character
assert sp.encode("") == [], sp.encode("")
assert sp.decode(sp.encode("a")) == "a"

# middle: an ordinary sentence from the corpus
s = corpus[3]
ids = sp.encode(s)
assert ids and all(0 <= i < vocab_size for i in ids), ids
assert sp.decode(ids) == s, sp.decode(ids)

# suspicious: unseen characters (astral emoji, other scripts) map to unk
unk = sp.unk_id()
for odd in ["\U0001F600", "日本", "ж"]:
    assert unk in sp.encode(odd), (odd, sp.encode(odd))
mixed = "the cat 日 sleeps"
assert unk in sp.encode(mixed)
assert sp.id_to_piece(sp.encode("the")[0]) != sp.id_to_piece(unk)

# maximum: a long input, about 100k characters
long_s = " ".join(corpus * 30)
assert len(long_s) > 100_000, len(long_s)
assert sp.decode(sp.encode(long_s)) == long_s

# error path: a vocabulary larger than the corpus supports must fail
try:
    spm.SentencePieceTrainer.train(
        input=corpus_path,
        model_prefix=os.path.join(tmp, "too_big"),
        vocab_size=100000,
        model_type="unigram",
        num_threads=1,
    )
except RuntimeError as e:
    print("oversized vocab rejected:", str(e).splitlines()[0])
else:
    raise AssertionError("training with an oversized vocab_size did not fail")

print("sentencepiece train/encode/decode OK")
