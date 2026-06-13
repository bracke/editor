with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Array_Container_Indexing_Vertical_Slice_Legality is

   --  Pass1312 vertical-slice array, container, and indexing legality.
   --  This package checks concrete Ada array aggregate, index constraint,
   --  slicing, generalized indexing, container aggregate, iterator, and
   --  delta-update rules against source-shaped semantic rows.  It is a
   --  direct compiler-grade legality model, not a closure/provenance/search
   --  wrapper.

   type Indexing_Id is new Natural;
   No_Indexing : constant Indexing_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Indexing_Kind is
     (Index_Array_Type_Declaration,
      Index_Array_Object_Declaration,
      Index_Index_Constraint,
      Index_Array_Aggregate,
      Index_Named_Array_Aggregate,
      Index_Positional_Array_Aggregate,
      Index_Array_Slice,
      Index_Indexed_Component,
      Index_Generalized_Indexing,
      Index_Container_Aggregate,
      Index_Container_Iterator,
      Index_Delta_Aggregate_Update,
      Index_Parallel_Iterator,
      Index_Unknown);

   type Composite_Kind is
     (Composite_Unknown,
      Composite_Array,
      Composite_Constrained_Array,
      Composite_Unconstrained_Array,
      Composite_Multidimensional_Array,
      Composite_String_Array,
      Composite_Record,
      Composite_Container,
      Composite_Formal_Array,
      Composite_Private_Array,
      Composite_Limited_View,
      Composite_Non_Array);

   type Index_Type_Kind is
     (Index_Type_Unknown,
      Index_Type_Discrete,
      Index_Type_Integer,
      Index_Type_Modular,
      Index_Type_Enumeration,
      Index_Type_Boolean,
      Index_Type_Character,
      Index_Type_Universal_Integer,
      Index_Type_Non_Discrete);

   type Container_Profile_Kind is
     (Container_Profile_None,
      Container_Profile_Constant_Indexing,
      Container_Profile_Variable_Indexing,
      Container_Profile_Iterator,
      Container_Profile_Aggregate_Empty,
      Container_Profile_Aggregate_Add_Named,
      Container_Profile_Aggregate_Add_Unnamed,
      Container_Profile_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Context,
      Legality_Not_Array_Or_Container,
      Legality_Index_Type_Not_Discrete,
      Legality_Index_Range_Mismatch,
      Legality_Index_Count_Mismatch,
      Legality_Index_Out_Of_Bounds,
      Legality_Unconstrained_Array_Missing_Constraint,
      Legality_Constrained_Array_Constraint_Conflict,
      Legality_Aggregate_Component_Missing,
      Legality_Aggregate_Component_Duplicate,
      Legality_Aggregate_Component_Type_Mismatch,
      Legality_Aggregate_Named_Positional_Mix,
      Legality_Aggregate_Choice_Overlap,
      Legality_Slice_Range_Mismatch,
      Legality_Generalized_Indexing_Profile_Missing,
      Legality_Generalized_Indexing_Profile_Mismatch,
      Legality_Container_Aggregate_Profile_Missing,
      Legality_Container_Element_Type_Mismatch,
      Legality_Iterator_Element_Type_Mismatch,
      Legality_Parallel_Iterator_Shared_State_Blocked,
      Legality_Delta_Update_Target_Missing,
      Legality_Delta_Update_Component_Mismatch,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Subtype_Range_Blocked,
      Legality_Predicate_Blocked,
      Legality_Accessibility_Blocked,
      Legality_Initialization_Blocked,
      Legality_Overload_Blocked,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Type_Fingerprint_Mismatch,
      Legality_Profile_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Indexing_Info is record
      Id       : Indexing_Id := No_Indexing;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Indexing_Kind := Index_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Context : Boolean := True;
      Composite : Composite_Kind := Composite_Array;
      Index_Type : Index_Type_Kind := Index_Type_Discrete;
      Container_Profile : Container_Profile_Kind := Container_Profile_None;

      Dimension_Count : Natural := 1;
      Supplied_Index_Count : Natural := 1;
      Index_Range_Compatible : Boolean := True;
      Index_Value_In_Bounds : Boolean := True;
      Runtime_Bounds_Check_Required : Boolean := False;
      Is_Constrained_Array : Boolean := True;
      Has_Index_Constraint : Boolean := True;
      Constraint_Conflicts_With_Type : Boolean := False;

      Aggregate_Component_Count : Natural := 1;
      Required_Component_Count : Natural := 1;
      Has_Duplicate_Component : Boolean := False;
      Component_Type_Compatible : Boolean := True;
      Mixes_Named_And_Positional : Boolean := False;
      Aggregate_Choices_Overlap : Boolean := False;

      Slice_Range_Compatible : Boolean := True;
      Has_Generalized_Indexing_Profile : Boolean := True;
      Generalized_Indexing_Profile_Compatible : Boolean := True;
      Has_Container_Aggregate_Profile : Boolean := True;
      Container_Element_Type_Compatible : Boolean := True;
      Iterator_Element_Type_Compatible : Boolean := True;
      Parallel_Iterator_Shared_State_Legal : Boolean := True;
      Has_Delta_Update_Target : Boolean := True;
      Delta_Update_Component_Compatible : Boolean := True;

      Private_View_Available : Boolean := True;
      Limited_View_Available : Boolean := True;
      Subtype_Range_Legal : Boolean := True;
      Predicate_Legal : Boolean := True;
      Accessibility_Legal : Boolean := True;
      Initialization_Legal : Boolean := True;
      Overload_Legal : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Indexing : Indexing_Id := No_Indexing;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Indexing_Kind := Index_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Context_Blockers : Natural := 0;
      Composite_Blockers : Natural := 0;
      Index_Type_Blockers : Natural := 0;
      Index_Range_Blockers : Natural := 0;
      Index_Count_Blockers : Natural := 0;
      Bounds_Blockers : Natural := 0;
      Missing_Constraint_Blockers : Natural := 0;
      Constraint_Conflict_Blockers : Natural := 0;
      Missing_Component_Blockers : Natural := 0;
      Duplicate_Component_Blockers : Natural := 0;
      Component_Type_Blockers : Natural := 0;
      Named_Positional_Mix_Blockers : Natural := 0;
      Choice_Overlap_Blockers : Natural := 0;
      Slice_Range_Blockers : Natural := 0;
      Generalized_Profile_Missing_Blockers : Natural := 0;
      Generalized_Profile_Mismatch_Blockers : Natural := 0;
      Container_Profile_Blockers : Natural := 0;
      Container_Element_Blockers : Natural := 0;
      Iterator_Element_Blockers : Natural := 0;
      Parallel_Shared_State_Blockers : Natural := 0;
      Delta_Target_Blockers : Natural := 0;
      Delta_Component_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Subtype_Range_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Initialization_Blockers : Natural := 0;
      Overload_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      Runtime_Check_Required : Boolean := False;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Indexing_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Indexing_Model);
   procedure Add_Indexing (Model : in out Indexing_Model; Info : Indexing_Info);

   function Build (Indexings : Indexing_Model) return Result_Model;

   function Indexing_Count (Model : Indexing_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Indexing_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Indexing_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Indexing_Model is record
      Items : Indexing_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Array_Container_Indexing_Vertical_Slice_Legality;
