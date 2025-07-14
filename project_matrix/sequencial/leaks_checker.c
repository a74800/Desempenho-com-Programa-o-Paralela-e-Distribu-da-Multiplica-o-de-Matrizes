//credits to Namam Tamrakar (original code) & Joao Dias (improvements)
//source code adapted from https://dev.to/namantam1/a-simple-program-to-detect-memory-leak-in-our-c-program-5c5i
//01/03/2024 - JD - added tracking for calloc and strdup functions
//16/03/2024 - JD - added tracking for realloc function
//16/03/2024 - JD - using %ul when printing size_t variables (with a cast to unsigned long)
// so that this file compiles without warnings both in 32 bits and 64 bits machines 
//(size_t uses 32 bits in a 32 bit machine, and 64 bits in a 64 bit machine)
//12/04/2024 - JD - solved bug when calling realloc with NULL pointer

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define MAX_ALLOCATIONS 10000
#define WARN(msg, line) (printf("Warning %d: %s\n", line, msg))

/* 
Data Structure to keep track of memory allocations
*/
typedef struct {
    size_t address;
    size_t size;
    uint32_t line;
} Mem;

struct {
    Mem mem[MAX_ALLOCATIONS];
    size_t total_allocated_size;
    size_t total_free_size;
} data;

/**
 * Find a memory by its address
 * 
 * @return: Pointer to memory
*/
Mem *find_by_address(size_t address) {
    for (uint32_t i=0; i<MAX_ALLOCATIONS; i++) {
        if (data.mem[i].address == address)
            return &data.mem[i]; // as soon as find return
    }

    // otherwise return null
    return NULL;
}


/**
 * insert memory allocated with size
*/
void insert(size_t address, size_t size, uint32_t line) {
    // check for null
    if (address == 0) {
        WARN("Memory allocation failed", line);
        return;
    }

    Mem *mem = find_by_address(0);
    // if the return value is null we need to increase the MAX_ALLOCATIONS value
    if (mem == NULL) {
        WARN("Max allocations reached", line);
        return;
    }

    // save all the allocation info
    mem->address = address;
    mem->size = size;
    mem->line = line;
    data.total_allocated_size += size;
}

//updates information regarding a previously allocated address that was resized
//by a call to realloc 
void resize(size_t old_address, size_t new_address, size_t new_size, uint32_t line) {
    // check for null
    if (new_address == 0) {
        WARN("Memory reallocation failed", line);
        return;
    }

    Mem *mem = find_by_address(old_address);
    // if the return value is null this means the original_address was never
    // allocated, or was already freed
    if (mem == NULL) {
        WARN("Realloc of unallocated memory", line);
        return;
    }

    // update all the allocation info
    int delta = new_size - mem->size;
    mem->address = new_address;
    mem->size = new_size;
    mem->line = line;
    data.total_allocated_size += delta;
}

/**
 * Remove the memory allocation
 * 
 * @return: -1 on failure else 0
*/
int erase(size_t address, uint32_t line) {
    if (address == 0) {
        WARN("Tried to free a null ptr", line);
        return -1;
    }

    Mem *mem = find_by_address(address);
    // if the address is not found we assume it is already deleted
    if (mem == NULL) {
        WARN("Double free detected", line);
        return -1;
    }

    // set address to null and update info
    mem->address = 0;
    data.total_free_size += mem->size;
    return 0;
}

void print_memory_leak_report() {
    printf("\nLeak Summary\n");
    printf("Total Memory allocated %lu bytes\n", (unsigned long)data.total_allocated_size);
    printf("Total Memory freed     %lu bytes\n", (unsigned long)data.total_free_size);
    printf("Memory Leaked          %lu bytes\n\n", 
        (unsigned long)(data.total_allocated_size - data.total_free_size));

    if (data.total_free_size != data.total_allocated_size) {
        printf("Detailed Report\n");
        for (int i=0; i<MAX_ALLOCATIONS; i++) {
            if (data.mem[i].address != 0) {
                printf("Memory leak at line %d: (%lu bytes)\n", 
                    data.mem[i].line,
                    (unsigned long)data.mem[i].size);
            }
        }
    }
}

void print_short_leak_report()
{
    printf("Memory Leaked          %lu bytes\n\n", 
        (unsigned long)(data.total_allocated_size - data.total_free_size));
}

size_t get_total_allocated_memory()
{
    return data.total_allocated_size;
}
size_t get_total_freed_memory()
{
    return data.total_free_size;
}

// Override allocation functions
void *_malloc(size_t size, uint32_t line) {
    void *ptr = malloc(size);

    // insert to memory data
    insert((size_t)ptr, size, line);

    return ptr;
}

void *_calloc(size_t nitems, size_t size, uint32_t line) {
    void *ptr = calloc(nitems,size);

    // insert to memory data
    insert((size_t)ptr, nitems*size, line);

    return ptr;
}

char *__strdup(const char* s, uint32_t line)
{
    char *ptr = strdup(s);
    size_t size = (strlen(s)+1)*sizeof(char);
    // insert to memory data
    insert((size_t)ptr, size, line);

    return ptr;
}

void _free(void *ptr, uint32_t line) {
    // erase memory data
    if (erase((size_t)ptr, line) == 0)
        free(ptr);
}

// Override allocation functions
void *_realloc(void *ptr, size_t size, uint32_t line) {
    void *new_ptr = realloc(ptr,size);

    if(ptr == NULL)
    {
        insert((size_t)new_ptr, size, line);
        return new_ptr;
    }

    if(size == 0)
    {
        _free(ptr,line);
        return NULL;
    }

    // resize memory data
    resize((size_t)ptr, (size_t) new_ptr, size, line);

    return new_ptr;
}