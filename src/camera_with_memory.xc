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

//#define DEBUG

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
    c = 4;

    while(1) {
//        if(c == 0) {
//            c = 4;
//        } else {
//            c = 0;
//        }
        //c = rx2(RX_M) - (int)'0';
        c = getchar() - (int)'0';
        //printf("\r\n");
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
        case 3:
            // send to computer
            c = rx(RX);
            tx(TX,0);
            printf("Sending image\r\n");
            // tx2_str(TX_M, buffer, strlen(buffer));
            sendFilteredImage();
            //sendImage();
            //sendImage2();
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
                //printf("(%d,%d)\r\n", center_points[i][0], center_points[i][1]);
                //delay(1e4);
            }
            printf("Done\n");
            break;

        case 4:
            // send to computer
            c = rx(RX);
            tx(TX,0);
            printf("Sending image\r\n");
            // tx2_str(TX_M, buffer, strlen(buffer));
            //sendFilteredImage();
            sendImage();
            //sendImage2();
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
                //printf("(%d,%d)\r\n", center_points[i][0], center_points[i][1]);
                //delay(1e4);
            }
            printf("Done\n");
            break;

        case 5:
            // send to computer
            c = rx(RX);
            tx(TX,0);
            printf("Sending image\r\n");
            // tx2_str(TX_M, buffer, strlen(buffer));
            //sendFilteredImage();
            //sendImage();
            sendImage2();
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
                //printf("(%d,%d)\r\n", center_points[i][0], center_points[i][1]);
                //delay(1e4);
            }
            printf("Done\n");
            break;
        }

        clear_points(center_points, POINT_BUFFER_LENGTH);
    }
}

void slave_thread(void) {
    int center_points[POINT_BUFFER_LENGTH][2];
    int num_points = 0;
    int num_columns = 0;
    int col_idx[MAX_COLUMNS];
    int num_rows = 0;
    int row_idx[MAX_ROWS];
    int j;
    JUMPER :> j;

    //char buffer[80];

    // uart init
    //uart_init(1e6);
    //uart_init2(9600);
    int c;

    //printf("Configuring camera\n");

    // camera init
    reset();
    delay(100e6);
    cameraConfig(); // if JUMPER == 1, mirrored
    delay(10e6);

    //printf("Start main loop\n");
    while(1) {
        c = rx2(RX_M) - (int)'0';
        //printf("Received: %d\n", c);
        switch(c) {
        case 0:
            // save image 1
            save_image1();
            //printf("Saved Image 1\n");
            tx2(TX_M, 0); // done
            break;
        case 1:
            // save image 2
            save_image2();
            //printf("Saved Image 2\n");
            // find points and columns
            // get our points
            clear_points(center_points, POINT_BUFFER_LENGTH);
            num_points = point_finder(center_points, POINT_BUFFER_LENGTH);
            // sort columns
            if(j == 0) {
                num_columns = sort_by_col(center_points, POINT_BUFFER_LENGTH, num_points, col_idx, MAX_COLUMNS);
            } else {
                num_rows = sort_by_row(center_points, POINT_BUFFER_LENGTH, num_points, row_idx, MAX_ROWS);
            }
            //printf("num_points: %d\n", num_points);

#ifdef DEBUG
            // send to computer
            c = rx(RX);
            tx(TX,0);
            //sendFilteredImage();
            sendImage();
            //sendImage2();
            rx(RX);
            tx(TX,num_points);

            for(int i = 0; i < num_points; i++) {
                tx(TX, center_points[i][0]);
                tx(TX, center_points[i][0] >> 8);
                tx(TX, center_points[i][1]);
                tx(TX, center_points[i][1] >> 8);
                //printf("(%d,%d)\r\n", center_points[i][0], center_points[i][1]);
                //delay(1e4);
            }
            //printf("Done\n");
#endif
            tx2(TX_M, 0); // done
            break;
        case 2: // cam A send your data
            // demo data

            num_points = 4;
            for(int i = 0; i < num_points; i++) {
                center_points[i][0] = 0;
                center_points[i][1] = 0;
            }

            num_columns = 100;

            if(j == 0) {
                tx2(TX_M, num_points);
                tx2(TX_M, (num_points >> 8));
                tx2(TX_M, num_columns);
                tx2(TX_M, (num_columns >> 8));
                for(int i = 0; i < num_points && i < POINT_BUFFER_LENGTH; i++) {
                    for(int j = 0; j < 2; j++) {
                        tx2(TX_M, center_points[i][j]);
                        tx2(TX_M, (center_points[i][j] >> 8));
                    }
                }
                for(int i = 0; i < num_columns && i < MAX_COLUMNS; i++) {
                    tx2(TX_M, col_idx[i]);
                    tx2(TX_M, (col_idx[i] >> 8));
                }
            }
            break;

        case 3: // cam B send your data
            // demo data

            num_points = 3;
            center_points[0][0] = 3;
            center_points[0][1] = 523;
            center_points[1][0] = 53;
            center_points[1][1] = 421;
            center_points[2][0] = 54;
            center_points[2][1] = 221;
            num_rows = 450;

            if(j == 1) {
                tx2(TX_M, num_points);
                tx2(TX_M, (num_points >> 8));
                tx2(TX_M, num_rows);
                tx2(TX_M, (num_rows >> 8));
                for(int i = 0; i < num_points && i < POINT_BUFFER_LENGTH; i++) {
                    for(int j = 0; j < 2; j++) {
                        tx2(TX_M, center_points[i][j]);
                        tx2(TX_M, (center_points[i][j] >> 8));
                    }
                }
                for(int i = 0; i < num_rows && i < MAX_ROWS; i++) {
                    tx2(TX_M, row_idx[i]);
                    tx2(TX_M, (row_idx[i] >> 8));
                }
            }
            break;
        }
    }
}

void tx_test(void) {
    //uart_init(9600);
    while(1) {
        tx(TX_M, 'a');
        delay(10e6);
    }
}

// main //

int main(void) {
    par {
        on tile[0]:slave_thread();
//        on tile[0]:tx_test();
    }
    return 0;
}
