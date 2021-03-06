#include "cminpack_lmdif.h"

int cminpack_lmdif(int (*func)(void *d, int n, int m, double *p, double *hx, int iflag), 
                   void *d, int m, int n, double *x, double *fvec, double tol, int *iwa, 
    double *wa, int lwa)
{
  /* Initialized data */

  const double factor = 100.;

  int mp5n, mode, nfev;
  double ftol, gtol, xtol;
  double epsfcn;
  int maxfev, nprint;
  int info;

  /*     ********** */

  /*     subroutine lmdif1 */

  /*     the purpose of lmdif1 is to minimize the sum of the squares of */
  /*     m nonlinear functions in n variables by a modification of the */
  /*     levenberg-marquardt algorithm. this is done by using the more */
  /*     general least-squares solver lmdif. the user must provide a */
  /*     subroutine which calculates the functions. the jacobian is */
  /*     then calculated by a forward-difference approximation. */

  /*     the subroutine statement is */

  /*       subroutine lmdif1(fcn,m,n,x,fvec,tol,info,iwa,wa,lwa) */

  /*     where */

  /*       fcn is the name of the user-supplied subroutine which */
  /*         calculates the functions. fcn must be declared */
  /*         in an external statement in the user calling */
  /*         program, and should be written as follows. */

  /*         subroutine fcn(m,n,x,fvec,iflag) */
  /*         integer m,n,iflag */
  /*         double precision x(n),fvec(m) */
  /*         ---------- */
  /*         calculate the functions at x and */
  /*         return this vector in fvec. */
  /*         ---------- */
  /*         return */
  /*         end */

  /*         the value of iflag should not be changed by fcn unless */
  /*         the user wants to terminate execution of lmdif1. */
  /*         in this case set iflag to a negative integer. */

  /*       m is a positive integer input variable set to the number */
  /*         of functions. */

  /*       n is a positive integer input variable set to the number */
  /*         of variables. n must not exceed m. */

  /*       x is an array of length n. on input x must contain */
  /*         an initial estimate of the solution vector. on output x */
  /*         contains the final estimate of the solution vector. */

  /*       fvec is an output array of length m which contains */
  /*         the functions evaluated at the output x. */

  /*       tol is a nonnegative input variable. termination occurs */
  /*         when the algorithm estimates either that the relative */
  /*         error in the sum of squares is at most tol or that */
  /*         the relative error between x and the solution is at */
  /*         most tol. */

  /*       info is an integer output variable. if the user has */
  /*         terminated execution, info is set to the (negative) */
  /*         value of iflag. see description of fcn. otherwise, */
  /*         info is set as follows. */

  /*         info = 0  improper input parameters. */

  /*         info = 1  algorithm estimates that the relative error */
  /*                   in the sum of squares is at most tol. */

  /*         info = 2  algorithm estimates that the relative error */
  /*                   between x and the solution is at most tol. */

  /*         info = 3  conditions for info = 1 and info = 2 both hold. */

  /*         info = 4  fvec is orthogonal to the columns of the */
  /*                   jacobian to machine precision. */

  /*         info = 5  number of calls to fcn has reached or */
  /*                   exceeded 200*(n+1). */

  /*         info = 6  tol is too small. no further reduction in */
  /*                   the sum of squares is possible. */

  /*         info = 7  tol is too small. no further improvement in */
  /*                   the approximate solution x is possible. */

  /*       iwa is an integer work array of length n. */

  /*       wa is a work array of length lwa. */

  /*       lwa is a positive integer input variable not less than */
  /*         m*n+5*n+m. */

  /*     subprograms called */

  /*       user-supplied ...... fcn */

  /*       minpack-supplied ... lmdif */

  /*     argonne national laboratory. minpack project. march 1980. */
  /*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

  /*     ********** */

  /*     check the input parameters for errors. */

  if (n <= 0 || m < n || tol < 0. || lwa < m * n + n * 5 + m) {
    return 0;
  }

  /*     call lmdif. */

  maxfev = (n + 1) * 200;
  ftol = tol;
  xtol = tol;
  gtol = 0.;
  epsfcn = 0.;
  mode = 1;
  nprint = 0;
  mp5n = m + n * 5;
  info = lmdif(func, d, m, n, x, fvec, ftol, xtol, gtol, maxfev,
      epsfcn, wa, mode, factor, nprint, &nfev, &wa[mp5n],
      m, iwa, &wa[n], &wa[(n << 1)], &wa[n * 3], 
      &wa[(n << 2)], &wa[n * 5]);
  if (info == 8) {
    info = 4;
  }
  return info;

  /*     last card of subroutine lmdif1. */

} /* lmdif1_ */

int lmdif(int (*func)(void *d, int n, int m, double *p, double *hx, int iflag), 
    void *d, int m, int n, double *x, 
    double *fvec, double ftol, double xtol, double
    gtol, int maxfev, double epsfcn, double *diag, int
    mode, double factor, int nprint, int *
    nfev, double *fjac, int ldfjac, int *ipvt, double *
    qtf, double *wa1, double *wa2, double *wa3, double *
    wa4)
{
  /* Initialized data */

  /* System generated locals */
  double d1, d2;

  /* Local variables */
  int i, j, l;
  double par, sum;
  int iter;
  double temp, temp1, temp2;
  int iflag;
  double delta = 0.;
  double ratio;
  double fnorm, gnorm;
  double pnorm, xnorm = 0., fnorm1, actred, dirder, epsmch, prered;
  int info;

  /*     ********** */

  /*     subroutine lmdif */

  /*     the purpose of lmdif is to minimize the sum of the squares of */
  /*     m nonlinear functions in n variables by a modification of */
  /*     the levenberg-marquardt algorithm. the user must provide a */
  /*     subroutine which calculates the functions. the jacobian is */
  /*     then calculated by a forward-difference approximation. */

  /*     the subroutine statement is */

  /*       subroutine lmdif(fcn,m,n,x,fvec,ftol,xtol,gtol,maxfev,epsfcn, */
  /*                        diag,mode,factor,nprint,info,nfev,fjac, */
  /*                        ldfjac,ipvt,qtf,wa1,wa2,wa3,wa4) */

  /*     where */

  /*       fcn is the name of the user-supplied subroutine which */
  /*         calculates the functions. fcn must be declared */
  /*         in an external statement in the user calling */
  /*         program, and should be written as follows. */

  /*         subroutine fcn(m,n,x,fvec,iflag) */
  /*         integer m,n,iflag */
  /*         double precision x(n),fvec(m) */
  /*         ---------- */
  /*         calculate the functions at x and */
  /*         return this vector in fvec. */
  /*         ---------- */
  /*         return */
  /*         end */

  /*         the value of iflag should not be changed by fcn unless */
  /*         the user wants to terminate execution of lmdif. */
  /*         in this case set iflag to a negative integer. */

  /*       m is a positive integer input variable set to the number */
  /*         of functions. */

  /*       n is a positive integer input variable set to the number */
  /*         of variables. n must not exceed m. */

  /*       x is an array of length n. on input x must contain */
  /*         an initial estimate of the solution vector. on output x */
  /*         contains the final estimate of the solution vector. */

  /*       fvec is an output array of length m which contains */
  /*         the functions evaluated at the output x. */

  /*       ftol is a nonnegative input variable. termination */
  /*         occurs when both the actual and predicted relative */
  /*         reductions in the sum of squares are at most ftol. */
  /*         therefore, ftol measures the relative error desired */
  /*         in the sum of squares. */

  /*       xtol is a nonnegative input variable. termination */
  /*         occurs when the relative error between two consecutive */
  /*         iterates is at most xtol. therefore, xtol measures the */
  /*         relative error desired in the approximate solution. */

  /*       gtol is a nonnegative input variable. termination */
  /*         occurs when the cosine of the angle between fvec and */
  /*         any column of the jacobian is at most gtol in absolute */
  /*         value. therefore, gtol measures the orthogonality */
  /*         desired between the function vector and the columns */
  /*         of the jacobian. */

  /*       maxfev is a positive integer input variable. termination */
  /*         occurs when the number of calls to fcn is at least */
  /*         maxfev by the end of an iteration. */

  /*       epsfcn is an input variable used in determining a suitable */
  /*         step length for the forward-difference approximation. this */
  /*         approximation assumes that the relative errors in the */
  /*         functions are of the order of epsfcn. if epsfcn is less */
  /*         than the machine precision, it is assumed that the relative */
  /*         errors in the functions are of the order of the machine */
  /*         precision. */

  /*       diag is an array of length n. if mode = 1 (see */
  /*         below), diag is internally set. if mode = 2, diag */
  /*         must contain positive entries that serve as */
  /*         multiplicative scale factors for the variables. */

  /*       mode is an integer input variable. if mode = 1, the */
  /*         variables will be scaled internally. if mode = 2, */
  /*         the scaling is specified by the input diag. other */
  /*         values of mode are equivalent to mode = 1. */

  /*       factor is a positive input variable used in determining the */
  /*         initial step bound. this bound is set to the product of */
  /*         factor and the euclidean norm of diag*x if nonzero, or else */
  /*         to factor itself. in most cases factor should lie in the */
  /*         interval (.1,100.). 100. is a generally recommended value. */

  /*       nprint is an integer input variable that enables controlled */
  /*         printing of iterates if it is positive. in this case, */
  /*         fcn is called with iflag = 0 at the beginning of the first */
  /*         iteration and every nprint iterations thereafter and */
  /*         immediately prior to return, with x and fvec available */
  /*         for printing. if nprint is not positive, no special calls */
  /*         of fcn with iflag = 0 are made. */

  /*       info is an integer output variable. if the user has */
  /*         terminated execution, info is set to the (negative) */
  /*         value of iflag. see description of fcn. otherwise, */
  /*         info is set as follows. */

  /*         info = 0  improper input parameters. */

  /*         info = 1  both actual and predicted relative reductions */
  /*                   in the sum of squares are at most ftol. */

  /*         info = 2  relative error between two consecutive iterates */
  /*                   is at most xtol. */

  /*         info = 3  conditions for info = 1 and info = 2 both hold. */

  /*         info = 4  the cosine of the angle between fvec and any */
  /*                   column of the jacobian is at most gtol in */
  /*                   absolute value. */

  /*         info = 5  number of calls to fcn has reached or */
  /*                   exceeded maxfev. */

  /*         info = 6  ftol is too small. no further reduction in */
  /*                   the sum of squares is possible. */

  /*         info = 7  xtol is too small. no further improvement in */
  /*                   the approximate solution x is possible. */

  /*         info = 8  gtol is too small. fvec is orthogonal to the */
  /*                   columns of the jacobian to machine precision. */

  /*       nfev is an integer output variable set to the number of */
  /*         calls to fcn. */

  /*       fjac is an output m by n array. the upper n by n submatrix */
  /*         of fjac contains an upper triangular matrix r with */
  /*         diagonal elements of nonincreasing magnitude such that */

  /*                t     t           t */
  /*               p *(jac *jac)*p = r *r, */

  /*         where p is a permutation matrix and jac is the final */
  /*         calculated jacobian. column j of p is column ipvt(j) */
  /*         (see below) of the identity matrix. the lower trapezoidal */
  /*         part of fjac contains information generated during */
  /*         the computation of r. */

  /*       ldfjac is a positive integer input variable not less than m */
  /*         which specifies the leading dimension of the array fjac. */

  /*       ipvt is an integer output array of length n. ipvt */
  /*         defines a permutation matrix p such that jac*p = q*r, */
  /*         where jac is the final calculated jacobian, q is */
  /*         orthogonal (not stored), and r is upper triangular */
  /*         with diagonal elements of nonincreasing magnitude. */
  /*         column j of p is column ipvt(j) of the identity matrix. */

  /*       qtf is an output array of length n which contains */
  /*         the first n elements of the vector (q transpose)*fvec. */

  /*       wa1, wa2, and wa3 are work arrays of length n. */

  /*       wa4 is a work array of length m. */

  /*     subprograms called */

  /*       user-supplied ...... fcn */

  /*       minpack-supplied ... dpmpar,enorm,fdjac2,lmpar,qrfac */

  /*       fortran-supplied ... dabs,dmax1,dmin1,dsqrt,mod */

  /*     argonne national laboratory. minpack project. march 1980. */
  /*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

  /*     ********** */

  /*     epsmch is the machine precision. */

  epsmch = DBL_EPSILON;

  info = 0;
  iflag = 0;
  *nfev = 0;

  /*     check the input parameters for errors. */

  if (n <= 0 || m < n || ldfjac < m || ftol < 0. || xtol < 0. || 
      gtol < 0. || maxfev <= 0 || factor <= 0.) {
    goto TERMINATE;
  }
  if (mode == 2) {
    for (j = 0; j < n; ++j) {
      if (diag[j] <= 0.) {
        goto TERMINATE;
      }
    }
  }

  /*     evaluate the function at the starting point */
  /*     and calculate its norm. */

  iflag = func(d, m, n, x, fvec, 1);
  *nfev = 1;
  if (iflag < 0) {
    goto TERMINATE;
  }
  fnorm = enorm(m, fvec);

  /*     initialize levenberg-marquardt parameter and iteration counter. */

  par = 0.;
  iter = 1;

  /*     beginning of the outer loop. */

  for (;;) {

    /*        calculate the jacobian matrix. */

    iflag = fdjac2(func, d, m, n, x, fvec, fjac, ldfjac,
        epsfcn, wa4);
    *nfev += n;
    if (iflag < 0) {
      goto TERMINATE;
    }

    /*        if requested, call fcn to enable printing of iterates. */

    if (nprint > 0) {
      iflag = 0;
      if ((iter - 1) % nprint == 0) {
        iflag = func(d, m, n, x, fvec, 0);
      }
      if (iflag < 0) {
        goto TERMINATE;
      }
    }

    /*        compute the qr factorization of the jacobian. */

    qrfac(m, n, fjac, ldfjac, 1, ipvt, n,
        wa1, wa2, wa3);

    /*        on the first iteration and if mode is 1, scale according */
    /*        to the norms of the columns of the initial jacobian. */

    if (iter == 1) {
      if (mode != 2) {
        for (j = 0; j < n; ++j) {
          diag[j] = wa2[j];
          if (wa2[j] == 0.) {
            diag[j] = 1.;
          }
        }
      }

      /*        on the first iteration, calculate the norm of the scaled x */
      /*        and initialize the step bound delta. */

      for (j = 0; j < n; ++j) {
        wa3[j] = diag[j] * x[j];
      }
      xnorm = enorm(n, wa3);
      delta = factor * xnorm;
      if (delta == 0.) {
        delta = factor;
      }
    }

    /*        form (q transpose)*fvec and store the first n components in */
    /*        qtf. */

    for (i = 0; i < m; ++i) {
      wa4[i] = fvec[i];
    }
    for (j = 0; j < n; ++j) {
      if (fjac[j + j * ldfjac] != 0.) {
        sum = 0.;
        for (i = j; i < m; ++i) {
          sum += fjac[i + j * ldfjac] * wa4[i];
        }
        temp = -sum / fjac[j + j * ldfjac];
        for (i = j; i < m; ++i) {
          wa4[i] += fjac[i + j * ldfjac] * temp;
        }
      }
      fjac[j + j * ldfjac] = wa1[j];
      qtf[j] = wa4[j];
    }

    /*        compute the norm of the scaled gradient. */

    gnorm = 0.;
    if (fnorm != 0.) {
      for (j = 0; j < n; ++j) {
        l = ipvt[j]-1;
        if (wa2[l] != 0.) {
          sum = 0.;
          for (i = 0; i <= j; ++i) {
            sum += fjac[i + j * ldfjac] * (qtf[i] / fnorm);
          }
          /* Computing MAX */
          d1 = fabs(sum / wa2[l]);
          gnorm = max(gnorm,d1);
        }
      }
    }

    /*        test for convergence of the gradient norm. */

    if (gnorm <= gtol) {
      info = 4;
    }
    if (info != 0) {
      goto TERMINATE;
    }

    /*        rescale if necessary. */

    if (mode != 2) {
      for (j = 0; j < n; ++j) {
        /* Computing MAX */
        d1 = diag[j], d2 = wa2[j];
        diag[j] = max(d1,d2);
      }
    }

    /*        beginning of the inner loop. */

    do {

      /*           determine the levenberg-marquardt parameter. */

      lmpar(n, fjac, ldfjac, ipvt, diag, qtf, delta,
          &par, wa1, wa2, wa3, wa4);

      /*           store the direction p and x + p. calculate the norm of p. */

      for (j = 0; j < n; ++j) {
        wa1[j] = -wa1[j];
        wa2[j] = x[j] + wa1[j];
        wa3[j] = diag[j] * wa1[j];
      }
      pnorm = enorm(n, wa3);

      /*           on the first iteration, adjust the initial step bound. */

      if (iter == 1) {
        delta = min(delta,pnorm);
      }

      /*           evaluate the function at x + p and calculate its norm. */

      iflag = func(d, m, n, wa2, wa4, 1);
      ++(*nfev);
      if (iflag < 0) {
        goto TERMINATE;
      }
      fnorm1 = enorm(m, wa4);

      /*           compute the scaled actual reduction. */

      actred = -1.;
      if (p1 * fnorm1 < fnorm) {
        /* Computing 2nd power */
        d1 = fnorm1 / fnorm;
        actred = 1. - d1 * d1;
      }

      /*           compute the scaled predicted reduction and */
      /*           the scaled directional derivative. */

      for (j = 0; j < n; ++j) {
        wa3[j] = 0.;
        l = ipvt[j]-1;
        temp = wa1[l];
        for (i = 0; i <= j; ++i) {
          wa3[i] += fjac[i + j * ldfjac] * temp;
        }
      }
      temp1 = enorm(n, wa3) / fnorm;
      temp2 = (sqrt(par) * pnorm) / fnorm;
      prered = temp1 * temp1 + temp2 * temp2 / p5;
      dirder = -(temp1 * temp1 + temp2 * temp2);

      /*           compute the ratio of the actual to the predicted */
      /*           reduction. */

      ratio = 0.;
      if (prered != 0.) {
        ratio = actred / prered;
      }

      /*           update the step bound. */

      if (ratio <= p25) {
        if (actred >= 0.) {
          temp = p5;
        } else {
          temp = p5 * dirder / (dirder + p5 * actred);
        }
        if (p1 * fnorm1 >= fnorm || temp < p1) {
          temp = p1;
        }
        /* Computing MIN */
        d1 = pnorm / p1;
        delta = temp * min(delta,d1);
        par /= temp;
      } else {
        if (par == 0. || ratio >= p75) {
          delta = pnorm / p5;
          par = p5 * par;
        }
      }

      /*           test for successful iteration. */

      if (ratio >= p0001) {

        /*           successful iteration. update x, fvec, and their norms. */

        for (j = 0; j < n; ++j) {
          x[j] = wa2[j];
          wa2[j] = diag[j] * x[j];
        }
        for (i = 0; i < m; ++i) {
          fvec[i] = wa4[i];
        }
        xnorm = enorm(n, wa2);
        fnorm = fnorm1;
        ++iter;
      }

      /*           tests for convergence. */

      if (fabs(actred) <= ftol && prered <= ftol && p5 * ratio <= 1.) {
        info = 1;
      }
      if (delta <= xtol * xnorm) {
        info = 2;
      }
      if (fabs(actred) <= ftol && prered <= ftol && p5 * ratio <= 1. && info == 2) {
        info = 3;
      }
      if (info != 0) {
        goto TERMINATE;
      }

      /*           tests for termination and stringent tolerances. */

      if (*nfev >= maxfev) {
        info = 5;
      }
      if (fabs(actred) <= epsmch && prered <= epsmch && p5 * ratio <= 1.) {
        info = 6;
      }
      if (delta <= epsmch * xnorm) {
        info = 7;
      }
      if (gnorm <= epsmch) {
        info = 8;
      }
      if (info != 0) {
        goto TERMINATE;
      }

      /*           end of the inner loop. repeat if iteration unsuccessful. */

    } while (ratio < p0001);

    /*        end of the outer loop. */

  }
TERMINATE:

  /*     termination, either normal or user imposed. */

  if (iflag < 0) {
    info = iflag;
  }
  if (nprint > 0) {
    func(d, m, n, x, fvec, 0);
  }
  return info;

  /*     last card of subroutine lmdif. */

} /* lmdif_ */

/*
   About the values for rdwarf and rgiant.

   The original values, both in signe-precision FORTRAN source code and in double-precision code were:
#define rdwarf 3.834e-20
#define rgiant 1.304e19
See for example:
http://www.netlib.org/slatec/src/denorm.f
http://www.netlib.org/slatec/src/enorm.f
However, rdwarf is smaller than sqrt(FLT_MIN) = 1.0842021724855044e-19, so that rdwarf**2 will
underflow. This contradicts the constraints expressed in the comments below.

We changed these constants to be sqrt(dpmpar(2))*0.9 and sqrt(dpmpar(3))*0.9, as proposed by the
implementation found in MPFIT http://cow.physics.wisc.edu/~craigm/idl/fitting.html
 */

double enorm(int n, const double *x)
{
  /* System generated locals */
  double ret_val, d1;

  /* Local variables */
  int i;
  double s1, s2, s3, xabs, x1max, x3max, agiant, floatn;

  /*     ********** */

  /*     function enorm */

  /*     given an n-vector x, this function calculates the */
  /*     euclidean norm of x. */

  /*     the euclidean norm is computed by accumulating the sum of */
  /*     squares in three different sums. the sums of squares for the */
  /*     small and large components are scaled so that no overflows */
  /*     occur. non-destructive underflows are permitted. underflows */
  /*     and overflows do not occur in the computation of the unscaled */
  /*     sum of squares for the intermediate components. */
  /*     the definitions of small, intermediate and large components */
  /*     depend on two constants, rdwarf and rgiant. the main */
  /*     restrictions on these constants are that rdwarf**2 not */
  /*     underflow and rgiant**2 not overflow. the constants */
  /*     given here are suitable for every known computer. */

  /*     the function statement is */

  /*       double precision function enorm(n,x) */

  /*     where */

  /*       n is a positive integer input variable. */

  /*       x is an input array of length n. */

  /*     subprograms called */

  /*       fortran-supplied ... dabs,dsqrt */

  /*     argonne national laboratory. minpack project. march 1980. */
  /*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

  /*     ********** */

  s1 = 0.;
  s2 = 0.;
  s3 = 0.;
  x1max = 0.;
  x3max = 0.;
  floatn = (double) (n);
  agiant = double_giant / floatn;
  for (i = 0; i < n; ++i) {
    xabs = fabs(x[i]);
    if (xabs <= double_dwarf || xabs >= agiant) {
      if (xabs > double_dwarf) {

        /*              sum for large components. */

        if (xabs > x1max) {
          /* Computing 2nd power */
          d1 = x1max / xabs;
          s1 = 1. + s1 * (d1 * d1);
          x1max = xabs;
        } else {
          /* Computing 2nd power */
          d1 = xabs / x1max;
          s1 += d1 * d1;
        }
      } else {

        /*              sum for small components. */

        if (xabs > x3max) {
          /* Computing 2nd power */
          d1 = x3max / xabs;
          s3 = 1. + s3 * (d1 * d1);
          x3max = xabs;
        } else {
          if (xabs != 0.) {
            /* Computing 2nd power */
            d1 = xabs / x3max;
            s3 += d1 * d1;
          }
        }
      }
    } else {

      /*           sum for intermediate components. */

      /* Computing 2nd power */
      s2 += xabs * xabs;
    }
  }

  /*     calculation of norm. */

  if (s1 != 0.) {
    ret_val = x1max * sqrt(s1 + (s2 / x1max) / x1max);
  } else {
    if (s2 != 0.) {
      if (s2 >= x3max) {
        ret_val = sqrt(s2 * (1. + (x3max / s2) * (x3max * s3)));
      } else {
        ret_val = sqrt(x3max * ((s2 / x3max) + (x3max * s3)));
      }
    } else {
      ret_val = x3max * sqrt(s3);
    }
  }
  return ret_val;

  /*     last card of function enorm. */
} /* enorm_ */

int fdjac2(int (*func)(void *d, int n, int m, double *p, double *hx, int iflag), 
    void *d, int m, int n, double *x, 
    const double *fvec, double *fjac, int ldfjac,
    double epsfcn, double *wa)
{
  /* Local variables */
  double h;
  int i, j;
  double eps, temp, epsmch;
  int iflag;

  /*     ********** */

  /*     subroutine fdjac2 */

  /*     this subroutine computes a forward-difference approximation */
  /*     to the m by n jacobian matrix associated with a specified */
  /*     problem of m functions in n variables. */

  /*     the subroutine statement is */

  /*       subroutine fdjac2(fcn,m,n,x,fvec,fjac,ldfjac,iflag,epsfcn,wa) */

  /*     where */

  /*       fcn is the name of the user-supplied subroutine which */
  /*         calculates the functions. fcn must be declared */
  /*         in an external statement in the user calling */
  /*         program, and should be written as follows. */

  /*         subroutine fcn(m,n,x,fvec,iflag) */
  /*         integer m,n,iflag */
  /*         double precision x(n),fvec(m) */
  /*         ---------- */
  /*         calculate the functions at x and */
  /*         return this vector in fvec. */
  /*         ---------- */
  /*         return */
  /*         end */

  /*         the value of iflag should not be changed by fcn unless */
  /*         the user wants to terminate execution of fdjac2. */
  /*         in this case set iflag to a negative integer. */

  /*       m is a positive integer input variable set to the number */
  /*         of functions. */

  /*       n is a positive integer input variable set to the number */
  /*         of variables. n must not exceed m. */

  /*       x is an input array of length n. */

  /*       fvec is an input array of length m which must contain the */
  /*         functions evaluated at x. */

  /*       fjac is an output m by n array which contains the */
  /*         approximation to the jacobian matrix evaluated at x. */

  /*       ldfjac is a positive integer input variable not less than m */
  /*         which specifies the leading dimension of the array fjac. */

  /*       iflag is an integer variable which can be used to terminate */
  /*         the execution of fdjac2. see description of fcn. */

  /*       epsfcn is an input variable used in determining a suitable */
  /*         step length for the forward-difference approximation. this */
  /*         approximation assumes that the relative errors in the */
  /*         functions are of the order of epsfcn. if epsfcn is less */
  /*         than the machine precision, it is assumed that the relative */
  /*         errors in the functions are of the order of the machine */
  /*         precision. */

  /*       wa is a work array of length m. */

  /*     subprograms called */

  /*       user-supplied ...... fcn */

  /*       minpack-supplied ... dpmpar */

  /*       fortran-supplied ... dabs,dmax1,dsqrt */

  /*     argonne national laboratory. minpack project. march 1980. */
  /*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

  /*     ********** */

  /*     epsmch is the machine precision. */

  epsmch = DBL_EPSILON;

  eps = sqrt((max(epsfcn,epsmch)));
  for (j = 0; j < n; ++j) {
    temp = x[j];
    h = eps * fabs(temp);
    if (h == 0.) {
      h = eps;
    }
    x[j] = temp + h;
    /* the last parameter of fcn_mn() is set to 2 to tell calls
       made to compute the function from calls made to compute
       the Jacobian (see fcn() in tlmfdrv.c) */
    iflag = func(d, m, n, x, wa, 2);
    if (iflag < 0) {
      return iflag;
    }
    x[j] = temp;
    for (i = 0; i < m; ++i) {
      fjac[i + j * ldfjac] = (wa[i] - fvec[i]) / h;
    }
  }
  return 0;

  /*     last card of subroutine fdjac2. */

} /* fdjac2_ */

void qrfac(int m, int n, double *a, int
    lda, int pivot, int *ipvt, int lipvt, double *rdiag,
    double *acnorm, double *wa)
{

  /* System generated locals */
  double d1;

  /* Local variables */
  int i, j, k, jp1;
  double sum;
  double temp;
  int minmn;
  double epsmch;
  double ajnorm;

  /*     ********** */

  /*     subroutine qrfac */

  /*     this subroutine uses householder transformations with column */
  /*     pivoting (optional) to compute a qr factorization of the */
  /*     m by n matrix a. that is, qrfac determines an orthogonal */
  /*     matrix q, a permutation matrix p, and an upper trapezoidal */
  /*     matrix r with diagonal elements of nonincreasing magnitude, */
  /*     such that a*p = q*r. the householder transformation for */
  /*     column k, k = 1,2,...,min(m,n), is of the form */

  /*                           t */
  /*           i - (1/u(k))*u*u */

  /*     where u has zeros in the first k-1 positions. the form of */
  /*     this transformation and the method of pivoting first */
  /*     appeared in the corresponding linpack subroutine. */

  /*     the subroutine statement is */

  /*       subroutine qrfac(m,n,a,lda,pivot,ipvt,lipvt,rdiag,acnorm,wa) */

  /*     where */

  /*       m is a positive integer input variable set to the number */
  /*         of rows of a. */

  /*       n is a positive integer input variable set to the number */
  /*         of columns of a. */

  /*       a is an m by n array. on input a contains the matrix for */
  /*         which the qr factorization is to be computed. on output */
  /*         the strict upper trapezoidal part of a contains the strict */
  /*         upper trapezoidal part of r, and the lower trapezoidal */
  /*         part of a contains a factored form of q (the non-trivial */
  /*         elements of the u vectors described above). */

  /*       lda is a positive integer input variable not less than m */
  /*         which specifies the leading dimension of the array a. */

  /*       pivot is a logical input variable. if pivot is set true, */
  /*         then column pivoting is enforced. if pivot is set false, */
  /*         then no column pivoting is done. */

  /*       ipvt is an integer output array of length lipvt. ipvt */
  /*         defines the permutation matrix p such that a*p = q*r. */
  /*         column j of p is column ipvt(j) of the identity matrix. */
  /*         if pivot is false, ipvt is not referenced. */

  /*       lipvt is a positive integer input variable. if pivot is false, */
  /*         then lipvt may be as small as 1. if pivot is true, then */
  /*         lipvt must be at least n. */

  /*       rdiag is an output array of length n which contains the */
  /*         diagonal elements of r. */

  /*       acnorm is an output array of length n which contains the */
  /*         norms of the corresponding columns of the input matrix a. */
  /*         if this information is not needed, then acnorm can coincide */
  /*         with rdiag. */

  /*       wa is a work array of length n. if pivot is false, then wa */
  /*         can coincide with rdiag. */

  /*     subprograms called */

  /*       minpack-supplied ... dpmpar,enorm */

  /*       fortran-supplied ... dmax1,dsqrt,min0 */

  /*     argonne national laboratory. minpack project. march 1980. */
  /*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

  /*     ********** */
  (void)lipvt;

  /*     epsmch is the machine precision. */

  epsmch = DBL_EPSILON;

  /*     compute the initial column norms and initialize several arrays. */

  for (j = 0; j < n; ++j) {
    acnorm[j] = enorm(m, &a[j * lda + 0]);
    rdiag[j] = acnorm[j];
    wa[j] = rdiag[j];
    if (pivot) {
      ipvt[j] = j+1;
    }
  }

  /*     reduce a to r with householder transformations. */

  minmn = min(m,n);
  for (j = 0; j < minmn; ++j) {
    if (pivot) {

      /*        bring the column of largest norm into the pivot position. */

      int kmax = j;
      for (k = j; k < n; ++k) {
        if (rdiag[k] > rdiag[kmax]) {
          kmax = k;
        }
      }
      if (kmax != j) {
        for (i = 0; i < m; ++i) {
          temp = a[i + j * lda];
          a[i + j * lda] = a[i + kmax * lda];
          a[i + kmax * lda] = temp;
        }
        rdiag[kmax] = rdiag[j];
        wa[kmax] = wa[j];
        k = ipvt[j];
        ipvt[j] = ipvt[kmax];
        ipvt[kmax] = k;
      }
    }

    /*        compute the householder transformation to reduce the */
    /*        j-th column of a to a multiple of the j-th unit vector. */

    ajnorm = enorm(m - (j+1) + 1, &a[j + j * lda]);
    if (ajnorm != 0.) {
      if (a[j + j * lda] < 0.) {
        ajnorm = -ajnorm;
      }
      for (i = j; i < m; ++i) {
        a[i + j * lda] /= ajnorm;
      }
      a[j + j * lda] += 1.;

      /*        apply the transformation to the remaining columns */
      /*        and update the norms. */

      jp1 = j + 1;
      if (n > jp1) {
        for (k = jp1; k < n; ++k) {
          sum = 0.;
          for (i = j; i < m; ++i) {
            sum += a[i + j * lda] * a[i + k * lda];
          }
          temp = sum / a[j + j * lda];
          for (i = j; i < m; ++i) {
            a[i + k * lda] -= temp * a[i + j * lda];
          }
          if (pivot && rdiag[k] != 0.) {
            temp = a[j + k * lda] / rdiag[k];
            /* Computing MAX */
            d1 = 1. - temp * temp;
            rdiag[k] *= sqrt((max((double)0.,d1)));
            /* Computing 2nd power */
            d1 = rdiag[k] / wa[k];
            if (p05 * (d1 * d1) <= epsmch) {
              rdiag[k] = enorm(m - (j+1), &a[jp1 + k * lda]);
              wa[k] = rdiag[k];
            }
          }
        }
      }
    }
    rdiag[j] = -ajnorm;
  }

  /*     last card of subroutine qrfac. */
} /* qrfac_ */

/* lmpar.f -- translated by f2c (version 20020621).
   You must link the resulting object file with the libraries:
   -lf2c -lm   (in that order)
 */

void lmpar(int n, double *r, int ldr, 
    const int *ipvt, const double *diag, const double *qtb, double delta, 
    double *par, double *x, double *sdiag, double *wa1, 
    double *wa2)
{
  /* Initialized data */

  /* System generated locals */
  double d1, d2;

  /* Local variables */
  int j, l;
  double fp;
  double parc, parl;
  int iter;
  double temp, paru, dwarf;
  int nsing;
  double gnorm;
  double dxnorm;

  /*     ********** */

  /*     subroutine lmpar */

  /*     given an m by n matrix a, an n by n nonsingular diagonal */
  /*     matrix d, an m-vector b, and a positive number delta, */
  /*     the problem is to determine a value for the parameter */
  /*     par such that if x solves the system */

  /*           a*x = b ,     sqrt(par)*d*x = 0 , */

  /*     in the least squares sense, and dxnorm is the euclidean */
  /*     norm of d*x, then either par is zero and */

  /*           (dxnorm-delta) .le. 0.1*delta , */

  /*     or par is positive and */

  /*           abs(dxnorm-delta) .le. 0.1*delta . */

  /*     this subroutine completes the solution of the problem */
  /*     if it is provided with the necessary information from the */
  /*     qr factorization, with column pivoting, of a. that is, if */
  /*     a*p = q*r, where p is a permutation matrix, q has orthogonal */
  /*     columns, and r is an upper triangular matrix with diagonal */
  /*     elements of nonincreasing magnitude, then lmpar expects */
  /*     the full upper triangle of r, the permutation matrix p, */
  /*     and the first n components of (q transpose)*b. on output */
  /*     lmpar also provides an upper triangular matrix s such that */

  /*            t   t                   t */
  /*           p *(a *a + par*d*d)*p = s *s . */

  /*     s is employed within lmpar and may be of separate interest. */

  /*     only a few iterations are generally needed for convergence */
  /*     of the algorithm. if, however, the limit of 10 iterations */
  /*     is reached, then the output par will contain the best */
  /*     value obtained so far. */

  /*     the subroutine statement is */

  /*       subroutine lmpar(n,r,ldr,ipvt,diag,qtb,delta,par,x,sdiag, */
  /*                        wa1,wa2) */

  /*     where */

  /*       n is a positive integer input variable set to the order of r. */

  /*       r is an n by n array. on input the full upper triangle */
  /*         must contain the full upper triangle of the matrix r. */
  /*         on output the full upper triangle is unaltered, and the */
  /*         strict lower triangle contains the strict upper triangle */
  /*         (transposed) of the upper triangular matrix s. */

  /*       ldr is a positive integer input variable not less than n */
  /*         which specifies the leading dimension of the array r. */

  /*       ipvt is an integer input array of length n which defines the */
  /*         permutation matrix p such that a*p = q*r. column j of p */
  /*         is column ipvt(j) of the identity matrix. */

  /*       diag is an input array of length n which must contain the */
  /*         diagonal elements of the matrix d. */

  /*       qtb is an input array of length n which must contain the first */
  /*         n elements of the vector (q transpose)*b. */

  /*       delta is a positive input variable which specifies an upper */
  /*         bound on the euclidean norm of d*x. */

  /*       par is a nonnegative variable. on input par contains an */
  /*         initial estimate of the levenberg-marquardt parameter. */
  /*         on output par contains the final estimate. */

  /*       x is an output array of length n which contains the least */
  /*         squares solution of the system a*x = b, sqrt(par)*d*x = 0, */
  /*         for the output par. */

  /*       sdiag is an output array of length n which contains the */
  /*         diagonal elements of the upper triangular matrix s. */

  /*       wa1 and wa2 are work arrays of length n. */

  /*     subprograms called */

  /*       minpack-supplied ... dpmpar,enorm,qrsolv */

  /*       fortran-supplied ... dabs,dmax1,dmin1,dsqrt */

  /*     argonne national laboratory. minpack project. march 1980. */
  /*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

  /*     ********** */

  /*     dwarf is the smallest positive magnitude. */

  dwarf = DBL_MIN;

  /*     compute and store in x the gauss-newton direction. if the */
  /*     jacobian is rank-deficient, obtain a least squares solution. */

  nsing = n;
  for (j = 0; j < n; ++j) {
    wa1[j] = qtb[j];
    if (r[j + j * ldr] == 0. && nsing == n) {
      nsing = j;
    }
    if (nsing < n) {
      wa1[j] = 0.;
    }
  }
  if (nsing >= 1) {
    int k;
    for (k = 1; k <= nsing; ++k) {
      j = nsing - k;
      wa1[j] /= r[j + j * ldr];
      temp = wa1[j];
      if (j >= 1) {
        int i;
        for (i = 0; i < j; ++i) {
          wa1[i] -= r[i + j * ldr] * temp;
        }
      }
    }
  }
  for (j = 0; j < n; ++j) {
    l = ipvt[j]-1;
    x[l] = wa1[j];
  }

  /*     initialize the iteration counter. */
  /*     evaluate the function at the origin, and test */
  /*     for acceptance of the gauss-newton direction. */

  iter = 0;
  for (j = 0; j < n; ++j) {
    wa2[j] = diag[j] * x[j];
  }
  dxnorm = enorm(n, wa2);
  fp = dxnorm - delta;
  if (fp <= p1 * delta) {
    goto TERMINATE;
  }

  /*     if the jacobian is not rank deficient, the newton */
  /*     step provides a lower bound, parl, for the zero of */
  /*     the function. otherwise set this bound to zero. */

  parl = 0.;
  if (nsing >= n) {
    for (j = 0; j < n; ++j) {
      l = ipvt[j]-1;
      wa1[j] = diag[l] * (wa2[l] / dxnorm);
    }
    for (j = 0; j < n; ++j) {
      double sum = 0.;
      if (j >= 1) {
        int i;
        for (i = 0; i < j; ++i) {
          sum += r[i + j * ldr] * wa1[i];
        }
      }
      wa1[j] = (wa1[j] - sum) / r[j + j * ldr];
    }
    temp = enorm(n, wa1);
    parl = fp / delta / temp / temp;
  }

  /*     calculate an upper bound, paru, for the zero of the function. */

  for (j = 0; j < n; ++j) {
    double sum = 0.;
    int i;

    for (i = 0; i <= j; ++i) {
      sum += r[i + j * ldr] * qtb[i];
    }
    l = ipvt[j]-1;
    wa1[j] = sum / diag[l];
  }
  gnorm = enorm(n, wa1);
  paru = gnorm / delta;
  if (paru == 0.) {
    paru = dwarf / min(delta,(double)p1) /* / p001 ??? */;
  }

  /*     if the input par lies outside of the interval (parl,paru), */
  /*     set par to the closer endpoint. */

  *par = max(*par,parl);
  *par = min(*par,paru);
  if (*par == 0.) {
    *par = gnorm / dxnorm;
  }

  /*     beginning of an iteration. */

  for (;;) {
    ++iter;

    /*        evaluate the function at the current value of par. */

    if (*par == 0.) {
      /* Computing MAX */
      d1 = dwarf, d2 = p001 * paru;
      *par = max(d1,d2);
    }
    temp = sqrt(*par);
    for (j = 0; j < n; ++j) {
      wa1[j] = temp * diag[j];
    }
    qrsolv(n, r, ldr, ipvt, wa1, qtb, x, sdiag, wa2);
    for (j = 0; j < n; ++j) {
      wa2[j] = diag[j] * x[j];
    }
    dxnorm = enorm(n, wa2);
    temp = fp;
    fp = dxnorm - delta;

    /*        if the function is small enough, accept the current value */
    /*        of par. also test for the exceptional cases where parl */
    /*        is zero or the number of iterations has reached 10. */

    if (fabs(fp) <= p1 * delta || (parl == 0. && fp <= temp && temp < 0.) || iter == 10) {
      goto TERMINATE;
    }

    /*        compute the newton correction. */

    for (j = 0; j < n; ++j) {
      l = ipvt[j]-1;
      wa1[j] = diag[l] * (wa2[l] / dxnorm);
    }
    for (j = 0; j < n; ++j) {
      wa1[j] /= sdiag[j];
      temp = wa1[j];
      if (n > j+1) {
        int i;
        for (i = j+1; i < n; ++i) {
          wa1[i] -= r[i + j * ldr] * temp;
        }
      }
    }
    temp = enorm(n, wa1);
    parc = fp / delta / temp / temp;

    /*        depending on the sign of the function, update parl or paru. */

    if (fp > 0.) {
      parl = max(parl,*par);
    }
    if (fp < 0.) {
      paru = min(paru,*par);
    }

    /*        compute an improved estimate for par. */

    /* Computing MAX */
    d1 = parl, d2 = *par + parc;
    *par = max(d1,d2);

    /*        end of an iteration. */

  }
TERMINATE:

  /*     termination. */

  if (iter == 0) {
    *par = 0.;
  }

  /*     last card of subroutine lmpar. */

} /* lmpar_ */

void qrsolv(int n, double *r, int ldr, 
    const int *ipvt, const double *diag, const double *qtb, double *x, 
    double *sdiag, double *wa)
{
  /* Initialized data */

  /* Local variables */
  int i, j, k, l;
  double cos, sin, sum, temp;
  int nsing;
  double qtbpj;

  /*     ********** */

  /*     subroutine qrsolv */

  /*     given an m by n matrix a, an n by n diagonal matrix d, */
  /*     and an m-vector b, the problem is to determine an x which */
  /*     solves the system */

  /*           a*x = b ,     d*x = 0 , */

  /*     in the least squares sense. */

  /*     this subroutine completes the solution of the problem */
  /*     if it is provided with the necessary information from the */
  /*     qr factorization, with column pivoting, of a. that is, if */
  /*     a*p = q*r, where p is a permutation matrix, q has orthogonal */
  /*     columns, and r is an upper triangular matrix with diagonal */
  /*     elements of nonincreasing magnitude, then qrsolv expects */
  /*     the full upper triangle of r, the permutation matrix p, */
  /*     and the first n components of (q transpose)*b. the system */
  /*     a*x = b, d*x = 0, is then equivalent to */

  /*                  t       t */
  /*           r*z = q *b ,  p *d*p*z = 0 , */

  /*     where x = p*z. if this system does not have full rank, */
  /*     then a least squares solution is obtained. on output qrsolv */
  /*     also provides an upper triangular matrix s such that */

  /*            t   t               t */
  /*           p *(a *a + d*d)*p = s *s . */

  /*     s is computed within qrsolv and may be of separate interest. */

  /*     the subroutine statement is */

  /*       subroutine qrsolv(n,r,ldr,ipvt,diag,qtb,x,sdiag,wa) */

  /*     where */

  /*       n is a positive integer input variable set to the order of r. */

  /*       r is an n by n array. on input the full upper triangle */
  /*         must contain the full upper triangle of the matrix r. */
  /*         on output the full upper triangle is unaltered, and the */
  /*         strict lower triangle contains the strict upper triangle */
  /*         (transposed) of the upper triangular matrix s. */

  /*       ldr is a positive integer input variable not less than n */
  /*         which specifies the leading dimension of the array r. */

  /*       ipvt is an integer input array of length n which defines the */
  /*         permutation matrix p such that a*p = q*r. column j of p */
  /*         is column ipvt(j) of the identity matrix. */

  /*       diag is an input array of length n which must contain the */
  /*         diagonal elements of the matrix d. */

  /*       qtb is an input array of length n which must contain the first */
  /*         n elements of the vector (q transpose)*b. */

  /*       x is an output array of length n which contains the least */
  /*         squares solution of the system a*x = b, d*x = 0. */

  /*       sdiag is an output array of length n which contains the */
  /*         diagonal elements of the upper triangular matrix s. */

  /*       wa is a work array of length n. */

  /*     subprograms called */

  /*       fortran-supplied ... dabs,dsqrt */

  /*     argonne national laboratory. minpack project. march 1980. */
  /*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

  /*     ********** */

  /*     copy r and (q transpose)*b to preserve input and initialize s. */
  /*     in particular, save the diagonal elements of r in x. */

  for (j = 0; j < n; ++j) {
    for (i = j; i < n; ++i) {
      r[i + j * ldr] = r[j + i * ldr];
    }
    x[j] = r[j + j * ldr];
    wa[j] = qtb[j];
  }

  /*     eliminate the diagonal matrix d using a givens rotation. */

  for (j = 0; j < n; ++j) {

    /*        prepare the row of d to be eliminated, locating the */
    /*        diagonal element using p from the qr factorization. */

    l = ipvt[j]-1;
    if (diag[l] != 0.) {
      for (k = j; k < n; ++k) {
        sdiag[k] = 0.;
      }
      sdiag[j] = diag[l];

      /*        the transformations to eliminate the row of d */
      /*        modify only a single element of (q transpose)*b */
      /*        beyond the first n, which is initially zero. */

      qtbpj = 0.;
      for (k = j; k < n; ++k) {

        /*           determine a givens rotation which eliminates the */
        /*           appropriate element in the current row of d. */

        if (sdiag[k] != 0.) {
          if (fabs(r[k + k * ldr]) < fabs(sdiag[k])) {
            double cotan;
            cotan = r[k + k * ldr] / sdiag[k];
            sin = p5 / sqrt(p25 + p25 * (cotan * cotan));
            cos = sin * cotan;
          } else {
            double tan;
            tan = sdiag[k] / r[k + k * ldr];
            cos = p5 / sqrt(p25 + p25 * (tan * tan));
            sin = cos * tan;
          }

          /*           compute the modified diagonal element of r and */
          /*           the modified element of ((q transpose)*b,0). */

          temp = cos * wa[k] + sin * qtbpj;
          qtbpj = -sin * wa[k] + cos * qtbpj;
          wa[k] = temp;

          /*           accumulate the tranformation in the row of s. */
          r[k + k * ldr] = cos * r[k + k * ldr] + sin * sdiag[k];
          if (n > k+1) {
            for (i = k+1; i < n; ++i) {
              temp = cos * r[i + k * ldr] + sin * sdiag[i];
              sdiag[i] = -sin * r[i + k * ldr] + cos * sdiag[i];
              r[i + k * ldr] = temp;
            }
          }
        }
      }
    }

    /*        store the diagonal element of s and restore */
    /*        the corresponding diagonal element of r. */

    sdiag[j] = r[j + j * ldr];
    r[j + j * ldr] = x[j];
  }

  /*     solve the triangular system for z. if the system is */
  /*     singular, then obtain a least squares solution. */

  nsing = n;
  for (j = 0; j < n; ++j) {
    if (sdiag[j] == 0. && nsing == n) {
      nsing = j;
    }
    if (nsing < n) {
      wa[j] = 0.;
    }
  }
  if (nsing >= 1) {
    for (k = 1; k <= nsing; ++k) {
      j = nsing - k;
      sum = 0.;
      if (nsing > j+1) {
        for (i = j+1; i < nsing; ++i) {
          sum += r[i + j * ldr] * wa[i];
        }
      }
      wa[j] = (wa[j] - sum) / sdiag[j];
    }
  }

  /*     permute the components of z back to components of x. */

  for (j = 0; j < n; ++j) {
    l = ipvt[j]-1;
    x[l] = wa[j];
  }
  return;

  /*     last card of subroutine qrsolv. */

} /* qrsolv_ */
