/*
 * slave_thread.xc
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

//#define DEBUG // for output to computer

#define POINT_BUFFER_LENGTH   300
#define MAX_COLUMNS           30
#define MAX_ROWS              30

extern in port RX_M; // = on tile[0]:XS1_PORT_1M;
extern out port TX_M; // = on tile[0]:XS1_PORT_1N;

void extern clear_points(int the_points[l][2], const static unsigned int l);

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
    uart_init(1e6);
    uart_init2(9600);
    int c;

    TX_M <: 1;

    //printf("Configuring camera\n");

    // camera init
    reset();
    delay(100e6);
    cameraConfig(); // if JUMPER == 1, mirrored
    delay(10e6);

    //printf("Start main loop\n");
    while(1) {
        c = rx2(RX_M);
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
            sendFilteredImage();
            //sendImage();
            //sendImage2();
            rx(RX);
            tx(TX,num_points);

            for(int i = 0; i < num_points; i++) {
                tx(TX, center_points[i][0]);
                tx(TX, center_points[i][0] >> 8);
                tx(TX, center_points[i][1]);
                tx(TX, center_points[i][1] >> 8);
            }
#endif
            tx2(TX_M, 0); // done
            break;
        case 2: // cam A send your data
            // demo data

//            num_points = 4;
//            for(int i = 0; i < num_points; i++) {
//                center_points[i][0] = 10;
//                center_points[i][1] = 400;
//            }
//
//            num_columns = 4;

            if(j == 0) {
                tx2(TX_M, num_points);
                tx2(TX_M, (num_points >> 8));
                tx2(TX_M, num_columns);
                tx2(TX_M, (num_columns >> 8));
                for(int i = 0; i < num_points && i < POINT_BUFFER_LENGTH; i++) {
                    for(int j = 0; j < 2; j++) {
                        tx2(TX_M, (char)center_points[i][j]);
                        tx2(TX_M, (char)(center_points[i][j] >> 8));
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
//
//            num_points = 3;
//            center_points[0][0] = 3;
//            center_points[0][1] = 523;
//            center_points[1][0] = 53;
//            center_points[1][1] = 421;
//            center_points[2][0] = 54;
//            center_points[2][1] = 221;
//            num_rows = 1;

            if(j == 1) {
                tx2(TX_M, num_points);
                tx2(TX_M, (num_points >> 8));
                tx2(TX_M, num_rows);
                tx2(TX_M, (num_rows >> 8));
                for(int i = 0; i < num_points && i < POINT_BUFFER_LENGTH; i++) {
                    for(int j = 0; j < 2; j++) {
                        tx2(TX_M, (char)center_points[i][j]);
                        tx2(TX_M, (char)(center_points[i][j] >> 8));
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
