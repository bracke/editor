Pass 317 completeness update

This pass tightens the expanded Ada declaration grammar after pass316.  It adds first-class syntax-tree declarations for abstract subprogram declarations, null procedure declarations, and expression function declarations instead of folding those source forms into generic subprogram/body nodes.

It also adds structured declaration child nodes for subprogram profiles and function result subtypes so subprogram-family declarations now expose name/profile/result/mode metadata in the syntax tree.  The  language validation guard and AUnit declaration-grammar coverage were extended accordingly.

No Python, shell scripts, or parser-generator tooling are part of the project source.
