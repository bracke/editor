with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Shared_State_Remediation_Worklist_Legality is

   --  Pass1218 shared-state remediation worklist legality.
   --
   --  This package consumes the Pass1217 shared-state stabilized diagnostic
   --  boundary and turns accepted/blocking abstract-state, volatile/atomic,
   --  overload/type, representation/freezing, tasking/protected, dependency,
   --  view, generic, and fingerprint evidence into a deterministic semantic
   --  remediation worklist.  It is a semantic scheduling model, not a UI
   --  projection: the original blocker family is preserved so bounded
   --  re-analysis can repair prerequisites in dependency order.

   package Stable renames Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;

   type Shared_State_Worklist_Id is new Natural;
   No_Shared_State_Worklist_Item : constant Shared_State_Worklist_Id := 0;

   subtype Shared_State_Worklist_Family is Stable.Shared_State_Stabilized_Family;
   subtype Shared_State_Worklist_Diagnostic_Status is Stable.Shared_State_Stabilized_Status;

   type Shared_State_Worklist_Action is
     (Shared_State_Worklist_No_Action,
      Shared_State_Worklist_Keep_Current_Evidence,
      Shared_State_Worklist_Close_Cross_Unit_Dependency,
      Shared_State_Worklist_Resolve_View_Barrier,
      Shared_State_Worklist_Repair_Generic_Backmapping,
      Shared_State_Worklist_Repair_State_Visibility,
      Shared_State_Worklist_Resolve_Abstract_State,
      Shared_State_Worklist_Resolve_Volatile_Atomic,
      Shared_State_Worklist_Resolve_Overload_Type,
      Shared_State_Worklist_Resolve_Representation,
      Shared_State_Worklist_Resolve_Tasking_Protected,
      Shared_State_Worklist_Recheck_Source_Fingerprint,
      Shared_State_Worklist_Split_Multiple_Blockers,
      Shared_State_Worklist_Recheck_Indeterminate);

   type Shared_State_Worklist_Priority is
     (Shared_State_Worklist_Priority_None,
      Shared_State_Worklist_Priority_Current_Evidence,
      Shared_State_Worklist_Priority_Stale_Or_Fingerprint,
      Shared_State_Worklist_Priority_Dependency,
      Shared_State_Worklist_Priority_View,
      Shared_State_Worklist_Priority_Generic_Backmapping,
      Shared_State_Worklist_Priority_State_Metadata,
      Shared_State_Worklist_Priority_Abstract_State,
      Shared_State_Worklist_Priority_Volatile_Atomic,
      Shared_State_Worklist_Priority_Overload_Type,
      Shared_State_Worklist_Priority_Representation,
      Shared_State_Worklist_Priority_Tasking_Protected,
      Shared_State_Worklist_Priority_Multiple,
      Shared_State_Worklist_Priority_Indeterminate);

   type Shared_State_Worklist_Item is record
      Id                     : Shared_State_Worklist_Id := No_Shared_State_Worklist_Item;
      Stabilized_Row         : Stable.Shared_State_Stabilized_Diagnostic_Id := Stable.No_Shared_State_Stabilized_Diagnostic;
      Stabilized_Status      : Shared_State_Worklist_Diagnostic_Status := Stable.Shared_State_Stabilized_Not_Checked;
      Family                 : Shared_State_Worklist_Family := Stable.Shared_State_Stabilized_Diagnostic_Unknown;
      Action                 : Shared_State_Worklist_Action := Shared_State_Worklist_No_Action;
      Priority               : Shared_State_Worklist_Priority := Shared_State_Worklist_Priority_None;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name        : Ada.Strings.Unbounded.Unbounded_String;
      State_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Ready_For_Recheck      : Boolean := False;
      Blocks_Downstream      : Boolean := False;
      Current_Evidence       : Boolean := False;
      Message                : Ada.Strings.Unbounded.Unbounded_String;
      Detail                 : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint     : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Worklist_Fingerprint   : Natural := 0;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
   end record;

   type Shared_State_Worklist_Model is private;
   type Shared_State_Worklist_Set is private;

   procedure Clear (Model : in out Shared_State_Worklist_Model);

   function Build
     (Diagnostics : Stable.Shared_State_Stabilized_Model)
      return Shared_State_Worklist_Model;

   function Row_Count (Model : Shared_State_Worklist_Model) return Natural;
   function Row_At
     (Model : Shared_State_Worklist_Model;
      Index : Positive) return Shared_State_Worklist_Item;

   function Query_Count (Set : Shared_State_Worklist_Set) return Natural;
   function Query_At
     (Set   : Shared_State_Worklist_Set;
      Index : Positive) return Shared_State_Worklist_Item;

   function Query_Action
     (Model  : Shared_State_Worklist_Model;
      Action : Shared_State_Worklist_Action) return Shared_State_Worklist_Set;
   function Query_Family
     (Model  : Shared_State_Worklist_Model;
      Family : Shared_State_Worklist_Family) return Shared_State_Worklist_Set;
   function Query_Priority
     (Model    : Shared_State_Worklist_Model;
      Priority : Shared_State_Worklist_Priority) return Shared_State_Worklist_Set;
   function Query_Node
     (Model : Shared_State_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Worklist_Set;

   function Count_Action
     (Model  : Shared_State_Worklist_Model;
      Action : Shared_State_Worklist_Action) return Natural;
   function Count_Family
     (Model  : Shared_State_Worklist_Model;
      Family : Shared_State_Worklist_Family) return Natural;
   function Count_Priority
     (Model    : Shared_State_Worklist_Model;
      Priority : Shared_State_Worklist_Priority) return Natural;

   function Current_Evidence_Count (Model : Shared_State_Worklist_Model) return Natural;
   function Ready_For_Recheck_Count (Model : Shared_State_Worklist_Model) return Natural;
   function Blocked_Downstream_Count (Model : Shared_State_Worklist_Model) return Natural;
   function Fingerprint (Model : Shared_State_Worklist_Model) return Natural;

   function Is_Current_Evidence (Item : Shared_State_Worklist_Item) return Boolean;
   function Is_Ready_For_Recheck (Item : Shared_State_Worklist_Item) return Boolean;
   function Blocks_Downstream (Item : Shared_State_Worklist_Item) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Shared_State_Worklist_Item);

   type Shared_State_Worklist_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Shared_State_Worklist_Model is record
      Rows                     : Row_Vectors.Vector;
      Current_Evidence_Total   : Natural := 0;
      Ready_For_Recheck_Total  : Natural := 0;
      Blocked_Downstream_Total : Natural := 0;
      Fingerprint              : Natural := 0;
   end record;

end Editor.Ada_Shared_State_Remediation_Worklist_Legality;
