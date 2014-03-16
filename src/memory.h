/*
 * memory.h
 *
 *  Created on: Mar 13, 2014
 *      Author: tylerjw
 */

#ifndef MEMORY_H_
#define MEMORY_H_

extern out port addr; // = on tile[0]:XS1_PORT_32A;
extern port data; // = on tile[0]:XS1_PORT_8B;
extern out port bus_sw; // = on tile[0]:XS1_PORT_1H;
extern out port cam_oe_we; // = on tile[0]:XS1_PORT_4E;
extern out port ce1; // = on tile[0]:XS1_PORT_1I;
extern out port ce2; // = on tile[0]:XS1_PORT_1L;

void memory_test_thread(void);
void memory_test_full_write(void);

// function declarations
void mem2_write(unsigned int start_addr, unsigned char d[n], unsigned n);
void mem2_write_byte(unsigned int start_addr, unsigned char d);
void mem2_read_init();
void mem1_write(unsigned int start_addr, unsigned char d[n], unsigned n);
void mem1_write_byte(unsigned int start_addr, unsigned char d);
void mem1_read_init();
unsigned char mem_read_byte(unsigned int start_addr);
void mem_read(unsigned int start_addr, unsigned char buffer[n], unsigned int n);

#endif /* MEMORY_H_ */
