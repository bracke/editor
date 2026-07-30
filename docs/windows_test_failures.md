# Windows test failures — RESOLVED (2026-07-30)

The AUnit suite (5567 tests) is **green on Linux, macOS and Windows**. This file
records the cross-platform bugs that getting the Windows job to run first
surfaced, and how they were fixed. It started at 91 failed assertions + 3 errors
on Windows and reached zero.

## The through-line

The editor treated paths as raw, `/`-separated, case-sensitive strings. Windows
uses `\`, is case-insensitive, and `Ada.Directories.Full_Name` (the editor's
stored file identity) returns backslashes. The fixes establish one convention:

- **Identity** (a file's stored path): the host-native form (`Full_Name`).
- **Comparison** (is-inside-project, diagnostic-to-buffer, project-root equality):
  `Editor.Path_Helpers.Normalize_For_Compare` — separators folded to `/` and
  case folded on Windows, the Windows flag from `Hostkit.Host.Current`.
- **Display labels** (project-relative, recent-project rows): portable `/` for
  the relative part, host separator when a full path is shown to the user.

OS is asked of `Hostkit.Host.Current`, never re-derived.

## Root causes fixed

1. **Save was broken on Windows (~69 of the 91).** Both atomic-write paths
   (`Editor.Files.Save_File`, workspace persistence) ended with
   `GNAT.OS_Lib.Rename_File` of a temp file over the target. Windows `rename`
   fails when the target exists, so every save of an existing file was a write
   error, cascading through save/reload/revert/save-as/snapshot tests. Now uses
   `Hostkit.Fs.Replace_File` (rename on POSIX, `MoveFileEx` with
   `MOVEFILE_REPLACE_EXISTING` on Windows).
2. **Fixture paths built as `Base & "/x"` / `Root & "/x"`** kept forward slashes
   on a native base. Added `Editor.Test_Temp.Path` / `Join` (native compose),
   swept the call sites, and made `Join` fall back to a plain host-separator
   append for segments `Ada.Directories.Compose` rejects (drive-relative
   `C:tmp.txt`, malformed `a|b=c` a test feeds as data).
3. **`Pure_Normalize_Path`** (buffer metadata / project labels / boundary checks)
   rebuilt with `/` regardless of host; now uses the host separator for identity,
   and `Pure_Relative_Path` emits `/` for the portable label.
4. **`Is_Inside_Project`** canonicalised with `Full_Name` then tested the boundary
   char against a literal `/`, so every in-project file read as outside on
   Windows. Now compares via `Normalize_For_Compare`.
5. **Diagnostic-to-buffer resolution** matched a compiler's `\`-path against a
   `/`-joined candidate and a `Full_Name` buffer path with exact equality; now
   `Normalize_For_Compare`.
6. **`recent_projects` row label** displayed the `/`-comparison key verbatim; now
   rendered with the host separator (storage/compare unchanged).
7. **`Ada.Directories.Exists` raises** on Windows for a path with an embedded
   drive letter; the File-Tree drive-relative test guards that probe.
8. **Two POSIX-only fixtures** spawned `/bin/sleep` and `/bin/echo` (absent on
   Windows); guarded on `Native_Process_Control_Is_POSIX`. (The `/bin/sleep` one
   was also the original 4-hour hang, via a worker task without a `terminate`
   alternative.)
