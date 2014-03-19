/*
 * camera.h
 *
 *  Created on: Mar 15, 2014
 *      Author: tylerjw
 */

#ifndef CAMERA_H_
#define CAMERA_H_

extern in port PCLK; // = on tile[0]:XS1_PORT_1E;
extern in port HREF; // = on tile[0]:XS1_PORT_1F;
extern in port VSYNC; // = on tile[0]:XS1_PORT_1G;
extern out port cam_oe_we; // = on tile[0]:XS1_PORT_4E;
extern out port bus_sw; // = on tile[0]:XS1_PORT_1H;
extern out port addr; // = on tile[0]:XS1_PORT_32A;
extern out port ce1; // = on tile[0]:XS1_PORT_1I;
extern out port ce2; // = on tile[0]:XS1_PORT_1L;

extern in port RX; // = on tile[0]:XS1_PORT_1O;
extern out port TX; // = on tile[0]:XS1_PORT_1P;

extern in port JUMPER; // = on tile[0]:XS1_PORT_1C;

#define PICHEIGHT 480
#define PICWIDTH 640
#define UARTDELAY 100

#define CAMON   0b0010  // camera on state
#define OE      0b0100  // output enable on memory

void count_pixels_and_lines_thread(void);
void testMemoryAndCamera();
void test_uart();

void save_image2(void);
void save_image1(void);
void sendImage();
void sendImage2();

void reset();
void cameraConfig();
void delay(int delay);

#endif /* CAMERA_H_ */
