/*
 * memory.xc
 *
 *  Created on: Mar 13, 2014
 *      Author: tylerjw
 */
#include <memory.h>
#include <platform.h>
#include <stdio.h>
#include <xs1.h>
#include <uart.h>

#define WE  0b1000
#define OE  0b0100
#define CAMON   0b0010  // camera on state

// function declarations
void mem2_write(unsigned int start_addr, unsigned char d[n], unsigned n);
void mem2_write_byte(unsigned int start_addr, unsigned char d);
void mem2_read_init();
void mem1_write(unsigned int start_addr, unsigned char d[n], unsigned n);
void mem1_write_byte(unsigned int start_addr, unsigned char d);
void mem1_read_init();
unsigned char mem_read_byte(unsigned int start_addr);
void mem_read(unsigned int start_addr, unsigned char buffer[n], unsigned int n);

// THREAD on TILE 0 /////////////////////////////////////////////////////////

void memory_test_thread(void) {
    int write_len = 11;
    unsigned char out_val[] = {0xAA, 0xBB, 0xCC, 0xDD, 0xEE,
                                    0xFF, 0x00, 0x11, 0x22, 0x33, 0x44};
    unsigned char in_val[12];
    unsigned int start_addr = 1;
    timer t;
    int time;
    t :> time;

    while(1) {
        mem1_write(start_addr, out_val, write_len);
        mem1_read_init();
        mem_read(start_addr, in_val, write_len);
        for(int i = 0; i < write_len; i++) {
            printf("in_val[%d] = 0x%0X\r\n", i, in_val[i]);
        }
        printf("\n");

        // delay
        time += 1000 * 1000 * 100 * 5;
        t when timerafter(time) :> void;
    }
}

void memory_test_full_write(void) {
    int errors = 0;
    unsigned char c;

    printf("Writing address to memory test.\r\n");
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        // 19 bits of address
        mem1_write_byte(i,(unsigned char)i);
    }

    mem1_read_init();
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        c = mem_read_byte(i);
        if(c != (unsigned char)i) {
            errors++;
            //printf("i: %x, uc_i: %x, val: %x\r\n", i, (unsigned char)i, c);
        }
    }

    printf("Bank 1 Errors: %d\n", errors);

    errors = 0;
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        // 19 bits of address
        mem2_write_byte(i,(unsigned char)i);
    }

    mem2_read_init();
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        c = mem_read_byte(i);
        if(c != (unsigned char)i) {
            errors++;
            //printf("i: %x, uc_i: %x, val: %x\r\n", i, (unsigned char)i, c);
        }
    }

    printf("Bank 2 Errors: %d\n", errors);

    printf("Writing 0x00 to memory test.\r\n");
    errors = 0;
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        // 19 bits of address
        mem1_write_byte(i,0x00);
    }

    mem1_read_init();
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        c = mem_read_byte(i);
        if(c != 0x00) {
            errors++;
        }
    }

    printf("Bank 1 Errors: %d\n", errors);

    errors = 0;
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        // 19 bits of address
        mem2_write_byte(i,0x00);
    }

    mem2_read_init();
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        c = mem_read_byte(i);
        if(c != 0x00) {
            errors++;
        }
    }

    printf("Bank 2 Errors: %d\n", errors);

    printf("Writing 0xff to memory test.\r\n");
    errors = 0;
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        // 19 bits of address
        mem1_write_byte(i,0xff);
    }

    mem1_read_init();
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        c = mem_read_byte(i);
        if(c != 0xff) {
            errors++;
        }
    }

    printf("Bank 1 Errors: %d\n", errors);

    errors = 0;
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        // 19 bits of address
        mem2_write_byte(i,0xff);
    }

    mem2_read_init();
    for(int i = 0; i <= 0b1111111111111111111; i++) {
        c = mem_read_byte(i);
        if(c != 0xff) {
            errors++;
        }
    }

    printf("Bank 2 Errors: %d\n", errors);
}

// Helper Functions ///////////////////////////////////////////////////////////

void mem2_write_byte(unsigned int start_addr, unsigned char d) {
    // write some data (write wave form 1, ce controlled)
    // bus switch high (off)
    bus_sw <: 1;
    // oe high, we low
    cam_oe_we <: OE | CAMON;
    // ce high for unused data chip
    ce1 <: 1;
    // start loop

    // ce high
    ce2 <: 1;
    // write address
    addr <: start_addr;
    // write data
    data <: d;
    // ce low (data writes)
    ce2 <: 0;

}

void mem1_write_byte(unsigned int start_addr, unsigned char d) {
    // write some data (write wave form 1, ce controlled)
    // bus switch high (off)
    bus_sw <: 1;
    // oe high, we low
    cam_oe_we <: OE | CAMON;
    // ce high for unused data chip
    ce2 <: 1;
    // start loop

    // ce high
    ce1 <: 1;
    // write address
    addr <: start_addr;
    // write data
    data <: d;
    // ce low (data writes)
    ce1 <: 0;

}
// yellow green orange red


void mem2_write(unsigned int start_addr, unsigned char d[n], unsigned n) {
    // write some data (write wave form 1, ce controlled)
    // bus switch high (off)
    bus_sw <: 1;
    // oe high, we low
    cam_oe_we <: OE | CAMON;
    // ce high for unused data chip
    ce1 <: 1;
    // start loop
    for(int i = 0; i < n; i++) {
        // ce high
        ce2 <: 1;
        // write address
        addr <: start_addr + i;
        // write data
        data <: d[i];
        // ce low (data writes)
        ce2 <: 0;
    }
}

void mem1_write(unsigned int start_addr, unsigned char d[n], unsigned n) {
    // write some data (write wave form 1, ce controlled)
    // bus switch high (off)
    bus_sw <: 1;
    // oe high, we low
    cam_oe_we <: OE | CAMON;
    // ce high for unused data chip
    ce2 <: 1;
    // start loop
    for(int i = 0; i < n; i++) {
        // ce high
        ce1 <: 1;
        // write address
        addr <: start_addr + i;
        // write data
        data <: d[i];
        // ce low (data writes)
        ce1 <: 0;
    }
}

void mem2_read_init() {
    // bus switch high (off)
    bus_sw <: 1;
    // ce high (off) for unusued data chip
    ce1 <: 1;
    // we high (off), oe low
    cam_oe_we <: CAMON | WE;
    // ce low (on) for used data chip
    ce2 <: 0;
}

void mem1_read_init() {
    // bus switch high (off)
    bus_sw <: 1;
    // ce high (off) for unusued data chip
    ce2 <: 1;
    // we high (off), oe low
    cam_oe_we <: CAMON | WE;
    // ce low (on) for used data chip
    ce1 <: 0;
}

unsigned char mem_read_byte(unsigned int start_addr) {
    // read some data, wave form 1
    unsigned char d;

    // start loop
    // write address
    addr <: start_addr;
    // increase addresss (delay the correct amount of time )
    start_addr += 1;
    // get data
    data :> d;
    // end loop

    return d;
}

void mem_read(unsigned int start_addr, unsigned char buffer[n], unsigned int n) {
    // read some data, wave form 1

    // start loop
    for(int i = 0; i < n; i++) {
        // write address
        addr <: start_addr;
        // increase addresss (delay the correct amount of time )
        start_addr += 1;
        // get data
        data :> buffer[i];
        // end loop
    }
}
