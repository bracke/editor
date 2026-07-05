with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Body_Spec_Conformance_Vertical_Slice_Legality is

   --  Case 1318 vertical-slice body/spec conformance and unit-completion
   --  legality.  This package models concrete Ada completion matching for
   --  subprograms, packages, task/protected units, stubs/separate bodies,
   --  generic bodies, profile conformance, mode/default/null-exclusion
   --  conformance, and cross-unit completion freshness.  It is intended as
   --  semantic evidence for elaboration, visibility, overload, generics, and
   --  diagnostics, not as another closure/provenance wrapper.

   type Completion_Id is new Natural;
   No_Completion : constant Completion_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Completion_Kind is
     (Completion_Subprogram_Body,
      Completion_Package_Body,
      Completion_Task_Body,
      Completion_Protected_Body,
      Completion_Generic_Package_Body,
      Completion_Generic_Subprogram_Body,
      Completion_Separate_Body,
      Completion_Body_Stub,
      Completion_Private_Type_Full_View,
      Completion_Deferred_Constant,
      Completion_Incomplete_Type,
      Completion_Unknown);

   type Unit_Kind is
     (Unit_Unknown,
      Unit_Package,
      Unit_Subprogram,
      Unit_Task,
      Unit_Protected,
      Unit_Generic_Package,
      Unit_Generic_Subprogram,
      Unit_Separate,
      Unit_Private_Type,
      Unit_Constant,
      Unit_Type);

   type Profile_Conformance_Kind is
     (Profile_Fully_Conformant,
      Profile_Mode_Mismatch,
      Profile_Type_Mismatch,
      Profile_Default_Mismatch,
      Profile_Null_Exclusion_Mismatch,
      Profile_Convention_Mismatch,
      Profile_Result_Mismatch,
      Profile_Not_Applicable,
      Profile_Unknown);

   type Completion_Placement is
     (Placement_Same_Declarative_Part,
      Placement_Package_Body,
      Placement_Library_Body,
      Placement_Subunit,
      Placement_Private_Part,
      Placement_Wrong_Region,
      Placement_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_Optional_Body,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Spec,
      Legality_Missing_Body,
      Legality_Duplicate_Body,
      Legality_Wrong_Completion_Kind,
      Legality_Wrong_Region,
      Legality_Profile_Mode_Mismatch,
      Legality_Profile_Type_Mismatch,
      Legality_Profile_Default_Mismatch,
      Legality_Profile_Null_Exclusion_Mismatch,
      Legality_Profile_Convention_Mismatch,
      Legality_Profile_Result_Mismatch,
      Legality_Generic_Formal_Mismatch,
      Legality_Generic_Body_Missing,
      Legality_Separate_Stub_Missing,
      Legality_Separate_Parent_Mismatch,
      Legality_Private_Full_View_Missing,
      Legality_Deferred_Constant_Mismatch,
      Legality_Incomplete_Type_Not_Completed,
      Legality_Visibility_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Private_View_Barrier,
      Legality_Elaboration_Blocker,
      Legality_Overload_Blocker,
      Legality_Representation_Blocker,
      Legality_Source_Fingerprint_Mismatch,
      Legality_Spec_Fingerprint_Mismatch,
      Legality_Body_Fingerprint_Mismatch,
      Legality_Profile_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Completion_Info is record
      Id       : Completion_Id := No_Completion;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Completion_Kind := Completion_Unknown;
      Spec_Unit : Unit_Kind := Unit_Unknown;
      Body_Unit : Unit_Kind := Unit_Unknown;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Placement : Completion_Placement := Placement_Unknown;
      View     : View_Kind := View_Full;
      Profile  : Profile_Conformance_Kind := Profile_Unknown;

      Has_AST_Coverage : Boolean := True;
      Has_Spec : Boolean := True;
      Has_Body : Boolean := True;
      Body_Required : Boolean := True;
      Duplicate_Body : Boolean := False;
      Completion_Kind_Matches : Boolean := True;
      Region_Matches : Boolean := True;
      Generic_Formals_Conform : Boolean := True;
      Generic_Body_Available : Boolean := True;
      Separate_Stub_Present : Boolean := True;
      Separate_Parent_Matches : Boolean := True;
      Private_Full_View_Present : Boolean := True;
      Deferred_Constant_Matches : Boolean := True;
      Incomplete_Type_Completed : Boolean := True;
      Visibility_OK : Boolean := True;
      Limited_View_Allows_Completion : Boolean := True;
      Private_View_Allows_Completion : Boolean := True;
      Elaboration_OK : Boolean := True;
      Overload_Profile_OK : Boolean := True;
      Representation_OK : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_Spec_Fingerprint : Natural := 0;
      Expected_Body_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Spec_Fingerprint : Natural := 0;
      Body_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Completion : Completion_Id := No_Completion;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Completion_Kind := Completion_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Missing_Spec_Blockers : Natural := 0;
      Missing_Body_Blockers : Natural := 0;
      Duplicate_Body_Blockers : Natural := 0;
      Kind_Blockers : Natural := 0;
      Region_Blockers : Natural := 0;
      Mode_Blockers : Natural := 0;
      Type_Blockers : Natural := 0;
      Default_Blockers : Natural := 0;
      Null_Exclusion_Blockers : Natural := 0;
      Convention_Blockers : Natural := 0;
      Result_Blockers : Natural := 0;
      Generic_Formal_Blockers : Natural := 0;
      Generic_Body_Blockers : Natural := 0;
      Stub_Blockers : Natural := 0;
      Separate_Parent_Blockers : Natural := 0;
      Private_Full_View_Blockers : Natural := 0;
      Deferred_Constant_Blockers : Natural := 0;
      Incomplete_Type_Blockers : Natural := 0;
      Visibility_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Elaboration_Blockers : Natural := 0;
      Overload_Blockers : Natural := 0;
      Representation_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Spec_Fingerprint_Blockers : Natural := 0;
      Body_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Completion_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Completion_Model);
   procedure Add_Completion (Model : in out Completion_Model; Info : Completion_Info);

   function Build (Completions : Completion_Model) return Result_Model;

   function Completion_Count (Model : Completion_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Completion_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Completion_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Completion_Model is record
      Items : Completion_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Body_Spec_Conformance_Vertical_Slice_Legality;
