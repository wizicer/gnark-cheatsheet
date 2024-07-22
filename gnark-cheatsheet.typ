#set document(title: "gnark cheatsheet", author: "Icer Liang @wizicer")

#set page(
  paper: "a4",
  margin: (x: 1cm, top: 1cm, bottom: 1cm),
  // header: align()[
  //   A fluid dynamic model for
  //   glacier flow
  // ],
  // numbering: "1",
)
// #set par(justify: true)
#set text(
  size: 9pt,
)

#show heading.where(
  level: 1
): it => block(width: 100%)[
  #set align(center)
  #set text(22pt, font: "Bodoni 72 Smallcaps", weight: "semibold")
  // #set text(22pt, font: "Encode Sans Condensed", weight: "regular")
  // #smallcaps(it.body)
  #underline(stroke: 8pt + rgb(37, 76, 202, 50), offset: -1pt, evade: false, [#it.body])
  
]

#show heading.where(
  level: 2
): it => text(
  size: 16pt,
  weight: "regular",
  font: "Arial",
  // style: "italic",
  it.body,
)

#show heading.where(
  level: 3
): it => block(width: 100%, height: 6pt)[
  #set align(center)
  #set text(11pt, 
    font: "Arial", 
    fill: rgb("#284ecb").darken(20%),
    style: "italic",
    weight: "regular")
  --- #it.body ---
]

#import "@preview/codly:1.0.0": *

#show: codly-init.with()
#codly(languages: (
  // go: (name: "", icon:rect(),  color: rgb("#5daad4")),
  go: (name: "", icon:rect(),  color: luma(200)),
),
display-icon: false,
number-format: none,
zebra-fill: rgb("#f9f9f9"),
// lang-format: none,
)

#let in_circuit_color = 0.5pt + rgb("#254cca")
#let out_circuit_color = 0.5pt + rgb("#29851c")

#show: rest => columns(3, gutter: 8pt, rest)

#figure(
  placement: bottom,
  box(
    width: 100%,
    inset: 2pt,
    [
      #set align(start)
      Made by #link("https://zkshanghai.xyz")[Icer Liang],
      #datetime.today().display().

      Inspired by #link("https://golang.sk/images/blog/cheatsheets/go-cheat-sheet.pdf")[golang.sk]
    ]
  ),
)

= Gnark Cheat Sheet

// == Concepts

// === zk-SNARK and gnark

// #text(
//   size:7pt,
// [
// A zk-SNARK is a cryptographic construction that allows you to provide a proof of knowledge (Argument of Knowledge) of secret inputs satisfying a public mathematical statement, without leaking any information on the inputs (Zero Knowledge).

// With `gnark`, you can write any circuit using the gnark API.
// An instance of such a circuit is 
// $op("hash")(x)=y$, where $y$ is public and $x$ secret.
// ]
// )

== Getting started

=== Installing Gnark

#codly(stroke: out_circuit_color)
```sh
go get github.com/consensys/gnark@latest
```

\*`frontend.Variable` is abbreviated as `Var`
#codly(display-name: false)

=== Define Circuit

#codly(stroke: in_circuit_color)
```go
import "github.com/consensys/gnark/frontend"
type Circuit struct {
    PreImage Var `gnark:",secret"`
    Hash     Var `gnark:"hash,public"`
}
func (c *Circuit) Define(
           api frontend.API) error {
    m, _ := mimc.NewMiMC(api)
    m.Write(c.PreImage)
    api.AssertIsEqual(c.Hash, m.Sum())
}
```

=== Compile

#codly(stroke: out_circuit_color)
```go
var mimcCircuit Circuit
cur := ecc.BN254.ScalarField()
r1cs, err := frontend.Compile(
  cur, r1cs.NewBuilder, &mimcCircuit)
vals := &Circuit { Hash: "161...469", PreImage: 35 }
w, _ := frontend.NewWitness(vals, cur)
pubw, _ := w.Public()
```

=== Prove: Groth16

```go
pk, vk, _ := groth16.Setup(cs)
proof, _ := groth16.Prove(cs, pk, w)
err := groth16.Verify(proof, vk, pubw)
```

=== Prove: PlonK

```go
srs, lag, _ := unsafekzg.NewSRS(cs)
pk, vk, _ := plonk.Setup(cs, srs, lag)
proof, _ := plonk.Prove(cs, pk, w)
err := plonk.Verify(proof, vk, pubw)
```

== API

#codly(stroke: in_circuit_color)

=== Assertions

```go
// fails if i1 != i2
AssertIsEqual(i1, i2 Var)
// fails if i1 == i2
AssertIsDifferent(i1, i2 Var)
// fails if v != 0 and v != 1
AssertIsBoolean(i1 Var)
// fails if v ∉ {0,1,2,3}
AssertIsCrumb(i1 Var)
// fails if v > bound.
AssertIsLessOrEqual(v Var, bound Var)
```

#colbreak()

=== Arithemetics

```go
// = i1 + i2 + ... in
Add(i1, i2 Var, in ...Var) Var
// a = a + (b * c)
MulAcc(a,b, c Var) Var
Neg(i1 Var) Var // -i. 
// = i1 - i2 - ... in
Sub(i1, i2 Var, in ...Var) Var
// = i1 * i2 * ... in
Mul(i1, i2 Var, in ...Var) Var
// i1 /i2. =0 if i1 = i2 = 0
DivUnchecked(i1, i2 Var) Var
Div(i1, i2 Var) Var // = i1 / i2
Inverse(i1 Var) Var // = 1 / i1
```

=== Binary
```go
// unpacks to binary (lsb first)
ToBinary(i1 Var, n ...int) []Var
// packs b to element (lsb first)
FromBinary(b ...Var) Var
// following a and b must be 0 or 1
Xor(a, b Var) Var // a ^ b
Or(a, b Var) Var // a | b
And(a, b Var) Var // a & b
```

=== Flow
```go
// performs a 2-bit lookup
Lookup2(b0,b1 Var,i0,i1,i2,i3 Var) Var
// if b is true, yields i1 else i2
Select(b Var, i1, i2 Var) Var
// returns 1 if a is zero, 0 otherwise
IsZero(i1 Var) Var
// 1 if i1>i2, 0 if i1=i2, -1 if i1<i2
Cmp(i1, i2 Var) Var
```

=== Debug

Run the program with `-tags=debug` to display a more verbose stack trace.

```go
Println(a ...Var) //like fmt.Println
```

// === Advanced

// ```go
// // for advanced circuit development
// Compiler() Compiler
// ```

// ```go
// // NewHint is a shortcut to api.Compiler().NewHint()
// // Deprecated: use api.Compiler().NewHint() instead
// NewHint(f solver.Hint, nbOutputs int, inputs ...Variable) ([]Variable, error)

// // ConstantValue is a shortcut to api.Compiler().ConstantValue()
// // Deprecated: use api.Compiler().ConstantValue() instead
// ConstantValue(v Variable) (*big.Int, bool)
// ```

== Standard library

=== MiMC Hash

```go
import "github.com/consensys/gnark/std/hash/mimc"
fMimc, _ := mimc.NewMiMC()
fMimc.Write(circuit.Data)
h := fMimc.Sum()
```

=== EdDSA Signature

```go
import t "github.com/consensys/gnark-crypto/ecc/twistededwards"
import te "github.com/consensys/gnark/std/algebra/native/twistededwards"
type Circuit struct {
    pub eddsa.PublicKey
    sig eddsa.Signature
    msg frontend.Variable
}
cur, _ := te.NewEdCurve(api, t.BN254)
eddsa.Verify(cur, c.sig, c.msg, c.pub, &fMimc)
```

#colbreak()

=== Merkle Proof

```go
import "github.com/consensys/gnark/std/accumulator/merkle"
type Circuit struct {
	M    merkle.MerkleProof
	Leaf frontend.Variable
}
c.M.VerifyProof(api, &hFunc, c.Leaf)
```

== Selector

```go
import "github.com/consensys/gnark/std/selector"
```

=== Slice

```go
// out[i] = i ∈ [s, e) ? in[i] : 0
Slice(s, e Var, in []Var) []Var
// out[i] = rs ? (i ≥ p ? in[i] : 0)
//             : (i < p ? in[i] : 0)
Partition(p Var, rs bool, in []Var) []Var
// out[i] = i < sp ? sv : ev
stepMask(outlen int, sp, sv, ev Var) []Var
```

=== Mux

```go
// out = in[b[0]+b[1]*2+b[2]*4+...]
BinaryMux(selBits, in []Var) Var
// out = vs[i] if ks[i] == qkey
Map(qkey Var, ks, vs []Var) Var
// out = in[sel]
Mux(sel Var, in ...Var) Var
// out[i] = ks[i] == k ? 1 : 0
KeyDecoder(k Var, ks []Var) []Var
// out[i] = i == s ? 1 : 0
Decoder(n int, sel Var) []Var
// out = a1*b1 + a2*b2 + ...
dotProduct(a, b []Var) Var
```

== Concepts
=== Glossary

`cs`: constraint system, 
`w`: (full) witness, 
`pubw`: public witness, 
`pk`: proving key, 
`vk`: verifying key, 
`r1cs`: rank-1 constraint system, 
`srs`: structured reference string.

=== Schemas

#text(
  size: 8pt,
  [
    $
    "R1CS: "
    cal(L) arrow(x) dot cal(R) arrow(x) = cal(O) arrow(x)
    $

    $
    "PlonK: "
    q_l_i a_i + q_r_i b_i + q_o_i c_i + q_m_i a_i b_i + q_c_i = 0
    $

    $
    "SAP: "
    x dot y = (x\/2 + y\/2)^2 -(x\/2 - y \/2)^2
    $
  ]
)

#let m1=math.op($bold(m_1)$)
#let m2=math.op($bold(m_2)$)

#text(
  size: 6pt,
  [
    #table(
    columns: (auto, auto, auto, auto),
    inset: 3pt,
    align: horizon,
    stroke: 0.5pt + rgb("#bbb"),
    table.header(
      [*Schema*],
      [*CRS/SRS*],
      [*Proof Size*],
      [*Verifier Work*],
    ),
    [Groth16],
    $(3n+m) GG_1$,
    $2 GG_1 + 1 GG_2$,
    $3P + ell m1$,
    [PlonK],
    $(n+a) GG_1+GG_2$,
    $9GG_1+7FF$,
    $2P+18 m1$,
    [Polymath],
    $(tilde(m) + 12 tilde(n)) GG_1$,
    $3 GG_1+1FF$,
    $2P + 2 m1 + m2 + tilde(ell) FF$,
    )
    \*$m=$wire num, $n=$multiplication gates,
    $tilde(m) approx 2m$, $tilde(n) approx 2n$,
    $bold(m_L) = GG_L exp$.
    $a=$addition gates, $P=$pairing, $ell=$pub inputs num, $tilde(ell) = O(ell log ell)$ PlonK is universal setup
  ]
  
)

// REF: Gabizon, Ariel, Zachary J. Williamson, and Oana Ciobotaru. “PLONK: Permutations over Lagrange-Bases for Oecumenical Noninteractive Arguments of Knowledge,” 2019. https://eprint.iacr.org/2019/953.

=== Resources

- https://docs.gnark.consensys.io/
- https://play.gnark.io/
- https://zkshanghai.xyz/

#colbreak()

== Serialization

#codly(stroke: out_circuit_color)

// === Serialization

// ```go
// cur := ecc.BN254
// // CS Serialize
// var buf bytes.Buffer
// cs.WriteTo(&buf)
// // CS Deserialize
// cs := groth16.NewCS(cur)
// cs.ReadFrom(&buf)
// // Witness Serialize
// w, _ := frontend.NewWitness(&val, cur)
// data, _ := w.MarshalBinary()
// json, _ := w.MarshalJSON()
// // Witness Deserialize
// w, _ := witness.New(cur)
// err := w.UnmarshalBinary(data)
// w, _ := witness.New(cur, ccs.GetSchema())
// err := w.UnmarshalJSON(json)
// pubw, _ := witness.Public()
// ```
=== CS Serialize

```go
var buf bytes.Buffer
cs.WriteTo(&buf)
```

=== CS Deserialize

```go
cs := groth16.NewCS(ecc.BN254)
cs.ReadFrom(&buf)
```

=== Witness Serialize

```go
w, _ := frontend.NewWitness(&assignment, ecc.BN254)
data, _ := w.MarshalBinary()
json, _ := w.MarshalJSON()
```

=== Witness Deserialize

```go
w, _ := witness.New(ecc.BN254)
err := w.UnmarshalBinary(data)
w, _ := witness.New(ecc.BN254, ccs.GetSchema())
err := w.UnmarshalJSON(json)
pubw, _ := witness.Public()
```

== Smart Contract

=== Export Solidity

```go
f, _ := os.Create("verifier.sol")
err = vk.ExportSolidity(f)
```

=== Export Plonk Proof

```go
_p, _ := proof.(interface{MarshalSolidity() []byte})
str := "0x" + hex.EncodeToString(
  _p.MarshalSolidity())
```

=== Export Groth16 Proof

```go
buf := bytes.Buffer{}
_, err := proof.WriteRawTo(&buf)
b := buf.Bytes()
var p [8]string
for i := 0; i < 8; i++ {
  p[i] = new(big.Int).SetBytes(
    b[32*i : 32*(i+1)]).String()
}
str := "["+strings.Join(p[:],",")+"]"
```

== Standard library

=== MiMC Hash

```go
import "github.com/consensys/gnark-crypto/ecc/bn254/fr/mimc"
fMimc := mimc.NewMiMC()
fMimc.Write(buf)
h := fMimc.Sum(nil)
```

=== EdDSA Signature

```go
import "math/rand"
import t "github.com/consensys/gnark-crypto/ecc/twistededwards"
import "github.com/consensys/gnark-crypto/hash"
curve := t.BN254
ht := hash.MIMC_BN254
seed := time.Now().Unix()
rnd := rand.New(rand.NewSource(seed))
s, _ := eddsa.New(curve, rnd)
sig, _ := s.Sign(msg, ht.New())
pk := s.Public()
v, _ := s.Verify(sig, msg, ht.New())
c.PublicKey.Assign(curve, pk.Bytes())
c.Signature.Assign(curve, sig)
```

=== Merkle Proof

```go
import mt "github.com/consensys/gnark-crypto/accumulator/merkletree"
depth := 5
num := uint64(2 << (depth - 1))
seg := 32
mod := ecc.BN254.ScalarField()
// Create tree by random data
mlen := len(mod.Bytes())
var buf bytes.Buffer
for i := 0; i < int(num); i++ {
  leaf, _:= rand.Int(rand.Reader, mod)
  b := leaf.Bytes()
  buf.Write(make([]byte, mlen-len(b)))
  buf.Write(b)
}
// build merkle tree proof and verify
hGo := hash.MIMC_BN254.New()
idx := uint64(1)
root, path, _, _ := mt.BuildReaderProof(&buf, hGo, seg, idx)
verified := mt.VerifyProof(hGo, root, path, idx, num)
c.Leaf = idx
c.M.RootHash = root
c.M.Path = make([]Var, depth+1)
for i := 0; i < depth+1; i++ {
  c.M.Path[i] = path[i]
}
```

// == Unit test

// ```go
// assert := groth16.NewAssert(t)
// var c Circuit

// assert.ProverFailed(&c, &Circuit{
//     Hash: 42,
//     PreImage: 42,
// })

// assert.ProverSucceeded(&c, &Circuit{
//     Hash: "1613...8469",
//     PreImage: 35,
// })
// ```

// == Hints

// ```go
// var b []frontend.Variable
// var Σbi frontend.Variable
// base := 1
// for i := 0; i < nBits; i++ {
//   b[i] = cs.NewHint(hint.IthBit, a, i)
//   cs.AssertIsBoolean(b[i])
//   Σbi = api.Add(Σbi, api.Mul(b[i], base))
//   base = base << 1
// }
// cs.AssertIsEqual(Σbi, a)
// ```


// TODO: how to convert byte[] to number to equal to number in-circuit print by api.Println

// TODO: selctor under github.com/consensys/gnark/std/selector