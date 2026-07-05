IDE-grade Outline/Semantic Colouring pass 124

This pass hardens compact generic tail parsing for named anonymous declare/accept blocks containing local callable bodies. It mirrors the package-tail anonymous block name stack in the generic tail splitter so `end Local_Run;` inside a named same-line declare block does not consume the surrounding block's `end Local_Block;` marker.

Validation in this container:
- zip integrity checked after packaging
- no Python or shell scripts added
- Ada build/AUnit not run because gprbuild/alr/gnatmake are unavailable
