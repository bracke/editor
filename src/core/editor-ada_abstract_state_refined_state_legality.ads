with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
with Editor.Ada_Flow_Contract_Final_Proof_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Deep_Edge_Legality;

package Editor.Ada_Abstract_State_Refined_State_Legality is

   --  Case 1211 abstract/refined state legality.
   --
   --  This package adds a concrete semantic model for abstract state and
   --  refined state proof obligations.  It connects state declarations,
   --  constituent mappings, cross-unit state visibility, Global/Depends state
   --  usage, task/protected shared-state effects, volatile/atomic effects, and
   --  final stabilized closure evidence.  It is deterministic, bounded, and
   --  snapshot-owned: it performs no parsing, file IO, dirty-state mutation,
   --  command/keybinding/workspace/render mutation, LSP use, compiler
   --  invocation, or external parser generation.

   package Flow_Proof renames Editor.Ada_Flow_Contract_Final_Proof_Legality;
   package Stabilized renames Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
   package Tasking_Deep renames Editor.Ada_Tasking_Protected_Deep_Edge_Legality;

   type Abstract_State_Row_Id is new Natural;
   No_Abstract_State_Row : constant Abstract_State_Row_Id := 0;

   type Abstract_State_Context_Kind is
     (Abstract_State_Declaration,
      Abstract_State_Refined_State_Aspect,
      Abstract_State_Constituent_Mapping,
      Abstract_State_Global_Use,
      Abstract_State_Depends_Source,
      Abstract_State_Depends_Target,
      Abstract_State_Cross_Unit_View,
      Abstract_State_Task_Protected_Shared_State,
      Abstract_State_Volatile_State,
      Abstract_State_Atomic_State,
      Abstract_State_Unknown);

   type Abstract_State_Status is
     (Abstract_State_Not_Checked,
      Abstract_State_Legal_Declaration_Accepted,
      Abstract_State_Legal_Refined_State_Accepted,
      Abstract_State_Legal_Constituent_Mapping_Accepted,
      Abstract_State_Legal_Global_Use_Accepted,
      Abstract_State_Legal_Depends_Source_Accepted,
      Abstract_State_Legal_Depends_Target_Accepted,
      Abstract_State_Legal_Cross_Unit_View_Accepted,
      Abstract_State_Legal_Task_Protected_Shared_State_Accepted,
      Abstract_State_Legal_Volatile_State_Accepted,
      Abstract_State_Legal_Atomic_State_Accepted,
      Abstract_State_Missing_Abstract_State_Declaration,
      Abstract_State_Duplicate_Abstract_State,
      Abstract_State_Missing_Refined_State_Aspect,
      Abstract_State_Missing_Constituent,
      Abstract_State_Extra_Constituent,
      Abstract_State_Constituent_Mode_Mismatch,
      Abstract_State_Constituent_Not_Visible,
      Abstract_State_Abstract_Global_Mode_Mismatch,
      Abstract_State_Abstract_Depends_Missing_Edge,
      Abstract_State_Abstract_Depends_Extra_Edge,
      Abstract_State_Refinement_Cycle,
      Abstract_State_Refinement_Overflow,
      Abstract_State_Missing_Flow_Proof_Row,
      Abstract_State_Flow_Proof_Blocker,
      Abstract_State_Missing_Tasking_Row,
      Abstract_State_Tasking_Blocker,
      Abstract_State_Missing_Stabilized_Closure_Row,
      Abstract_State_Stabilized_Closure_Blocker,
      Abstract_State_Volatile_Effect_Blocker,
      Abstract_State_Atomic_Effect_Blocker,
      Abstract_State_Source_Fingerprint_Mismatch,
      Abstract_State_Multiple_Blockers,
      Abstract_State_Indeterminate);

   type Abstract_State_Context_Info is record
      Id                         : Abstract_State_Row_Id := No_Abstract_State_Row;
      Kind                       : Abstract_State_Context_Kind := Abstract_State_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Constituent_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Constituent_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Flow_Proof_Row             : Flow_Proof.Flow_Contract_Proof_Row_Id := Flow_Proof.No_Flow_Contract_Proof_Row;
      Flow_Proof_Status          : Flow_Proof.Flow_Contract_Proof_Status := Flow_Proof.Flow_Contract_Proof_Not_Checked;
      Tasking_Row                : Tasking_Deep.Deep_Tasking_Row_Id := Tasking_Deep.No_Deep_Tasking_Row;
      Tasking_Status             : Tasking_Deep.Deep_Tasking_Status := Tasking_Deep.Deep_Tasking_Not_Checked;
      Stabilized_Row             : Stabilized.Final_Stabilized_Closure_Id := Stabilized.No_Final_Stabilized_Closure;
      Stabilized_Status          : Stabilized.Final_Stabilized_Closure_Status := Stabilized.Final_Stabilized_Closure_Not_Checked;
      Requires_Flow_Proof        : Boolean := True;
      Requires_Tasking           : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Missing_Abstract_State     : Boolean := False;
      Duplicate_Abstract_State   : Boolean := False;
      Missing_Refined_State      : Boolean := False;
      Missing_Constituent        : Boolean := False;
      Extra_Constituent          : Boolean := False;
      Constituent_Mode_Mismatch  : Boolean := False;
      Constituent_Not_Visible    : Boolean := False;
      Abstract_Global_Mode_Mismatch : Boolean := False;
      Depends_Missing_Edge       : Boolean := False;
      Depends_Extra_Edge         : Boolean := False;
      Refinement_Cycle           : Boolean := False;
      Refinement_Overflow        : Boolean := False;
      Volatile_Effect_Error      : Boolean := False;
      Atomic_Effect_Error        : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Abstract_State_Info is record
      Id                         : Abstract_State_Row_Id := No_Abstract_State_Row;
      Context                    : Abstract_State_Row_Id := No_Abstract_State_Row;
      Kind                       : Abstract_State_Context_Kind := Abstract_State_Unknown;
      Status                     : Abstract_State_Status := Abstract_State_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Constituent_Name           : Ada.Strings.Unbounded.Unbounded_String;
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

   type Abstract_State_Context_Model is private;
   type Abstract_State_Model is private;
   type Abstract_State_Set is private;

   procedure Clear (Model : in out Abstract_State_Context_Model);
   procedure Add_Context (Model : in out Abstract_State_Context_Model; Info : Abstract_State_Context_Info);
   function Context_Count (Model : Abstract_State_Context_Model) return Natural;
   function Context_At (Model : Abstract_State_Context_Model; Index : Positive) return Abstract_State_Context_Info;
   function Fingerprint (Model : Abstract_State_Context_Model) return Natural;

   function Build (Contexts : Abstract_State_Context_Model) return Abstract_State_Model;
   function Row_Count (Model : Abstract_State_Model) return Natural;
   function Row_At (Model : Abstract_State_Model; Index : Positive) return Abstract_State_Info;
   function First_For_Node (Model : Abstract_State_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Abstract_State_Info;
   function Rows_For_Status (Model : Abstract_State_Model; Status : Abstract_State_Status) return Abstract_State_Set;
   function Rows_For_Kind (Model : Abstract_State_Model; Kind : Abstract_State_Context_Kind) return Abstract_State_Set;
   function Set_Count (Set : Abstract_State_Set) return Natural;
   function Set_At (Set : Abstract_State_Set; Index : Positive) return Abstract_State_Info;
   function Count_Status (Model : Abstract_State_Model; Status : Abstract_State_Status) return Natural;
   function Count_Kind (Model : Abstract_State_Model; Kind : Abstract_State_Context_Kind) return Natural;
   function Legal_Count (Model : Abstract_State_Model) return Natural;
   function Error_Count (Model : Abstract_State_Model) return Natural;
   function Flow_Error_Count (Model : Abstract_State_Model) return Natural;
   function Tasking_Error_Count (Model : Abstract_State_Model) return Natural;
   function Closure_Error_Count (Model : Abstract_State_Model) return Natural;
   function Refinement_Error_Count (Model : Abstract_State_Model) return Natural;
   function State_Effect_Error_Count (Model : Abstract_State_Model) return Natural;
   function Indeterminate_Count (Model : Abstract_State_Model) return Natural;
   function Fingerprint (Model : Abstract_State_Model) return Natural;

   function Is_Legal (Status : Abstract_State_Status) return Boolean;
   function Is_Flow_Error (Status : Abstract_State_Status) return Boolean;
   function Is_Tasking_Error (Status : Abstract_State_Status) return Boolean;
   function Is_Closure_Error (Status : Abstract_State_Status) return Boolean;
   function Is_Refinement_Error (Status : Abstract_State_Status) return Boolean;
   function Is_State_Effect_Error (Status : Abstract_State_Status) return Boolean;
   function Is_Indeterminate (Status : Abstract_State_Status) return Boolean;
   function Has_Error (Info : Abstract_State_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors (Positive, Abstract_State_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors (Positive, Abstract_State_Info);

   type Abstract_State_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Abstract_State_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Abstract_State_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Flow_Error_Total : Natural := 0;
      Tasking_Error_Total : Natural := 0;
      Closure_Error_Total : Natural := 0;
      Refinement_Error_Total : Natural := 0;
      State_Effect_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Abstract_State_Refined_State_Legality;
