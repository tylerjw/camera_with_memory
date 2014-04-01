/*
 * console_input_thread.xc
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



#define POINT_BUFFER_LENGTH   300
#define MAX_COLUMNS           30
#define MAX_ROWS              30


// utility
void clear_points(int the_points[l][2], const static unsigned int l) {
    for(int i = 0; i < l; i++) {
        the_points[i][0] = 0;
        the_points[i][1] = 0;
    }
}

void console_input_thread(void) {
    int center_points[POINT_BUFFER_LENGTH][2];
    int num_points = 0;
    int num_columns = 0;
    int col_idx[MAX_COLUMNS];
    int num_rows = 0;
    int row_idx[MAX_ROWS];
    timer t;
    int time;

    //char buffer[80];

    // uart init
    uart_init(1e6);
    int c;

    printf("Resetting the Camera\n");
    // camera init
    reset();
    delay(100e6);
    cameraConfig(); // if JUMPER == 1, mirrored
    delay(10e6);
    printf("Send input\n");

    t :> time;

    while(1) {

        //c = rx2(RX_M) - (int)'0';
        c = getchar() - (int)'0';
        //c = 2;
        //printf("Received: %d\r\n", c);

        switch(c) {
        case 0:
            // save image 1
            save_image1();
            //printf("Saved Image 1\r\n");
            break;
        case 1:
            // save image 2
            save_image2();
            //printf("Saved Image 2\r\n");
            break;
        case 2:
            // find points and columns
            // get our points
            num_points = point_finder(center_points, POINT_BUFFER_LENGTH);
            // sort columns

            num_columns = sort_by_col(center_points, POINT_BUFFER_LENGTH, num_points, col_idx, MAX_COLUMNS);
//
//            for(int i=0,j=0; i<num_points; i++)
//            {
//                if(i == col_idx[j])
//                  printf("Column %d:\n", j++);
//                printf("(%d,%d)\r\n", center_points[i][0], center_points[i][1]);
//            }

            num_rows = sort_by_row(center_points, POINT_BUFFER_LENGTH, num_points, row_idx, MAX_ROWS);

            printf("Points Found %d, Columns Found: %d, Rows Found: %d\r\n", num_points, num_columns, num_rows);
//
//            for(int i=0,j=0; i<num_points; i++)
//            {
//                if(i == row_idx[j])
//                  printf("Row %d:\n", j++);
//                printf("(%d,%d)\r\n", center_points[i][0], center_points[i][1]);
//            }
            break;
        case 3:
            // send to computer
            rx(RX);
            tx(TX,0);
            sendFilteredImage();
            num_points = point_finder(center_points, POINT_BUFFER_LENGTH);
            rx(RX);
            tx(TX,num_points);
            for(int i = 0; i < num_points; i++) {
                tx(TX, center_points[i][0]);
                tx(TX, center_points[i][0] >> 8);
                tx(TX, center_points[i][1]);
                tx(TX, center_points[i][1] >> 8);
            }
            printf("points: %d\n", num_points);
            break;

        case 4:
            // send to computer
            rx(RX);
            tx(TX,0);
            sendImage();
            num_points = point_finder(center_points, POINT_BUFFER_LENGTH);
            rx(RX);
            tx(TX,num_points);
            for(int i = 0; i < num_points; i++) {
                tx(TX, center_points[i][0]);
                tx(TX, center_points[i][0] >> 8);
                tx(TX, center_points[i][1]);
                tx(TX, center_points[i][1] >> 8);
            }
            printf("points: %d\n", num_points);
            break;

        case 5:
            // send to computer
            rx(RX);
            tx(TX,0);
            sendImage2();
            num_points = point_finder(center_points, POINT_BUFFER_LENGTH);
            rx(RX);
            tx(TX,num_points);
            for(int i = 0; i < num_points; i++) {
                tx(TX, center_points[i][0]);
                tx(TX, center_points[i][0] >> 8);
                tx(TX, center_points[i][1]);
                tx(TX, center_points[i][1] >> 8);
            }
            printf("points: %d\n", num_points);
            break;
        }
    }
}
