/*
 * troubleshooting_threads.xc
 *
 *  Created on: Mar 30, 2014
 *      Author: tylerjw
 */
#include <platform.h>
#include <xs1.h>
#include <camera.h>
#include <memory.h>
#include <point.h>
#include <stdio.h>
#include <string.h>
#include <uart.h>

extern out port TX_M; // = on tile[0]:XS1_PORT_1N;

void tx_test(void) {
    while(1) {
        tx2(TX_M, 'a');
        delay(10e6);
    }
}
