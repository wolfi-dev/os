import multiprocessing

def worker(managed_list, process_id):
  print(f"Process {process_id}: Starting")
  managed_list.append(process_id)

if __name__ == '__main__':

  with multiprocessing.Manager() as manager:
    shared_list = manager.list()
    processes = []
    num_processes = 5
    for i in range(num_processes):
        p = multiprocessing.Process(target=worker, args=(shared_list, i))
        processes.append(p)
        p.start()

    for p in processes:
        p.join()

    print("\nAll processes finished.")
    print(f"Final shared list: {list(shared_list)}")
    print(f"List length: {len(shared_list)}")
