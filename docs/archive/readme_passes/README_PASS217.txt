Editor pass 217

This pass adds bounded Ada entry-family declaration metadata to the parser-owned
language model. Entry family index groups are retained as metadata on the entry
symbol and surfaced in Outline details, without creating standalone Outline rows
or semantic declaration symbols for the index subtype/choices.
