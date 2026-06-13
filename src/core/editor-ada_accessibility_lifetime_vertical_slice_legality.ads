with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Accessibility_Lifetime_Vertical_Slice_Legality is

   --  Pass1300 vertical-slice accessibility and lifetime legality.  This
   --  package performs concrete RM-facing accessibility checks against
   --  source-shaped scope, entity, and access-flow evidence.  It models
   --  scope/master depth, rejects access values escaping to longer-lived
   --  masters through assignments, returns, aggregates, generics, renamings,
   --  discriminants, and protected/task shared state, and validates
   --  access-to-subprogram profile compatibility without adding another
   --  diagnostic/provenance/recheck wrapper.

   type Scope_Id is new Natural;
   No_Scope : constant Scope_Id := 0;

   type Entity_Id is new Natural;
   No_Entity : constant Entity_Id := 0;

   type Flow_Id is new Natural;
   No_Flow : constant Flow_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Scope_Kind is
     (Scope_Library,
      Scope_Package_Spec,
      Scope_Package_Body,
      Scope_Subprogram,
      Scope_Block,
      Scope_Task,
      Scope_Protected,
      Scope_Generic_Template,
      Scope_Generic_Instance,
      Scope_Unknown);

   type Entity_Kind is
     (Entity_Object,
      Entity_Access_Object,
      Entity_Anonymous_Access,
      Entity_Access_Subprogram,
      Entity_Function_Result,
      Entity_Generic_Formal_Object,
      Entity_Renaming,
      Entity_Discriminant_Component,
      Entity_Protected_Task_State,
      Entity_Unknown);

   type Operation_Kind is
     (Operation_Assignment,
      Operation_Return,
      Operation_Aggregate_Component,
      Operation_Generic_Actual,
      Operation_Renaming,
      Operation_Access_To_Subprogram,
      Operation_Protected_Task_Shared_State,
      Operation_Discriminant_Component,
      Operation_Unknown);

   type Accessibility_Status is
     (Accessibility_Not_Checked,
      Accessibility_Legal_Static_Master,
      Accessibility_Legal_Runtime_Check,
      Accessibility_Legal_Local_Target,
      Accessibility_Legal_Access_To_Subprogram_Profile,
      Accessibility_Legal_Generic_Substitution,
      Accessibility_Escape_To_Longer_Lived_Master,
      Accessibility_Return_Escape,
      Accessibility_Assignment_Escape,
      Accessibility_Aggregate_Component_Escape,
      Accessibility_Generic_Actual_Escape,
      Accessibility_Renaming_Escape,
      Accessibility_Subprogram_Profile_Mismatch,
      Accessibility_Protected_Task_State_Escape,
      Accessibility_Discriminant_Dependent_Escape,
      Accessibility_Missing_Source,
      Accessibility_Missing_Target,
      Accessibility_Source_Fingerprint_Mismatch,
      Accessibility_Substitution_Fingerprint_Mismatch,
      Accessibility_Multiple_Blockers,
      Accessibility_Indeterminate);

   type Scope_Info is record
      Id       : Scope_Id := No_Scope;
      Parent   : Scope_Id := No_Scope;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Scope_Kind := Scope_Unknown;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Master_Level : Natural := 0;
      Is_Library_Level : Boolean := False;
      Is_Generic_Template : Boolean := False;
      Is_Generic_Instance : Boolean := False;
      Source_Fingerprint : Natural := 0;
   end record;

   type Entity_Info is record
      Id       : Entity_Id := No_Entity;
      Scope    : Scope_Id := No_Scope;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Entity_Kind := Entity_Unknown;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Master_Level : Natural := 0;
      Is_Aliased : Boolean := False;
      Is_Anonymous_Access : Boolean := False;
      Is_Access_To_Subprogram : Boolean := False;
      Is_Generic_Formal : Boolean := False;
      Is_From_Renaming : Boolean := False;
      Renamed_Entity : Entity_Id := No_Entity;
      Is_Discriminant_Dependent : Boolean := False;
      Is_Protected_Or_Task_State : Boolean := False;
      Has_Controlled_Finalization : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
   end record;

   type Flow_Info is record
      Id       : Flow_Id := No_Flow;
      Source   : Entity_Id := No_Entity;
      Target   : Entity_Id := No_Entity;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation : Operation_Kind := Operation_Unknown;
      Allows_Runtime_Accessibility_Check : Boolean := False;
      Requires_Access_To_Subprogram_Profile : Boolean := False;
      In_Generic_Instance : Boolean := False;
      Through_Renaming : Boolean := False;
      Through_Discriminant : Boolean := False;
      Through_Aggregate : Boolean := False;
      Through_Return_Object : Boolean := False;
      Through_Protected_Or_Task_State : Boolean := False;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_Target_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Flow_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Flow     : Flow_Id := No_Flow;
      Source   : Entity_Id := No_Entity;
      Target   : Entity_Id := No_Entity;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation : Operation_Kind := Operation_Unknown;
      Status   : Accessibility_Status := Accessibility_Not_Checked;
      Escape_Blockers : Natural := 0;
      Return_Blockers : Natural := 0;
      Assignment_Blockers : Natural := 0;
      Aggregate_Blockers : Natural := 0;
      Generic_Blockers : Natural := 0;
      Renaming_Blockers : Natural := 0;
      Profile_Blockers : Natural := 0;
      Protected_Task_Blockers : Natural := 0;
      Discriminant_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Substitution_Fingerprint_Blockers : Natural := 0;
      Missing_Source_Blockers : Natural := 0;
      Missing_Target_Blockers : Natural := 0;
      Source_Master_Level : Natural := 0;
      Target_Master_Level : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint : Natural := 0;
      Target_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Scope_Model is private;
   type Entity_Model is private;
   type Flow_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Scope_Model);
   procedure Clear (Model : in out Entity_Model);
   procedure Clear (Model : in out Flow_Model);

   procedure Add_Scope (Model : in out Scope_Model; Info : Scope_Info);
   procedure Add_Entity (Model : in out Entity_Model; Info : Entity_Info);
   procedure Add_Flow (Model : in out Flow_Model; Info : Flow_Info);

   function Build
     (Scopes   : Scope_Model;
      Entities : Entity_Model;
      Flows    : Flow_Model) return Result_Model;

   function Scope_Count (Model : Scope_Model) return Natural;
   function Entity_Count (Model : Entity_Model) return Natural;
   function Flow_Count (Model : Flow_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function First_For_Node
     (Model : Result_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Result_Info;

   function Count_Status
     (Model : Result_Model;
      Status : Accessibility_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Scope_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Scope_Info);
   package Entity_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Entity_Info);
   package Flow_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Flow_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Scope_Model is record
      Items : Scope_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Entity_Model is record
      Items : Entity_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Flow_Model is record
      Items : Flow_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Accessibility_Lifetime_Vertical_Slice_Legality;
