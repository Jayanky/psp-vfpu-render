# .globl putLine
# $a0 = int* buffer
# $a1 = unsigned float* startCoord
# $a2 = unsigned float* endCoord
# $a3 = unsigned int color
putLine:
    .macro putPixel
    # address += ((y * bufferwidth) + x) * bpp
    mul.s $f7, $f2, $f3
    add.s $f7, $f7, $f0
    mul.s $f7, $f7, $f4
    cvt.w.s $f7, $f7
    mfc1 $t7, $f7
    sub.s $f7, $f7, $f7
    addu $t7, $t7, $a0

    # store
    sw $a3, 0($t7)

    # check if x0 <= x1, increment counter
    c.le.s $f0, $f1
    add.s $f2, $f2, $f6
    add.s $f0, $f0, $f5
    .endm

    # load coordinates
    lv.q r000, 0($a1)
    lv.q r001, 0($a2)

    # vfpu_cc[0] = x0 > x1
    vcmp.s gt, s000, s001

    # flip x0 and x1 / y0 and y1 based on comparison
    vcmovt.p r002, r001, 0
    vcmovt.p r001, r000, 0
    vcmovt.p r000, r002, 0

    # x0 - x1, y0 - y1.
    vsub.p r002, r000, r001

    # vfpu_cc[0] = |x0 - x1| < |y0 - y1|
    vcmp.s lt, s002[|x|], s012[|x|]

    # flip x and y based on result of comparison.
    vcmovt.p c020, c010, 0
    vcmovt.p c010, c000, 0
    vcmovt.p c000, c020, 0

    # dx = x1 - x0, dy = y1 - y0
    vsub.p r002, r001, r000

    # find amount to increment y by every loop
    vdiv.s s701, s012[x], s002[x]

    # get addresses to load into fpu registers
    la $t0, xval
    la $t1, xval2
    la $t2, yval
    la $t3, bufferwidth
    la $t4, bytesperpxl
    la $t5, xincval
    la $t6, yincval

    # load ready values from loaded addresses into fpu
    sv.s s001, 0($t1)
    sv.s s701, 0($t6)
    l.s $f1, 0($t1)
    l.s $f3, 0($t3)
    l.s $f4, 0($t4)
    l.s $f5, 0($t5)
    l.s $f6, 0($t6)

    bvt 0, steep

    # load x and y values into registers
    sv.s s000, 0($t0)
    sv.s s010, 0($t2)
    l.s $f0, 0($t0)
    l.s $f2, 0($t2)

    loopnormal:
    putPixel
    bc1t loopnormal
    j end

    steep:
    # detranspose and load x and y value into float registers
    sv.s s010, 0($t0)
    sv.s s000, 0($t2)
    l.s $f0, 0($t0)
    l.s $f2, 0($t2)

    loopsteep:
    putPixel
    bc1t loopsteep

    end:
    # return
    jr $ra

.data
.align 4, 1
xval: .float 0
xval2: .float 0
yval: .float 0
bufferwidth: .float 512
bytesperpxl: .float 4
xincval: .float 1
yincval: .float 0
