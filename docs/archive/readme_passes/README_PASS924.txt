Editor IDE-grade Outline / Semantic Colouring / Ada Parser - Pass924

Summary:
- Added Production_Object_Subtype_Reserved_Boundary_Recovery_Boundary.
- Refined malformed object declaration subtype/access-definition recovery so reserved/aspect boundary tokens after ':' are not treated as subtype marks.
- Added AUnit regression Test_Language_Model_Token_Cursor_Object_Subtype_Reserved_Boundary_Recovery_Pass924.
- Updated validation guards, parser coverage matrix, syntax-colouring notes, release checklist, and README.

Covered malformed forms include:
- Missing_With : with Volatile;
- Missing_Then : then;

Preserved metadata includes:
- Production_Object_Declaration
- Production_Object_Declaration_Recovery_Boundary
- Production_Recovery_Point
- valid following object initializer metadata

This improves structural grammar coverage for malformed Ada object subtype indications. It is not compiler-grade object declaration legality checking, subtype legality checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
