; ========== CapsLockX ==========
; 名称：时基加速模型
; 描述：用来模拟按键和鼠标，计算一个虚拟的光标运动物理模型。
; 版本：v2020.06.27
; 作者：snomiao
; 联系：snomiao@gmail.com
; 支持：https://github.com/snomiao/CapsLockX
; 版权：Copyright © 2017-2022 Snowstar Laboratory. All Rights Reserved.
; ========== CapsLockX ==========
; 光标加速度微分对称模型（不要在意这中二的名字hhhh

perf_now()
{
    DllCall("QueryPerformanceCounter", "Int64*", Counter)
    DllCall("QueryPerformanceFrequency", "Int64*", QuadPart)
    return Counter/QuadPart
}
perf_timing(showq := 1)
{
    static last := perf_now()
    now := perf_now()
    d := now - last
    static d99 := 0
    static dl := 0
    d99 := d99*99/100 + d*1/100
    last := now
    fps := 1/d99
    if (showq) {
        tooltip perf %fps% %d% %d99% %dl%
    }
    dl := d
}
class AccModel2D
{
    __New(RealOpFunc, WeakenRatio := 1, AcclerateRatio := 1, LongitudeAcclerateRatio := 0)
    {
        this.StartTime := 0, this.Moving := 0
        this.LeftStartTime := 0, this.RightStartTime := 0
        this.UpStartTime := 0, this.DownStartTime := 0
        this.LateralSpeed := 0, this.LateralDistance := 0
        this.LogitudeSpeed := 0, this.LogitudeDistance := 0
        this.LeftKey := "", this.RightKey := ""
        this.UpKey := "", this.DownKey := ""
        this.间隔 := 0
        this.clock := ObjBindMethod(this, "_ticker")
        this.RealOpFunc := RealOpFunc
        this.LateralAcclerateRatio := AcclerateRatio
        this.LongitudeAcclerateRatio := LongitudeAcclerateRatio == 0 ? this.LateralAcclerateRatio : LongitudeAcclerateRatio
        this.WeakenRatio := WeakenRatio
        this.中键间隔 := 0.1 ; 100ms
    }
    _dt(t, CurrentTime)
    {
        Return t ? (CurrentTime - t) / this._QPF() : 0
    }
    _ma(_dt)
    {
        sgn := this._sign(_dt)
        abs := Abs(_dt)
        ; 1x 指数函数 + 1x 4次函数
        a := 0
        a += 1 * sgn * ( Exp(abs) - 1 )
        a += 1 * sgn
        a += 4 * sgn * abs
        a += 9 * sgn * abs * abs
        a += 16 * sgn * abs * abs * abs
        return a
    }
    _sign(x)
    {
        return x == 0 ? 0 : (x > 0 ? 1 : -1)
    }
    _damping(v, a, dt)
    {
        ; 限制最大速度
        if (this.MaxSpeed) {
            maxs := this.MaxSpeed
            v := v < -maxs ? -maxs : v
            v := v > maxs ? maxs : v
            if (abs(v)==maxs) {
                ; tooltip 警告：达到最大速度
            }
        }
        ; 摩擦力不阻碍用户意志，加速度同向时不使用摩擦力
        if (a * v > 0) {
            Return v
        }
        
        ; 简单粗暴倍数降速
        v *= Exp(-dt*20)
        v -= this._sign(v) * dt
        ; v *= 1 - this.WeakenRatio
        ; 线性降速
        ; v -= !this.WeakenRatio ? 0 : v > 1 ? 1 : (v < -1 ? -1 : 0)
        ; 零点吸附
        v:= Abs(v) < 1 ? 0 : v
        Return v
    }
    _ticker()
    {
        re := this._tickerLooper()
    }
    _tickerLooper()
    {
        ; 用户操作总时间计算
        CurrentTime := this._QPC()
        ; dt 计算
        dt := this.StartTime == 0 ? 0 : ((CurrentTime - this.StartTime) / this._QPF())
        this.StartTime := CurrentTime
        left_hold_time := this._dt(this.LeftStartTime, CurrentTime), right_hold_time := this._dt(this.RightStartTime, CurrentTime)
        up_hold_time := this._dt(this.UpStartTime, CurrentTime), down_hold_time := this._dt(this.DownStartTime, CurrentTime)
        ; 同时按下相当于中键（同时也会取消自动）
        if (this.LeftStartTime && this.RightStartTime && Abs(right_hold_time-left_hold_time) < this.中键间隔) {
            this.RealOpFunc.Call(this._sign(right_hold_time-left_hold_time), 0, "横中键")
            this.StopMove()
            return 1
        }
        if (this.UpStartTime && this.DownStartTime && Abs(down_hold_time-up_hold_time) < this.中键间隔) {
            this.RealOpFunc.Call(0, this._sign(down_hold_time-up_hold_time), "纵中键")
            this.StopMove()
            return 1
        }
        ; 处理移动
        lateral_acc := this._ma(right_hold_time-left_hold_time) * this.LateralAcclerateRatio
        longitude_acc := this._ma(down_hold_time-up_hold_time) * this.LongitudeAcclerateRatio
        this.LateralSpeed += lateral_acc * dt
        this.LogitudeSpeed += longitude_acc * dt
        this.LateralSpeed := this._damping(this.LateralSpeed, lateral_acc, dt)
        this.LogitudeSpeed := this._damping(this.LogitudeSpeed, longitude_acc, dt)
        
        ; perf_timing(1)
        ; 快速启动
        if (!dt) {
            this.Starting := 1
            this.RealOpFunc.Call(0, 0, "Move")
            this.Starting := 0
            
            this.LateralDistance := this._sign(lateral_acc)
            this.LogitudeDistance := this._sign(longitude_acc)
        }
        this.LateralDistance += this.LateralSpeed * dt
        this.LogitudeDistance += this.LogitudeSpeed * dt
        ;横输出 := this.LateralDistance | 0  ; 取整输出
        lateral_remain := this.LateralDistance | 0  ; 取整输出
        longitude_remain := this.LogitudeDistance | 0  ; 取整输出
        this.LateralDistance -= lateral_remain      ; 收回零头攒起来
        this.LogitudeDistance -= longitude_remain      ; 收回零头攒起来
        
        ; debug
        ;msg := dt "`n" CurrentTime "`n" this.StartTime "`n" lateral_acc "`n" this.LateralSpeed "`n" this.LateralDistance "`n" this.lateral_remain
        ;tooltip %msg%
        
        if (lateral_remain || longitude_remain) {
            ;tooltip %dt% %lateral_remain% %longitude_remain% %lateral_acc% %longitude_acc%
            this.RealOpFunc.Call(lateral_remain, longitude_remain, "Move")
        }
        ; 要求的键弹起，结束定时器
        if (this.LeftKey && !GetKeyState(this.LeftKey, "P")) {
            this.LeftKey := "", this.ReleaseLeft()
        }
        if (this.RightKey && !GetKeyState(this.RightKey, "P")) {
            this.RightKey := "", this.ReleaseRight()
        }
        if (this.UpKey && !GetKeyState(this.UpKey, "P")) {
            this.UpKey := "", this.ReleaseUp()
        }
        if (this.DownKey && !GetKeyState(this.DownKey, "P")) {
            this.DownKey := "", this.ReleaseDown()
        }
        ; 速度归 0，结束定时器
        if ( !this.LateralSpeed && !this.LogitudeSpeed && !(lateral_remain || longitude_remain)) {
            this.StopMove()
            return 0
        }
        return 1
    }
    StartMove() {
        this.StartTime := 0
        this._ticker()
        clock := this.clock
        SetTimer % clock, % 0
    }
    StopMove(){
        clock := this.clock
        SetTimer % clock, Off
        if (this.StartTime != 0) {
            this.StartTime := 0
            this.RealOpFunc.Call(0, 0, "StopMove")
        }
        this.StartTime := 0, this.Moving := 0
        this.LeftStartTime := 0, this.RightStartTime := 0
        this.UpStartTime := 0, this.DownStartTime := 0
        this.LateralSpeed := 0, this.LateralDistance := 0
        this.LogitudeSpeed := 0, this.LogitudeDistance := 0
        this.LeftKey := "", this.RightKey := ""
        this.UpKey := "", this.DownKey := ""
    }
    PressLeft(LeftKey:=""){
        if (this.LeftKey) {
            return
        }
        this.LeftKey := LeftKey
        this.LeftStartTime := this.LeftStartTime ? this.LeftStartTime : this._QPC()
        this.StartMove()
    }
    ReleaseLeft(){
        this.LeftStartTime := 0
    }
    PressRight(RightKey:=""){
        if (this.RightKey) {
            return
        }
        this.RightKey := RightKey
        this.RightStartTime := this.RightStartTime ? this.RightStartTime : this._QPC()
        this.StartMove()
        ;tooltip, right move
    }
    ReleaseRight(){
        this.RightStartTime := 0
    }
    PressUp(UpKey:=""){
        if (this.UpKey) {
            return
        }
        this.UpKey := UpKey
        this.UpStartTime := this.UpStartTime ? this.UpStartTime : this._QPC()
        this.StartMove()
    }
    ReleaseUp(){
        this.UpStartTime := 0
    }
    PressDown(DownKey:=""){
        if (this.DownKey) {
            return
        }
        this.DownKey := DownKey
        this.DownStartTime := this.DownStartTime ? this.DownStartTime : this._QPC()
        this.StartMove()
    }
    ReleaseDown(){
        this.DownStartTime := 0
    }
    ; 高性能计时器，精度能够达到微秒级，相比之下 A_Tick 的精度大概只有10几ms。
    _QPF()
    {
        DllCall("QueryPerformanceFrequency", "Int64*", QuadPart)
        Return QuadPart
    }
    _QPC()
    {
        DllCall("QueryPerformanceCounter", "Int64*", Counter)
        Return Counter
    }
    _QPS()
    {
        ; static _QPF
        return this._QPC() / this._QPF()
    }
}
class FPS_Debugger
{
    __New()
    {
        this.interval := 1000
        this.count := 0
        this.timer := ObjBindMethod(this, "Tick")
        timer := this.timer
        SetTimer % timer, % this.interval
    }
    inc()
    {
        this.count := this.count + 1
        ; ToolTip % "FPS:" this.count
    }
    ; In this example, the timer calls this method:
    Tick()
    {
        ToolTip % "FPS:" this.count
        this.count := 0
    }
}
