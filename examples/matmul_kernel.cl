// Matmul8x4Blocks
//
// Each work item computes a 4-column by 8-row (8x4) section of the output
// matrix. The inner loops read in a 4x4 section of matrix B, an 8x4 section of
// matrix A, and accumulate the partial results for the corresponding 8x4
// section of matrix C. The outer loop iterates over the width of matrix A and
// the height of matrix B to get the complete result.
__kernel void Matmul8x4Blocks(__read_only image2d_t matrix_a,
                              __read_only image2d_t matrix_b,
                              __write_only image2d_t matrix_c,
                              int matrix_a_width) {
  const int wid_x = get_global_id(0);
  const int wid_y = get_global_id(1);

  float4 a[8];
  float4 b[4];
  float4 c[8];

  for (int i = 0; i < 8; ++i) {
    c[i] = (float4)(0.0f);
  }

  for (int j = 0; j < matrix_a_width; j += 4) {
    #pragma unroll
    for (int i = 0; i < 4; ++i) {
      b[i] = read_imagef(matrix_b, (int2)(wid_x, i + j));
    }

    #pragma unroll
    for (int i = 0; i < 8; ++i) {
      a[i] = read_imagef(matrix_a, (int2)(j / 4, 8 * wid_y + i));
    }

    #pragma unroll
    for (int i = 0; i < 8; ++i) {
      c[i] += a[i].x * b[0] + a[i].y * b[1] + a[i].z * b[2] + a[i].w * b[3];
    }
  }

  #pragma unroll
  for (int i = 0; i < 8; ++i) {
    write_imagef(matrix_c, (int2)(wid_x, 8 * wid_y + i), c[i]);
  }
}
