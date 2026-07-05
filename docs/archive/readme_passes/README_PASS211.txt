IDE-grade outline/semantic language-model pass 211

This pass adds parser/model metadata for Ada access and array declaration forms. The parser retains these forms on owning symbols and keeps their subtype/profile details as bounded target/profile metadata rather than emitting keyword or anonymous-expression symbols.
