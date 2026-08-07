# Fixture sync — dummy_collection

**Source:** `metanorma/suma/spec/fixtures/dummy_collection/`
**Snapshot:** suma@4bf4891 (merge of suma#108, 2026-08-05)

## Why this exists

Phase 4b of the suma#107 → metanorma-cli integration arc. The dummy
ISO 10303 collection exercises the full collection build path:
top-level `collection.yml` with three docref module-level
`collection.yml` documents, each with `document.adoc` + `schemas.yaml`
+ `changes.yaml` + EXPRESS schemas.

`suma ~> 0.5.0` is already in metanorma-cli's gemspec as a runtime
dependency, but suma's `spec/fixtures/` is not exposed as a runtime
artifact (and should not be — test fixtures belong in test trees).
This copy is the cleanest way to exercise the path from metanorma-cli's
own acceptance suite.

## Sync procedure

When the upstream fixture changes, re-sync:

```
# from this repo root
SUMA_SHA=<new-sha>
git fetch --depth=1 https://github.com/metanorma/suma.git "$SUMA_SHA"
git checkout FETCH_HEAD -- spec/fixtures/dummy_collection/
# Update the snapshot line at the top of this file.
git add spec/fixtures/dummy_collection/
git commit -m "spec: sync dummy_collection from suma@$SUMA_SHA"
```

## Drift surface

Until a CI sync check is added (would require suma git history access),
drift is caught only at manual review. If acceptance fails after a
suma bump, suspect this fixture first.
