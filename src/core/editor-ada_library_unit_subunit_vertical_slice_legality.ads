with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Library_Unit_Subunit_Vertical_Slice_Legality is

   --  Case 1331 vertical-slice library-unit/subunit legality.
   --  This source-shaped model checks Ada unit closure facts that cross
   --  separate subunits, body stubs, child units, private children, and
   --  library-unit completions.  It is intentionally a legality engine, not a
   --  diagnostic projection layer: callers provide snapshot-owned evidence
   --  rows and receive deterministic blocker families with freshness checks.

   type Unit_Id is new Natural;
   No_Unit : constant Unit_Id := 0;

   type Stub_Id is new Natural;
   No_Stub : constant Stub_Id := 0;

   type Check_Id is new Natural;
   No_Check : constant Check_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Unit_Kind is
     (Unit_Package_Spec,
      Unit_Package_Body,
      Unit_Subprogram_Spec,
      Unit_Subprogram_Body,
      Unit_Generic_Package_Spec,
      Unit_Generic_Package_Body,
      Unit_Generic_Subprogram_Spec,
      Unit_Generic_Subprogram_Body,
      Unit_Task_Body,
      Unit_Protected_Body,
      Unit_Child_Spec,
      Unit_Child_Body,
      Unit_Private_Child_Spec,
      Unit_Private_Child_Body,
      Unit_Subunit,
      Unit_Unknown);

   type Stub_Kind is
     (Stub_Package_Body,
      Stub_Subprogram_Body,
      Stub_Task_Body,
      Stub_Protected_Body,
      Stub_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Check_Kind is
     (Check_Body_Stub,
      Check_Separate_Subunit,
      Check_Nested_Separate_Body,
      Check_Library_Unit_Completion,
      Check_Child_Unit,
      Check_Private_Child_Body,
      Check_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Missing_Check,
      Legality_Missing_Parent_Unit,
      Legality_Missing_Child_Unit,
      Legality_Missing_Spec,
      Legality_Missing_Body,
      Legality_Missing_Stub,
      Legality_Unit_Kind_Mismatch,
      Legality_Stub_Kind_Mismatch,
      Legality_Parent_Name_Mismatch,
      Legality_Parent_Not_Library_Unit,
      Legality_Body_Before_Spec,
      Legality_Duplicate_Body,
      Legality_Duplicate_Subunit,
      Legality_Body_Stub_Requires_Separate,
      Legality_Separate_Without_Stub,
      Legality_Nested_Separate_Parent_Mismatch,
      Legality_Library_Unit_Incomplete,
      Legality_Child_Parent_Missing,
      Legality_Private_Child_Spec_Missing,
      Legality_Private_Child_Body_Not_Visible,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_View_Barrier,
      Legality_Source_Fingerprint_Mismatch,
      Legality_Unit_Fingerprint_Mismatch,
      Legality_Body_Fingerprint_Mismatch,
      Legality_Stub_Fingerprint_Mismatch,
      Legality_Closure_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Unit_Info is record
      Id : Unit_Id := No_Unit;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Unit_Kind := Unit_Unknown;
      Parent : Unit_Id := No_Unit;
      Spec : Unit_Id := No_Unit;
      Body_Ref : Unit_Id := No_Unit;
      View : View_Kind := View_Full;
      Is_Library_Unit : Boolean := True;
      Is_Private_Child : Boolean := False;
      Parent_Name_Matches : Boolean := True;
      Has_Required_Body : Boolean := True;
      Body_Present : Boolean := True;
      Spec_Present : Boolean := True;
      Body_After_Spec : Boolean := True;
      Duplicate_Body : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Body_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      Expected_Body_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
   end record;

   package Unit_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Unit_Info);

   type Unit_Model is record
      Items : Unit_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Stub_Info is record
      Id : Stub_Id := No_Stub;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Stub_Kind := Stub_Unknown;
      Parent_Unit : Unit_Id := No_Unit;
      Separate_Body : Unit_Id := No_Unit;
      Expected_Separate_Kind : Unit_Kind := Unit_Unknown;
      Separate_Present : Boolean := True;
      Duplicate_Subunit : Boolean := False;
      Parent_Name_Matches : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Stub_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_Stub_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
   end record;

   package Stub_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Stub_Info);

   type Stub_Model is record
      Items : Stub_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Check_Info is record
      Id : Check_Id := No_Check;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Check_Kind := Check_Unknown;
      Unit : Unit_Id := No_Unit;
      Parent_Unit : Unit_Id := No_Unit;
      Child_Unit : Unit_Id := No_Unit;
      Spec_Unit : Unit_Id := No_Unit;
      Body_Unit : Unit_Id := No_Unit;
      Stub : Stub_Id := No_Stub;
      Nested_Parent_Stub : Stub_Id := No_Stub;
      Expected_Unit_Kind : Unit_Kind := Unit_Unknown;
      Expected_Stub_Kind : Stub_Kind := Stub_Unknown;
      Parent_Name_Matches : Boolean := True;
      Child_Parent_Present : Boolean := True;
      Private_Child_Visible : Boolean := True;
      Private_Child_Spec_Present : Boolean := True;
      Body_After_Spec : Boolean := True;
      Duplicate_Body : Boolean := False;
      Duplicate_Subunit : Boolean := False;
      Requires_Separate_Body : Boolean := False;
      Separate_Body_Present : Boolean := True;
      Nested_Separate_Parent_Matches : Boolean := True;
      Library_Unit_Complete : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Body_Fingerprint : Natural := 0;
      Stub_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      Expected_Body_Fingerprint : Natural := 0;
      Expected_Stub_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
   end record;

   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Check_Info);

   type Check_Model is record
      Items : Check_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Check : Check_Id := No_Check;
      Status : Legality_Status := Legality_Not_Checked;
      Source_Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Fingerprint : Natural := 0;
      Missing_Check_Blockers : Natural := 0;
      Missing_Parent_Unit_Blockers : Natural := 0;
      Missing_Child_Unit_Blockers : Natural := 0;
      Missing_Spec_Blockers : Natural := 0;
      Missing_Body_Blockers : Natural := 0;
      Missing_Stub_Blockers : Natural := 0;
      Unit_Kind_Blockers : Natural := 0;
      Stub_Kind_Blockers : Natural := 0;
      Parent_Name_Blockers : Natural := 0;
      Parent_Library_Blockers : Natural := 0;
      Body_Before_Spec_Blockers : Natural := 0;
      Duplicate_Body_Blockers : Natural := 0;
      Duplicate_Subunit_Blockers : Natural := 0;
      Body_Stub_Separate_Blockers : Natural := 0;
      Separate_Without_Stub_Blockers : Natural := 0;
      Nested_Separate_Parent_Blockers : Natural := 0;
      Library_Unit_Incomplete_Blockers : Natural := 0;
      Child_Parent_Blockers : Natural := 0;
      Private_Child_Spec_Blockers : Natural := 0;
      Private_Child_Visibility_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Unit_Fingerprint_Blockers : Natural := 0;
      Body_Fingerprint_Blockers : Natural := 0;
      Stub_Fingerprint_Blockers : Natural := 0;
      Closure_Fingerprint_Blockers : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Result_Info);

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   procedure Clear (Model : in out Unit_Model);
   procedure Clear (Model : in out Stub_Model);
   procedure Clear (Model : in out Check_Model);
   procedure Clear (Model : in out Result_Model);

   procedure Add_Unit (Model : in out Unit_Model; Item : Unit_Info);
   procedure Add_Stub (Model : in out Stub_Model; Item : Stub_Info);
   procedure Add_Check (Model : in out Check_Model; Item : Check_Info);

   function Build
     (Units : Unit_Model;
      Stubs : Stub_Model;
      Checks : Check_Model) return Result_Model;

   function Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;

end Editor.Ada_Library_Unit_Subunit_Vertical_Slice_Legality;
