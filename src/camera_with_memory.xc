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

#define POINT_BUFFER_LENGTH   300
#define MAX_COLUMNS           30
#define MAX_ROWS              30

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

void clear_points(int the_points[l][2], const static unsigned int l) {
    for(int i = 0; i < l; i++) {
        the_points[i][0] = 0;
        the_points[i][1] = 0;
    }
}

// threads //

void camera_thread(void) {
    int center_points[POINT_BUFFER_LENGTH][2];
    int num_points = 0;
    int num_columns = 0;
    int col_idx[MAX_COLUMNS];
    int num_rows = 0;
    int row_idx[MAX_ROWS];

    //char buffer[80];

    // uart init
    uart_init(1e6);
    int c;

    // camera init
    reset();
    delay(100e6);
    cameraConfig(); // if JUMPER == 1, mirrored
    delay(10e6);

    while(1) {
        //c = rx2(RX_M) - (int)'0';
        c = getchar() - (int)'0';
        printf("\r\n");
        // tx2_str(TX_M, buffer, strlen(buffer));
        //c = 2;
        //printf("Received: %d\r\n", c);

        switch(c) {
        case 0:
            // save image 1
            save_image1();
            printf("Saved Image 1\r\n");
            // tx2_str(TX_M, buffer, strlen(buffer));
            break;
        case 1:
            // save image 2
            save_image2();
            printf("Saved Image 2\r\n");
            // tx2_str(TX_M, buffer, strlen(buffer));
            break;
        case 2:
            // find points and columns
            // get our points
            num_points = point_finder(center_points, POINT_BUFFER_LENGTH);
            // sort columns

//            num_columns = sort_by_col(center_points, POINT_BUFFER_LENGTH, num_points, col_idx, MAX_COLUMNS);
//
//            for(int i=0,j=0; i<num_points; i++)
//            {
//                if(i == col_idx[j])
//                  printf("Column %d:\n", j++);
//                printf("(%d,%d)\r\n", center_points[i][0], center_points[i][1]);
//            }

            num_rows = sort_by_row(center_points, POINT_BUFFER_LENGTH, num_points, row_idx, MAX_ROWS);

            printf("Points Found %d, Columns Found: %d, Rows Found: %d\r\n", num_points, num_columns, num_rows);

            for(int i=0,j=0; i<num_points; i++)
            {
                if(i == row_idx[j])
                  printf("Row %d:\n", j++);
                printf("(%d,%d)\r\n", center_points[i][0], center_points[i][1]);
            }
            break;
        case 4:
            // send to computer image 2
            c = rx(RX);
            tx(TX,0);
            printf("Sending image\r\n");
            // tx2_str(TX_M, buffer, strlen(buffer));
            sendImage2();
            printf("Image Sent\r\n");
            // tx2_str(TX_M, buffer, strlen(buffer));
            break;
        case 3:
            // send to computer
            c = rx(RX);
            tx(TX,0);
            printf("Sending image\r\n");
            // tx2_str(TX_M, buffer, strlen(buffer));
            sendFilteredImage();
            printf("Image Sent\r\n");
            // tx2_str(TX_M, buffer, strlen(buffer));
            num_points = point_finder(center_points, POINT_BUFFER_LENGTH);
            printf("num_points = %d\n", num_points);
            printf("Performing handshake\n");
            //tx(TX,10);
            rx(RX);
            tx(TX,num_points);
            //rx(RX);
            printf("Sending points\n");
            for(int i = 0; i < num_points; i++) {
                //rx(RX);
                tx(TX, center_points[i][0]);
                tx(TX, center_points[i][0] >> 8);
                tx(TX, center_points[i][1]);
                tx(TX, center_points[i][1] >> 8);
                printf("(%d,%d)\r\n", center_points[i][0], center_points[i][1]);
                //delay(1e4);
            }
            printf("Done\n");
            break;
        }
        clear_points(center_points, POINT_BUFFER_LENGTH);
    }
}

// main //

int main(void) {
    par {
        on tile[0]:camera_thread();
    }
    return 0;
}
