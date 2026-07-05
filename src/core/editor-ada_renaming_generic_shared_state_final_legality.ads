with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
with Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
with Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
with Editor.Ada_Renaming_Alias_Visibility_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

package Editor.Ada_Renaming_Generic_Shared_State_Final_Legality is

   --  Case 1236 renaming/alias visibility generic shared-state final legality.
   --
   --  This package connects Ada renaming, aliasing, use-clause, selected-name, and visibility evidence with the generic/shared-state final semantic chain.
   --  Conclusions for object, exception, package, subprogram, generic renamings, selected aliases,
   --  use clauses, alias lifetime, homograph hiding, direct/use visibility,
   --  generic replay, dispatching and shared-state redirection paths, generic
   --  replay, cross-unit closure, discriminants/variants, accessibility, and
   --  representation-sensitive shared-state effects are accepted only when the
   --  prerequisite semantic evidence agrees.  Missing or blocked prerequisites
   --  remain first-class blocker families; this layer performs no parsing,
   --  file IO, command routing, rendering, or workspace mutation.

   package Renaming_Base renames Editor.Ada_Renaming_Alias_Visibility_Legality;
   package Cross_Generic renames Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
   package Elab_Generic renames Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Overload_Generic renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   package Rep_Generic renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Tasking_Generic renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
   package Access_Generic renames Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
   package Disc_Generic renames Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;

   type Renaming_Generic_Final_Row_Id is new Natural;
   No_Renaming_Generic_Final_Row : constant Renaming_Generic_Final_Row_Id := 0;

   type Renaming_Generic_Final_Kind is
     (Renaming_Generic_Final_Object_Renaming,
      Renaming_Generic_Final_Exception_Renaming,
      Renaming_Generic_Final_Package_Renaming,
      Renaming_Generic_Final_Subprogram_Renaming,
      Renaming_Generic_Final_Generic_Renaming,
      Renaming_Generic_Final_Use_Package,
      Renaming_Generic_Final_Use_Type,
      Renaming_Generic_Final_Selected_Alias,
      Renaming_Generic_Final_Alias_Redirection,
      Renaming_Generic_Final_Homograph_Visibility,
      Renaming_Generic_Final_Accessibility_Alias,
      Renaming_Generic_Final_Dispatching_Alias,
      Renaming_Generic_Final_Global_Depends_Alias,
      Renaming_Generic_Final_Generic_Replay,
      Renaming_Generic_Final_Cross_Unit_Alias,
      Renaming_Generic_Final_Unknown);

   type Renaming_Generic_Final_Blocker_Family is
     (Renaming_Generic_Final_Blocker_None,
      Renaming_Generic_Final_Blocker_Renaming_Alias_Visibility,
      Renaming_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State,
      Renaming_Generic_Final_Blocker_Elaboration_Generic_Shared_State,
      Renaming_Generic_Final_Blocker_Generic_Abstract_Replay,
      Renaming_Generic_Final_Blocker_Overload_Generic_Shared_State,
      Renaming_Generic_Final_Blocker_Representation_Generic_Shared_State,
      Renaming_Generic_Final_Blocker_Tasking_Generic_Shared_State,
      Renaming_Generic_Final_Blocker_Accessibility_Generic_Shared_State,
      Renaming_Generic_Final_Blocker_Discriminant_Generic_Shared_State,
      Renaming_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Renaming_Generic_Final_Blocker_Target_Resolution,
      Renaming_Generic_Final_Blocker_Visibility,
      Renaming_Generic_Final_Blocker_Alias_Lifetime,
      Renaming_Generic_Final_Blocker_Homograph_Hiding,
      Renaming_Generic_Final_Blocker_Profile_Conformance,
      Renaming_Generic_Final_Blocker_Generic_Renaming,
      Renaming_Generic_Final_Blocker_Use_Clause,
      Renaming_Generic_Final_Blocker_Accessibility_Alias,
      Renaming_Generic_Final_Blocker_Discriminant_Alias,
      Renaming_Generic_Final_Blocker_Representation_Alias,
      Renaming_Generic_Final_Blocker_Source_Fingerprint,
      Renaming_Generic_Final_Blocker_Substitution_Fingerprint,
      Renaming_Generic_Final_Blocker_Multiple,
      Renaming_Generic_Final_Blocker_Indeterminate);

   type Renaming_Generic_Final_Status is
     (Renaming_Generic_Final_Not_Checked,
      Renaming_Generic_Final_Legal_Object_Renaming_Accepted,
      Renaming_Generic_Final_Legal_Exception_Renaming_Accepted,
      Renaming_Generic_Final_Legal_Package_Renaming_Accepted,
      Renaming_Generic_Final_Legal_Subprogram_Renaming_Accepted,
      Renaming_Generic_Final_Legal_Generic_Renaming_Accepted,
      Renaming_Generic_Final_Legal_Use_Package_Accepted,
      Renaming_Generic_Final_Legal_Use_Type_Accepted,
      Renaming_Generic_Final_Legal_Selected_Alias_Accepted,
      Renaming_Generic_Final_Legal_Alias_Redirection_Accepted,
      Renaming_Generic_Final_Legal_Homograph_Visibility_Accepted,
      Renaming_Generic_Final_Legal_Accessibility_Alias_Accepted,
      Renaming_Generic_Final_Legal_Dispatching_Alias_Accepted,
      Renaming_Generic_Final_Legal_Global_Depends_Alias_Accepted,
      Renaming_Generic_Final_Legal_Generic_Replay_Accepted,
      Renaming_Generic_Final_Legal_Cross_Unit_Alias_Accepted,
      Renaming_Generic_Final_Missing_Renaming_Alias_Row,
      Renaming_Generic_Final_Renaming_Alias_Blocker,
      Renaming_Generic_Final_Missing_Cross_Unit_Generic_Row,
      Renaming_Generic_Final_Cross_Unit_Generic_Blocker,
      Renaming_Generic_Final_Missing_Elaboration_Generic_Row,
      Renaming_Generic_Final_Elaboration_Generic_Blocker,
      Renaming_Generic_Final_Missing_Generic_Replay_Row,
      Renaming_Generic_Final_Generic_Replay_Blocker,
      Renaming_Generic_Final_Missing_Overload_Generic_Row,
      Renaming_Generic_Final_Overload_Generic_Blocker,
      Renaming_Generic_Final_Missing_Representation_Generic_Row,
      Renaming_Generic_Final_Representation_Generic_Blocker,
      Renaming_Generic_Final_Missing_Tasking_Generic_Row,
      Renaming_Generic_Final_Tasking_Generic_Blocker,
      Renaming_Generic_Final_Missing_Accessibility_Generic_Row,
      Renaming_Generic_Final_Accessibility_Generic_Blocker,
      Renaming_Generic_Final_Missing_Discriminant_Generic_Row,
      Renaming_Generic_Final_Discriminant_Generic_Blocker,
      Renaming_Generic_Final_Missing_Stabilized_Closure_Row,
      Renaming_Generic_Final_Stabilized_Closure_Blocker,
      Renaming_Generic_Final_Target_Resolution_Blocker,
      Renaming_Generic_Final_Visibility_Blocker,
      Renaming_Generic_Final_Alias_Lifetime_Blocker,
      Renaming_Generic_Final_Homograph_Hiding_Blocker,
      Renaming_Generic_Final_Profile_Conformance_Blocker,
      Renaming_Generic_Final_Generic_Renaming_Blocker,
      Renaming_Generic_Final_Use_Clause_Blocker,
      Renaming_Generic_Final_Accessibility_Alias_Blocker,
      Renaming_Generic_Final_Discriminant_Alias_Blocker,
      Renaming_Generic_Final_Representation_Alias_Blocker,
      Renaming_Generic_Final_Source_Fingerprint_Mismatch,
      Renaming_Generic_Final_Substitution_Fingerprint_Mismatch,
      Renaming_Generic_Final_Multiple_Blockers,
      Renaming_Generic_Final_Indeterminate);

   type Renaming_Generic_Final_Context is record
      Id                         : Renaming_Generic_Final_Row_Id := No_Renaming_Generic_Final_Row;
      Kind                       : Renaming_Generic_Final_Kind := Renaming_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Renaming_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Renaming_Base_Row        : Renaming_Base.Renaming_Legality_Id := Renaming_Base.No_Renaming_Legality;
      Renaming_Base_Status     : Renaming_Base.Renaming_Legality_Status := Renaming_Base.Renaming_Legality_Not_Checked;
      Cross_Generic_Row          : Cross_Generic.Cross_Unit_Generic_Final_Row_Id := Cross_Generic.No_Cross_Unit_Generic_Final_Row;
      Cross_Generic_Status       : Cross_Generic.Cross_Unit_Generic_Final_Status := Cross_Generic.Cross_Unit_Generic_Final_Not_Checked;
      Elaboration_Generic_Row    : Elab_Generic.Elaboration_Generic_Final_Row_Id := Elab_Generic.No_Elaboration_Generic_Final_Row;
      Elaboration_Generic_Status : Elab_Generic.Elaboration_Generic_Final_Status := Elab_Generic.Elaboration_Generic_Final_Not_Checked;
      Generic_Replay_Row         : Generic_Replay.Generic_Abstract_Replay_Row_Id := Generic_Replay.No_Generic_Abstract_Replay_Row;
      Generic_Replay_Status      : Generic_Replay.Generic_Abstract_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Not_Checked;
      Overload_Generic_Row       : Overload_Generic.Overload_Generic_Final_Row_Id := Overload_Generic.No_Overload_Generic_Final_Row;
      Overload_Generic_Status    : Overload_Generic.Overload_Generic_Final_Status := Overload_Generic.Overload_Generic_Final_Not_Checked;
      Representation_Generic_Row : Rep_Generic.Representation_Generic_Final_Row_Id := Rep_Generic.No_Representation_Generic_Final_Row;
      Representation_Generic_Status : Rep_Generic.Representation_Generic_Final_Status := Rep_Generic.Representation_Generic_Final_Not_Checked;
      Tasking_Generic_Row        : Tasking_Generic.Tasking_Generic_Final_Row_Id := Tasking_Generic.No_Tasking_Generic_Final_Row;
      Tasking_Generic_Status     : Tasking_Generic.Tasking_Generic_Final_Status := Tasking_Generic.Tasking_Generic_Final_Not_Checked;
      Accessibility_Generic_Row  : Access_Generic.Accessibility_Generic_Final_Row_Id := Access_Generic.No_Accessibility_Generic_Final_Row;
      Accessibility_Generic_Status : Access_Generic.Accessibility_Generic_Final_Status := Access_Generic.Accessibility_Generic_Final_Not_Checked;
      Discriminant_Generic_Row   : Disc_Generic.Discriminant_Generic_Final_Row_Id := Disc_Generic.No_Discriminant_Generic_Final_Row;
      Discriminant_Generic_Status : Disc_Generic.Discriminant_Generic_Final_Status := Disc_Generic.Discriminant_Generic_Final_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Elaboration_Generic : Boolean := False;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Overload_Generic  : Boolean := False;
      Requires_Representation_Generic : Boolean := False;
      Requires_Tasking_Generic   : Boolean := False;
      Requires_Accessibility_Generic : Boolean := False;
      Requires_Discriminant_Generic : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Target_Resolution_Blocker : Boolean := False;
      Visibility_Blocker  : Boolean := False;
      Alias_Lifetime_Blocker : Boolean := False;
      Homograph_Hiding_Blocker : Boolean := False;
      Profile_Conformance_Blocker : Boolean := False;
      Generic_Renaming_Blocker  : Boolean := False;
      Use_Clause_Blocker         : Boolean := False;
      Accessibility_Alias_Blocker : Boolean := False;
      Discriminant_Alias_Blocker : Boolean := False;
      Representation_Alias_Blocker : Boolean := False;
      Source_Fingerprint        : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint  : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                : Positive := 1;
      Start_Column              : Positive := 1;
      End_Line                  : Positive := 1;
      End_Column                : Positive := 1;
   end record;

   type Renaming_Generic_Final_Row is record
      Id                         : Renaming_Generic_Final_Row_Id := No_Renaming_Generic_Final_Row;
      Context                    : Renaming_Generic_Final_Row_Id := No_Renaming_Generic_Final_Row;
      Kind                       : Renaming_Generic_Final_Kind := Renaming_Generic_Final_Unknown;
      Status                     : Renaming_Generic_Final_Status := Renaming_Generic_Final_Not_Checked;
      Blocker_Family             : Renaming_Generic_Final_Blocker_Family := Renaming_Generic_Final_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Renaming_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Fingerprint                : Natural := 0;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Renaming_Generic_Final_Context_Model is private;
   type Renaming_Generic_Final_Model is private;
   type Renaming_Generic_Final_Set is private;

   procedure Clear (Model : in out Renaming_Generic_Final_Context_Model);
   procedure Add_Context (Model : in out Renaming_Generic_Final_Context_Model; Info : Renaming_Generic_Final_Context);
   function Context_Count (Model : Renaming_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Renaming_Generic_Final_Context_Model) return Renaming_Generic_Final_Model;
   function Count (Model : Renaming_Generic_Final_Model) return Natural;
   function Row_At (Model : Renaming_Generic_Final_Model; Index : Positive) return Renaming_Generic_Final_Row;
   function Accepted_Count (Model : Renaming_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Renaming_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Renaming_Generic_Final_Model) return Natural;
   function Count_By_Status (Model : Renaming_Generic_Final_Model; Status : Renaming_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family (Model : Renaming_Generic_Final_Model; Family : Renaming_Generic_Final_Blocker_Family) return Natural;
   function Find_By_Node (Model : Renaming_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Renaming_Generic_Final_Set;
   function Find_By_Source_Fingerprint (Model : Renaming_Generic_Final_Model; Fingerprint : Natural) return Renaming_Generic_Final_Set;
   function Query_Blocker_Family (Model : Renaming_Generic_Final_Model; Family : Renaming_Generic_Final_Blocker_Family) return Renaming_Generic_Final_Set;
   function Query_Count (Set : Renaming_Generic_Final_Set) return Natural;
   function Query_Row_At (Set : Renaming_Generic_Final_Set; Index : Positive) return Renaming_Generic_Final_Row;
   function Stable_Fingerprint (Model : Renaming_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Renaming_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Renaming_Generic_Final_Status) return Boolean;
   function Blocks_Downstream (Status : Renaming_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Renaming_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Renaming_Generic_Final_Row);

   type Renaming_Generic_Final_Context_Model is record
      Items : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Renaming_Generic_Final_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Renaming_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Renaming_Generic_Shared_State_Final_Legality;
