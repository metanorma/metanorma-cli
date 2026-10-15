#!/usr/bin/env python3
"""Run three isolated downstream arms; failed or empty coverage never passes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import time

JOB_SECONDS = 9000
ARM_SECONDS = 2800
DEADLINE = None
import xml.etree.ElementTree as ET
import zipfile
from html.parser import HTMLParser

ARMS = ("baseline", "pr486", "pr487")
PINS = {"baseline": "159172cd17d9ae0896f6504efd368459d05d34ef",
        "pr486": "c806d05cdf44fb89ce94c4e34c4cc2f81cb92b6a",
        "pr487": "43550d88cff7f7d62afd0486bf0794f2845b9f8c"}
MATHML = "http://www.w3.org/1998/Math/MathML"
OMML = "http://schemas.openxmlformats.org/officeDocument/2006/math"


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False,
                                     separators=(",", ":")).encode()).hexdigest()


def file_sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def normalize_failure(text, roots=()):
    text = re.sub(r"\x1b\[[0-9;]*m", "", text)
    for root in sorted(map(str, roots), key=len, reverse=True):
        text = text.replace(root, "<WORK>")
    text = re.sub(r"\b[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\b", "<UUID>", text, flags=re.I)
    text = re.sub(r"\b\d{4}-\d\d-\d\d[T ]\d\d:\d\d:\d\d(?:\.\d+)?Z?", "<TIME>", text)
    text = re.sub(r"\b\d+(?:\.\d+)? seconds?\b", "<DURATION>", text)
    return "\n".join(line.rstrip() for line in text.splitlines()).strip()


def failure_evidence(result_path, log, roots=()):
    """Prefer actual example IDs and exceptions over noisy process output."""
    try:
        payload = json.loads(Path(result_path).read_text())
        failures = [{"id": e["id"], "exception": e.get("exception", {})}
                    for e in payload["examples"] if e.get("status") == "failed"]
        if failures:
            normalized = normalize_failure(json.dumps(failures, sort_keys=True), roots)
            return {"example_ids": sorted(e["id"] for e in failures),
                    "fingerprint": digest(normalized), "normalized": normalized}
    except (OSError, ValueError, KeyError, TypeError):
        pass
    lines = log.splitlines()
    focused = [line for line in lines if re.search(r"error|fatal|exception|failed|cannot|conflict", line, re.I)]
    normalized = normalize_failure("\n".join(focused[-40:] or lines[-40:]), roots)
    return {"example_ids": [], "fingerprint": digest(normalized), "normalized": normalized}


def tree(node):
    """Keep namespaces, attributes, text and CHILD ORDER; never sort operands."""
    return [node.tag, sorted(node.attrib.items()), node.text or "",
            [[tree(child), child.tail or ""] for child in node]]


class MathHTML(HTMLParser):
    """HTML fallback captures only complete math/oMath subtrees, in document order."""
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack, self.roots, self.errors = [], [], []

    def handle_starttag(self, tag, attrs):
        if self.stack or tag in ("math", "m:omath", "m:omathpara"):
            node = ET.Element(tag, dict(attrs))
            if self.stack:
                self.stack[-1].append(node)
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        self.handle_endtag(tag)

    def handle_endtag(self, tag):
        if not self.stack:
            return
        if self.stack[-1].tag != tag:
            self.errors.append("unbalanced math HTML: " + tag)
            return
        node = self.stack.pop()
        if not self.stack:
            self.roots.append(node)

    def handle_data(self, data):
        if self.stack:
            node = self.stack[-1]
            if len(node):
                node[-1].tail = (node[-1].tail or "") + data
            else:
                node.text = (node.text or "") + data


def extract_math(data, html=False):
    try:
        root = ET.fromstring(data)
        roots = []
        def visit(node):
            if node.tag in (f"{{{MATHML}}}math", f"{{{OMML}}}oMath", f"{{{OMML}}}oMathPara"):
                roots.append(tree(node))
            else:
                for child in node:
                    visit(child)
        visit(root)
        return roots, []
    except ET.ParseError as exc:
        if not html:
            return [], [str(exc)]
        parser = MathHTML()
        parser.feed(data.decode("utf-8", errors="replace") if isinstance(data, bytes) else data)
        if parser.stack:
            parser.errors.append("unclosed math HTML")
        return [tree(node) for node in parser.roots], parser.errors


def math_inventory(directory):
    files, errors = {}, []
    for path in sorted(Path(directory).rglob("*")):
        if not path.is_file():
            continue
        suffix = path.suffix.lower()
        if suffix not in (".xml", ".html", ".htm", ".doc", ".docx"):
            continue
        name = str(path.relative_to(directory))
        if suffix == ".docx":
            try:
                with zipfile.ZipFile(path) as archive:
                    members = [(n, archive.read(n)) for n in sorted(archive.namelist())
                               if n.startswith("word/") and n.endswith(".xml")]
            except (OSError, zipfile.BadZipFile) as exc:
                errors.append([name, str(exc)])
                continue
        else:
            members = [("", path.read_bytes())]
        for member, data in members:
            trees, failures = extract_math(data, html=suffix in (".html", ".htm", ".doc"))
            key = name + (":" + member if member else "")
            if trees:
                files[key] = {"count": len(trees), "sha256": digest(trees), "trees": trees}
            errors.extend([[key, failure] for failure in failures])
    return {"files": files, "math_count": sum(v["count"] for v in files.values()), "errors": errors}


def classify(baseline, candidate):
    if baseline.get("setup_error") or candidate.get("setup_error"):
        return "blocked_setup"
    if "exit" not in baseline or "exit" not in candidate:
        return "blocked_missing_arm"
    if baseline.get("timed_out") or candidate.get("timed_out"):
        return "blocked_timeout"
    if baseline["exit"] or candidate["exit"]:
        if baseline["exit"] and candidate["exit"]:
            a, b = baseline.get("failure", {}), candidate.get("failure", {})
            if a.get("fingerprint") and a["fingerprint"] == b.get("fingerprint"):
                return "pre_existing_failure_blocked_coverage"
            return "unresolved_different_failures"
        return "candidate_only_failure_regression_suspect" if candidate["exit"] else "baseline_failure_candidate_passed"
    if baseline.get("coverage_error") or candidate.get("coverage_error"):
        return "blocked_coverage"
    before, after = baseline.get("test_inventory"), candidate.get("test_inventory")
    if before is not None or after is not None:
        if not before or not after or before["ids"] != after["ids"]:
            return "blocked_test_inventory_drift"
        if set(after["pending"]) - set(before["pending"]):
            return "blocked_candidate_pending_regression"
    if baseline.get("math") != candidate.get("math"):
        return "output_change_needs_review"
    return "passed_exercised_scope"


def command(argv, cwd, env, prefix, timeout=3600):
    started = time.monotonic()
    if DEADLINE is not None:
        timeout = max(0.01, min(timeout, DEADLINE - started))
    prefix = Path(prefix)
    with prefix.with_suffix(".log").open("wb") as log:
        try:
            proc = subprocess.Popen(argv, cwd=cwd, env=env, stdout=log,
                                    stderr=subprocess.STDOUT, start_new_session=True)
            try:
                result = {"exit": proc.wait(timeout=timeout), "timed_out": False}
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGTERM)
                try:
                    proc.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    os.killpg(proc.pid, signal.SIGKILL)
                    proc.wait()
                result = {"exit": 124, "timed_out": True}
        except OSError as exc:
            log.write(str(exc).encode())
            result = {"exit": 127, "timed_out": False}
    result.update(command=argv, elapsed_seconds=round(time.monotonic()-started, 3))
    prefix.with_suffix(".json").write_text(json.dumps(result, indent=2))
    prefix.with_suffix(".exit").write_text(str(result["exit"]) + "\n")
    return result



def remaining_timeout(seconds):
    return max(0.01, min(seconds, DEADLINE - time.monotonic())) if DEADLINE is not None else seconds


def clone_at(repo, sha, target):
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("Expected immutable full Git SHA")
    if not re.fullmatch(r"[\w.-]+/[\w.-]+", repo):
        raise ValueError("Expected GitHub owner/repository")
    target.mkdir(parents=True, exist_ok=False)
    for argv in (["git", "init", "--quiet", str(target)],
                 ["git", "-C", str(target), "fetch", "--depth=1", "https://github.com/" + repo + ".git", sha],
                 ["git", "-C", str(target), "checkout", "--detach", "FETCH_HEAD"]):
        subprocess.run(argv, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=remaining_timeout(600))
    actual = subprocess.check_output(["git", "-C", str(target), "rev-parse", "HEAD"], text=True, timeout=remaining_timeout(30)).strip()
    if actual != sha:
        raise ValueError("Fetched source revision differs")
    # Gitlink revisions are pinned by the parent tree. Never use --remote.
    subprocess.run(["git", "-C", str(target), "submodule", "update", "--init", "--recursive", "--depth=1"],
                   check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=remaining_timeout(600))


def copy_cli(source, destination):
    destination.mkdir(parents=True, exist_ok=False)
    tracked = subprocess.check_output(["git", "-C", str(source), "ls-files", "-z"])
    for entry in tracked.decode().split("\0"):
        if not entry or entry.startswith(".comparison/"):
            continue
        relative = Path(entry)
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("Unsafe tracked path")
        origin, target = source / relative, destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if origin.is_symlink():
            link = os.readlink(origin)
            if Path(link).is_absolute() or not origin.resolve().is_relative_to(source):
                raise ValueError("External source symlink: " + entry)
            target.symlink_to(link)
        else:
            shutil.copy2(origin, target)


def focused_comparison(baseline, candidate, group):
    if baseline.get("setup_error") or candidate.get("setup_error"):
        return "blocked_setup"
    if baseline.get("timed_out") or candidate.get("timed_out"):
        return "blocked_timeout"
    expected_count = {"pr486": 6, "pr487": 8}[group]
    a, b = baseline.get("probes", {}).get("rows", []), candidate.get("probes", {}).get("rows", [])
    ids_a = [r.get("id") for r in a]
    ids_b = [r.get("id") for r in b]
    if (len(ids_a) != len(set(ids_a)) or len(ids_b) != len(set(ids_b)) or
            set(ids_a) != set(ids_b) or not ids_a):
        return "blocked_probe_coverage"
    groups_a = {r["id"]: r.get("group") for r in a}
    groups_b = {r["id"]: r.get("group") for r in b}
    targeted = [r for r in b if r.get("group") == group]
    if (groups_a != groups_b or len(targeted) != expected_count or
            any(sum(r.get("group") == name for r in b) != count
                for name, count in (("pr486", 6), ("pr487", 8)))):
        return "blocked_probe_coverage"
    if any(r.get("error") for r in a + b):
        return "blocked_probe_execution"
    # Any unaccounted process failure is still a failure, even if rows look green.
    for arm, rows in ((baseline, a), (candidate, b)):
        failed = {r["id"] for r in rows if r.get("passed") is not True}
        expected_exit = 1 if failed else 0
        if arm.get("exit") != expected_exit:
            return "blocked_probe_execution"
    if any(r.get("passed") is not True for r in targeted):
        return "candidate_targeted_failure"
    before = {r["id"] for r in a if r.get("passed") is not True}
    after = {r["id"] for r in b if r.get("passed") is not True}
    if after - before:
        return "candidate_only_failure_regression_suspect"
    return "passed_targeted_group_other_baseline_bugs_retained" if after else "passed_exercised_scope"


def run_case(case, cli, arm_dir, env, snapshot):
    result_path = arm_dir / "rspec.json"
    if case["kind"] == "suite":
        argv = ["bundle", "exec", "rspec", "spec", "--format", "documentation",
                "--format", "json", "--out", str(result_path)]
        cwd = cli
        outputs = cli
    elif case["kind"] == "focused":
        result_path = arm_dir / "probes.json"
        argv = ["bundle", "exec", "ruby", str(cli / ".github/scripts/plurimath_compare_probes.rb"),
                "--output", str(result_path)]
        cwd = cli
        outputs = cli
    else:
        input_dir = arm_dir / "input"
        if case["kind"] == "template":
            new = ["bundle", "exec", "metanorma", "new", str(input_dir), "--type", case["flavor"],
                   "--doctype", case["doctype"], "--template", str(snapshot)]
            generated = command(new, cli, env, arm_dir / "generate-template", 600)
            if generated["exit"] or not input_dir.is_dir() or not any(input_dir.rglob("*.adoc")):
                return {"setup_error": "Template generation failed or produced no AsciiDoc", "generation": generated}
        else:
            shutil.copytree(snapshot, input_dir, ignore=shutil.ignore_patterns(".git"))
        outputs = arm_dir / "artifacts"
        config = select_config(input_dir)
        argv = ["bundle", "exec", "metanorma", "site", "generate", str(input_dir),
                "--config", str(config), "--output-dir", str(outputs), "--strict", "--no-progress",
                "--agree-to-terms", "--install-fonts"]
        cwd = cli
    result = command(argv, cwd, env, arm_dir / "scenario", case.get("timeout", 1800))
    if case["kind"] in ("sample", "template"):
        result["input_config"] = {"path": str(config.relative_to(input_dir)), "sha256": file_sha(config),
                                  "source_repo": case["repo"], "source_sha": case["sha"]}
    log = (arm_dir / "scenario.log").read_text(errors="replace")
    result["failure"] = failure_evidence(result_path, log, (cli, arm_dir)) if result["exit"] else None
    if case["kind"] == "focused":
        try:
            result["probes"] = json.loads(result_path.read_text())
        except (OSError, ValueError) as exc:
            result["coverage_error"] = "Missing/invalid focused output: " + str(exc)
    elif case["kind"] == "suite":
        try:
            payload = json.loads(result_path.read_text())
            result["rspec_summary"] = payload["summary"]
            result["test_inventory"] = suite_inventory(payload)
            if not result["test_inventory"]["exercised"]:
                result["coverage_error"] = "Suite exercised zero examples (empty or all pending)"
        except (OSError, ValueError, KeyError) as exc:
            result["coverage_error"] = "Missing/invalid RSpec output: " + str(exc)
    else:
        inventory = math_inventory(outputs)
        (arm_dir / "math-inventory.json").write_text(json.dumps(inventory, indent=2))
        result["math"] = inventory
        if inventory["errors"] or inventory["math_count"] == 0:
            result["coverage_error"] = "Unparseable generated artifacts or no actual MathML/OMML"
    return result



def select_config(directory):
    for name in ("metanorma.test.yml", "metanorma.yml"):
        candidate = Path(directory) / name
        if candidate.is_file():
            return candidate
    raise ValueError("No metanorma.test.yml or metanorma.yml smoke configuration")


def suite_inventory(payload):
    examples = payload["examples"]
    ids = [e["id"] for e in examples]
    if len(ids) != len(set(ids)):
        raise ValueError("Duplicate RSpec example IDs")
    counts = {status: sum(e["status"] == status for e in examples)
              for status in ("passed", "failed", "pending")}
    return {"ids": sorted(ids), "pending": sorted(e["id"] for e in examples if e["status"] == "pending"),
            "counts": counts, "exercised": counts["passed"] + counts["failed"]}


def redact(text):
    for key, value in os.environ.items():
        if len(value) >= 8 and re.search(r"token|secret|password|credential|private.key", key, re.I):
            text = text.replace(value, "<REDACTED>")
    text = re.sub(r"https?://[^/\s:@]+:[^/\s@]+@", "https://<REDACTED>@", text)
    text = re.sub(r"\b(?:gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+)\b", "<REDACTED>", text)
    return text


def export_evidence(root, output, max_file=25*1024*1024, max_total=250*1024*1024):
    """Export only evidence and generated public documents, never bundles/input code."""
    copied, skipped, total = [], [], 0
    for name in ARMS:
        arm = root / name
        if not arm.is_dir():
            continue
        candidates = [path for suffix in (".log", ".exit", ".json", ".xml", ".html", ".htm", ".doc", ".docx")
                      for path in arm.glob("*" + suffix)]
        artifacts = arm / "artifacts"
        if artifacts.is_dir():
            candidates += [p for p in artifacts.rglob("*") if p.suffix.lower() in
                           (".xml", ".html", ".htm", ".doc", ".docx")]
        for path in sorted(set(candidates)):
            if not path.is_file() or path.is_symlink():
                continue
            relative = path.relative_to(root)
            size = path.stat().st_size
            if size > max_file or total + size > max_total:
                skipped.append(str(relative))
                continue
            destination = output / "evidence" / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            if path.suffix.lower() in (".docx", ".doc"):
                shutil.copy2(path, destination)
            else:
                destination.write_text(redact(path.read_text(errors="replace")))
            copied.append(str(relative))
            total += size
    return {"copied": copied, "skipped_size_limit": skipped, "source_bytes": total,
            "max_file_bytes": max_file, "max_total_bytes": max_total}


def render_summary(report):
    lines = ["## Plurimath downstream comparison: " + report["case"], "",
             "| Candidate | Result |", "|---|---|"]
    for name, status in report["comparisons"].items():
        lines.append("| " + name + " | " + status + " |")
    if report.get("setup_error"):
        lines.extend(["", "Setup blocked: " + report["setup_error"]])
    lines.extend(["", report.get("qualification", ""), "",
                  "Failed, changed-output, and empty-math scenarios are not verified passes.", ""])
    return redact("\n".join(lines))


def verify_provenance(provenance, variant, expected_source, baseline_fingerprint=None):
    actual = provenance["plurimath"]
    if actual["sha"] != variant["sha"] or actual["version"] != variant["version"]:
        raise ValueError("Loaded Plurimath SHA/version differs")
    if Path(actual["source"]).resolve() != Path(expected_source).resolve():
        raise ValueError("Wrong Plurimath source loaded")
    fingerprint = provenance["dependency_fingerprint"]
    if not fingerprint or (baseline_fingerprint is not None and fingerprint != baseline_fingerprint):
        raise ValueError("Non-Plurimath runtime dependency drift")
    return fingerprint


def run(args):
    global DEADLINE
    job_deadline = time.monotonic() + JOB_SECONDS
    DEADLINE = job_deadline
    source = Path(__file__).resolve().parents[2]
    manifest_path = source / ".comparison/manifest.json"
    args.output = args.output.resolve()
    args.output.mkdir(parents=True, exist_ok=True)
    report_path = args.output / "result.json"
    report = {"case": args.case, "arms": {}, "comparisons": {}, "scope": "selected pinned downstream scenario"}
    try:
        manifest = json.loads(manifest_path.read_text())
        if manifest["schema"] != 1:
            raise ValueError("Unknown manifest schema")
        variants = {v["name"]: v for v in manifest["variants"]}
        if set(variants) != set(ARMS) or len(manifest["variants"]) != len(ARMS):
            raise ValueError("Manifest requires exactly baseline, pr486 and pr487")
        if any(variants[name]["sha"] != PINS[name] for name in ARMS):
            raise ValueError("Manifest changes the fixed comparison commits")
        cases = [c for c in manifest["cases"] if c["name"] == args.case]
        if len(cases) != 1:
            raise ValueError("Case missing or duplicated")
        case = cases[0]
        if case["kind"] not in ("suite", "focused", "sample", "template"):
            raise ValueError("Unknown case kind")
        head = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True, timeout=remaining_timeout(30)).strip()
        if head != manifest["cli_sha"]:
            raise ValueError("CLI source HEAD differs from prepared artifact")
        common = source / ".comparison"
        if file_sha(common / "Gemfile.lock") != manifest["lock_sha256"]:
            raise ValueError("Prepared common lock hash differs")
        gemfile_sha = file_sha(common / "Gemfile")
        if gemfile_sha != manifest["gemfile_sha256"]:
            raise ValueError("Prepared Gemfile hash differs")
        root = args.work_root.resolve()
        root.mkdir(parents=True, exist_ok=False)
        report["manifest"] = manifest
        report["qualification"] = ("Supported Bundler/XDG caches are per-arm. Default-home CLI and "
            "Relaton caches may be shared within the job; no runtime path hooks are applied. "
            "Candidate-only failures require reproduction before attributing root cause.")
        snapshot = None
        if case["kind"] in ("sample", "template"):
            snapshot = root / "snapshot"
            if case.get("pin_error") or not case.get("sha"):
                raise ValueError("Source pin unavailable: " + str(case.get("pin_error", case["repo"])))
            clone_at(case["repo"], case["sha"], snapshot)
        fingerprints = {}
        for name in ARMS:
            variant = variants[name]
            DEADLINE = min(job_deadline, time.monotonic() + ARM_SECONDS)
            arm_dir = root / name
            arm_dir.mkdir()
            cli = arm_dir / "cli"
            try:
                copy_cli(source, cli)
                comp = cli / ".comparison"
                comp.mkdir()
                for filename in ("Gemfile", "Gemfile.lock"):
                    shutil.copy2(common / filename, comp / filename)
                clone_at("plurimath/plurimath", variant["sha"], comp / "plurimath")
                env = os.environ.copy()
                env.update(BUNDLE_GEMFILE=str(comp / "Gemfile"), BUNDLE_FROZEN="true",
                           BUNDLE_PATH=str(arm_dir / "bundle"), BUNDLE_APP_CONFIG=str(arm_dir / "bundle-config"),
                           BUNDLE_USER_HOME=str(arm_dir / "bundler"), GEM_SPEC_CACHE=str(arm_dir / "gem-spec-cache"),
                           XDG_CACHE_HOME=str(arm_dir / "cache"), XDG_CONFIG_HOME=str(arm_dir / "config"),
                           XDG_DATA_HOME=str(arm_dir / "data"), GIT_TERMINAL_PROMPT="0")
                installed = command(["bundle", "install", "--jobs", "2", "--retry", "1"], cli, env, arm_dir / "install", 1800)
                if installed["exit"]:
                    raise ValueError("Frozen bundle installation failed; see install.log")
                probe = command(["bundle", "exec", "ruby", str(cli / ".github/scripts/plurimath_compare_provenance.rb"), str(arm_dir / "loaded-provenance.json")],
                                cli, env, arm_dir / "provenance", 120)
                if probe["exit"]:
                    raise ValueError("Loaded dependency provenance failed")
                provenance = json.loads((arm_dir / "loaded-provenance.json").read_text())
                fingerprints[name] = verify_provenance(provenance, variant, comp / "plurimath",
                    fingerprints.get("baseline") if name != "baseline" else None)
                result = run_case(case, cli, arm_dir, env, snapshot)
                if file_sha(comp / "Gemfile.lock") != manifest["lock_sha256"] or file_sha(comp / "Gemfile") != gemfile_sha:
                    raise ValueError("Gemfile/lock changed during execution")
                result.update(provenance=provenance, lock_sha256=manifest["lock_sha256"], gemfile_sha256=gemfile_sha)
                report["arms"][name] = result
            except (OSError, ValueError, subprocess.SubprocessError) as exc:
                report["arms"][name] = {"setup_error": str(exc)}
            report_path.write_text(redact(json.dumps(report, indent=2)))
        baseline = report["arms"].get("baseline", {})
        for name in ARMS[1:]:
            candidate = report["arms"].get(name, {})
            report["comparisons"][name] = (focused_comparison(baseline, candidate, name)
                if case["kind"] == "focused" else classify(baseline, candidate))
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as exc:
        report["setup_error"] = str(exc)
    report_path.write_text(redact(json.dumps(report, indent=2)))
    if "root" in locals() and root.is_dir():
        report["evidence_export"] = export_evidence(root, args.output)
        report_path.write_text(redact(json.dumps(report, indent=2)))
    summary = render_summary(report)
    (args.output / "summary.md").write_text(summary)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as handle:
            handle.write(summary)
    statuses = report["comparisons"].values()
    success = len(report["comparisons"]) == 2 and all(status.startswith("passed_") for status in statuses)
    print(json.dumps({"case": args.case, "comparisons": report["comparisons"], "output": str(args.output)}))
    return 0 if success and not report.get("setup_error") else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", required=True)
    parser.add_argument("--work-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    return run(args)


if __name__ == "__main__":
    sys.exit(main())
