# logの実装試行錯誤

x = y * 2^e (eは整数, 1 <= y < 2)

と展開すると

log(x) = e log2 + log(y)

## 入力値の分解

xからyと整数eを得るには

```
union fi {
  float f;
  uint32_t i;
};

fi.f = x;
float e = int(fi.i >> 23) - 127;
fi.i = (fi.i & 0x7fffff) | (127 << 23);
float y = fi.f;
```

とする.
float eを作るところでintにしないとうまくfloatに変換できない.
AVXで使うために必要な定数は-127と127 << 23.

しかし

```
float e = (int(fi.i - (127 << 23))) >> 23;
```
とすると127 << 23の1個に減らせる.

## log(y)の計算

Maclaurin展開はlog(1 + x) = x - x^2/2 + x^3/3 + ...

expと違って係数が1ずつしか増えないので収束が遅いのが難.

## 逆数を使う

a = (y - √2) / (y + √2)

とすると|a| <= (√2 - 1)/(√2 + 1) = 0.1715...

y = sqrt(2) (1 + a) / (1 - a)

なので

log(y) = (1/2) log 2 + log((1 + a) / (1 - a))

するとlogの部分は偶数次が消えて7次で打ち切る.

log((1 + a) / (1 + a) = 2a(1 + a^2/3 + a^4/5 + a^6/7)

b = a^2とすると結局

log(x) = (e + 1/2) log2 + 2a(1 + b(1/3 + b(1/5 + b/7)))

となる.

## 逆数近似

```
t = rcp(x)
1/x = 2 * t - x t^2
```

を使う.

```
vrcp14ps(t, in);
vaddps(out, t, t);
vmulps(t, t, t);
vmulps(t, t, in);
vsubps(out, out, t);
```

mul + subpsをFMAに置き換えられるなら変える方がよい.

### 変形1

-1/x = -((x t) t - 2 * t)

とすれば

```
// inverseNeg
vrcp14ps(out, in);
vaddps(t, out, out);
vmulps(out, out, out);
vfmsub213ps(out, in, t);
```

とできる.
1/xの変わりに-1/xになるので後半で符号反転を吸収するように変形する.

コードはこんな感じ

```
// input zm0
vpsubd(zm1, zm0, i127shl23);
vpsrad(zm1, zm1, 23); // e
vcvtdq2ps(zm1, zm1); // float(e)
vpandd(zm0, zm0, x7fffff);
vpord(zm0, zm0, i127shl23); // y

vaddps(zm2, zm0, sqrt2); // y + sqrt2
inverseNeg(t1, zm2, t2); // t1 = -1/zm2
vfmadd213ps(zm1, log2, log2div2); // e

vsubps(zm0, sqrt2, zm0); // sqrt2 - y

vmulps(zm2, zm0, t1); // a = (y - sqrt2) / (y + sqrt2)
vmulps(t1, zm2, zm2); // b
vmovaps(zm0, logCoeff[3]);
vfmadd213ps(zm0, t1, logCoeff[2]);
vfmadd213ps(zm0, t1, logCoeff[1]);
vfmadd213ps(zm0, t1, logCoeff[0]);
vfmadd213ps(zm0, zm2, zm1);
```

約13clk/loop.
区間[1e-6, 4]でstep = 1e-6刻みでstd::logとの差の平均が2.023025e-08.

### 変形2

1/x = (2 - xt)t

とすれば定数2をレジスタに入れることでFMAを使える(by @k_nitadoriさん).

## 素直にMaclaurin展開

log(1+x)の展開は収束が遅いので使えないと思っていた.
しかしAgnerさんによるとvrcp14psのレイテンシは7なのでFMAが速いならありかもと試す.

log y (1<= y < 2)なのでa = (2/3)y- 1とすると|a| <= 1/3.

y = (3/2)(1 + a)なのでlog y = log(3/2) + log(1 + a)

12次の項はa^12/12 = 1.56e-7. このあたりで打ち切る.
14clk程度.

## 並列化

FMAは同時2ポート実行できるので

1 + a1 x + a2 x^2 + a3 x^3 + ... = (1 + a2 x^2 + a4 x^4 + ...) + x(a1 + a3 x^2 + a5 x^4 + ...)

と偶数奇数の項に分けて並列で計算したらどうだろう.

xx = x^2の計算と最後に(偶数項) + x(奇数項)の計算が増えるのでmulとFMAが1回ずつ増える.

10次より大きいと並列化の方が速くなった. 12clk/loop.
ただし気持ち精度が悪くなる.

## 係数の改善

(log(1+x)-x)/x^2をremezで最小化するほうがややよくなった.
9次まででも区間[1e-6, 4]でstep = 1e-6刻みでの誤差の平均が3.671254e-08.
これでもよさそう.
この場合並列化による恩恵よりもmulとFMAが1回ずつ増えるコストの方が大きかった.

更にこうするとlog(1 + x) = x + a2 x^2 + ...と1次の係数が1にしばれる.
よってa = (2/3)y - 1の変換係数の1を共有できる.

結局

```
vpsubd(zm1, zm0, i127shl23); // zm1 = x - (127 << 23)
vpsrad(zm1, zm1, 23); // e = zm1 >> 23
vcvtdq2ps(zm1, zm1); // float(e)
vpandd(zm0, zm0, x7fffff); // 仮数部取り出し
vpord(zm0, zm0, i127shl23); // y

vfmsub213ps(zm0, f2div3, logCoeff[0]); // a = y * (2/3) - 1
vfmadd213ps(zm1, log2, log1p5); // e = e * log(2) + log(1.5)
int logN = ConstVar::logN; // 9
vmovaps(zm2, logCoeff[logN - 1]);
for (int i = logN - 2; i >= 0; i--) {
    vfmadd213ps(zm2, zm0, logCoeff[i]);
}
vfmadd213ps(zm0, zm2, zm1); // log(x) = e * log(2) + log(1.5) + log(y)
```

が今のところ一番高速.
11clk/loop.
実装コードは[fmath2.hpp](https://github.com/herumi/fmath/blob/master/fmath2.hpp).