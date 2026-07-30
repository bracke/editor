# Known Windows test failures (follow-up)

Status as of 2026-07-30. The AUnit suite runs to completion on all three OSes,
and is **green on Linux and macOS**. On **Windows**, 91 assertions still fail.
These are pre-existing editor cross-platform behaviour bugs, newly *observable*
now that the Windows job builds only `tests.adb` and no longer hangs — they are
not regressions from the work that got the suite running.

## What was fixed to get here

- **The Windows hang** (the job used to run the full 4 h cap and be cancelled):
  `Assert_Async_Build_Real_Process_Cancel_Integration` declares a worker task in
  its declarative part, so the task activates on entry, before the POSIX skip
  can return. On a skipped run `Start` was never called and the task sat forever
  on `accept Start`, blocking the function's scope exit. Fixed with a
  `select accept Start or terminate end select`.
- **OS detection**: the process-control backend was derived by string-matching a
  label and defaulting the unknown case to POSIX, so `Is_POSIX` reported POSIX on
  Windows. Now derived from `Hostkit.Host.Current`.
- **Test scratch paths**: `Editor.Test_Temp.Path` composes paths with the host
  separator (was `Base & "/..."`, which kept forward slashes and never matched
  the editor's backslash `Full_Name` on Windows). Cleared ~44 failures.

The `Test_Temp.Path` output was verified byte-equal to `Ada.Directories.Full_Name`
on the Windows runner (including the 8.3 `RUNNER~1` form), so the remaining 91 are
**not** a test-path construction problem, and the editor uses byte-exact
`Stream_IO` (no CRLF translation), so they are **not** line-ending problems.

## The 91 remaining failures — categories (to investigate)

All are in file-lifecycle / association tests. Distribution by file:

| count | file |
|------:|------|
| 12 | editor-files-save_operation_tests.adb |
| 11 | editor-files-reload_revert_operation_tests.adb |
| 11 | editor-dogfood_workflow-tests.adb |
|  9 | editor-files-copy_move_association_tests.adb |
|  7 | editor-files-operations_tests.adb |
|  6 | editor-buffers-tests.adb |
|  5 | editor-workspace_persistence-tests.adb |
|  5 | editor-files-tests.adb |
|  4 | editor-missing_stale_recovery-tests.adb |
|  4 | editor-files-rename_delete_operation_tests.adb |
| 3+ | save_reload, project_workspace_session, semantic_index_state, bookmarks, ... |

Likely root-cause buckets (each needs a Windows CI cycle to confirm — there is no
local Windows here):

1. **Path equality / collision** — e.g. "source-equals-target must remain a
   deterministic no-overwrite collision". The editor compares two paths for
   identity; on Windows that must be case-insensitive and short/long-name aware.
2. **Path normalisation** — "save should drop redundant-slash structural paths",
   "…noncanonical backslash structural paths". The editor's structural-path
   canonicalisation rules were written for POSIX separators.
3. **Reload / external-change detection** — "successful reload must replace text
   with exact disk contents". A save then an external overwrite then reload does
   not pick up the new bytes; the change-detection (mtime/identity) likely keys
   off a path that does not compare equal on Windows.
4. **Association tracking after save-as / move** — "subsequent save must write to
   moved target path, not old source path", "clean association invariant failed".

The common thread across 1–4 is Windows path **identity/normalisation inside the
editor core** (not the tests). Recommended approach: add targeted diagnostics that
print `File_Info.Path` and the compared path through one representative flow per
bucket, fix the editor's path comparison/normalisation to be host-aware (route
through `Hostkit.Host`/`Hostkit.Fs` where an OS distinction is needed), and
re-run. Fixing bucket 1–2 (path identity) will likely clear most of the others.
