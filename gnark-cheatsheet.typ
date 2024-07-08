#set page(
  paper: "a4",
  margin: 1cm,
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
  #set text(30pt, weight: "regular")
  // #smallcaps(it.body)
  #it.body
]

#show heading.where(
  level: 2
): it => text(
  size: 16pt,
  weight: "regular",
  // style: "italic",
  it.body,
)

#show heading.where(
  level: 3
): it => block(width: 100%)[
  #set align(center)
  #set text(11pt, style: "italic", weight: "regular")
  --- #it.body ---
]

#import "@preview/codly:0.2.1": *

#show: codly-init.with()
#codly(languages: (
  // go: (name: "", icon:rect(),  color: rgb("#5daad4")),
  go: (name: "", icon:rect(),  color: luma(200)),
),
display-icon:false,
stroke-color: rgb("#CE412B"),
stroke-width: 0.5pt,
enable-numbers: false,
)

#show: rest => columns(3, gutter: 8pt, rest)

= cheat sheet

== Installing Gnark

```bash
go get github.com/consensys/gnark@latest
```

== Define circuit

```go
type Circuit struct {
    PreImage frontend.Variable
    Hash     frontend.Variable
                   `gnark:",public"`
}

func (c *Circuit) Define(
           api frontend.API) error {
    mimc, err := 
           mimc.NewMiMC(api.Curve())
    api.AssertIsEqual(c.Hash, 
          mimc.Hash(cs, c.PreImage))

    return nil
}
```

== Compile and prove

```go
var mimcCircuit Circuit
r1cs, err := frontend.Compile(
  ecc.BN254.ScalarField(),
  r1cs.NewBuilder, &mimcCircuit)

values := &Circuit{
    Hash: "1613...8469",
    PreImage: 35,
}
witness, _ := frontend.NewWitness(
    values, ecc.BN254.ScalarField())
publicWitness, _ := witness.Public()
pk, vk, err := groth16.Setup(r1cs)
proof, err := groth16.Prove(
                  r1cs, pk, witness)
err := groth16.Verify(
           proof, vk, publicWitness)
```

== Unit test

```go
assert := groth16.NewAssert(t)
var c Circuit

assert.ProverFailed(&c, &Circuit{
    Hash: 42,
    PreImage: 42,
})

assert.ProverSucceeded(&c, &Circuit{
    Hash: "1613...8469",
    PreImage: 35,
})
```

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

== Flow

Select if `b` is true, yields `i2` else yields `i2`
```go
func (cs *ConstraintSystem) Select(b Variable, i1, i2 interface{}) Variable
```


== Hints

```go
var b []frontend.Variable
var Σbi frontend.Variable
base := 1
for i := 0; i < nBits; i++ {
  b[i] = cs.NewHint(hint.IthBit, a, i)
  cs.AssertIsBoolean(b[i])
  Σbi = api.Add(Σbi, api.Mul(b[i], base))
  base = base << 1
}
cs.AssertIsEqual(Σbi, a)
```

== Debug

Run the program with `-tags=debug` to display a more verbose stack trace.

```go
api.Println("A.X", pubKey.A.X)
```

== Backends

=== Groth16

```go
pk, vk, _ := groth16.Setup(cs)
proof, _ := groth16.Prove(cs, pk, w)
err := groth16.Verify(proof, vk, pubw)
```

=== PlonK

```go
srs, lag, _ := unsafekzg.NewSRS(cs)
pk, vk, _ := plonk.Setup(cs, srs, lag)
proof, _ := plonk.Prove(cs, pk, w)
err := plonk.Verify(proof, vk, pubw)
```

== Export Solidity

```go
f, _ := os.Create("verifier.sol")
err = vk.ExportSolidity(f)
```

== Glossary

- `cs`: constraint system
- `w`: witness
- `pubw`: public witness
- `pk`: proving key
- `vk`: verifying key