with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality is

   --  Pass1165 compiler-grade dataflow definite-initialization consumer
   --  legality.
   --
   --  This layer feeds Pass1164 exact initialization/object-flow evidence back
   --  into Global/Depends and flow-effect consumers.  It prevents Global,
   --  Depends, Refined_Global, Refined_Depends, call-propagation, generic,
   --  protected, and tasking flow conclusions from remaining confident when
   --  the object read/write they depend on is not definitely initialized, is
   --  only conditionally initialized, is used after finalization, or is blocked
   --  by exact lifetime, discriminant, representation, or repaired-coverage
   --  evidence.

   package Dataflow renames Editor.Ada_Dataflow_Global_Depends_Legality;
   package Flow renames Editor.Ada_Flow_Effect_Graph_Legality;
   package Init_Obj renames Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;

   type Dataflow_Init_Row_Id is new Natural;
   No_Dataflow_Init_Row : constant Dataflow_Init_Row_Id := 0;

   type Dataflow_Init_Status is
     (Dataflow_Init_Not_Checked,
      Dataflow_Init_Legal_Read_Accepted,
      Dataflow_Init_Legal_Write_Accepted,
      Dataflow_Init_Legal_Read_Write_Accepted,
      Dataflow_Init_Legal_Null_Effect_Accepted,
      Dataflow_Init_Legal_Depends_Edge_Accepted,
      Dataflow_Init_Legal_Refinement_Accepted,
      Dataflow_Init_Legal_Call_Propagation_Accepted,
      Dataflow_Init_Legal_Generic_Effect_Accepted,
      Dataflow_Init_Legal_Task_Protected_Effect_Accepted,
      Dataflow_Init_Base_Dataflow_Error,
      Dataflow_Init_Missing_Flow_Edge_Row,
      Dataflow_Init_Flow_Global_Blocker,
      Dataflow_Init_Flow_Depends_Blocker,
      Dataflow_Init_Flow_Propagation_Blocker,
      Dataflow_Init_Flow_Generic_Blocker,
      Dataflow_Init_Flow_Tasking_Protected_Blocker,
      Dataflow_Init_Flow_Coverage_Blocker,
      Dataflow_Init_Flow_Linked_Dataflow_Blocker,
      Dataflow_Init_Missing_Initialization_Object_Flow_Row,
      Dataflow_Init_Mismatched_Initialization_Object,
      Dataflow_Init_Read_Before_Write_Blocker,
      Dataflow_Init_Component_Read_Before_Write_Blocker,
      Dataflow_Init_Partial_Component_Init_Blocker,
      Dataflow_Init_Out_Parameter_Not_Assigned_Blocker,
      Dataflow_Init_In_Out_Conditional_Assignment_Blocker,
      Dataflow_Init_Return_Object_Not_Initialized_Blocker,
      Dataflow_Init_Branch_Loop_Merge_Blocker,
      Dataflow_Init_Exception_Path_Loss_Blocker,
      Dataflow_Init_Finalization_Uses_Uninitialized_Blocker,
      Dataflow_Init_Use_After_Finalization_Blocker,
      Dataflow_Init_Lifetime_Blocker,
      Dataflow_Init_Discriminant_Representation_Blocker,
      Dataflow_Init_Coverage_Blocker,
      Dataflow_Init_Linked_Initialization_Blocker,
      Dataflow_Init_Multiple_Blockers,
      Dataflow_Init_Indeterminate);

   type Dataflow_Init_Context_Info is record
      Id                         : Dataflow_Init_Row_Id := No_Dataflow_Init_Row;
      Kind                       : Dataflow.Dataflow_Context_Kind := Dataflow.Dataflow_Context_Unknown;
      Effect                     : Dataflow.Dataflow_Effect_Kind := Dataflow.Dataflow_Effect_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Dataflow_Row               : Dataflow.Dataflow_Legality_Id := Dataflow.No_Dataflow_Legality;
      Dataflow_Status            : Dataflow.Dataflow_Legality_Status := Dataflow.Dataflow_Legality_Not_Checked;
      Flow_Edge_Row              : Flow.Flow_Edge_Id := Flow.No_Flow_Edge;
      Flow_Status                : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Flow_Edge                  : Flow.Flow_Edge_Kind := Flow.Flow_Edge_Unknown;
      Flow_Matches               : Natural := 0;
      Initialization_Row         : Init_Obj.Initialization_Object_Flow_Row_Id := Init_Obj.No_Initialization_Object_Flow_Row;
      Initialization_Status      : Init_Obj.Initialization_Object_Flow_Status := Init_Obj.Initialization_Object_Flow_Not_Checked;
      Initialization_Matches     : Natural := 0;
      Reads_Object               : Boolean := False;
      Writes_Object              : Boolean := False;
      Propagates_Call            : Boolean := False;
      Generic_Effect             : Boolean := False;
      Tasking_Protected_Effect   : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Dataflow_Fingerprint       : Natural := 0;
      Flow_Fingerprint           : Natural := 0;
      Initialization_Fingerprint : Natural := 0;
   end record;

   type Dataflow_Init_Info is record
      Id                         : Dataflow_Init_Row_Id := No_Dataflow_Init_Row;
      Context                    : Dataflow_Init_Row_Id := No_Dataflow_Init_Row;
      Kind                       : Dataflow.Dataflow_Context_Kind := Dataflow.Dataflow_Context_Unknown;
      Effect                     : Dataflow.Dataflow_Effect_Kind := Dataflow.Dataflow_Effect_Unknown;
      Status                     : Dataflow_Init_Status := Dataflow_Init_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Dataflow_Row               : Dataflow.Dataflow_Legality_Id := Dataflow.No_Dataflow_Legality;
      Dataflow_Status            : Dataflow.Dataflow_Legality_Status := Dataflow.Dataflow_Legality_Not_Checked;
      Flow_Edge_Row              : Flow.Flow_Edge_Id := Flow.No_Flow_Edge;
      Flow_Status                : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Flow_Edge                  : Flow.Flow_Edge_Kind := Flow.Flow_Edge_Unknown;
      Flow_Matches               : Natural := 0;
      Initialization_Row         : Init_Obj.Initialization_Object_Flow_Row_Id := Init_Obj.No_Initialization_Object_Flow_Row;
      Initialization_Status      : Init_Obj.Initialization_Object_Flow_Status := Init_Obj.Initialization_Object_Flow_Not_Checked;
      Initialization_Matches     : Natural := 0;
      Reads_Object               : Boolean := False;
      Writes_Object              : Boolean := False;
      Propagates_Call            : Boolean := False;
      Generic_Effect             : Boolean := False;
      Tasking_Protected_Effect   : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Dataflow_Fingerprint       : Natural := 0;
      Flow_Fingerprint           : Natural := 0;
      Initialization_Fingerprint : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Dataflow_Init_Context_Model is private;
   type Dataflow_Init_Set is private;
   type Dataflow_Init_Model is private;

   procedure Clear (Model : in out Dataflow_Init_Context_Model);
   procedure Add_Context
     (Model : in out Dataflow_Init_Context_Model;
      Info  : Dataflow_Init_Context_Info);

   function Context_Count (Model : Dataflow_Init_Context_Model) return Natural;
   function Context_At
     (Model : Dataflow_Init_Context_Model;
      Index : Positive) return Dataflow_Init_Context_Info;
   function Fingerprint (Model : Dataflow_Init_Context_Model) return Natural;

   function Build (Contexts : Dataflow_Init_Context_Model) return Dataflow_Init_Model;

   function Row_Count (Model : Dataflow_Init_Model) return Natural;
   function Row_At
     (Model : Dataflow_Init_Model;
      Index : Positive) return Dataflow_Init_Info;
   function First_For_Node
     (Model : Dataflow_Init_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dataflow_Init_Info;
   function Rows_For_Status
     (Model  : Dataflow_Init_Model;
      Status : Dataflow_Init_Status) return Dataflow_Init_Set;
   function Rows_For_Kind
     (Model : Dataflow_Init_Model;
      Kind  : Dataflow.Dataflow_Context_Kind) return Dataflow_Init_Set;
   function Rows_For_Object
     (Model : Dataflow_Init_Model;
      Name  : String) return Dataflow_Init_Set;

   function Set_Count (Results : Dataflow_Init_Set) return Natural;
   function Set_At
     (Results : Dataflow_Init_Set;
      Index   : Positive) return Dataflow_Init_Info;

   function Count_Status
     (Model  : Dataflow_Init_Model;
      Status : Dataflow_Init_Status) return Natural;
   function Count_Kind
     (Model : Dataflow_Init_Model;
      Kind  : Dataflow.Dataflow_Context_Kind) return Natural;

   function Legal_Count (Model : Dataflow_Init_Model) return Natural;
   function Error_Count (Model : Dataflow_Init_Model) return Natural;
   function Flow_Error_Count (Model : Dataflow_Init_Model) return Natural;
   function Initialization_Error_Count (Model : Dataflow_Init_Model) return Natural;
   function Lifetime_Error_Count (Model : Dataflow_Init_Model) return Natural;
   function Representation_Error_Count (Model : Dataflow_Init_Model) return Natural;
   function Coverage_Error_Count (Model : Dataflow_Init_Model) return Natural;
   function Indeterminate_Count (Model : Dataflow_Init_Model) return Natural;
   function Fingerprint (Model : Dataflow_Init_Model) return Natural;

   function Is_Legal (Status : Dataflow_Init_Status) return Boolean;
   function Is_Error (Status : Dataflow_Init_Status) return Boolean;
   function Is_Flow_Error (Status : Dataflow_Init_Status) return Boolean;
   function Is_Initialization_Error (Status : Dataflow_Init_Status) return Boolean;
   function Is_Lifetime_Error (Status : Dataflow_Init_Status) return Boolean;
   function Is_Representation_Error (Status : Dataflow_Init_Status) return Boolean;
   function Is_Coverage_Error (Status : Dataflow_Init_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Dataflow_Init_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Dataflow_Init_Info);

   type Dataflow_Init_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Dataflow_Init_Set is record
      Items : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Dataflow_Init_Model is record
      Rows : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
