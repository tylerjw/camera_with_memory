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

#define POINT_BUFFER_LENGTH   200
#define MAX_COLUMNS           30

in port RX = on tile[0]:XS1_PORT_1O;
out port TX = on tile[0]:XS1_PORT_1P;

out port addr = on tile[0]:XS1_PORT_32A;
port data = on tile[0]:XS1_PORT_8B;
out port bus_sw = on tile[0]:XS1_PORT_1H;
out port cam_oe_we = on tile[0]:XS1_PORT_4E;
out port ce1 = on tile[0]:XS1_PORT_1I;
out port ce2 = on tile[0]:XS1_PORT_1L;

in port PCLK = on tile[0]:XS1_PORT_1E;
in port HREF = on tile[0]:XS1_PORT_1F;
in port VSYNC = on tile[0]:XS1_PORT_1G;

void camera_thread(void) {
    int center_points[POINT_BUFFER_LENGTH][2];
    int num_points = 0;
    int num_columns = 0;
    int col_idx[MAX_COLUMNS];

    // camera init
    reset();
    delay(100e6);
    cameraConfig();
    delay(10e6);
    while(1) {
        // save image 1
        save_image1();
        // turn off the laser -- to implement
        save_image2();

        // get our points
        num_points = point_finder(center_points, POINT_BUFFER_LENGTH);
        // sort columns
        num_columns = sort_by_col(center_points, POINT_BUFFER_LENGTH, num_points, col_idx, MAX_COLUMNS);

        printf("Points Found %d, Columns Found: %d\n", num_points, num_columns);

        delay(100e6); // 1 second delay
    }
}

int main(void) {
    par {
        on tile[0]:camera_thread();
    }
    return 0;
}
