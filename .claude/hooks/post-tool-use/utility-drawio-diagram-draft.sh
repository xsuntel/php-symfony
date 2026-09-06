#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - PostToolUse - draw.io diagram draft guard
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.PostToolUse (matcher "Edit|Write").
# Dual entry point — the same file is both the hook and the checker the reviewer runs by hand:
#   hook  : payload arrives as JSON on stdin, file path read with jq.
#   CLI   : utility-drawio-diagram-draft.sh <draft path>, used by utility-drawio-diagram-author (self gate)
#           and utility-drawio-diagram-reviewer (the output is the evidence its verdict rests on).
# One implementation means the hook and the reviewer can never drift apart.
# This is the executable projection of the `## Storage Format (non-negotiable)` and
# `## Structural Integrity (non-negotiable)` sections of .claude/rules/utility-drawio-diagram-rule.md —
# it adds no criteria of its own; the rule stays the SoT.
# The sidecar .claude/tmp/utility/drawio/diagram-draft.meta.json carries apply mode and the baseline
# cell ids. baselineCellIds does double duty: it detects set_page omissions, and it scopes the
# convention checks (palette, grid) to the cells this draft authored — a replacement draft has to
# carry the existing cells verbatim, so flagging those would only produce unfixable findings.
# Without the sidecar the structural checks still run; the apply/omission checks are skipped and the
# convention checks fall back to every cell.
# Exit 2 does NOT block — PostToolUse runs after the tool — it only surfaces stderr so the draft is
# corrected inside the same turn.
# ----------------------------------------------------------------------------------------------------------------------

FILE_PATH="${1:-}"

# No argument means the hook invoked us, so the path has to come out of the stdin payload.
# Edit exposes tool_input.file_path; Write's response uses tool_response.filePath.
# `|| true` is load-bearing under `set -e` — see php-lint.sh for the full rationale.
if [ -z "${FILE_PATH}" ]; then
  command -v jq >/dev/null 2>&1 || exit 0
  FILE_PATH="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' || true)"
fi

case "${FILE_PATH}" in
  *.claude/tmp/utility/drawio/diagram-draft.xml) ;;
  *) exit 0 ;;
esac

[ -f "${FILE_PATH}" ] || exit 0

if ! command -v python3 >/dev/null 2>&1; then
  echo "[ SKIP ] drawio draft guard: python3 not found — the structural checks did not run." >&2
  exit 1
fi

META_PATH="${FILE_PATH%/*}/diagram-draft.meta.json"

set +e
REPORT="$(python3 - "${FILE_PATH}" "${META_PATH}" <<'PYTHON'
import json
import os
import re
import sys
import xml.etree.ElementTree as ElementTree

draft_path, meta_path = sys.argv[1], sys.argv[2]
must, should = [], []

raw = open(draft_path, encoding="utf-8").read()

meta = {}
if os.path.isfile(meta_path):
    try:
        meta = json.load(open(meta_path, encoding="utf-8"))
    except json.JSONDecodeError as error:
        must.append("the sidecar meta.json is not valid JSON — %s" % error)


def report_and_exit():
    for line in must:
        print("  [MUST] %s" % line)
    for line in should:
        print("  [SHOULD] %s" % line)
    sys.exit(2 if must else 0)


# Storage format is checked on the raw text: a comment or a compressed body survives parsing, and the
# escape rule needs no separate check because an unescaped < or & is already a parse error.
if "<!--" in raw:
    must.append("an XML comment (<!-- -->) is present — move the explanation into a value or UserObject attribute.")
if 'compressed="true"' in raw:
    must.append('compressed="true" is present — store uncompressed XML only.')

try:
    root = ElementTree.fromstring(raw)
except ElementTree.ParseError as error:
    must.append("not well-formed XML — %s" % error)
    report_and_exit()

apply_mode = meta.get("apply")

if root.tag == "mxfile":
    models = [(diagram, diagram.find("mxGraphModel")) for diagram in root.findall("diagram")]
    if apply_mode == "set_page":
        must.append("meta apply is set_page but an <mxfile> wrapper is present — it must be a single <mxGraphModel>.")
elif root.tag == "mxGraphModel":
    models = [(None, root)]
    if apply_mode == "Write":
        must.append("meta apply is Write but there is no <mxfile> wrapper — the whole document must be written.")
else:
    must.append("the root element is neither <mxfile> nor <mxGraphModel> — found: <%s>" % root.tag)
    report_and_exit()

if not models:
    must.append("there is no <mxGraphModel> at all.")
    report_and_exit()

PALETTE = {
    "#dae8fc": "#6c8ebf",
    "#d5e8d4": "#82b366",
    "#e1d5e7": "#9673a6",
    "#f8cecc": "#b85450",
    "#fff2cc": "#d6b656",
}
# Neutrals are allowed everywhere, and the mxgraph.aws4 stencils carry brand colours that are part of
# the stencil definition rather than a palette choice — flagging those would be a pure false positive.
NEUTRAL = {"none", "#f5f5f5", "#666666", "#ffffff", "#000000", "default", "inherit"}
STENCIL_BRAND = {"#8c4fff", "#232f3d", "#232f3e", "#a153a0", "#ed7100", "#7aa116", "#e7157b", "#01a88d"}
DEFAULT_PAGE_NAME = re.compile(r"^(페이지|Page)[- ]?\d+$")


def style_of(element):
    return (element.get("style") or "").lower()


def style_value(style, key):
    match = re.search(r"(?:^|;)%s=([^;]*)" % key, style)
    return match.group(1) if match else None


for diagram, model in models:
    page_name = diagram.get("name") if diagram is not None else meta.get("page", "")
    label = "page '%s'" % page_name if page_name else "model"

    if model is None:
        must.append("%s has no <mxGraphModel> — most likely a Base64-compressed body." % label)
        continue

    cell_root = model.find("root")
    if cell_root is None:
        must.append("%s has no <root>." % label)
        continue

    # A cell is either a bare <mxCell> or an <mxCell> wrapped in <object>/<UserObject>, where the id
    # lives on the wrapper. Missing this case would make every annotated cell look like a dangling id.
    cells = []
    for child in cell_root:
        if child.tag == "mxCell":
            cells.append((child.get("id"), child))
        elif child.tag in ("object", "UserObject"):
            inner = child.find("mxCell")
            if inner is not None:
                cells.append((child.get("id"), inner))

    ids = [cell_id for cell_id, _ in cells]
    id_set = set(ids)
    baseline_ids = set(meta.get("baselineCellIds") or [])

    # draw.io regenerates the root ids with a page-local prefix whenever a page is copied — 62 of the
    # repository's 114 pages carry them. Judge the structure rather than the literal ids: one cell
    # with no parent, plus one layer cell parented to it.
    parentless = {cell_id for cell_id, cell in cells if cell.get("parent") is None}
    layers = {cell_id for cell_id, cell in cells if cell.get("parent") in parentless}

    if not parentless or not layers:
        must.append("%s: no root cells — a top-level cell with no parent, plus a layer cell parented to it, are both required." % label)
    elif not baseline_ids and (parentless != {"0"} or "1" not in layers):
        # Only a brand new page gets to choose its root ids; replacing a page keeps the ones it has.
        should.append('%s: the root cell ids are not "0"/"1" — a new page uses 0/1.' % label)

    for duplicate in sorted({cell_id for cell_id in ids if cell_id is not None and ids.count(cell_id) > 1}):
        must.append("%s: duplicate id — '%s'" % (label, duplicate))

    for cell_id, cell in cells:
        if cell_id is None:
            must.append("%s: a cell has no id." % label)
            continue

        is_vertex = cell.get("vertex") == "1"
        is_edge = cell.get("edge") == "1"

        # A set_page draft has to carry every existing cell verbatim, so convention checks only make
        # sense on the cells this draft actually authored. Structural MUSTs still cover every cell —
        # a broken reference breaks the file no matter who wrote it.
        reviewable = not baseline_ids or cell_id not in baseline_ids

        if is_vertex and is_edge:
            must.append("%s: cell '%s' carries both vertex and edge." % (label, cell_id))

        parent = cell.get("parent")
        if parent is not None and parent not in id_set:
            must.append("%s: the parent '%s' of cell '%s' does not exist." % (label, parent, cell_id))

        for endpoint in ("source", "target"):
            reference = cell.get(endpoint)
            if reference is not None and reference not in id_set:
                must.append(
                    "%s: the %s '%s' of edge '%s' does not exist — use an mxPoint for an unconnected endpoint."
                    % (label, endpoint, reference, cell_id)
                )

        # Root cells and layers legitimately carry no geometry; only drawn cells need one.
        if is_vertex or is_edge:
            geometry = cell.find("mxGeometry")
            if geometry is None:
                must.append("%s: cell '%s' has no <mxGeometry>." % (label, cell_id))
            elif geometry.get("as") != "geometry":
                must.append('%s: the <mxGeometry> of cell \'%s\' lacks as="geometry" — the coordinates are ignored.' % (label, cell_id))
            elif is_vertex:
                for axis in ("x", "y", "width", "height"):
                    value = geometry.get(axis)
                    if value is None:
                        continue
                    try:
                        number = float(value)
                    except ValueError:
                        must.append("%s: the %s of cell '%s' is not a number — '%s'" % (label, axis, cell_id, value))
                        continue
                    # round() absorbs the float noise draw.io leaves behind (x="-2.84e-14" is 0).
                    if reviewable and round(number, 6) % 10 != 0:
                        should.append("%s: cell '%s' has %s=%s, which is not a multiple of 10." % (label, cell_id, axis, value))

        style = style_of(cell)
        fill = style_value(style, "fillcolor")
        stroke = style_value(style, "strokecolor")
        if reviewable and fill and fill not in NEUTRAL and fill not in STENCIL_BRAND:
            if fill not in PALETTE:
                should.append("%s: the fillColor '%s' of cell '%s' is outside the 5-pair palette." % (label, fill, cell_id))
            elif stroke and stroke not in STENCIL_BRAND and stroke != PALETTE[fill]:
                should.append(
                    "%s: cell '%s' pairs fill '%s' with stroke '%s' — the matching stroke is '%s'."
                    % (label, cell_id, fill, stroke, PALETTE[fill])
                )

    if model.get("gridSize") != "10":
        should.append("%s: gridSize is '%s' — it must be 10." % (label, model.get("gridSize")))
    if model.get("pageWidth") not in ("1600", "1920", "1200"):
        should.append("%s: pageWidth is '%s' — it must be one of 1600/1920/1200." % (label, model.get("pageWidth")))
    if model.get("pageHeight") not in ("1200", "1920"):
        should.append("%s: pageHeight is '%s' — it must be one of 1200/1920." % (label, model.get("pageHeight")))

    if page_name and DEFAULT_PAGE_NAME.match(page_name):
        should.append("the page name '%s' is a default — rename it to describe its contents." % page_name)

    # set_page swaps the whole page, so a baseline id that is neither in the draft nor declared as an
    # intentional deletion is silent data loss — the one failure mode a reviewer cannot see by reading.
    if apply_mode == "set_page" and diagram is None:
        baseline = meta.get("baselineCellIds")
        if isinstance(baseline, list):
            intentional = set(meta.get("intentionalDeletions") or [])
            missing = [cell_id for cell_id in baseline if cell_id not in id_set and cell_id not in intentional]
            if missing:
                must.append(
                    "%d cell(s) missing under set_page — absent from the draft and not listed in intentionalDeletions: %s"
                    % (len(missing), ", ".join(missing[:20]) + (" …" if len(missing) > 20 else ""))
                )
        elif meta:
            should.append("meta has no baselineCellIds — the set_page missing-cell check could not run.")

if apply_mode is None and meta == {}:
    should.append("the sidecar diagram-draft.meta.json is absent — the apply-mode and missing-cell checks were skipped.")

report_and_exit()
PYTHON
)"
STATUS=$?
set -e

if [ "${STATUS}" -eq 2 ]; then
  {
    echo "[ FAIL ] drawio draft (.claude/rules/utility-drawio-diagram-rule.md):"
    printf '%s\n' "${REPORT}"
  } >&2
  exit 2
fi

if [ "${STATUS}" -ne 0 ]; then
  echo "[ SKIP ] drawio draft guard: the check script exited abnormally (exit ${STATUS})." >&2
  printf '%s\n' "${REPORT}" >&2
  exit 1
fi

if [ -n "${REPORT}" ]; then
  echo "[ WARN ] drawio draft (.claude/rules/utility-drawio-diagram-rule.md):"
  printf '%s\n' "${REPORT}"
fi

exit 0
