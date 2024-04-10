module boundary_conditions_mod

  character(12) :: filename(5)
  
  private :: map_bc_1d_uprofile
  private :: apply_bc_constant_flow
  public  :: configure_bc_type
  public  :: configure_bc_vars
  public  :: update_bc_interface_flow
  public  :: update_bc_interface_thermo

  public  :: apply_bc_const
  !public  :: apply_convective_outlet
  
contains

!==========================================================================================================
!==========================================================================================================
  subroutine  map_bc_1d_uprofile(filename, n, y, u)
    use parameters_constant_mod 
    use udf_type_mod
    implicit none 
    character(*), intent(in) :: filename
    integer,  intent(in)  :: n
    real(WP), intent(in)  :: y(n)
    real(WP), intent(out) :: u(n)

    integer, parameter :: IOMSG_LEN = 200
    character(len = IOMSG_LEN) :: iotxt
    integer :: ioerr, inputUnit
    character(len = 80) :: str
    
    real(WP) :: rtmp
    integer :: i, nn
    real(WP), allocatable :: uprofile(:)
    real(WP), allocatable :: yy(:)

    !----------------------------------------------------------------------------------------------------------
    ! to read given u-velocity profile, dimensionless, x/H, U/Umean
    !----------------------------------------------------------------------------------------------------------

    open ( newunit = inputUnit,     &
           file    = trim(filename), &
           status  = 'old',         &
           action  = 'read',        &
           iostat  = ioerr,         &
           iomsg   = iotxt)
    if(ioerr /= 0) then
      write (*, *) 'Problem openning : '//trim(filename)
      write (*, *) 'Message: ', trim (iotxt)
      stop 4
    end if

    nn = 0
    read(inputUnit, *, iostat = ioerr) str

    do
      read(inputUnit, *, iostat = ioerr) rtmp, rtmp
      if(ioerr /= 0) exit
      nn = nn + 1
    end do
    rewind(inputUnit)
    !----------------------------------------------------------------------------------------------------------
    ! to read given u-velocity profile, dimensionless, x/H, U/Umean
    !----------------------------------------------------------------------------------------------------------
    allocate ( uprofile (nn) )
    allocate ( yy (nn) )

    read(inputUnit, *, iostat = ioerr) str
    do i = 1, nn
      read(inputUnit, *, iostat = ioerr) yy(i), uprofile(i)
    end do
    close(inputUnit)


    call map_1d_profile_to_case(nn, yy, uprofile, n, y, u)


    deallocate(uprofile)
    deallocate(yy)

    return
  end subroutine


!==========================================================================================================
!> \brief Apply b.c. conditions 
!---------------------------------------------------------------------------------------------------------- 
!> Scope:  mpi    called-freq    xdomain     module
!>         all    once           specified   public
!----------------------------------------------------------------------------------------------------------
! Arguments
!----------------------------------------------------------------------------------------------------------
!  mode           name          role                                           
!----------------------------------------------------------------------------------------------------------
!> \param[in]     d             domain
!> \param[out]    f             flow
!==========================================================================================================
  subroutine apply_bc_constant_flow (dm) ! apply once only
    use parameters_constant_mod
    use udf_type_mod
    implicit none
    type(t_domain), intent( inout)   :: dm

    real(WP) :: var1y(1:dm%np(2))
    
    integer :: m, n, k, ny

    ! -3-1-||||-2-4
    !do m = 1, NBC ! u, v, w, p, T(dim)

! ux - 
    do n = 1, 2
      dm%fbcx_qx(n, :, :) = dm%fbcx_const(n, 1)
      dm%fbcy_qx(:, n, :) = dm%fbcy_const(n, 1)
      dm%fbcz_qx(:, :, n) = dm%fbcz_const(n, 1)
    end do
    do n = 3, 4
      dm%fbcx_qx(n, :, :) = dm%fbcx_const(n - 2, 1)
      dm%fbcy_qx(:, n, :) = dm%fbcy_const(n - 2, 1)
      dm%fbcz_qx(:, :, n) = dm%fbcz_const(n - 2, 1)
    end do
! uy- 
    do n = 1, 2
      dm%fbcx_qy(n, :, :) = dm%fbcx_const(n, 2)
      dm%fbcy_qy(:, n, :) = dm%fbcy_const(n, 2)
      dm%fbcz_qy(:, :, n) = dm%fbcz_const(n, 2)
    end do
    do n = 3, 4
      dm%fbcx_qy(n, :, :) = dm%fbcx_const(n - 2, 2)
      dm%fbcy_qy(:, n, :) = dm%fbcy_const(n - 2, 2)
      dm%fbcz_qy(:, :, n) = dm%fbcz_const(n - 2, 2)
    end do
! uz- 
    do n = 1, 2
      dm%fbcx_qz(n, :, :) = dm%fbcx_const(n, 3)
      dm%fbcy_qz(:, n, :) = dm%fbcy_const(n, 3)
      dm%fbcz_qz(:, :, n) = dm%fbcz_const(n, 3)
    end do
    do n = 3, 4
      dm%fbcx_qz(n, :, :) = dm%fbcx_const(n - 2, 3)
      dm%fbcy_qz(:, n, :) = dm%fbcy_const(n - 2, 3)
      dm%fbcz_qz(:, :, n) = dm%fbcz_const(n - 2, 3)
    end do
! pr- 
    do n = 1, 2
      dm%fbcx_pr(n, :, :) = dm%fbcx_const(n, 4)
      dm%fbcy_pr(:, n, :) = dm%fbcy_const(n, 4)
      dm%fbcz_pr(:, :, n) = dm%fbcz_const(n, 4)
    end do
    do n = 3, 4
      dm%fbcx_pr(n, :, :) = dm%fbcx_const(n - 2, 4)
      dm%fbcy_pr(:, n, :) = dm%fbcy_const(n - 2, 4)
      dm%fbcz_pr(:, :, n) = dm%fbcz_const(n - 2, 4)
    end do

!----------------------------------------------------------------------------------------------------------
! to build up bc for var(x_const, y, z)
!----------------------------------------------------------------------------------------------------------
    ! filename(1) = 'pf1d_u1y.dat' !(undim)
    ! filename(2) = 'pf1d_v1y.dat' !(undim)
    ! filename(3) = 'pf1d_w1y.dat' !(undim)
    ! filename(4) = 'pf1d_p1y.dat' !(undim)
    ! filename(5) = 'pf1d_T1y.dat' !(dim  )
    ! do m = 1, NBC
    !   if(dm%ibcx_nominal(1, m) == IBC_PROFILE1D) then
    !     if(m /= 2) then
    !       ny = dm%nc(2)
    !       call map_bc_1d_uprofile( filename(m), ny, dm%yc, var1y(1:ny) )
    !     else
    !       ny = dm%np(2)
    !       call map_bc_1d_uprofile( filename(m), ny, dm%yp, var1y(1:ny) )
    !     end if
    !     do k = 1, size(dm%fbcx_var, 3) 
    !       do j = 1, 
    !       dm%fbcx_var(1, 1:ny, k, m) = var1y(1:ny) ! wrong
    !     end do
    !   end if
    ! end do

    return
  end subroutine

!==========================================================================================================
!==========================================================================================================
  subroutine configure_bc_type(dm)
    use parameters_constant_mod
    use udf_type_mod
    implicit none
    type(t_domain), intent(inout) :: dm


    integer :: m, n

!----------------------------------------------------------------------------------------------------------
! to set up real bc for calculation from given nominal b.c.
!----------------------------------------------------------------------------------------------------------
    do n = 1, 2
      do m = 1, NBC
!----------------------------------------------------------------------------------------------------------
! x-direction
!----------------------------------------------------------------------------------------------------------
        if (dm%ibcx_nominal(n, m) == IBC_PROFILE1D)   then
          dm%ibcx(n, m) = IBC_DIRICHLET
        else if (dm%ibcx_nominal(n, m) == IBC_TURBGEN  .or. &
                 dm%ibcx_nominal(n, m) == IBC_DATABASE )   then
          if(m /=5) then
            dm%ibcx(n, m) = IBC_INTERIOR ! for temperature, default is no incoming thermal flow, check
          else 
            dm%ibcx(n, m) = IBC_DIRICHLET
          end if
        else if (dm%ibcx_nominal(n, m) == IBC_CONVECTIVE)   then
          dm%ibcx(n, m) = IBC_INTRPL
        else
          dm%ibcx(n, m) = dm%ibcx_nominal(n, m)   
        end if
!----------------------------------------------------------------------------------------------------------
! y-direction
!----------------------------------------------------------------------------------------------------------
        if (dm%ibcy_nominal(n, m) == IBC_PROFILE1D)   then
          dm%ibcy(n, m) = IBC_DIRICHLET
        else if (dm%ibcy_nominal(n, m) == IBC_TURBGEN  .or. &
                 dm%ibcy_nominal(n, m) == IBC_DATABASE )   then
          if(m /=5) then
            dm%ibcy(n, m) = IBC_INTERIOR
          else 
            dm%ibcy(n, m) = IBC_DIRICHLET
          end if
        else if (dm%ibcy_nominal(n, m) == IBC_CONVECTIVE)   then
          dm%ibcy(n, m) = IBC_INTRPL
        else
          dm%ibcy(n, m) = dm%ibcy_nominal(n, m)   
        end if
!----------------------------------------------------------------------------------------------------------
! z-direction
!----------------------------------------------------------------------------------------------------------
        if (dm%ibcz_nominal(n, m) == IBC_PROFILE1D)   then
          dm%ibcz(n, m) = IBC_DIRICHLET
        else if (dm%ibcz_nominal(n, m) == IBC_TURBGEN  .or. &
                 dm%ibcz_nominal(n, m) == IBC_DATABASE )   then
          if(m /=5) then
            dm%ibcz(n, m) = IBC_INTERIOR
          else 
            dm%ibcz(n, m) = IBC_DIRICHLET
          end if
        else if (dm%ibcz_nominal(n, m) == IBC_CONVECTIVE)   then
          dm%ibcz(n, m) = IBC_INTRPL
        else
          dm%ibcz(n, m) = dm%ibcz_nominal(n, m)   
        end if

      end do
    end do
!----------------------------------------------------------------------------------------------------------
! to exclude non-resonable input
!----------------------------------------------------------------------------------------------------------
    do m = 1, NBC
      if(dm%ibcx_nominal(2, m) == IBC_PROFILE1D) call Print_error_msg(" This BC IBC_PROFILE1D is not supported.")
      do n = 1, 2
        if(dm%ibcx(n, m)         >  IBC_OTHERS   ) dm%ibcx(n, m) = IBC_INTRPL
        if(dm%ibcy(n, m)         >  IBC_OTHERS   ) dm%ibcy(n, m) = IBC_INTRPL
        if(dm%ibcz(n, m)         >  IBC_OTHERS   ) dm%ibcz(n, m) = IBC_INTRPL
        if(dm%ibcy_nominal(n, m) == IBC_PROFILE1D) call Print_error_msg(" This BC IBC_PROFILE1D is not supported.")
        if(dm%ibcz_nominal(n, m) == IBC_PROFILE1D) call Print_error_msg(" This BC IBC_PROFILE1D is not supported.")
      end do
    end do

    return
  end subroutine 

  subroutine configure_bc_vars(dm)
    use parameters_constant_mod
    use udf_type_mod
    implicit none
    type(t_domain), intent(inout) :: dm

!----------------------------------------------------------------------------------------------------------
! to set up real bc values for calculation from given nominal b.c. values
! np, not nc, is used to provide enough space
! NBC = qx, qy, qz, p, T; 
! DIM = gx, gy, gz; 
! warning: this bc treatment is not proper for a inlet plane with field data.... to check and to update
!----------------------------------------------------------------------------------------------------------
    if(dm%is_thermo) then

      allocate( dm%fbcx_qx(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) ) ! default x pencil
      allocate( dm%fbcy_qx(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) ) ! default y pencil
      allocate( dm%fbcz_qx(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) ) ! default z pencil

      allocate( dm%fbcx_qy(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_qy(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_qy(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil

      allocate( dm%fbcx_qz(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_qz(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_qz(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil

      allocate( dm%fbcx_gx(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_gx(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_gx(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil

      allocate( dm%fbcx_gy(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_gy(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_gy(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil

      allocate( dm%fbcx_gz(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_gz(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_gz(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil

      allocate( dm%fbcx_pr(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_pr(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_pr(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil

      allocate( dm%ftpbcx_var(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%ftpbcy_var(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%ftpbcz_var(dm%dppp%zsz(1), dm%dppp%zsz(2),             4)  )! default z pencil

    else
      allocate( dm%fbcx_qx(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_qx(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_qx(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil

      allocate( dm%fbcx_qy(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_qy(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_qy(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil

      allocate( dm%fbcx_qz(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_qz(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_qz(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil

      allocate( dm%fbcx_pr(             4, dm%dppp%xsz(2), dm%dppp%xsz(3)) )! default x pencil
      allocate( dm%fbcy_pr(dm%dppp%ysz(1),              4, dm%dppp%ysz(3)) )! default y pencil
      allocate( dm%fbcz_pr(dm%dppp%zsz(1), dm%dppp%zsz(2),              4) )! default z pencil
    end if

    call apply_bc_constant_flow(dm)

    return
  end subroutine 

!==========================================================================================================
!==========================================================================================================
  subroutine update_bc_interface_flow(dm0, fl0, dm1, fl1)
    use parameters_constant_mod
    use udf_type_mod
    implicit none
    type(t_domain), intent(inout) :: dm0, dm1
    type(t_flow), intent(in)      :: fl0, fl1
    
    integer :: m
!----------------------------------------------------------------------------------------------------------
!   all in x-pencil
!   no overlap of values
!----------------------------------------------------------------------------------------------------------
!----------------------------------------------------------------------------------------------------------
!   bc in x - direction
!----------------------------------------------------------------------------------------------------------
    ! ux, dm0-dm1, np
    m = 1
    if(dm1%ibcx(1, m) == IBC_INTERIOR) then
      dm1%fbcx_qx(1, :, :) = fl0%qx(dm0%np_geo(1) - 1, :, :)
      dm1%fbcx_qx(3, :, :) = fl0%qx(dm0%np_geo(1) - 2, :, :)
    end if
    if(dm0%ibcx(2, m) == IBC_INTERIOR) then
      dm0%fbcx_qx(2, :, :) = fl1%qx(2, :, :)
      dm0%fbcx_qx(4, :, :) = fl1%qx(3, :, :)
    end if

    ! uy, dm0-dm1, nc
    m = 2
    if(dm1%ibcx(1, m) == IBC_INTERIOR) then
      dm1%fbcx_qy(1, :, :) = fl0%qy(dm0%nc(1),     :, :)
      dm1%fbcx_qy(3, :, :) = fl0%qy(dm0%nc(1) - 1, :, :)
    end if
    if(dm0%ibcx(2, m) == IBC_INTERIOR) then
      dm0%fbcx_qy(2, :, :) = fl1%qy(1, :, :)
      dm0%fbcx_qy(4, :, :) = fl1%qy(2, :, :)
    end if

    ! uz, dm0-dm1, nc
    m = 3
    if(dm1%ibcx(1, m) == IBC_INTERIOR) then
      dm1%fbcx_qz(1, :, :) = fl0%qz(dm0%nc(1),     :, :)
      dm1%fbcx_qz(3, :, :) = fl0%qz(dm0%nc(1) - 1, :, :)
    end if
    if(dm0%ibcx(2, m) == IBC_INTERIOR) then
      dm0%fbcx_qz(2, :, :) = fl1%qz(1, :, :)
      dm0%fbcx_qz(4, :, :) = fl1%qz(2, :, :)
    end if

    ! p, dm0-dm1, nc
    m = 4
    if(dm1%ibcx(1, m) == IBC_INTERIOR) then
      dm1%fbcx_pr(1, :, :) = fl0%pres(dm0%nc(1),     :, :)
      dm1%fbcx_pr(3, :, :) = fl0%pres(dm0%nc(1) - 1, :, :)
    end if
    if(dm0%ibcx(2, m) == IBC_INTERIOR) then
      dm0%fbcx_pr(2, :, :) = fl1%pres(1, :, :)
      dm0%fbcx_pr(4, :, :) = fl1%pres(2, :, :)
    end if
!----------------------------------------------------------------------------------------------------------
!   bc in y - direction
!----------------------------------------------------------------------------------------------------------
    ! ux, dm0-dm1, nc
    m = 1
    if(dm1%ibcy(1, m) == IBC_INTERIOR) then
      dm1%fbcy_qx(:, 1, :) = fl0%qx(:, dm0%nc(2),     :)
      dm1%fbcy_qx(:, 3, :) = fl0%qx(:, dm0%nc(2) - 1, :)
    end if
    if(dm0%ibcy(2, m) == IBC_INTERIOR) then
      dm0%fbcy_qx(:, 2, :) = fl1%qx(:, 1, :)
      dm0%fbcy_qx(:, 4, :) = fl1%qx(:, 2, :)
    end if

    ! uy, dm0-dm1, np
    m = 2
    if(dm1%ibcy(1, m) == IBC_INTERIOR) then
      dm1%fbcy_qy(:, 1, :) = fl0%qy(:, dm0%np_geo(2) - 1, :)
      dm1%fbcy_qy(:, 3, :) = fl0%qy(:, dm0%np_geo(2) - 2, :)
    end if
    if(dm0%ibcy(2, m) == IBC_INTERIOR) then
      dm0%fbcy_qy(:, 2, :) = fl1%qy(:, 2, :)
      dm0%fbcy_qy(:, 4, :) = fl1%qy(:, 3, :)
    end if

    ! uz, dm0-dm1, nc
    m = 3
    if(dm1%ibcy(1, m) == IBC_INTERIOR) then
      dm1%fbcy_qz(:, 1, :) = fl0%qz(:, dm0%nc(2),     :)
      dm1%fbcy_qz(:, 3, :) = fl0%qz(:, dm0%nc(2) - 1, :)
    end if
    if(dm0%ibcy(2, m) == IBC_INTERIOR) then
      dm0%fbcy_qz(:, 2, :) = fl1%qz(:, 1, :)
      dm0%fbcy_qz(:, 4, :) = fl1%qz(:, 2, :)
    end if

    ! p, dm0-dm1, nc
    m = 4
    if(dm1%ibcy(1, m) == IBC_INTERIOR) then
      dm1%fbcy_pr(:, 1, :) = fl0%pres(:, dm0%nc(2),     :)
      dm1%fbcy_pr(:, 3, :) = fl0%pres(:, dm0%nc(2) - 1, :)
    end if
    if(dm0%ibcy(2, m) == IBC_INTERIOR) then
      dm0%fbcy_pr(:, 2, :) = fl1%pres(:, 1, :)
      dm0%fbcy_pr(:, 4, :) = fl1%pres(:, 2, :)
    end if
!----------------------------------------------------------------------------------------------------------
!   bc in z - direction
!----------------------------------------------------------------------------------------------------------
    ! ux, dm0-dm1, nc
    m = 1
    if(dm1%ibcz(1, m) == IBC_INTERIOR) then
      dm1%fbcz_qx(:, :, 1) = fl0%qx(:, :, dm0%nc(2)    )
      dm1%fbcz_qx(:, :, 3) = fl0%qx(:, :, dm0%nc(2) - 1)
    end if
    if(dm0%ibcz(2, m) == IBC_INTERIOR) then
      dm0%fbcz_qx(:, :, 2) = fl1%qx(:, :, 1)
      dm0%fbcz_qx(:, :, 4) = fl1%qx(:, :, 2)
    end if

    ! uy, dm0-dm1, nc
    m = 2
    if(dm1%ibcz(1, m) == IBC_INTERIOR) then
      dm1%fbcz_qy(:, :, 1) = fl0%qy(:, :, dm0%nc(2)    )
      dm1%fbcz_qy(:, :, 3) = fl0%qy(:, :, dm0%nc(2) - 1)
    end if
    if(dm0%ibcz(2, m) == IBC_INTERIOR) then
      dm0%fbcz_qy(:, :, 2) = fl1%qy(:, :, 1)
      dm0%fbcz_qy(:, :, 4) = fl1%qy(:, :, 2)
    end if

    ! uz, dm0-dm1, np
    m = 3
    if(dm1%ibcz(1, m) == IBC_INTERIOR) then
      dm1%fbcz_qz(:, :, 1) = fl0%qz(:, :, dm0%np_geo(2) - 1)
      dm1%fbcz_qz(:, :, 3) = fl0%qz(:, :, dm0%np_geo(2) - 2)
    end if
    if(dm0%ibcz(2, m) == IBC_INTERIOR) then
      dm0%fbcz_qz(:, :, 2) = fl1%qz(:, :, 2)
      dm0%fbcz_qz(:, :, 4) = fl1%qz(:, :, 3)
    end if

    ! p, dm0-dm1, nc
    m = 4
    if(dm1%ibcz(1, m) == IBC_INTERIOR) then
      dm1%fbcz_pr(:, :, 1) = fl0%pres(:, :, dm0%nc(2)    )
      dm1%fbcz_pr(:, :, 3) = fl0%pres(:, :, dm0%nc(2) - 1)
    end if
    if(dm0%ibcz(2, m) == IBC_INTERIOR) then
      dm0%fbcz_pr(:, :, 2) = fl1%pres(:, :, 1)
      dm0%fbcz_pr(:, :, 4) = fl1%pres(:, :, 2)
    end if
    return
  end subroutine

!==========================================================================================================
!==========================================================================================================
  subroutine update_bc_interface_thermo(dm0, fl0, tm0, dm1, fl1, tm1)
    use parameters_constant_mod
    use thermo_info_mod
    use udf_type_mod
    implicit none
    type(t_domain), intent(inout) :: dm0, dm1
    type(t_flow), intent(in)      :: fl0, fl1
    type(t_thermo), intent(in)    :: tm0, tm1
    
    integer :: m, i, j, k
!----------------------------------------------------------------------------------------------------------
!   all in x-pencil
!----------------------------------------------------------------------------------------------------------
!----------------------------------------------------------------------------------------------------------
!   bc in x - direction
!----------------------------------------------------------------------------------------------------------
    ! gx, dm0-dm1, np
    m = 6
    if(dm1%ibcx(1, m) == IBC_INTERIOR) then
      dm1%fbcx_gx(1, :, :) = fl0%gx(dm0%np_geo(1) - 1,     :, :)
      dm1%fbcx_gx(3, :, :) = fl0%gx(dm0%np_geo(1) - 2, :, :)
    end if
    if(dm0%ibcx(2, m) == IBC_INTERIOR) then
      dm0%fbcx_gx(2, :, :) = fl1%gx(2, :, :)
      dm0%fbcx_gx(4, :, :) = fl1%gx(3, :, :)
    end if

    ! gy, dm0-dm1, nc
    m = 7
    if(dm1%ibcx(1, m) == IBC_INTERIOR) then
      dm1%fbcx_gy(1, :, :) = fl0%gy(dm0%nc(1),     :, :)
      dm1%fbcx_gy(3, :, :) = fl0%gy(dm0%nc(1) - 1, :, :)
    end if
    if(dm0%ibcx(2, m) == IBC_INTERIOR) then
      dm0%fbcx_gy(2, :, :) = fl1%gy(1, :, :)
      dm0%fbcx_gy(4, :, :) = fl1%gy(2, :, :)
    end if

    ! gz, dm0-dm1, nc
    m = 8
    if(dm1%ibcx(1, m) == IBC_INTERIOR) then
      dm1%fbcx_gz(1, :, :) = fl0%gz(dm0%nc(1),     :, :)
      dm1%fbcx_gz(3, :, :) = fl0%gz(dm0%nc(1) - 1, :, :)
    end if
    if(dm0%ibcx(2, m) == IBC_INTERIOR) then
      dm0%fbcx_gz(2, :, :) = fl1%gz(1, :, :)
      dm0%fbcx_gz(4, :, :) = fl1%gz(2, :, :)
    end if

    ! thermal field, dm0-dm1
    m = 5
    if(dm1%ibcx(1, m) == IBC_INTERIOR) then
      dm1%ftpbcx_var(1, :, :)%t = tm0%tTemp(dm0%nc(1),     :, :)
      dm1%ftpbcx_var(3, :, :)%t = tm0%tTemp(dm0%nc(1) - 1, :, :)
      do k = 1, dm1%np(3)
        do j = 1, dm1%np(2)
          call ftp_refresh_thermal_properties_from_T_undim(dm1%ftpbcx_var(1, j, k))
          call ftp_refresh_thermal_properties_from_T_undim(dm1%ftpbcx_var(3, j, k))
        end do
      end do
    end if
    if(dm0%ibcx(2, m) == IBC_INTERIOR) then
      dm0%ftpbcx_var(2, :, :)%t = tm1%tTemp(1, :, :)
      dm0%ftpbcx_var(4, :, :)%t = tm1%tTemp(2, :, :)
      do k = 1, dm0%np(3)
        do j = 1, dm0%np(2)
          call ftp_refresh_thermal_properties_from_T_undim(dm0%ftpbcx_var(2, j, k))
          call ftp_refresh_thermal_properties_from_T_undim(dm0%ftpbcx_var(4, j, k))
        end do
      end do
    end if
!----------------------------------------------------------------------------------------------------------
!   bc in y - direction
!----------------------------------------------------------------------------------------------------------
    ! gx, dm0-dm1, nc
    m = 6
    if(dm1%ibcy(1, m) == IBC_INTERIOR) then
      dm1%fbcy_gx(:, 1, :) = fl0%gx(:, dm0%nc(1),     :)
      dm1%fbcy_gx(:, 3, :) = fl0%gx(:, dm0%nc(1) - 1, :)
    end if
    if(dm0%ibcy(2, m) == IBC_INTERIOR) then
      dm0%fbcy_gx(:, 2, :) = fl1%gx(:, 1, :)
      dm0%fbcy_gx(:, 4, :) = fl1%gx(:, 2, :)
    end if

    ! gy, dm0-dm1, nc
    m = 7
    if(dm1%ibcy(1, m) == IBC_INTERIOR) then
      dm1%fbcy_gy(:, 1, :) = fl0%gy(:, dm0%np_geo(1) - 1, :)
      dm1%fbcy_gy(:, 3, :) = fl0%gy(:, dm0%np_geo(1) - 2, :)
    end if
    if(dm0%ibcy(2, m) == IBC_INTERIOR) then
      dm0%fbcy_gy(:, 2, :) = fl1%gy(:, 2, :)
      dm0%fbcy_gy(:, 4, :) = fl1%gy(:, 3, :)
    end if

    ! gz, dm0-dm1, nc
    m = 8
    if(dm1%ibcy(1, m) == IBC_INTERIOR) then
      dm1%fbcy_gz(:, 1, :) = fl0%gz(:, dm0%nc(1),     :)
      dm1%fbcy_gz(:, 3, :) = fl0%gz(:, dm0%nc(1) - 1, :)
    end if
    if(dm0%ibcy(2, m) == IBC_INTERIOR) then
      dm0%fbcy_gz(:, 2, :) = fl1%gz(:, 1, :)
      dm0%fbcy_gz(:, 4, :) = fl1%gz(:, 2, :)
    end if

    ! thermal field, dm0-dm1
    m = 5
    if(dm1%ibcy(1, m) == IBC_INTERIOR) then
      dm1%ftpbcy_var(:, 1, :)%t = tm0%tTemp(:, dm0%nc(1),     :)
      dm1%ftpbcy_var(:, 3, :)%t = tm0%tTemp(:, dm0%nc(1) - 1, :)
      do k = 1, dm1%np(3)
        do i = 1, dm1%np(1)
          call ftp_refresh_thermal_properties_from_T_undim(dm1%ftpbcy_var(i, 1, k))
          call ftp_refresh_thermal_properties_from_T_undim(dm1%ftpbcy_var(i, 3, k))
        end do
      end do
    end if
    if(dm0%ibcy(2, m) == IBC_INTERIOR) then
      dm0%ftpbcy_var(:, 2, :)%t = tm1%tTemp(:, 1, :)
      dm0%ftpbcy_var(:, 4, :)%t = tm1%tTemp(:, 2, :)
      do k = 1, dm0%np(3)
        do i = 1, dm0%np(1)
          call ftp_refresh_thermal_properties_from_T_undim(dm0%ftpbcy_var(i, 2, k))
          call ftp_refresh_thermal_properties_from_T_undim(dm0%ftpbcy_var(i, 4, k))
        end do
      end do
    end if
!----------------------------------------------------------------------------------------------------------
!   bc in z - direction
!----------------------------------------------------------------------------------------------------------
    ! gx, dm0-dm1, nc
    m = 6
    if(dm1%ibcz(1, m) == IBC_INTERIOR) then
      dm1%fbcz_gx(:, :, 1) = fl0%gx(:, :, dm0%nc(1)    )
      dm1%fbcz_gx(:, :, 3) = fl0%gx(:, :, dm0%nc(1) - 1)
    end if
    if(dm0%ibcz(2, m) == IBC_INTERIOR) then
      dm0%fbcz_gx(:, :, 2) = fl1%gx(:, :, 1)
      dm0%fbcz_gx(:, :, 4) = fl1%gx(:, :, 2)
    end if

    ! gy, dm0-dm1, nc
    m = 7
    if(dm1%ibcz(1, m) == IBC_INTERIOR) then
      dm1%fbcz_gy(:, :, 1) = fl0%gy(:, :, dm0%nc(1)    )
      dm1%fbcz_gy(:, :, 3) = fl0%gy(:, :, dm0%nc(1) - 1)
    end if
    if(dm0%ibcz(2, m) == IBC_INTERIOR) then
      dm0%fbcz_gy(:, :, 2) = fl1%gy(:, :, 1)
      dm0%fbcz_gy(:, :, 4) = fl1%gy(:, :, 2)
    end if

    ! gz, dm0-dm1, np
    m = 8
    if(dm1%ibcz(1, m) == IBC_INTERIOR) then
      dm1%fbcz_gz(:, :, 1) = fl0%gz(:, :, dm0%np_geo(1) - 1)
      dm1%fbcz_gz(:, :, 3) = fl0%gz(:, :, dm0%np_geo(1) - 2)
    end if
    if(dm0%ibcz(2, m) == IBC_INTERIOR) then
      dm0%fbcz_gz(:, :, 2) = fl1%gz(:, :, 2)
      dm0%fbcz_gz(:, :, 4) = fl1%gz(:, :, 3)
    end if

    ! thermal field, dm0-dm1
    m = 5
    if(dm1%ibcz(1, m) == IBC_INTERIOR) then
      dm1%ftpbcz_var(:, :, 1)%t = tm0%tTemp(:, :, dm0%nc(1)    )
      dm1%ftpbcz_var(:, :, 3)%t = tm0%tTemp(:, :, dm0%nc(1) - 1)
      do j = 1, dm1%np(2)
        do i = 1, dm1%np(1)
          call ftp_refresh_thermal_properties_from_T_undim(dm1%ftpbcz_var(i, j, 1))
          call ftp_refresh_thermal_properties_from_T_undim(dm1%ftpbcz_var(i, j, 3))
        end do
      end do
    end if
    if(dm0%ibcz(2, m) == IBC_INTERIOR) then
      dm0%ftpbcz_var(:, :, 2)%t = tm1%tTemp(:, :, 1)
      dm0%ftpbcz_var(:, :, 4)%t = tm1%tTemp(:, :, 2)
      do j = 1, dm0%np(2)
        do i = 1, dm0%np(1)
          call ftp_refresh_thermal_properties_from_T_undim(dm0%ftpbcz_var(i, j, 2))
          call ftp_refresh_thermal_properties_from_T_undim(dm0%ftpbcz_var(i, j, 4))
        end do
      end do
    end if
    return
  end subroutine

!==========================================================================================================
!> \brief Apply b.c. conditions 
!---------------------------------------------------------------------------------------------------------- 
!> Scope:  mpi    called-freq    xdomain     module
!>         all    once           specified   public
!----------------------------------------------------------------------------------------------------------
! Arguments
!----------------------------------------------------------------------------------------------------------
!  mode           name          role                                           
!----------------------------------------------------------------------------------------------------------
!> \param[in]     d             domain
!> \param[out]    f             flow
!==========================================================================================================
  subroutine apply_bc_const (dm, fl) ! check, necessary?
    use parameters_constant_mod
    use udf_type_mod
    implicit none
    type(t_domain), intent( in    )   :: dm
    type(t_flow),   intent( inout )   :: fl

    integer :: m, s
    type(DECOMP_INFO) :: dtmp

    real(WP), dimension( dm%dccp%ysz(1), dm%dccp%ysz(2), dm%dccp%ysz(3) ) :: accp_ypencil !
    real(WP), dimension( dm%dccp%zsz(1), dm%dccp%zsz(2), dm%dccp%zsz(3) ) :: accp_zpencil ! 
    real(WP), dimension( dm%dcpc%ysz(1), dm%dcpc%ysz(2), dm%dcpc%ysz(3) ) :: acpc_ypencil !


     if(dm%ibcx(1, 1) /= IBC_DIRICHLET .and. &
        dm%ibcx(2, 1) /= IBC_DIRICHLET .and. &
        dm%ibcy(1, 2) /= IBC_DIRICHLET .and. &
        dm%ibcy(2, 2) /= IBC_DIRICHLET .and. &
        dm%ibcz(1, 3) /= IBC_DIRICHLET .and. &
        dm%ibcz(2, 3) /= IBC_DIRICHLET ) return
!----------------------------------------------------------------------------------------------------------
!   all in x-pencil
!----------------------------------------------------------------------------------------------------------

!----------------------------------------------------------------------------------------------------------
!   ux at x-direction. BC of others at x-direction are given in oeprations directly.
!----------------------------------------------------------------------------------------------------------
    m = 1
    dtmp = dm%dpcc
    ! constant value bc.
    do s = 1, 2
      if(dm%ibcx_nominal(s, m) == IBC_DIRICHLET) then
        if(dtmp%xst(m) == 1) then
               fl%qx(1, 1:dtmp%xsz(2), 1:dtmp%xsz(3)) = &
          dm%fbcx_qx(1, 1:dtmp%xsz(2), 1:dtmp%xsz(3))
          !if(dm%is_thermo) fl%gx(1, :, :) = fl%qx(1, :, :) * dm%fbc_dend(s, m)
        end if
        if(dtmp%xen(m) == dm%np(m)) then
               fl%qx(dtmp%xsz(m), 1:dtmp%xsz(2), 1:dtmp%xsz(3)) = &
          dm%fbcx_qx(2,           1:dtmp%xsz(2), 1:dtmp%xsz(3))
          !if(dm%is_thermo) fl%gx(dtmp%xsz(m), :, :) = fl%qx(dtmp%xsz(m), :, :) * dm%fbc_dend(s, m)
        end if
      end if
    end do

!----------------------------------------------------------------------------------------------------------
!   uy at y-direction. BC of others at y-direction are given in oeprations directly.
!----------------------------------------------------------------------------------------------------------
    m = 2
    dtmp = dm%dcpc
    do s = 1, 2
      if(dm%ibcy_nominal(s, m) == IBC_DIRICHLET) then
        call transpose_x_to_y(fl%qy, acpc_ypencil, dm%dcpc)
        if(dtmp%yst(m) == 1) then
          acpc_ypencil(1:dtmp%ysz(1), 1, 1:dtmp%ysz(3)) = &
            dm%fbcy_qy(1:dtmp%ysz(1), 1, 1:dtmp%ysz(3))
          !if(dm%is_thermo) fl%gy(:, 1, :) = fl%qy(:, 1, :) * dm%fbc_dend(s, m)
        end if
        if(dtmp%yen(m) == dm%np(m)) then
          acpc_ypencil(1:dtmp%ysz(1), dtmp%ysz(m), 1:dtmp%ysz(3)) = &
            dm%fbcy_qy(1:dtmp%ysz(1), 2,           1:dtmp%ysz(3))
          !if(dm%is_thermo) fl%gy(:, dtmp%xsz(m), :) = fl%qy(:, dtmp%xsz(m), :)  * dm%fbc_dend(s, m)
        end if
        call transpose_y_to_x(acpc_ypencil, fl%qy, dm%dcpc)
      end if
    end do

!----------------------------------------------------------------------------------------------------------
!   uz at z-direction. BC of others at z-direction are given in oeprations directly.
!----------------------------------------------------------------------------------------------------------
    m = 3
    dtmp = dm%dccp
    do s = 1, 2
      if(dm%ibcz_nominal(s, m) == IBC_DIRICHLET) then
        call transpose_x_to_y(fl%qz,        accp_ypencil, dm%dccp)
        call transpose_y_to_z(accp_ypencil, accp_zpencil, dm%dccp)
        if(dtmp%zst(m) == 1) then
          accp_zpencil(1:dtmp%zsz(1), 1:dtmp%zsz(2), 1) = &
            dm%fbcz_qz(1:dtmp%zsz(1), 1:dtmp%zsz(2), 1)
          !if(dm%is_thermo) fl%gz(:, :, 1) = fl%qz(:, :, 1) * dm%fbc_dend(s, m)
        end if
        if(dtmp%zen(m) == dm%np(m)) then
          accp_zpencil(1:dtmp%zsz(1), 1:dtmp%zsz(2), dtmp%zsz(m)) = &
            dm%fbcz_qz(1:dtmp%zsz(1), 1:dtmp%zsz(2), 2)
          !if(dm%is_thermo)  fl%gz(:, :, dtmp%xsz(m)) = fl%qz(:, :, dtmp%xsz(m)) *  dm%fbc_dend(s, m)
        end if
        call transpose_z_to_y(accp_zpencil, accp_ypencil, dm%dccp )
        call transpose_y_to_x(accp_ypencil, fl%qz, dm%dccp)
      end if
    end do

    return
  end subroutine


!==========================================================================================================
!==========================================================================================================
!   subroutine Apply_x_convective_outlet ? check necessary?
!     use solver_tools_mod

! !----------------------------------------------------------------------------------------------------------
! !  to get convective outlet bc, ux_cbc
! !----------------------------------------------------------------------------------------------------------
!     call Find_max_min_3d(fl%qx, umax, umin)
!     ux_cbc = HALF * (umax + umin)

!     return
!   end subroutine



end module
