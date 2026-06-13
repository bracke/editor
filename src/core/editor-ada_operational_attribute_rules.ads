with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Operational_Attribute_Rules is

   --  Compiler-grade operational-attribute conflict foundation.  This model
   --  consumes the unified representation-legality stream, after aspect vs
   --  attribute-definition normalization, and records duplicate/conflicting
   --  operational properties without mutating analysis, rendering, command,
   --  workspace, or buffer state.

   type Operational_Rule_Status is
     (Operational_Rule_Ok,
      Operational_Rule_Duplicate_Property,
      Operational_Rule_Conflicting_Boolean_Value,
      Operational_Rule_Target_Error,
      Operational_Rule_Value_Error,
      Operational_Rule_Unknown);

   type Operational_Boolean_Value is
     (Operational_Boolean_None,
      Operational_Boolean_True,
      Operational_Boolean_False,
      Operational_Boolean_Unknown);

   type Operational_Rule_Info is record
      Clause_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target  : Ada.Strings.Unbounded.Unbounded_String;
      Clause_Kind        : Editor.Ada_Language_Model.Representation_Clause_Kind :=
        Editor.Ada_Language_Model.Representation_Other_Clause;
      Source_Form        : Editor.Ada_Language_Model.Representation_Source_Form :=
        Editor.Ada_Language_Model.Representation_Source_Attribute_Definition;
      Boolean_Value      : Operational_Boolean_Value := Operational_Boolean_None;
      Previous_Clause    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Previous_Value     : Operational_Boolean_Value := Operational_Boolean_None;
      Status             : Operational_Rule_Status := Operational_Rule_Unknown;
      Source_Line        : Positive := 1;
      Fingerprint        : Natural := 0;
   end record;

   type Operational_Rule_Model is private;

   procedure Clear (Model : in out Operational_Rule_Model);

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model)
      return Operational_Rule_Model;

   function Rule_Count (Model : Operational_Rule_Model) return Natural;

   function Rule_At
     (Model : Operational_Rule_Model;
      Index : Positive) return Operational_Rule_Info;

   function Duplicate_Count (Model : Operational_Rule_Model) return Natural;
   function Conflict_Count (Model : Operational_Rule_Model) return Natural;
   function Target_Error_Count (Model : Operational_Rule_Model) return Natural;
   function Value_Error_Count (Model : Operational_Rule_Model) return Natural;
   function Ok_Count (Model : Operational_Rule_Model) return Natural;
   function Unknown_Count (Model : Operational_Rule_Model) return Natural;
   function Fingerprint (Model : Operational_Rule_Model) return Natural;

private
   package Rule_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Operational_Rule_Info);

   type Operational_Rule_Model is record
      Rules              : Rule_Vectors.Vector;
      Duplicate_Total    : Natural := 0;
      Conflict_Total     : Natural := 0;
      Target_Error_Total : Natural := 0;
      Value_Error_Total  : Natural := 0;
      Ok_Total           : Natural := 0;
      Unknown_Total      : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Operational_Attribute_Rules;
