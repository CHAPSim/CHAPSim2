!##############################################################################
module precision_mod
  
  integer, parameter :: I4 = selected_int_kind( 4 )
  integer, parameter :: I8 = selected_int_kind( 8 )
  integer, parameter :: I15 = selected_int_kind( 15 )
  integer, parameter :: SP = selected_real_kind( p = 6, r = 37 )
  integer, parameter :: DP = selected_real_kind( p = 15, r = 307 )
  integer, parameter :: QP = selected_real_kind( p = 33, r = 4931 )

  integer, parameter :: WP = DP

end module precision_mod

!##############################################################################
module parameters_constant_mod
  use precision_mod

  real(WP), parameter :: ZPONE     = 0.1_WP
  real(WP), parameter :: ZPTWO     = 0.2_WP
  real(WP), parameter :: ZPTHREE   = 0.3_WP
  real(WP), parameter :: ZPFOUR    = 0.4_WP
  real(WP), parameter :: ZPFIVE    = 0.5_WP
  real(WP), parameter :: ZPSIX     = 0.6_WP
  real(WP), parameter :: ZPSEVEN   = 0.7_WP
  real(WP), parameter :: ZPEIGHT   = 0.8_WP
  real(WP), parameter :: ZPNINE    = 0.9_WP

  real(WP), parameter :: HALF      = 0.5_WP
  real(WP), parameter :: ZERO      = 0.0_WP
  real(WP), parameter :: ONE       = 1.0_WP
  real(WP), parameter :: ONEPFIVE  = 1.5_WP
  real(WP), parameter :: TWO       = 2.0_WP
  real(WP), parameter :: THREE     = 3.0_WP
  real(WP), parameter :: FOUR      = 4.0_WP
  real(WP), parameter :: FIVE      = 5.0_WP
  real(WP), parameter :: SIX       = 6.0_WP
  real(WP), parameter :: SEVEN     = 7.0_WP
  real(WP), parameter :: EIGHT     = 8.0_WP
  real(WP), parameter :: NINE      = 9.0_WP

  real(WP), parameter :: TWELVE    = 12.0_WP 
  real(WP), parameter :: FIFTEEN   = 15.0_WP
  real(WP), parameter :: SEVENTEEN = 17.0_WP
  real(WP), parameter :: SIXTY     = 60.0_WP

  real(WP), parameter :: MINP      = 1.0E-20_WP
  real(WP), parameter :: MAXP      = 1.0E20_WP

  real(WP), parameter :: MINN      = -1.0E20_WP
  real(WP), parameter :: MAXN      = -1.0E-20_WP


  real(WP), parameter :: TRUNCERR = 1.0E-15_WP

  real(WP), parameter :: PI = dacos( -ONE )
  real(WP), parameter :: TWOPI = TWO * dacos( -ONE )

  real(WP), parameter, dimension(3, 3) :: KRONECKER_DELTA = &
                                            reshape( (/ &
                                            ONE, ZERO, ZERO, &
                                            ZERO, ONE, ZERO, &
                                            ZERO, ZERO, ONE  /), &
                                            (/3, 3/) )
end module parameters_constant_mod


!##############################################################################
module math_mod
  use precision_mod

  interface sqrt_wp
    module procedure sqrt_sp
    module procedure sqrt_dp
  end interface sqrt_wp

  interface tanh_wp
    module procedure tanh_sp
    module procedure tanh_dp
  end interface tanh_wp
  
contains

  pure function sqrt_sp ( r ) result(d)
    real(kind = SP), intent(in) :: r
    real(kind = SP) :: d
    d = sqrt ( r )
  end function

  pure function sqrt_dp ( r ) result (d)
    real(kind = DP), intent(in) :: r
    real(kind = DP) :: d
    d = dsqrt ( r ) 
  end function


  pure function tanh_sp ( r ) result(d)
    real(kind = SP), intent(in) :: r
    real(kind = SP) :: d
    d = tanh ( r )
  end function

  pure function tanh_dp ( r ) result (d)
    real(kind = DP), intent(in) :: r
    real(kind = DP) :: d
    d = dtanh ( r ) 
  end function

end module math_mod


