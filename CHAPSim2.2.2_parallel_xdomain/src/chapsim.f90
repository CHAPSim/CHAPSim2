!-------------------------------------------------------------------------------
!                      CHAPSim version 2.0.0
!                      --------------------------
! This file is part of CHAPSim, a general-purpose CFD tool.
!
! This program is free software; you can redistribute it and/or modify it under
! the terms of the GNU General Public License as published by the Free Software
! Foundation; either version 3 of the License, or (at your option) any later
! version.
!
! This program is distributed in the hope that it will be useful, but WITHOUT
! ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
! FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
! details.
!
! You should have received a copy of the GNU General Public License along with
! this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
! Street, Fifth Floor, Boston, MA 02110-1301, USA.

!-------------------------------------------------------------------------------
!===============================================================================
!> \file chapsim.f90
!>
!> \brief The main program.
!>
!===============================================================================
program chapsim
  implicit none

  call Initialize_chapsim ()
  call Solve_eqs_iteration()
  call Finalise_chapsim   ()
  
end program
!===============================================================================
!> \brief Initialisation and preprocessing of geometry, mesh and tools
!>
!> This subroutine is called at beginning of the main program
!>
!-------------------------------------------------------------------------------
! Arguments
!-------------------------------------------------------------------------------
!  mode           name          role                                           
!-------------------------------------------------------------------------------
!> \param[in]     none          NA
!> \param[out]    none          NA
!===============================================================================
subroutine Initialize_chapsim()
  use code_performance_mod
  use input_general_mod
  
  use geometry_mod
  use input_thermo_mod
  use operations
  use domain_decomposition_mod
  use poisson_mod
  use flow_thermo_initialiasation
  implicit none



!-------------------------------------------------------------------------------
! initialisation of mpi, nrank, nproc
!-------------------------------------------------------------------------------
  call Initialize_mpi
  call Call_cpu_time(CPU_TIME_CODE_START, 0, 0)
!-------------------------------------------------------------------------------
! reading input parameters
!-------------------------------------------------------------------------------
  call Read_input_parameters
!-------------------------------------------------------------------------------
! build up thermo_mapping_relations, independent of any domains
!-------------------------------------------------------------------------------
  if(is_any_energyeq) call Build_up_thermo_mapping_relations
!-------------------------------------------------------------------------------
! build up operation coefficients
!-------------------------------------------------------------------------------
  call Prepare_coeffs_for_operations

  do i = 1, nxdomain
    call Initialize_domain_decomposition ( domain(i) )
    call Initialize_decomp_poisson ( domain(i) )
  end do

  !call Test_poisson_solver

  call Initialize_flow_thermal_fields()

  return
end subroutine Initialize_chapsim

!===============================================================================
!===============================================================================
!> \brief solve the governing equations in iteration
!>
!> This subroutine is the main solver. 
!>
!-------------------------------------------------------------------------------
! Arguments
!______________________________________________________________________________.
!  mode           name          role                                           !
!______________________________________________________________________________!
!> \param[in]     none          NA
!> \param[out]    none          NA
!_______________________________________________________________________________
subroutine Solve_eqs_iteration
  use input_general_mod!,  only :  ithermo, nIterFlowEnd, nIterThermoEnd, &
                                  !nIterFlowStart, nIterThermoStart, &
                                  !tThermo, tFlow, nIterFlowEnd, nrsttckpt, &
                                  !dt, nsubitr, niter
  use var_dft_mod!,      only : flow, thermo, domain
  use flow_variables_mod!, only : Calculate_RePrGr, Check_maximum_velocity
  use eq_momentum_mod!,    only : Solve_momentum_eq
  use solver_tools_mod!,   only : Check_cfl_diffusion, Check_cfl_convection
  use continuity_eq_mod
  use poisson_mod
  use code_performance_mod
  implicit none

  logical    :: is_flow   = .false.
  logical    :: is_thermo = .false.
  integer(4) :: iter, isub
  real(wp)   :: rtmp

  interface 
  subroutine Display_vtk_slice(d, str, varnm, vartp, var0, iter)
   use udf_type_mod
   type(t_domain), intent( in ) :: d
   integer(4) :: vartp
   character( len = *), intent( in ) :: str
   character( len = *), intent( in ) :: varnm
   real(WP), intent( in ) :: var0(:, :, :)
   integer(4), intent( in ) :: iter
  end subroutine Display_vtk_slice
end interface
  
  do i = 1, nxdomain
    if(d%ithermo == 1) then
      niter = MAX(flow(i)%nIterFlowEnd, thermo(i)%nIterThermoEnd)
    else
      niter = nIterFlowEnd
    end if
  end do

  do iter = nrsttckpt + 1, niter
    call Call_cpu_time(CPU_TIME_ITER_START, nrsttckpt, niter, iter)
!===============================================================================
!      setting up 1/re, 1/re/prt, gravity, etc
!===============================================================================
    call Calculate_RePrGr(flow, thermo, iter)
!===============================================================================
!      setting up flow solver
!===============================================================================
    if ( (iter >= nIterFlowStart) .and. (iter <=nIterFlowEnd)) then
      is_flow = .true.
      flow%time = flow%time + dt
      call Check_cfl_diffusion (domain%h2r(:), flow%rre)
      call Check_cfl_convection(flow%qx, flow%qy, flow%qz, domain)
    end if
!===============================================================================
!     setting up thermo solver
!===============================================================================
    if ( (iter >= nIterThermoStart) .and. (iter <=nIterThermoEnd)) then
      is_thermo = .true.
      thermo%time = thermo%time  + dt
    end if
!===============================================================================
!     main solver
!===============================================================================
    do isub = 1, nsubitr
      !if(is_thermo) call Solve_energy_eq  (flow, thermo, domain, isub)
      if(is_flow)   call Solve_momentum_eq(flow, domain, isub)
#ifdef DEBUG
      write (OUTPUT_UNIT, '(A, I1)') "  Sub-iteration in RK = ", isub
      call Check_mass_conservation(flow, domain) 
      call Check_maximum_velocity(flow%qx, flow%qy, flow%qz)
      call Get_volumetric_average_3d(flow%qx, 'ux', domain, rtmp)   
#endif
    end do
!
    !comment this part code for testing 
    ! below is for validation
    ! cpu time will be calculated later today 
!===============================================================================
!     validation
!===============================================================================
    call Check_mass_conservation(flow, domain) 
    if(icase == ICASE_TGV2D) call Validate_TGV2D_error (flow, domain)

    call Call_cpu_time(CPU_TIME_ITER_END, nrsttckpt, niter, iter)
!===============================================================================
!   visualisation
!===============================================================================
    if(MOD(iter, nvisu) == 0) then
      call Display_vtk_slice(domain, 'xy', 'u', 1, flow%qx, iter)
      call Display_vtk_slice(domain, 'xy', 'v', 2, flow%qy, iter)
      call Display_vtk_slice(domain, 'xy', 'p', 0, flow%pres, iter)
    end if
  end do


  return
end subroutine Solve_eqs_iteration

!===============================================================================
!===============================================================================
!> \brief Finalising the flow solver
!>
!> This subroutine is called at the end of the main program
!>
!-------------------------------------------------------------------------------
! Arguments
!______________________________________________________________________________.
!  mode           name          role                                           !
!______________________________________________________________________________!
!> \param[in]     none          NA
!> \param[out]    none          NA
!_______________________________________________________________________________
subroutine Finalise_chapsim()
  use input_general_mod
  use mpi_mod
  use code_performance_mod
  implicit none

  !call Deallocate_all_variables
  call Call_cpu_time(CPU_TIME_CODE_END, nrsttckpt, niter)
  call Finalise_mpi()
  return
end subroutine Finalise_chapsim




