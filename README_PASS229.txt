Pass 229 parser-completeness increment.

Adds bounded Ada body-stub metadata to the language model and parser. The parser now records `is separate` body stubs on owning package/subprogram/task/protected declarations while keeping actual `separate (...)` subunits modeled separately. Outline details project `body-stub`, and regression coverage/validation guards require the new bounded metadata path.
