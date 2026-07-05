# Product Workflow

The daily editor loop is:

1. Open or restore a project.
2. Open files through File Tree, recent buffers, or Quick Open.
3. Search within the active buffer or project.
4. Edit, save, reload, or revert buffers through lifecycle-aware commands.
5. Run builds and inspect Build Output, Diagnostics, and related navigation.
6. Use Outline, Messages, Search Results, and Terminal as focused panels.

User-facing status text should describe the visible condition and, when useful,
the next action. It must not expose implementation identifiers, generated object
names, test-only wording, or historical pass labels.

Historical product-workflow evidence is archived at
`docs/archive/active_doc_history/product_workflow.md`.
