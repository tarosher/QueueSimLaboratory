# Public GitHub release checklist — approval required

**Current status: HOLD (private release candidate).** The independent author has selected MIT with copyright attribution **Jiajun Xia**, and a standard LICENSE is present. The new `QueueSimLaboratory` repository uses a clean Git root rather than the old email-bearing private development history. Source provenance, new-commit acceptance, and explicit authorization to make the repository public remain pending.

## Before setting the repository public

- [x] Original supermarket-course project: owner self-reports **sole authorship** (2026-10-27). This does not independently clear course-policy or third-party restrictions.
- [x] Initial static scan of the 60 MATLAB source files and Git tree completed ([screening report](RELEASE_SOURCE_SCREENING_ZH.md)); no obvious embedded third-party source signatures observed. **This does not confirm rights.**
- [ ] Review any third-party contributions, borrowed materials, and actual source provenance throughout the current framework.
- [ ] Keep `legacy/` (38 MATLAB files), original figures and any borrowed code/data **out of the Git history** unless redistribution approval is documented. If uncertain, publish only separately cleared, authored code, with an adapted regression strategy.
- [x] Course-rule owner statement (2026-10-27): to the author's knowledge, the original course does not prohibit publishing the independently created project. No school-specific authorization is claimed; if restricted teacher-provided material is identified, exclude it or obtain permission.
- [x] Confirm proposed copyright attribution: `Copyright (c) 2026 Jiajun Xia` (owner selected real-name identification, 2026-10-27).
- [x] License type and named copyright holder selected: MIT, Copyright (c) 2026 Jiajun Xia.
- [ ] Explicitly authorize public distribution under MIT after final provenance and release review.
- [x] Confirm author attribution **Jiajun Xia**, MIT copyright notice, and non-sensitive software citation metadata (`CITATION.cff`). No institutional affiliation or contact email is asserted.
- [x] Create and verify clean new GitHub `main` history: one root commit `a3c8cfe0879d5c4313869ea67979498a752f0538`, author/committer Jiajun Xia and GitHub `noreply` email; no old email-bearing commits.
- [ ] Confirm no tokens, institutional data, personal identifiers or copyrighted attachments are present.
- [ ] Run all MATLAB tests and export smoke checks on the **exact** publishable commit.
- [x] Confirm GitHub static Actions success on clean initial commit ([run 40542216485](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40542216485)); private MATLAB CI skipped and requires local verification or appropriate license.
- [ ] Cut an annotated version tag and release only after checklist approval.

## Automation vs approval

`python tools/check_release.py` is a best-effort **technical** preflight. `--public` now checks both a license file and an explicit approval marker `PUBLIC_RELEASE_APPROVED: YES` in the approval record. Its checks do not establish actual ownership or legal permission. The checklist items above require a human decision.

MATLAB Actions auto-license MATLAB for public GitHub repositories; private ones may need a batch licensing token. The workflow cannot circumvent software licensing restrictions.

## Release-preparation documents (2026-10-27)

- [Draft release notes](RELEASE_NOTES_V0.2.0_DRAFT.md) — technical scope and verified tests only; **not published**.
- [Provenance audit form](PROVENANCE_AUDIT_ZH.md) — owner statement on independent authorship and no known course prohibition recorded; non-obvious third-party provenance and commit-email exposure remain for final review.
- [Approval record](RELEASE_APPROVAL_RECORD_ZH.md) — explicit human signoff fields; current status **HOLD**.
- [Release playbook](RELEASE_PLAYBOOK_ZH.md) — future publishing sequence, not authorization to publish.
