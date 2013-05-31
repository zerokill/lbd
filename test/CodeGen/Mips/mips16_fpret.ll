; RUN: llc -mtriple=mipsel-linux-gnu -march=mipsel -mcpu=mips16 -soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=1
; RUN: llc -mtriple=mipsel-linux-gnu -march=mipsel -mcpu=mips16 -soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=2
; RUN: llc -mtriple=mipsel-linux-gnu  -march=mipsel -mcpu=mips16 -soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=3
; RUN: llc -mtriple=mipsel-linux-gnu -march=mipsel -mcpu=mips16 -soft-float -mips16-hard-float -relocation-model=static < %s | FileCheck %s -check-prefix=4


@x = global float 0x41F487E980000000, align 4
@dx = global double 0x41CDCC8BC4800000, align 8
@cx = global { float, float } { float 1.000000e+00, float 9.900000e+01 }, align 4
@dcx = global { double, double } { double 0x42CE5E14A412B480, double 0x423AA4C580DB0000 }, align 8

define float @foox()  {
entry:
  %0 = load float* @x, align 4
  ret float %0
; 1: 	.ent	foox
; 1:	lw	$2, %lo(x)(${{[0-9]+}})
; 1:	jal	__mips16_ret_sf
}

define double @foodx()  {
entry:
  %0 = load double* @dx, align 8
  ret double %0
; 1: 	.ent	foodx
; 1: 	lw	$2, %lo(dx)(${{[0-9]+}})
; 1:	jal	__mips16_ret_df
; 2: 	.ent	foodx
; 2:	lw	$3, 4(${{[0-9]+}})
; 2:	jal	__mips16_ret_df

}

define { float, float } @foocx()  {
entry:
  %retval = alloca { float, float }, align 4
  %cx.real = load float* getelementptr inbounds ({ float, float }* @cx, i32 0, i32 0)
  %cx.imag = load float* getelementptr inbounds ({ float, float }* @cx, i32 0, i32 1)
  %real = getelementptr inbounds { float, float }* %retval, i32 0, i32 0
  %imag = getelementptr inbounds { float, float }* %retval, i32 0, i32 1
  store float %cx.real, float* %real
  store float %cx.imag, float* %imag
  %0 = load { float, float }* %retval
  ret { float, float } %0
; 1: 	.ent	foocx
; 1: 	lw	$2, %lo(cx)(${{[0-9]+}})
; 1:	jal	__mips16_ret_sc
; 2: 	.ent	foocx
; 2:	lw	$3, 4(${{[0-9]+}})
; 2:	jal	__mips16_ret_sc
}

define { double, double } @foodcx()  {
entry:
  %retval = alloca { double, double }, align 8
  %dcx.real = load double* getelementptr inbounds ({ double, double }* @dcx, i32 0, i32 0)
  %dcx.imag = load double* getelementptr inbounds ({ double, double }* @dcx, i32 0, i32 1)
  %real = getelementptr inbounds { double, double }* %retval, i32 0, i32 0
  %imag = getelementptr inbounds { double, double }* %retval, i32 0, i32 1
  store double %dcx.real, double* %real
  store double %dcx.imag, double* %imag
  %0 = load { double, double }* %retval
  ret { double, double } %0
; 1: 	.ent	foodcx
; 1: 	lw	$2, %lo(dcx)(${{[0-9]+}})
; 1:	jal	__mips16_ret_dc
; 2: 	.ent	foodcx
; 2:	lw	$3, 4(${{[0-9]+}})
; 2:	jal	__mips16_ret_dc
; 3: 	.ent	foodcx
; 3:	lw	$4, 8(${{[0-9]+}})
; 3:	jal	__mips16_ret_dc
; 4: 	.ent	foodcx
; 4:	lw	$5, 12(${{[0-9]+}})
; 4:	jal	__mips16_ret_dc
}

