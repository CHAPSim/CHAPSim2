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
  call Initialize_flow ()
  call Solve_eqs_iteration()

  call Finalise_chapsim ()
  
end program
!===============================================================================
!===============================================================================
!> \brief Initialisation and preprocessing of geometry, mesh and tools
!>
!> This subroutine is called at beginning of the main program
!>
!-------------------------------------------------------------------------------
! Arguments
!______________________________________________________________________________.
!  mode           name          role                                           !
!______________________________________________________________________________!
!> \param[in]     none          NA
!> \param[out]    none          NA
!_______________________________________________________________________________
subroutine Initialize_chapsim()
  !use mpi_mod
  use input_general_mod
  use input_thermo_mod
  !use domain_decomposition_mod
  use geometry_mod
  use flow_variables_mod
  use operations
  implicit none

  !call Initialize_mpi()
  call Initialize_general_input ()
  call Initialize_thermo_input ()
  call Initialize_geometry_variables ()
  call Prepare_coeffs_for_operations()

  !call Initialize_domain_decompsition ()
  return
end subroutine Initialize_chapsim
!===============================================================================
!===============================================================================
!> \brief Initialisation and preprocessing of the flow field
!>
!> This subroutine is called at beginning of the main program
!>
!-------------------------------------------------------------------------------
! Arguments
!______________________________________________________________________________.
!  mode           name          role                                           !
!______________________________________________________________________________!
!> \param[in]     none          NA
!> \param[out]    none          NA
!_______________________________________________________________________________
subroutine Initialize_flow()
  use flow_variables_mod
  use input_general_mod, only : irestart, &
      INITIAL_RANDOM, INITIAL_RESTART, INITIAL_INTERPL
  implicit none

  call Allocate_variables ()
  call Define_parameters_in_eqs ()
  if (irestart == INITIAL_RANDOM) then
    call Initialize_flow_variables ()
  else if (irestart == INITIAL_RESTART) then

  else if (irestart == INITIAL_INTERPL) then

  else
    call Print_error_msg("Error in flow initialisation flag.")
  end if
  
  return
end subroutine Initialize_flow

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
  use mpi_mod
  implicit none

  !call Deallocate_all_variables
  !call Finalise_mpi()
  return
end subroutine Finalise_chapsim




