#!/usr/bin/env python3
"""Safety and decision tests: synthetic inputs only, no Ruby/network/builds."""
import importlib.util
import json
from pathlib import Path
import tempfile
from unittest.mock import patch
import unittest
import zipfile

SPEC = importlib.util.spec_from_file_location("comparison", Path(__file__).with_name("plurimath_compare_run.py"))
m = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(m)


class Decisions(unittest.TestCase):
    def test_failure_does_not_become_success_when_shared(self):
        failed = {"exit": 1, "failure": {"fingerprint": "same"}}
        self.assertEqual(m.classify(failed, failed), "pre_existing_failure_blocked_coverage")
        self.assertEqual(m.classify(failed, {"exit": 1, "failure": {"fingerprint": "different"}}),
                         "unresolved_different_failures")
        self.assertEqual(m.classify({"exit": 0}, failed), "candidate_only_failure_regression_suspect")

    def test_missing_setup_timeout_and_no_math_block(self):
        for candidate, expected in (({}, "blocked_missing_arm"),
                                    ({"setup_error": "drift"}, "blocked_setup"),
                                    ({"exit": 124, "timed_out": True}, "blocked_timeout"),
                                    ({"exit": 0, "coverage_error": "no math"}, "blocked_coverage")):
            self.assertEqual(m.classify({"exit": 0}, candidate), expected)

    def test_suite_inventory_pending_and_missing_ids_block(self):
        def inventory(examples):
            return m.suite_inventory({"examples": examples})
        examples = [{"id": "a", "status": "passed"}, {"id": "b", "status": "pending"}]
        original = inventory(examples)
        self.assertEqual(original["exercised"], 1)
        self.assertEqual(inventory([{ "id": "a", "status": "pending"}])["exercised"], 0)
        before = {"exit": 0, "test_inventory": original}
        missing = {"exit": 0, "test_inventory": inventory(examples[:1])}
        self.assertEqual(m.classify(before, missing), "blocked_test_inventory_drift")
        pending = {"exit": 0, "test_inventory": inventory([dict(e, status="pending") for e in examples])}
        self.assertEqual(m.classify(before, pending), "blocked_candidate_pending_regression")

    def test_smoke_config_precedence_and_absence(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, "No metanorma"):
                m.select_config(directory)
            Path(directory, "metanorma.yml").write_text("default")
            self.assertEqual(m.select_config(directory).name, "metanorma.yml")
            Path(directory, "metanorma.test.yml").write_text("smoke")
            self.assertEqual(m.select_config(directory).name, "metanorma.test.yml")

    def test_evidence_directory_exports_logs_documents_not_bundle_or_source(self):
        with tempfile.TemporaryDirectory() as directory:
            root, output = Path(directory, "work"), Path(directory, "output")
            arm = root / "baseline"
            (arm / "bundle").mkdir(parents=True)
            (arm / "artifacts").mkdir()
            (arm / "bundle/private.rb").write_text("private source")
            (arm / "scenario.log").write_text("token=secret-value-test")
            (arm / "scenario.exit").write_text("1")
            (arm / "artifacts/public.xml").write_text("<document/>")
            with patch.dict(m.os.environ, {"TEST_SECRET_TOKEN": "secret-value-test"}):
                exported = m.export_evidence(root, output)
            self.assertIn("baseline/scenario.log", exported["copied"])
            self.assertIn("baseline/artifacts/public.xml", exported["copied"])
            self.assertNotIn("secret-value-test", (output / "evidence/baseline/scenario.log").read_text())
            self.assertFalse((output / "evidence/baseline/bundle").exists())
            limited = m.export_evidence(root, Path(directory, "limited"), max_file=1)
            self.assertTrue(limited["skipped_size_limit"])

    def test_actual_source_and_runtime_dependency_drift_block(self):
        variant = {"sha": "fixed", "version": "0.11.9"}
        provenance = {"plurimath": dict(variant, source="/tmp/source"), "dependency_fingerprint": "exact"}
        self.assertEqual(m.verify_provenance(provenance, variant, "/tmp/source", "exact"), "exact")
        with self.assertRaisesRegex(ValueError, "dependency drift"):
            m.verify_provenance(provenance, variant, "/tmp/source", "different")
        with self.assertRaisesRegex(ValueError, "Wrong Plurimath"):
            m.verify_provenance(provenance, variant, "/tmp/other", "exact")
        with self.assertRaisesRegex(ValueError, "SHA/version"):
            m.verify_provenance(provenance, dict(variant, sha="other"), "/tmp/source", "exact")

    def test_changed_tree_requires_review(self):
        self.assertEqual(m.classify({"exit": 0, "math": "before"}, {"exit": 0, "math": "after"}),
                         "output_change_needs_review")

    def test_failure_normalization_preserves_operands(self):
        a = "\x1b[31m/work/a: expected -2, got 2 at 2026-10-15T12:32:45Z after 2.3 seconds"
        b = "/work/b: expected -2, got 2 at 2026-10-15T12:32:46Z after 4 seconds"
        self.assertEqual(m.normalize_failure(a, ["/work/a"]), m.normalize_failure(b, ["/work/b"]))
        self.assertNotEqual(m.normalize_failure("expected -2"), m.normalize_failure("expected 2"))

    def test_rspec_ids_and_exception_change_are_load_bearing(self):
        with tempfile.TemporaryDirectory() as directory:
            result = Path(directory) / "rspec.json"
            payload = {"examples": [{"id": "./spec/a_spec.rb[1:2]", "status": "failed",
                                     "exception": {"class": "Expectation", "message": "expected -2"}}]}
            result.write_text(json.dumps(payload))
            first = m.failure_evidence(result, "irrelevant log")
            self.assertEqual(first["example_ids"], ["./spec/a_spec.rb[1:2]"])
            payload["examples"][0]["exception"]["message"] = "expected 2"
            result.write_text(json.dumps(payload))
            self.assertNotEqual(first["fingerprint"], m.failure_evidence(result, "same log")["fingerprint"])

    def test_targeted_group_must_pass_and_other_baseline_bugs_can_remain(self):
        rows = [{"id": "a" + str(i), "group": "pr486", "passed": False} for i in range(6)]
        rows += [{"id": "b" + str(i), "group": "pr487", "passed": False} for i in range(8)]
        baseline = {"exit": 1, "probes": {"rows": rows}}
        candidate = {"exit": 1, "probes": {"rows": [dict(r, passed=r["group"] == "pr486") for r in rows]}}
        self.assertEqual(m.focused_comparison(baseline, candidate, "pr486"),
                         "passed_targeted_group_other_baseline_bugs_retained")
        candidate["probes"]["rows"][0]["passed"] = False
        self.assertEqual(m.focused_comparison(baseline, candidate, "pr486"), "candidate_targeted_failure")

    def test_focused_missing_duplicate_and_unaccounted_exit_do_not_pass(self):
        rows = [{"id": "a" + str(i), "group": "pr486", "passed": True} for i in range(6)]
        rows += [{"id": "b" + str(i), "group": "pr487", "passed": True} for i in range(8)]
        complete = {"exit": 0, "probes": {"rows": rows}}
        self.assertEqual(m.focused_comparison(complete, {"exit": 0}, "pr486"), "blocked_probe_coverage")
        duplicate = {"exit": 0, "probes": {"rows": rows + [rows[0]]}}
        self.assertEqual(m.focused_comparison(complete, duplicate, "pr486"), "blocked_probe_coverage")
        self.assertEqual(m.focused_comparison(complete, dict(complete, exit=1), "pr486"),
                         "blocked_probe_execution")


class OrderedArtifacts(unittest.TestCase):
    def test_mathml_operand_order_and_semantic_wrapper_are_preserved(self):
        a = f'<math xmlns="{m.MATHML}"><munder><mi>x</mi><mi>y</mi></munder></math>'
        b = a.replace('<mi>x</mi><mi>y</mi>', '<mi>y</mi><mi>x</mi>')
        c = a.replace('<munder>', '<munder><msqrt>').replace('</munder>', '</msqrt></munder>')
        trees, errors = m.extract_math(a)
        self.assertFalse(errors)
        self.assertNotEqual(m.digest(trees), m.digest(m.extract_math(b)[0]))
        self.assertNotEqual(m.digest(trees), m.digest(m.extract_math(c)[0]))

    def test_html_fallback_requires_balanced_math(self):
        data = '<!doctype html><html><br><math><mi>a</mi><mo>-</mo><mn>2</mn></math></html>'
        trees, errors = m.extract_math(data, html=True)
        self.assertEqual(len(trees), 1)
        self.assertEqual(errors, [])
        self.assertTrue(m.extract_math(data.replace('</math>', ''), html=True)[1])

    def test_docx_word_math_is_inventoried_in_order(self):
        with tempfile.TemporaryDirectory() as directory:
            with zipfile.ZipFile(Path(directory) / 'output.docx', 'w') as archive:
                archive.writestr('word/document.xml',
                    f'<w:document xmlns:w="urn:word" xmlns:m="{m.OMML}"><m:oMath>'
                    '<m:limUpp><m:e><m:r><m:t>x</m:t></m:r></m:e>'
                    '<m:lim><m:r><m:t>y</m:t></m:r></m:lim></m:limUpp></m:oMath></w:document>')
            result = m.math_inventory(directory)
            self.assertEqual(result['math_count'], 1)
            self.assertFalse(result['errors'])
            self.assertIn('output.docx:word/document.xml', result['files'])

    def test_zero_math_and_corrupt_xml_are_visible(self):
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, 'no-math.html').write_text('<html>text</html>')
            self.assertEqual(m.math_inventory(directory)['math_count'], 0)
            Path(directory, 'broken.xml').write_text('<math>')
            self.assertTrue(m.math_inventory(directory)['errors'])


if __name__ == '__main__':
    unittest.main()
