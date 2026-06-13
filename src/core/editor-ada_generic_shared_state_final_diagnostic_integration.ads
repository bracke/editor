with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration is

   --  Pass1239 generic/shared-state final diagnostic integration.
   --
   --  This package feeds the completed generic/shared-state final semantic
   --  chain into a diagnostic-boundary model.  Accepted semantic rows are
   --  withheld as current non-diagnostic evidence.  Blocking rows are emitted
   --  with their original definite-initialization, dataflow, predicate,
   --  generic replay, shared-state closure, representation/freezing,
   --  tasking/protected, accessibility, discriminant/variant,
   --  exception/finalization, renaming/alias, volatile/atomic, fingerprint,
   --  multiple-blocker, and indeterminate families preserved.

   package Dataflow_Generic renames Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;

   type Generic_Shared_State_Final_Diagnostic_Id is new Natural;
   No_Generic_Shared_State_Final_Diagnostic : constant Generic_Shared_State_Final_Diagnostic_Id := 0;

   type Generic_Shared_State_Final_Diagnostic_Family is
     (Generic_Shared_State_Final_Diagnostic_Accepted,
      Generic_Shared_State_Final_Diagnostic_Definite_Initialization,
      Generic_Shared_State_Final_Diagnostic_Dataflow_Initialization,
      Generic_Shared_State_Final_Diagnostic_Predicate_Dataflow,
      Generic_Shared_State_Final_Diagnostic_Predicate_Generic_Shared_State,
      Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay,
      Generic_Shared_State_Final_Diagnostic_Stabilized_Shared_State_Closure,
      Generic_Shared_State_Final_Diagnostic_Representation_Generic_Shared_State,
      Generic_Shared_State_Final_Diagnostic_Tasking_Generic_Shared_State,
      Generic_Shared_State_Final_Diagnostic_Accessibility_Generic_Shared_State,
      Generic_Shared_State_Final_Diagnostic_Discriminant_Generic_Shared_State,
      Generic_Shared_State_Final_Diagnostic_Exception_Finalization_Generic_Shared_State,
      Generic_Shared_State_Final_Diagnostic_Renaming_Generic_Shared_State,
      Generic_Shared_State_Final_Diagnostic_Volatile_Atomic_Representation,
      Generic_Shared_State_Final_Diagnostic_Local_Dataflow_RM,
      Generic_Shared_State_Final_Diagnostic_Fingerprint,
      Generic_Shared_State_Final_Diagnostic_Multiple,
      Generic_Shared_State_Final_Diagnostic_Indeterminate,
      Generic_Shared_State_Final_Diagnostic_Unknown);

   type Generic_Shared_State_Final_Diagnostic_Severity is
     (Generic_Shared_State_Final_Diagnostic_Info,
      Generic_Shared_State_Final_Diagnostic_Warning,
      Generic_Shared_State_Final_Diagnostic_Error);

   type Generic_Shared_State_Final_Diagnostic_Status is
     (Generic_Shared_State_Final_Diagnostic_Not_Checked,
      Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current,
      Generic_Shared_State_Final_Diagnostic_Definite_Initialization_Blocker,
      Generic_Shared_State_Final_Diagnostic_Dataflow_Initialization_Blocker,
      Generic_Shared_State_Final_Diagnostic_Predicate_Dataflow_Blocker,
      Generic_Shared_State_Final_Diagnostic_Predicate_Generic_Blocker,
      Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay_Blocker,
      Generic_Shared_State_Final_Diagnostic_Stabilized_Closure_Blocker,
      Generic_Shared_State_Final_Diagnostic_Representation_Generic_Blocker,
      Generic_Shared_State_Final_Diagnostic_Tasking_Generic_Blocker,
      Generic_Shared_State_Final_Diagnostic_Accessibility_Generic_Blocker,
      Generic_Shared_State_Final_Diagnostic_Discriminant_Generic_Blocker,
      Generic_Shared_State_Final_Diagnostic_Exception_Finalization_Generic_Blocker,
      Generic_Shared_State_Final_Diagnostic_Renaming_Generic_Blocker,
      Generic_Shared_State_Final_Diagnostic_Volatile_Atomic_Representation_Blocker,
      Generic_Shared_State_Final_Diagnostic_Local_Dataflow_RM_Blocker,
      Generic_Shared_State_Final_Diagnostic_Source_Fingerprint_Mismatch,
      Generic_Shared_State_Final_Diagnostic_Substitution_Fingerprint_Mismatch,
      Generic_Shared_State_Final_Diagnostic_Multiple_Blockers,
      Generic_Shared_State_Final_Diagnostic_Indeterminate);

   type Generic_Shared_State_Final_Diagnostic_Row is record
      Id                    : Generic_Shared_State_Final_Diagnostic_Id := No_Generic_Shared_State_Final_Diagnostic;
      Dataflow_Row          : Dataflow_Generic.Dataflow_Generic_Final_Row_Id := Dataflow_Generic.No_Dataflow_Generic_Final_Row;
      Dataflow_Status       : Dataflow_Generic.Dataflow_Generic_Final_Status := Dataflow_Generic.Dataflow_Generic_Final_Not_Checked;
      Status                : Generic_Shared_State_Final_Diagnostic_Status := Generic_Shared_State_Final_Diagnostic_Not_Checked;
      Family                : Generic_Shared_State_Final_Diagnostic_Family := Generic_Shared_State_Final_Diagnostic_Unknown;
      Severity              : Generic_Shared_State_Final_Diagnostic_Severity := Generic_Shared_State_Final_Diagnostic_Warning;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name         : Ada.Strings.Unbounded.Unbounded_String;
      State_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Emitted               : Boolean := False;
      Withheld_Current      : Boolean := False;
      Blocks_Downstream     : Boolean := False;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint    : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Semantic_Fingerprint  : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
   end record;

   type Generic_Shared_State_Final_Diagnostic_Set is private;
   type Generic_Shared_State_Final_Diagnostic_Model is private;

   procedure Clear (Model : in out Generic_Shared_State_Final_Diagnostic_Model);

   function Build
     (Dataflow_Model : Dataflow_Generic.Dataflow_Generic_Final_Model)
      return Generic_Shared_State_Final_Diagnostic_Model;

   function Row_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural;
   function Row_At
     (Model : Generic_Shared_State_Final_Diagnostic_Model;
      Index : Positive) return Generic_Shared_State_Final_Diagnostic_Row;

   function Query_Count (Set : Generic_Shared_State_Final_Diagnostic_Set) return Natural;
   function Query_At
     (Set   : Generic_Shared_State_Final_Diagnostic_Set;
      Index : Positive) return Generic_Shared_State_Final_Diagnostic_Row;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Diagnostic_Model;
      Status : Generic_Shared_State_Final_Diagnostic_Status)
      return Generic_Shared_State_Final_Diagnostic_Set;
   function Query_Family
     (Model  : Generic_Shared_State_Final_Diagnostic_Model;
      Family : Generic_Shared_State_Final_Diagnostic_Family)
      return Generic_Shared_State_Final_Diagnostic_Set;
   function Query_Node
     (Model : Generic_Shared_State_Final_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Generic_Shared_State_Final_Diagnostic_Set;
   function Query_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Diagnostic_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Diagnostic_Set;

   function Count_Status
     (Model  : Generic_Shared_State_Final_Diagnostic_Model;
      Status : Generic_Shared_State_Final_Diagnostic_Status) return Natural;
   function Count_Family
     (Model  : Generic_Shared_State_Final_Diagnostic_Model;
      Family : Generic_Shared_State_Final_Diagnostic_Family) return Natural;

   function Error_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural;
   function Info_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural;
   function Emitted_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural;
   function Withheld_Current_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural;

   function Is_Emitted (Status : Generic_Shared_State_Final_Diagnostic_Status) return Boolean;
   function Is_Withheld_Current (Status : Generic_Shared_State_Final_Diagnostic_Status) return Boolean;
   function Has_Error (Row : Generic_Shared_State_Final_Diagnostic_Row) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Shared_State_Final_Diagnostic_Row);

   type Generic_Shared_State_Final_Diagnostic_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Shared_State_Final_Diagnostic_Model is record
      Rows                   : Row_Vectors.Vector;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Info_Total             : Natural := 0;
      Emitted_Total          : Natural := 0;
      Withheld_Current_Total : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
