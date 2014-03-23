/*
 * point.xc
 *
 *  Created on: Mar 17, 2014
 *      Author: tylerjw
 */

#include <point.h>
#include <memory.h>
#include <platform.h>
#include <xs1.h>
#include <stdlib.h>

#include <stdio.h>

// internal interface
void init_point(struct Point *p);
void add_line(struct Point *p, int left, int right); // adds a line of pixels to POINT
void add_point(struct Point *p, int index);
int test_point(struct Point *p, int index); // x-failure: 0, y-falure: -1, new point and success = 1
int test_shape(struct Point *p); //
void calculate_center(struct Point *p);
int in_points(int points[length][2], unsigned int length, int center[2]) ;

int in_points(int points[length][2], unsigned int length, int center[2]) {
  for(int i = 0; i < length; i++) {
    if(center[0] == points[i][0] && center[1] == points[i][1])
      return 1;
  }
  return 0;
}

void calculate_center(struct Point *p)
{
  for(int i=0; i < 2; i++)
    p->center[i] = p->min[i] + ((p->max[i] - p->min[i])/2);
}

void init_point(struct Point *p)
{
  for(int i=0; i < 2; i++)
  {
    p->min[i] = p->max[i] = p->center[i] = -1;
  }
  p->size = 0;
}

void add_line(struct Point *p, int left, int right)
{
  if(left == right)
  {
    add_point(p, left);
  }
  else if(p->size == 0)
  {
    p->min[0] = XVAL(left);
    p->max[0] = XVAL(right);
    p->min[1] = p->max[1] = YVAL(left); // should be the same column
    p->size += right - left;
  }
  else
  {
    if(XVAL(left) < p->min[0]) p->min[0] = XVAL(left);
    if(XVAL(right) > p->max[0]) p->max[0] = XVAL(right);
    p->max[1] = YVAL(left); // should just be one line and should be greater than last one
    p->size += right - left;
  }
}

void add_point(struct Point *p, int index)
{
  if(p->size == 0)
  {
    p->min[0] = p->max[0] = XVAL(index);
    p->min[1] = p->max[1] = YVAL(index); // should be the same column
  }
  else
  {
    if(XVAL(index) < p->min[0]) p->min[0] = XVAL(index);
    if(XVAL(index) > p->max[0]) p->max[0] = XVAL(index);
    p->max[1] = YVAL(index); // should just be one line and should be greater than last one
  }
  p->size++;
}

int test_point(struct Point *p, int index)
{
  if(p->size == 0) { // new point
    //printf("new point\n");
    return 1;
  }
  if(YVAL(index) > (p->max[1]+1)) { // should never be a break - done with point
    //printf("break\n");
    return -1;
  }
  if(XVAL(index) < (p->min[0]-THRESHOLD) || XVAL(index) > (p->max[0]+THRESHOLD)) {
    //printf("not this point\n");
    return 0; // don't add to this point, but keep active
  }
  //printf("good point, add\n");
  return 1; // should be good, add to this point
}

int test_shape(struct Point *p)
{
  int width, height, skew;

  if(p->size < MIN_SIZE)
    return -1;
  if(p->size > MAX_SIZE)
    return -2;

  width = p->max[0] - p->min[0];
  height = p->max[1] - p->min[1];
  skew = height - width;

  if(skew > MAX_SKEW || skew < MIN_SKEW)
    return -3;

  return 1;
}

int point_finder(int center_points[length][2], static const unsigned int length)
{
  // point finder variables
  int left, right;
  const int threshold_C = 80;
  //const int change_C = 60;
  struct Point points[length];
  const int unused_C = 0;
  const int active_C = 1;
  int point_status[length];
  int right_point = -1;
  int num_centers = 0;
  unsigned char working_line[WIDTH];

  // init the points
  for(int i = 0; i < length; i++) {
    init_point(&points[i]);
  }

  // point finder algorithm
  for(int y=0; y<HEIGHT; y++)
  {
    left = right = -1; // new line
    read_filtered_line(working_line, WIDTH, y);
    for(int x=0; x<WIDTH; x++) {
//      if((x > 130 && x < 135) || (x > 255 && x < 260) || (x > 385 && x < 390) || (x > 512 && x < 520)) {
//          left = right = -1;
//          continue;
//      }
      if(working_line[x] > threshold_C)
      {
        if(left == -1) // new line of high values
        {
          left = y*WIDTH + x;
          right = left;
        }
        else
        {
          right = y*WIDTH + x;
        }
      } else if(left != -1 && ((right - left) > 1)) {
        int found = 0;
        for(int j=0; j<=right_point && found == 0;j++)
        {

          if(point_status[j] == active_C)
          {
            //printf("testing point %d\n", j);
            int test = test_point(&points[j], left);
            if(test == 1)
            {
              add_line(&points[j],left,right);
              found = 1;
              //printf("%d Right Point: %d\n", j, right_point);
              //break;
            } else if (test == -1) {
              // point should be consemated - we went past this point
              int shape = test_shape(&points[j]); // test the shape
              if(shape == 1) {
                calculate_center(&points[j]); // calculates the center points
                //printf("Good Shape (%d,%d)\n", points[j].center[0], points[j].center[1]);
                if(num_centers == (length-1)) {
                  printf("Out of memory in center_points\n");
                  continue;
                }
                if(!in_points(center_points,length,points[j].center) && points[j].center[0] > 5) {
                  center_points[num_centers][0] = points[j].center[0];
                  center_points[num_centers][1] = points[j].center[1];
                  num_centers++;
                }
              }
              // free the point
              point_status[j] = unused_C;
              init_point(&points[j]);
            }
          }
        }
        if(!found)
        {
          //printf("didn't find place for point\n");
          // reuse unused points
          int found_unused = 0;
          for(int j = 0; j <= right_point; j++) {
            if(point_status[j] == unused_C) {
              found_unused = 1;
              point_status[j] = active_C;
              add_line(&points[j], left, right);
              //printf("found unused point\n");
            }
          }

          if(right_point == (length-1))
            printf("Need more memory for points array!\n");
          //printf("found_unused == 0 -> %d\n", found_unused == 0);
          //printf("right_point: %d < length: %d -> %d\n", right_point, length, right_point < length);
          if(found_unused == 0 && (right_point < length-1 || right_point == -1)) { // get new point (bounded, safe)
            //printf("adding a point!\n");
            //printf("right_point: %d\n", right_point);
            right_point++;
            point_status[right_point] = active_C;
            add_line(&points[right_point], left, right);
            //printf("added a point\n");
          }

        }
        left = -1;
      }
    }
  }

  printf("Right Point: %d\n", right_point);
  return num_centers;
}


int sort_by_col(int center_points[size_points][2], static const unsigned int size_points,
        unsigned int num_points,
        int col_idx[col_idx_size], static const unsigned int col_idx_size)
{
  int working_array_x[size_points]; // array for copying data points
  int working_array_y[size_points]; // array for copying data points
  int column_number[size_points];    // the column number of each point
  int column_max[col_idx_size];         // the xvalue of the point that's lowest in the column (allong y axis) maximum (+threshold)
  int column_min[col_idx_size];         // the min x value, -1 once copied
  int num_col = 0;          // the number of columns found
  int const done_C = -1000;     // done with this column
  int point_count = 0;          // counter for adding values back into the array
  int col_idx_count = 0;        // counter for adding values to col_idx

  column_number[0] = num_col; // first element
  column_min[0] = center_points[0][0] - COL_THRESHOLD;
  column_max[0] = center_points[0][0] + COL_THRESHOLD;
  num_col++;
  working_array_x[0] = center_points[0][0];
  working_array_y[0] = center_points[0][1];

  for(int p = 1; p < num_points; p++) // p - point number
  {
    int column_found = 0; // bool false
    for(int col = 0; col < num_col; col++) // col - column number
    {
      if(center_points[p][0] <= column_max[col] && center_points[p][0] >= column_min[col])
      {
        // in this column
        column_number[p] = col;
        column_min[col] = center_points[p][0] - COL_THRESHOLD;
        column_max[col] = center_points[p][0] + COL_THRESHOLD;
        column_found = 1; // true
      }
    }
    if(!column_found && num_col < col_idx_size)
    {
      column_number[p] = num_col;
      column_min[num_col] = center_points[p][0] - COL_THRESHOLD;
      column_max[num_col] = center_points[p][0] + COL_THRESHOLD;
      num_col++;
    }
    column_found = 0; // false

    working_array_x[p] = center_points[p][0]; // copy into working array
    working_array_y[p] = center_points[p][1];
  }

  // sort the columns and the array
  for(int col = 0; col < num_col; col++) // col - column number
  {
    int lowest = -1;
    for(int col2 = 0; col2 < num_col; col2++) // col2 = column number
    {
      if(column_min[col2] != done_C) {
          if(lowest == -1)
          {
            lowest = col2;
          }
          else if(column_max[lowest] > column_max[col2])  // runs over the end
          {
            lowest = col2;
          }
      }
    }
    column_min[lowest] = done_C;
    for(int p = 0; p < num_points; p++) // p - point number
    {
      if(column_number[p] == lowest && point_count < size_points)
      {
        center_points[point_count][0] = working_array_x[p];
        center_points[point_count][1] = working_array_y[p];
        point_count++;
      }
    }
    if(col_idx_count == 0)
      col_idx[col_idx_count++] = 0;
    if(col_idx_count < col_idx_size) // protect the array (shoud never be false)
      col_idx[col_idx_count++] = point_count; // store the values of where the columns start
  }

  return num_col;
}

int sort_by_row(int center_points[size_points][2], static const unsigned int size_points,
        unsigned int num_points,
        int row_idx[row_idx_size], static const unsigned int row_idx_size)
{
  int num_row = 0;
  int working_array_x[size_points]; // array for copying data points
  int working_array_y[size_points]; // array for copying data points
  int min = center_points[0][0];
  int max = min;

  row_idx[0] = 0; // first row always starts at first element

  // sort by row
  // copy into dummy arrays and find max and min x values
  for(int i = 0; i < num_points && i < size_points; i++) {
    working_array_x[i] = center_points[i][0];
    working_array_y[i] = center_points[i][1];
    if(working_array_y[i] < min) {
      min = working_array_y[i];
    }
    if(working_array_y[i] > max) {
      max = working_array_y[i];
    }
  }
  int idx = 0;

  for(int val = min; val <= max; val++) {
    for(int i = 0; i < num_points && i < size_points; i++) {
      if(working_array_y[i] == val) {
        center_points[idx][0] = working_array_x[i];
        center_points[idx][1] = working_array_y[i];
        idx++;
      }
    }
  }

  for(int i = 1; i < num_points && i < size_points; i++) // i - point number
  {
    if(abs(center_points[i][1] - center_points[i-1][1]) > ROW_THRESHOLD && num_row < row_idx_size) {
      // new row
      num_row++;
      //printf("%d, %d, %d\r\n", center_points[i][0], center_points[i-1][0], abs(center_points[i][0] - center_points[i-1][0]));
      row_idx[num_row] = i;
    }
  }

  return num_row;
}
