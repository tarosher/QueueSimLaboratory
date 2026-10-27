# QueueSimLab v0.2.0 public release checklist

**Owner decision: APPROVED on 2026-10-27.** Jiajun Xia explicitly authorized the `tarosher/QueueSimLaboratory` repository to become public and v0.2.0 to be distributed under MIT. See [approval record](RELEASE_APPROVAL_RECORD_ZH.md).

## Checked before publication

- [x] Sole authorship of the original supermarket-queue course project confirmed by its owner; no known course restriction on releasing their own code.
- [x] `legacy/` (38 original course MATLAB files) and its dependent regression test excluded from this public repository.
- [x] Initial source/provenance scan of the 60 MATLAB files found no obvious external source copies or bundled restricted binary materials. This is a limited technical screening, not a guarantee of complete ownership.
- [x] MIT `LICENSE` at repository root identifies `Copyright (c) 2026 Jiajun Xia`.
- [x] `CITATION.cff` identifies Jiajun Xia and the correct repository URL.
- [x] Clean Git history contains only GitHub noreply author and committer addresses; original personal-email history remains in the separate private archive.
- [x] MATLAB R2022b local acceptance: 89/89 tests; Benchmarks A–C have 23 metric rows; 6 performance workloads. The recorded accepted commit is `b7494619d12277e703695563f6c328f9cbdebfd0`.
- [x] Static Actions CI passed on the above `main` commit. Private MATLAB Actions were skipped, not passed.
- [x] Project owner explicitly approved public visibility and MIT release on 2026-10-27.

## GitHub publication actions still to perform

- [ ] Push the approved documentation-only commit to `main` and check its static CI.
- [ ] Change only **QueueSimLaboratory** to Public. Keep the original `tarosher/QueueSimLab` Private.
- [ ] Verify public code tree, MIT license, `.gitignore`, absence of generated outputs and author privacy settings.
- [ ] Create the `v0.2.0` release tag from current `main`; copy verified [release notes](RELEASE_NOTES_V0.2.0.md), and publish GitHub Release.
- [ ] Confirm the release tag and source archive match the reviewed commit.

The command `python tools/check_release.py --public` checks file structure, license presence and recorded owner authorization. It cannot establish legal provenance or change repository visibility; pass/fail of MATLAB tests is independent.
