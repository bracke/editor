with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
with Editor.Ada_Flow_Contract_Final_Proof_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Deep_Edge_Legality;

package Editor.Ada_Volatile_Atomic_Shared_State_Legality is

   --  Pass1212 volatile/atomic/shared-variable legality.
   --
   --  This package deepens Ada shared-state legality after abstract/refined
   --  state modelling.  It connects volatile and atomic object effects,
   --  independent components, shared variables, protected/task shared-state
   --  effects, Shared_Passive-style state contexts, abstract/refined state
   --  proof rows, final flow/contract proof rows, deep tasking/protected rows,
   --  and stabilized closure evidence.  It is deterministic, bounded, and
   --  snapshot-owned: it performs no parsing, file IO, dirty-state mutation,
   --  command/keybinding/workspace/render mutation, LSP use, compiler
   --  invocation, or external parser generation.

   package Abstract_States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   package Flow_Proof renames Editor.Ada_Flow_Contract_Final_Proof_Legality;
   package Stabilized renames Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
   package Tasking_Deep renames Editor.Ada_Tasking_Protected_Deep_Edge_Legality;

   type Shared_State_Row_Id is new Natural;
   No_Shared_State_Row : constant Shared_State_Row_Id := 0;

   type Shared_State_Context_Kind is
     (Shared_State_Volatile_Read,
      Shared_State_Volatile_Write,
      Shared_State_Volatile_Read_Write_Order,
      Shared_State_Atomic_Read,
      Shared_State_Atomic_Write,
      Shared_State_Atomic_Read_Write,
      Shared_State_Independent_Component,
      Shared_State_Shared_Variable_Access,
      Shared_State_Protected_Object_Access,
      Shared_State_Task_Activation_Effect,
      Shared_State_Task_Termination_Effect,
      Shared_State_Shared_Passive_Context,
      Shared_State_Abstract_State_Effect,
      Shared_State_Unknown);

   type Shared_State_Status is
     (Shared_State_Not_Checked,
      Shared_State_Legal_Volatile_Read_Accepted,
      Shared_State_Legal_Volatile_Write_Accepted,
      Shared_State_Legal_Volatile_Order_Accepted,
      Shared_State_Legal_Atomic_Read_Accepted,
      Shared_State_Legal_Atomic_Write_Accepted,
      Shared_State_Legal_Atomic_Read_Write_Accepted,
      Shared_State_Legal_Independent_Component_Accepted,
      Shared_State_Legal_Shared_Variable_Access_Accepted,
      Shared_State_Legal_Protected_Object_Access_Accepted,
      Shared_State_Legal_Task_Activation_Accepted,
      Shared_State_Legal_Task_Termination_Accepted,
      Shared_State_Legal_Shared_Passive_Accepted,
      Shared_State_Legal_Abstract_State_Effect_Accepted,
      Shared_State_Missing_Abstract_State_Row,
      Shared_State_Abstract_State_Blocker,
      Shared_State_Missing_Flow_Proof_Row,
      Shared_State_Flow_Proof_Blocker,
      Shared_State_Missing_Tasking_Row,
      Shared_State_Tasking_Blocker,
      Shared_State_Missing_Stabilized_Closure_Row,
      Shared_State_Stabilized_Closure_Blocker,
      Shared_State_Volatile_Read_Order_Blocker,
      Shared_State_Volatile_Write_Order_Blocker,
      Shared_State_Volatile_Read_Write_Reordering,
      Shared_State_Atomic_Read_Write_Blocker,
      Shared_State_Atomic_Nonatomic_Mixed_Access,
      Shared_State_Atomic_Alignment_Blocker,
      Shared_State_Independent_Component_Overlap,
      Shared_State_Shared_Variable_Unprotected_Access,
      Shared_State_Protected_State_Mode_Mismatch,
      Shared_State_Task_Activation_Effect_Blocker,
      Shared_State_Task_Termination_Effect_Blocker,
      Shared_State_Shared_Passive_Effect_Blocker,
      Shared_State_Source_Fingerprint_Mismatch,
      Shared_State_Multiple_Blockers,
      Shared_State_Indeterminate);

   type Shared_State_Context_Info is record
      Id                         : Shared_State_Row_Id := No_Shared_State_Row;
      Kind                       : Shared_State_Context_Kind := Shared_State_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Abstract_State_Row         : Abstract_States.Abstract_State_Row_Id := Abstract_States.No_Abstract_State_Row;
      Abstract_State_Status      : Abstract_States.Abstract_State_Status := Abstract_States.Abstract_State_Not_Checked;
      Flow_Proof_Row             : Flow_Proof.Flow_Contract_Proof_Row_Id := Flow_Proof.No_Flow_Contract_Proof_Row;
      Flow_Proof_Status          : Flow_Proof.Flow_Contract_Proof_Status := Flow_Proof.Flow_Contract_Proof_Not_Checked;
      Tasking_Row                : Tasking_Deep.Deep_Tasking_Row_Id := Tasking_Deep.No_Deep_Tasking_Row;
      Tasking_Status             : Tasking_Deep.Deep_Tasking_Status := Tasking_Deep.Deep_Tasking_Not_Checked;
      Stabilized_Row             : Stabilized.Final_Stabilized_Closure_Id := Stabilized.No_Final_Stabilized_Closure;
      Stabilized_Status          : Stabilized.Final_Stabilized_Closure_Status := Stabilized.Final_Stabilized_Closure_Not_Checked;
      Requires_Abstract_State    : Boolean := False;
      Requires_Flow_Proof        : Boolean := True;
      Requires_Tasking           : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Volatile_Read_Order_Error  : Boolean := False;
      Volatile_Write_Order_Error : Boolean := False;
      Volatile_Reordering        : Boolean := False;
      Atomic_Read_Write_Error    : Boolean := False;
      Atomic_Nonatomic_Mixed_Access : Boolean := False;
      Atomic_Alignment_Error     : Boolean := False;
      Independent_Component_Overlap : Boolean := False;
      Shared_Variable_Unprotected : Boolean := False;
      Protected_Mode_Mismatch    : Boolean := False;
      Task_Activation_Error      : Boolean := False;
      Task_Termination_Error     : Boolean := False;
      Shared_Passive_Error       : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Shared_State_Info is record
      Id                         : Shared_State_Row_Id := No_Shared_State_Row;
      Context                    : Shared_State_Row_Id := No_Shared_State_Row;
      Kind                       : Shared_State_Context_Kind := Shared_State_Unknown;
      Status                     : Shared_State_Status := Shared_State_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
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

   type Shared_State_Context_Model is private;
   type Shared_State_Model is private;
   type Shared_State_Set is private;

   procedure Clear (Model : in out Shared_State_Context_Model);
   procedure Add_Context (Model : in out Shared_State_Context_Model; Info : Shared_State_Context_Info);
   function Context_Count (Model : Shared_State_Context_Model) return Natural;
   function Context_At (Model : Shared_State_Context_Model; Index : Positive) return Shared_State_Context_Info;
   function Fingerprint (Model : Shared_State_Context_Model) return Natural;

   function Build (Contexts : Shared_State_Context_Model) return Shared_State_Model;
   function Row_Count (Model : Shared_State_Model) return Natural;
   function Row_At (Model : Shared_State_Model; Index : Positive) return Shared_State_Info;
   function First_For_Node (Model : Shared_State_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Info;
   function Rows_For_Status (Model : Shared_State_Model; Status : Shared_State_Status) return Shared_State_Set;
   function Rows_For_Kind (Model : Shared_State_Model; Kind : Shared_State_Context_Kind) return Shared_State_Set;
   function Set_Count (Set : Shared_State_Set) return Natural;
   function Set_At (Set : Shared_State_Set; Index : Positive) return Shared_State_Info;
   function Count_Status (Model : Shared_State_Model; Status : Shared_State_Status) return Natural;
   function Count_Kind (Model : Shared_State_Model; Kind : Shared_State_Context_Kind) return Natural;
   function Legal_Count (Model : Shared_State_Model) return Natural;
   function Error_Count (Model : Shared_State_Model) return Natural;
   function Volatile_Error_Count (Model : Shared_State_Model) return Natural;
   function Atomic_Error_Count (Model : Shared_State_Model) return Natural;
   function Shared_Variable_Error_Count (Model : Shared_State_Model) return Natural;
   function Dependency_Error_Count (Model : Shared_State_Model) return Natural;
   function Indeterminate_Count (Model : Shared_State_Model) return Natural;
   function Fingerprint (Model : Shared_State_Model) return Natural;

   function Is_Legal (Status : Shared_State_Status) return Boolean;
   function Is_Volatile_Error (Status : Shared_State_Status) return Boolean;
   function Is_Atomic_Error (Status : Shared_State_Status) return Boolean;
   function Is_Shared_Variable_Error (Status : Shared_State_Status) return Boolean;
   function Is_Dependency_Error (Status : Shared_State_Status) return Boolean;
   function Is_Indeterminate (Status : Shared_State_Status) return Boolean;
   function Has_Error (Info : Shared_State_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Shared_State_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Shared_State_Info);

   type Shared_State_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Shared_State_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Shared_State_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Volatile_Atomic_Shared_State_Legality;
