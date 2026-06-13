with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration is

   --  Pass1217 shared-state stabilized diagnostic integration.
   --
   --  This package feeds Pass1216 cross-unit shared-state final closure into a
   --  stabilized diagnostic-boundary model.  Accepted shared-state closure rows
   --  are withheld as current semantic evidence; blockers are emitted with their
   --  original abstract-state, volatile/atomic, representation, tasking, view,
   --  dependency, generic, and fingerprint families preserved.

   package Cross_Shared renames Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;

   type Shared_State_Stabilized_Diagnostic_Id is new Natural;
   No_Shared_State_Stabilized_Diagnostic : constant Shared_State_Stabilized_Diagnostic_Id := 0;

   type Shared_State_Stabilized_Family is
     (Shared_State_Stabilized_Diagnostic_Accepted,
      Shared_State_Stabilized_Diagnostic_Cross_Unit,
      Shared_State_Stabilized_Diagnostic_Abstract_State,
      Shared_State_Stabilized_Diagnostic_Volatile_Atomic,
      Shared_State_Stabilized_Diagnostic_Overload_Type,
      Shared_State_Stabilized_Diagnostic_Representation,
      Shared_State_Stabilized_Diagnostic_Tasking_Protected,
      Shared_State_Stabilized_Diagnostic_Dependency,
      Shared_State_Stabilized_Diagnostic_View_Barrier,
      Shared_State_Stabilized_Diagnostic_Generic_Backmapping,
      Shared_State_Stabilized_Diagnostic_State_Visibility,
      Shared_State_Stabilized_Diagnostic_Fingerprint,
      Shared_State_Stabilized_Diagnostic_Multiple,
      Shared_State_Stabilized_Diagnostic_Indeterminate,
      Shared_State_Stabilized_Diagnostic_Unknown);

   type Shared_State_Stabilized_Severity is
     (Shared_State_Stabilized_Info,
      Shared_State_Stabilized_Warning,
      Shared_State_Stabilized_Error);

   type Shared_State_Stabilized_Status is
     (Shared_State_Stabilized_Not_Checked,
      Shared_State_Stabilized_Withheld_Accepted_Current,
      Shared_State_Stabilized_Cross_Unit_Blocker,
      Shared_State_Stabilized_Abstract_State_Blocker,
      Shared_State_Stabilized_Shared_State_Blocker,
      Shared_State_Stabilized_Overload_Type_Blocker,
      Shared_State_Stabilized_Representation_Blocker,
      Shared_State_Stabilized_Tasking_Protected_Blocker,
      Shared_State_Stabilized_Dependency_Blocker,
      Shared_State_Stabilized_View_Barrier,
      Shared_State_Stabilized_Generic_Backmapping_Blocker,
      Shared_State_Stabilized_State_Visibility_Blocker,
      Shared_State_Stabilized_Source_Fingerprint_Mismatch,
      Shared_State_Stabilized_Multiple_Blockers,
      Shared_State_Stabilized_Indeterminate);

   type Shared_State_Stabilized_Row is record
      Id                    : Shared_State_Stabilized_Diagnostic_Id := No_Shared_State_Stabilized_Diagnostic;
      Cross_Shared_Row      : Cross_Shared.Cross_Unit_Shared_State_Row_Id := Cross_Shared.No_Cross_Unit_Shared_State_Row;
      Cross_Shared_Status   : Cross_Shared.Cross_Unit_Shared_State_Status := Cross_Shared.Cross_Unit_Shared_State_Not_Checked;
      Status                : Shared_State_Stabilized_Status := Shared_State_Stabilized_Not_Checked;
      Family                : Shared_State_Stabilized_Family := Shared_State_Stabilized_Diagnostic_Unknown;
      Severity              : Shared_State_Stabilized_Severity := Shared_State_Stabilized_Warning;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name       : Ada.Strings.Unbounded.Unbounded_String;
      State_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Emitted               : Boolean := False;
      Withheld_Current      : Boolean := False;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint    : Natural := 0;
      Closure_Fingerprint   : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
   end record;

   type Shared_State_Stabilized_Set is private;
   type Shared_State_Stabilized_Model is private;

   procedure Clear (Model : in out Shared_State_Stabilized_Model);

   function Build
     (Cross_Shared_Model : Cross_Shared.Cross_Unit_Shared_State_Model)
      return Shared_State_Stabilized_Model;

   function Row_Count (Model : Shared_State_Stabilized_Model) return Natural;
   function Row_At
     (Model : Shared_State_Stabilized_Model;
      Index : Positive) return Shared_State_Stabilized_Row;

   function Query_Count (Set : Shared_State_Stabilized_Set) return Natural;
   function Query_At
     (Set   : Shared_State_Stabilized_Set;
      Index : Positive) return Shared_State_Stabilized_Row;

   function Query_Status
     (Model  : Shared_State_Stabilized_Model;
      Status : Shared_State_Stabilized_Status) return Shared_State_Stabilized_Set;
   function Query_Family
     (Model  : Shared_State_Stabilized_Model;
      Family : Shared_State_Stabilized_Family) return Shared_State_Stabilized_Set;
   function Query_Node
     (Model : Shared_State_Stabilized_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Stabilized_Set;

   function Count_Status
     (Model  : Shared_State_Stabilized_Model;
      Status : Shared_State_Stabilized_Status) return Natural;
   function Count_Family
     (Model  : Shared_State_Stabilized_Model;
      Family : Shared_State_Stabilized_Family) return Natural;

   function Error_Count (Model : Shared_State_Stabilized_Model) return Natural;
   function Warning_Count (Model : Shared_State_Stabilized_Model) return Natural;
   function Info_Count (Model : Shared_State_Stabilized_Model) return Natural;
   function Emitted_Count (Model : Shared_State_Stabilized_Model) return Natural;
   function Withheld_Current_Count (Model : Shared_State_Stabilized_Model) return Natural;
   function Indeterminate_Count (Model : Shared_State_Stabilized_Model) return Natural;
   function Fingerprint (Model : Shared_State_Stabilized_Model) return Natural;

   function Is_Emitted (Status : Shared_State_Stabilized_Status) return Boolean;
   function Is_Withheld_Current (Status : Shared_State_Stabilized_Status) return Boolean;
   function Has_Error (Row : Shared_State_Stabilized_Row) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Shared_State_Stabilized_Row);

   type Shared_State_Stabilized_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Shared_State_Stabilized_Model is record
      Rows                   : Row_Vectors.Vector;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Info_Total             : Natural := 0;
      Emitted_Total          : Natural := 0;
      Withheld_Current_Total : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
