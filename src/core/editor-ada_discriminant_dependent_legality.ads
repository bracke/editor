with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Record_Variant_Aggregate_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Discriminant_Dependent_Legality is

   --  Case 1142 discriminant-dependent legality.
   --
   --  This package connects discriminant constraints/defaults and variant
   --  presence rules to the semantic use sites that can change or depend on a
   --  discriminated object: assignment, conversion, return, allocator,
   --  aggregate, and generic actual matching.  It consumes existing widened
   --  legality rows and coverage-gate enforcement instead of reparsing source
   --  text or emitting presentation-only diagnostics.

   type Discriminant_Context_Id is new Natural;
   No_Discriminant_Context : constant Discriminant_Context_Id := 0;

   type Discriminant_Legality_Id is new Natural;
   No_Discriminant_Legality : constant Discriminant_Legality_Id := 0;

   type Discriminant_Context_Kind is
     (Discriminant_Context_Record_Type,
      Discriminant_Context_Discriminant_Constraint,
      Discriminant_Context_Discriminant_Default,
      Discriminant_Context_Variant_Part,
      Discriminant_Context_Record_Aggregate,
      Discriminant_Context_Assignment,
      Discriminant_Context_Conversion,
      Discriminant_Context_Return,
      Discriminant_Context_Allocator,
      Discriminant_Context_Generic_Actual,
      Discriminant_Context_Private_Full_View,
      Discriminant_Context_Unknown);

   type Discriminant_Legality_Status is
     (Discriminant_Legality_Not_Checked,
      Discriminant_Legality_Legal_Constrained_Record,
      Discriminant_Legality_Legal_Unconstrained_With_Defaults,
      Discriminant_Legality_Legal_Discriminant_Default,
      Discriminant_Legality_Legal_Variant_Presence,
      Discriminant_Legality_Legal_Aggregate_Discriminants,
      Discriminant_Legality_Legal_Assignment_Check,
      Discriminant_Legality_Legal_Conversion_Check,
      Discriminant_Legality_Legal_Return_Check,
      Discriminant_Legality_Legal_Allocator_Check,
      Discriminant_Legality_Legal_Generic_Actual_Check,
      Discriminant_Legality_Missing_Discriminant_Constraint,
      Discriminant_Legality_Duplicate_Discriminant_Constraint,
      Discriminant_Legality_Discriminant_Type_Mismatch,
      Discriminant_Legality_Default_Not_Static,
      Discriminant_Legality_Default_Out_Of_Range,
      Discriminant_Legality_Default_Depends_On_Later_Discriminant,
      Discriminant_Legality_Unconstrained_Record_Without_Defaults,
      Discriminant_Legality_Constrained_Object_Discriminant_Changed,
      Discriminant_Legality_Assignment_Discriminant_Mismatch,
      Discriminant_Legality_Conversion_Discriminant_Mismatch,
      Discriminant_Legality_Return_Discriminant_Mismatch,
      Discriminant_Legality_Allocator_Discriminant_Mismatch,
      Discriminant_Legality_Generic_Actual_Discriminant_Mismatch,
      Discriminant_Legality_Variant_Missing_For_Value,
      Discriminant_Legality_Variant_Forbidden_For_Value,
      Discriminant_Legality_Variant_Choice_Overlap,
      Discriminant_Legality_Variant_Choice_Coverage_Gap,
      Discriminant_Legality_Linked_Record_Aggregate_Error,
      Discriminant_Legality_Linked_Assignment_Error,
      Discriminant_Legality_Linked_Conversion_Error,
      Discriminant_Legality_Linked_Return_Error,
      Discriminant_Legality_Linked_Generic_Replay_Error,
      Discriminant_Legality_Private_Full_View_Mismatch,
      Discriminant_Legality_Coverage_Gate_Blocker,
      Discriminant_Legality_Multiple_Blockers,
      Discriminant_Legality_Indeterminate);

   type Discriminant_Context_Info is record
      Id       : Discriminant_Context_Id := No_Discriminant_Context;
      Kind     : Discriminant_Context_Kind := Discriminant_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name : Ada.Strings.Unbounded.Unbounded_String;
      Discriminant_Count : Natural := 0;
      Expected_Discriminant_Count : Natural := 0;
      Missing_Discriminant_Count : Natural := 0;
      Duplicate_Discriminant_Count : Natural := 0;
      Type_Mismatch_Count : Natural := 0;
      Defaulted_Discriminant_Count : Natural := 0;
      Nonstatic_Default_Count : Natural := 0;
      Out_Of_Range_Default_Count : Natural := 0;
      Later_Dependent_Default_Count : Natural := 0;
      Type_Is_Constrained : Boolean := False;
      Type_Is_Unconstrained : Boolean := False;
      Object_Is_Constrained : Boolean := False;
      Discriminant_Value_Changed : Boolean := False;
      Variant_Choice_Count : Natural := 0;
      Expected_Variant_Choice_Count : Natural := 0;
      Missing_Variant_For_Value : Boolean := False;
      Forbidden_Variant_For_Value : Boolean := False;
      Variant_Overlap_Count : Natural := 0;
      Variant_Coverage_Gap_Count : Natural := 0;
      Private_Full_View_Mismatch : Boolean := False;
      Linked_Record_Status : Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Status :=
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Not_Checked;
      Linked_Assignment_Status : Editor.Ada_Assignment_Legality.Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Linked_Conversion_Status : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Linked_Return_Status : Editor.Ada_Return_Legality.Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Linked_Replay_Status : Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Status :=
        Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Not_Checked;
      Gate_Status : Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Status :=
        Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Not_Checked;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
   end record;

   type Discriminant_Legality_Info is record
      Id       : Discriminant_Legality_Id := No_Discriminant_Legality;
      Context  : Discriminant_Context_Id := No_Discriminant_Context;
      Kind     : Discriminant_Context_Kind := Discriminant_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Discriminant_Legality_Status := Discriminant_Legality_Not_Checked;
      Type_Name : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name : Ada.Strings.Unbounded.Unbounded_String;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      Discriminant_Count : Natural := 0;
      Expected_Discriminant_Count : Natural := 0;
      Variant_Choice_Count : Natural := 0;
      Expected_Variant_Choice_Count : Natural := 0;
      Blocker_Count : Natural := 0;
      Gate_Status : Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Status :=
        Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Not_Checked;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Discriminant_Context_Model is private;
   type Discriminant_Result_Set is private;
   type Discriminant_Legality_Model is private;

   procedure Clear (Model : in out Discriminant_Context_Model);
   procedure Add_Context
     (Model : in out Discriminant_Context_Model;
      Info  : Discriminant_Context_Info);

   function Context_Count (Model : Discriminant_Context_Model) return Natural;
   function Context_At
     (Model : Discriminant_Context_Model;
      Index : Positive) return Discriminant_Context_Info;
   function Fingerprint (Model : Discriminant_Context_Model) return Natural;

   function Build (Contexts : Discriminant_Context_Model) return Discriminant_Legality_Model;

   function Row_Count (Model : Discriminant_Legality_Model) return Natural;
   function Row_At
     (Model : Discriminant_Legality_Model;
      Index : Positive) return Discriminant_Legality_Info;
   function First_For_Node
     (Model : Discriminant_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Legality_Info;
   function Rows_For_Status
     (Model  : Discriminant_Legality_Model;
      Status : Discriminant_Legality_Status) return Discriminant_Result_Set;
   function Rows_For_Kind
     (Model : Discriminant_Legality_Model;
      Kind  : Discriminant_Context_Kind) return Discriminant_Result_Set;
   function Rows_For_Type
     (Model     : Discriminant_Legality_Model;
      Type_Name : String) return Discriminant_Result_Set;

   function Result_Count (Results : Discriminant_Result_Set) return Natural;
   function Result_At
     (Results : Discriminant_Result_Set;
      Index   : Positive) return Discriminant_Legality_Info;

   function Count_Status
     (Model  : Discriminant_Legality_Model;
      Status : Discriminant_Legality_Status) return Natural;
   function Count_Kind
     (Model : Discriminant_Legality_Model;
      Kind  : Discriminant_Context_Kind) return Natural;

   function Legal_Count (Model : Discriminant_Legality_Model) return Natural;
   function Error_Count (Model : Discriminant_Legality_Model) return Natural;
   function Variant_Error_Count (Model : Discriminant_Legality_Model) return Natural;
   function Default_Error_Count (Model : Discriminant_Legality_Model) return Natural;
   function Use_Site_Error_Count (Model : Discriminant_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Discriminant_Legality_Model) return Natural;
   function Coverage_Gate_Error_Count (Model : Discriminant_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Discriminant_Legality_Model) return Natural;
   function Fingerprint (Model : Discriminant_Legality_Model) return Natural;

   function Has_Legality (Info : Discriminant_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Discriminant_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Discriminant_Legality_Info);

   type Discriminant_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Discriminant_Result_Set is record
      Items : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Discriminant_Legality_Model is record
      Rows : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Discriminant_Dependent_Legality;
