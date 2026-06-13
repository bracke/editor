Editor Phase 579 pass 236

This pass adds bounded Ada task/protected interface metadata to the parser-owned language model. `task interface` and `protected interface` declarations now retain explicit qualifier metadata on their owning type/formal-type symbols, are reflected in Outline detail strings, and remain non-declarative for semantic colouring.
