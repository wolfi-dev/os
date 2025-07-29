import sys
import etcd

key = sys.argv[1]
value = sys.argv[2]

def setup(key, value):
    client = etcd.Client(host="127.0.0.1", port=2379)
    client.write(key, value)
    result = client.read(key).value
    print(result)

setup(key, value)