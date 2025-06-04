from pysyncobj import SyncObj, replicated
import time
class MyCounter(SyncObj):
    def __init__(self, selfAddr, partnerAddrs):
        super(MyCounter, self).__init__(selfAddr, partnerAddrs)
        self.__counter = 0

    @replicated
    def incCounter(self):
        self.__counter += 1

    def getCounter(self):
        return self.__counter


node1 = MyCounter('localhost:4321', ['localhost:4322', 'localhost:4323'])
node2 = MyCounter('localhost:4322', ['localhost:4321', 'localhost:4323'])
node3 = MyCounter('localhost:4323', ['localhost:4321', 'localhost:4322'])

# Allow cluster to form
time.sleep(2)

node1.incCounter()
node1.incCounter()

# Wait for replication
time.sleep(2)

assert node2.getCounter() == 2
assert node3.getCounter() == 2
print('Replication successful')
