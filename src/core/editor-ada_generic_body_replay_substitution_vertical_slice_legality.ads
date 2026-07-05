with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality is

   --  Case 1320 vertical-slice generic body replay/substitution legality.  This
   --  package models concrete Ada generic body replay after actual matching:
   --  body availability, formal-to-actual binding, nested instantiation replay,
   --  source-to-instance backmapping, private/limited view barriers, overload
   --  and type evidence, freezing/representation evidence, accessibility,
   --  shared-state effects, and stale source/substitution fingerprints.  It is
   --  a semantic rule engine, not a diagnostic/provenance wrapper.

   type Instance_Id is new Natural;
   No_Instance : constant Instance_Id := 0;

   type Event_Id is new Natural;
   No_Event : constant Event_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Replay_Event_Kind is
     (Event_Call,
      Event_Operator_Call,
      Event_Object_Declaration,
      Event_Type_Declaration,
      Event_Renaming,
      Event_Nested_Instantiation,
      Event_Representation_Clause,
      Event_Predicate_Aspect,
      Event_Dataflow_Use,
      Event_Tasking_Use,
      Event_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal_Replayed,
      Legality_Legal_Runtime_Check,
      Legality_Legal_Nested_Replay,
      Legality_Missing_Generic_Body,
      Legality_Missing_Formal_Actual_Binding,
      Legality_Missing_Source_Backmapping,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Nested_Instance_Cycle,
      Legality_Dependency_Depth_Overflow,
      Legality_Overload_Blocker,
      Legality_Type_Substitution_Mismatch,
      Legality_Visibility_Blocker,
      Legality_Freezing_Blocker,
      Legality_Representation_Blocker,
      Legality_Accessibility_Blocker,
      Legality_Predicate_Blocker,
      Legality_Dataflow_Blocker,
      Legality_Shared_State_Blocker,
      Legality_Source_Fingerprint_Mismatch,
      Legality_Substitution_Fingerprint_Mismatch,
      Legality_Backmapping_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Replay_Context_Info is record
      Instance : Instance_Id := No_Instance;
      Generic_Name : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name : Ada.Strings.Unbounded.Unbounded_String;
      Body_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Has_Generic_Body : Boolean := True;
      Has_Formal_Actual_Bindings : Boolean := True;
      Has_Source_Backmapping : Boolean := True;
      View : View_Kind := View_Full;
      Allows_Private_View : Boolean := True;
      Allows_Limited_View : Boolean := True;
      Nested_Depth : Natural := 0;
      Max_Nested_Depth : Natural := 32;
      Nested_Cycle : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Backmapping_Fingerprint : Natural := 0;
      Expected_Backmapping_Fingerprint : Natural := 0;
   end record;

   type Replay_Event_Info is record
      Id : Event_Id := No_Event;
      Instance : Instance_Id := No_Instance;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Replay_Event_Kind := Event_Unknown;
      Source_Text : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Type : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Type : Ada.Strings.Unbounded.Unbounded_String;
      Requires_Runtime_Check : Boolean := False;
      Overload_Resolved : Boolean := True;
      Type_Substitution_Valid : Boolean := True;
      Visibility_Valid : Boolean := True;
      Freezing_Valid : Boolean := True;
      Representation_Valid : Boolean := True;
      Accessibility_Valid : Boolean := True;
      Predicate_Valid : Boolean := True;
      Dataflow_Valid : Boolean := True;
      Shared_State_Valid : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Backmapping_Fingerprint : Natural := 0;
      Expected_Backmapping_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Instance : Instance_Id := No_Instance;
      Event : Event_Id := No_Event;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Replay_Event_Kind := Event_Unknown;
      Status : Legality_Status := Legality_Not_Checked;
      Missing_Body_Blockers : Natural := 0;
      Missing_Binding_Blockers : Natural := 0;
      Missing_Backmapping_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Nested_Cycle_Blockers : Natural := 0;
      Dependency_Depth_Blockers : Natural := 0;
      Overload_Blockers : Natural := 0;
      Type_Substitution_Blockers : Natural := 0;
      Visibility_Blockers : Natural := 0;
      Freezing_Blockers : Natural := 0;
      Representation_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Dataflow_Blockers : Natural := 0;
      Shared_State_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Substitution_Fingerprint_Blockers : Natural := 0;
      Backmapping_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Context_Model is private;
   type Event_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Context_Model);
   procedure Clear (Model : in out Event_Model);
   procedure Add_Context (Model : in out Context_Model; Info : Replay_Context_Info);
   procedure Add_Event (Model : in out Event_Model; Info : Replay_Event_Info);

   function Build (Contexts : Context_Model; Events : Event_Model) return Result_Model;

   function Context_Count (Model : Context_Model) return Natural;
   function Event_Count (Model : Event_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Replay_Context_Info);
   package Event_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Replay_Event_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Context_Model is record
      Items : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Event_Model is record
      Items : Event_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality;
