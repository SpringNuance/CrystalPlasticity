!     May 03rd, 2022
!     Eralp Demir
!
      module backstress
      implicit none
      contains
!
!     Armstrong-Frederic backstress model
!     Two input parameters are required
      subroutine backstressmodel1(backstressparam,nslip,X,gdot,dt,dX)
      use userinputs, only : maxnparam
      implicit none
!     Inputs
!     Backstress parameters
      real(8), intent(in) :: backstressparam(maxnparam)
!     Number of slip systems
      integer, intent(in) :: nslip
!     Current value of slip rate
      real(8), intent(in) :: gdot(nslip)
!     Current value of backstress
      real(8), intent(in) :: X(nslip)
!     time increment
      real(8), intent(in) :: dt
!
!     Output
!     Backtress increment
      real(8), intent(out) :: dX(nslip)
!
!     Variables used in this subroutine
!     Backstress evolution parameter
      real(8) :: h
!     Backstress relief parameter
      real(8) :: hD
      integer :: is
!
!     Backstress evolution
      h = backstressparam(1)
!
!     Backstress annihiliation
      hD = backstressparam(2)
!
      dX = 0.
      do is=1,nslip
!
          dX(is) = (h*gdot(is) - hD*X(is)*abs(gdot(is)))*dt
!
      end do
!
!
!
      return
      end subroutine backstressmodel1
!
!
!
!
!
!    NON-LOCAL backstress calculation based on GND density
      subroutine backstressmodel2
      use userinputs, only: numel, maxnslip
      use globalvariables, only: numpt,
     + phaseid, numslip_all, numscrew_all, screw_all,
     + burgerv_all, gf_all, G12_all, v12_all,
     + statev_backstress, statev_gnd
      use utilities, only: matvec6
      implicit none
      integer :: matid, nslip, nscrew
      real(8) :: burgerv(maxnslip)
      integer :: screw(maxnslip)
      real(8) :: X(maxnslip)
      real(8) :: gf, G12, v12
      real(8) :: rhoGNDe, rhoGNDs
      integer :: ie, ip, is, i, k, l
!
!
!
!
!
!
      do ie=1, numel
!
!         Reset arrays
          burgerv=0.;screw=0
!
!
!
!         Assume the same material for al the Gaussian points of an element
          matid = phaseid(ie,1)
!
!         Number of slip systems
          nslip = numslip_all(matid)
!
!         Number of screw systems
          nscrew = numscrew_all(matid)
!
!         Screw systems
          screw = screw_all(matid,1:nscrew)
!
!         Geometric factor
          gf = gf_all(matid)
!
!         Shear Modulus
          G12 = G12_all(matid)
!
!         Poisson's ratio
          v12 = v12_all(matid)
!
!         Burgers vector
          burgerv(1:nslip) = burgerv_all(matid,1:nslip)
!
!

!
!
          do ip=1,numpt
!
!
!
!
!
!
!             Reset backstress
              X = 0.
!
!
!             Edges
              do is = 1, nslip
!
!
!                 Edge dislocation density
                  rhoGNDe = statev_gnd(ie,ip,is)
!
!
!
!
!                 Backstress due to edges
                  X(is) = -gf*G12*burgerv(is)*
     + sqrt(abs(rhoGNDe))*sign(1.0,rhoGNDe)/(1.-v12)
!
!
!
              end do
!
!
!
!             Screws
              do i = 1, nscrew
!
                  is = screw(i)
!
!
!                 Screw dislocation density
                  rhoGNDs = statev_gnd(ie,ip,nslip+i)
!
!                 Backstress due to screws
                  X(is) = X(is) + gf*G12*burgerv(is)*
     + sqrt(abs(rhoGNDs))*sign(1.0,rhoGNDs)
!
!
!
              end do
!
!
!
!
!
!
!             Assign to the global vector
              statev_backstress(ie,ip,1:nslip) = X
!
!
!
!
!
!
          end do
!
!
!
!
!
!
!
      end do
!
!
!
!
!
!
!
      return
!
      end subroutine backstressmodel2
!
!
      end module backstress