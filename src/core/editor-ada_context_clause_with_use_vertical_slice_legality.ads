with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Context_Clause_With_Use_Vertical_Slice_Legality is

   --  Pass1330 vertical-slice context-clause and unit-visibility legality.
   --  The model is source-shaped: each row represents one with/use/private
   --  with/limited with clause as seen by a snapshot-owned Ada unit context.
   --  It deliberately checks real Ada legality facts rather than projection
   --  state: target-unit resolution, duplicate clauses, limited/private-view
   --  barriers, child/private-child visibility, body/spec propagation,
   --  generic contract contexts, use-package/use-type target classes, and
   --  circular limited-view dependencies.

   type Unit_Id is new Natural;
   No_Unit : constant Unit_Id := 0;

   type Type_Id is new Natural;
   No_Type : constant Type_Id := 0;

   type Clause_Id is new Natural;
   No_Clause : constant Clause_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Unit_Kind is
     (Unit_Package_Spec,
      Unit_Package_Body,
      Unit_Subprogram_Spec,
      Unit_Subprogram_Body,
      Unit_Generic_Package,
      Unit_Generic_Subprogram,
      Unit_Child_Package,
      Unit_Private_Child_Package,
      Unit_Unknown);

   type Type_Kind is
     (Type_Discrete,
      Type_Record,
      Type_Tagged,
      Type_Access,
      Type_Private,
      Type_Incomplete,
      Type_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Clause_Kind is
     (Clause_With,
      Clause_Private_With,
      Clause_Limited_With,
      Clause_Use_Package,
      Clause_Use_Type,
      Clause_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Limited_View,
      Legality_Missing_Clause,
      Legality_Missing_Context_Unit,
      Legality_Missing_Target_Unit,
      Legality_Unit_Name_Mismatch,
      Legality_Duplicate_With,
      Legality_Duplicate_Use,
      Legality_Nonlimited_With_Cycle,
      Legality_Private_With_Not_Allowed,
      Legality_Private_Child_Not_Visible,
      Legality_Limited_View_Barrier,
      Legality_Private_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_View_Barrier,
      Legality_Use_Target_Not_Package,
      Legality_Use_Type_Target_Not_Type,
      Legality_Use_Clause_Without_With,
      Legality_Body_Context_Not_Propagated,
      Legality_Generic_Context_Missing,
      Legality_Ambiguous_Use_Homograph,
      Legality_Source_Fingerprint_Mismatch,
      Legality_Unit_Fingerprint_Mismatch,
      Legality_View_Fingerprint_Mismatch,
      Legality_Closure_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Unit_Info is record
      Id : Unit_Id := No_Unit;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Unit_Kind := Unit_Unknown;
      Parent : Unit_Id := No_Unit;
      View : View_Kind := View_Full;
      Is_Private_Child : Boolean := False;
      Is_Generic : Boolean := False;
      Context_Propagated_To_Body : Boolean := True;
      Generic_Contract_Context_Present : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
   end record;

   package Unit_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Unit_Info);

   type Unit_Model is record
      Items : Unit_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Type_Info is record
      Id : Type_Id := No_Type;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Type_Kind := Type_Unknown;
      View : View_Kind := View_Full;
      Source_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
   end record;

   package Type_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Type_Info);

   type Type_Model is record
      Items : Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Clause_Info is record
      Id : Clause_Id := No_Clause;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Clause_Kind := Clause_Unknown;
      Context_Unit : Unit_Id := No_Unit;
      Target_Unit : Unit_Id := No_Unit;
      Target_Type : Type_Id := No_Type;
      Target_Name_Matches : Boolean := True;
      Duplicate_With : Boolean := False;
      Duplicate_Use : Boolean := False;
      Dependency_Cycle : Boolean := False;
      Private_With_Allowed : Boolean := True;
      Private_Child_Visible : Boolean := True;
      Consumer_Requires_Full_View : Boolean := False;
      Use_Has_With : Boolean := True;
      Use_Target_Is_Package : Boolean := True;
      Use_Type_Target_Is_Type : Boolean := True;
      Body_Context_Propagated : Boolean := True;
      Generic_Context_Present : Boolean := True;
      Ambiguous_Use_Homograph : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
   end record;

   package Clause_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Clause_Info);

   type Clause_Model is record
      Items : Clause_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Clause : Clause_Id := No_Clause;
      Status : Legality_Status := Legality_Not_Checked;
      Source_Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Fingerprint : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Missing_Clause_Blockers : Natural := 0;
      Missing_Context_Unit_Blockers : Natural := 0;
      Missing_Target_Unit_Blockers : Natural := 0;
      Unit_Name_Mismatch_Blockers : Natural := 0;
      Duplicate_With_Blockers : Natural := 0;
      Duplicate_Use_Blockers : Natural := 0;
      Nonlimited_With_Cycle_Blockers : Natural := 0;
      Private_With_Blockers : Natural := 0;
      Private_Child_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Use_Target_Package_Blockers : Natural := 0;
      Use_Type_Target_Blockers : Natural := 0;
      Use_Without_With_Blockers : Natural := 0;
      Body_Context_Blockers : Natural := 0;
      Generic_Context_Blockers : Natural := 0;
      Ambiguous_Use_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Unit_Fingerprint_Blockers : Natural := 0;
      View_Fingerprint_Blockers : Natural := 0;
      Closure_Fingerprint_Blockers : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Result_Info);

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   procedure Clear (Model : in out Unit_Model);
   procedure Clear (Model : in out Type_Model);
   procedure Clear (Model : in out Clause_Model);
   procedure Clear (Model : in out Result_Model);

   procedure Add_Unit (Model : in out Unit_Model; Item : Unit_Info);
   procedure Add_Type (Model : in out Type_Model; Item : Type_Info);
   procedure Add_Clause (Model : in out Clause_Model; Item : Clause_Info);

   function Build
     (Units : Unit_Model;
      Types : Type_Model;
      Clauses : Clause_Model) return Result_Model;

   function Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;

end Editor.Ada_Context_Clause_With_Use_Vertical_Slice_Legality;
