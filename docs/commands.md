# Commands

Commands are registered through stable `Editor.Commands.Command_Id` values with
descriptor metadata, persisted stable names, bindability policy, palette
projection, availability checks, and executor routing.

## Copy Policy

Palette-visible command labels and descriptions are user-facing product copy.
They should:

- describe the action in plain language;
- avoid implementation terms such as route, fixture, payload, scaffold, or test;
- avoid fallback phrasing such as `Execute <label>.`;
- keep stable command IDs separate from display labels.

## Daily Command Groups

Core file and project commands:

- `project.open`, `project.close`, `project.switch`, `project.reopen-recent`
- `file.open`, `file.save`, `file.save-as`, `file.reload-buffer`,
  `file.revert-buffer`, `file.close-buffer`
- `file-tree.refresh`, `file-tree.open-selected`, `file-tree.create-file`,
  `file-tree.create-directory`, `file-tree.rename-selected`,
  `file-tree.delete-selected`

Navigation and search commands:

- `quick-open.show`, `quick-open.open-selected`
- `project.search.show`, `project.search.run`,
  `project.search.open-selected`
- `find.show`, `find.next`, `find.previous`
- `outline.show`, `outline.refresh`, `outline.open-selected`

Build and diagnostics commands:

- `build.run`, `build.cancel`
- `build.ui.show`, `build.ui.toggle`, `build.ui.hide`, `build.ui.focus`
- `build.refresh-candidates`, `build.select-first-candidate`,
  `build.select-next-candidate`, `build.select-previous-candidate`
- `diagnostics.show`, `diagnostics.open-selected`
- `problems.focus`, `problems.open-selected`
- `problems.filter.all`, `problems.filter.errors`,
  `problems.filter.warnings`, `problems.filter.info`,
  `problems.filter.hints`
- `terminal.show`, `terminal.toggle`, `terminal.run-selected-task`,
  `terminal.rerun-last-task`, `terminal.cancel-task`

Ada language commands:

- `outline.refresh-project-index`, `outline.goto-declaration`,
  `outline.goto-body`, `outline.goto-spec`
- `semantic.refresh-buffer`, `semantic.refresh-project-index`
- `language.index.clear`, `language.index.status`

Historical command-surface notes are archived at
`docs/archive/active_doc_history/commands.md`.
