module geometry_initialisation_mod
  implicit none

  private
  public :: Initialize_geometry_variables
  public :: Display_vtk_mesh

contains

  subroutine Display_vtk_mesh(nd, str)
    use geometry_mod
    type(node_t), intent( in ) :: nd(:, :, :)
    character( len = *), intent( in ) :: str

    integer :: output_unit
    integer :: i, j, k
    integer :: n1, n2, n3

    n1 = size( nd(:, 1, 1) )
    n2 = size( nd(1, :, 1) )
    n3 = size( nd(1, 1, :) )

    if ( trim( str ) == 'xy' ) then
      n3 = 1
    end if
    if ( trim( str ) == 'yz' ) then
      n1 = 1
    end if
    if ( trim( str ) == 'zx' ) then
      n2 = 1
    end if

    open(newunit = output_unit, file = 'mesh_'//str//'.vtk', action = "write", status = "replace")
    write(output_unit, '(A)') '# vtk DataFile Version 2.0'
    write(output_unit, '(A)') str//'_mesh'
    write(output_unit, '(A)') 'ASCII'
    write(output_unit, '(A)') 'DATASET STRUCTURED_GRID'
    write(output_unit, '(A, 3I10.1)') 'DIMENSIONS', n1, n2, n3
    write(output_unit, '(A, I10.1, X, A)') 'POINTS', n1 * n2 * n3, 'float'
    do k = 1, n3
      do j = 1, n2
        do i = 1, n1
          write(output_unit, *) nd(i, j, k)%x, nd(i, j, k)%y, nd(i, j, k)%z 
        end do
      end do
    end do
    close(output_unit)

  end subroutine Display_vtk_mesh

  subroutine Initialize_geometry_variables ()
    use mpi_mod
    use input_general_mod
    use geometry_mod
    use math_mod
    use parameters_constant_mod, only : ONE, HALF, ZERO
    integer :: i, j, k
    real(WP) :: s, yy, c1, c2, c3, c4

    ! Build up domain info
    domain%bcx(:) = ifbcx(:)
    domain%bcy(:) = ifbcy(:)
    domain%bcz(:) = ifbcz(:)

    domain%is_periodic(:) = is_periodic(:)
    
    domain%nc(1) = ncx
    domain%nc(2) = ncy
    domain%nc(3) = ncz

    domain%np(1) = npx
    domain%np(2) = npy
    domain%np(3) = npz

    domain%dx = lxx / real(ncx, WP)
    domain%dz = lzz / real(ncz, WP)

    domain%dx2 = domain%dx * domain%dx
    domain%dz2 = domain%dz * domain%dz

    domain%dxi = ONE / domain%dx
    domain%dzi = ONE / domain%dz

    ! Build up node and cell info
    allocate ( node (npx, npy, npz) )
    allocate ( cell (ncx, ncy, ncz) )
    
    do k = 1, npz
      do j = 1, npy
        do i = 1, npx
          node(i, j, k)%x = ZERO
          node(i, j, k)%y = ZERO
          node(i, j, k)%z = ZERO
        end do
      end do
    end do
    
    do k = 1, ncz
      do j = 1, ncy
        do i = 1, ncx
          cell(i, j, k)%x = ZERO
          cell(i, j, k)%y = ZERO
          cell(i, j, k)%z = ZERO
        end do
      end do
    end do

    block_xcoordinate: do i = 1, npx
      node(i, :, :)%x = real( (i - 1), WP ) * domain%dx
      if (i < npx) cell(i, :, :)%x = (real( i, WP ) - HALF) * domain%dx
    end do block_xcoordinate

    block_zcoordinate: do k = 1, npz
      node(:, :, k)%z = real( (k - 1), WP ) * domain%dz
      if (k < npz) cell(:, :, k)%z = (real( k, WP ) - HALF) * domain%dz
    end do block_zcoordinate

    block_ycnst: if (istret == ISTRET_SIDES) then
      c1 = rstret * HALF
      c2 = tanh_wp (c1)
      c3 = ONE
      c4 = HALF
    else if (istret == ISTRET_BOTTOM) then
      c1 = rstret * ONE
      c2 = tanh_wp (c1)
      c3 = ONE
      c4 = ONE
    else if (istret == ISTRET_TOP) then
      c1 = rstret * ZERO
      c2 = tanh_wp (rstret)
      c3 = ZERO
      c4 = ONE
    else
      c1 = rstret * HALF
      c2 = tanh_wp (c1)
      c3 = ONE
      c4 = HALF
    end if block_ycnst

    block_ynd: do j = 1, npy
      yy = real ((j - 1), WP) / real ( (npy - 1), WP)
      if(istret == ISTRET_NO) then
        s = yy
      else 
        s = (tanh_wp( (rstret * yy) - c1 ) / c2 + c3) * c4
      end if
      node(:, j, :)%y = s * (lyt - lyb) + lyb
    end do block_ynd 

    block_ycl: do j = 1, ncy
      cell(:, j, :)%y = ( node(1, j, 1)%y + node(1, j + 1, 1)%y ) * HALF
    end do block_ycl

    if(myid == 0) then ! test
      call Display_vtk_mesh ( node(:, :, :), 'xy' )
      call Display_vtk_mesh ( node(:, :, :), 'yz' )
      call Display_vtk_mesh ( node(:, :, :), 'zx' )
      call Display_vtk_mesh ( node(:, :, :), '3D' )
    end if

  end subroutine  Initialize_geometry_variables

end module geometry_initialisation_mod


