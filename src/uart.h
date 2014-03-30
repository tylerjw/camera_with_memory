/*
 * uart.h
 *
 *  Created on: Mar 13, 2014
 *      Author: tylerjw
 */

#ifndef UART_H_
#define UART_H_

void uart_init(int baud);
void uart_init2(int baud);
void tx(out port TX, unsigned char byte);
void tx_str(out port TX, char *str);
void tx2(out port TX, char byte);
void tx2_str(out port TX, char str[n], unsigned int n);
unsigned char rx(in port RX);
unsigned char rx2(in port RX);

#endif /* UART_H_ */
