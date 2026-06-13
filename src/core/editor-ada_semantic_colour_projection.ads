with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Diagnostics;
with Editor.Ada_Expression_Diagnostics;
with Editor.Ada_Generic_Contract_Diagnostics;
with Editor.Ada_Representation_Diagnostics;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Semantic_Colour_Projection is

   --  Projection-only semantic colouring bridge for parser-owned Ada semantic
   --  diagnostics.  This package does not parse, read files, mutate buffers,
   --  register commands, or perform rendering.  It converts already-built
   --  expression, generic-contract, cross-unit, and representation/freezing
   --  diagnostic metadata into deterministic syntax-token overlays that the
   --  existing rendering path may consume as plain projection data.

   type Semantic_Colour_Entry_Id is new Natural;
   No_Semantic_Colour_Entry : constant Semantic_Colour_Entry_Id := 0;

   type Semantic_Colour_Source is
     (Semantic_Colour_From_Expression,
      Semantic_Colour_From_Generic_Contract,
      Semantic_Colour_From_Cross_Unit,
      Semantic_Colour_From_Representation);

   type Semantic_Colour_Severity is
     (Semantic_Colour_Info,
      Semantic_Colour_Warning,
      Semantic_Colour_Error);

   type Semantic_Colour_Entry is record
      Id       : Semantic_Colour_Entry_Id := No_Semantic_Colour_Entry;
      Source   : Semantic_Colour_Source := Semantic_Colour_From_Expression;
      Severity : Semantic_Colour_Severity := Semantic_Colour_Info;
      Token    : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Fingerprint  : Natural := 0;
   end record;

   type Semantic_Colour_Model is private;

   procedure Clear (Model : in out Semantic_Colour_Model);

   function Build
     (Expressions     : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Generics        : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
      Cross_Units     : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Representation  : Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model)
      return Semantic_Colour_Model;

   function Entry_Count (Model : Semantic_Colour_Model) return Natural;
   function Entry_At
     (Model : Semantic_Colour_Model;
      Index : Positive) return Semantic_Colour_Entry;

   function Error_Count (Model : Semantic_Colour_Model) return Natural;
   function Warning_Count (Model : Semantic_Colour_Model) return Natural;
   function Info_Count (Model : Semantic_Colour_Model) return Natural;
   function Count_Source
     (Model  : Semantic_Colour_Model;
      Source : Semantic_Colour_Source) return Natural;
   function Count_Token
     (Model : Semantic_Colour_Model;
      Token : Editor.Syntax.Token_Kind) return Natural;
   function Fingerprint (Model : Semantic_Colour_Model) return Natural;

private
   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Semantic_Colour_Entry);

   type Semantic_Colour_Model is record
      Entries            : Entry_Vectors.Vector;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Semantic_Colour_Projection;
