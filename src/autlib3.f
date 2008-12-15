      MODULE INTERFACES

      IMPLICIT NONE
      PRIVATE

      PUBLIC :: FNLP,STPNLP ! Folds (Algebraic Problems)
      PUBLIC :: FNBP,STPNBP ! BP (Algebraic Problems)
      PUBLIC :: FNC1,STPNC1 ! Optimizations (Algebraic,NFPR=2)
      PUBLIC :: FNC2,STPNC2 ! Optimizations (Algebraic,otherwise)
      PUBLIC :: FNDS        ! Discrete systems
      PUBLIC :: FNTI        ! Time integration
      PUBLIC :: FNHB,STPNHB ! Hopf bifs (ODEs,waves,maps)
      PUBLIC :: FNPS,BCPS,ICPS,STPNPS ! Periodic solutions
      PUBLIC :: FNWS        ! Spatially uniform sols (parabolic PDEs)
      PUBLIC :: FNWP        ! Travelling waves (parabolic PDEs)
      PUBLIC :: FNSP        ! Stationary states (parabolic PDEs)
      PUBLIC :: FNPE,ICPE,PVLSPE   ! Time evolution (parabolic PDEs)
      PUBLIC :: FNPL,BCPL,ICPL,STPNPL ! Fold cont of periodic sol
      PUBLIC :: FNPBP,BCPBP,ICPBP,STPNPBP ! BP cont of periodic sol
      PUBLIC :: FNPD,BCPD,ICPD,STPNPD ! PD cont of periodic sol
      PUBLIC :: FNTR,BCTR,ICTR,STPNTR ! Torus cont of periodic sol
      PUBLIC :: FNPO,BCPO,ICPO,STPNPO ! Optimization of periodic sol
      PUBLIC :: FNBL,BCBL,ICBL,STPNBL ! Fold cont of BVPs
      PUBLIC :: FNBBP,BCBBP,ICBBP,STPNBBP ! BP cont of BVPs

      PUBLIC :: FUNI,BCNI,ICNI ! Interface subroutines

      PUBLIC :: FUNC,STPNT,BCND,ICND,FOPT,PVLS ! User subroutines

      INTERFACE
         SUBROUTINE FUNC(NDIM,U,ICP,PAR,IJAC,F,DFDU,DFDP)
         INTEGER, INTENT(IN) :: NDIM, IJAC, ICP(*)
         DOUBLE PRECISION, INTENT(IN) :: U(NDIM), PAR(*)
         DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
         DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
         END SUBROUTINE FUNC

         SUBROUTINE STPNT(NDIM,U,PAR,T)
         INTEGER, INTENT(IN) :: NDIM
         DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
         DOUBLE PRECISION, INTENT(IN) :: T
         END SUBROUTINE STPNT

         SUBROUTINE BCND(NDIM,PAR,ICP,NBC,U0,U1,FB,IJAC,DBC)
         INTEGER, INTENT(IN) :: NDIM, ICP(*), NBC, IJAC
         DOUBLE PRECISION, INTENT(IN) :: PAR(*), U0(NDIM), U1(NDIM)
         DOUBLE PRECISION, INTENT(OUT) :: FB(NBC)
         DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)
         END SUBROUTINE BCND

         SUBROUTINE ICND(NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,FI,IJ,DINT)
         INTEGER, INTENT(IN) :: NDIM, ICP(*), NINT, IJ
         DOUBLE PRECISION, INTENT(IN) :: PAR(*),U(NDIM),UOLD(NDIM)
         DOUBLE PRECISION, INTENT(IN) :: UDOT(NDIM),UPOLD(NDIM)
         DOUBLE PRECISION, INTENT(OUT) :: FI(NINT)
         DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)
         END SUBROUTINE ICND

         SUBROUTINE FOPT(NDIM,U,ICP,PAR,IJAC,FS,DFDU,DFDP)
         INTEGER, INTENT(IN) :: NDIM, ICP(*), IJAC
         DOUBLE PRECISION, INTENT(IN) :: U(NDIM), PAR(*)
         DOUBLE PRECISION, INTENT(OUT) :: FS
         DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
         END SUBROUTINE FOPT

         SUBROUTINE PVLS(NDIM,U,PAR)
         INTEGER, INTENT(IN) :: NDIM
         DOUBLE PRECISION, INTENT(IN) :: U(NDIM)
         DOUBLE PRECISION, INTENT(INOUT) :: PAR(*)
         END SUBROUTINE PVLS
      END INTERFACE

      DOUBLE PRECISION, PARAMETER :: HMACH=1.0d-7

      CONTAINS

C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C  Subroutines for the Continuation of Folds (Algebraic Problems)
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNLP(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for the 2-par continuation of folds.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:,:),DFP(:,:),FF1(:),FF2(:)
      INTEGER NDM,NPAR,I,II,J
      DOUBLE PRECISION UMX,EP,P,UU
C
       NDM=IAP(23)
       NPAR=IAP(31)
C
C Generate the function.
C
       ALLOCATE(DFU(NDM,NDM),DFP(NDM,NPAR))
       CALL FFLP(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,NDM,DFU,DFP)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU,DFP)
         RETURN
       ENDIF
       ALLOCATE(FF1(NDIM),FF2(NDIM))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DFDU(1:NDM,1:NDM)=DFU(:,:)
       DFDU(1:NDM,NDM+1:2*NDM)=0d0
       DFDU(1:NDM,NDIM)=DFP(:,ICP(2))

       DFDU(NDM+1:2*NDM,NDM+1:2*NDM)=DFU(:,:)

       DFDU(NDIM,1:NDM)=0d0
       DFDU(NDIM,NDM+1:2*NDM)=2*U(NDM+1:NDM*2)
       DFDU(NDIM,NDIM)=0d0

       DO II=1,NDM+1
         I=II
         IF(I==NDM+1)I=NDIM
         UU=U(I)
         U(I)=UU-EP
         CALL FFLP(IAP,NDIM,U,UOLD,ICP,PAR,0,FF1,NDM,DFU,DFP)
         U(I)=UU+EP
         CALL FFLP(IAP,NDIM,U,UOLD,ICP,PAR,0,FF2,NDM,DFU,DFP)
         U(I)=UU
         DO J=NDM+1,NDIM
           DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(FF2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF1,DFU,DFP)
         RETURN
       ENDIF
       P=PAR(ICP(1))
       PAR(ICP(1))=P+EP
C
       DFDP(1:NDM,ICP(1))=DFP(:,ICP(1))
       CALL FFLP(IAP,NDIM,U,UOLD,ICP,PAR,0,FF1,NDM,DFU,DFP)
C
       DO J=NDM+1,NDIM
         DFDP(J,ICP(1))=(FF1(J)-F(J))/EP
       ENDDO
C
       PAR(ICP(1))=P
       DEALLOCATE(FF1,DFU,DFP)
C
      RETURN
      END SUBROUTINE FNLP
C
C     ---------- ----
      SUBROUTINE FFLP(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,NDM,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NDM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM),DFDP(NDM,*)

      INTEGER IPS,IJC,I,J
C
       IPS=IAP(2)
C
       PAR(ICP(2))=U(NDIM)
       IJC=IJAC
       IF(IJAC==0)IJC=1
       IF(IPS.EQ.-1) THEN
         CALL FNDS(IAP,NDM,U,UOLD,ICP,PAR,IJC,F,DFDU,DFDP)
       ELSE
         CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,IJC,F,DFDU,DFDP)
       ENDIF
C
       DO I=1,NDM
         F(NDM+I)=0.d0
         DO J=1,NDM
           F(NDM+I)=F(NDM+I)+DFDU(I,J)*U(NDM+J)
         ENDDO
       ENDDO
C
       F(NDIM)=-1
C
       DO I=1,NDM
         F(NDIM)=F(NDIM)+U(NDM+I)*U(NDM+I)
       ENDDO
C
      RETURN
      END SUBROUTINE FFLP
C
C     ---------- ------
      SUBROUTINE STPNLP(IAP,PAR,ICP,U,UDOT,NODIR)
C
      USE IO
      USE SUPPORT
C
C Generates starting data for the continuation of folds.
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),U(*),UDOT(*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:),V(:),F(:)
      DOUBLE PRECISION DUMDFP(1)
      INTEGER ICPRS(2),NDIM,IPS,NDM,I
C
       NDIM=IAP(1)
       IPS=IAP(2)
       NDM=IAP(23)
C
       CALL READLB(IAP,ICPRS,U,UDOT,PAR)
C
       ALLOCATE(DFU(NDM*NDM),V(NDM),F(NDM))
       IF(IPS.EQ.-1)THEN
         CALL FNDS(IAP,NDM,U,U,ICP,PAR,1,F,DFU,DUMDFP)
       ELSE
         CALL FUNI(IAP,NDM,U,U,ICP,PAR,1,F,DFU,DUMDFP)
       ENDIF
       CALL NLVC(NDM,NDM,1,DFU,V)
       CALL NRMLZ(NDM,V)
       DO I=1,NDM
         U(NDM+I)=V(I)
       ENDDO
       DEALLOCATE(DFU,V,F)
       U(NDIM)=PAR(ICP(2))
       NODIR=1
C
      RETURN
      END SUBROUTINE STPNLP
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C   Subroutines for BP cont (Algebraic Problems) (by F. Dercole)
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNBP(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for the 2-par continuation of BP.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:),DFP(:),FF1(:),FF2(:)
      INTEGER NDM,NPAR,I,J
      DOUBLE PRECISION UMX,EP,P,UU
C
       NDM=IAP(23)
       NPAR=IAP(31)
C
C Generate the function.
C
       ALLOCATE(DFU(NDM*NDM),DFP(NDM*NPAR))
       CALL FFBP(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFU,DFP)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU,DFP)
         RETURN
       ENDIF
       ALLOCATE(FF1(NDIM),FF2(NDIM))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         UU=U(I)
         U(I)=UU-EP
         CALL FFBP(IAP,NDIM,U,UOLD,ICP,PAR,FF1,NDM,DFU,DFP)
         U(I)=UU+EP
         CALL FFBP(IAP,NDIM,U,UOLD,ICP,PAR,FF2,NDM,DFU,DFP)
         U(I)=UU
         DO J=1,NDIM
           DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(FF2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF1,DFU,DFP)
         RETURN
       ENDIF
       P=PAR(ICP(1))
       PAR(ICP(1))=P+EP
C
       CALL FFBP(IAP,NDIM,U,UOLD,ICP,PAR,FF1,NDM,DFU,DFP)
C
       DO J=1,NDIM
         DFDP(J,ICP(1))=(FF1(J)-F(J))/EP
       ENDDO
C
       PAR(ICP(1))=P
       DEALLOCATE(FF1,DFU,DFP)
C
      RETURN
      END SUBROUTINE FNBP
C
C     ---------- ----
      SUBROUTINE FFBP(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NDM
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM),DFDP(NDM,*)

      INTEGER IPS,ISW,I,J
C
       IPS=IAP(2)
       ISW=IAP(10)
C
       IF(ISW.EQ.3) THEN
C        ** Generic case
         PAR(ICP(3))=U(NDIM)
       ENDIF
       PAR(ICP(2))=U(NDIM-1)
C
       IF(IPS.EQ.-1) THEN
         CALL FNDS(IAP,NDM,U,UOLD,ICP,PAR,2,F,DFDU,DFDP)
       ELSE
         CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,2,F,DFDU,DFDP)
       ENDIF
C
       IF(ISW.EQ.2) THEN
C        ** Non-generic case
         DO I=1,NDM
           F(I)=F(I)+U(NDIM)*U(NDM+I)
         ENDDO
       ENDIF
C
       DO I=1,NDM
         F(NDM+I)=0.d0
         DO J=1,NDM
           F(NDM+I)=F(NDM+I)+DFDU(J,I)*U(NDM+J)
         ENDDO
       ENDDO
C
       F(NDIM-1)=0.d0
       DO I=1,NDM
         F(NDIM-1)=F(NDIM-1)+DFDP(I,ICP(1))*U(NDM+I)
       ENDDO
C
       F(NDIM)=-1
       DO I=1,NDM
         F(NDIM)=F(NDIM)+U(NDM+I)*U(NDM+I)
       ENDDO
C
      RETURN
      END SUBROUTINE FFBP
C
C     ---------- ------
      SUBROUTINE STPNBP(IAP,PAR,ICP,U,UDOT,NODIR)
C
      USE IO
      USE SUPPORT
C
C Generates starting data for the continuation of BP.
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),U(*),UDOT(*)
C Local
      DOUBLE PRECISION, ALLOCATABLE ::DFU(:,:),DFP(:,:),A(:,:),V(:),F(:)
      INTEGER :: ICPRS(3),NDIM,IPS,ISW,NDM,NPAR,I,J
C
       NDIM=IAP(1)
       IPS=IAP(2)
       ISW=IAP(10)
       NDM=IAP(23)
       NPAR=IAP(31)
C
       CALL READLB(IAP,ICPRS,U,UDOT,PAR)
C
       ALLOCATE(DFU(NDM,NDM),DFP(NDM,NPAR),A(NDM+1,NDM+1))
       ALLOCATE(V(NDM+1),F(NDM))
       IF(IPS.EQ.-1)THEN
         CALL FNDS(IAP,NDM,U,U,ICP,PAR,2,F,DFU,DFP)
       ELSE
         CALL FUNI(IAP,NDM,U,U,ICP,PAR,2,F,DFU,DFP)
       ENDIF
       A(:,1:NDM)=DFU(:,:)
       A(:,NDM+1)=DFP(:,ICP(1))
       CALL NLVC(NDM,NDM+1,2,A,V)
       DEALLOCATE(A)
       ALLOCATE(A(NDM+1,NDM+1))
       DO I=1,NDM
         DO J=1,NDM
           A(I,J)=DFU(J,I)
         ENDDO
         A(NDM+1,I)=DFP(I,ICP(1))
       ENDDO
       DO I=1,NDM+1
          A(I,NDM+1)=V(I)
       ENDDO
       CALL NLVC(NDM+1,NDM+1,1,A,V)
       CALL NRMLZ(NDM,V)
       DO I=1,NDM
         U(NDM+I)=V(I)
       ENDDO
       DEALLOCATE(DFU,DFP,A,V,F)
       U(NDIM-1)=PAR(ICP(2))
       IF(ISW.EQ.3) THEN
C        ** Generic case
         U(NDIM)=PAR(ICP(3))
       ELSE
C        ** Non-generic case
         U(NDIM)=0.d0
       ENDIF
C
       NODIR=1
      RETURN
      END SUBROUTINE STPNBP
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C     Subroutines for the Optimization of Algebraic Systems
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNC1(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generate the equations for the continuation scheme used for
C the optimization of algebraic systems (one parameter).
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DDU(:),DDP(:)
      INTEGER JAC,NDM,NFPR,NPAR,I,II,J
C
       JAC=IAP(22)
       NDM=IAP(23)
       NFPR=IAP(29)
       NPAR=IAP(31)
       ALLOCATE(DDU(NDIM),DDP(NPAR))
C
       PAR(ICP(2))=U(NDIM)
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Rearrange (Since dimensions in FNC1 and FUNI differ).
C
       IF(IJAC.NE.0)THEN
         DO J=NDM,1,-1
           DO I=NDM,1,-1
             II=(J-1)*NDM+I-1
             DFDU(I,J)=DFDU(MOD(II,NDIM)+1, II/NDIM+1)
           ENDDO
         ENDDO
C
         DO J=NPAR,1,-1
           DO I=NDM,1,-1
             II=(J-1)*NDM+I-1
             DFDP(I,J)=DFDP(MOD(II,NDIM)+1, II/NDIM+1)
           ENDDO
         ENDDO
       ENDIF
C
       CALL FOPI(JAC,NFPR,NDM,U,ICP,PAR,IJAC,F(NDIM),DDU,DDP)
       F(NDIM)=PAR(ICP(1))-F(NDIM)
C
       IF(IJAC.NE.0)THEN
         DO I=1,NDM
           DFDU(NDIM,I)=-DDU(I)
           DFDU(I,NDIM)=DFDP(I,ICP(2))
           DFDP(I,ICP(1))=0
         ENDDO
         DFDU(NDIM,NDIM)=-DDP(ICP(2))
         DFDP(NDIM,ICP(1))=1
       ENDIF
C
      DEALLOCATE(DDU,DDP)
      RETURN
      END SUBROUTINE FNC1
C
C     ---------- ------
      SUBROUTINE STPNC1(IAP,PAR,ICP,U,UDOT,NODIR)
C
C Generate starting data for optimization problems (one parameter).
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),U(*),UDOT(*)
C Local
      INTEGER NDIM,JAC,NDM,NFPR
      DOUBLE PRECISION DUM(1),T,FOP
C
       NDIM=IAP(1)
       JAC=IAP(22)
       NDM=IAP(23)
       NFPR=IAP(29)
C
       T=0.d0
       U(:NDIM)=0.d0
       CALL STPNT(NDIM,U,PAR,T)
       NFPR=2
       IAP(29)=NFPR
       CALL FOPI(JAC,NFPR,NDM,U,ICP,PAR,0,FOP,DUM,DUM)
       PAR(ICP(1))=FOP
       U(NDIM)=PAR(ICP(2))
       NODIR=1
       UDOT(:NDIM)=0d0
C
      RETURN
      END SUBROUTINE STPNC1
C
C     ---------- ----
      SUBROUTINE FNC2(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generate the equations for the continuation scheme used for the
C optimization of algebraic systems (more than one parameter).
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:),DFP(:),UU1(:),UU2(:),
     *     FF1(:),FF2(:)
      INTEGER NDM,NPAR,I,J
      DOUBLE PRECISION UMX,EP
C
       NDM=IAP(23)
       NPAR=IAP(31)
C
C Generate the function.
C
       ALLOCATE(DFU(NDM*NDM),DFP(NDM*NPAR))
       CALL FFC2(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFU,DFP)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU,DFP)
         RETURN
       ENDIF
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NDIM),FF2(NDIM))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U(J)
           UU2(J)=U(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FFC2(IAP,NDIM,UU1,UOLD,ICP,PAR,FF1,NDM,DFU,DFP)
         CALL FFC2(IAP,NDIM,UU2,UOLD,ICP,PAR,FF2,NDM,DFU,DFP)
         DO J=1,NDIM
           DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(DFU,DFP,UU1,UU2,FF1,FF2)
       IF (IJAC.EQ.1)RETURN
C
       DO I=1,NDIM
         DFDP(I,ICP(1))=0.d0
       ENDDO
       DFDP(NDIM,ICP(1))=1.d0
C
      RETURN
      END SUBROUTINE FNC2
C
C     ---------- ----
      SUBROUTINE FFC2(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NDM
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM),DFDP(NDM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DDU(:),DDP(:)
      INTEGER JAC,NFPR,NPAR,NDM2,ICPM,I,J
      DOUBLE PRECISION FOP
C
       JAC=IAP(22)
       NFPR=IAP(29)
       NPAR=IAP(31)
       ALLOCATE(DDU(NDM),DDP(NPAR))
C
       DO I=2,NFPR
         PAR(ICP(I))=U(2*NDM+I)
       ENDDO
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,2,F,DFDU,DFDP)
       CALL FOPI(JAC,NFPR,NDM,U,ICP,PAR,2,FOP,DDU,DDP)
C
       DO I=1,NDM
         F(NDM+I)=DDU(I)*U(2*NDM+1)
         DO J=1,NDM
           F(NDM+I)=F(NDM+I)+DFDU(J,I)*U(NDM+J)
         ENDDO
       ENDDO
C
       NDM2=2*NDM
       ICPM=NFPR-2
       DO I=1,ICPM
         F(NDM2+I)=DDP(ICP(I+1))*U(NDM2+1)
       ENDDO
C
       DO I=1,ICPM
         DO J=1,NDM
           F(NDM2+I)=F(NDM2+I)+U(NDM+J)*DFDP(J,ICP(I+1))
         ENDDO
       ENDDO
C
       F(NDIM-1)=U(NDM2+1)*U(NDM2+1)-1
       DO J=1,NDM
         F(NDIM-1)=F(NDIM-1)+U(NDM+J)*U(NDM+J)
       ENDDO
       F(NDIM)=PAR(ICP(1))-FOP
C
      DEALLOCATE(DDU,DDP)
      RETURN
      END SUBROUTINE FFC2
C
C     ---------- ------
      SUBROUTINE STPNC2(IAP,PAR,ICP,U,UDOT,NODIR)
C
      USE IO
      USE SUPPORT
C
C Generates starting data for the continuation equations for
C optimization of algebraic systems (More than one parameter).
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),U(*),UDOT(*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:),DFP(:),DD(:,:),DU(:),V(:),
     *     F(:),DP(:)
      INTEGER, ALLOCATABLE :: ICPRS(:)
      INTEGER NDIM,JAC,NDM,NFPR,NPAR,I,J
      DOUBLE PRECISION FOP
C
       NDIM=IAP(1)
       JAC=IAP(22)
       NDM=IAP(23)
       NFPR=IAP(29)
       NPAR=IAP(31)
C
       ALLOCATE(ICPRS(NFPR))
       CALL READLB(IAP,ICPRS,U,UDOT,PAR)
       DEALLOCATE(ICPRS)
C
       IF(NFPR.EQ.3)THEN
         ALLOCATE(DFU(NDM*NDM),DFP(NDM*NPAR),F(NDM),V(NDM+1))
         ALLOCATE(DD(NDM+1,NDM+1),DU(NDM),DP(NPAR))
         CALL FUNI(IAP,NDM,U,U,ICP,PAR,2,F,DFU,DFP)
         CALL FOPI(JAC,NFPR,NDM,U,ICP,PAR,2,FOP,DU,DP)
C       TRANSPOSE
         DO I=1,NDM
           DO J=1,NDM
             DD(I,J)=DFU((I-1)*NDM+J)
           ENDDO
         ENDDO
         DO I=1,NDM
           DD(I,NDM+1)=DU(I)
           DD(NDM+1,I)=DFP((ICP(2)-1)*NDM+I)
         ENDDO
         DD(NDM+1,NDM+1)=DP(ICP(2))
         CALL NLVC(NDM+1,NDM+1,1,DD,V)
         CALL NRMLZ(NDM+1,V)
         DO I=1,NDM+1
           U(NDM+I)=V(I)
         ENDDO
         PAR(ICP(1))=FOP
         DEALLOCATE(DFU,DFP,F,V,DD,DU,DP)
       ENDIF
C
       DO I=1,NFPR-1
         U(NDIM-NFPR+1+I)=PAR(ICP(I+1))
       ENDDO
C
       NODIR=1
      RETURN
      END SUBROUTINE STPNC2
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C        Subroutines for Discrete Dynamical Systems
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNDS(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generate the equations for continuing fixed points.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)

      INTEGER I
C
       CALL FUNI(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
       DO I=1,NDIM
         F(I)=F(I)-U(I)
       ENDDO
C
       IF(IJAC.EQ.0)RETURN
C
       DO I=1,NDIM
         DFDU(I,I)=DFDU(I,I)-1
       ENDDO
C
      RETURN
      END SUBROUTINE FNDS
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C        Subroutines for Time Integration of ODEs
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNTI(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generate the equations for continuing fixed points.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM+1)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)

      INTEGER I,J
      DOUBLE PRECISION TOLD,DT
C
       CALL FUNI(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
       TOLD=UOLD(NDIM+1)
       DT=PAR(ICP(1))-TOLD
C
       DO I=1,NDIM
         DFDP(I,ICP(1))=F(I)
         F(I)= DT*F(I) - U(I) + UOLD(I)
       ENDDO
C
       IF(IJAC.EQ.0)RETURN
C
       DO I=1,NDIM
         DO J=1,NDIM
           DFDU(I,J)= DT*DFDU(I,J)
         ENDDO
         DFDU(I,I)= DFDU(I,I) - 1.d0
       ENDDO
C
      RETURN
      END SUBROUTINE FNTI
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C     Subroutines for the Continuation of Hopf Bifurcation Points
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNHB(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for the 2-parameter continuation of Hopf
C bifurcation points in ODE/wave/map.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE ::DFU(:),UU1(:),UU2(:),FF1(:),FF2(:)
      INTEGER NDM,I,J
      DOUBLE PRECISION UMX,EP,P
C
       NDM=IAP(23)
C
C Generate the function.
C
       ALLOCATE(DFU(NDIM*NDIM))
       CALL FFHB(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFU)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU)
         RETURN
       ENDIF
C
C Generate the Jacobian.
C
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NDIM),FF2(NDIM))
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U(J)
           UU2(J)=U(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FFHB(IAP,NDIM,UU1,UOLD,ICP,PAR,FF1,NDM,DFU)
         CALL FFHB(IAP,NDIM,UU2,UOLD,ICP,PAR,FF2,NDM,DFU)
         DO J=1,NDIM
           DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(UU1,UU2,FF2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF1,DFU)
         RETURN
       ENDIF
C
       P=PAR(ICP(1))
       PAR(ICP(1))=P+EP
C
       CALL FFHB(IAP,NDIM,U,UOLD,ICP,PAR,FF1,NDM,DFU)
C
       DO J=1,NDIM
         DFDP(J,ICP(1))=(FF1(J)-F(J))/EP
       ENDDO
C
       PAR(ICP(1))=P
       DEALLOCATE(FF1,DFU)
C
      RETURN
      END SUBROUTINE FNHB
C
C     ---------- ----
      SUBROUTINE FFHB(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFDU)
C
      USE SUPPORT
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NDM
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM)
C Local
      INTEGER IPS,NDM2,I,J
      DOUBLE PRECISION DUMDP(1),THTA,S1,C1,ROM
C
       IPS=IAP(2)
       NDM2=2*NDM
C
       PAR(ICP(2))=U(NDIM)
       IF(IPS==-1)THEN
          THTA=U(NDIM-1)
          S1=SIN(THTA)
          C1=COS(THTA)
          ROM=1.d0
       ELSE
          ROM=U(NDIM-1)
          IF(IPS==11)THEN
             PAR(ICP(2))=U(NDIM)
          ELSE
             PAR(11)=ROM*PI(2.d0)
          ENDIF
          S1=1.d0
          C1=0.d0
       ENDIF
       IF(IPS==11)THEN 
          CALL FNWS(IAP,NDIM,U,UOLD,ICP,PAR,1,F,DFDU,DUMDP)
       ELSE
          CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,1,F,DFDU,DUMDP)
       ENDIF
C
       IF(IPS==-1)THEN
          DO I=1,NDM
             F(I)=F(I)-U(I)
             DFDU(I,I)=DFDU(I,I)-C1
          ENDDO
       ENDIF
       DO I=1,NDM
          F(NDM+I)=S1*U(NDM2+I)
          F(NDM2+I)=-S1*U(NDM+I)
          DO J=1,NDM
             F(NDM+I)=F(NDM+I)+ROM*DFDU(I,J)*U(NDM+J)
             F(NDM2+I)=F(NDM2+I)+ROM*DFDU(I,J)*U(NDM2+J)
          ENDDO
       ENDDO
C
       F(NDIM-1)=-1
C
       DO I=1,NDM
          F(NDIM-1)=F(NDIM-1)+U(NDM+I)*U(NDM+I)+U(NDM2+I)*U(NDM2+I)
       ENDDO
C
       F(NDIM)=0.d0
C
       IF(IPS==-1)THEN
          DO I=1,NDM
             F(NDIM)=F(NDIM)+UOLD(NDM2+I)*U(NDM+I)-UOLD(NDM+I)*U(NDM2+I)
          ENDDO
       ELSE
          DO I=1,NDM
             F(NDIM)=F(NDIM)+UOLD(NDM2+I)*(U(NDM+I)-UOLD(NDM+I)) -
     *            UOLD(NDM+I)*(U(NDM2+I)-UOLD(NDM2+I))
          ENDDO
       ENDIF
C
      END SUBROUTINE FFHB
C
C     ---------- ------
      SUBROUTINE STPNHB(IAP,PAR,ICP,U,UDOT,NODIR)
C
      USE IO
      USE SUPPORT
C
C Generates starting data for the 2-parameter continuation of
C Hopf bifurcation point (ODE/wave/map).
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),U(*),UDOT(*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:,:),SMAT(:,:),V(:),F(:)
      INTEGER :: ICPRS(2),NDIM,IPS,NDM,NDM2,I,J
      DOUBLE PRECISION DFP(1),THTA,S1,C1,ROM,PERIOD
C
       NDIM=IAP(1)
       IPS=IAP(2)
       NDM=IAP(23)
       ALLOCATE(DFU(NDM,NDM),F(NDIM),V(NDIM),SMAT(2*NDM,2*NDM))
C
       CALL READLB(IAP,ICPRS,U,UDOT,PAR)
C
       IF(IPS==-1)THEN
          THTA=PI(2.d0)/PAR(11)
          S1=DSIN(THTA)
          C1=DCOS(THTA)
          ROM=1d0
          U(NDIM-1)=THTA
       ELSE
          PERIOD=PAR(11)
          ROM=PERIOD/PI(2.d0)
          S1=1d0
          C1=0d0
          U(NDIM-1)=ROM
       ENDIF
       IF(IPS==11)THEN 
          CALL FNWS(IAP,NDM,U,U,ICP,PAR,1,F,DFU,DFP)
       ELSE
          CALL FUNI(IAP,NDM,U,U,ICP,PAR,1,F,DFU,DFP)
       ENDIF
C
       NDM2=2*NDM
       DO I=1,NDM2
         DO J=1,NDM2
           SMAT(I,J)=0.d0
         ENDDO
       ENDDO
C
       DO I=1,NDM
         SMAT(I,NDM+I)=S1
       ENDDO
C
       DO I=1,NDM
         SMAT(NDM+I,I)=-S1
       ENDDO
C
       DO I=1,NDM 
         DO J=1,NDM
           SMAT(I,J)=ROM*DFU(I,J)
           SMAT(NDM+I,NDM+J)=ROM*DFU(I,J)
         ENDDO
         SMAT(I,I)=SMAT(I,I)-C1
         SMAT(NDM+I,NDM+I)=SMAT(NDM+I,NDM+I)-C1
       ENDDO
       CALL NLVC(NDM2,NDM2,2,SMAT,V)
       CALL NRMLZ(NDM2,V)
C
       DO I=1,NDM2
         U(NDM+I)=V(I)
       ENDDO
C
       U(NDIM)=PAR(ICP(2))
C
       DEALLOCATE(DFU,F,V,SMAT)
       NODIR=1
      END SUBROUTINE STPNHB
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C          Periodic Solutions and Fixed Period Orbits
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNPS(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for the continuation of periodic orbits.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      INTEGER J,NFPX
      DOUBLE PRECISION PERIOD
C
C Generate the function.
C
       CALL FUNI(IAP,NDIM,U,UOLD,ICP,PAR,ABS(IJAC),F,DFDU,DFDP)
       PERIOD=PAR(11)
       IF(ICP(2).EQ.11.AND.(IJAC.EQ.2.OR.IJAC.EQ.-1))THEN
C          **Variable period continuation
           DFDP(:,11)=F(:)
       ENDIF
       F(:)=PERIOD*F(:)
       IF(IJAC.EQ.0)RETURN
C      **Generate the Jacobian.
       DFDU(:,:)=PERIOD*DFDU(:,:)
       IF(ABS(IJAC).EQ.1)RETURN
       NFPX=1
       IF(ICP(2).NE.11)THEN
C          **Fixed period continuation
           NFPX=2
       ENDIF
       DO J=1,NFPX
           DFDP(:,ICP(J))=PERIOD*DFDP(:,ICP(J))
       ENDDO
C
      END SUBROUTINE FNPS
C
C     ---------- ----
      SUBROUTINE BCPS(IAP,NDIM,PAR,ICP,NBC,U0,U1,F,IJAC,DBC)
C
      USE BVP, ONLY: IRTN, NRTN
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)

      INTEGER NPAR,NN,I,J
C
       DO I=1,NDIM
         F(I)=U0(I)-U1(I)
       ENDDO
C
C Rotations
       IF(IRTN.NE.0)THEN
         DO I=1,NDIM
           IF(NRTN(I).NE.0)F(I)=F(I) + PAR(19)*NRTN(I)
         ENDDO
       ENDIF
C
       IF(IJAC.EQ.0)RETURN
C
       NPAR=IAP(31)
       NN=2*NDIM+NPAR
       DO I=1,NBC
         DO J=1,NN
           DBC(I,J)=0.d0
         ENDDO
       ENDDO
C
       DO I=1,NDIM
         DBC(I,I)=1
         DBC(I,NDIM+I)=-1
       ENDDO
C
      RETURN
      END SUBROUTINE BCPS
C
C     ---------- ----
      SUBROUTINE ICPS(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     * F,IJAC,DINT)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)

      INTEGER NPAR,NN,I
C
       F(1)=0.d0
       DO I=1,NDIM
         F(1)=F(1)+(U(I)-UOLD(I))*UPOLD(I)
       ENDDO
C
       IF(IJAC.EQ.0)RETURN
C
       NPAR=IAP(31)
       NN=NDIM+NPAR
       DO I=1,NN
         DINT(1,I)=0.d0
       ENDDO
C
       DO I=1,NDIM
          DINT(1,I)=UPOLD(I)
       ENDDO
C
      RETURN
      END SUBROUTINE ICPS
C
C     ---------- -----
      SUBROUTINE PDBLE(NDIM,NTST,NCOL,UPS,UDOTPS,TM,PAR)
C
C Preprocesses restart data for switching branches at a period doubling
C
C
      USE BVP, ONLY: IRTN

      INTEGER, INTENT(IN) :: NDIM,NCOL
      INTEGER, INTENT(INOUT) :: NTST
      DOUBLE PRECISION,INTENT(INOUT) :: TM(0:*),UPS(NDIM,0:*),
     *     UDOTPS(NDIM,0:*),PAR(*)

      INTEGER NTC,I,J
C
       PAR(11)=2.d0*PAR(11)
       IF(IRTN.NE.0)PAR(19)=2.d0*PAR(19)
C
       DO I=0,NTST-1
         TM(I)=.5d0*TM(I)
         TM(NTST+I)=.5d0+TM(I)
       ENDDO
       TM(2*NTST)=1
C
       NTC=NTST*NCOL
       DO J=0,NTC
              UPS(:,NTC+J)=   UPS(:,NTC)+   UPS(:,J)-   UPS(:,0)
           UDOTPS(:,NTC+J)=UDOTPS(:,NTC)+UDOTPS(:,J)-UDOTPS(:,0)
       ENDDO
C
       NTST=2*NTST
C
      RETURN
      END SUBROUTINE PDBLE
C
C     ---------- ------
      SUBROUTINE STPNPS(IAP,PAR,ICP,NTSR,NCOLRS,
     * RLDOT,UPS,UDOTPS,TM,NODIR)
C
      USE BVP
      USE MESH
C
C Generates starting data for the continuation of a branch of periodic
C solutions.
C If IPS is not equal to 2 then the user must have supplied
C BCND, ICND, and period-scaled F in FUNC, and the user period-scaling of F
C must be taken into account.
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(INOUT) :: NTSR,NCOLRS
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),RLDOT(*),
     *     UPS(IAP(1),0:*),UDOTPS(IAP(1),0:*),TM(0:*)

      DOUBLE PRECISION, ALLOCATABLE :: UPSR(:,:),UDOTPSR(:,:),TMR(:)
      INTEGER NDIM,IPS,IRS,ISW,ITP,NCOL,NTST,NDIMRD,NTSR2
C
       NDIM=IAP(1)
       IPS=IAP(2)
       IRS=IAP(3)
       ISW=IAP(10)
       ITP=IAP(27)
C
       IF(IRS==0)THEN
          CALL STPNUB(IAP,PAR,ICP,NTSR,NCOLRS,
     *         RLDOT,UPS,UDOTPS,TM,NODIR)
          RETURN
       ENDIF

       IF((IPS.EQ.2.OR.IPS.EQ.7).AND.ISW.EQ.-1.AND.ITP.EQ.7) THEN
C               period doubling
          NTSR2=NTSR*2
       ELSE
          NTSR2=NTSR
       ENDIF
       ALLOCATE(UPSR(NDIM,0:NCOLRS*NTSR2),
     *      UDOTPSR(NDIM,0:NCOLRS*NTSR2),TMR(0:NTSR2))
       CALL STPNBV1(IAP,PAR,ICP,NDIM,NTSR,NDIMRD,NCOLRS,
     *      RLDOT,UPSR,UDOTPSR,TMR,NODIR)
       IF((IPS.EQ.2.OR.IPS.EQ.7).AND.ISW.EQ.-1.AND.ITP.EQ.7) THEN
C
C Special case : Preprocess restart data in case of branch switching
C at a period doubling bifurcation.
C
          CALL PDBLE(NDIM,NTSR,NCOLRS,UPSR,UDOTPSR,TMR,PAR)
       ENDIF
       NTST=IAP(5)
       NCOL=IAP(6)
       CALL ADAPT2(NTSR,NCOLRS,NDIM,NTST,NCOL,NDIM,
     *      TMR,UPSR,UDOTPSR,TM,UPS,UDOTPS,.TRUE.)
       DEALLOCATE(TMR,UPSR,UDOTPSR)

      END SUBROUTINE STPNPS
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C          Travelling Wave Solutions to Parabolic PDEs
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNWS(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Sets up equations for the continuation of spatially homogeneous
C solutions to parabolic systems, for the purpose of finding
C bifurcations to travelling wave solutions.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:,:),DFP(:,:)
      INTEGER NDM,NPAR,NFPR,I,J
      DOUBLE PRECISION C
C
       NDM=IAP(23)
       NPAR=IAP(31)
C
C Generate the function.
C
       NDM=NDM/2
C
       IF(IJAC.NE.0)THEN
         ALLOCATE(DFU(NDM,NDM))
         IF(IJAC.NE.1)THEN
           ALLOCATE(DFP(NDM,NPAR))
         ENDIF
       ENDIF
C
       NFPR=IAP(29)
C
       C=PAR(10)
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,IJAC,F,DFU,DFP)
C
       DO I=1,NDM
         F(NDM+I)=-( C*U(NDM+I) + F(I) )/PAR(14+I)
         F(I)=U(NDM+I)
       ENDDO
C
       IF(IJAC.EQ.0)RETURN
C
       DO I=1,NDM
         DO J=1,NDM
           DFDU(I,J)        =0.d0
           DFDU(I,J+NDM)    =0.d0
           DFDU(I+NDM,J)    =-DFU(I,J)/PAR(14+I)
           DFDU(I+NDM,J+NDM)=0.d0
         ENDDO
         DFDU(I,I+NDM)     =1
         DFDU(I+NDM,I+NDM)=-C/PAR(14+I)
       ENDDO
C
       DEALLOCATE(DFU)
       IF(IJAC.EQ.1)RETURN
C
       DO I=1,NDM
         IF(ICP(1).LT.10)THEN
           DFDP(I,ICP(1))    =0.d0
           DFDP(I+NDM,ICP(1))=-DFP(I,ICP(1))/PAR(14+I)
         ENDIF
         IF(NFPR.GT.1.AND.ICP(2).LT.10)THEN
           DFDP(I,ICP(2))    =0.d0
           DFDP(I+NDM,ICP(2))=-DFP(I,ICP(2))/PAR(14+I)
         ENDIF
       ENDDO
C
C Derivative with respect to the wave speed.
C
       DO I=1,NDM
         DFDP(I,10)    =0.d0
         DFDP(I+NDM,10)=-U(NDM+I)/PAR(14+I)
       ENDDO
C
C Derivatives with respect to the diffusion coefficients.
C
       DO J=1,NDM
         DO I=1,NDM
           DFDP(I,14+J)    =0.d0
           DFDP(I+NDM,14+J)=0.d0
         ENDDO
         DFDP(J+NDM,14+J)=-F(J+NDM)/PAR(14+J)
       ENDDO
C
      DEALLOCATE(DFP)
      RETURN
      END SUBROUTINE FNWS
C
C     ---------- ----
      SUBROUTINE FNWP(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Equations for the continuation of traveling waves.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)

      INTEGER NFPX,J
      DOUBLE PRECISION PERIOD
C
C Generate the function and Jacobian.
C
      CALL FNWS(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
      PERIOD=PAR(11)
      IF(ICP(2).EQ.11.AND.(IJAC.EQ.2.OR.IJAC.EQ.-1))THEN
C        **Variable wave length
         DFDP(:,11)=F(:)
      ENDIF
      F(:)=PERIOD*F(:)
      IF(IJAC.EQ.0)RETURN
      DFDU(:,:)=PERIOD*DFDU(:,:)
      IF(ABS(IJAC).EQ.1)RETURN
      NFPX=1
      IF(ICP(2).NE.11)THEN
C        **Fixed wave length
         NFPX=2
      ENDIF
      DO J=1,NFPX
         DFDP(:,ICP(J))=PERIOD*DFDP(:,ICP(J))
      ENDDO

      END SUBROUTINE FNWP
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C             Parabolic PDEs : Stationary States
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNSP(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for taking one time step (Implicit Euler).
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:,:),DFP(:,:)
      INTEGER NDM,NPAR,I,J
      DOUBLE PRECISION PERIOD
C
       NDM=IAP(23)
       NPAR=IAP(31)
C
C Generate the function and Jacobian.
C
       IF(IJAC.NE.0)THEN
         ALLOCATE(DFU(NDM,NDM))
         IF(IJAC.NE.1)THEN
           ALLOCATE(DFP(NDM,NPAR))
         ENDIF
       ENDIF
C
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,IJAC,F(NDM+1),DFU,DFP)
C
       PERIOD=PAR(11)
       DO I=1,NDM
         F(I)    = PERIOD*U(NDM+I)
         F(NDM+I)=-PERIOD*F(NDM+I)/PAR(14+I)
       ENDDO
C
       IF(IJAC.EQ.0)RETURN
C
       DO I=1,NDM
         DO J=1,NDM
           DFDU(I,J)        =0.d0
           DFDU(I,J+NDM)    =0.d0
           DFDU(I+NDM,J)    =-PERIOD*DFU(I,J)/PAR(14+I)
           DFDU(I+NDM,J+NDM)=0.d0
         ENDDO
         DFDU(I,I+NDM)     =PERIOD
       ENDDO
       DEALLOCATE(DFU)
       IF(IJAC.EQ.1)RETURN
       DO I=1,NDM
         IF(ICP(1).EQ.11)THEN
           DFDP(I,ICP(1))    = F(I)/PERIOD
           DFDP(NDM+I,ICP(1))= F(NDM+I)/PERIOD
         ELSEIF(ICP(1).EQ.14+I)THEN
           DFDP(I,ICP(1))    = 0.d0
           DFDP(NDM+I,ICP(1))=-F(NDM+I)/PAR(14+I)
         ELSEIF(ICP(1).NE.11 .AND. 
     *          .NOT. (ICP(1).GT.14 .AND. ICP(1).LE.14+NDM) )THEN
           DFDP(I,ICP(1))    =0.d0
           DFDP(I+NDM,ICP(1))=-PERIOD*DFP(I,ICP(1))/PAR(14+I)
         ENDIF
       ENDDO
C
      DEALLOCATE(DFP)
      RETURN
      END SUBROUTINE FNSP
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C            Time Evolution of Parabolic PDEs
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNPE(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for taking one time step (Implicit Euler).
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:,:)
      INTEGER NDM,IIJAC,I,J
      DOUBLE PRECISION DUMDFP(1),T,DT,PERIOD,RLOLD
C
       NDM=IAP(23)
C
C Generate the function and Jacobian.
C
       IF(IJAC.NE.0)THEN
         ALLOCATE(DFU(NDM,NDM))
       ENDIF
C
       PERIOD=PAR(11)
       T=PAR(ICP(1))
       RLOLD=PAR(12)
       IF(T==RLOLD)THEN
          ! Two reasons:
          ! 1. at the start, then UOLD==U, so we can set DT to 1, because
          !    it is irrelevant.
          ! 2. from STUPBV, to calculate UPOLDP, which is not needed because
          !    NINT is forced to 0.
          DT=1.d0
       ELSE
          DT=T-RLOLD
       ENDIF
C
       IIJAC=IJAC
       IF(IJAC.GT.1)IIJAC=1
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,IIJAC,F(NDM+1),DFU,DUMDFP)
C
       DO I=1,NDM
         F(I)=PERIOD*U(NDM+I)
         F(NDM+I)=PERIOD*( (U(I)-UOLD(I))/DT - F(NDM+I) )/PAR(14+I)
       ENDDO
C
       IF(IJAC.EQ.0)RETURN
C
       DO I=1,NDM
         DO J=1,NDM
           DFDU(I,J)        =0.d0
           DFDU(I,J+NDM)    =0.d0
           DFDU(I+NDM,J)    =-PERIOD*DFU(I,J)/PAR(14+I)
           DFDU(I+NDM,J+NDM)=0.d0
         ENDDO
         DFDU(I,I+NDM)     =PERIOD
         DFDU(I+NDM,I)     =DFDU(I+NDM,I) + PERIOD/(DT*PAR(14+I))
       ENDDO
       DEALLOCATE(DFU)
       IF(IJAC.EQ.1)RETURN
C
       DO I=1,NDM
         DFDP(I,ICP(1))    =0.d0
         DFDP(I+NDM,ICP(1))=-PERIOD*(U(I)-UOLD(I))/(DT**2*PAR(14+I))
       ENDDO
C
      RETURN
      END SUBROUTINE FNPE
C
C     ---------- ----
      SUBROUTINE ICPE(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     * F,IJAC,DINT)
C
C Dummy integral condition subroutine for parabolic systems.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)

      F(:)=0d0
      RETURN
      END SUBROUTINE ICPE

C     ---------- ------
      SUBROUTINE PVLSPE(IAP,ICP,UPS,NDIM,PAR)

      USE BVP
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM
      DOUBLE PRECISION, INTENT(IN) :: UPS(NDIM,0:*)
      DOUBLE PRECISION, INTENT(INOUT) :: PAR(*)

C     save old time
      
      PAR(12)=PAR(ICP(1))
      CALL PVLSBV(IAP,ICP,UPS,NDIM,PAR)

      END SUBROUTINE PVLSPE
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C    Subroutines for the Continuation of Folds for Periodic Solution
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNPL(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:,:),DFP(:,:),FF1(:),FF2(:)
      INTEGER NDM,NFPR,NPAR,I,J
      DOUBLE PRECISION UMX,UU,EP,P
C
       NDM=IAP(23)
       NFPR=IAP(29)
       NPAR=IAP(31)
C
C Generate the function.
C
       ALLOCATE(DFU(NDM,NDM),DFP(NDM,NPAR))
       CALL FFPL(IAP,U,UOLD,ICP,PAR,IJAC,F,NDM,DFU,DFP)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU,DFP)
         RETURN
       ENDIF
C
C Generate the Jacobian.
C
       DFDU(1:NDM,1:NDM)=DFU(:,:)
       DFDU(1:NDM,NDM+1:NDIM)=0d0
       DFDU(NDM+1:NDIM,NDM+1:NDIM)=DFU(:,:)
       IF(IJAC==2)THEN
          DO I=1,NFPR-2
             DFDP(1:NDM,ICP(I))=DFP(:,ICP(I))
          ENDDO
          IF(ICP(2)==11)THEN
             DFDP(NDM+1:NDIM,11)=
     *            (F(NDM+1:NDIM)-PAR(12)/PAR(11)*F(1:NDM))/PAR(11)
          ENDIF
          DFDP(1:NDM,12)=0d0
          DFDP(NDM+1:NDIM,12)=DFP(:,ICP(2))/PAR(11)
          IF(ICP(3)==13)THEN
             DFDP(1:NDM,13)=0d0
          ELSE
             DFDP(1:NDM,ICP(3))=PAR(11)*DFP(:,ICP(3))
          ENDIF
       ENDIF
C
       UMX=0.d0
       DO I=1,NDM
         IF(ABS(U(I))>UMX)UMX=ABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       ALLOCATE(FF1(NDIM),FF2(NDIM))
       DO I=1,NDM
         UU=U(I)
         U(I)=UU-EP
         CALL FFPL(IAP,U,UOLD,ICP,PAR,0,FF1,NDM,DFU,DFP)
         U(I)=UU+EP
         CALL FFPL(IAP,U,UOLD,ICP,PAR,0,FF2,NDM,DFU,DFP)
         U(I)=UU
         DO J=NDM+1,NDIM
           DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(FF2)
       IF (IJAC.EQ.1)THEN
         DEALLOCATE(DFU,DFP,FF1)
         RETURN
       ENDIF
C
       DO I=1,NFPR-1
         IF(ICP(I)==11)CYCLE
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FFPL(IAP,U,UOLD,ICP,PAR,0,FF1,NDM,DFU,DFP)
         DO J=NDM+1,NDIM
           DFDP(J,ICP(I))=(FF1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
      ENDDO
C
      DEALLOCATE(DFU,DFP,FF1)
      END SUBROUTINE FNPL
C
C     ---------- ----
      SUBROUTINE FFPL(IAP,U,UOLD,ICP,PAR,IJAC,F,NDM,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(2*NDM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(2*NDM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(2*NDM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM),DFDP(NDM,*)

      INTEGER IJC,I,J
C
       IJC=IJAC
       IF(IJC==0)IJC=-1
       IF(ICP(2)/=11)IJC=2
       CALL FNPS(IAP,NDM,U,UOLD,ICP,PAR,IJC,F,DFDU,DFDP)
C
       DO I=1,NDM
         F(NDM+I)=0.d0
         DO J=1,NDM
           F(NDM+I)=F(NDM+I)+DFDU(I,J)*U(NDM+J)
         ENDDO
         F(NDM+I)=F(NDM+I)+PAR(12)/PAR(11)*DFDP(I,ICP(2))
       ENDDO
C
      RETURN
      END SUBROUTINE FFPL
C
C     ---------- ----
      SUBROUTINE BCPL(IAP,NDIM,PAR,ICP,NBC,U0,U1,F,IJAC,DBC)
C
C Boundary conditions for continuing folds (Periodic solutions)
C
      USE BVP, ONLY: IRTN, NRTN
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)

      INTEGER NDM,NPAR,NN,I,J
C
       DO I=1,NDIM
         F(I)=U0(I)-U1(I)
       ENDDO
C
C Rotations
       IF(IRTN.NE.0)THEN
         NDM=IAP(23)
         DO I=1,NDM
           IF(NRTN(I).NE.0)F(I)=F(I) + PAR(19)*NRTN(I)
         ENDDO
       ENDIF
C
       IF(IJAC.EQ.0)RETURN
C
       NPAR=IAP(31)
       NN=2*NDIM+NPAR
       DO I=1,NBC
         DO J=1,NN
           DBC(I,J)=0.d0
         ENDDO
       ENDDO
C
       DO I=1,NDIM
         DBC(I,I)=1
         DBC(I,NDIM+I)=-1
       ENDDO
C
      RETURN
      END SUBROUTINE BCPL
C
C     ---------- ----
      SUBROUTINE ICPL(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     * F,IJAC,DINT)
C
C Integral conditions for continuing folds (Periodic solutions)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)

      INTEGER NDM,NPAR,NN,I,J
C
       NDM=IAP(23)
C
       F(1)=0.d0
       F(2)=0.d0
       F(3)=PAR(12)**2 - PAR(13)
C
       DO I=1,NDM
         F(1)=F(1)+(U(I)-UOLD(I))*UPOLD(I)
         F(2)=F(2)+U(NDM+I)*UPOLD(I)
         F(3)=F(3)+U(NDM+I)*U(NDM+I)
       ENDDO
C
       IF(IJAC.EQ.0)RETURN
C
       NPAR=IAP(31)
       NN=NDIM+NPAR
       DO I=1,NINT
         DO J=1,NN
           DINT(I,J)=0.d0
         ENDDO
       ENDDO
C
       DO I=1,NDM
         DINT(1,I)=UPOLD(I)
         DINT(2,NDM+I)=UPOLD(I)
         DINT(3,NDM+I)=2.d0*U(NDM+I)
       ENDDO
C
       DINT(3,NDIM+12)=2.d0*PAR(12)
       DINT(3,NDIM+13)=-1.d0
C
      RETURN
      END SUBROUTINE ICPL
C
C     ---------- ------
      SUBROUTINE STPNPL(IAP,PAR,ICP,NTSR,NCOLRS,
     * RLDOT,UPS,UDOTPS,TM,NODIR)
C
      USE BVP
      USE IO
      USE MESH
C
C Generates starting data for the 2-parameter continuation of folds
C on a branch of periodic solutions.
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(INOUT) :: NTSR,NCOLRS
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),RLDOT(*),
     *     UPS(IAP(1),0:*),UDOTPS(IAP(1),0:*),TM(0:*)
C Local
      DOUBLE PRECISION RLDOTRS(4)
      INTEGER ICPRS(4),NDIM,NDM,NCOL,NTST,ITPRS,NDIMRD,J
      DOUBLE PRECISION, ALLOCATABLE :: UPSR(:,:),UDOTPSR(:,:),TMR(:)
C
       NDIM=IAP(1)
       NDM=IAP(23)
C
       ALLOCATE(UPSR(NDIM,0:NCOLRS*NTSR),UDOTPSR(NDIM,0:NCOLRS*NTSR),
     *      TMR(0:NTSR))
       CALL READBV(IAP,PAR,ICPRS,NTSR,NCOLRS,NDIMRD,RLDOTRS,UPSR,
     *      UDOTPSR,TMR,ITPRS,NDIM)
C
C Complement starting data
         PAR(12)=0.d0
         PAR(13)=0.d0
         IF(ICP(3).EQ.11)THEN
C          Variable period
           RLDOT(1)=RLDOTRS(1)
           RLDOT(2)=0.d0
           RLDOT(3)=RLDOTRS(2)
           RLDOT(4)=0.d0
C          Variable period
         ELSE
C          Fixed period
           RLDOT(1)=RLDOTRS(1)
           RLDOT(2)=RLDOTRS(2)
           RLDOT(3)=0.d0
           RLDOT(4)=0.d0
         ENDIF
         DO J=0,NTSR*NCOLRS
            UPSR(NDM+1:NDIM,J)=0.d0
            UDOTPSR(NDM+1:NDIM,J)=0.d0
         ENDDO
C
       NODIR=0
       NTST=IAP(5)
       NCOL=IAP(6)
       CALL ADAPT2(NTSR,NCOLRS,NDIM,NTST,NCOL,NDIM,
     *      TMR,UPSR,UDOTPSR,TM,UPS,UDOTPS,.FALSE.)
       DEALLOCATE(TMR,UPSR,UDOTPSR)
C
      RETURN
      END SUBROUTINE STPNPL
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C   Subroutines for BP cont (Periodic Solutions) (by F. Dercole)
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- -----
      SUBROUTINE FNPBP(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:),DFP(:),UU1(:),UU2(:),
     *     FF1(:),FF2(:)
      INTEGER NDM,NFPR,NPAR,I,J
      DOUBLE PRECISION UMX,EP,P
C
       NDM=IAP(23)
       NFPR=IAP(29)
       NPAR=IAP(31)
C
C Generate the function.
C
       ALLOCATE(DFU(NDM*NDM),DFP(NDM*NPAR))
       CALL FFPBP(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFU,DFP)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU,DFP)
         RETURN
       ENDIF
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NDIM),FF2(NDIM))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U(J)
           UU2(J)=U(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FFPBP(IAP,NDIM,UU1,UOLD,ICP,PAR,FF1,NDM,DFU,DFP)
         CALL FFPBP(IAP,NDIM,UU2,UOLD,ICP,PAR,FF2,NDM,DFU,DFP)
         DO J=1,NDIM
           DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(UU1,UU2,FF2)
       IF (IJAC.EQ.1)THEN
         DEALLOCATE(DFU,DFP,FF1)
         RETURN
       ENDIF
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FFPBP(IAP,NDIM,U,UOLD,ICP,PAR,FF1,NDM,DFU,DFP)
         DO J=1,NDIM
           DFDP(J,ICP(I))=(FF1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
      ENDDO
C
      DEALLOCATE(DFU,DFP,FF1)
      RETURN
      END SUBROUTINE FNPBP
C
C     ---------- -----
      SUBROUTINE FFPBP(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NDM
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM),DFDP(NDM,*)
C Local
      DOUBLE PRECISION DUM(1),UPOLD(NDM)
      INTEGER ISW,I,J
      DOUBLE PRECISION PERIOD
C
       PERIOD=PAR(11)
       ISW=IAP(10)
C
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,2,F,DFDU,DFDP)
       CALL FUNC(NDM,UOLD,ICP,PAR,0,UPOLD,DUM,DUM)
C
       IF(ISW.GT.0) THEN
C        ** restart 1 or 2
         DO I=1,NDM
           F(NDM+I)=0.d0
           DO J=1,NDM
             F(NDM+I)=F(NDM+I)-DFDU(J,I)*U(NDM+J)
           ENDDO
           F(NDM+I)=PERIOD*(F(NDM+I)+UPOLD(I)*PAR(16))
         ENDDO
       ELSE
C        ** start
         DO I=1,NDM
           F(NDM+I)=0.d0
           F(2*NDM+I)=0.d0
           F(3*NDM+I)=0.d0
           DO J=1,NDM
             F(NDM+I)=F(NDM+I)+DFDU(I,J)*U(NDM+J)
             F(2*NDM+I)=F(2*NDM+I)+DFDU(I,J)*U(2*NDM+J)
             F(3*NDM+I)=F(3*NDM+I)-DFDU(J,I)*U(3*NDM+J)
           ENDDO
           F(NDM+I)=PERIOD*(F(NDM+I)+DFDP(I,ICP(1))*PAR(12))
           F(2*NDM+I)=PERIOD*(F(2*NDM+I)+DFDP(I,ICP(1))*PAR(14))
           F(3*NDM+I)=PERIOD*(F(3*NDM+I)+UPOLD(I)*PAR(16))+
     *       PAR(20)*U(NDM+I)+PAR(21)*U(2*NDM+I)
           IF(ICP(4).EQ.11)THEN
C            ** Variable period
             F(NDM+I)=F(NDM+I)+F(I)*PAR(13)
             F(2*NDM+I)=F(2*NDM+I)+F(I)*PAR(15)
           ELSE
C            ** Fixed period
             F(NDM+I)=F(NDM+I)+PERIOD*DFDP(I,ICP(2))*PAR(13)
             F(2*NDM+I)=F(2*NDM+I)+PERIOD*DFDP(I,ICP(2))*PAR(15)
           ENDIF
         ENDDO
       ENDIF
C
       IF((ISW.EQ.2).OR.(ISW.LT.0)) THEN
C        ** Non-generic and/or start
         DO I=1,NDM
           F(I)=PERIOD*F(I)-PAR(18)*U(NDIM-NDM+I)
         ENDDO
       ELSE
C        ** generic and restart
         DO I=1,NDM
           F(I)=PERIOD*F(I)
         ENDDO
       ENDIF
C
      RETURN
      END SUBROUTINE FFPBP
C
C     ---------- -----
      SUBROUTINE BCPBP(IAP,NDIM,PAR,ICP,NBC,U0,U1,FB,IJAC,DBC)
C
C Boundary conditions for continuing BP (Periodic solutions)
C
      USE BVP, ONLY: IRTN, NRTN
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: FB(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)

      INTEGER ISW,NDM,NPAR,NN,I,J
C
       ISW=IAP(10)
       NDM=IAP(23)
C
       DO I=1,NDIM
         FB(I)=U0(I)-U1(I)
       ENDDO
C
       IF((ISW.EQ.2).OR.(ISW.LT.0)) THEN
C        ** Non-generic and/or start
         DO I=1,NDM
           FB(I)=FB(I)+PAR(18)*U0(NDIM-NDM+I)
         ENDDO
       ENDIF
C
C Rotations
       IF(IRTN.NE.0)THEN
         DO I=1,NDM
           IF(NRTN(I).NE.0)FB(I)=FB(I)+PAR(19)*NRTN(I)
         ENDDO
       ENDIF
C
       IF(IJAC.EQ.0)RETURN
C
       NPAR=IAP(31)
       NN=2*NDIM+NPAR
       DO I=1,NBC
         DO J=1,NN
           DBC(I,J)=0.d0
         ENDDO
       ENDDO
C
       DO I=1,NDIM
         DBC(I,I)=1
         DBC(I,NDIM+I)=-1
       ENDDO
C
       IF((ISW.EQ.2).OR.(ISW.LT.0)) THEN
C        ** Non-generic and/or start
         DO I=1,NDM
           DBC(I,NDIM-NDM+I)=PAR(18)
         ENDDO
       ENDIF
C
       IF(IJAC.EQ.1)RETURN
C
       IF((ISW.EQ.2).OR.(ISW.LT.0)) THEN
C        ** Non-generic and/or start
         DO I=1,NDM
           DBC(I,2*NDIM+18)=U0(NDIM-NDM+I)
         ENDDO
       ENDIF
C
      RETURN
      END SUBROUTINE BCPBP
C
C     ---------- -----
      SUBROUTINE ICPBP(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     *  F,IJAC,DINT)
C
C Integral conditions for continuing BP (Periodic solutions)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)
C
C Local
      DOUBLE PRECISION, ALLOCATABLE :: UU1(:),UU2(:),FF1(:),FF2(:)
      INTEGER NFPR,I,J
      DOUBLE PRECISION UMX,EP,P
C
       NFPR=IAP(29)
C
C Generate the function.
C
       CALL FIPBP(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,F)
C
       IF(IJAC.EQ.0)RETURN
C
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NINT),FF2(NINT))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U(J)
           UU2(J)=U(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FIPBP(IAP,NDIM,PAR,ICP,NINT,UU1,UOLD,UDOT,UPOLD,FF1)
         CALL FIPBP(IAP,NDIM,PAR,ICP,NINT,UU2,UOLD,UDOT,UPOLD,FF2)
         DO J=1,NINT
           DINT(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(UU1,UU2,FF2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF1)
         RETURN
       ENDIF
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FIPBP(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,FF1)
         DO J=1,NINT
           DINT(J,NDIM+ICP(I))=(FF1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
       DEALLOCATE(FF1)
C
      RETURN
      END SUBROUTINE ICPBP
C
C     ---------- -----
      SUBROUTINE FIPBP(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,FI)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: FI(NINT)
C
C Local
      DOUBLE PRECISION, ALLOCATABLE :: F(:),DFU(:,:),DFP(:,:)
      INTEGER ISW,NDM,NPAR,I
      DOUBLE PRECISION PERIOD
C
       PERIOD=PAR(11)
       ISW=IAP(10)
       NDM=IAP(23)
       NPAR=IAP(31)
C
       ALLOCATE(F(NDM),DFU(NDM,NDM),DFP(NDM,NPAR))
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,2,F,DFU,DFP)
C
       FI(1)=0.d0
       FI(NINT)=PAR(16)**2-PAR(17)
       DO I=1,NDM
         FI(1)=FI(1)+(U(I)-UOLD(I))*UPOLD(I)
         FI(NINT)=FI(NINT)+U(NDIM-NDM+I)**2
       ENDDO
C
       IF((ISW.EQ.2).OR.(ISW.LT.0)) THEN
C        ** Non-generic and/or start
         FI(1)=FI(1)+PAR(18)*PAR(16)
       ENDIF
C
       IF(ISW.GT.0) THEN
C        ** restart 1 or 2
         FI(2)=0.d0
         FI(3)=0.d0
         DO I=1,NDM
           FI(2)=FI(2)-PERIOD*DFP(I,ICP(1))*U(NDM+I)
           IF(ICP(4).EQ.11)THEN
C            ** Variable period
             FI(3)=FI(3)-F(I)*U(NDM+I)
           ELSE
C            ** Fixed period
             FI(3)=FI(3)-PERIOD*DFP(I,ICP(2))*U(NDM+I)
           ENDIF
         ENDDO
       ELSE
C        ** start
         FI(2)=0.d0
         FI(3)=0.d0
         FI(4)=PAR(12)**2+PAR(13)**2-1.d0
         FI(5)=PAR(14)**2+PAR(15)**2-1.d0
         FI(6)=PAR(12)*PAR(14)+PAR(13)*PAR(15)
         FI(7)=FI(6)
         FI(8)=PAR(20)*PAR(12)+PAR(21)*PAR(14)
         FI(9)=PAR(20)*PAR(13)+PAR(21)*PAR(15)
         DO I=1,NDM
           FI(2)=FI(2)+U(NDM+I)*UPOLD(I)
           FI(3)=FI(3)+U(2*NDM+I)*UPOLD(I)
           FI(4)=FI(4)+U(NDM+I)*UOLD(NDM+I)
           FI(5)=FI(5)+U(2*NDM+I)*UOLD(2*NDM+I)
           FI(6)=FI(6)+U(NDM+I)*UOLD(2*NDM+I)
           FI(7)=FI(7)+U(2*NDM+I)*UOLD(NDM+I)
           FI(8)=FI(8)-PERIOD*DFP(I,ICP(1))*U(3*NDM+I)
           IF(ICP(4).EQ.11)THEN
C            ** Variable period
             FI(9)=FI(9)-F(I)*U(3*NDM+I)
           ELSE
C            ** Fixed period
             FI(9)=FI(9)-PERIOD*DFP(I,ICP(2))*U(3*NDM+I)
           ENDIF
         ENDDO
       ENDIF
C
       DEALLOCATE(F,DFU,DFP)
C
      RETURN
      END SUBROUTINE FIPBP
C
C     ---------- -------
      SUBROUTINE STPNPBP(IAP,PAR,ICP,NTSR,NCOLRS,
     * RLDOT,UPS,UDOTPS,TM,NODIR)
C
      USE BVP
      USE IO
      USE MESH
      USE SOLVEBV
C
C Generates starting data for the 2-parameter continuation of BP
C on a branch of periodic solutions.
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(INOUT) :: NTSR,NCOLRS
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),RLDOT(*),
     *     UPS(IAP(1),0:*),UDOTPS(IAP(1),0:*),TM(0:*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: VPS(:,:),VDOTPS(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: THU1(:)
      DOUBLE PRECISION, ALLOCATABLE :: P0(:,:),P1(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: U(:),DTM(:)
      INTEGER ICPRS(11)
      DOUBLE PRECISION DUM(1),RLDOTRS(11),RLCUR(2),RVDOT(2),THL1(2)
      DOUBLE PRECISION, ALLOCATABLE :: UPST(:,:),UDOTPST(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: VDOTPST(:,:),UPOLDPT(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: UPSR(:,:),UDOTPSR(:,:),TMR(:)
      INTEGER NDIM,NTST,NCOL,NBC,NINT,ISW,NDM,NFPR,NDIM3,IFST,NLLV,ITPRS
      INTEGER NDIMRD,I,J
      DOUBLE PRECISION DET,RDSZ
C
       NDIM=IAP(1)
       NTST=IAP(5)
       NCOL=IAP(6)
       ISW=IAP(10)
       NDM=IAP(23)
       NFPR=IAP(29)
C
       NDIM3=GETNDIM3()
C
       IF(NDIM.EQ.NDIM3) THEN
C        ** restart 2
         CALL STPNBV(IAP,PAR,ICP,NTSR,NCOLRS,RLDOT,
     *     UPS,UDOTPS,TM,NODIR)
         RETURN
       ENDIF
C
       ALLOCATE(UPSR(NDIM,0:NCOLRS*NTSR),UDOTPSR(NDIM,0:NCOLRS*NTSR),
     *      TMR(0:NTSR))
       IF(ISW.LT.0) THEN
C
C Start
C
C        ** allocation
         ALLOCATE(UPST(NDM,0:NTSR*NCOLRS),UDOTPST(NDM,0:NTSR*NCOLRS))
         ALLOCATE(UPOLDPT(NDM,0:NTSR*NCOLRS))
         ALLOCATE(VDOTPST(NDM,0:NTSR*NCOLRS))
         ALLOCATE(THU1(NDM))
         ALLOCATE(P0(NDM,NDM),P1(NDM,NDM))
         ALLOCATE(U(NDM),DTM(NTSR))
C
C        ** read the std branch
         CALL READBV(IAP,PAR,ICPRS,NTSR,NCOLRS,NDIMRD,RLDOTRS,UPST,
     *     UDOTPST,TMR,ITPRS,NDM)
C
         DO I=1,NTSR
           DTM(I)=TMR(I)-TMR(I-1)
         ENDDO
C
         RLCUR(1)=PAR(ICPRS(1))
         RLCUR(2)=PAR(ICPRS(2))
C
C Compute the second null vector
C
C        ** redefine IAP
         IAP(1)=NDM
         IAP(5)=NTSR
         IAP(6)=NCOLRS
         NBC=IAP(12)
         NINT=IAP(13)
         IAP(12)=NDM
         IAP(13)=1
         IAP(29)=2
C
C        ** compute UPOLDP
         DO J=0,NTSR*NCOLRS
            U(:)=UPST(:,J)
            CALL FNPS(IAP,NDM,U,U,ICPRS,PAR,0,UPOLDPT(1,J),DUM,DUM)
         ENDDO
C
C        ** unit weights
         THL1(:)=1.d0
         THU1(1:NDM)=1.d0
C
C        ** call SOLVBV
         RDSZ=0.d0
         NLLV=1
         IFST=1
         CALL SOLVBV(IFST,IAP,DET,PAR,ICPRS,FNPS,BCPS,ICPS,RDSZ,NLLV,
     *     RLCUR,RLCUR,RLDOTRS,NDM,UPST,UPST,UDOTPST,UPOLDPT,
     *     DTM,VDOTPST,RVDOT,P0,P1,THL1,THU1)
C
C        ** normalization
         CALL SCALEB(NTSR,NCOLRS,NDM,2,UDOTPST,RLDOTRS,DTM,THL1,THU1)
         CALL SCALEB(NTSR,NCOLRS,NDM,2,VDOTPST,RVDOT,DTM,THL1,THU1)
C
C        ** restore IAP
         IAP(1)=NDIM
         IAP(5)=NTST
         IAP(6)=NCOL
         IAP(12)=NBC
         IAP(13)=NINT
         IAP(29)=NFPR
C
C        ** init UPS,PAR
         UPSR(1:NDM,:)=UPST(:,:)
         UPSR(NDM+1:2*NDM,:)=UDOTPST(:,:)
         UPSR(2*NDM+1:3*NDM,:)=VDOTPST(:,:)
         UPSR(3*NDM+1:4*NDM,:)=0.d0
         UDOTPSR(:,:)=0.d0
C
C        ** init q,r,psi^*3,a,b,c1,c1
         PAR(12:13)=RLDOTRS(1:2)
         PAR(14:15)=RVDOT(1:2)
         PAR(16:18)=0.d0
         PAR(20:21)=0.d0
         RLDOT(1:2)=0.d0
         IF(ICP(4).EQ.11)THEN
C          ** Variable period
           RLDOT(3)=1.d0
           RLDOT(4)=0.d0
         ELSE
C          ** Fixed period
           RLDOT(3)=0.d0
           RLDOT(4)=1.d0
         ENDIF
         RLDOT(5:11)=0.d0
C
         DEALLOCATE(UPST,UPOLDPT,UDOTPST,VDOTPST)
         DEALLOCATE(THU1)
         DEALLOCATE(P0,P1)
         DEALLOCATE(U,DTM)
C
         NODIR=0
C
       ELSE
C
C Restart 1
C
         ALLOCATE(VPS(2*NDIM,0:NTSR*NCOLRS),
     *         VDOTPS(2*NDIM,0:NTSR*NCOLRS))
C
C        ** read the std branch
         CALL READBV(IAP,PAR,ICPRS,NTSR,NCOLRS,NDIMRD,RLDOTRS,VPS,
     *     VDOTPS,TMR,ITPRS,2*NDIM)
C
         UPSR(1:NDM,:)=VPS(1:NDM,:)
         UPSR(NDM+1:2*NDM,:)=VPS(3*NDM+1:4*NDM,:)
C
         DEALLOCATE(VPS,VDOTPS)
C
         NODIR=1
C
       ENDIF
C
       CALL ADAPT2(NTSR,NCOLRS,NDIM,NTST,NCOL,NDIM,
     *      TMR,UPSR,UDOTPSR,TM,UPS,UDOTPS,.FALSE.)
       DEALLOCATE(TMR,UPSR,UDOTPSR)
      RETURN
      END SUBROUTINE STPNPBP
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C   Subroutines for the Continuation of Period Doubling Bifurcations
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNPD(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE ::DFU(:),UU1(:),UU2(:),FF1(:),FF2(:)
      INTEGER NDM,NFPR,I,J
      DOUBLE PRECISION UMX,EP,P
C
       NDM=IAP(23)
       NFPR=IAP(29)
C
C Generate the function.
C
       ALLOCATE(DFU(NDM*NDM))
       CALL FFPD(IAP,U,UOLD,ICP,PAR,F,NDM,DFU)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU)
         RETURN
       ENDIF
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NDIM),FF2(NDIM))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U(J)
           UU2(J)=U(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FFPD(IAP,UU1,UOLD,ICP,PAR,FF1,NDM,DFU)
         CALL FFPD(IAP,UU2,UOLD,ICP,PAR,FF2,NDM,DFU)
         DO J=1,NDIM
           DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(UU1,UU2,FF2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF1,DFU)
         RETURN
       ENDIF
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FFPD(IAP,U,UOLD,ICP,PAR,FF1,NDM,DFU)
         DO J=1,NDIM
           DFDP(J,ICP(I))=(FF1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
      ENDDO
C
      DEALLOCATE(FF1,DFU)
      RETURN
      END SUBROUTINE FNPD
C
C     ---------- ----
      SUBROUTINE FFPD(IAP,U,UOLD,ICP,PAR,F,NDM,DFDU)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDM
      DOUBLE PRECISION, INTENT(IN) :: UOLD(2*NDM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(2*NDM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(2*NDM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM)
C Local
      INTEGER I,J
      DOUBLE PRECISION DUMDP(1),PERIOD
C
       PERIOD=PAR(11)
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,1,F,DFDU,DUMDP)
C
       DO I=1,NDM
         F(NDM+I)=0.d0
         DO J=1,NDM
           F(NDM+I)=F(NDM+I)+DFDU(I,J)*U(NDM+J)
        ENDDO
         F(I)=PERIOD*F(I)
         F(NDM+I)=PERIOD*F(NDM+I)
       ENDDO
C
      RETURN
      END SUBROUTINE FFPD
C
C     ---------- ----
      SUBROUTINE BCPD(IAP,NDIM,PAR,ICP,NBC,U0,U1,F,IJAC,DBC)
C
      USE BVP, ONLY: IRTN, NRTN
C
C Generate boundary conditions for the 2-parameter continuation
C of period doubling bifurcations.
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)
C
      INTEGER NDM,NPAR,NN,I,J
       NDM=IAP(23)
C
       DO I=1,NDM
         F(I)=U0(I)-U1(I)
         F(NDM+I)=U0(NDM+I)+U1(NDM+I)
       ENDDO
C
C Rotations
       IF(IRTN.NE.0)THEN
         DO I=1,NDM
           IF(NRTN(I).NE.0)F(I)=F(I) + PAR(19)*NRTN(I)
         ENDDO
       ENDIF
C
       IF(IJAC.EQ.0)RETURN
C
       NPAR=IAP(31)
       NN=2*NDIM+NPAR
       DO I=1,NBC
         DO J=1,NN
           DBC(I,J)=0.d0
         ENDDO
       ENDDO
C
       DO I=1,NDIM
         DBC(I,I)=1
         IF(I.LE.NDM) THEN
           DBC(I,NDIM+I)=-1
         ELSE
           DBC(I,NDIM+I)=1
         ENDIF
       ENDDO
C
      RETURN
      END SUBROUTINE BCPD
C
C     ---------- ----
      SUBROUTINE ICPD(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     * F,IJAC,DINT)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)

      INTEGER NDM,NPAR,NN,I,J
C
       NDM=IAP(23)
C
       F(1)=0.d0
       F(2)=-PAR(13)
C
       DO I=1,NDM
         F(1)=F(1)+(U(I)-UOLD(I))*UPOLD(I)
         F(2)=F(2)+U(NDM+I)*U(NDM+I)
       ENDDO
C
       IF(IJAC.EQ.0)RETURN
C
       NPAR=IAP(31)
       NN=NDIM+NPAR
       DO I=1,NINT
         DO J=1,NN
           DINT(I,J)=0.d0
         ENDDO
       ENDDO
C
       DO I=1,NDM
         DINT(1,I)=UPOLD(I)
         DINT(2,NDM+I)=2.d0*U(NDM+I)
       ENDDO
C
       DINT(2,NDIM+13)=-1.d0
C
      RETURN
      END SUBROUTINE ICPD
C
C     ---------- ------
      SUBROUTINE STPNPD(IAP,PAR,ICP,NTSR,NCOLRS,
     * RLDOT,UPS,UDOTPS,TM,NODIR)
C
      USE BVP
      USE IO
      USE MESH
C
C Generates starting data for the 2-parameter continuation of
C period-doubling bifurcations on a branch of periodic solutions.
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(INOUT) :: NTSR,NCOLRS
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),RLDOT(*),
     *     UPS(IAP(1),0:*),UDOTPS(IAP(1),0:*),TM(0:*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: UPSR(:,:),UDOTPSR(:,:),TMR(:)
      DOUBLE PRECISION RLDOTRS(4)
      INTEGER ICPRS(4),NDIM,NDM,NCOL,NTST,NDIMRD,ITPRS,J
C
       NDIM=IAP(1)
       NDM=IAP(23)
C
       ALLOCATE(UPSR(NDIM,0:NCOLRS*NTSR),UDOTPSR(NDIM,0:NCOLRS*NTSR),
     *      TMR(0:NTSR))
       CALL READBV(IAP,PAR,ICPRS,NTSR,NCOLRS,NDIMRD,RLDOTRS,UPSR,
     *      UDOTPSR,TMR,ITPRS,NDIM)
       RLDOT(1)=RLDOTRS(1)
       RLDOT(2)=RLDOTRS(2)
C
C Complement starting data 
         PAR(13)=0.d0
         RLDOT(3)=0.d0
         DO J=0,NTSR*NCOLRS
            UPSR(NDM+1:NDIM,J)=0.d0
            UDOTPSR(NDM+1:NDIM,J)=0.d0
         ENDDO
C
       NODIR=0
       NTST=IAP(5)
       NCOL=IAP(6)
       CALL ADAPT2(NTSR,NCOLRS,NDIM,NTST,NCOL,NDIM,
     *      TMR,UPSR,UDOTPSR,TM,UPS,UDOTPS,.FALSE.)
       DEALLOCATE(TMR,UPSR,UDOTPSR)
C
      RETURN
      END SUBROUTINE STPNPD
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C       Subroutines for the Continuation of Torus Bifurcations
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNTR(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for the 2-parameter continuation of
C torus bifurcations.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE ::DFU(:),UU1(:),UU2(:),FF1(:),FF2(:)
      INTEGER NDM,NFPR,I,J
      DOUBLE PRECISION EP,UMX,P
C
       NDM=IAP(23)
       NFPR=IAP(29)
C
C Generate the function.
C
       ALLOCATE(DFU(NDM*NDM))
       CALL FFTR(IAP,U,UOLD,ICP,PAR,F,NDM,DFU)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU)
         RETURN
       ENDIF
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NDIM),FF2(NDIM))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U(J)
           UU2(J)=U(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FFTR(IAP,UU1,UOLD,ICP,PAR,FF1,NDM,DFU)
         CALL FFTR(IAP,UU2,UOLD,ICP,PAR,FF2,NDM,DFU)
         DO J=1,NDIM
           DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(UU1,UU2,FF2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF1,DFU)
         RETURN
       ENDIF
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FFTR(IAP,U,UOLD,ICP,PAR,FF1,NDM,DFU)
         DO J=1,NDIM
           DFDP(J,ICP(I))=(FF1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
      DEALLOCATE(FF1,DFU)
      RETURN
      END SUBROUTINE FNTR
C
C     ---------- ----
      SUBROUTINE FFTR(IAP,U,UOLD,ICP,PAR,F,NDM,DFDU)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDM
      DOUBLE PRECISION, INTENT(IN) :: UOLD(*)
      DOUBLE PRECISION, INTENT(INOUT) :: U(*),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDM*3)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,*)
C Local
      INTEGER NDM2,I,J
      DOUBLE PRECISION DUMDP(1),PERIOD
C
       PERIOD=PAR(11)
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,1,F,DFDU,DUMDP)
C
       NDM2=2*NDM
       DO I=1,NDM
         F(NDM+I)=0.d0
         F(NDM2+I)=0.d0
         DO J=1,NDM
           F(NDM+I)=F(NDM+I)+DFDU(I,J)*U(NDM+J)
           F(NDM2+I)=F(NDM2+I)+DFDU(I,J)*U(NDM2+J)
         ENDDO
         F(NDM+I)=PERIOD*F(NDM+I)
         F(NDM2+I)=PERIOD*F(NDM2+I)
         F(I)=PERIOD*F(I)
       ENDDO
C
      RETURN
      END SUBROUTINE FFTR
C
C     ---------- ----
      SUBROUTINE BCTR(IAP,NDIM,PAR,ICP,NBC,U0,U1,F,IJAC,DBC)
C
      USE BVP, ONLY: IRTN, NRTN
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)

      INTEGER NDM,NDM2,NN,NPAR,I,J
      DOUBLE PRECISION THETA,SS,CS
C
       NDM=IAP(23)
C
       NDM2=2*NDM
       THETA=PAR(12)
C
       SS=SIN(THETA)
       CS=COS(THETA)
C
       DO I=1,NDM
         F(I)=U0(I)-U1(I)
         F(NDM+I)= U1(NDM+I) -CS*U0(NDM+I) +SS*U0(NDM2+I)
         F(NDM2+I)=U1(NDM2+I)-CS*U0(NDM2+I)-SS*U0(NDM+I)
       ENDDO
C
C Rotations
       IF(IRTN.NE.0)THEN
         DO I=1,NDM
           IF(NRTN(I).NE.0)F(I)=F(I) + PAR(19)*NRTN(I)
         ENDDO
       ENDIF
C
       IF(IJAC.EQ.0)RETURN
C
       NPAR=IAP(31)
       NN=2*NDIM+NPAR
       DO I=1,NBC
         DO J=1,NN
           DBC(I,J)=0.d0
         ENDDO
       ENDDO
C
       DO I=1,NDM
         DBC(I,I)=1
         DBC(I,NDIM+I)=-1
         DBC(NDM+I,NDM+I)=-CS
         DBC(NDM+I,NDM2+I)=SS
         DBC(NDM+I,NDIM+NDM+I)=1
         DBC(NDM+I,2*NDIM+12)=CS*U0(NDM2+I)+SS*U0(NDM+I)
         DBC(NDM2+I,NDM+I)=-SS
         DBC(NDM2+I,NDM2+I)=-CS
         DBC(NDM2+I,NDIM+NDM2+I)=1
         DBC(NDM2+I,2*NDIM+12)=SS*U0(NDM2+I)-CS*U0(NDM+I)
       ENDDO
C
      RETURN
      END SUBROUTINE BCTR
C
C     ---------- ----
      SUBROUTINE ICTR(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     * F,IJAC,DINT)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)

      INTEGER NDM,NDM2,NN,NPAR,I,J
C
       NDM=IAP(23)
       NDM2=2*NDM
C
       F(1)=0.d0
       F(2)=0.d0
       F(3)=-PAR(13)
C
       DO I=1,NDM
         F(1)=F(1)+(U(I)-UOLD(I))*UPOLD(I)
         F(2)=F(2)+U(NDM+I)*UOLD(NDM2+I)-U(NDM2+I)*UOLD(NDM+I)
         F(3)=F(3)+U(NDM+I)*U(NDM+I) +U(NDM2+I)*U(NDM2+I)
       ENDDO
C
       IF(IJAC.EQ.0)RETURN
C
       NPAR=IAP(31)
       NN=NDIM+NPAR
       DO I=1,NINT
         DO J=1,NN
           DINT(I,J)=0.d0
         ENDDO
       ENDDO
C
      DO I=1,NDM
        DINT(1,I)=UPOLD(I)
        DINT(2,NDM+I)=UOLD(NDM2+I)
        DINT(2,NDM2+I)=-UOLD(NDM+I)
        DINT(3,NDM+I)=2*U(NDM+I)
        DINT(3,NDM2+I)=2*U(NDM2+I)
      ENDDO
C
      DINT(3,NDIM+13)=-1
C
      RETURN
      END SUBROUTINE ICTR
C
C     ---------- ------
      SUBROUTINE STPNTR(IAP,PAR,ICP,NTSR,NCOLRS,
     * RLDOT,UPS,UDOTPS,TM,NODIR)
C
      USE BVP
      USE IO
      USE MESH
C
C Generates starting data for the 2-parameter continuation of torus
C bifurcations.
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(INOUT) :: NTSR,NCOLRS
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),RLDOT(*),
     *     UPS(IAP(1),0:*),UDOTPS(IAP(1),0:*),TM(0:*)
C Local
      DOUBLE PRECISION RLDOTRS(4),T,DT
      INTEGER ICPRS(4),NDIM,NDM,NCOL,NTST,NDIMRD,ITPRS,I,J,K
      DOUBLE PRECISION, ALLOCATABLE :: UPSR(:,:),UDOTPSR(:,:),TMR(:)
C
       NDIM=IAP(1)
       NDM=IAP(23)
C
       ALLOCATE(UPSR(NDIM,0:NCOLRS*NTSR),UDOTPSR(NDIM,0:NCOLRS*NTSR),
     *      TMR(0:NTSR))
       CALL READBV(IAP,PAR,ICPRS,NTSR,NCOLRS,NDIMRD,RLDOTRS,UPSR,
     *      UDOTPSR,TMR,ITPRS,NDIM)
C
       RLDOT(1)=RLDOTRS(1)
       RLDOT(2)=RLDOTRS(2)
       RLDOT(3)=0.d0
       RLDOT(4)=0.d0
C
       T=0.d0
       DT=0.d0
       DO I=0,NTSR*NCOLRS
          IF(MOD(I,NCOLRS)==0)THEN
             J=I/NCOLRS
             T=TMR(J)
             IF(J<NTSR)DT=(TMR(J+1)-T)/NCOLRS
          ENDIF
          DO K=NDM+1,2*NDM
             UPSR(K,I)        = 0.0001d0*SIN(T)
             UPSR(K+NDM,I)    = 0.0001d0*COS(T)
             UDOTPSR(K,I)     = 0.d0
             UDOTPSR(K+NDM,I) = 0.d0
          ENDDO
          T=T+DT
       ENDDO
C
       PAR(13)=0.d0
C
       NODIR=0
       NTST=IAP(5)
       NCOL=IAP(6)
       CALL ADAPT2(NTSR,NCOLRS,NDIM,NTST,NCOL,NDIM,
     *      TMR,UPSR,UDOTPSR,TM,UPS,UDOTPS,.FALSE.)
       DEALLOCATE(TMR,UPSR,UDOTPSR)
C
      RETURN
      END SUBROUTINE STPNTR
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C        Subroutines for Optimization of Periodic Solutions
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNPO(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for periodic optimization problems.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:),FF1(:),FF2(:),UPOLD(:)
      INTEGER NDM,NFPR,I,J
      DOUBLE PRECISION UMX,EP,P,PERIOD,UU,DUMDU(1),DUMDP(1)
C
       NDM=IAP(23)
       NFPR=IAP(29)
C
C Generate F(UOLD)
C
       ALLOCATE(UPOLD(NDIM))
       CALL FUNC(NDM,UOLD,ICP,PAR,0,UPOLD,DUMDU,DUMDP)
       PERIOD=PAR(11)
       DO I=1,NDM
         UPOLD(I)=PERIOD*UPOLD(I)
       ENDDO
C
C Generate the function.
C
      CALL FFPO(IAP,U,UOLD,UPOLD,ICP,PAR,F,NDM,DFDU)
C
      IF(IJAC.EQ.0)THEN
        DEALLOCATE(UPOLD)
        RETURN
      ENDIF
C
      ALLOCATE(DFU(NDIM*NDIM),FF1(NDIM),FF2(NDIM))
C
C Generate the Jacobian.
C
      UMX=0.d0
      DO I=1,NDIM
        IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
      ENDDO
C
      EP=HMACH*(1+UMX)
C
      DO I=1,NDIM
        UU=U(I)
        U(I)=UU-EP
        CALL FFPO(IAP,U,UOLD,UPOLD,ICP,PAR,FF1,NDM,DFU)
        U(I)=UU+EP
        CALL FFPO(IAP,U,UOLD,UPOLD,ICP,PAR,FF2,NDM,DFU)
        U(I)=UU
        DO J=1,NDIM
          DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
        ENDDO
      ENDDO
C
      DEALLOCATE(FF2)
      IF(IJAC.EQ.1)THEN
        DEALLOCATE(UPOLD,DFU,FF1)
        RETURN
      ENDIF
C
      DO I=1,NFPR
        P=PAR(ICP(I))
        PAR(ICP(I))=P+EP
        CALL FFPO(IAP,U,UOLD,UPOLD,ICP,PAR,FF1,NDM,DFU)
        DO J=1,NDIM
          DFDP(J,ICP(I))=(FF1(J)-F(J))/EP
        ENDDO
        PAR(ICP(I))=P
      ENDDO
C
      DEALLOCATE(UPOLD,DFU,FF1)
      RETURN
      END SUBROUTINE FNPO
C
C     ---------- ----
      SUBROUTINE FFPO(IAP,U,UOLD,UPOLD,ICP,PAR,F,NDM,DFDU)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDM
      DOUBLE PRECISION, INTENT(IN) :: UOLD(*),UPOLD(*)
      DOUBLE PRECISION, INTENT(INOUT) :: U(*),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDM*2)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,*)
C Local
      INTEGER JAC,NFPR,I,J
      DOUBLE PRECISION DUMDP(1),PERIOD,RKAPPA,GAMMA,DFU,FOP

       JAC=IAP(22)
       NFPR=IAP(29)
       PERIOD=PAR(11)
       RKAPPA=PAR(13)
       GAMMA =PAR(14)
C
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,1,F(NDM+1),DFDU,DUMDP)
       CALL FOPI(JAC,NFPR,NDM,U,ICP,PAR,1,FOP,F,DUMDP)
C
       DO I=1,NDM
         DFU=F(I)
         F(I)=F(NDM+I)
         F(NDM+I)=0.d0
         DO J=1,NDM
           F(NDM+I)=F(NDM+I)-DFDU(J,I)*U(NDM+J)
         ENDDO
         F(I)=PERIOD*F(I)
         F(NDM+I)=PERIOD*F(NDM+I)+ RKAPPA*UPOLD(I) + GAMMA*DFU
       ENDDO
C
      RETURN
      END SUBROUTINE FFPO
C
C     ---------- ----
      SUBROUTINE BCPO(IAP,NDIM,PAR,ICP,NBC,U0,U1,F,IJAC,DBC)
C
      USE BVP, ONLY: IRTN, NRTN
C
C Generates the boundary conditions for periodic optimization problems.
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)

      INTEGER NFPR,I,J
C
      NFPR=IAP(29)
C
      DO I=1,NBC
        F(I)=U0(I)-U1(I)
      ENDDO
C
C Rotations
       IF(IRTN.NE.0)THEN
         DO I=1,NBC/2
           IF(NRTN(I).NE.0)F(I)=F(I) + PAR(19)*NRTN(I)
         ENDDO
       ENDIF
C
       IF(IJAC.EQ.0)RETURN
C
      DO I=1,NBC
        DO J=1,2*NDIM
         DBC(I,J)=0.d0
        ENDDO
        DBC(I,I)=1.D0
        DBC(I,NDIM+I)=-1.d0
        DO J=1,NFPR
          DBC(I,2*NDIM+ICP(J))=0.d0
        ENDDO
      ENDDO
 
      RETURN
      END SUBROUTINE BCPO
C
C     ---------- ----
      SUBROUTINE ICPO(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     * F,IJAC,DINT)
C
C Generates integral conditions for periodic optimization problems.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)

C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:),DFP(:),F1(:),F2(:)
      INTEGER NPAR,NDM,NFPR,I,J
      DOUBLE PRECISION UMX,EP,P,UU

      NPAR=IAP(31)
      ALLOCATE(DFU(NDIM*NDIM),DFP(NDIM*NPAR))
C
       NDM=IAP(23)
       NFPR=IAP(29)
C
C Generate the function.
C
       CALL FIPO(IAP,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,F,NDM,DFU,DFP)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU,DFP)
         RETURN
       ENDIF
C
C Generate the Jacobian.
C
       ALLOCATE(F1(NINT),F2(NINT))
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         UU=U(I)
         U(I)=UU-EP
         CALL FIPO(IAP,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,F1,NDM,DFU,DFP)
         U(I)=UU+EP
         CALL FIPO(IAP,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,F2,NDM,DFU,DFP)
         U(I)=UU
         DO J=1,NINT
           DINT(J,I)=(F2(J)-F1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FIPO(IAP,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,F1,NDM,DFU,DFP)
         DO J=1,NINT
           DINT(J,NDIM+ICP(I))=(F1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
       DEALLOCATE(F1,F2,DFU,DFP)
      RETURN
      END SUBROUTINE ICPO
C
C     ---------- ----
      SUBROUTINE FIPO(IAP,PAR,ICP,NINT,
     * U,UOLD,UDOT,UPOLD,FI,NDM,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDM,NINT
      DOUBLE PRECISION, INTENT(IN)::UOLD(2*NDM),UDOT(2*NDM),UPOLD(2*NDM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(2*NDM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: FI(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM),DFDP(NDM,*)
C
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:),DFP(:),F(:)
      INTEGER JAC,NFPR,NPAR,INDX,I,J,L
      DOUBLE PRECISION FOP
C
       JAC=IAP(22)
       NFPR=IAP(29)
       NPAR=IAP(31)
C
       FI(1)=0.d0
       DO I=1,NDM
         FI(1)=FI(1)+(U(I)-UOLD(I))*UPOLD(I)
       ENDDO
C
       ALLOCATE(DFU(NDM),F(NDM),DFP(NPAR))
       DO I=1,NPAR
        DFP(I)=0.d0
       ENDDO
       CALL FOPI(JAC,NFPR,NDM,U,ICP,PAR,2,FOP,DFU,DFP)
       FI(2)=PAR(10)-FOP
C
       FI(3)=PAR(13)**2+PAR(14)**2-PAR(12)
       DO I=1,NDM
         FI(3)=FI(3)+U(NDM+I)**2
       ENDDO
C
       DO I=1,NDM
         DO J=1,NPAR
           DFDP(I,J)=0.d0
         ENDDO
       ENDDO
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,2,F,DFDU,DFDP)
C
       DO L=4,NINT
         INDX=ICP(NFPR+L-3)
         IF(INDX.EQ.11)THEN
           FI(L)=-PAR(14)*DFP(INDX) - PAR(20+INDX)
           DO I=1,NDM
             FI(L)=FI(L)+F(I)*U(NDM+I)
           ENDDO
         ELSE
           FI(L)=-PAR(14)*DFP(INDX) - PAR(20+INDX)
           DO I=1,NDM
             FI(L)=FI(L)+PAR(11)*DFDP(I,INDX)*U(NDM+I)
           ENDDO
         ENDIF
       ENDDO
C
      DEALLOCATE(DFU,DFP,F)
      RETURN
      END SUBROUTINE FIPO
C
C     ---------- ------
      SUBROUTINE STPNPO(IAP,PAR,ICP,NTSR,NCOLRS,
     * RLDOT,UPS,UDOTPS,TM,NODIR)
C
      USE BVP
      USE IO
      USE MESH
C
C Generates starting data for optimization of periodic solutions.
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(INOUT) :: NTSR,NCOLRS
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),RLDOT(*),
     *     UPS(IAP(1),0:*),UDOTPS(IAP(1),0:*),TM(0:*)
C Local
      INTEGER, ALLOCATABLE :: ICPRS(:)
      DOUBLE PRECISION, ALLOCATABLE :: RLDOTRS(:)
      DOUBLE PRECISION, ALLOCATABLE :: U(:),TEMP(:),DTMTEMP(:)
      DOUBLE PRECISION, ALLOCATABLE :: UPSR(:,:),UDOTPSR(:,:),TMR(:)
      INTEGER NDIM,NTST,NCOL,NDM,NFPR,NPAR,NDIMRD,ITPRS,I,J,K
      DOUBLE PRECISION FS,DUMU(1),DUMP(1)
C
       NDIM=IAP(1)
       NTST=IAP(5)
       NCOL=IAP(6)
       NDM=IAP(23)
       NFPR=IAP(29)
       NPAR=IAP(31)
C
       ALLOCATE(ICPRS(NFPR),RLDOTRS(NFPR))
       ALLOCATE(UPSR(NDIM,0:NCOLRS*NTSR),UDOTPSR(NDIM,0:NCOLRS*NTSR),
     *      TMR(0:NTSR))
       CALL READBV(IAP,PAR,ICPRS,NTSR,NCOLRS,NDIMRD,RLDOTRS,UPSR,
     *      UDOTPSR,TMR,ITPRS,NDIM)
       DEALLOCATE(ICPRS,RLDOTRS)
       ALLOCATE(U(NDM),TEMP(0:NTSR*NCOLRS),DTMTEMP(NTSR))
       DO J=1,NTSR
         DTMTEMP(J)=TMR(J)-TMR(J-1)
       ENDDO
C
C Compute the starting value of the objective functional
       DO J=0,NTSR*NCOLRS
          DO K=1,NDM
             U(K)=UPSR(K,J)
          ENDDO
          CALL FOPT(NDM,U,ICP,PAR,0,FS,DUMU,DUMP)
          TEMP(J)=FS
       ENDDO
       PAR(10)=RINTG(NTSR,NCOLRS,1,1,TEMP,DTMTEMP)
       DEALLOCATE(U,TEMP,DTMTEMP)
C
C Complement starting data
C
       DO I=12,NPAR
         PAR(I)=0.d0
       ENDDO
C
       DO J=0,NTSR*NCOLRS
          DO K=NDM+1,NDIM
             UPSR(K,J)=0.d0
          ENDDO
       ENDDO
C
       NODIR=1
       RLDOT(:NFPR)=0d0
       CALL ADAPT2(NTSR,NCOLRS,NDIM,NTST,NCOL,NDIM,
     *      TMR,UPSR,UDOTPSR,TM,UPS,UDOTPS,.FALSE.)
       DEALLOCATE(TMR,UPSR,UDOTPSR)
C
      RETURN
      END SUBROUTINE STPNPO
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C        Subroutines for the Continuation of Folds for BVP.
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FNBL(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for the 2-parameter continuation
C of folds (BVP).
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:,:),DFP(:,:),FF1(:),FF2(:)
      INTEGER NDM,NFPR,NFPX,NPAR,I,J
      DOUBLE PRECISION UU,UMX,EP,P
C
       NDM=IAP(23)
       NFPR=IAP(29)
       NPAR=IAP(31)
C
C Generate the function.
C
      ALLOCATE(DFU(NDM,NDM),DFP(NDM,NPAR))
      CALL FFBL(IAP,U,UOLD,ICP,PAR,F,NDM,DFU,DFP)
C
      IF(IJAC.EQ.0)THEN
        DEALLOCATE(DFU,DFP)
        RETURN
      ENDIF
C
C Generate the Jacobian.
C
      DFDU(1:NDM,1:NDM)=DFU(:,:)
      DFDU(1:NDM,NDM+1:NDIM)=0d0
      DFDU(NDM+1:NDIM,NDM+1:NDIM)=DFU(:,:)
      IF(IJAC==2)THEN
         NFPX=NFPR/2-1
         DO I=1,NFPR-NFPX
            DFDP(1:NDM,ICP(I))=DFP(:,ICP(I))
         ENDDO
         DO I=1,NFPX
            DFDP(1:NDM,ICP(NFPR-NFPX+I))=0d0
            DFDP(NDM+1:NDIM,ICP(NFPR-NFPX+I))=DFP(:,ICP(I+1))
         ENDDO
      ENDIF

      UMX=0.d0
      DO I=1,NDIM
        IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
      ENDDO
C
      EP=HMACH*(1+UMX)
C
      ALLOCATE(FF1(NDIM),FF2(NDIM))
      DO I=1,NDM
        UU=U(I)
        U(I)=UU-EP
        CALL FFBL(IAP,U,UOLD,ICP,PAR,FF1,NDM,DFU,DFP)
        U(I)=UU+EP
        CALL FFBL(IAP,U,UOLD,ICP,PAR,FF2,NDM,DFU,DFP)
        U(I)=UU
        DO J=NDM+1,NDIM
          DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
        ENDDO
      ENDDO
C
      DEALLOCATE(FF2)
      IF (IJAC.EQ.1)THEN
        DEALLOCATE(DFU,DFP,FF1)
        RETURN
      ENDIF
C
      NFPX=NFPR/2-1
      DO I=1,NFPR-NFPX
        P=PAR(ICP(I))
        PAR(ICP(I))=P+EP
        CALL FFBL(IAP,U,UOLD,ICP,PAR,FF1,NDM,DFU,DFP)
        DO J=1,NDIM
          DFDP(J,ICP(I))=(FF1(J)-F(J))/EP
        ENDDO
        PAR(ICP(I))=P
      ENDDO
C
      DEALLOCATE(DFU,DFP,FF1)
      RETURN
      END SUBROUTINE FNBL
C
C     ---------- ----
      SUBROUTINE FFBL(IAP,U,UOLD,ICP,PAR,F,NDM,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDM
      DOUBLE PRECISION, INTENT(IN) :: UOLD(2*NDM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(2*NDM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(2*NDM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM),DFDP(NDM,*)

      INTEGER NFPR,NFPX,I,J
C
       NFPR=IAP(29)
C
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,2,F,DFDU,DFDP)
C
       NFPX=NFPR/2-1
       DO I=1,NDM
         F(NDM+I)=0.d0
         DO J=1,NDM
           F(NDM+I)=F(NDM+I)+DFDU(I,J)*U(NDM+J)
         ENDDO
         DO J=1,NFPX
            F(NDM+I)=F(NDM+I)
     *           + DFDP(I,ICP(1+J))*PAR(ICP(NFPR-NFPX+J))
         ENDDO
       ENDDO
C
      RETURN
      END SUBROUTINE FFBL
C
C     ---------- ----
      SUBROUTINE BCBL(IAP,NDIM,PAR,ICP,NBC,U0,U1,F,IJAC,DBC)
C
C Generates the boundary conditions for the 2-parameter continuation
C of folds (BVP).
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: UU1(:),UU2(:),FF1(:),FF2(:),
     *     DFU(:,:)
      INTEGER NDM,NBC0,NFPR,NPAR,I,J
      DOUBLE PRECISION UMX,EP,P
C
       NDM=IAP(23)
       NBC0=NBC/2
       NFPR=IAP(29)
       NPAR=IAP(31)
       ALLOCATE(DFU(NBC0,2*NDM+NPAR))
C
C Generate the function.
C
       CALL FBBL(IAP,NDIM,PAR,ICP,NBC0,U0,U1,F,DFU)
C
       IF(IJAC.EQ.0)THEN
          DEALLOCATE(DFU)
          RETURN
       ENDIF
C
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NBC),FF2(NBC))
C
C Derivatives with respect to U0.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U0(I)).GT.UMX)UMX=DABS(U0(I))
       ENDDO
       EP=HMACH*(1+UMX)
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U0(J)
           UU2(J)=U0(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FBBL(IAP,NDIM,PAR,ICP,NBC0,UU1,U1,FF1,DFU)
         CALL FBBL(IAP,NDIM,PAR,ICP,NBC0,UU2,U1,FF2,DFU)
         DO J=1,NBC
           DBC(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
C Derivatives with respect to U1.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U1(I)).GT.UMX)UMX=DABS(U1(I))
       ENDDO
       EP=HMACH*(1+UMX)
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U1(J)
           UU2(J)=U1(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FBBL(IAP,NDIM,PAR,ICP,NBC0,U0,UU1,FF1,DFU)
         CALL FBBL(IAP,NDIM,PAR,ICP,NBC0,U0,UU2,FF2,DFU)
         DO J=1,NBC
           DBC(J,NDIM+I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(FF1,UU1,UU2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF2,DFU)
         RETURN
       ENDIF
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FBBL(IAP,NDIM,PAR,ICP,NBC0,U0,U1,FF2,DFU)
         DO J=1,NBC
           DBC(J,2*NDIM+ICP(I))=(FF2(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
      DEALLOCATE(DFU,FF2)
      RETURN
      END SUBROUTINE BCBL
C
C     ---------- ----
      SUBROUTINE FBBL(IAP,NDIM,PAR,ICP,NBC0,U0,U1,F,DBC)
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC0
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NBC0+IAP(23)+IAP(29)/2-1)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC0,*)
C
      INTEGER NDM,NFPR,NFPX,I,J
C
       NDM=IAP(23)
       NFPR=IAP(29)
C
       NFPX=NFPR/2-1
       CALL BCNI(IAP,NDM,PAR,ICP,NBC0,U0,U1,F,2,DBC)
       DO I=1,NBC0
         F(NBC0+I)=0.d0
         DO J=1,NDM
           F(NBC0+I)=F(NBC0+I)+DBC(I,J)*U0(NDM+J)
           F(NBC0+I)=F(NBC0+I)+DBC(I,NDM+J)*U1(NDM+J)
         ENDDO
         DO J=1,NFPX
            F(NBC0+I)=F(NBC0+I)
     *       + DBC(I,NDIM+ICP(1+J))*PAR(ICP(NFPR-NFPX+J))
         ENDDO
       ENDDO
C
      RETURN
      END SUBROUTINE FBBL
C
C     ---------- ----
      SUBROUTINE ICBL(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     * F,IJAC,DINT)
C
C Generates integral conditions for the 2-parameter continuation of
C folds (BVP).
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: UU1(:),UU2(:),FF1(:),FF2(:),
     *     DFU(:,:)
      INTEGER NDM,NNT0,NFPR,NPAR,I,J
      DOUBLE PRECISION UMX,EP,P
C
       NDM=IAP(23)
       NNT0=(NINT-1)/2
       NFPR=IAP(29)
       NPAR=IAP(31)
       ALLOCATE(DFU(NNT0,NDM+NPAR))
C
C Generate the function.
C
       CALL FIBL(IAP,PAR,ICP,NINT,NNT0,U,UOLD,UDOT,UPOLD,F,DFU)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU)
         RETURN
       ENDIF
C
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NINT),FF2(NINT))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U(J)
           UU2(J)=U(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FIBL(IAP,PAR,ICP,NINT,NNT0,UU1,UOLD,UDOT,
     *    UPOLD,FF1,DFU)
         CALL FIBL(IAP,PAR,ICP,NINT,NNT0,UU2,UOLD,UDOT,
     *    UPOLD,FF2,DFU)
         DO J=1,NINT
           DINT(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(UU1,UU2,FF2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF1,DFU)
         RETURN
       ENDIF
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FIBL(IAP,PAR,ICP,NINT,NNT0,U,UOLD,UDOT,
     *    UPOLD,FF1,DFU)
         DO J=1,NINT
           DINT(J,NDIM+ICP(I))=(FF1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
      DEALLOCATE(FF1,DFU)
      RETURN
      END SUBROUTINE ICBL
C
C     ---------- ----
      SUBROUTINE FIBL(IAP,PAR,ICP,NINT,NNT0,
     * U,UOLD,UDOT,UPOLD,F,DINT)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NINT,NNT0
      DOUBLE PRECISION, INTENT(IN) :: UOLD(*),UDOT(*),UPOLD(*)
      DOUBLE PRECISION, INTENT(INOUT) :: U(*),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NNT0,*)
      INTEGER NDM,NFPR,NFPX,I,J
C
       NDM=IAP(23)
       NFPR=IAP(29)
C
       NFPX=0
       IF(NINT.GT.1) THEN
         NFPX=NFPR/2-1
         CALL ICNI(IAP,NDM,PAR,ICP,NNT0,U,UOLD,UDOT,UPOLD,F,2,DINT)
         DO I=1,NNT0
           F(NNT0+I)=0.d0
           DO J=1,NDM
             F(NNT0+I)=F(NNT0+I)+DINT(I,J)*U(NDM+J)
           ENDDO
           IF(NFPX.NE.0) THEN
             DO J=1,NFPX
               F(NNT0+I)=F(NNT0+I)
     *         + DINT(I,NDM+ICP(1+J))*PAR(ICP(NFPR-NFPX+J))
             ENDDO
           ENDIF
         ENDDO
       ENDIF
C
C Note that PAR(11+NFPR/2) is used to keep the norm of the null vector
       F(NINT)=-PAR(11+NFPR/2)
       DO I=1,NDM
         F(NINT)=F(NINT)+U(NDM+I)*U(NDM+I)
       ENDDO
       IF(NFPX.NE.0) THEN
         DO I=1,NFPX
           F(NINT)=F(NINT)+PAR(ICP(NFPR-NFPX+I))**2
         ENDDO
       ENDIF
C
      RETURN
      END SUBROUTINE FIBL
C
C     ---------- ------
      SUBROUTINE STPNBL(IAP,PAR,ICP,NTSR,NCOLRS,
     * RLDOT,UPS,UDOTPS,TM,NODIR)
C
      USE BVP
      USE IO
      USE MESH
C
C
C Generates starting data for the 2-parameter continuation of folds.
C (BVP).
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(INOUT) :: NTSR,NCOLRS
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),RLDOT(*),
     *     UPS(IAP(1),0:*),UDOTPS(IAP(1),0:*),TM(0:*)
C Local
      INTEGER, ALLOCATABLE :: ICPRS(:)
      DOUBLE PRECISION, ALLOCATABLE :: RLDOTRS(:)
      DOUBLE PRECISION, ALLOCATABLE :: UPSR(:,:),UDOTPSR(:,:),TMR(:)
      INTEGER NDIM,NCOL,NDM,NFPR,NFPR0,NFPX,NTST,NDIMRD,ITPRS,I,J
C
       NDIM=IAP(1)
       NDM=IAP(23)
       NFPR=IAP(29)
C
       ALLOCATE(ICPRS(NFPR),RLDOTRS(NFPR))
       ALLOCATE(UPSR(NDIM,0:NCOLRS*NTSR),UDOTPSR(NDIM,0:NCOLRS*NTSR),
     *      TMR(0:NTSR))
       CALL READBV(IAP,PAR,ICPRS,NTSR,NCOLRS,NDIMRD,RLDOTRS,UPSR,
     *      UDOTPSR,TMR,ITPRS,NDIM)
C
       NFPR0=NFPR/2
       DO I=1,NFPR0
         RLDOT(I)=RLDOTRS(I)
       ENDDO
       DEALLOCATE(ICPRS,RLDOTRS)
C
       DO J=0,NTSR*NCOLRS
          UPSR(NDM+1:NDIM,J)=0.d0
          UDOTPSR(NDM+1:NDIM,J)=0.d0
       ENDDO
C
       NFPX=NFPR/2-1
       IF(NFPX.GT.0) THEN
         DO I=1,NFPX
           PAR(ICP(NFPR0+1+I))=0.d0
           RLDOT(NFPR0+I+1)=0.d0
         ENDDO
       ENDIF
C Initialize the norm of the null vector
       PAR(11+NFPR/2)=0.
       RLDOT(NFPR0+1)=0.d0
C
       NODIR=0
       NTST=IAP(5)
       NCOL=IAP(6)
       CALL ADAPT2(NTSR,NCOLRS,NDIM,NTST,NCOL,NDIM,
     *      TMR,UPSR,UDOTPSR,TM,UPS,UDOTPS,.FALSE.)
       DEALLOCATE(TMR,UPSR,UDOTPSR)
C
      RETURN
      END SUBROUTINE STPNBL
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C   Subroutines for BP cont (BVPs) (by F. Dercole)
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- -----
      SUBROUTINE FNBBP(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Generates the equations for the 2-parameter continuation
C of BP (BVP).
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)

C Local
      DOUBLE PRECISION, ALLOCATABLE :: DFU(:),DFP(:),UU1(:),UU2(:),
     *     FF1(:),FF2(:)
      INTEGER NDM,NFPR,NPAR,I,J
      DOUBLE PRECISION UMX,EP,P
C
       NDM=IAP(23)
       NFPR=IAP(29)
       NPAR=IAP(31)
C
C Generate the function.
C
       ALLOCATE(DFU(NDM*NDM),DFP(NDM*NPAR))
       CALL FFBBP(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFU,DFP)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU,DFP)
         RETURN
       ENDIF
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NDIM),FF2(NDIM))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U(J)
           UU2(J)=U(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FFBBP(IAP,NDIM,UU1,UOLD,ICP,PAR,FF1,NDM,DFU,DFP)
         CALL FFBBP(IAP,NDIM,UU2,UOLD,ICP,PAR,FF2,NDM,DFU,DFP)
         DO J=1,NDIM
           DFDU(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(UU1,UU2,FF2)
       IF (IJAC.EQ.1)THEN
         DEALLOCATE(DFU,DFP,FF1)
         RETURN
       ENDIF
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FFBBP(IAP,NDIM,U,UOLD,ICP,PAR,FF1,NDM,DFU,DFP)
         DO J=1,NDIM
           DFDP(J,ICP(I))=(FF1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
       DEALLOCATE(DFU,DFP,FF1)
C
      RETURN
      END SUBROUTINE FNBBP
C
C     ---------- -----
      SUBROUTINE FFBBP(IAP,NDIM,U,UOLD,ICP,PAR,F,NDM,DFDU,DFDP)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NDM
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDM,NDM),DFDP(NDM,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: FI(:),DINT(:,:)
      DOUBLE PRECISION DUM(1),UPOLD(NDM)
      INTEGER ISW,NBC,NINT,NBC0,NNT0,NFPX,I,J
C
       ISW=IAP(10)
       NBC=IAP(12)
       NINT=IAP(13)
C
       IF(ISW.LT.0) THEN
C        ** start
         NBC0=(4*NBC-NINT-5*NDM+2)/15
         NNT0=(-NBC+4*NINT+5*NDM-23)/15
       ELSE IF(ISW.EQ.2) THEN
C        ** Non-generic case
         NBC0=(2*NBC-NINT-3*NDM)/3
         NNT0=(-NBC+2*NINT+3*NDM-3)/3
       ELSE
C        ** generic case
         NBC0=(2*NBC-NINT-3*NDM)/3
         NNT0=(-NBC+2*NINT+3*NDM-3)/3
       ENDIF
       NFPX=NBC0+NNT0-NDM+1
C
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,2,F,DFDU,DFDP)
       IF(NNT0.GT.0) THEN
         ALLOCATE(FI(NNT0),DINT(NNT0,NDM))
         CALL FUNC(NDM,UOLD,ICP,PAR,0,UPOLD,DUM,DUM)
         CALL ICNI(IAP,NDM,PAR,ICP,NNT0,U,UOLD,DUM,UPOLD,FI,1,DINT)
       ENDIF
C
       IF((ISW.EQ.2).OR.(ISW.LT.0)) THEN
C        ** Non-generic and/or start
         DO I=1,NDM
           F(I)=F(I)-PAR(11+3*NFPX+NDM+1)*U(NDIM-NDM+I)
         ENDDO
       ENDIF
C
       IF(ISW.GT.0) THEN
C        ** restart 1 or 2
         DO I=1,NDM
           F(NDM+I)=0.d0
           DO J=1,NDM
             F(NDM+I)=F(NDM+I)-DFDU(J,I)*U(NDM+J)
           ENDDO
           DO J=1,NNT0
             F(NDM+I)=F(NDM+I)+DINT(J,I)*PAR(11+2*NFPX+NBC0+J)
           ENDDO
         ENDDO
       ELSE
C        ** start
         DO I=1,NDM
           F(NDM+I)=0.d0
           F(2*NDM+I)=0.d0
           F(3*NDM+I)=PAR(11+3*NFPX+NDM+2)*U(NDM+I)+
     *       PAR(11+3*NFPX+NDM+3)*U(2*NDM+I)
           DO J=1,NDM
             F(NDM+I)=F(NDM+I)+DFDU(I,J)*U(NDM+J)
             F(2*NDM+I)=F(2*NDM+I)+DFDU(I,J)*U(2*NDM+J)
             F(3*NDM+I)=F(3*NDM+I)-DFDU(J,I)*U(3*NDM+J)
           ENDDO
           DO J=1,NFPX
             F(NDM+I)=F(NDM+I)+DFDP(I,ICP(J))*PAR(11+J)
             F(2*NDM+I)=F(2*NDM+I)+DFDP(I,ICP(J))*PAR(11+NFPX+J)
           ENDDO
           DO J=1,NNT0
             F(3*NDM+I)=F(3*NDM+I)+DINT(J,I)*PAR(11+2*NFPX+NBC0+J)
           ENDDO
         ENDDO
       ENDIF
       IF(NNT0.GT.0) THEN
         DEALLOCATE(FI,DINT)
       ENDIF
C
      RETURN
      END SUBROUTINE FFBBP
C
C     ---------- -----
      SUBROUTINE BCBBP(IAP,NDIM,PAR,ICP,NBC,U0,U1,F,IJAC,DBC)
C
C Generates the boundary conditions for the 2-parameter continuation
C of BP (BVP).
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: UU1(:),UU2(:),FF1(:),FF2(:),
     *     DFU(:,:)
      INTEGER ISW,NINT,NDM,NFPR,NPAR,NBC0,I,J
      DOUBLE PRECISION UMX,EP,P
C
       ISW=IAP(10)
       NINT=IAP(13)
       NDM=IAP(23)
       NFPR=IAP(29)
       NPAR=IAP(31)
C
       IF(ISW.LT.0) THEN
C        ** start
         NBC0=(4*NBC-NINT-5*NDM+2)/15
       ELSE IF(ISW.EQ.2) THEN
C        ** Non-generic case
         NBC0=(2*NBC-NINT-3*NDM)/3
       ELSE
C        ** generic case
         NBC0=(2*NBC-NINT-3*NDM)/3
       ENDIF
C
C Generate the function.
C
       ALLOCATE(DFU(NBC0,2*NDM+NPAR))
       CALL FBBBP(IAP,NDIM,PAR,ICP,NBC,NBC0,U0,U1,F,DFU)
C
       IF(IJAC.EQ.0)THEN
          DEALLOCATE(DFU)
          RETURN
       ENDIF
C
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NBC),FF2(NBC))
C
C Derivatives with respect to U0.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U0(I)).GT.UMX)UMX=DABS(U0(I))
       ENDDO
       EP=HMACH*(1+UMX)
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U0(J)
           UU2(J)=U0(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FBBBP(IAP,NDIM,PAR,ICP,NBC,NBC0,UU1,U1,FF1,DFU)
         CALL FBBBP(IAP,NDIM,PAR,ICP,NBC,NBC0,UU2,U1,FF2,DFU)
         DO J=1,NBC
           DBC(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
C Derivatives with respect to U1.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U1(I)).GT.UMX)UMX=DABS(U1(I))
       ENDDO
       EP=HMACH*(1+UMX)
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U1(J)
           UU2(J)=U1(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FBBBP(IAP,NDIM,PAR,ICP,NBC,NBC0,U0,UU1,FF1,DFU)
         CALL FBBBP(IAP,NDIM,PAR,ICP,NBC,NBC0,U0,UU2,FF2,DFU)
         DO J=1,NBC
           DBC(J,NDIM+I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(UU1,UU2,FF2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF1,DFU)
         RETURN
       ENDIF
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FBBBP(IAP,NDIM,PAR,ICP,NBC,NBC0,U0,U1,FF1,DFU)
         DO J=1,NBC
           DBC(J,2*NDIM+ICP(I))=(FF1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
       DEALLOCATE(FF1,DFU)
C
      RETURN
      END SUBROUTINE BCBBP
C
C     ---------- -----
      SUBROUTINE FBBBP(IAP,NDIM,PAR,ICP,NBC,NBC0,U0,U1,FB,DBC)
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,NBC0
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: FB(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC0,*)

      INTEGER ISW,NINT,NDM,NNT0,NFPX,I,J
C
       ISW=IAP(10)
       NINT=IAP(13)
       NDM=IAP(23)
C
       IF(ISW.LT.0) THEN
C        ** start
         NNT0=(-NBC+4*NINT+5*NDM-23)/15
       ELSE IF(ISW.EQ.2) THEN
C        ** Non-generic case
         NNT0=(-NBC+2*NINT+3*NDM-3)/3
       ELSE
C        ** generic case
         NNT0=(-NBC+2*NINT+3*NDM-3)/3
       ENDIF
       NFPX=NBC0+NNT0-NDM+1
C
       CALL BCNI(IAP,NDM,PAR,ICP,NBC0,U0,U1,FB,2,DBC)
C
       IF((ISW.EQ.2).OR.(ISW.LT.0)) THEN
C        ** Non-generic and/or start
         DO I=1,NBC0
           FB(I)=FB(I)+PAR(11+3*NFPX+NDM+1)*PAR(11+2*NFPX+I)
         ENDDO
       ENDIF
C
       IF(ISW.GT.0) THEN
C        ** restart 1 or 2
         DO I=1,NDM
           FB(NBC0+I)=-U0(NDM+I)
           FB(NBC0+NDM+I)=U1(NDM+I)
           DO J=1,NBC0
             FB(NBC0+I)=FB(NBC0+I)+DBC(J,I)*PAR(11+2*NFPX+J)
             FB(NBC0+NDM+I)=FB(NBC0+NDM+I)+DBC(J,NDM+I)*PAR(11+2*NFPX+J)
           ENDDO
         ENDDO
         DO I=1,NFPX
           FB(NBC0+2*NDM+I)=PAR(11+3*NFPX+NDM+3+I)
           DO J=1,NBC0
             FB(NBC0+2*NDM+I)=FB(NBC0+2*NDM+I)+
     *         DBC(J,2*NDM+ICP(I))*PAR(11+2*NFPX+J)
           ENDDO
         ENDDO
       ELSE
C        ** start
         DO I=1,NBC0
           FB(NBC0+I)=0.d0
           FB(2*NBC0+I)=0.d0
           DO J=1,NDM
             FB(NBC0+I)=FB(NBC0+I)+DBC(I,J)*U0(NDM+J)
             FB(NBC0+I)=FB(NBC0+I)+DBC(I,NDM+J)*U1(NDM+J)
             FB(2*NBC0+I)=FB(2*NBC0+I)+DBC(I,J)*U0(2*NDM+J)
             FB(2*NBC0+I)=FB(2*NBC0+I)+DBC(I,NDM+J)*U1(2*NDM+J)
           ENDDO
           DO J=1,NFPX
             FB(NBC0+I)=FB(NBC0+I)+DBC(I,2*NDM+ICP(J))*PAR(11+J)
             FB(2*NBC0+I)=FB(2*NBC0+I)+
     *         DBC(I,2*NDM+ICP(J))*PAR(11+NFPX+J)
           ENDDO
         ENDDO
         DO I=1,NDM
           FB(3*NBC0+I)=-U0(3*NDM+I)
           FB(3*NBC0+NDM+I)=U1(3*NDM+I)
           DO J=1,NBC0
             FB(3*NBC0+I)=FB(3*NBC0+I)+DBC(J,I)*PAR(11+2*NFPX+J)
             FB(3*NBC0+NDM+I)=FB(3*NBC0+NDM+I)+
     *         DBC(J,NDM+I)*PAR(11+2*NFPX+J)
           ENDDO
         ENDDO
         DO I=1,NFPX
           FB(3*NBC0+2*NDM+I)=PAR(11+3*NFPX+NDM+3+I)
           DO J=1,NBC0
             FB(3*NBC0+2*NDM+I)=FB(3*NBC0+2*NDM+I)+
     *         DBC(J,2*NDM+ICP(I))*PAR(11+2*NFPX+J)
           ENDDO
         ENDDO
       ENDIF
C
      RETURN
      END SUBROUTINE FBBBP
C
C     ---------- -----
      SUBROUTINE ICBBP(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     * F,IJAC,DINT)
C
C Generates integral conditions for the 2-parameter continuation
C of BP (BVP).
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: UU1(:),UU2(:),FF1(:),FF2(:),
     *     DFU(:)
      INTEGER ISW,NBC,NDM,NFPR,NPAR,NNT0,I,J
      DOUBLE PRECISION UMX,EP,P
C
       ISW=IAP(10)
       NBC=IAP(12)
       NDM=IAP(23)
       NFPR=IAP(29)
       NPAR=IAP(31)
C
       IF(ISW.LT.0) THEN
C        ** start
         NNT0=(-NBC+4*NINT+5*NDM-23)/15
       ELSE IF(ISW.EQ.2) THEN
C        ** Non-generic case
         NNT0=(-NBC+2*NINT+3*NDM-3)/3
       ELSE
C        ** generic case
         NNT0=(-NBC+2*NINT+3*NDM-3)/3
       ENDIF
C
C Generate the function.
C
       IF(NNT0.GT.0) THEN
         ALLOCATE(DFU(NNT0*(NDM+NPAR)))
       ELSE
         ALLOCATE(DFU(1))
       ENDIF
       CALL FIBBP(IAP,NDIM,PAR,ICP,NINT,NNT0,U,UOLD,UDOT,
     *   UPOLD,F,DFU)
C
       IF(IJAC.EQ.0)THEN
         DEALLOCATE(DFU)
         RETURN
       ENDIF
C
       ALLOCATE(UU1(NDIM),UU2(NDIM),FF1(NINT),FF2(NINT))
C
C Generate the Jacobian.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       DO I=1,NDIM
         DO J=1,NDIM
           UU1(J)=U(J)
           UU2(J)=U(J)
         ENDDO
         UU1(I)=UU1(I)-EP
         UU2(I)=UU2(I)+EP
         CALL FIBBP(IAP,NDIM,PAR,ICP,NINT,NNT0,UU1,UOLD,UDOT,
     *    UPOLD,FF1,DFU)
         CALL FIBBP(IAP,NDIM,PAR,ICP,NINT,NNT0,UU2,UOLD,UDOT,
     *    UPOLD,FF2,DFU)
         DO J=1,NINT
           DINT(J,I)=(FF2(J)-FF1(J))/(2*EP)
         ENDDO
       ENDDO
C
       DEALLOCATE(UU1,UU2,FF2)
       IF(IJAC.EQ.1)THEN
         DEALLOCATE(FF1,DFU)
         RETURN
       ENDIF
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         PAR(ICP(I))=P+EP
         CALL FIBBP(IAP,NDIM,PAR,ICP,NINT,NNT0,U,UOLD,UDOT,
     *    UPOLD,FF1,DFU)
         DO J=1,NINT
           DINT(J,NDIM+ICP(I))=(FF1(J)-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
       DEALLOCATE(FF1,DFU)
C
      RETURN
      END SUBROUTINE ICBBP
C
C     ---------- -----
      SUBROUTINE FIBBP(IAP,NDIM,PAR,ICP,NINT,NNT0,
     * U,UOLD,UDOT,UPOLD,FI,DINT)
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,NNT0
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: FI(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NNT0,*)
C
C Local
      DOUBLE PRECISION, ALLOCATABLE :: F(:),DFU(:,:),DFP(:,:)
      INTEGER ISW,NBC,NDM,NBC0,NFPX,NPAR,I,J
C
       ISW=IAP(10)
       NBC=IAP(12)
       NDM=IAP(23)
       NPAR=IAP(31)
C
       IF(ISW.LT.0) THEN
C        ** start
         NBC0=(4*NBC-NINT-5*NDM+2)/15
       ELSE IF(ISW.EQ.2) THEN
C        ** Non-generic case
         NBC0=(2*NBC-NINT-3*NDM)/3
       ELSE
C        ** generic case
         NBC0=(2*NBC-NINT-3*NDM)/3
       ENDIF
       NFPX=NBC0+NNT0-NDM+1
C
       ALLOCATE(F(NDM),DFU(NDM,NDM),DFP(NDM,NPAR))
       CALL FUNI(IAP,NDM,U,UOLD,ICP,PAR,2,F,DFU,DFP)
       IF(NNT0.GT.0) THEN
         CALL ICNI(IAP,NDM,PAR,ICP,NNT0,U,UOLD,UDOT,UPOLD,FI,2,DINT)
C
         IF((ISW.EQ.2).OR.(ISW.LT.0)) THEN
C          ** Non-generic and/or start
           DO I=1,NNT0
             FI(I)=FI(I)+PAR(11+3*NFPX+NDM+1)*PAR(11+2*NFPX+NBC0+I)
           ENDDO
         ENDIF
       ENDIF
C
       IF(ISW.GT.0) THEN
C        ** restart 1 or 2
         DO I=1,NFPX
           FI(NNT0+I)=-PAR(11+3*NFPX+NDM+3+I)
           DO J=1,NDM
             FI(NNT0+I)=FI(NNT0+I)-DFP(J,ICP(I))*U(NDM+J)
           ENDDO
           DO J=1,NNT0
             FI(NNT0+I)=FI(NNT0+I)+
     *         DINT(J,NDM+ICP(I))*PAR(11+2*NFPX+NBC0+J)
           ENDDO
         ENDDO
       ELSE
C        ** start
         DO I=1,NNT0
           FI(NNT0+I)=0.d0
           FI(2*NNT0+I)=0.d0
           DO J=1,NDM
             FI(NNT0+I)=FI(NNT0+I)+DINT(I,J)*U(NDM+J)
             FI(2*NNT0+I)=FI(2*NNT0+I)+DINT(I,J)*U(2*NDM+J)
           ENDDO
           DO J=1,NFPX
             FI(NNT0+I)=FI(NNT0+I)+DINT(I,NDM+ICP(J))*PAR(11+J)
             FI(2*NNT0+I)=FI(2*NNT0+I)+DINT(I,NDM+ICP(J))*PAR(11+NFPX+J)
           ENDDO
         ENDDO
         FI(3*NNT0+1)=-1.d0
         FI(3*NNT0+2)=-1.d0
         FI(3*NNT0+3)=0.d0
         FI(3*NNT0+4)=0.d0
         DO I=1,NDM
           FI(3*NNT0+1)=FI(3*NNT0+1)+U(NDM+I)*UOLD(NDM+I)
           FI(3*NNT0+2)=FI(3*NNT0+2)+U(2*NDM+I)*UOLD(2*NDM+I)
           FI(3*NNT0+3)=FI(3*NNT0+3)+U(NDM+I)*UOLD(2*NDM+I)
           FI(3*NNT0+4)=FI(3*NNT0+4)+U(2*NDM+I)*UOLD(NDM+I)
         ENDDO
         DO I=1,NFPX
           FI(3*NNT0+1)=FI(3*NNT0+1)+PAR(11+I)**2
           FI(3*NNT0+2)=FI(3*NNT0+2)+PAR(11+NFPX+I)**2
           FI(3*NNT0+3)=FI(3*NNT0+3)+PAR(11+I)*PAR(11+NFPX+I)
           FI(3*NNT0+4)=FI(3*NNT0+4)+PAR(11+I)*PAR(11+NFPX+I)
           FI(3*NNT0+4+I)=-PAR(11+3*NFPX+NDM+3+I)+
     *       PAR(11+3*NFPX+NDM+2)*PAR(11+I)+
     *       PAR(11+3*NFPX+NDM+3)*PAR(11+NFPX+I)
           DO J=1,NDM
             FI(3*NNT0+4+I)=FI(3*NNT0+4+I)-DFP(J,ICP(I))*U(3*NDM+J)
           ENDDO
           DO J=1,NNT0
             FI(3*NNT0+4+I)=FI(3*NNT0+4+I)+DINT(J,NDM+ICP(I))*
     *         PAR(11+2*NFPX+NBC0+J)
           ENDDO
         ENDDO
       ENDIF
       DEALLOCATE(F,DFU,DFP)
C
       FI(NINT)=-PAR(11+3*NFPX+NDM)
       DO I=1,NDM
         FI(NINT)=FI(NINT)+U(NDIM-NDM+I)**2
       ENDDO
       DO I=1,NBC0+NNT0
         FI(NINT)=FI(NINT)+PAR(11+2*NFPX+I)**2
       ENDDO
C
      RETURN
      END SUBROUTINE FIBBP
C
C     ---------- -------
      SUBROUTINE STPNBBP(IAP,PAR,ICP,NTSR,NCOLRS,
     * RLDOT,UPS,UDOTPS,TM,NODIR)
C
      USE SOLVEBV
      USE BVP
      USE IO
      USE MESH
C
C Generates starting data for the 2-parameter continuation
C of BP (BVP).
C
      INTEGER, INTENT(INOUT) :: IAP(*)
      INTEGER, INTENT(IN) :: ICP(*)
      INTEGER, INTENT(INOUT) :: NTSR,NCOLRS
      INTEGER, INTENT(OUT) :: NODIR
      DOUBLE PRECISION, INTENT(OUT) :: PAR(*),RLDOT(*),
     *     UPS(IAP(1),0:*),UDOTPS(IAP(1),0:*),TM(0:*)
C Local
      INTEGER, ALLOCATABLE :: ICPRS(:)
      DOUBLE PRECISION, ALLOCATABLE :: VPS(:,:),VDOTPS(:,:),RVDOT(:)
      DOUBLE PRECISION, ALLOCATABLE :: THU1(:),THL1(:)
      DOUBLE PRECISION, ALLOCATABLE :: P0(:,:),P1(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: U(:),RLDOTRS(:),RLCUR(:)
      DOUBLE PRECISION, ALLOCATABLE :: DTM(:),UPST(:,:),UDOTPST(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: VDOTPST(:,:),UPOLDPT(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: UPSR(:,:),UDOTPSR(:,:),TMR(:)
      INTEGER NDIM,NTST,NCOL,ISW,NBC,NINT,NFPR,NDIM3,I,J,IFST,NLLV
      INTEGER ITPRS,NDM,NBC0,NNT0,NFPX,NDIMRD
      DOUBLE PRECISION DUM(1),DET,RDSZ
C
       NDIM=IAP(1)
       NTST=IAP(5)
       NCOL=IAP(6)
       ISW=IAP(10)
       NBC=IAP(12)
       NINT=IAP(13)
       NDM=IAP(23)
       NFPR=IAP(29)
C
       NDIM3=GETNDIM3()
C
       IF(NDIM.EQ.NDIM3) THEN
C        ** restart 2
         CALL STPNBV(IAP,PAR,ICP,NTSR,NCOLRS,RLDOT,
     *     UPS,UDOTPS,TM,NODIR)
         RETURN
       ENDIF
C
       ALLOCATE(UPSR(NDIM,0:NCOLRS*NTSR),
     *      UDOTPSR(NDIM,0:NCOLRS*NTSR),TMR(0:NTSR))
       IF(ISW.LT.0) THEN
C        ** start
         NBC0=(4*NBC-NINT-5*NDM+2)/15
         NNT0=(-NBC+4*NINT+5*NDM-23)/15
       ELSE IF(ISW.EQ.2) THEN
C        ** Non-generic case
         NBC0=(2*NBC-NINT-3*NDM)/3
         NNT0=(-NBC+2*NINT+3*NDM-3)/3
       ELSE
C        ** generic case
         NBC0=(2*NBC-NINT-3*NDM)/3
         NNT0=(-NBC+2*NINT+3*NDM-3)/3
       ENDIF
       NFPX=NBC0+NNT0-NDM+1
C
       ALLOCATE(ICPRS(NFPR),RLCUR(NFPR),RLDOTRS(NFPR))
       IF(ISW.LT.0) THEN
C
C Start
C
C        ** allocation
         ALLOCATE(UPST(NDM,0:NTSR*NCOLRS),UDOTPST(NDM,0:NTSR*NCOLRS))
         ALLOCATE(UPOLDPT(NDM,0:NTSR*NCOLRS))
         ALLOCATE(VDOTPST(NDM,0:NTSR*NCOLRS),RVDOT(NFPX))
         ALLOCATE(THU1(NDM),THL1(NFPX))
         ALLOCATE(P0(NDM,NDM),P1(NDM,NDM))
         ALLOCATE(U(NDM),DTM(NTSR))
C
C        ** read the std branch
         CALL READBV(IAP,PAR,ICPRS,NTSR,NCOLRS,NDIMRD,RLDOTRS,UPST,
     *     UDOTPST,TMR,ITPRS,NDM)
C
         DO I=1,NTSR
           DTM(I)=TMR(I)-TMR(I-1)
         ENDDO
C
         DO I=1,NFPX
           RLCUR(I)=PAR(ICPRS(I))
         ENDDO
C
C Compute the second null vector
C
C        ** redefine IAP
         IAP(1)=NDM
         IAP(5)=NTSR
         IAP(6)=NCOLRS
         IAP(12)=NBC0
         IAP(13)=NNT0
         IAP(29)=NFPX
C
C        ** compute UPOLDP
         IF(NNT0.GT.0) THEN
            DO J=0,NTSR*NCOLRS
               U(:)=UPST(:,J)
               CALL FUNI(IAP,NDM,U,U,ICPRS,PAR,0,
     *              UPOLDPT(1,J),DUM,DUM)
            ENDDO
         ENDIF
C
C        ** unit weights
         THL1(1:NFPX)=1.d0
         THU1(1:NDM)=1.d0
C
C        ** call SOLVBV
         RDSZ=0.d0
         NLLV=1
         IFST=1
         CALL SOLVBV(IFST,IAP,DET,PAR,ICPRS,FUNI,BCNI,ICNI,RDSZ,NLLV,
     *     RLCUR,RLCUR,RLDOTRS,NDM,UPST,UPST,UDOTPST,UPOLDPT,
     *     DTM,VDOTPST,RVDOT,P0,P1,THL1,THU1)
C
C        ** normalization
         CALL SCALEB(NTSR,NCOLRS,NDM,NFPX,UDOTPST,RLDOTRS,DTM,THL1,THU1)
         CALL SCALEB(NTSR,NCOLRS,NDM,NFPX,VDOTPST,RVDOT,DTM,THL1,THU1)
C
C        ** restore IAP
         IAP(1)=NDIM
         IAP(5)=NTST
         IAP(6)=NCOL
         IAP(12)=NBC
         IAP(13)=NINT
         IAP(29)=NFPR

C        ** init UPS,PAR
         UPSR(1:NDM,:)=UPST(:,:)
         UPSR(NDM+1:2*NDM,:)=UDOTPST(:,:)
         UPSR(2*NDM+1:3*NDM,:)=VDOTPST(:,:)
         UPSR(3*NDM+1:4*NDM,:)=0.d0
         UDOTPSR(:,:)=0.d0
C
         DO I=1,NFPX
           PAR(11+I)=RLDOTRS(I)
           PAR(11+NFPX+I)=RVDOT(I)
           RLDOT(I)=0.d0
           RLDOT(NFPX+I+2)=0.d0
           RLDOT(2*NFPX+I+2)=0.d0
         ENDDO
C
C        ** init psi^*2,psi^*3
         DO I=1,NBC0+NNT0
           PAR(11+2*NFPX+I)=0.d0
           RLDOT(3*NFPX+I+2)=0.d0
         ENDDO
C
C        ** init a,b,c1,c1,d
         PAR(11+3*NFPX+NDM:11+3*NFPX+NDM+3)=0.d0
         RLDOT(NFPX+1)=0.d0
         RLDOT(NFPX+2)=1.d0
         RLDOT(4*NFPX+NDM+2)=0.d0
         RLDOT(4*NFPX+NDM+3)=0.d0
         DO I=1,NFPX
           PAR(11+3*NFPX+NDM+3+I)=0.d0
           RLDOT(4*NFPX+NDM+I+3)=0.d0
         ENDDO
C
         DEALLOCATE(UPST,UPOLDPT,UDOTPST,VDOTPST,RVDOT)
         DEALLOCATE(THU1,THL1)
         DEALLOCATE(P0,P1)
         DEALLOCATE(U,DTM)
C
         NODIR=0
C
       ELSE
C
C Restart 1
C
         ALLOCATE(VPS(2*NDIM,0:NTSR*NCOLRS),
     *         VDOTPS(2*NDIM,0:NTSR*NCOLRS))
C
C        ** read the std branch
         CALL READBV(IAP,PAR,ICPRS,NTSR,NCOLRS,NDIMRD,RLDOTRS,VPS,
     *     VDOTPS,TMR,ITPRS,2*NDIM)
C
         UPSR(1:NDM,:)=VPS(1:NDM,:)
         UPSR(NDM+1:2*NDM,:)=VPS(3*NDM+1:4*NDM,:)
C
         DEALLOCATE(VPS,VDOTPS)
C
         NODIR=1
C
       ENDIF
       DEALLOCATE(ICPRS,RLDOTRS,RLCUR)
C
       CALL ADAPT2(NTSR,NCOLRS,NDIM,NTST,NCOL,NDIM,
     *      TMR,UPSR,UDOTPSR,TM,UPS,UDOTPS,.FALSE.)
       DEALLOCATE(TMR,UPSR,UDOTPSR)
      RETURN
      END SUBROUTINE STPNBBP
C
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C          Routines for Interface with User Supplied Routines
C  (To generate Jacobian by differencing, if not supplied analytically)
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
C
C     ---------- ----
      SUBROUTINE FUNI(IAP,NDIM,U,UOLD,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Interface subroutine to user supplied FUNC.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM),DFDP(NDIM,*)
C
      INTEGER JAC,I,J,NFPR,IJC
      DOUBLE PRECISION UMX,EP,UU,P
C
       JAC=IAP(22)
C
C Generate the function.
C
C
C if the user specified the Jacobian but not the
C parameter derivatives we do not generate the Jacobian here
C
       IF(JAC.EQ.0.AND.IJAC.NE.0)THEN
C
C Generate the Jacobian by differencing.
C
         UMX=0.d0
         DO I=1,NDIM
           IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
         ENDDO
C
         EP=HMACH*(1+UMX)
C
         DO I=1,NDIM
           UU=U(I)
           U(I)=UU-EP
           CALL FUNC(NDIM,U,ICP,PAR,0,F,DFDU,DFDP)
           U(I)=UU+EP
           CALL FUNC(NDIM,U,ICP,PAR,0,DFDU(1,I),DFDU,DFDP)
           U(I)=UU
           DO J=1,NDIM
             DFDU(J,I)=(DFDU(J,I)-F(J))/(2*EP)
           ENDDO
         ENDDO
C
       ENDIF
C
       IF((IJAC.EQ.1.AND.JAC.NE.0).OR.(IJAC.EQ.2.AND.JAC.EQ.1))THEN
         IJC=IJAC
       ELSE
         IJC=0
       ENDIF
       CALL FUNC(NDIM,U,ICP,PAR,IJC,F,DFDU,DFDP)
       IF(JAC.EQ.1.OR.IJAC.NE.2)RETURN
       NFPR=IAP(29)
       DO I=1,NFPR
         P=PAR(ICP(I))
         EP=HMACH*( 1 +ABS(P) )
         PAR(ICP(I))=P+EP
         CALL FUNC(NDIM,U,ICP,PAR,0,DFDP(1,ICP(I)),DFDU,DFDP)
         DO J=1,NDIM
           DFDP(J,ICP(I))=(DFDP(J,ICP(I))-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
      RETURN
      END SUBROUTINE FUNI
C
C     ---------- ----
      SUBROUTINE BCNI(IAP,NDIM,PAR,ICP,NBC,U0,U1,F,IJAC,DBC)
C
C Interface subroutine to the user supplied BCND.
C
      INTEGER, INTENT(IN) :: IAP(*),NDIM,ICP(*),NBC,IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U0(NDIM),U1(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NBC)
      DOUBLE PRECISION, INTENT(INOUT) :: DBC(NBC,*)
C Local
      DOUBLE PRECISION EP,UMX,UU,P
      INTEGER IJC,I,J,JAC,NFPR
C
       JAC=IAP(22)
C
C Generate the function.
C
       IF(JAC==0 .AND. IJAC/=0)THEN
C
C Generate the Jacobian by differencing.
C
          UMX=0.d0
          DO I=1,NDIM
             IF(ABS(U0(I)).GT.UMX)UMX=ABS(U0(I))
          ENDDO
C
          EP=HMACH*(1+UMX)
C
          DO I=1,NDIM
             UU=U0(I)
             U0(I)=UU-EP
             CALL BCND(NDIM,PAR,ICP,NBC,U0,U1,F,0,DBC)
             U0(I)=UU+EP
             CALL BCND(NDIM,PAR,ICP,NBC,U0,U1,DBC(1,I),0,DBC)
             U0(I)=UU
             DO J=1,NBC
                DBC(J,I)=(DBC(J,I)-F(J))/(2*EP)
             ENDDO
          ENDDO
C
          UMX=0.d0
          DO I=1,NDIM
             IF(ABS(U1(I)).GT.UMX)UMX=ABS(U1(I))
          ENDDO
C
          EP=HMACH*(1+UMX)
C
          DO I=1,NDIM
             UU=U1(I)
             U1(I)=UU-EP
             CALL BCND(NDIM,PAR,ICP,NBC,U0,U1,F,0,DBC)
             U1(I)=UU+EP
             CALL BCND(NDIM,PAR,ICP,NBC,U0,U1,DBC(1,NDIM+I),0,DBC)
             U1(I)=UU
             DO J=1,NBC
                DBC(J,NDIM+I)=(DBC(J,NDIM+I)-F(J))/(2*EP)
             ENDDO
          ENDDO
       ENDIF
C
       IF((IJAC.EQ.1.AND.JAC.NE.0).OR.(IJAC.EQ.2.AND.JAC.EQ.1))THEN
         IJC=IJAC
       ELSE
         IJC=0
       ENDIF
       CALL BCND(NDIM,PAR,ICP,NBC,U0,U1,F,IJC,DBC)
       IF(JAC==1 .OR. IJAC/=2)RETURN
C
       NFPR=IAP(29)
       DO I=1,NFPR
         P=PAR(ICP(I))
         EP=HMACH*( 1 +ABS(P))
         PAR(ICP(I))=P+EP
         CALL BCND(NDIM,PAR,ICP,NBC,U0,U1,DBC(1,2*NDIM+ICP(I)),0,DBC)
         DO J=1,NBC
           DBC(J,2*NDIM+ICP(I))=(DBC(J,2*NDIM+ICP(I))-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
      RETURN
      END SUBROUTINE BCNI
C
C     ---------- ----
      SUBROUTINE ICNI(IAP,NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     * F,IJAC,DINT)
C
C Interface subroutine to user supplied ICND.
C
      INTEGER, INTENT(IN) :: IAP(*),ICP(*),NDIM,NINT,IJAC
      DOUBLE PRECISION, INTENT(IN) :: UOLD(NDIM),UDOT(NDIM),UPOLD(NDIM)
      DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F(NINT)
      DOUBLE PRECISION, INTENT(INOUT) :: DINT(NINT,*)
C
      INTEGER JAC,I,J,NFPR,IJC
      DOUBLE PRECISION UMX,EP,UU,P
C
       JAC=IAP(22)
C
C Generate the integrand.
C
       IF(JAC==0 .AND. IJAC/=0)THEN
C
C Generate the Jacobian by differencing.
C
          UMX=0.d0
          DO I=1,NDIM
             IF(ABS(U(I)).GT.UMX)UMX=ABS(U(I))
          ENDDO
C
          EP=HMACH*(1+UMX)
C
          DO I=1,NDIM
             UU=U(I)
             U(I)=UU-EP
             CALL ICND(NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,F,0,DINT)
             U(I)=UU+EP
             CALL ICND(NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,DINT(1,I),0,
     *            DINT)
             U(I)=UU
             DO J=1,NINT
                DINT(J,I)=(DINT(J,I)-F(J))/(2*EP)
             ENDDO
          ENDDO
       ENDIF
C
       IF((IJAC.EQ.1.AND.JAC.NE.0).OR.(IJAC.EQ.2.AND.JAC.EQ.1))THEN
         IJC=IJAC
       ELSE
         IJC=0
       ENDIF
       CALL ICND(NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,F,IJC,DINT)
       IF(JAC==1 .OR. IJAC/=2)RETURN
C
       NFPR=IAP(29)
       DO I=1,NFPR
         P=PAR(ICP(I))
         EP=HMACH*( 1 +ABS(P) )
         PAR(ICP(I))=P+EP
         CALL ICND(NDIM,PAR,ICP,NINT,U,UOLD,UDOT,UPOLD,
     *        DINT(1,NDIM+ICP(I)),0,DINT)
         DO J=1,NINT
           DINT(J,NDIM+ICP(I))=(DINT(J,NDIM+ICP(I))-F(J))/EP
         ENDDO
         PAR(ICP(I))=P
       ENDDO
C
      RETURN
      END SUBROUTINE ICNI
C
C     ---------- ----
      SUBROUTINE FOPI(JAC,NFPR,NDIM,U,ICP,PAR,IJAC,F,DFDU,DFDP)
C
C Interface subroutine to user supplied FOPT.
C
      INTEGER, INTENT(IN) :: JAC,NFPR,NDIM,ICP(*),IJAC
      DOUBLE PRECISION, INTENT(INOUT) :: U(*),PAR(*)
      DOUBLE PRECISION, INTENT(OUT) :: F
      DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM),DFDP(*)
C Local
      DOUBLE PRECISION, ALLOCATABLE :: U1ZZ(:),U2ZZ(:)
      INTEGER IJC,I,J
      DOUBLE PRECISION UMX,EP,P,F1,F2
C
C
C Generate the objective function.
C
       IF(JAC.EQ.0)THEN
         IJC=0
       ELSE
         IJC=IJAC
       ENDIF
       CALL FOPT(NDIM,U,ICP,PAR,IJC,F,DFDU,DFDP)
C
       IF(JAC.EQ.1 .OR. IJAC.EQ.0)RETURN
C
C Generate the Jacobian by differencing.
C
       UMX=0.d0
       DO I=1,NDIM
         IF(DABS(U(I)).GT.UMX)UMX=DABS(U(I))
       ENDDO
C
       EP=HMACH*(1+UMX)
C
       ALLOCATE(U1ZZ(NDIM),U2ZZ(NDIM))
       DO I=1,NDIM
         DO J=1,NDIM
           U1ZZ(J)=U(J)
           U2ZZ(J)=U(J)
         ENDDO
         U1ZZ(I)=U1ZZ(I)-EP
         U2ZZ(I)=U2ZZ(I)+EP
         CALL FOPT(NDIM,U1ZZ,ICP,PAR,0,F1,DFDU,DFDP)
         CALL FOPT(NDIM,U2ZZ,ICP,PAR,0,F2,DFDU,DFDP)
         DFDU(I)=(F2-F1)/(2*EP)
       ENDDO
       DEALLOCATE(U1ZZ,U2ZZ)
C
       IF(IJAC.EQ.1)RETURN
C
       DO I=1,NFPR
         P=PAR(ICP(I))
         EP=HMACH*( 1 +ABS(P) )
         PAR(ICP(I))=P+EP
         CALL FOPT(NDIM,U,ICP,PAR,0,F1,DFDU,DFDP)
         DFDP(ICP(I))=(F1-F)/EP
         PAR(ICP(I))=P
       ENDDO
C
       RETURN
       END SUBROUTINE FOPI
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
      END MODULE INTERFACES
