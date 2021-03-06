/*
 * camera_with_memory.xc
 *
 *  Created on: Mar 14, 2014
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

in port RX = on tile[0]:XS1_PORT_1O;
out port TX = on tile[0]:XS1_PORT_1P;

in port RX_M = on tile[0]:XS1_PORT_1M;
out port TX_M = on tile[0]:XS1_PORT_1N;

out port addr = on tile[0]:XS1_PORT_32A;
port data = on tile[0]:XS1_PORT_8B;
out port bus_sw = on tile[0]:XS1_PORT_1H;
out port cam_oe_we = on tile[0]:XS1_PORT_4E;
out port ce1 = on tile[0]:XS1_PORT_1I;
out port ce2 = on tile[0]:XS1_PORT_1L;

in port PCLK = on tile[0]:XS1_PORT_1E;
in port HREF = on tile[0]:XS1_PORT_1F;
in port VSYNC = on tile[0]:XS1_PORT_1G;

in port JUMPER = on tile[0]:XS1_PORT_1C;

// threads //

void extern console_input_thread(void);
void extern slave_thread(void);
void extern tx_test(void);

// main //

int main(void) {
    par {
        on tile[0]:slave_thread();
    }
    return 0;
}
