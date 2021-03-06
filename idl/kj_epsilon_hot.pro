
function kj_IPrime, zeta, n

    ; This should work fine for n=0, since the IDL routines
    ; handle the n=-n symmetry for integer argument (unlike 
    ; the fortran routines).

    return, beselI(zeta,n-1) - n/zeta * beselI(zeta,n)

end


function kj_epsilon_hot, f, amu, atomicZ, B, density, harmonicNumber, kPar, kPer, T_eV, $
    epsilon_cold = epsilon_cold, epsilon_swan_WD = epsilon_swan_WD, epsilon_swan_ND = epsilon_swan_ND, $
    kx = kx, nuOmg = _nu_omg

; Vectorized over kPer

if keyword_set(_nu_omg) then nu_omg = _nu_omg else nu_omg = 0

@dlg_constants

NK = n_elements(kPer)

iiNeg = where( kPer lt 0, iiNegCnt)
if iiNegCnt gt 0 then stop
_kPer = kPer>1e-5

w = 2 * !Pi * f
m = amu * _amu
q = atomicZ * _e
nPar = _c * kPar / w
nPer = _c * _kPer / w

nS = n_elements(amu)

Shat = dComplexArr(NK) + dcomplex(1,0)
Dhat = dComplexArr(NK) + dcomplex(0,0)
Phat = dComplexArr(NK) + dcomplex(1,0)

etahat = dComplexArr(NK) + dcomplex(0,0)
tauhat = dComplexArr(NK) + dcomplex(0,0)
epshat = dComplexArr(NK) + dcomplex(0,0)

if arg_present(epsilon_swan_WD) then begin
    K0 = dComplex(0,0)
    K1 = dComplex(1,0)
    K2 = dComplex(0,0)
    K3 = dComplex(1,0)
    K4 = dComplex(0,0)
    K5 = dComplex(0,0)
endif

if arg_present(epsilon_swan_ND) then begin
    K0_ND = dComplex(0,0)
    K1_ND = dComplex(1,0)
    K2_ND = dComplex(0,0)
    K3_ND = dComplex(1,0)
    K4_ND = dComplex(0,0)
    K5_ND = dComplex(0,0)
endif

for alp = 0,nS-1 do begin
   
    wc = q[alp] * B / m[alp]
    wp = sqrt( density[alp] * q[alp]^2 / (m[alp] * _e0) ) 
    vTh = sqrt(2*T_eV[alp]*_e/m[alp])

    lambda = _kPer^2 * vTh^2 / (2*wc^2)

    Ssum = dcomplexArr(NK)
    Dsum = dcomplexArr(NK)
    Psum = dcomplexArr(NK)

    eta_sum = dcomplexArr(NK)
    tau_sum = dcomplexArr(NK)
    eps_sum = dcomplexArr(NK)

    if arg_present(epsilon_swan_WD) then begin
        K0_HarmSum = dComplexArr(NK)
        K1_HarmSum = dComplexArr(NK)
        K2_HarmSum = dComplexArr(NK)
        K3_HarmSum = dComplexArr(NK)
        K4_HarmSum = dComplexArr(NK)
        K5_HarmSum = dComplexArr(NK)
    endif

    if arg_present(epsilon_swan_ND) then begin
        K0_HarmSum_ND = dComplexArr(NK)
        K1_HarmSum_ND = dComplexArr(NK)
        K2_HarmSum_ND = dComplexArr(NK)
        K3_HarmSum_ND = dComplexArr(NK)
        K4_HarmSum_ND = dComplexArr(NK)
        K5_HarmSum_ND = dComplexArr(NK)
    endif

    for n = -harmonicNumber,harmonicNumber do begin

        ; Brambilla expressions, pg 254-255

        _w = w

        x = (_w - n*wc) / (kPar * vTh)
        x0 = _w / (kPar * vTh)

        ZetaC = (nu_omg * w) / (kPar * vTh) ; Smithe modification
        Z = (kj_zfunction(x, Zp=Zp, ZetaC=ZetaC))[0]
        Zp = Zp[0]

        In = beselI(lambda, n, /double)
        Inp = kj_IPrime(lambda, n)

        Ssum += n^2 / lambda * In * exp( -lambda ) * (-x0 * Z )
        Dsum += n * ( Inp - In ) * exp(-lambda) * (-x0 * Z )
        Psum += In * exp(-lambda) * (x0 * x * Zp )

        eta_sum += n/lambda * In * exp(-lambda) * (x0^2 * Zp )
        tau_sum += ( Inp - In ) * exp(-lambda) * (-x0 * Z )
        eps_sum += ( Inp - In ) * exp(-lambda) * (x0^2 * Zp )

        ; Swanson expressions, pg 175-176

        if arg_present(epsilon_swan_WD) or arg_present(epsilon_swan_ND) then begin

            wc_swan = abs(wc)

            x = (w + n*wc_swan) / (kPar * vTh) 

            ZetaC = (nu_omg * w) / (kPar * vTh) ; Smithe modification
            Z_swan = (kj_zfunction(x, Zp=Zp_swan, ZetaC=ZetaC))[0]
            Zp_swan = Zp_swan[0]
            
            v0 = 0
            T_eV_Per = T_eV
            T_eV_Par = T_eV
            kz = kPar
            _f1 = ( 1.0 - kz * v0 / w )
            _f2 = kz * vTh / w * ( 1 - T_eV_Per / T_eV_Par )
            _f3 = _f1 * Z_swan  + _f2 * Zp_swan / 2.0

            _f4 = ( w + n * wc_swan ) / ( kz * vTh ) 
            _f5 = 1d0 + n * wc_swan / w * ( 1 - T_eV_Par / T_eV_Per ) 
            _f6 = 2 * n * wc_swan * T_eV_Par * v0 / ( w * T_eV_Per * vTh )
            _f7 = kz * vTh / ( w + n * wc_swan )

            _f9 = n * wc_swan * v0 / ( w * vTh )
            _f10 = T_eV_Per / T_eV_Par - n * wc_swan / w * ( 1.0 - T_eV_Per / T_eV_Par )

        endif

        if arg_present(epsilon_swan_WD) then begin
            K0_HarmSum += lambda * ( In - Inp ) * _f3
            K1_HarmSum += n^2 * In / lambda * _f3
            K2_HarmSum += n * ( In - Inp ) * _f3
            K3_HarmSum += In * _f4 * ( _f5 * Zp_swan + _f6 * ( Z_swan + _f7 ) ) 
            K4_HarmSum += n * In / lambda * ( _f9 * Z_swan + _f10 * Zp_swan / 2.0 ) 
            K5_HarmSum += ( In - Inp ) * ( _f9 * Z_swan + _f10 * Zp_swan / 2.0 )
        endif

        ; Swanson No Drift (ND) Case, pg 176
        if arg_present(epsilon_swan_ND) then begin
            K0_HarmSum_ND += lambda * ( In - Inp ) * Z_swan
            K1_HarmSum_ND += n^2 * In / lambda * Z_swan
            K2_HarmSum_ND += n * ( In - Inp ) * Z_swan
            K3_HarmSum_ND += In * x * Zp_swan 
            K4_HarmSum_ND += n * In / lambda * Zp_swan  
            K5_HarmSum_ND += ( In - Inp ) * Zp_swan 
        endif
    endfor 

    ; Brambilla

    Shat -= wp^2/_w^2 * Ssum
    Dhat += wp^2/_w^2 * Dsum
    Phat -= wp^2/_w^2 * Psum

    etaHat += wp^2/(_w*wc) * vth^2/_c^2 * eta_sum
    tauHat += wp^2/wc^2 * vth^2/_c^2 * tau_sum
    epsHat += wp^2/(_w*wc) * vTh^2/_c^2 * eps_sum

    ; Swanson

    if arg_present(epsilon_swan_WD) then begin

        _eps = atomicZ / abs(atomicZ) 
        _g1 = wp^2 * exp(-lambda) / ( w * kz * vTh )
        ; The factor of 2 is within the harmonic sum for _WD.
        _g2 = _kPer * wp^2 * exp(-lambda) / ( kz * w * wc_swan ) 
 
        K0 += 2 * _g1 * K0_HarmSum 
        K1 += _g1 * K1_HarmSum
        K2 += _ii * _eps * _g1 * K2_HarmSum 
        K3 -= _g1 * K3_HarmSum
        K4 += _g2 * K4_HarmSum
        K5 += _ii * _eps * _g2 * K5_HarmSum
    endif

    if arg_present(epsilon_swan_ND) then begin

        _eps = atomicZ / abs(atomicZ) 
        _g1 = wp^2 * exp(-lambda) / ( w * kz * vTh )
        _g2 = _kPer * wp^2 * exp(-lambda) / ( 2 * kz * w * wc_swan ) 
 
        K0_ND += 2 * _g1 * K0_HarmSum_ND
        K1_ND += _g1 * K1_HarmSum_ND
        K2_ND += _ii * _eps * _g1 * K2_HarmSum_ND 
        K3_ND -= _g1 * K3_HarmSum_ND
        K4_ND += _g2 * K4_HarmSum_ND
        K5_ND += _ii * _eps * _g2 * K5_HarmSum_ND
    endif

endfor

; Brambilla

etaHat = -etaHat/2.0
tauHat = -tauHat/2.0
epsHat = +epsHat/2.0

exx = SHat
exy = -_ii * DHat
exz = nPar * nPer * etaHat

eyx = +_ii * DHat
eyy = SHat - 2*nPer^2 * tauHat
eyz = +_ii * nPar * nPer * epsHat

ezx = nPar * nPer * etaHat
ezy = -_ii * nPar * nPer * epsHat
ezz = PHat

epsilon = dComplexArr(3,3,NK)

epsilon[0,0,*] = exx
epsilon[0,1,*] = exy
epsilon[0,2,*] = exz

epsilon[1,0,*] = eyx
epsilon[1,1,*] = eyy
epsilon[1,2,*] = eyz

epsilon[2,0,*] = ezx
epsilon[2,1,*] = ezy
epsilon[2,2,*] = ezz

; Swamson

if arg_present(epsilon_swan_WD) then begin

    epsilon_swan_WD = dComplexArr(3,3,NK)
    
    psi = acos ( kx / _kPer )
    
    swan_exx = K1 + sin(psi)^2 * K0
    swan_exy = K2 - cos(psi) * sin(psi) * K0
    swan_exz = cos(psi) * K4 + sin(psi) * K5
    
    swan_eyx = -K2 - cos(psi) * sin(psi) * K0
    swan_eyy = K1 + cos(psi)^2 * K0
    swan_eyz = sin(psi) * K4 - cos(psi) * K5
   
    swan_ezx = cos(psi) * K4 - sin(psi) * K5
    swan_ezy = sin(psi) * K4 + cos(psi) * K5
    swan_ezz = K3
    
    epsilon_swan_WD[0,0,*] = swan_exx
    epsilon_swan_WD[0,1,*] = swan_exy
    epsilon_swan_WD[0,2,*] = swan_exz
    
    epsilon_swan_WD[1,0,*] = swan_eyx
    epsilon_swan_WD[1,1,*] = swan_eyy
    epsilon_swan_WD[1,2,*] = swan_eyz
  
    epsilon_swan_WD[2,0,*] = swan_ezx
    epsilon_swan_WD[2,1,*] = swan_ezy
    epsilon_swan_WD[2,2,*] = swan_ezz

endif

; Swamson No Drifts ( kx = _kPer, ky = 0 )

if arg_present(epsilon_swan_ND) then begin

    epsilon_swan_ND = dComplexArr(3,3,NK)
    
    swan_ND_exx = K1_ND 
    swan_ND_exy = K2_ND 
    swan_ND_exz = K4_ND 
    
    swan_ND_eyx = -K2_ND
    swan_ND_eyy = K1_ND + K0_ND
    swan_ND_eyz = -K5_ND
    
    swan_ND_ezx = K4_ND
    swan_ND_ezy = K5_ND
    swan_ND_ezz = K3_ND
    
    epsilon_swan_ND[0,0,*] = swan_ND_exx
    epsilon_swan_ND[0,1,*] = swan_ND_exy
    epsilon_swan_ND[0,2,*] = swan_ND_exz
    
    epsilon_swan_ND[1,0,*] = swan_ND_eyx
    epsilon_swan_ND[1,1,*] = swan_ND_eyy
    epsilon_swan_ND[1,2,*] = swan_ND_eyz
    
    epsilon_swan_ND[2,0,*] = swan_ND_ezx
    epsilon_swan_ND[2,1,*] = swan_ND_ezy
    epsilon_swan_ND[2,2,*] = swan_ND_ezz

    ; ------------------------------------------------------
    ; Check to see if the Brambilla and Swansons dielectrics
    ; match.

    AA = epsilon_swan_ND
    BB = epsilon

    tol = 1e-8

    diff_re = abs((real_part(AA) - real_part(BB)))/abs(real_part(AA))
    iiZero = where(diff_re lt tol,iiCnt)
    diff_re[iiZero] = 0
    iiZero = where(abs((real_part(AA) - real_part(BB))) lt tol, iiCnt)
    diff_re[iiZero] = 0
    
    diff_im = abs((imaginary(AA) - imaginary(BB)))/abs(imaginary(AA))
    iiZero = where(diff_im lt tol,iiCnt)
    diff_im[iiZero] = 0
    iiZero = where(abs((imaginary(AA) - imaginary(BB))) lt tol, iiCnt)
    diff_im[iiZero] = 0
    
    iiInf = where(diff_re*0 ne 0,iiCntInf)
    if iiCntInf gt 0 then diff_re[iiInf] = 0
    
    iiInf = where(diff_im*0 ne 0,iiCntInf)
    if iiCntInf gt 0 then diff_im[iiInf] = 0

    iiBad_re = where(total(total(diff_re,1),1) ge tol,iiBadCnt_re)
    iiBad_im = where(total(total(diff_im,1),1) ge tol,iiBadCnt_im)

    if iiBadCnt_re gt 0 or iiBadCnt_im gt 0 then begin

        print, iiBadCnt_re, iiBadCnt_im
        print, ''
        print, '-------------'
        print, atomicZ, kPar

        print, AA[*,*,iiBad_re[0]]
        print, ''
        print, BB[*,*,iiBad_re[0]]

        print, ''
        print, AA[*,*,iiBad_im[0]]
        print, ''
        print, BB[*,*,iiBad_im[0]]

        print, iiBad_re[0], iiBad_im[0]

        stop
    endif
    
    ; ----------------------------------------------------------

endif

; Optionally also return the cold plasma epsilon

if arg_present(epsilon_cold) then begin

    epsilon_cold = dComplexArr(3,3,NK)

    for i=0,NK-1 do begin
        epsilon_cold[*,*,i] = kj_epsilon_cold( f, amu, atomicZ, B, density, nu_omg )
    endfor

endif

if total(epsilon) ne total(epsilon) then stop

return, epsilon

end

; Test Z function snippet 

pro kj_test_zfunction

    n = 200
    x = (dIndGen(n)/(n-1)-0.5)*2*120
    z = kj_zFun(x)
    zP = kj_zFunPrime(x)
    z2 = kj_zfunction(x,Zp=zP2)
    
    p=plot(x,z)
    p=plot(x,z2,/over, color='r')
    
    p=plot(x,imaginary(z),/over)
    p=plot(x,imaginary(z2),/over, color='r')
    
    p=plot(x,zP)
    p=plot(x,zP2,/over, color='r')
    
    p=plot(x,imaginary(zP),/over)
    p=plot(x,imaginary(zP2),/over, color='r')
    
    stop

end
