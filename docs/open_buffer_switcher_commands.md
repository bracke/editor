# Open Buffer Switcher Commands

Phase 317 developer reference for the Open Buffer Switcher command surface. Descriptors remain authoritative; this document is a compact maintenance artifact kept synchronized by tests.

## Stable Name Rules

- Canonical names are the stable names listed in the command tables.
- Keybindings save canonical stable command names only.
- Unknown command names are rejected or ignored according to keybinding load policy.
- Optional absent commands are not exposed, hinted, bound, or palette-visible.

Only current Open Buffer Switcher command names are accepted.

## Route Classes

- `Executor`: command-like action routed through `Editor.Executor` and descriptor availability checks.
- `Local UI`: switcher-local interaction that is not a command descriptor and does not route command-like mutation through Executor.
- `Invoker`: command descriptor that delegates to another command through Executor. No switcher invoker descriptors are currently registered.
- `Display-only`: snapshot, hint, formatting, or render derivation; not a command descriptor.

All command descriptors documented below are `Executor` routes in this snapshot. Display-only helpers are named only in the read-only derivation section and must not be persisted or bound as commands.


## Availability Owner Notes

Availability is owned by the workflow state named in the `Owner` column and must remain side-effect-free. Switcher overlay commands are owned by overlay visibility and selection state. Filter, query, sort, selected-action, and preview commands are owned by their corresponding session-local switcher state. Mark commands are owned by the current mark set; mark review navigation is owned by the active mark-review projection. Pending marked-close commands are owned by captured pending targets, while ordinary pruned and dirty pending commands are owned by their respective target sets. Dirty-prune preview commands are owned by the captured preview target set and its removed-target history. Dirty-prune apply commands are owned by captured apply-confirmation targets and their removed-target history. Cleanup commands are owned by guarded buffer cleanup policy. Reopen and recent-buffer commands are owned by the reopen stack and recent-buffer traversal state.

Availability checks may report unavailable state, but must not create, repair, prune, restore, close, reopen, persist, or otherwise mutate switcher workflow state.

## Persistence Boundaries

All Open Buffer Switcher workflow state is session-local. Keybindings may persist stable command names only. Workspace, settings, and recent-project persistence must not store marks, pending marked-close targets, ordinary pruned targets, dirty pending targets, dirty-prune preview targets, dirty-prune apply targets, removed-target histories, review modes, selected hints, derived snapshots, or command messages.

Availability checks and read-only derivation paths must remain side-effect-free and must not repair workflow state.

## Contextual Hints

Contextual hints reference canonical command ids. They are derived from the centralized switcher snapshot and selected row identity, show only implemented available relevant commands under the current hint policy, and may show active keybinding text when display policy allows. Hint invocation must dispatch through Executor and must not become a parallel mutation path. Hints and selected hint state are not persisted.

The `Hint` column uses `conditional` for commands currently referenced by the switcher contextual-hint derivation and `no` otherwise.

## Command Palette

The Command Palette projects from command descriptors and Executor availability. Projection must not mutate state. Palette-visible switcher commands appear once under canonical names. Old names, optional absent commands, local-only mechanics, and display-only helpers are not palette entries.

## Keybindings

Bindable commands may be assigned active runtime bindings. Non-bindable commands are rejected by keybinding assignment. Keybindings persist stable command names only. Hint keybinding text reflects active runtime bindings, not defaults or files.

No new default keybindings are defined by this reference.

## Read-Only Derivation Is Not a Command Surface

The following are display-only or read-only derivation paths and must not be listed as command names: batch-state snapshot derivation, row marker derivation, contextual hint derivation, header/footer badge formatting, message formatting, render packet emission, and availability checks.

## Command Families

<!-- switcher-command-table:start -->

### Switcher Basics

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.open | Inspect and switch among currently open buffers | Navigation | General | yes | yes | no | Executor | switcher overlay | current |
| buffers.switcher.close | Hide the open-buffer list | Navigation | General | yes | no | conditional | Executor | switcher overlay | current |
| buffers.switcher.accept | Switch to the selected open buffer-list row | Navigation | General | yes | no | conditional | Executor | switcher overlay | current |
| buffers.switcher.next | Select the next open-buffer list row | Navigation | General | yes | no | conditional | Executor | switcher overlay | current |
| buffers.switcher.previous | Select the previous open-buffer list row | Navigation | General | yes | no | conditional | Executor | switcher overlay | current |

### Filters and Sort

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.filter.clear | Clear the active open-buffer list filter. | Navigation | General | yes | yes | conditional | Executor | filter/query/sort state | current |
| buffers.switcher.filter.pinned | Show only pinned open buffers in the Open Buffer List. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.filter.group | Show only open buffers in the named session-local group. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.filter.label | Show only open buffers with the named session-local label. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.filter.noted | Show only open buffers that have session-local notes. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.sort.default | Use the default Open Buffer List order. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.sort.recent | Order Open Buffer List rows by recent activation. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.sort.name | Order Open Buffer List rows by display name. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.sort.pinned | Order pinned open buffers before unpinned buffers in the open-buffer list. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.sort.group | Order grouped open buffers by group name in the open-buffer list. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.sort.label | Order labeled open buffers by label text in the open-buffer list. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |
| buffers.switcher.sort.next | Cycle to the next Open Buffer List sort mode. | Navigation | General | yes | yes | conditional | Executor | filter/query/sort state | current |
| buffers.switcher.sort.previous | Cycle to the previous Open Buffer List sort mode. | Navigation | General | yes | yes | no | Executor | filter/query/sort state | current |

### Selected Actions

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.selected.close | Close the selected open buffer from the buffer list. | Navigation | Destructive+Lifecycle | yes | yes | no | Executor | selected row | current |
| buffers.switcher.selected.pin | Pin the selected open buffer from the open-buffer list. | Navigation | Lifecycle | yes | yes | no | Executor | selected row | current |
| buffers.switcher.selected.unpin | Unpin the selected open buffer from the open-buffer list. | Navigation | Lifecycle | yes | yes | no | Executor | selected row | current |
| buffers.switcher.selected.toggle-pin | Toggle pin state for the selected open buffer from the open-buffer list. | Navigation | Lifecycle | yes | yes | no | Executor | selected row | current |
| buffers.switcher.selected.group.assign | Assign the selected open buffer to a session-local group from the open-buffer list. | Navigation | Lifecycle | yes | yes | no | Executor | selected row | current |
| buffers.switcher.selected.group.clear | Clear the selected open buffer group from the open-buffer list. | Navigation | Lifecycle | yes | yes | no | Executor | selected row | current |
| buffers.switcher.selected.label.set | Set the selected open buffer label from the open-buffer list. | Navigation | Lifecycle | yes | yes | no | Executor | selected row | current |
| buffers.switcher.selected.label.clear | Clear the selected open buffer label from the open-buffer list. | Navigation | Lifecycle | yes | yes | no | Executor | selected row | current |
| buffers.switcher.selected.note.set | Set the selected open buffer note from the open-buffer list. | Navigation | Lifecycle | yes | yes | no | Executor | selected row | current |
| buffers.switcher.selected.note.clear | Clear the selected open buffer note from the open-buffer list. | Navigation | Lifecycle | yes | yes | no | Executor | selected row | current |

### Preview

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.preview.toggle | Show or hide the selected open-buffer preview in the open-buffer list. | Navigation | General | yes | yes | no | Executor | preview state | current |
| buffers.switcher.preview.show | Show a compact read-only preview for the selected open buffer. | Navigation | General | yes | yes | no | Executor | preview state | current |
| buffers.switcher.preview.hide | Hide the selected open-buffer preview in the open-buffer list. | Navigation | General | yes | yes | no | Executor | preview state | current |
| buffers.switcher.preview.next-line | Scroll the selected-buffer preview down by one line. | Navigation | General | yes | yes | no | Executor | preview state | current |
| buffers.switcher.preview.previous-line | Scroll the selected-buffer preview up by one line. | Navigation | General | yes | yes | no | Executor | preview state | current |
| buffers.switcher.preview.center-cursor | Return the selected-buffer preview to that buffer's cursor line. | Navigation | General | yes | yes | no | Executor | preview state | current |

### Marks and Mark Presets

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.mark.toggle | Mark or unmark the selected open buffer in the open-buffer list. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.set | Mark the selected open buffer in the open-buffer list. | Navigation | General | yes | yes | conditional | Executor | mark set | current |
| buffers.switcher.mark.clear | Clear the mark from the selected open buffer in the open-buffer list. | Navigation | General | yes | yes | conditional | Executor | mark set | current |
| buffers.switcher.mark.clear-all | Clear all temporary Open Buffer List marks. | Navigation | General | yes | yes | conditional | Executor | mark set | current |
| buffers.switcher.mark.invert-visible | Invert marks for the currently visible open-buffer rows. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.visible | Mark all currently visible open-buffer list rows. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.clear-visible | Clear marks from currently visible open-buffer list rows. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.pinned | Mark all currently open pinned buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.close-marked | Prepare confirmation for closing all currently marked open buffers. | Navigation | General | yes | yes | conditional | Executor | mark set | current |
| buffers.switcher.mark.confirm | Confirm the pending marked buffer action. | Navigation | Lifecycle | yes | yes | conditional | Executor | mark set | current |
| buffers.switcher.mark.cancel | Cancel the pending marked buffer action without mutation. | Navigation | General | yes | yes | conditional | Executor | mark set | current |

### Mark Review

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.mark.review.toggle | Show or hide a marked-only review view in the Open Buffer List. | Navigation | General | yes | yes | no | Executor | mark review state | current |
| buffers.switcher.mark.review.show | Show only currently marked open buffers in the open-buffer list. | Navigation | General | yes | yes | conditional | Executor | mark review state | current |
| buffers.switcher.mark.review.hide | Return the open-buffer list to its normal view. | Navigation | General | yes | yes | conditional | Executor | mark review state | current |
| buffers.switcher.mark.next | Move the open-buffer list selection to the next marked candidate without activating it. | Navigation | General | yes | yes | conditional | Executor | mark review state | current |
| buffers.switcher.mark.previous | Move the open-buffer list selection to the previous marked candidate without activating it. | Navigation | General | yes | yes | conditional | Executor | mark review state | current |
| buffers.switcher.mark.summary | Report the current count of marked open buffers. | Navigation | General | yes | yes | no | Executor | mark review state | current |

### Marked Metadata Apply

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.mark.group | Mark all currently open buffers in a session-local group. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.label | Mark all currently open buffers with a session-local label. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.noted | Mark all currently open buffers that have session-local notes. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.pin-marked | Pin all currently marked open buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.unpin-marked | Unpin all currently marked open buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.clear-metadata | Clear group, label, and note details from all marked open buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.group.assign | Assign a group to all currently marked open buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.group.clear | Clear group names from all currently marked open buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.label.set | Set a label on all currently marked open buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.label.clear | Clear labels from all currently marked open buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.note.set | Set a note on all currently marked open buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |
| buffers.switcher.mark.note.clear | Clear notes from all currently marked open buffers. | Navigation | General | yes | yes | no | Executor | mark set | current |

### Pending Marked Close

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.pending-mark.review.toggle | Show or hide the captured pending marked-close target review in the Open Buffer List. | Navigation | General | yes | yes | no | Executor | pending marked close | current |
| buffers.switcher.pending-mark.review.show | Show captured pending marked-close targets in the Open Buffer List. | Navigation | General | yes | yes | conditional | Executor | pending marked close | current |
| buffers.switcher.pending-mark.review.hide | Hide pending marked-close target review without cancelling the pending action. | Navigation | General | yes | yes | conditional | Executor | pending marked close | current |
| buffers.switcher.pending-mark.next | Move open-buffer list selection to the next captured pending close target without activating it. | Navigation | General | yes | yes | conditional | Executor | pending marked close | current |
| buffers.switcher.pending-mark.previous | Move open-buffer list selection to the previous captured pending close target without activating it. | Navigation | General | yes | yes | conditional | Executor | pending marked close | current |
| buffers.switcher.pending-mark.summary | Report captured and still-open pending marked-close target counts. | Navigation | General | yes | yes | no | Executor | pending marked close | current |
| buffers.switcher.pending-mark.remove-selected | Remove the selected buffer from the captured pending marked-close targets without changing marks. | Navigation | General | yes | yes | conditional | Executor | pending marked close | current |
| buffers.switcher.pending-mark.restore-last-pruned | Restore the most recently pruned pending marked-close target without changing marks. | Navigation | General | yes | yes | conditional | Executor | pending marked close | current |

### Ordinary Pruned Targets

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.pending-mark.pruned-summary | Report pruned pending marked-close target counts. | Navigation | General | yes | yes | no | Executor | ordinary pruned targets | current |
| buffers.switcher.pending-mark.pruned-next | Move open-buffer list selection to the next still-open pruned pending marked-close target without restoring it. | Navigation | General | yes | yes | conditional | Executor | ordinary pruned targets | current |
| buffers.switcher.pending-mark.pruned-previous | Move open-buffer list selection to the previous still-open pruned pending marked-close target without restoring it. | Navigation | General | yes | yes | conditional | Executor | ordinary pruned targets | current |
| buffers.switcher.pending-mark.pruned-review.toggle | Show or hide pruned pending marked-close targets in the Open Buffer List. | Navigation | General | yes | yes | no | Executor | ordinary pruned targets | current |
| buffers.switcher.pending-mark.pruned-review.show | Show still-open pruned pending marked-close targets in the Open Buffer List. | Navigation | General | yes | yes | conditional | Executor | ordinary pruned targets | current |
| buffers.switcher.pending-mark.pruned-review.hide | Hide pruned pending marked-close target review without restoring targets. | Navigation | General | yes | yes | conditional | Executor | ordinary pruned targets | current |
| buffers.switcher.pending-mark.restore-selected-pruned | Restore the selected still-open pruned pending marked-close target without changing marks. | Navigation | General | yes | yes | no | Executor | ordinary pruned targets | current |

### Dirty Pending Targets

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.pending-mark.dirty-summary | Report dirty still-open pending marked-close target counts. | Navigation | General | yes | yes | no | Executor | dirty pending targets | current |
| buffers.switcher.pending-mark.dirty-next | Move open-buffer list selection to the next dirty pending marked-close target without activating it. | Navigation | General | yes | yes | conditional | Executor | dirty pending targets | current |
| buffers.switcher.pending-mark.dirty-previous | Move open-buffer list selection to the previous dirty pending marked-close target without activating it. | Navigation | General | yes | yes | conditional | Executor | dirty pending targets | current |
| buffers.switcher.pending-mark.dirty-remove-selected | Remove the selected dirty pending marked-close target without closing, saving, discarding, or changing marks. | Navigation | General | yes | yes | conditional | Executor | dirty pending targets | current |

### Dirty-Prune Preview

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.pending-mark.dirty-prune.preview | Capture all currently dirty pending marked-close targets for explicit bulk pruning. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.apply | Capture the current dirty-prune preview targets for explicit apply confirmation without pruning pending close targets. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.cancel | Clear the prepared dirty pending marked-close prune without mutation. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.summary | Report captured and still-applicable dirty pending marked-close prune targets. | Navigation | General | yes | yes | no | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.next | Move open-buffer list selection to the next captured dirty-prune preview target without activating or pruning it. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.previous | Move open-buffer list selection to the previous captured dirty-prune preview target without activating or pruning it. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.review.toggle | Toggle review of captured dirty-prune preview targets in the Open Buffer List. | Navigation | General | yes | yes | no | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.review.show | Show captured dirty-prune preview targets in the Open Buffer List without applying them. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.review.hide | Return the open-buffer list to its normal view without clearing the dirty-prune preview. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.remove-selected | Remove the selected buffer from the prepared dirty-prune preview without pruning pending close targets. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.restore-last-removed | Restore the most recently removed buffer to the prepared dirty-prune preview without pruning pending close targets. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.removed-summary | Report dirty-prune preview targets removed from the current prepared preview. | Navigation | General | yes | yes | no | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.removed-next | Move open-buffer list selection to the next still-open target removed from the dirty-prune preview without restoring or activating it. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.removed-previous | Move open-buffer list selection to the previous still-open target removed from the dirty-prune preview without restoring or activating it. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.clear-stale | Remove stale targets from the prepared dirty-prune preview without pruning active pending close targets. | Navigation | General | yes | yes | conditional | Executor | dirty-prune preview | current |
| buffers.switcher.pending-mark.dirty-prune.stale-summary | Report stale targets in the prepared dirty-prune preview without mutating it. | Navigation | General | yes | yes | no | Executor | dirty-prune preview | current |

### Dirty-Prune Apply Confirmation

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| buffers.switcher.pending-mark.dirty-prune.apply.confirm | Confirm and prune captured dirty-prune apply targets that are still open, pending, and dirty. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.cancel | Clear the pending dirty-prune apply confirmation without mutating preview or pending close targets. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.summary | Report captured and still-applicable dirty-prune apply confirmation targets. | Navigation | General | yes | yes | no | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.next | Move open-buffer list selection to the next captured dirty-prune apply target without activating or pruning it. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.previous | Move open-buffer list selection to the previous captured dirty-prune apply target without activating or pruning it. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.review.toggle | Toggle review of captured dirty-prune apply targets in the Open Buffer List. | Navigation | General | yes | yes | no | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.review.show | Show captured dirty-prune apply targets in the Open Buffer List without confirming them. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.review.hide | Return the open-buffer list to its normal view without clearing dirty-prune apply confirmation. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.remove-selected | Remove the selected buffer from dirty-prune apply confirmation without mutating the preview or pending close targets. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.restore-last-removed | Restore the most recently removed buffer to dirty-prune apply confirmation. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.removed-summary | Report targets removed from the current dirty-prune apply confirmation. | Navigation | General | yes | yes | no | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.removed-next | Move open-buffer list selection to the next still-open target removed from dirty-prune apply confirmation. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.removed-previous | Move open-buffer list selection to the previous still-open target removed from dirty-prune apply confirmation. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.clear-stale | Remove stale targets from dirty-prune apply confirmation without recording removals or pruning pending close targets. | Navigation | General | yes | yes | conditional | Executor | dirty-prune apply confirmation | current |
| buffers.switcher.pending-mark.dirty-prune.apply.stale-summary | Report stale targets in the pending dirty-prune apply confirmation without mutating it. | Navigation | General | yes | yes | no | Executor | dirty-prune apply confirmation | current |

### Cleanup, Reopen, Recent Buffers

| Stable name | Short description | Category | Class | Bindable | Palette | Hint | Route | Owner | Status |
|---|---|---|---|---:|---:|---:|---|---|---|
| file.close-other-buffers | Close every non-active clean buffer and leave dirty buffers open. | File | Destructive+Lifecycle | yes | yes | no | Executor | buffer cleanup policy | current |
| file.close-clean-buffers | Close clean buffers while leaving dirty buffers open. | File | Destructive+Lifecycle | yes | yes | no | Executor | buffer cleanup policy | current |
| buffers.recent.previous | Switch to the most recently used non-active open buffer | File | Lifecycle | yes | yes | no | Executor | recent-buffer traversal | current |
| buffers.recent.next | Move forward through recent-buffer traversal | File | Lifecycle | yes | yes | no | Executor | recent-buffer traversal | current |

<!-- switcher-command-table:end -->

## Mutation Notes

- Marks and mark presets mutate only the switcher mark set unless a later confirmation command explicitly performs lifecycle work.
- Pending marked-close prepare/confirm/cancel is owned by the pending marked-close workflow. Confirmed close operations must use guarded close policy and create reopen entries only for successfully closed buffers.
- Dirty-prune preview commands mutate only active preview targets and removed-preview history. They do not close buffers, mutate active pending-close targets, or create ordinary pruned history.
- Dirty-prune apply commands mutate captured apply-confirmation targets. Confirm may prune active pending-close targets and ordinary pruned history after revalidation; it does not close buffers.
- Cleanup commands use guarded cleanup policy and preserve dirty buffers according to the existing close guards.
- Reopen and recent-buffer commands are owned by the reopen stack and recent-buffer traversal state respectively.

## Optional Absent Commands

No optional absent switcher commands are documented in this snapshot. If a future baseline records optional absent commands, they must remain absent from descriptors, hints, keybindings, and Command Palette projection.

## Accepted Command Names

Only current Open Buffer Switcher command names are accepted.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.


Pass1237 adds Editor.Ada_Predicate_Generic_Shared_State_Final_Legality. It connects predicate/invariant use-site and propagation evidence to the generic/shared-state final semantic chain, preserving blocker-family identity across generic replay, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, dispatching Global/Depends, cross-unit closure, stabilized shared-state closure, source-fingerprint, substitution-fingerprint, multiple-blocker, and indeterminate states.


Pass1238 adds Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality. It integrates definite-initialization/dataflow legality with the generic/shared-state final chain, preserving blocker families for initialization, dataflow, predicates, generic replay, shared-state closure, representation/freezing, tasking/protected, accessibility, discriminants, exception/finalization, renaming, volatile/atomic representation, access escape, variant components, finalization, and fingerprint mismatches.

Pass1239: Added generic/shared-state final diagnostic integration and feed support. The integration exposes only blocking rows while preserving original semantic blocker-family identity and withholds accepted rows as current semantic evidence.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1254: Predicate/invariant RM completion now consumes the completed generic/shared-state RM chain and keeps prerequisite blocker families distinct for downstream semantic closure.


Pass1256: RM-completed generic/shared-state diagnostic integration now exposes completed-chain blockers while withholding accepted rows as current semantic evidence.


Pass1258 — Coverage-proven RM-completion AST repair legality
Adds coverage-proven AST repair over the RM-completed generic/shared-state chain while preserving blocker-family identity.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1260: Added generic/shared-state RM-completion recheck application legality, preserving RM-completion blocker-family identity while applying eligibility back into the semantic closure/feed boundary.


Pass1262 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality. It consumes RM-completion recheck convergence rows and promotes only stable generic/shared-state RM-completion conclusions while preserving prerequisite blocker-family identity for withheld rows.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
