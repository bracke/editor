with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
with Editor.Ada_Flow_Refinement_Consumer_Legality;
with Editor.Ada_Refined_Global_Depends_Conformance_Legality;
with Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Flow_Contract_Final_Proof_Legality is

   --  Pass1192 compiler-grade flow/contract final proof legality.
   --
   --  This layer strengthens Global, Depends, Refined_Global and
   --  Refined_Depends proof obligations after the final consumer chain.  It
   --  preserves blockers for transitive Depends closure, dispatching-call Global
   --  refinement, abstract/refined state modelling, volatile and atomic effects,
   --  cross-unit closure, definite-initialization dataflow, representation and
   --  contract/predicate/dataflow consumers.  The package is deterministic,
   --  bounded, snapshot-owned, and performs no parsing, file IO, dirty-state
   --  mutation, command/keybinding/workspace/render mutation, compiler
   --  invocation, LSP use, or external parser generation.

   package Contract_CPD renames Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
   package Cross_Final renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
   package Dataflow_Init renames Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
   package Flow_Consumer renames Editor.Ada_Flow_Refinement_Consumer_Legality;
   package Refined renames Editor.Ada_Refined_Global_Depends_Conformance_Legality;
   package Rep_Final renames Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;

   type Flow_Contract_Proof_Row_Id is new Natural;
   No_Flow_Contract_Proof_Row : constant Flow_Contract_Proof_Row_Id := 0;

   type Flow_Contract_Proof_Context_Kind is
     (Flow_Contract_Global_Aspect,
      Flow_Contract_Depends_Aspect,
      Flow_Contract_Refined_Global,
      Flow_Contract_Refined_Depends,
      Flow_Contract_Transitive_Depends_Closure,
      Flow_Contract_Dispatching_Global_Refinement,
      Flow_Contract_Abstract_State,
      Flow_Contract_Refined_State,
      Flow_Contract_Volatile_Object_Effect,
      Flow_Contract_Atomic_Object_Effect,
      Flow_Contract_Independent_Component_Effect,
      Flow_Contract_Call_Chain_Propagation,
      Flow_Contract_Generic_Effect_Substitution,
      Flow_Contract_Task_Protected_Shared_State,
      Flow_Contract_Unknown);

   type Flow_Contract_Proof_Status is
     (Flow_Contract_Proof_Not_Checked,
      Flow_Contract_Proof_Legal_Global_Accepted,
      Flow_Contract_Proof_Legal_Depends_Accepted,
      Flow_Contract_Proof_Legal_Refined_Global_Accepted,
      Flow_Contract_Proof_Legal_Refined_Depends_Accepted,
      Flow_Contract_Proof_Legal_Transitive_Depends_Accepted,
      Flow_Contract_Proof_Legal_Dispatching_Global_Accepted,
      Flow_Contract_Proof_Legal_Abstract_State_Accepted,
      Flow_Contract_Proof_Legal_Refined_State_Accepted,
      Flow_Contract_Proof_Legal_Volatile_Effect_Accepted,
      Flow_Contract_Proof_Legal_Atomic_Effect_Accepted,
      Flow_Contract_Proof_Legal_Independent_Component_Accepted,
      Flow_Contract_Proof_Legal_Call_Chain_Accepted,
      Flow_Contract_Proof_Legal_Generic_Effect_Accepted,
      Flow_Contract_Proof_Legal_Task_Protected_State_Accepted,
      Flow_Contract_Proof_Missing_Refined_Conformance_Row,
      Flow_Contract_Proof_Refined_Global_Blocker,
      Flow_Contract_Proof_Refined_Depends_Blocker,
      Flow_Contract_Proof_Missing_Flow_Consumer_Row,
      Flow_Contract_Proof_Flow_Global_Blocker,
      Flow_Contract_Proof_Flow_Depends_Blocker,
      Flow_Contract_Proof_Flow_Propagation_Blocker,
      Flow_Contract_Proof_Missing_Dataflow_Init_Row,
      Flow_Contract_Proof_Dataflow_Init_Blocker,
      Flow_Contract_Proof_Definite_Init_Blocker,
      Flow_Contract_Proof_Missing_Contract_CPD_Row,
      Flow_Contract_Proof_Contract_Predicate_Blocker,
      Flow_Contract_Proof_Contract_Dataflow_Blocker,
      Flow_Contract_Proof_Missing_Cross_Unit_Final_Row,
      Flow_Contract_Proof_Cross_Unit_Blocker,
      Flow_Contract_Proof_Missing_Representation_Final_Row,
      Flow_Contract_Proof_Representation_Final_Blocker,
      Flow_Contract_Proof_Transitive_Depends_Missing_Edge,
      Flow_Contract_Proof_Transitive_Depends_Cycle,
      Flow_Contract_Proof_Transitive_Depends_Overflow,
      Flow_Contract_Proof_Dispatching_Global_Not_Refined,
      Flow_Contract_Proof_Abstract_State_Missing,
      Flow_Contract_Proof_Abstract_State_Mode_Mismatch,
      Flow_Contract_Proof_Refined_State_Missing,
      Flow_Contract_Proof_Refined_State_Extra,
      Flow_Contract_Proof_Volatile_Read_Order_Blocker,
      Flow_Contract_Proof_Volatile_Write_Order_Blocker,
      Flow_Contract_Proof_Atomic_Read_Write_Blocker,
      Flow_Contract_Proof_Independent_Component_Blocker,
      Flow_Contract_Proof_Shared_State_Task_Blocker,
      Flow_Contract_Proof_Source_Fingerprint_Mismatch,
      Flow_Contract_Proof_Multiple_Blockers,
      Flow_Contract_Proof_Indeterminate);

   type Flow_Contract_Proof_Context_Info is record
      Id                         : Flow_Contract_Proof_Row_Id := No_Flow_Contract_Proof_Row;
      Kind                       : Flow_Contract_Proof_Context_Kind := Flow_Contract_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subprogram_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Refined_Status             : Refined.Refined_Conformance_Status := Refined.Refined_Conformance_Not_Checked;
      Flow_Status                : Flow_Consumer.Consumer_Status := Flow_Consumer.Consumer_Not_Checked;
      Dataflow_Init_Status       : Dataflow_Init.Dataflow_Init_Status := Dataflow_Init.Dataflow_Init_Not_Checked;
      Contract_CPD_Status        : Contract_CPD.Contract_Predicate_Status := Contract_CPD.Contract_Predicate_Not_Checked;
      Cross_Unit_Status          : Cross_Final.Cross_Unit_Final_Status := Cross_Final.Cross_Unit_Final_Not_Checked;
      Representation_Status      : Rep_Final.Final_Representation_Status := Rep_Final.Final_Representation_Not_Checked;
      Requires_Refined           : Boolean := False;
      Requires_Flow              : Boolean := False;
      Requires_Dataflow_Init     : Boolean := False;
      Requires_Contract_CPD      : Boolean := False;
      Requires_Cross_Unit        : Boolean := False;
      Requires_Representation    : Boolean := False;
      Transitive_Depends_Missing_Edge : Boolean := False;
      Transitive_Depends_Cycle   : Boolean := False;
      Transitive_Depends_Overflow : Boolean := False;
      Dispatching_Global_Not_Refined : Boolean := False;
      Abstract_State_Missing     : Boolean := False;
      Abstract_State_Mode_Mismatch : Boolean := False;
      Refined_State_Missing      : Boolean := False;
      Refined_State_Extra        : Boolean := False;
      Volatile_Read_Order_Error  : Boolean := False;
      Volatile_Write_Order_Error : Boolean := False;
      Atomic_Read_Write_Error    : Boolean := False;
      Independent_Component_Error : Boolean := False;
      Shared_State_Task_Error    : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Flow_Contract_Proof_Info is record
      Id                         : Flow_Contract_Proof_Row_Id := No_Flow_Contract_Proof_Row;
      Context                    : Flow_Contract_Proof_Row_Id := No_Flow_Contract_Proof_Row;
      Kind                       : Flow_Contract_Proof_Context_Kind := Flow_Contract_Unknown;
      Status                     : Flow_Contract_Proof_Status := Flow_Contract_Proof_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subprogram_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
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

   type Flow_Contract_Proof_Context_Model is private;
   type Flow_Contract_Proof_Set is private;
   type Flow_Contract_Proof_Model is private;

   procedure Clear (Model : in out Flow_Contract_Proof_Context_Model);
   procedure Add_Context (Model : in out Flow_Contract_Proof_Context_Model; Info : Flow_Contract_Proof_Context_Info);
   function Context_Count (Model : Flow_Contract_Proof_Context_Model) return Natural;
   function Context_At (Model : Flow_Contract_Proof_Context_Model; Index : Positive) return Flow_Contract_Proof_Context_Info;
   function Fingerprint (Model : Flow_Contract_Proof_Context_Model) return Natural;

   function Build (Contexts : Flow_Contract_Proof_Context_Model) return Flow_Contract_Proof_Model;
   function Row_Count (Model : Flow_Contract_Proof_Model) return Natural;
   function Row_At (Model : Flow_Contract_Proof_Model; Index : Positive) return Flow_Contract_Proof_Info;
   function First_For_Node (Model : Flow_Contract_Proof_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Flow_Contract_Proof_Info;
   function Rows_For_Status (Model : Flow_Contract_Proof_Model; Status : Flow_Contract_Proof_Status) return Flow_Contract_Proof_Set;
   function Rows_For_Kind (Model : Flow_Contract_Proof_Model; Kind : Flow_Contract_Proof_Context_Kind) return Flow_Contract_Proof_Set;
   function Set_Count (Set : Flow_Contract_Proof_Set) return Natural;
   function Set_At (Set : Flow_Contract_Proof_Set; Index : Positive) return Flow_Contract_Proof_Info;
   function Count_Status (Model : Flow_Contract_Proof_Model; Status : Flow_Contract_Proof_Status) return Natural;
   function Count_Kind (Model : Flow_Contract_Proof_Model; Kind : Flow_Contract_Proof_Context_Kind) return Natural;
   function Legal_Count (Model : Flow_Contract_Proof_Model) return Natural;
   function Error_Count (Model : Flow_Contract_Proof_Model) return Natural;
   function Refined_Error_Count (Model : Flow_Contract_Proof_Model) return Natural;
   function Flow_Error_Count (Model : Flow_Contract_Proof_Model) return Natural;
   function Dataflow_Error_Count (Model : Flow_Contract_Proof_Model) return Natural;
   function Contract_Error_Count (Model : Flow_Contract_Proof_Model) return Natural;
   function State_Effect_Error_Count (Model : Flow_Contract_Proof_Model) return Natural;
   function Indeterminate_Count (Model : Flow_Contract_Proof_Model) return Natural;
   function Fingerprint (Model : Flow_Contract_Proof_Model) return Natural;

   function Is_Legal (Status : Flow_Contract_Proof_Status) return Boolean;
   function Is_Refined_Error (Status : Flow_Contract_Proof_Status) return Boolean;
   function Is_Flow_Error (Status : Flow_Contract_Proof_Status) return Boolean;
   function Is_Dataflow_Error (Status : Flow_Contract_Proof_Status) return Boolean;
   function Is_Contract_Error (Status : Flow_Contract_Proof_Status) return Boolean;
   function Is_State_Effect_Error (Status : Flow_Contract_Proof_Status) return Boolean;
   function Is_Indeterminate (Status : Flow_Contract_Proof_Status) return Boolean;
   function Has_Error (Info : Flow_Contract_Proof_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors (Positive, Flow_Contract_Proof_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors (Positive, Flow_Contract_Proof_Info);

   type Flow_Contract_Proof_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Flow_Contract_Proof_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Flow_Contract_Proof_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Refined_Error_Total : Natural := 0;
      Flow_Error_Total : Natural := 0;
      Dataflow_Error_Total : Natural := 0;
      Contract_Error_Total : Natural := 0;
      State_Effect_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Flow_Contract_Final_Proof_Legality;
