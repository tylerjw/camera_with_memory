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

// internal interface
void init_point(struct Point *p);
void add_line(struct Point *p, int left, int right); // adds a line of pixels to POINT
void add_point(struct Point *p, int index);
int test_point(struct Point *p, int index); // x-failure: 0, y-falure: -1, new point and success = 1
int test_shape(struct Point *p); //

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
  if(p->size == 0) // new point
    return 1;
  if(YVAL(index) > (p->max[1]+1)) // should never be a break - done with point
    return -1;
  if(XVAL(index) < (p->min[0]-THRESHOLD) || XVAL(index) > (p->max[0]+THRESHOLD))
    return 0; // don't add to this point, but keep active

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
  const int threshold_C = 10;
  struct Point points[length];
  const int unused_C = 0;
  const int active_C = 1;
  const int consemated_C = 2;
  const int bad_C = -1;
  int point_status[length];
  int left_point = 0;
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
      if(working_line[x] > threshold_C)
      {
        if(left == -1) // new line
        {
          left = right = y*WIDTH + x;
        }
        else
        {
          right = y*WIDTH + x;
        }
      } else if(left != -1) {
        int found = 0; // bool (false)
        for(int j=left_point; j<=right_point;j++)
        {
          if(point_status[j] == active_C)
          {
            int test = test_point(&points[j], left);
            if(test == 1)
            {
              add_line(&points[j], left,right);
              found = 1; // ture
              break;
            } else if (test == -1) {
              // point should be consemated
              if(j == left_point)
                left_point++;
              point_status[j] = consemated_C;
            }
          }
        }
        if(!found)
        {
          right_point++;
          point_status[right_point] = active_C;
          add_line(&points[right_point], left, right);
        }
        left = -1;
      }
    }
  }
  for(int i = left_point; i <= right_point; i++)
    point_status[i] = consemated_C;
  for(int i = 0; i < 100 && point_status[i] != unused_C; i++)
  {
    int test = test_shape(&points[i]);
    if(test < 0) // bad
    {
      point_status[i] = bad_C;
      // printf("%d(%d): (%d,%d) - bad (%d)\n", i, point_status[i], *center, *(center+1), test);
      continue;
    } else {
      center_points[num_centers][0] = points[i].center[0];
      center_points[num_centers][1] = points[i].center[1];
      num_centers++;
    }
    //printf("%d(%d): (%d,%d)\n", i, point_status[i], *center, *(center+1));
  }

  return num_centers;
}
