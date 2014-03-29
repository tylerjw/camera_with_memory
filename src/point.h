/*
 * point.h
 *
 *  Created on: Mar 17, 2014
 *      Author: tylerjw
 */

#ifndef POINT_H_
#define POINT_H_

#define WIDTH       640
#define HEIGHT      480
#define NUM_PIXELS  (WIDTH*HEIGHT)

#define XVAL(idx) (idx%WIDTH)
#define YVAL(idx) (idx/WIDTH)

#define THRESHOLD 10  // threshold for point test
#define MIN_SIZE  5
#define MAX_SIZE  (30*30)
#define MIN_SKEW  -30
#define MAX_SKEW  30

#define COL_THRESHOLD 20  // threshold for being in the same column
#define ROW_THRESHOLD 20

struct Point {
  int min[2];
  int max[2];
  int size;
  int center[2];
};

/** point finder
takes the working green array, finds center points

returns number of center points
*/
int point_finder(int center_points[length][2], static const unsigned int length);

/* sorts array of order pairs and sorts them by column
 * @param center_points     array of center points
 * @param num_points      number of center points
 * @param col_idx         array of colom index points (output)
 * @param col_idx_size      size of col_idx array
 * @returns number of columns
 *
 *
*/

int sort_by_col(int center_points[size_points][2], static const unsigned int size_points,
        unsigned int num_points,
        int col_idx[col_idx_size], static const unsigned int col_idx_size);

int sort_by_row(int center_points[size_points][2], static const unsigned int size_points,
        unsigned int num_points,
        int row_idx[row_idx_size], static const unsigned int row_idx_size);


#endif /* POINT_H_ */
