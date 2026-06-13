with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package Editor.Ada_Overload_Shared_State_RM_Edge_Legality is

   --  Pass1213 overload/type RM shared-state edge legality.
   --
   --  This package deepens the final overload/type RM consumer layer with
   --  abstract/refined-state and volatile/atomic/shared-state evidence.  It
   --  prevents prefixed calls, dispatching calls, access-to-subprogram
   --  selections, controlling-result selections, inherited primitive
   --  selections, generic formal subprogram selections, and universal numeric
   --  ties from remaining confidently legal when the selected operation has
   --  unresolved or illegal abstract-state, volatile, atomic, protected, or
   --  shared-variable effects.  It is deterministic, bounded, and
   --  snapshot-owned and performs no parsing, file IO, dirty-state mutation,
   --  command/keybinding/workspace/render mutation, compiler invocation, LSP
   --  use, external parser generation, or projection-side analysis.

   package Abstract_States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   package Final_RM renames Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
   package Shared_State renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;

   type Overload_Shared_State_Row_Id is new Natural;
   No_Overload_Shared_State_Row : constant Overload_Shared_State_Row_Id := 0;

   type Overload_Shared_State_Context_Kind is
     (Overload_Shared_State_Prefixed_Call,
      Overload_Shared_State_Dispatching_Call,
      Overload_Shared_State_Access_Subprogram_Call,
      Overload_Shared_State_Class_Wide_Controlling_Result,
      Overload_Shared_State_Inherited_Primitive,
      Overload_Shared_State_Generic_Formal_Subprogram,
      Overload_Shared_State_Universal_Numeric_Operator,
      Overload_Shared_State_Renamed_Primitive,
      Overload_Shared_State_Abstract_State_Effect,
      Overload_Shared_State_Volatile_Atomic_Effect,
      Overload_Shared_State_Unknown);

   type Overload_Shared_State_Status is
     (Overload_Shared_State_Not_Checked,
      Overload_Shared_State_Legal_Prefixed_Call_Accepted,
      Overload_Shared_State_Legal_Dispatching_Call_Accepted,
      Overload_Shared_State_Legal_Access_Subprogram_Call_Accepted,
      Overload_Shared_State_Legal_Class_Wide_Result_Accepted,
      Overload_Shared_State_Legal_Inherited_Primitive_Accepted,
      Overload_Shared_State_Legal_Generic_Formal_Subprogram_Accepted,
      Overload_Shared_State_Legal_Universal_Numeric_Operator_Accepted,
      Overload_Shared_State_Legal_Renamed_Primitive_Accepted,
      Overload_Shared_State_Legal_Abstract_State_Effect_Accepted,
      Overload_Shared_State_Legal_Volatile_Atomic_Effect_Accepted,
      Overload_Shared_State_Missing_Final_RM_Row,
      Overload_Shared_State_Final_RM_Blocker,
      Overload_Shared_State_Final_RM_Ambiguous,
      Overload_Shared_State_Missing_Shared_State_Row,
      Overload_Shared_State_Shared_State_Blocker,
      Overload_Shared_State_Missing_Abstract_State_Row,
      Overload_Shared_State_Abstract_State_Blocker,
      Overload_Shared_State_Volatile_Effect_Blocker,
      Overload_Shared_State_Atomic_Effect_Blocker,
      Overload_Shared_State_Shared_Variable_Effect_Blocker,
      Overload_Shared_State_Protected_Effect_Blocker,
      Overload_Shared_State_Dispatching_Effect_Mismatch,
      Overload_Shared_State_Access_Subprogram_Effect_Mismatch,
      Overload_Shared_State_Generic_Formal_Effect_Mismatch,
      Overload_Shared_State_Renamed_Primitive_Effect_Mismatch,
      Overload_Shared_State_Universal_Numeric_State_Ambiguous,
      Overload_Shared_State_Source_Fingerprint_Mismatch,
      Overload_Shared_State_Multiple_Blockers,
      Overload_Shared_State_Indeterminate);

   type Overload_Shared_State_Context_Info is record
      Id                         : Overload_Shared_State_Row_Id := No_Overload_Shared_State_Row;
      Kind                       : Overload_Shared_State_Context_Kind := Overload_Shared_State_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Final_RM_Row               : Final_RM.Final_RM_Row_Id := Final_RM.No_Final_RM_Row;
      Final_RM_Status            : Final_RM.Final_RM_Status := Final_RM.Final_RM_Not_Checked;
      Shared_State_Row           : Shared_State.Shared_State_Row_Id := Shared_State.No_Shared_State_Row;
      Shared_State_Status        : Shared_State.Shared_State_Status := Shared_State.Shared_State_Not_Checked;
      Abstract_State_Row         : Abstract_States.Abstract_State_Row_Id := Abstract_States.No_Abstract_State_Row;
      Abstract_State_Status      : Abstract_States.Abstract_State_Status := Abstract_States.Abstract_State_Not_Checked;
      Requires_Final_RM          : Boolean := True;
      Requires_Shared_State      : Boolean := True;
      Requires_Abstract_State    : Boolean := False;
      Volatile_Effect_Blocker    : Boolean := False;
      Atomic_Effect_Blocker      : Boolean := False;
      Shared_Variable_Blocker    : Boolean := False;
      Protected_Effect_Blocker   : Boolean := False;
      Dispatching_Effect_Mismatch : Boolean := False;
      Access_Subprogram_Effect_Mismatch : Boolean := False;
      Generic_Formal_Effect_Mismatch : Boolean := False;
      Renamed_Primitive_Effect_Mismatch : Boolean := False;
      Universal_Numeric_State_Ambiguous : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Overload_Shared_State_Info is record
      Id                         : Overload_Shared_State_Row_Id := No_Overload_Shared_State_Row;
      Context                    : Overload_Shared_State_Row_Id := No_Overload_Shared_State_Row;
      Kind                       : Overload_Shared_State_Context_Kind := Overload_Shared_State_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                     : Overload_Shared_State_Status := Overload_Shared_State_Not_Checked;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Final_RM_Row               : Final_RM.Final_RM_Row_Id := Final_RM.No_Final_RM_Row;
      Final_RM_Status            : Final_RM.Final_RM_Status := Final_RM.Final_RM_Not_Checked;
      Shared_State_Row           : Shared_State.Shared_State_Row_Id := Shared_State.No_Shared_State_Row;
      Shared_State_Status        : Shared_State.Shared_State_Status := Shared_State.Shared_State_Not_Checked;
      Abstract_State_Row         : Abstract_States.Abstract_State_Row_Id := Abstract_States.No_Abstract_State_Row;
      Abstract_State_Status      : Abstract_States.Abstract_State_Status := Abstract_States.Abstract_State_Not_Checked;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Overload_Shared_State_Context_Model is private;
   type Overload_Shared_State_Model is private;
   type Overload_Shared_State_Set is private;

   procedure Clear (Model : in out Overload_Shared_State_Context_Model);
   procedure Add_Context
     (Model : in out Overload_Shared_State_Context_Model;
      Info  : Overload_Shared_State_Context_Info);
   function Context_Count (Model : Overload_Shared_State_Context_Model) return Natural;
   function Context_At
     (Model : Overload_Shared_State_Context_Model;
      Index : Positive) return Overload_Shared_State_Context_Info;
   function Fingerprint (Model : Overload_Shared_State_Context_Model) return Natural;

   function Build (Contexts : Overload_Shared_State_Context_Model) return Overload_Shared_State_Model;
   function Row_Count (Model : Overload_Shared_State_Model) return Natural;
   function Row_At
     (Model : Overload_Shared_State_Model;
      Index : Positive) return Overload_Shared_State_Info;
   function First_For_Node
     (Model : Overload_Shared_State_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Shared_State_Info;
   function Rows_For_Status
     (Model  : Overload_Shared_State_Model;
      Status : Overload_Shared_State_Status) return Overload_Shared_State_Set;
   function Rows_For_Kind
     (Model : Overload_Shared_State_Model;
      Kind  : Overload_Shared_State_Context_Kind) return Overload_Shared_State_Set;
   function Set_Count (Set : Overload_Shared_State_Set) return Natural;
   function Set_At
     (Set   : Overload_Shared_State_Set;
      Index : Positive) return Overload_Shared_State_Info;

   function Count_Status
     (Model  : Overload_Shared_State_Model;
      Status : Overload_Shared_State_Status) return Natural;
   function Count_Kind
     (Model : Overload_Shared_State_Model;
      Kind  : Overload_Shared_State_Context_Kind) return Natural;
   function Legal_Count (Model : Overload_Shared_State_Model) return Natural;
   function Blocker_Count (Model : Overload_Shared_State_Model) return Natural;
   function Dependency_Blocker_Count (Model : Overload_Shared_State_Model) return Natural;
   function Shared_State_Blocker_Count (Model : Overload_Shared_State_Model) return Natural;
   function Abstract_State_Blocker_Count (Model : Overload_Shared_State_Model) return Natural;
   function Effect_Blocker_Count (Model : Overload_Shared_State_Model) return Natural;
   function Ambiguous_Count (Model : Overload_Shared_State_Model) return Natural;
   function Indeterminate_Count (Model : Overload_Shared_State_Model) return Natural;
   function Fingerprint (Model : Overload_Shared_State_Model) return Natural;

   function Is_Legal (Status : Overload_Shared_State_Status) return Boolean;
   function Is_Dependency_Blocker (Status : Overload_Shared_State_Status) return Boolean;
   function Is_Effect_Blocker (Status : Overload_Shared_State_Status) return Boolean;
   function Is_Ambiguous (Status : Overload_Shared_State_Status) return Boolean;
   function Has_Error (Info : Overload_Shared_State_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Shared_State_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Shared_State_Info);

   type Overload_Shared_State_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Shared_State_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Shared_State_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
