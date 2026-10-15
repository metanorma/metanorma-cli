# Plurimath downstream comparison

This test branch starts from CLI main at
`31488e3e657940d0826cff152c9c71e2918a9b53`. It replaces this branch's `rake`
workflow with a manual comparison; it does not publish, dispatch releases, or
run on branch pushes. Existing product Gemfiles and library code are unchanged.

Run the already registered workflow against this branch:

```sh
gh workflow run rake.yml --repo metanorma/metanorma-cli \
  --ref test/plurimath-downstream-verification --field scope=core
```

Use `scope=all-public` for the broader public matrix. Core has five targets:
the CLI suite, focused consumer probes, ISO and BIPM samples, and the ISO
template. All-public has 21 targets from the checked-in sample/template smoke
matrices. Both use Linux and Ruby 3.3, with at most two target jobs in parallel.
Private corpora/private fonts and other OS/Ruby combinations are excluded.
The CLI development bundle still requires the existing private-source read
credential; unavailable credentials are a setup failure.

Each target runs three exact Plurimath revisions serially:

| Arm | Commit |
|---|---|
| Baseline | `159172cd17d9ae0896f6504efd368459d05d34ef` |
| PR 486 | `c806d05cdf44fb89ce94c4e34c4cc2f81cb92b6a` |
| PR 487 | `43550d88cff7f7d62afd0486bf0794f2845b9f8c` |

Preparation resolves one common lock, pins corpus revisions, and saves both as
artifacts. The generated test-only Gemfile includes main's full development
stack. Its duplicate Isodoc declarations are normalized to main, and Suma's
existing SVG compatibility fix is pinned to
`bca133cb830f51be3bca1b6239ab74233c977b86`. These common prerequisites apply
equally to all arms; this is not a claim about the released dependency stack.
Every arm uses frozen installation and verifies the loaded Plurimath commit,
version, source location and common non-Plurimath dependency fingerprint.

The focused probes test real Standoc Asciidoctor conversion and the Html2Doc
MathML-to-OMML method boundary. They assert six negative-operand cases and eight
base/script cases independently of snapshots. Each PR must repair its own group
and introduce no new failing probe. The CLI suite and sample/template targets
separately exercise the CLI end to end.

Each target uploads `result.json`, `summary.md`, bounded logs, command exits,
provenance and generated math evidence. Matching baseline failures remain
blocked coverage; candidate-only failures are regression suspects requiring
reproduction. Other XML/OMML tree changes require review. A red target can thus
mean baseline failure, blocked setup, changed output, or a candidate failure;
read its summary rather than treating every red check as a regression.

Math-free or unparseable corpus outputs do not establish math compatibility.
Default-home CLI/Relaton caches may be shared within a target job, and remote
bibliography/font services can vary. Supported caches and working copies are
separate per arm. No Word visual or whole-release clearance follows from these
structural checks. No heavy builds are required locally before running GHA.
