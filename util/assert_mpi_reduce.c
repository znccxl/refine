/* mpicc -g -o assert_mpi_reduce assert_mpi_reduce.c */
#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"
int main(int argc, char *argv[]) {
  int i, n = 10;
  int nproc, rank;
  double *in, *out;
  long total;

  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &nproc);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  if (argc > 1) n = atoi(argv[1]);

  in = (double *)malloc(n * sizeof(double));
  out = (double *)malloc(n * sizeof(double));

  for (i = 0; i < n; i++) in[i] = 0;
  if (0 == rank) {
    printf("calling MPI_Reduce( %d, MPI_DOUBLE, MPI_SUM) with %d\n", n, nproc);
    total = (long)n * (long)nproc;
    printf("for a total of %ld\n", total);
    fflush(stdout);
  }
  MPI_Allreduce(in, out, n, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
  if (0 == rank) {
    printf("MPI_Allreduce returned\n");
    fflush(stdout);
  }

  free(out);
  free(in);

  MPI_Finalize();
  return 0;
}
