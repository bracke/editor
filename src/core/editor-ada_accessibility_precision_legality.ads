with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
with Editor.Ada_Record_Variant_Aggregate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Accessibility_Precision_Legality is

   --  Pass1128 compiler-grade accessibility precision layer.
   --
   --  This package deepens the Pass1111 accessibility/lifetime model by
   --  connecting nested accessibility levels, anonymous access parameters,
   --  allocator masters, access discriminants, return accessibility,
   --  generic-instance actual lifetime substitution, and record/variant
   --  aggregate discriminant contexts.  It remains snapshot-owned and
   --  projection-free: callers provide semantic facts; this package performs
   --  no parsing, file IO, editor mutation, command registration, compiler
   --  invocation, or render-side analysis.

   subtype Accessibility_Legality_Status is
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status;
   subtype Accessibility_Level is
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Level;
   subtype Access_Context_Kind is
     Editor.Ada_Accessibility_Lifetime_Legality.Access_Context_Kind;


   Unknown_Level : constant Accessibility_Level :=
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Level_Unknown;
   subtype Record_Aggregate_Legality_Status is
     Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Status;
   subtype Generic_Body_Expansion_Status is
     Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Status;

   type Accessibility_Precision_Context_Id is new Natural;
   No_Accessibility_Precision_Context : constant Accessibility_Precision_Context_Id := 0;

   type Accessibility_Precision_Legality_Id is new Natural;
   No_Accessibility_Precision_Legality : constant Accessibility_Precision_Legality_Id := 0;

   type Accessibility_Precision_Context_Kind is
     (Accessibility_Precision_Context_Nested_Access_Object,
      Accessibility_Precision_Context_Anonymous_Access_Parameter,
      Accessibility_Precision_Context_Access_Discriminant,
      Accessibility_Precision_Context_Allocator,
      Accessibility_Precision_Context_Return_Access,
      Accessibility_Precision_Context_Return_Object,
      Accessibility_Precision_Context_Access_Conversion,
      Accessibility_Precision_Context_Renaming,
      Accessibility_Precision_Context_Generic_Actual,
      Accessibility_Precision_Context_Record_Aggregate_Discriminant,
      Accessibility_Precision_Context_Unknown);

   type Accessibility_Precision_Status is
     (Accessibility_Precision_Not_Checked,
      Accessibility_Precision_Legal_Static_Level,
      Accessibility_Precision_Legal_Dynamic_Check,
      Accessibility_Precision_Legal_Allocator_Master,
      Accessibility_Precision_Legal_Return_Level,
      Accessibility_Precision_Legal_Access_Discriminant,
      Accessibility_Precision_Legal_Generic_Substitution,
      Accessibility_Precision_Legal_Aggregate_Discriminant,
      Accessibility_Precision_Anonymous_Access_Level_Too_Deep,
      Accessibility_Precision_Anonymous_Access_Level_Unresolved,
      Accessibility_Precision_Access_Parameter_Escapes,
      Accessibility_Precision_Allocator_Master_Too_Short,
      Accessibility_Precision_Allocator_Designated_Subtype_Mismatch,
      Accessibility_Precision_Return_Access_Too_Short_Lived,
      Accessibility_Precision_Return_Object_Too_Short_Lived,
      Accessibility_Precision_Access_Discriminant_Too_Short_Lived,
      Accessibility_Precision_Access_Discriminant_Unresolved,
      Accessibility_Precision_Access_Conversion_Level_Too_Deep,
      Accessibility_Precision_Renaming_Dangling_Risk,
      Accessibility_Precision_Generic_Actual_Too_Short_Lived,
      Accessibility_Precision_Generic_Actual_Unresolved,
      Accessibility_Precision_Aggregate_Discriminant_Lifetime_Error,
      Accessibility_Precision_Aggregate_Discriminant_Unresolved,
      Accessibility_Precision_Private_View_Barrier,
      Accessibility_Precision_Limited_View_Barrier,
      Accessibility_Precision_Cross_Unit_Unresolved_View,
      Accessibility_Precision_Linked_Accessibility_Error,
      Accessibility_Precision_Linked_Generic_Body_Error,
      Accessibility_Precision_Linked_Record_Aggregate_Error,
      Accessibility_Precision_Indeterminate);

   type Accessibility_Precision_Context_Info is record
      Id                    : Accessibility_Precision_Context_Id := No_Accessibility_Precision_Context;
      Kind                  : Accessibility_Precision_Context_Kind := Accessibility_Precision_Context_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Source_Level          : Accessibility_Level := Unknown_Level;
      Target_Level          : Accessibility_Level := Unknown_Level;
      Allocator_Master_Level : Accessibility_Level := Unknown_Level;
      Designated_Object_Level : Accessibility_Level := Unknown_Level;
      Return_Master_Level   : Accessibility_Level := Unknown_Level;
      Requires_Static_Check : Boolean := False;
      Requires_Dynamic_Check : Boolean := False;
      Anonymous_Access_Parameter : Boolean := False;
      Access_Parameter_Escapes : Boolean := False;
      Access_Discriminant_Context : Boolean := False;
      Allocator_Context     : Boolean := False;
      Return_Context        : Boolean := False;
      Generic_Actual_Context : Boolean := False;
      Aggregate_Discriminant_Context : Boolean := False;
      Designated_Subtype_Mismatch : Boolean := False;
      Private_View_Barrier  : Boolean := False;
      Limited_View_Barrier  : Boolean := False;
      Cross_Unit_Unresolved : Boolean := False;
      Base_Accessibility_Status : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Base_Access_Context   : Access_Context_Kind :=
        Editor.Ada_Accessibility_Lifetime_Legality.Access_Context_Unknown;
      Generic_Status        : Generic_Body_Expansion_Status :=
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Not_Checked;
      Record_Aggregate_Status : Record_Aggregate_Legality_Status :=
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Accessibility_Precision_Legality_Info is record
      Id                    : Accessibility_Precision_Legality_Id := No_Accessibility_Precision_Legality;
      Context               : Accessibility_Precision_Context_Id := No_Accessibility_Precision_Context;
      Kind                  : Accessibility_Precision_Context_Kind := Accessibility_Precision_Context_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Status                : Accessibility_Precision_Status := Accessibility_Precision_Not_Checked;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Level          : Accessibility_Level := Unknown_Level;
      Target_Level          : Accessibility_Level := Unknown_Level;
      Allocator_Master_Level : Accessibility_Level := Unknown_Level;
      Designated_Object_Level : Accessibility_Level := Unknown_Level;
      Return_Master_Level   : Accessibility_Level := Unknown_Level;
      Base_Accessibility_Status : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Generic_Status        : Generic_Body_Expansion_Status :=
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Not_Checked;
      Record_Aggregate_Status : Record_Aggregate_Legality_Status :=
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Accessibility_Precision_Context_Model is private;
   type Accessibility_Precision_Result_Set is private;
   type Accessibility_Precision_Legality_Model is private;

   procedure Clear (Model : in out Accessibility_Precision_Context_Model);
   procedure Add_Context
     (Model : in out Accessibility_Precision_Context_Model;
      Info  : Accessibility_Precision_Context_Info);

   function Context_Count (Model : Accessibility_Precision_Context_Model) return Natural;
   function Context_At
     (Model : Accessibility_Precision_Context_Model;
      Index : Positive) return Accessibility_Precision_Context_Info;
   function Fingerprint (Model : Accessibility_Precision_Context_Model) return Natural;

   function Build
     (Contexts : Accessibility_Precision_Context_Model) return Accessibility_Precision_Legality_Model;

   function Legality_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Legality_At
     (Model : Accessibility_Precision_Legality_Model;
      Index : Positive) return Accessibility_Precision_Legality_Info;

   function First_For_Node
     (Model : Accessibility_Precision_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_Precision_Legality_Info;
   function Rows_For_Status
     (Model  : Accessibility_Precision_Legality_Model;
      Status : Accessibility_Precision_Status) return Accessibility_Precision_Result_Set;
   function Rows_For_Kind
     (Model : Accessibility_Precision_Legality_Model;
      Kind  : Accessibility_Precision_Context_Kind) return Accessibility_Precision_Result_Set;
   function Rows_For_Object
     (Model : Accessibility_Precision_Legality_Model;
      Name  : String) return Accessibility_Precision_Result_Set;

   function Result_Count (Results : Accessibility_Precision_Result_Set) return Natural;
   function Result_At
     (Results : Accessibility_Precision_Result_Set;
      Index   : Positive) return Accessibility_Precision_Legality_Info;

   function Count_Status
     (Model  : Accessibility_Precision_Legality_Model;
      Status : Accessibility_Precision_Status) return Natural;
   function Count_Kind
     (Model : Accessibility_Precision_Legality_Model;
      Kind  : Accessibility_Precision_Context_Kind) return Natural;

   function Legal_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Dynamic_Check_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Anonymous_Access_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Allocator_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Return_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Discriminant_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Generic_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Accessibility_Precision_Legality_Model) return Natural;
   function Fingerprint (Model : Accessibility_Precision_Legality_Model) return Natural;

   function Has_Legality (Info : Accessibility_Precision_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Accessibility_Precision_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Accessibility_Precision_Legality_Info);

   type Accessibility_Precision_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Accessibility_Precision_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Accessibility_Precision_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Dynamic_Check_Total : Natural := 0;
      Anonymous_Access_Error_Total : Natural := 0;
      Allocator_Error_Total : Natural := 0;
      Return_Error_Total : Natural := 0;
      Discriminant_Error_Total : Natural := 0;
      Generic_Error_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Accessibility_Precision_Legality;
