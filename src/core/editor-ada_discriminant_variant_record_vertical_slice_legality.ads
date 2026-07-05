with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Discriminant_Variant_Record_Vertical_Slice_Legality is

   --  Case 1313 vertical-slice discriminant, variant, and record legality.
   --  This package validates concrete Ada record/discriminant/variant cases
   --  against source-shaped semantic rows.  It is a direct compiler-grade
   --  legality model for discriminant-dependent components, variant coverage,
   --  constrained/unconstrained records, aggregate discriminants, and
   --  representation-sensitive layout.  It is not a closure/provenance/search
   --  wrapper.

   type Record_Id is new Natural;
   No_Record : constant Record_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Record_Construct_Kind is
     (Record_Type_Declaration,
      Record_Extension_Declaration,
      Record_Object_Declaration,
      Record_Aggregate,
      Record_Delta_Aggregate,
      Discriminant_Part,
      Discriminant_Constraint,
      Variant_Part,
      Variant_Alternative,
      Component_Declaration,
      Component_Selection,
      Representation_Component_Clause,
      Unknown_Construct);

   type Record_View_Kind is
     (View_Unknown,
      View_Full_Record,
      View_Private_Record,
      View_Limited_Record,
      View_Tagged_Record,
      View_Record_Extension,
      View_Formal_Record,
      View_Non_Record);

   type Discriminant_Kind is
     (Discriminant_None,
      Discriminant_Known_Static,
      Discriminant_Known_Dynamic,
      Discriminant_Defaulted,
      Discriminant_Unconstrained,
      Discriminant_Unknown);

   type Variant_Coverage_Kind is
     (Coverage_None,
      Coverage_Complete,
      Coverage_Missing_Alternative,
      Coverage_Overlapping_Choices,
      Coverage_Non_Static_Choice,
      Coverage_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Context,
      Legality_Not_Record,
      Legality_Discriminant_Missing,
      Legality_Discriminant_Type_Mismatch,
      Legality_Discriminant_Default_Mismatch,
      Legality_Discriminant_Constraint_Mismatch,
      Legality_Discriminant_Dependent_Component_Blocked,
      Legality_Variant_Part_Missing_Discriminant,
      Legality_Variant_Coverage_Incomplete,
      Legality_Variant_Choice_Overlap,
      Legality_Variant_Choice_Not_Static,
      Legality_Variant_Component_Inactive,
      Legality_Record_Aggregate_Discriminant_Missing,
      Legality_Record_Aggregate_Component_Missing,
      Legality_Record_Aggregate_Component_Duplicate,
      Legality_Record_Aggregate_Component_Type_Mismatch,
      Legality_Record_Aggregate_Named_Positional_Mix,
      Legality_Delta_Update_Target_Missing,
      Legality_Delta_Update_Component_Mismatch,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Tagged_Extension_Blocked,
      Legality_Representation_Layout_Conflict,
      Legality_Controlled_Finalization_Blocked,
      Legality_Accessibility_Blocked,
      Legality_Initialization_Blocked,
      Legality_Subtype_Range_Blocked,
      Legality_Predicate_Blocked,
      Legality_Overload_Blocked,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Type_Fingerprint_Mismatch,
      Legality_Layout_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Record_Info is record
      Id       : Record_Id := No_Record;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Record_Construct_Kind := Unknown_Construct;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Context      : Boolean := True;
      View             : Record_View_Kind := View_Full_Record;
      Discriminant     : Discriminant_Kind := Discriminant_None;
      Coverage         : Variant_Coverage_Kind := Coverage_None;

      Required_Discriminant_Count : Natural := 0;
      Supplied_Discriminant_Count : Natural := 0;
      Discriminant_Type_Compatible : Boolean := True;
      Discriminant_Default_Compatible : Boolean := True;
      Discriminant_Constraint_Compatible : Boolean := True;
      Discriminant_Dependent_Component_Legal : Boolean := True;

      Variant_Has_Governing_Discriminant : Boolean := True;
      Selected_Variant_Active : Boolean := True;
      Runtime_Variant_Check_Required : Boolean := False;

      Aggregate_Component_Count : Natural := 0;
      Required_Component_Count  : Natural := 0;
      Has_Duplicate_Component   : Boolean := False;
      Component_Type_Compatible : Boolean := True;
      Mixes_Named_And_Positional : Boolean := False;

      Has_Delta_Update_Target : Boolean := True;
      Delta_Update_Component_Compatible : Boolean := True;

      Private_View_Available : Boolean := True;
      Limited_View_Available : Boolean := True;
      Tagged_Extension_Legal : Boolean := True;
      Representation_Layout_Legal : Boolean := True;
      Controlled_Finalization_Legal : Boolean := True;
      Accessibility_Legal : Boolean := True;
      Initialization_Legal : Boolean := True;
      Subtype_Range_Legal : Boolean := True;
      Predicate_Legal : Boolean := True;
      Overload_Legal : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint    : Natural := 0;
      Expected_Type_Fingerprint   : Natural := 0;
      Expected_Layout_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint    : Natural := 0;
      Type_Fingerprint   : Natural := 0;
      Layout_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Record_Ref : Record_Id := No_Record;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Record_Construct_Kind := Unknown_Construct;
      Status   : Legality_Status := Legality_Not_Checked;

      AST_Blockers : Natural := 0;
      Context_Blockers : Natural := 0;
      Record_View_Blockers : Natural := 0;
      Discriminant_Missing_Blockers : Natural := 0;
      Discriminant_Type_Blockers : Natural := 0;
      Discriminant_Default_Blockers : Natural := 0;
      Discriminant_Constraint_Blockers : Natural := 0;
      Discriminant_Dependent_Component_Blockers : Natural := 0;
      Variant_Governing_Discriminant_Blockers : Natural := 0;
      Variant_Coverage_Blockers : Natural := 0;
      Variant_Choice_Overlap_Blockers : Natural := 0;
      Variant_Choice_Static_Blockers : Natural := 0;
      Variant_Inactive_Component_Blockers : Natural := 0;
      Aggregate_Discriminant_Blockers : Natural := 0;
      Aggregate_Component_Missing_Blockers : Natural := 0;
      Aggregate_Component_Duplicate_Blockers : Natural := 0;
      Aggregate_Component_Type_Blockers : Natural := 0;
      Aggregate_Named_Positional_Blockers : Natural := 0;
      Delta_Target_Blockers : Natural := 0;
      Delta_Component_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Tagged_Extension_Blockers : Natural := 0;
      Representation_Layout_Blockers : Natural := 0;
      Controlled_Finalization_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Initialization_Blockers : Natural := 0;
      Subtype_Range_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Overload_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Layout_Fingerprint_Blockers : Natural := 0;

      Runtime_Check_Required : Boolean := False;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint    : Natural := 0;
      Type_Fingerprint   : Natural := 0;
      Layout_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Record_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Record_Model);
   procedure Add_Record (Model : in out Record_Model; Info : Record_Info);

   function Build (Records : Record_Model) return Result_Model;

   function Record_Count (Model : Record_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Record_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Record_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Record_Model is record
      Items : Record_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Discriminant_Variant_Record_Vertical_Slice_Legality;
