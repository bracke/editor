with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Predicate_Invariant_Use_Site_Legality is

   --  Case 1124 compiler-grade semantic building block.  This package turns
   --  predicate/invariant metadata into use-site legality instead of leaving
   --  predicates as parallel staticness facts.  Callers provide snapshot-owned
   --  use-site facts for assignments, returns, conversions, aggregates, calls,
   --  generic actuals, and defaults; this package classifies whether subtype
   --  predicates and type invariants are known satisfied, dynamically required,
   --  unresolved, violated, or blocked by linked semantic legality.

   subtype Predicate_Policy is
     Editor.Ada_Staticness_Range_Predicate_Legality.Predicate_Policy;
   subtype Static_Legality_Status is
     Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status;
   subtype Assignment_Legality_Status is
     Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   subtype Return_Legality_Status is
     Editor.Ada_Return_Legality.Return_Legality_Status;
   subtype Semantic_Legality_Status is
     Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status;
   subtype Overload_Legality_Status is
     Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status;
   subtype Instance_Legality_Status is
     Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Status;

   type Predicate_Use_Context_Id is new Natural;
   No_Predicate_Use_Context : constant Predicate_Use_Context_Id := 0;

   type Predicate_Use_Legality_Id is new Natural;
   No_Predicate_Use_Legality : constant Predicate_Use_Legality_Id := 0;

   type Predicate_Use_Context_Kind is
     (Predicate_Use_Assignment,
      Predicate_Use_Object_Initialization,
      Predicate_Use_Return,
      Predicate_Use_Conversion,
      Predicate_Use_Qualified_Expression,
      Predicate_Use_Record_Aggregate,
      Predicate_Use_Array_Aggregate,
      Predicate_Use_Call_Actual,
      Predicate_Use_Default_Expression,
      Predicate_Use_Generic_Actual,
      Predicate_Use_Discriminant_Default,
      Predicate_Use_Component_Default,
      Predicate_Use_Unknown);

   type Invariant_Policy is
     (Invariant_Not_Present,
      Invariant_Known_Preserved,
      Invariant_Known_Violated,
      Invariant_Dynamic_Check_Required,
      Invariant_Unresolved,
      Invariant_Private_View_Barrier,
      Invariant_Unknown);

   type Use_Site_Check_Point is
     (Check_Point_Before_Assignment,
      Check_Point_After_Assignment,
      Check_Point_Return_Object,
      Check_Point_Conversion_Result,
      Check_Point_Aggregate_Result,
      Check_Point_Call_Entry,
      Check_Point_Call_Return,
      Check_Point_Generic_Instantiation,
      Check_Point_Default_Evaluation,
      Check_Point_Unknown);

   type Predicate_Use_Legality_Status is
     (Predicate_Use_Legality_Not_Checked,
      Predicate_Use_Legality_Legal_Static_Predicate,
      Predicate_Use_Legality_Legal_Dynamic_Predicate_Check,
      Predicate_Use_Legality_Legal_Invariant_Preserved,
      Predicate_Use_Legality_Legal_Dynamic_Invariant_Check,
      Predicate_Use_Legality_Legal_Static_Range_And_Predicate,
      Predicate_Use_Legality_Legal_Linked_Assignment,
      Predicate_Use_Legality_Legal_Linked_Return,
      Predicate_Use_Legality_Legal_Linked_Semantic,
      Predicate_Use_Legality_Legal_Linked_Overload,
      Predicate_Use_Legality_Legal_Linked_Generic_Actual,
      Predicate_Use_Legality_Static_Predicate_Failure,
      Predicate_Use_Legality_Predicate_Unresolved,
      Predicate_Use_Legality_Predicate_Non_Static_Where_Static_Required,
      Predicate_Use_Legality_Invariant_Violation,
      Predicate_Use_Legality_Invariant_Unresolved,
      Predicate_Use_Legality_Invariant_Private_View_Barrier,
      Predicate_Use_Legality_Missing_Check_At_Assignment,
      Predicate_Use_Legality_Missing_Check_At_Return,
      Predicate_Use_Legality_Missing_Check_At_Conversion,
      Predicate_Use_Legality_Missing_Check_At_Aggregate,
      Predicate_Use_Legality_Missing_Check_At_Call,
      Predicate_Use_Legality_Missing_Check_At_Generic_Actual,
      Predicate_Use_Legality_Linked_Staticness_Error,
      Predicate_Use_Legality_Linked_Assignment_Error,
      Predicate_Use_Legality_Linked_Return_Error,
      Predicate_Use_Legality_Linked_Semantic_Error,
      Predicate_Use_Legality_Linked_Overload_Error,
      Predicate_Use_Legality_Linked_Generic_Actual_Error,
      Predicate_Use_Legality_Universal_Numeric_Unresolved,
      Predicate_Use_Legality_Cross_Unit_Unresolved_View,
      Predicate_Use_Legality_Indeterminate);

   type Predicate_Use_Context_Info is record
      Id                  : Predicate_Use_Context_Id := No_Predicate_Use_Context;
      Kind                : Predicate_Use_Context_Kind := Predicate_Use_Unknown;
      Check_Point         : Use_Site_Check_Point := Check_Point_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Predicate           : Predicate_Policy :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Predicate_Not_Present;
      Invariant           : Invariant_Policy := Invariant_Not_Present;
      Requires_Static_Predicate : Boolean := False;
      Requires_Predicate_Check  : Boolean := False;
      Requires_Invariant_Check  : Boolean := False;
      Check_Is_Inserted         : Boolean := True;
      Cross_Unit_View_Resolved  : Boolean := True;
      Staticness_Status   : Static_Legality_Status :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked;
      Assignment_Status   : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Status       : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Semantic_Status     : Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Overload_Status     : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Instance_Status     : Instance_Legality_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
   end record;

   type Predicate_Use_Legality_Info is record
      Id                  : Predicate_Use_Legality_Id := No_Predicate_Use_Legality;
      Context             : Predicate_Use_Context_Id := No_Predicate_Use_Context;
      Kind                : Predicate_Use_Context_Kind := Predicate_Use_Unknown;
      Check_Point         : Use_Site_Check_Point := Check_Point_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Status              : Predicate_Use_Legality_Status := Predicate_Use_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Predicate           : Predicate_Policy :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Predicate_Not_Present;
      Invariant           : Invariant_Policy := Invariant_Not_Present;
      Staticness_Status   : Static_Legality_Status :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked;
      Assignment_Status   : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Status       : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Semantic_Status     : Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Overload_Status     : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Instance_Status     : Instance_Legality_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Predicate_Use_Context_Model is private;
   type Predicate_Use_Result_Set is private;
   type Predicate_Use_Legality_Model is private;

   procedure Clear (Model : in out Predicate_Use_Context_Model);
   procedure Add_Context
     (Model : in out Predicate_Use_Context_Model;
      Info  : Predicate_Use_Context_Info);
   function Context_Count (Model : Predicate_Use_Context_Model) return Natural;
   function Context_At
     (Model : Predicate_Use_Context_Model;
      Index : Positive) return Predicate_Use_Context_Info;
   function Fingerprint (Model : Predicate_Use_Context_Model) return Natural;

   function Build
     (Contexts : Predicate_Use_Context_Model) return Predicate_Use_Legality_Model;

   function Row_Count (Model : Predicate_Use_Legality_Model) return Natural;
   function Row_At
     (Model : Predicate_Use_Legality_Model;
      Index : Positive) return Predicate_Use_Legality_Info;
   function First_For_Node
     (Model : Predicate_Use_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Predicate_Use_Legality_Info;
   function Rows_For_Status
     (Model  : Predicate_Use_Legality_Model;
      Status : Predicate_Use_Legality_Status) return Predicate_Use_Result_Set;
   function Rows_For_Kind
     (Model : Predicate_Use_Legality_Model;
      Kind  : Predicate_Use_Context_Kind) return Predicate_Use_Result_Set;
   function Rows_For_Subtype
     (Model        : Predicate_Use_Legality_Model;
      Subtype_Name : String) return Predicate_Use_Result_Set;
   function Result_Count (Results : Predicate_Use_Result_Set) return Natural;
   function Result_At
     (Results : Predicate_Use_Result_Set;
      Index   : Positive) return Predicate_Use_Legality_Info;

   function Count_Status
     (Model  : Predicate_Use_Legality_Model;
      Status : Predicate_Use_Legality_Status) return Natural;
   function Count_Kind
     (Model : Predicate_Use_Legality_Model;
      Kind  : Predicate_Use_Context_Kind) return Natural;
   function Legal_Count (Model : Predicate_Use_Legality_Model) return Natural;
   function Error_Count (Model : Predicate_Use_Legality_Model) return Natural;
   function Predicate_Error_Count (Model : Predicate_Use_Legality_Model) return Natural;
   function Invariant_Error_Count (Model : Predicate_Use_Legality_Model) return Natural;
   function Missing_Check_Count (Model : Predicate_Use_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Predicate_Use_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Predicate_Use_Legality_Model) return Natural;
   function Fingerprint (Model : Predicate_Use_Legality_Model) return Natural;
   function Has_Legality (Info : Predicate_Use_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Predicate_Use_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Predicate_Use_Legality_Info);

   type Predicate_Use_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Predicate_Use_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Predicate_Use_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Predicate_Error_Total : Natural := 0;
      Invariant_Error_Total : Natural := 0;
      Missing_Check_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Predicate_Invariant_Use_Site_Legality;
