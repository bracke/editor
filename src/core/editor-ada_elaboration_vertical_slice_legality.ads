with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Elaboration_Vertical_Slice_Legality is

   --  Pass1301 vertical-slice elaboration legality.  This package performs
   --  concrete RM-facing elaboration checks against source-shaped unit,
   --  pragma, body-availability, and call evidence.  It builds a bounded
   --  dependency view, rejects calls before required bodies are elaborated,
   --  reports dependency cycles, and models Elaborate, Elaborate_All,
   --  Preelaborate, and Pure constraints without adding another diagnostic
   --  or provenance wrapper.

   type Unit_Id is new Natural;
   No_Unit : constant Unit_Id := 0;

   type Edge_Id is new Natural;
   No_Edge : constant Edge_Id := 0;

   type Call_Id is new Natural;
   No_Call : constant Call_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Unit_Kind is
     (Unit_Package_Spec,
      Unit_Package_Body,
      Unit_Subprogram_Spec,
      Unit_Subprogram_Body,
      Unit_Generic_Spec,
      Unit_Generic_Body,
      Unit_Child_Spec,
      Unit_Child_Body,
      Unit_Separate_Body,
      Unit_Unknown);

   type Dependency_Kind is
     (Dependency_With,
      Dependency_Private_With,
      Dependency_Limited_With,
      Dependency_Body_Depends_On_Spec,
      Dependency_Elaborate,
      Dependency_Elaborate_All,
      Dependency_Preelaborate,
      Dependency_Pure,
      Dependency_Generic_Instance,
      Dependency_Separate_Body,
      Dependency_Unknown);

   type Call_Kind is
     (Call_Library_Level,
      Call_Package_Body_Elaboration,
      Call_Default_Expression,
      Call_Object_Initialization,
      Call_Generic_Instance,
      Call_Task_Activation,
      Call_Protected_Initialization,
      Call_Unknown);

   type Elaboration_Status is
     (Elaboration_Not_Checked,
      Elaboration_Legal_No_Call,
      Elaboration_Legal_Body_Elaborated,
      Elaboration_Legal_Elaborate_Pragma,
      Elaboration_Legal_Elaborate_All_Pragma,
      Elaboration_Legal_Preelaborable_Call,
      Elaboration_Legal_Pure_Call,
      Elaboration_Missing_Caller,
      Elaboration_Missing_Callee,
      Elaboration_Missing_Body,
      Elaboration_Call_Before_Body,
      Elaboration_Cycle,
      Elaboration_Elaborate_All_Violation,
      Elaboration_Preelaborate_Violation,
      Elaboration_Pure_Violation,
      Elaboration_Limited_View_Barrier,
      Elaboration_Private_View_Barrier,
      Elaboration_Generic_Body_Unavailable,
      Elaboration_Separate_Body_Unlinked,
      Elaboration_Source_Fingerprint_Mismatch,
      Elaboration_Dependency_Fingerprint_Mismatch,
      Elaboration_Multiple_Blockers,
      Elaboration_Indeterminate);

   type Unit_Info is record
      Id       : Unit_Id := No_Unit;
      Body_Id  : Unit_Id := No_Unit;
      Spec_Id  : Unit_Id := No_Unit;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Unit_Kind := Unit_Unknown;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Has_Body : Boolean := False;
      Body_Elaborated_Before_Use : Boolean := False;
      Is_Preelaborated : Boolean := False;
      Is_Pure : Boolean := False;
      Has_Elaborate : Boolean := False;
      Has_Elaborate_All : Boolean := False;
      Is_Generic : Boolean := False;
      Generic_Body_Available : Boolean := False;
      Is_Limited_View : Boolean := False;
      Is_Private_View : Boolean := False;
      Is_Separate_Body : Boolean := False;
      Separate_Linked : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Dependency_Fingerprint : Natural := 0;
   end record;

   type Dependency_Info is record
      Id       : Edge_Id := No_Edge;
      From_Unit : Unit_Id := No_Unit;
      To_Unit   : Unit_Id := No_Unit;
      Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind      : Dependency_Kind := Dependency_Unknown;
      Is_Transitive : Boolean := False;
      Is_Cyclic : Boolean := False;
      Is_Limited_View : Boolean := False;
      Is_Private_View : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Dependency_Fingerprint : Natural := 0;
   end record;

   type Call_Info is record
      Id       : Call_Id := No_Call;
      Caller   : Unit_Id := No_Unit;
      Callee   : Unit_Id := No_Unit;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Call_Kind := Call_Unknown;
      Requires_Body_Before_Call : Boolean := True;
      Requires_Elaborate_All : Boolean := False;
      Occurs_In_Preelaborated_Unit : Boolean := False;
      Occurs_In_Pure_Unit : Boolean := False;
      Through_Generic_Instance : Boolean := False;
      Through_Separate_Body : Boolean := False;
      Expected_Caller_Fingerprint : Natural := 0;
      Expected_Callee_Fingerprint : Natural := 0;
      Expected_Dependency_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Call_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Call     : Call_Id := No_Call;
      Caller   : Unit_Id := No_Unit;
      Callee   : Unit_Id := No_Unit;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Elaboration_Status := Elaboration_Not_Checked;
      Missing_Caller_Blockers : Natural := 0;
      Missing_Callee_Blockers : Natural := 0;
      Missing_Body_Blockers : Natural := 0;
      Call_Before_Body_Blockers : Natural := 0;
      Cycle_Blockers : Natural := 0;
      Elaborate_All_Blockers : Natural := 0;
      Preelaborate_Blockers : Natural := 0;
      Pure_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Generic_Body_Blockers : Natural := 0;
      Separate_Body_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Dependency_Fingerprint_Blockers : Natural := 0;
      Caller_Fingerprint : Natural := 0;
      Callee_Fingerprint : Natural := 0;
      Dependency_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Unit_Model is private;
   type Dependency_Model is private;
   type Call_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Unit_Model);
   procedure Clear (Model : in out Dependency_Model);
   procedure Clear (Model : in out Call_Model);

   procedure Add_Unit (Model : in out Unit_Model; Info : Unit_Info);
   procedure Add_Dependency (Model : in out Dependency_Model; Info : Dependency_Info);
   procedure Add_Call (Model : in out Call_Model; Info : Call_Info);

   function Build
     (Units        : Unit_Model;
      Dependencies : Dependency_Model;
      Calls        : Call_Model) return Result_Model;

   function Unit_Count (Model : Unit_Model) return Natural;
   function Dependency_Count (Model : Dependency_Model) return Natural;
   function Call_Count (Model : Call_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function First_For_Node
     (Model : Result_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Result_Info;
   function Count_Status
     (Model : Result_Model;
      Status : Elaboration_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Unit_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Unit_Info);
   package Dependency_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Dependency_Info);
   package Call_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Call_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Unit_Model is record
      Items : Unit_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Dependency_Model is record
      Items : Dependency_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Call_Model is record
      Items : Call_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Elaboration_Vertical_Slice_Legality;
