#!/usr/bin/env python3
"""Freeze the common CLI bundle and corpus revisions before comparing Plurimath."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess


VARIANTS = [
    {"name": "baseline", "sha": "159172cd17d9ae0896f6504efd368459d05d34ef", "version": "0.11.9"},
    {"name": "pr486", "sha": "c806d05cdf44fb89ce94c4e34c4cc2f81cb92b6a", "version": "0.11.9"},
    {"name": "pr487", "sha": "43550d88cff7f7d62afd0486bf0794f2845b9f8c", "version": "0.11.9"},
]


def capture(*args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def cases_for(root, scope):
    cases = [{"name": "cli-suite", "kind": "suite"}, {"name": "focused", "kind": "focused"}]
    excluded = []
    samples = json.loads((root / ".github/workflows/samples-smoke-matrix.json").read_text())
    for sample in samples["flavor"]:
        flavor = sample["id"]
        if not sample.get("public", False):
            excluded.append({"name": "sample-" + flavor, "reason": "private corpus or private fonts"})
            continue
        if scope == "core" and flavor not in ("iso", "bipm"):
            excluded.append({"name": "sample-" + flavor, "reason": "outside selected core scope"})
            continue
        cases.append({"name": "sample-" + flavor, "kind": "sample", "repo": "metanorma/mn-samples-" + flavor,
                      "flavor": flavor, "experimental": sample.get("experimental", False)})
    templates = json.loads((root / ".github/workflows/templates-smoke-matrix.json").read_text())
    for template in templates["include"]:
        flavor, doctype = template["type"], template["doctype"]
        name = "template-" + flavor + "-" + doctype
        if scope == "core" and flavor != "iso":
            excluded.append({"name": name, "reason": "outside selected core scope"})
            continue
        cases.append({"name": name, "kind": "template", "repo": "metanorma/mn-templates-" + flavor,
                      "flavor": flavor, "doctype": doctype, "experimental": template.get("experimental", False)})
    return cases, excluded


def prepare(root, scope):
    directory = root / ".comparison"
    directory.mkdir(exist_ok=True)
    cases, excluded = cases_for(root, scope)
    manifest = {"schema": 1, "cli_sha": capture("git", "rev-parse", "HEAD", cwd=root),
                "cli_base": "31488e3e657940d0826cff152c9c71e2918a9b53", "ruby": "3.3",
                "scope": scope, "variants": VARIANTS, "cases": cases, "exclusions": excluded}
    for case in cases:
        if "repo" not in case:
            continue
        try:
            result = capture("git", "ls-remote", "https://github.com/" + case["repo"] + ".git", "HEAD")
            case["sha"] = result.split()[0]
            if len(case["sha"]) != 40:
                raise ValueError("Expected a full source commit")
        except (subprocess.CalledProcessError, IndexError, ValueError) as error:
            # Keep the target in the matrix: unavailable source is blocked coverage.
            case["pin_error"] = str(error)
    manifest_path = directory / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    plurimath = directory / "plurimath"
    subprocess.run(["git", "init", str(plurimath)], check=True)
    subprocess.run(["git", "-C", str(plurimath), "fetch", "--depth=1",
                    "https://github.com/plurimath/plurimath.git", VARIANTS[0]["sha"]], check=True)
    subprocess.run(["git", "-C", str(plurimath), "checkout", "--detach", "FETCH_HEAD"], check=True)
    gemfile = directory / "Gemfile"
    # Keep product files unchanged. This test-only bundle takes main's full
    # dependency set, normalizes its duplicate Isodoc branch declaration, and
    # includes Suma's existing compatibility fix before the first resolution.
    original = (root / "Gemfile").read_text()
    generated = original.replace('\ngemspec\n', '\ngemspec path: ".."\n')
    generated = generated.replace('branch: "rt-pubid-2-migration"', 'branch: "main"')
    generated += '\ngem "suma", github: "metanorma/suma", ref: "bca133cb830f51be3bca1b6239ab74233c977b86"\n'
    generated += 'gem "plurimath", path: "plurimath"\n'
    gemfile.write_text(generated)
    manifest["cli_gemfile_sha256"] = hashlib.sha256(original.encode()).hexdigest()
    manifest["test_bundle_prerequisites"] = {
        "suma": "bca133cb830f51be3bca1b6239ab74233c977b86",
        "isodoc_duplicate_branch": "main",
    }
    environment = dict(os.environ, BUNDLE_GEMFILE=str(gemfile), BUNDLE_APP_CONFIG=str(directory / "bundle-config"))
    with (directory / "resolve.log").open("w") as log:
        result = subprocess.run(["bundle", "lock", "--add-platform", "x86_64-linux"], cwd=root,
                                env=environment, stdout=log, stderr=subprocess.STDOUT)
    manifest["resolve_exit"] = result.returncode
    if result.returncode == 0:
        manifest["lock_sha256"] = hashlib.sha256((directory / "Gemfile.lock").read_bytes()).hexdigest()
        manifest["gemfile_sha256"] = hashlib.sha256(gemfile.read_bytes()).hexdigest()
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    if result.returncode:
        print((directory / "resolve.log").read_text())
        raise SystemExit(result.returncode)
    matrix = json.dumps({"case": [case["name"] for case in cases]}, separators=(",", ":"))
    output_path = os.environ.get("GITHUB_OUTPUT")
    if output_path:
        with open(output_path, "a") as output:
            output.write("matrix=" + matrix + "\n")
    print(json.dumps({"cases": len(cases), "excluded": excluded, "lock_sha256": manifest["lock_sha256"]}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scope", choices=("core", "all-public"), default="all-public")
    arguments = parser.parse_args()
    prepare(Path(__file__).resolve().parents[2], arguments.scope)
