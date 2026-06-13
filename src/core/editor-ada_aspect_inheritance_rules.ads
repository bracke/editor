with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Aspect_Inheritance_Rules is

   --  Compiler-grade representation/aspect inheritance foundation.  The model
   --  remains parser-owned and deterministic: it projects already-staged
   --  representation/aspect legality and type-graph relationships into
   --  inherited-property and explicit-override metadata without reading files,
   --  mutating buffers, or reaching into rendering/workspace state.

   type Aspect_Inheritance_Status is
     (Aspect_Inheritance_Not_Inherited,
      Aspect_Inheritance_Inherited,
      Aspect_Inheritance_Explicit_Override,
      Aspect_Inheritance_Explicit_Conflict,
      Aspect_Inheritance_Private_Partial_View,
      Aspect_Inheritance_Private_Full_View_Override,
      Aspect_Inheritance_Unknown);

   type Aspect_Inheritance_Info is record
      Target_Type        : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Ancestor_Type      : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Clause_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Ancestor_Clause    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Ancestor_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Property_Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind :=
        Editor.Ada_Language_Model.Representation_Other_Clause;
      Explicit_Source    : Editor.Ada_Language_Model.Representation_Source_Form :=
        Editor.Ada_Language_Model.Representation_Source_Attribute_Definition;
      Inherited_Value    : Ada.Strings.Unbounded.Unbounded_String;
      Explicit_Value     : Ada.Strings.Unbounded.Unbounded_String;
      Status             : Aspect_Inheritance_Status := Aspect_Inheritance_Unknown;
      Source_Line        : Positive := 1;
      Fingerprint        : Natural := 0;
   end record;

   type Aspect_Inheritance_Model is private;

   procedure Clear (Model : in out Aspect_Inheritance_Model);

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Types    : Editor.Ada_Type_Graph.Type_Model) return Aspect_Inheritance_Model;

   function Rule_Count (Model : Aspect_Inheritance_Model) return Natural;

   function Rule_At
     (Model : Aspect_Inheritance_Model;
      Index : Positive) return Aspect_Inheritance_Info;

   function Inherited_Count (Model : Aspect_Inheritance_Model) return Natural;
   function Override_Count (Model : Aspect_Inheritance_Model) return Natural;
   function Conflict_Count (Model : Aspect_Inheritance_Model) return Natural;
   function Private_View_Count (Model : Aspect_Inheritance_Model) return Natural;
   function Unknown_Count (Model : Aspect_Inheritance_Model) return Natural;
   function Fingerprint (Model : Aspect_Inheritance_Model) return Natural;

private
   package Rule_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Aspect_Inheritance_Info);

   type Aspect_Inheritance_Model is record
      Rules              : Rule_Vectors.Vector;
      Inherited_Total    : Natural := 0;
      Override_Total     : Natural := 0;
      Conflict_Total     : Natural := 0;
      Private_View_Total : Natural := 0;
      Unknown_Total      : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Aspect_Inheritance_Rules;
