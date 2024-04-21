from tinydb import TinyDB, Query

try:
    db = TinyDB('wolfi.json')
    db.insert({
       'language': 'python3',
       'package':'tinydb',
       'repo':'wolfi-dev/os',
       'os':'wolfi'
    })
    all_items = db.all()
    print(all_items)
except Exception as e:
    print(f"ERROR {e}")