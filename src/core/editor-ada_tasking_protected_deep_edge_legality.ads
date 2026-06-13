with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Flow_Contract_Final_Proof_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Final_Effects_Legality;

package Editor.Ada_Tasking_Protected_Deep_Edge_Legality is

   --  Pass1193 compiler-grade tasking/protected deep edge legality.
   --
   --  This layer strengthens the final tasking/protected effect model for hard
   --  Ada RM edge cases that require more than one local final-effect row:
   --  protected action reentrancy through indirect calls, entry-family queue
   --  semantics, terminate-alternative dependency graphs, and abort/deferred-
   --  finalization ordering.  It consumes the final tasking effect layer, final
   --  flow/contract proof layer, and final cross-unit closure layer so these
   --  edge conclusions cannot remain confidently legal when dependent semantic
   --  evidence is missing, blocked, stale, or indeterminate.  The model is
   --  deterministic, bounded, snapshot-owned, and performs no parsing, file IO,
   --  dirty-state mutation, rendering mutation, command mutation, workspace
   --  mutation, LSP use, compiler invocation, or external parser generation.

   package Cross_Final renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
   package Flow_Proof renames Editor.Ada_Flow_Contract_Final_Proof_Legality;
   package Tasking_Final renames Editor.Ada_Tasking_Protected_Final_Effects_Legality;

   type Deep_Tasking_Row_Id is new Natural;
   No_Deep_Tasking_Row : constant Deep_Tasking_Row_Id := 0;

   type Deep_Tasking_Context_Kind is
     (Deep_Tasking_Protected_Indirect_Call,
      Deep_Tasking_Protected_Reentrancy_Path,
      Deep_Tasking_Entry_Family_Index,
      Deep_Tasking_Entry_Family_Queue,
      Deep_Tasking_Requeue_Entry_Family,
      Deep_Tasking_Select_Entry_Family,
      Deep_Tasking_Accept_Body_Effect_Path,
      Deep_Tasking_Terminate_Alternative_Graph,
      Deep_Tasking_Task_Termination_Graph,
      Deep_Tasking_Abort_Deferred_Finalization,
      Deep_Tasking_Abortable_Select_Finalization,
      Deep_Tasking_Unknown);

   type Deep_Tasking_Status is
     (Deep_Tasking_Not_Checked,
      Deep_Tasking_Legal_Protected_Indirect_Call_Accepted,
      Deep_Tasking_Legal_Protected_Reentrancy_Path_Accepted,
      Deep_Tasking_Legal_Entry_Family_Index_Accepted,
      Deep_Tasking_Legal_Entry_Family_Queue_Accepted,
      Deep_Tasking_Legal_Requeue_Entry_Family_Accepted,
      Deep_Tasking_Legal_Select_Entry_Family_Accepted,
      Deep_Tasking_Legal_Accept_Body_Effect_Path_Accepted,
      Deep_Tasking_Legal_Terminate_Alternative_Graph_Accepted,
      Deep_Tasking_Legal_Task_Termination_Graph_Accepted,
      Deep_Tasking_Legal_Abort_Deferred_Finalization_Accepted,
      Deep_Tasking_Legal_Abortable_Select_Finalization_Accepted,
      Deep_Tasking_Missing_Final_Tasking_Row,
      Deep_Tasking_Final_Tasking_Blocker,
      Deep_Tasking_Missing_Flow_Proof_Row,
      Deep_Tasking_Flow_Contract_Blocker,
      Deep_Tasking_Missing_Cross_Unit_Row,
      Deep_Tasking_Cross_Unit_Blocker,
      Deep_Tasking_Indirect_Reentrancy_Blocker,
      Deep_Tasking_Protected_Callback_Reentrancy_Blocker,
      Deep_Tasking_Entry_Family_Index_Blocker,
      Deep_Tasking_Entry_Family_Queue_Blocker,
      Deep_Tasking_Requeue_Family_Blocker,
      Deep_Tasking_Select_Family_Blocker,
      Deep_Tasking_Accept_Body_Effect_Blocker,
      Deep_Tasking_Terminate_Dependency_Missing_Edge,
      Deep_Tasking_Terminate_Dependency_Cycle,
      Deep_Tasking_Terminate_Dependency_Overflow,
      Deep_Tasking_Task_Termination_Order_Blocker,
      Deep_Tasking_Abort_Deferred_Finalization_Blocker,
      Deep_Tasking_Abortable_Select_Finalization_Blocker,
      Deep_Tasking_Source_Fingerprint_Mismatch,
      Deep_Tasking_Multiple_Blockers,
      Deep_Tasking_Indeterminate);

   type Deep_Tasking_Context_Info is record
      Id                         : Deep_Tasking_Row_Id := No_Deep_Tasking_Row;
      Kind                       : Deep_Tasking_Context_Kind := Deep_Tasking_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Final_Tasking_Row          : Tasking_Final.Final_Tasking_Row_Id := Tasking_Final.No_Final_Tasking_Row;
      Final_Tasking_Status       : Tasking_Final.Final_Tasking_Status := Tasking_Final.Final_Tasking_Not_Checked;
      Final_Tasking_Matches      : Natural := 0;
      Flow_Proof_Row             : Flow_Proof.Flow_Contract_Proof_Row_Id := Flow_Proof.No_Flow_Contract_Proof_Row;
      Flow_Proof_Status          : Flow_Proof.Flow_Contract_Proof_Status := Flow_Proof.Flow_Contract_Proof_Not_Checked;
      Flow_Proof_Matches         : Natural := 0;
      Cross_Unit_Status          : Cross_Final.Cross_Unit_Final_Status := Cross_Final.Cross_Unit_Final_Not_Checked;
      Cross_Unit_Matches         : Natural := 0;
      Requires_Final_Tasking     : Boolean := True;
      Requires_Flow_Proof        : Boolean := False;
      Requires_Cross_Unit        : Boolean := False;
      Indirect_Reentrancy        : Boolean := False;
      Callback_Reentrancy        : Boolean := False;
      Entry_Family_Index_Error   : Boolean := False;
      Entry_Family_Queue_Error   : Boolean := False;
      Requeue_Family_Error       : Boolean := False;
      Select_Family_Error        : Boolean := False;
      Accept_Body_Effect_Error   : Boolean := False;
      Terminate_Missing_Edge     : Boolean := False;
      Terminate_Cycle            : Boolean := False;
      Terminate_Overflow         : Boolean := False;
      Task_Termination_Order_Error : Boolean := False;
      Abort_Deferred_Finalization_Error : Boolean := False;
      Abortable_Select_Finalization_Error : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Deep_Tasking_Info is record
      Id                         : Deep_Tasking_Row_Id := No_Deep_Tasking_Row;
      Context                    : Deep_Tasking_Row_Id := No_Deep_Tasking_Row;
      Kind                       : Deep_Tasking_Context_Kind := Deep_Tasking_Unknown;
      Status                     : Deep_Tasking_Status := Deep_Tasking_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Final_Tasking_Status       : Tasking_Final.Final_Tasking_Status := Tasking_Final.Final_Tasking_Not_Checked;
      Flow_Proof_Status          : Flow_Proof.Flow_Contract_Proof_Status := Flow_Proof.Flow_Contract_Proof_Not_Checked;
      Cross_Unit_Status          : Cross_Final.Cross_Unit_Final_Status := Cross_Final.Cross_Unit_Final_Not_Checked;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Deep_Tasking_Context_Model is private;
   type Deep_Tasking_Set is private;
   type Deep_Tasking_Model is private;

   procedure Clear (Model : in out Deep_Tasking_Context_Model);
   procedure Add_Context (Model : in out Deep_Tasking_Context_Model; Info : Deep_Tasking_Context_Info);
   function Context_Count (Model : Deep_Tasking_Context_Model) return Natural;
   function Context_At (Model : Deep_Tasking_Context_Model; Index : Positive) return Deep_Tasking_Context_Info;
   function Fingerprint (Model : Deep_Tasking_Context_Model) return Natural;

   function Build (Contexts : Deep_Tasking_Context_Model) return Deep_Tasking_Model;
   function Row_Count (Model : Deep_Tasking_Model) return Natural;
   function Row_At (Model : Deep_Tasking_Model; Index : Positive) return Deep_Tasking_Info;
   function First_For_Node (Model : Deep_Tasking_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Deep_Tasking_Info;
   function Rows_For_Status (Model : Deep_Tasking_Model; Status : Deep_Tasking_Status) return Deep_Tasking_Set;
   function Rows_For_Kind (Model : Deep_Tasking_Model; Kind : Deep_Tasking_Context_Kind) return Deep_Tasking_Set;
   function Set_Count (Set : Deep_Tasking_Set) return Natural;
   function Set_At (Set : Deep_Tasking_Set; Index : Positive) return Deep_Tasking_Info;
   function Count_Status (Model : Deep_Tasking_Model; Status : Deep_Tasking_Status) return Natural;
   function Count_Kind (Model : Deep_Tasking_Model; Kind : Deep_Tasking_Context_Kind) return Natural;
   function Legal_Count (Model : Deep_Tasking_Model) return Natural;
   function Error_Count (Model : Deep_Tasking_Model) return Natural;
   function Final_Tasking_Error_Count (Model : Deep_Tasking_Model) return Natural;
   function Flow_Proof_Error_Count (Model : Deep_Tasking_Model) return Natural;
   function Cross_Unit_Error_Count (Model : Deep_Tasking_Model) return Natural;
   function Tasking_Edge_Error_Count (Model : Deep_Tasking_Model) return Natural;
   function Indeterminate_Count (Model : Deep_Tasking_Model) return Natural;
   function Fingerprint (Model : Deep_Tasking_Model) return Natural;

   function Is_Legal (Status : Deep_Tasking_Status) return Boolean;
   function Is_Final_Tasking_Error (Status : Deep_Tasking_Status) return Boolean;
   function Is_Flow_Proof_Error (Status : Deep_Tasking_Status) return Boolean;
   function Is_Cross_Unit_Error (Status : Deep_Tasking_Status) return Boolean;
   function Is_Tasking_Edge_Error (Status : Deep_Tasking_Status) return Boolean;
   function Is_Indeterminate (Status : Deep_Tasking_Status) return Boolean;
   function Has_Error (Info : Deep_Tasking_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors (Positive, Deep_Tasking_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors (Positive, Deep_Tasking_Info);

   type Deep_Tasking_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Deep_Tasking_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Deep_Tasking_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Final_Tasking_Error_Total : Natural := 0;
      Flow_Proof_Error_Total : Natural := 0;
      Cross_Unit_Error_Total : Natural := 0;
      Tasking_Edge_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
