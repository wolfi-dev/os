import asyncio
from asgiref.sync import async_to_sync

# Define an asynchronous function
async def async_test():
    await asyncio.sleep(1)
    return "Asynchronous test completed"

# Synchronous wrapper to run the asynchronous function
def run_test():
    try:
        result = async_to_sync(async_test)()
        print(result)
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    run_test()