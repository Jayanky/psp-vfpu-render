.globl putLine
# $a0 = void* buffer
# $a1 = float* startCoord
# $a2 = float* endCoord
# $a3 = unsigned int color
putLine:
    .macro putPixel
    # address += ((y * bufferwidth) + x) * bpp
    mul.s $f7, $f2, $f3
    add.s $f7, $f7, $f0
    round.w.s $f7, $f7
    mfc1 $t7, $f7
    multu $t7, $t4
    mflo $t7
    addu $t7, $t7, $a0

    # store
    sw $a3, 0($t7)
    .endm

    # load coordinates
    lv.q r000, 0($a1)
    lv.q r001, 0($a2)

    # x0 - x1, y0 - y1.
    vsub.p r002, r000, r001

    # vfpu_cc[0] = |x0 - x1| < |y0 - y1|
    vcmp.s lt, s002[|x|], s012[|x|]

    # flip x and y based on result of comparison.
    vcmovt.p c020, c010, 0
    vcmovt.p c010, c000, 0
    vcmovt.p c000, c020, 0

    # store steepness check
    vmfvc s700, $131   

    # vfpu_cc[0] = x0 > x1
    vcmp.s gt, s000, s001

    # flip x0 and x1 / y0 and y1 based on comparison
    vcmovt.p r002, r001, 0
    vcmovt.p r001, r000, 0
    vcmovt.p r000, r002, 0

    # restore steepness check
    vmtvc $131, s700

    # dx = x1 - x0, dy = y1 - y0
    vsub.p r002, r001, r000

    # find amount to increment y by every loop
    vdiv.s s701, s012[x], s002[x]

    # get addresses to load for fpu registers
    la $t0, xval
    la $t1, xval2
    la $t2, yval
    la $t6, yincval

    # load immediates into fpu registers
    li.s $f3, 512
    li $t4, 4
    li.s $f5, 1

    # load ready values from loaded addresses into fpu
    sv.s s000, 0($t0)    
    sv.s s001, 0($t1)
    sv.s s010, 0($t2)    
    sv.s s701, 0($t6)
    l.s $f0, 0($t0)
    l.s $f1, 0($t1)
    l.s $f2, 0($t2)
    l.s $f6, 0($t6)

    bvt 0, steep

    # load x and y values for plotting
    l.s $f0, 0($t0)
    l.s $f2, 0($t2)

    normalloop:
    putPixel

    # check if x0 <= x1, increment counter
    c.le.s $f0, $f1
    add.s $f2, $f2, $f6
    add.s $f0, $f0, $f5
    bc1t normalloop
    j end

    steep:
    # detranspose and load x and y values for plotting
    l.s $f0, 0($t2)
    l.s $f2, 0($t0)

    steeploop:
    putPixel

    # check if x0 <= x1, increment counter
    # x and y are un-detransposed for loop calculations.
    c.le.s $f2, $f1
    add.s $f0, $f0, $f6
    add.s $f2, $f2, $f5
    bc1t steeploop

    end:
    jr $ra

.data
.align 4, 1
xval: .float 0
xval2: .float 0
yval: .float 0
yincval: .float 0
