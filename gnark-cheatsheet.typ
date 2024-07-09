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

#import "@preview/codly:0.2.1": *

#show: codly-init.with()
#codly(languages: (
  // go: (name: "", icon:rect(),  color: rgb("#5daad4")),
  go: (name: "", icon:rect(),  color: luma(200)),
),
display-icon:false,
stroke-color: rgb("#254cca"),
stroke-width: 0.5pt,
enable-numbers: false,
)

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

```bash
go get github.com/consensys/gnark@latest
```

\*`frontend.Variable` is abbreviated as `Var`

=== Define circuit

```go
type Circuit struct {
    PreImage Var
    Hash     Var `gnark:",public"`
}
func (c *Circuit) Define(
           api frontend.API) error {
    m, _ := mimc.NewMiMC(api.Curve())
    api.AssertIsEqual(c.Hash, 
          m.Hash(cs, c.PreImage))
}
```

=== Compile

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
// performs a 2-bit lookup
Lookup2(b0,b1 Var,i0,i1,i2,i3 Var) Var
```

=== Flow
```go
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
f, _ := mimc.NewMiMC(api.Curve())
h := f.Hash(cs, circuit.Data)
```

=== EdDSA Signature

```go
type Circuit struct {
    pub eddsa.PublicKey
    sig eddsa.Signature
    msg frontend.Variable
}
cur, _ := twistededwards.NewEdCurve(api.Curve())
c.PublicKey.Curve = cur
eddsa.Verify(cs, c.sig, c.msg, c.pub)
```

=== Merkle Proof

```go
type Circuit struct {
    Root         frontend.Variable
    Path, Helper []frontend.Variable
}
hFunc, _ := mimc.NewMiMC(api.Curve())
merkle.VerifyProof(cs, hFunc, c.Root, c.Path, c.Helper)
```

=== zk-SNARK Verifier

```go
type Circuit struct {
    InnerProof   Proof
    InnerVk      VerifyingKey
    PublicInputs []frontend.Variable
}
groth16.Verify(api, c.InnerVk, c.InnerProof, c.PublicInputs)
```

== Serialization

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

=== Export Solidity

```go
f, _ := os.Create("verifier.sol")
err = vk.ExportSolidity(f)
_p, _ := proof.(interface{MarshalSolidity() []byte})
proofStr := hex.EncodeToString(_p.MarshalSolidity())
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
  ]
)

#text(
  size: 7pt,
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
    $3n+m GG_1$,
    $2 GG_1 + 1 GG_2$,
    $3P + ell GG_1 exp$,
    [PlonK],
    $n+a GG_1+GG_2$,
    $9GG_1+7FF$,
    $2P+18GG_1 exp$,
    )
    \*$m=$wire num, $n=$multiplication gates, $a=$addition gates, $P=$pairing, $ell=$pub inputs num, PlonK is universal setup
  ]
  
)

=== Resources

- https://docs.gnark.consensys.io/

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