with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Accessibility_Lifetime_Legality is

   --  Pass1111 compiler-grade accessibility/lifetime/aliasing legality layer.
   --  This package consolidates Ada access-related legality metadata for
   --  accessibility levels, anonymous access parameters, allocators, access
   --  discriminants, return accessibility, aliased-object requirements, and
   --  linked assignment/return/conversion/staticness legality.  It is
   --  snapshot-owned and projection-free: no parsing, file IO, save/reload,
   --  dirty-state mutation, compiler invocation, command registration,
   --  keybinding/workspace mutation, or render-side analysis.

   subtype Assignment_Legality_Id is
     Editor.Ada_Assignment_Legality.Assignment_Legality_Id;
   subtype Assignment_Legality_Status is
     Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   subtype Return_Legality_Id is
     Editor.Ada_Return_Legality.Return_Legality_Id;
   subtype Return_Legality_Status is
     Editor.Ada_Return_Legality.Return_Legality_Status;
   subtype Semantic_Legality_Id is
     Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Id;
   subtype Semantic_Legality_Status is
     Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status;
   subtype Static_Legality_Id is
     Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Id;
   subtype Static_Legality_Status is
     Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status;

   type Accessibility_Context_Id is new Natural;
   No_Accessibility_Context : constant Accessibility_Context_Id := 0;

   type Accessibility_Legality_Id is new Natural;
   No_Accessibility_Legality : constant Accessibility_Legality_Id := 0;

   type Access_Context_Kind is
     (Access_Context_Object_Assignment,
      Access_Context_Subprogram_Assignment,
      Access_Context_Anonymous_Access_Parameter,
      Access_Context_Access_Conversion,
      Access_Context_Allocator,
      Access_Context_Access_Discriminant,
      Access_Context_Return_Object,
      Access_Context_Return_Access,
      Access_Context_Aliased_Object_Reference,
      Access_Context_Renaming,
      Access_Context_Generic_Actual,
      Access_Context_Aggregate_Component,
      Access_Context_Unknown);

   type Access_Target_Kind is
     (Access_Target_None,
      Access_Target_Object,
      Access_Target_Subprogram,
      Access_Target_Protected_Subprogram,
      Access_Target_Incomplete_View,
      Access_Target_Unknown);

   type Accessibility_Level is
     (Accessibility_Level_Library,
      Accessibility_Level_Unit,
      Accessibility_Level_Master,
      Accessibility_Level_Local,
      Accessibility_Level_Deeper,
      Accessibility_Level_Unknown);

   type Alias_Requirement is
     (Alias_Not_Required,
      Alias_Required,
      Alias_Satisfied,
      Alias_Missing,
      Alias_Unknown);

   type Accessibility_Legality_Status is
     (Accessibility_Legality_Not_Checked,
      Accessibility_Legality_Static_Compatible,
      Accessibility_Legality_Dynamic_Check_Required,
      Accessibility_Legality_Null_Exclusion_Checked,
      Accessibility_Legality_Aliased_Object_Compatible,
      Accessibility_Legality_Allocator_Compatible,
      Accessibility_Legality_Access_Conversion_Compatible,
      Accessibility_Legality_Return_Access_Compatible,
      Accessibility_Legality_Null_Exclusion_Violation,
      Accessibility_Legality_Access_Kind_Mismatch,
      Accessibility_Legality_Target_Not_Aliased,
      Accessibility_Legality_Level_Too_Deep,
      Accessibility_Legality_Return_Object_Too_Short_Lived,
      Accessibility_Legality_Anonymous_Access_Level_Unresolved,
      Accessibility_Legality_Allocator_Designated_Subtype_Mismatch,
      Accessibility_Legality_Access_Discriminant_Lifetime_Error,
      Accessibility_Legality_Access_Parameter_Escapes,
      Accessibility_Legality_Dangling_Rename_Risk,
      Accessibility_Legality_Private_View_Barrier,
      Accessibility_Legality_Limited_View_Barrier,
      Accessibility_Legality_Cross_Unit_Unresolved_View,
      Accessibility_Legality_Linked_Assignment_Error,
      Accessibility_Legality_Linked_Return_Error,
      Accessibility_Legality_Linked_Semantic_Error,
      Accessibility_Legality_Linked_Staticness_Error,
      Accessibility_Legality_Indeterminate);

   type Accessibility_Context_Info is record
      Id                     : Accessibility_Context_Id := No_Accessibility_Context;
      Kind                   : Access_Context_Kind := Access_Context_Unknown;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Access          : Access_Target_Kind := Access_Target_Unknown;
      Target_Access          : Access_Target_Kind := Access_Target_Unknown;
      Source_Level           : Accessibility_Level := Accessibility_Level_Unknown;
      Target_Level           : Accessibility_Level := Accessibility_Level_Unknown;
      Source_Is_Null_Literal : Boolean := False;
      Target_Is_Null_Excluding : Boolean := False;
      Requires_Aliased_Target : Boolean := False;
      Target_Is_Aliased      : Boolean := False;
      Alias_State            : Alias_Requirement := Alias_Not_Required;
      Requires_Dynamic_Check : Boolean := False;
      Accessibility_Known_Compatible : Boolean := False;
      Escapes_Current_Master : Boolean := False;
      Return_Object_Context  : Boolean := False;
      Access_Discriminant_Context : Boolean := False;
      Private_View_Barrier   : Boolean := False;
      Limited_View_Barrier   : Boolean := False;
      Cross_Unit_Unresolved  : Boolean := False;
      Assignment             : Assignment_Legality_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Legality;
      Assignment_Status      : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Item            : Return_Legality_Id :=
        Editor.Ada_Return_Legality.No_Return_Legality;
      Return_Status          : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Semantic_Item          : Semantic_Legality_Id :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.No_Semantic_Legality;
      Semantic_Status        : Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Static_Item            : Static_Legality_Id :=
        Editor.Ada_Staticness_Range_Predicate_Legality.No_Static_Legality;
      Static_Status          : Static_Legality_Status :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Source_Fingerprint     : Natural := 0;
   end record;

   type Accessibility_Legality_Info is record
      Id                     : Accessibility_Legality_Id := No_Accessibility_Legality;
      Context                : Accessibility_Context_Id := No_Accessibility_Context;
      Kind                   : Access_Context_Kind := Access_Context_Unknown;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                 : Accessibility_Legality_Status := Accessibility_Legality_Not_Checked;
      Message                : Ada.Strings.Unbounded.Unbounded_String;
      Detail                 : Ada.Strings.Unbounded.Unbounded_String;
      Source_Access          : Access_Target_Kind := Access_Target_Unknown;
      Target_Access          : Access_Target_Kind := Access_Target_Unknown;
      Source_Level           : Accessibility_Level := Accessibility_Level_Unknown;
      Target_Level           : Accessibility_Level := Accessibility_Level_Unknown;
      Alias_State            : Alias_Requirement := Alias_Not_Required;
      Assignment_Status      : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Status          : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Semantic_Status        : Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Static_Status          : Static_Legality_Status :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Source_Fingerprint     : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

   type Accessibility_Context_Model is private;
   type Accessibility_Result_Set is private;
   type Accessibility_Legality_Model is private;

   procedure Clear (Model : in out Accessibility_Context_Model);
   procedure Add_Context
     (Model : in out Accessibility_Context_Model;
      Info  : Accessibility_Context_Info);

   function Context_Count (Model : Accessibility_Context_Model) return Natural;
   function Context_At
     (Model : Accessibility_Context_Model;
      Index : Positive) return Accessibility_Context_Info;
   function Fingerprint (Model : Accessibility_Context_Model) return Natural;

   function Build
     (Contexts : Accessibility_Context_Model) return Accessibility_Legality_Model;

   function Build_Contexts_From_Semantic_Legality
     (Semantics : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model)
      return Accessibility_Context_Model;

   function Legality_Count (Model : Accessibility_Legality_Model) return Natural;
   function Legality_At
     (Model : Accessibility_Legality_Model;
      Index : Positive) return Accessibility_Legality_Info;

   function First_For_Node
     (Model : Accessibility_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_Legality_Info;
   function Rows_For_Status
     (Model  : Accessibility_Legality_Model;
      Status : Accessibility_Legality_Status) return Accessibility_Result_Set;
   function Rows_For_Kind
     (Model : Accessibility_Legality_Model;
      Kind  : Access_Context_Kind) return Accessibility_Result_Set;
   function Rows_For_Alias_State
     (Model : Accessibility_Legality_Model;
      State : Alias_Requirement) return Accessibility_Result_Set;
   function Rows_For_Level
     (Model : Accessibility_Legality_Model;
      Level : Accessibility_Level) return Accessibility_Result_Set;

   function Result_Count (Results : Accessibility_Result_Set) return Natural;
   function Result_At
     (Results : Accessibility_Result_Set;
      Index   : Positive) return Accessibility_Legality_Info;

   function Count_Status
     (Model  : Accessibility_Legality_Model;
      Status : Accessibility_Legality_Status) return Natural;
   function Count_Kind
     (Model : Accessibility_Legality_Model;
      Kind  : Access_Context_Kind) return Natural;
   function Count_Alias_State
     (Model : Accessibility_Legality_Model;
      State : Alias_Requirement) return Natural;
   function Count_Level
     (Model : Accessibility_Legality_Model;
      Level : Accessibility_Level) return Natural;

   function Legal_Count (Model : Accessibility_Legality_Model) return Natural;
   function Error_Count (Model : Accessibility_Legality_Model) return Natural;
   function Lifetime_Error_Count (Model : Accessibility_Legality_Model) return Natural;
   function Null_Exclusion_Error_Count (Model : Accessibility_Legality_Model) return Natural;
   function Aliasing_Error_Count (Model : Accessibility_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Accessibility_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Accessibility_Legality_Model) return Natural;
   function Fingerprint (Model : Accessibility_Legality_Model) return Natural;

   function Has_Legality (Info : Accessibility_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Accessibility_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Accessibility_Legality_Info);

   type Accessibility_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Accessibility_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Accessibility_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Lifetime_Error_Total : Natural := 0;
      Null_Exclusion_Error_Total : Natural := 0;
      Aliasing_Error_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Accessibility_Lifetime_Legality;
