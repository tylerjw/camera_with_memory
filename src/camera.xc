/*
 * camera.xc
 *
 *  Created on: Mar 15, 2014
 *      Author: tylerjw
 */
#include <platform.h>
#include <stdio.h>
#include <xs1.h>
#include <i2c.h>
#include <memory.h>
#include <uart.h>
#include <camera.h>

r_i2c i2c_if = {on tile[0]:XS1_PORT_1J, on tile[0]:XS1_PORT_1K, 250};

void reset();
void timeFrame(in port VSYNC);
void cameraConfig();
void delay(int delay);
void count_pixels_and_lines_thread(void);
void save_image1(void);
void sendImage();
void testMemoryAndCamera();
void configureMirroredImage();
void save_test_image(void);

void delay(int delay){
    timer t;
    int time;
    t :> time;
    time += delay;
    t when timerafter(time) :> void;
}

void sendFilteredImage(){
    unsigned char working_line[PICWIDTH];

    for(int y = 0; y < PICHEIGHT; y++){
        read_filtered_line(working_line, PICWIDTH, y);
        for(int x = 0; x < PICWIDTH; x++){

            tx(TX,working_line[x]);
        }
        if(y == 0) {
            for(int i = 0; i < 20; i++) {
                printf("%d\t",working_line[i]);
            }
            printf("\n");
        }
    }
}

void sendImage(){
    int location = 0;
    unsigned char c = 0;
    mem1_read_init();
    for(int y = 0; y < PICHEIGHT; y++){
        for(int x = 0; x < PICWIDTH; x++){
            c = mem_read_byte(location);
            location++;

            tx(TX,c);
            if(y == 0 && x < 20) {
                printf("%d\t",c);
            }
        }
        if(y == 0) {
            printf("\n");
        }
    }
}

void sendImage2(){
    int location = 0;
    unsigned char c = 0;
    mem2_read_init();
    for(int y = 0; y < PICHEIGHT; y++){
        for(int x = 0; x < PICWIDTH; x++){
            c = mem_read_byte(location);
            location++;

            tx(TX,c);
            if(y == 0 && x < 20) {
                printf("%d\t",c);
            }
        }
        if(y == 0) {
            printf("\n");
        }

    }
}

void save_test_image(void) {
    int address = 0;
    for(int y = 0; y < PICHEIGHT; y++) {
        for(int x = 0; x < PICWIDTH; x++) {
            mem1_write_byte(address, (unsigned int)x);
            address++;
        }
    }
}

void testMemoryAndCamera(){
    int c = 1;
    reset();
    delay(100e6);
    cameraConfig();
    delay(10e6);
    uart_init(1e6);
    while(1){
        //printf("Saving image...\n");
        //delay(1e6);
        save_image1(); // save an image
        //save_test_image();
        //printf("Waiting for start condition\n");
        c = rx(RX);
        tx(TX,0);
        //printf("Sending image\n");
        sendImage();
        //printf("Image Sent!\n");
    }
}

void test_uart() {
    int c = 1;
    uart_init(1e6);
    while(1) {
        printf("Waiting for start condition\n");
        c = rx(RX);
        //while(1){

    //        tx(TX,0xAA);
    //        printf("meh\n");
    //        delay(100e6);
        //}
        tx(TX,0);
        printf("Sending image\n");
        for(int y = 0; y < PICHEIGHT; y++) {
            for(int x = 0; x < PICWIDTH; x++) {
                tx(TX, (unsigned char)x);
            }
        }
        printf("Image Sent!\n");
    }
}

/*
 * save an image to memory bank 1
 *
 * wait for vsync to signal start of new image (high then low)
 * open databus switch
 * wait for href to go high
 * start loop
 *  set address
 *  when pclock -> high
 *      write data
 *      increment address
 */
void save_image1(void) {
    int location = 0;
    // connect data bus switch from camera to memory
    bus_sw <: 0;

    ce2 <: 1; // deselect chip 2
    ce1 <: 1; // select chip 1 (inactive state)

    cam_oe_we <: CAMON | OE; // configured for writing

    addr <: location; // set the memory address to zero

    VSYNC when pinseq(1) :> void; // wait for VSYHC == 1
    VSYNC when pinseq(0) :> void; // wait for VSYNC == 0 // new frame

    for(register int y = 0; y < PICHEIGHT; y++){
        HREF when pinseq(1) :> void; //HREF goes high as bytes become useful
        PCLK when pinseq(0) :> void;
        PCLK when pinseq(1) :> void;
        for(register int x = 0; x < PICWIDTH; x++){
            PCLK when pinseq(0) :> void;
            addr <: location;
            PCLK when pinseq(1) :> void; //rising edge signifies valid byte
            location++;
            //this byte is ignored
            PCLK when pinseq(0) :> void;
            ce1 <: 1;
            PCLK when pinseq(1) :> void; //rising edge signifies valid byte
            ce1 <: 0;
        }
        ce1 <: 1;
        HREF when pinseq(0) :> void; //waits until HREF goes low at end of row
    }
    //cam_oe_we <: CAMON; // stop writing
}

/*
 * save an image to memory bank 2
 *
 * wait for vsync to signal start of new image (high then low)
 * open databus switch
 * wait for href to go high
 * start loop
 *  set address
 *  when pclock -> high
 *      write data
 *      increment address
 */
void save_image2(void) {
    int location = 0;
    // connect data bus switch from camera to memory
    bus_sw <: 0;

    ce2 <: 1; // select chip 2 (inactive)
    ce1 <: 1; // deselect chip 1

    cam_oe_we <: CAMON | OE; // configured for writing

    addr <: location; // set the memory address to zero

    VSYNC when pinseq(1) :> void; // wait for VSYHC == 1
    VSYNC when pinseq(0) :> void; // wait for VSYNC == 0 // new frame

    for(register int y = 0; y < PICHEIGHT; y++){
        HREF when pinseq(1) :> void; //HREF goes high as bytes become useful
        PCLK when pinseq(0) :> void;
        PCLK when pinseq(1) :> void;
        for(register int x = 0; x < PICWIDTH; x++){
            PCLK when pinseq(0) :> void;
            addr <: location;
            PCLK when pinseq(1) :> void; //rising edge signifies valid byte
            location++;
            //this byte is ignored
            PCLK when pinseq(0) :> void;
            ce2 <: 1;
            PCLK when pinseq(1) :> void; //rising edge signifies valid byte
            ce2 <: 0;
        }
        ce2 <: 1;
        HREF when pinseq(0) :> void; //waits until HREF goes low at end of row
    }
    //cam_oe_we <: CAMON; // stop writing
}

/*
 * initialize
 * program camera over i2c
 */
void cameraConfig() {
    int j;
    JUMPER :> j;
    ///////////clock setup
    //char data[1] = {0b10001111}; // puts a divider on clock (fps = 1)
    char data[1] = {0b10000011}; // fps = 3
    i2c_master_write_reg(0x21,0x11,data,1,i2c_if);
    data[0] = 0b00000000; // default yuv mode
    i2c_master_write_reg(0x21,0x12,data,1,i2c_if);
    data[0] = 0xC0; // default 16bit mode
    i2c_master_write_reg(0x21,0x40,data,1,i2c_if);
//    data[0] = 0x00; // default 16bit mode
//    i2c_master_write_reg(0x21,0x00,data,1,i2c_if);
    data[0] = 0x13; // manual gain
    i2c_master_write_reg(0x21,0x74,data,1,i2c_if);
    ///////////end clock setup
    if(j == 1) {
        configureMirroredImage();
    }
}

void configureMirroredImage() {
    char data[1] = {0b00110000}; // flip image
    i2c_master_write_reg(0x21,0x1E,data,1,i2c_if);
    delay(50000000);
}

void count_pixels_and_lines_thread(void) {

    int lines = 0;
    int pixelsPerLine[480];
    int countingLines = 1;
    int countingPixels;
    int pixelCount;
    unsigned char test;
    //reset();

    cam_oe_we <: CAMON;
    cameraConfig();

    VSYNC when pinseq(1) :> void; // wait for VSYHC == 1
    VSYNC when pinseq(0) :> void; // wait for VSYNC == 0 // new frame

    while(countingLines == 1){ // am i still counting lines
        select{

        case HREF when pinseq(1) :> void: // HREF is high
            pixelCount = 0;
            countingPixels = 1; // we are counting pixels
            while(countingPixels == 1){
                PCLK when pinseq(0) :> void; // wait for PCLK == 0
                HREF :> test; // store HREF value
                if(test == 1){ // lines hasn't ended yet
                    PCLK when pinseq(1) :> void; // wait for PCLK == 0
                    pixelCount++; // increase pixelCount
                }else{ // line ended
                    pixelsPerLine[lines] = pixelCount;
                    countingPixels = 0;
                }
            }
            HREF when pinseq(0) :> void; // wait for HREF == 0
            lines++;
            break;

        case VSYNC when pinseq(1) :> void: // when VSYNC goes high again - end of picture
            countingLines = 0;
            printf("lines = %d\n",lines);
            for(int i = 0; i < 1; i++) {
                printf("pixelsPerLine[%d] = %d\n",i,pixelsPerLine[i]);
            }
            break;
        }
    }
    timeFrame(VSYNC);
}

void reset(void) {
    timer t;
    int time;
    t :> time;
    cam_oe_we <: 0;
    time += 1000 * 1000 * 2;
    t when timerafter(time) :> void;
    cam_oe_we <: CAMON;
}

void timeFrame(in port VSYNC){
    timer t;
    int time;
    int oldtime;
    int fps;
    //reset();
    VSYNC when pinseq(1) :> void; //first mark of a new frame
    t :> oldtime;
    VSYNC when pinseq(0) :> void; // 17 t_lines from first row
    VSYNC when pinseq(1) :> void; //first mark of a new frame
    t :> time;
    time = time - oldtime;
    fps = 100000000/time;
    printf("time for frame = %d, fps = %d\n", time, fps);
    VSYNC when pinseq(0) :> void; // 17 t_lines from first row
}
