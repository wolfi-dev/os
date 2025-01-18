/*
 * test_libnftnl.c
 *
 * This program is a simple test for the libnftnl library.
 * It tests the basic functionality of allocating and freeing 
 * an nftnl_chain structure using libnftnl's API.
 *
 * The program does the following:
 * - Allocates a new nftnl_chain object.
 * - Prints a success message if allocation is successful.
 * - Frees the allocated nftnl_chain object.
 *
 * This is used to verify that the libnftnl library is working correctly.
 */

#include <stdio.h>
#include <libnftnl/chain.h>

int main() {
    struct nftnl_chain *chain = nftnl_chain_alloc();

    if (!chain) {
        fprintf(stderr, "Failed to allocate nftnl_chain.\n");
        return 1;
    }

    printf("Successfully allocated nftnl_chain.\n");
    nftnl_chain_free(chain);

    return 0;
}
