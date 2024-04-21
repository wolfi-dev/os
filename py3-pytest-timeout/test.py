# test.py

import time

def test_a_slow_test():
    """This should take 3 seconds to run. An agressive 'pytest --timeout'
    value will kill it, but forgiving timeout flag will let it go."""
    time.sleep(3)
