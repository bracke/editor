with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package Editor.Ada_Tasking_Shared_State_Final_Legality is

   --  Pass1215 tasking/shared-state final legality.
   --
   --  This package closes hard tasking/protected shared-state interactions by
   --  connecting deep tasking/protected RM edge evidence with abstract/refined
   --  state, volatile/atomic/shared-variable, overload shared-state, and
   --  representation/freezing shared-state evidence.  It prevents protected
   --  operation, task activation/termination, accept/requeue/select, entry
   --  family, and abort/finalization conclusions from remaining confidently
   --  legal when shared-state prerequisites are missing, blocked, stale, or
   --  fingerprint-mismatched.

   package Abstract_States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   package Overload_State renames Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
   package Rep_State renames Editor.Ada_Representation_Shared_State_Final_Legality;
   package Shared_State renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;
   package Tasking_Deep renames Editor.Ada_Tasking_Protected_Deep_Edge_Legality;

   type Tasking_Shared_State_Row_Id is new Natural;
   No_Tasking_Shared_State_Row : constant Tasking_Shared_State_Row_Id := 0;

   type Tasking_Shared_State_Context_Kind is
     (Tasking_Shared_State_Protected_Function_Read,
      Tasking_Shared_State_Protected_Procedure_Write,
      Tasking_Shared_State_Protected_Entry_Barrier,
      Tasking_Shared_State_Entry_Family_Queue,
      Tasking_Shared_State_Accept_Body_Effect,
      Tasking_Shared_State_Requeue_Effect,
      Tasking_Shared_State_Select_Alternative,
      Tasking_Shared_State_Task_Activation,
      Tasking_Shared_State_Task_Termination,
      Tasking_Shared_State_Abortable_Finalization,
      Tasking_Shared_State_Abstract_State_Access,
      Tasking_Shared_State_Representation_Effect,
      Tasking_Shared_State_Unknown);

   type Tasking_Shared_State_Status is
     (Tasking_Shared_State_Not_Checked,
      Tasking_Shared_State_Legal_Protected_Function_Read_Accepted,
      Tasking_Shared_State_Legal_Protected_Procedure_Write_Accepted,
      Tasking_Shared_State_Legal_Protected_Entry_Barrier_Accepted,
      Tasking_Shared_State_Legal_Entry_Family_Queue_Accepted,
      Tasking_Shared_State_Legal_Accept_Body_Effect_Accepted,
      Tasking_Shared_State_Legal_Requeue_Effect_Accepted,
      Tasking_Shared_State_Legal_Select_Alternative_Accepted,
      Tasking_Shared_State_Legal_Task_Activation_Accepted,
      Tasking_Shared_State_Legal_Task_Termination_Accepted,
      Tasking_Shared_State_Legal_Abortable_Finalization_Accepted,
      Tasking_Shared_State_Legal_Abstract_State_Access_Accepted,
      Tasking_Shared_State_Legal_Representation_Effect_Accepted,
      Tasking_Shared_State_Missing_Deep_Tasking_Row,
      Tasking_Shared_State_Deep_Tasking_Blocker,
      Tasking_Shared_State_Missing_Shared_State_Row,
      Tasking_Shared_State_Shared_State_Blocker,
      Tasking_Shared_State_Missing_Abstract_State_Row,
      Tasking_Shared_State_Abstract_State_Blocker,
      Tasking_Shared_State_Missing_Overload_State_Row,
      Tasking_Shared_State_Overload_State_Blocker,
      Tasking_Shared_State_Missing_Representation_State_Row,
      Tasking_Shared_State_Representation_State_Blocker,
      Tasking_Shared_State_Protected_Read_Mode_Blocker,
      Tasking_Shared_State_Protected_Write_Mode_Blocker,
      Tasking_Shared_State_Barrier_Side_Effect_Blocker,
      Tasking_Shared_State_Entry_Family_Queue_Blocker,
      Tasking_Shared_State_Accept_Body_Effect_Blocker,
      Tasking_Shared_State_Requeue_Shared_State_Blocker,
      Tasking_Shared_State_Select_Shared_State_Blocker,
      Tasking_Shared_State_Task_Activation_Shared_State_Blocker,
      Tasking_Shared_State_Task_Termination_Shared_State_Blocker,
      Tasking_Shared_State_Abort_Finalization_Shared_State_Blocker,
      Tasking_Shared_State_Abstract_State_Mode_Blocker,
      Tasking_Shared_State_Representation_Effect_Blocker,
      Tasking_Shared_State_Source_Fingerprint_Mismatch,
      Tasking_Shared_State_Multiple_Blockers,
      Tasking_Shared_State_Indeterminate);

   type Tasking_Shared_State_Context_Info is record
      Id                         : Tasking_Shared_State_Row_Id := No_Tasking_Shared_State_Row;
      Kind                       : Tasking_Shared_State_Context_Kind := Tasking_Shared_State_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Deep_Tasking_Row           : Tasking_Deep.Deep_Tasking_Row_Id := Tasking_Deep.No_Deep_Tasking_Row;
      Deep_Tasking_Status        : Tasking_Deep.Deep_Tasking_Status := Tasking_Deep.Deep_Tasking_Not_Checked;
      Shared_State_Row           : Shared_State.Shared_State_Row_Id := Shared_State.No_Shared_State_Row;
      Shared_State_Status        : Shared_State.Shared_State_Status := Shared_State.Shared_State_Not_Checked;
      Abstract_State_Row         : Abstract_States.Abstract_State_Row_Id := Abstract_States.No_Abstract_State_Row;
      Abstract_State_Status      : Abstract_States.Abstract_State_Status := Abstract_States.Abstract_State_Not_Checked;
      Overload_State_Row         : Overload_State.Overload_Shared_State_Row_Id := Overload_State.No_Overload_Shared_State_Row;
      Overload_State_Status      : Overload_State.Overload_Shared_State_Status := Overload_State.Overload_Shared_State_Not_Checked;
      Representation_State_Row   : Rep_State.Representation_Shared_State_Row_Id := Rep_State.No_Representation_Shared_State_Row;
      Representation_State_Status : Rep_State.Representation_Shared_State_Status := Rep_State.Representation_Shared_State_Not_Checked;
      Requires_Deep_Tasking      : Boolean := True;
      Requires_Shared_State      : Boolean := True;
      Requires_Abstract_State    : Boolean := False;
      Requires_Overload_State    : Boolean := False;
      Requires_Representation_State : Boolean := False;
      Protected_Read_Mode_Error  : Boolean := False;
      Protected_Write_Mode_Error : Boolean := False;
      Barrier_Side_Effect_Error  : Boolean := False;
      Entry_Family_Queue_Error   : Boolean := False;
      Accept_Body_Effect_Error   : Boolean := False;
      Requeue_Shared_State_Error : Boolean := False;
      Select_Shared_State_Error  : Boolean := False;
      Task_Activation_Shared_State_Error : Boolean := False;
      Task_Termination_Shared_State_Error : Boolean := False;
      Abort_Finalization_Shared_State_Error : Boolean := False;
      Abstract_State_Mode_Error  : Boolean := False;
      Representation_Effect_Error : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Tasking_Shared_State_Info is record
      Id                         : Tasking_Shared_State_Row_Id := No_Tasking_Shared_State_Row;
      Context                    : Tasking_Shared_State_Row_Id := No_Tasking_Shared_State_Row;
      Kind                       : Tasking_Shared_State_Context_Kind := Tasking_Shared_State_Unknown;
      Status                     : Tasking_Shared_State_Status := Tasking_Shared_State_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Tasking_Shared_State_Context_Model is private;
   type Tasking_Shared_State_Model is private;
   type Tasking_Shared_State_Set is private;

   procedure Clear (Model : in out Tasking_Shared_State_Context_Model);
   procedure Add_Context (Model : in out Tasking_Shared_State_Context_Model; Info : Tasking_Shared_State_Context_Info);
   function Context_Count (Model : Tasking_Shared_State_Context_Model) return Natural;
   function Context_At (Model : Tasking_Shared_State_Context_Model; Index : Positive) return Tasking_Shared_State_Context_Info;
   function Fingerprint (Model : Tasking_Shared_State_Context_Model) return Natural;

   function Build (Contexts : Tasking_Shared_State_Context_Model) return Tasking_Shared_State_Model;
   function Row_Count (Model : Tasking_Shared_State_Model) return Natural;
   function Row_At (Model : Tasking_Shared_State_Model; Index : Positive) return Tasking_Shared_State_Info;
   function First_For_Node (Model : Tasking_Shared_State_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Shared_State_Info;
   function Rows_For_Status (Model : Tasking_Shared_State_Model; Status : Tasking_Shared_State_Status) return Tasking_Shared_State_Set;
   function Rows_For_Kind (Model : Tasking_Shared_State_Model; Kind : Tasking_Shared_State_Context_Kind) return Tasking_Shared_State_Set;
   function Set_Count (Set : Tasking_Shared_State_Set) return Natural;
   function Set_At (Set : Tasking_Shared_State_Set; Index : Positive) return Tasking_Shared_State_Info;
   function Count_Status (Model : Tasking_Shared_State_Model; Status : Tasking_Shared_State_Status) return Natural;
   function Count_Kind (Model : Tasking_Shared_State_Model; Kind : Tasking_Shared_State_Context_Kind) return Natural;
   function Legal_Count (Model : Tasking_Shared_State_Model) return Natural;
   function Error_Count (Model : Tasking_Shared_State_Model) return Natural;
   function Dependency_Error_Count (Model : Tasking_Shared_State_Model) return Natural;
   function Shared_State_Error_Count (Model : Tasking_Shared_State_Model) return Natural;
   function Tasking_Error_Count (Model : Tasking_Shared_State_Model) return Natural;
   function Representation_Error_Count (Model : Tasking_Shared_State_Model) return Natural;
   function Indeterminate_Count (Model : Tasking_Shared_State_Model) return Natural;
   function Fingerprint (Model : Tasking_Shared_State_Model) return Natural;

   function Is_Legal (Status : Tasking_Shared_State_Status) return Boolean;
   function Is_Dependency_Error (Status : Tasking_Shared_State_Status) return Boolean;
   function Is_Shared_State_Error (Status : Tasking_Shared_State_Status) return Boolean;
   function Is_Tasking_Error (Status : Tasking_Shared_State_Status) return Boolean;
   function Is_Representation_Error (Status : Tasking_Shared_State_Status) return Boolean;
   function Is_Indeterminate (Status : Tasking_Shared_State_Status) return Boolean;
   function Has_Error (Info : Tasking_Shared_State_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Tasking_Shared_State_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Tasking_Shared_State_Info);

   type Tasking_Shared_State_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Tasking_Shared_State_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Tasking_Shared_State_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Tasking_Shared_State_Final_Legality;
