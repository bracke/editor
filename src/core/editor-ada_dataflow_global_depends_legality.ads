with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Definite_Initialization_Flow_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Dataflow_Global_Depends_Legality is

   --  Case 1123 compiler-grade dataflow legality layer.  This package connects
   --  Global/Depends contract-aspect facts with flow-sensitive object-state
   --  facts from definite-initialization analysis.  It models read/write
   --  effects, parameter-mode effects, dependency edges, initialization-before-
   --  read requirements, and linked contract/initialization failures without
   --  parsing, file IO, dirty-state mutation, renderer/workspace mutation,
   --  compiler invocation, or unbounded analysis.

   subtype Contract_Legality_Status is
     Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Status;
   subtype Flow_Contract_State is
     Editor.Ada_Contract_Aspect_Legality.Flow_Contract_State;
   subtype Initialization_Legality_Status is
     Editor.Ada_Definite_Initialization_Flow_Legality.Initialization_Legality_Status;
   subtype Object_State is
     Editor.Ada_Definite_Initialization_Flow_Legality.Object_State;

   type Dataflow_Context_Id is new Natural;
   No_Dataflow_Context : constant Dataflow_Context_Id := 0;

   type Dataflow_Legality_Id is new Natural;
   No_Dataflow_Legality : constant Dataflow_Legality_Id := 0;

   type Dataflow_Context_Kind is
     (Dataflow_Context_Subprogram,
      Dataflow_Context_Entry,
      Dataflow_Context_Protected_Operation,
      Dataflow_Context_Task_Body,
      Dataflow_Context_Package_Elaboration,
      Dataflow_Context_Generic_Instance,
      Dataflow_Context_Contract_Aspect,
      Dataflow_Context_Statement,
      Dataflow_Context_Expression,
      Dataflow_Context_Unknown);

   type Dataflow_Effect_Kind is
     (Dataflow_Effect_Read,
      Dataflow_Effect_Write,
      Dataflow_Effect_Read_Write,
      Dataflow_Effect_Null,
      Dataflow_Effect_Depends_Edge,
      Dataflow_Effect_Refinement,
      Dataflow_Effect_Unknown);

   type Global_Mode is
     (Global_Mode_Not_Declared,
      Global_Mode_Null,
      Global_Mode_In,
      Global_Mode_Out,
      Global_Mode_In_Out,
      Global_Mode_Proof_In,
      Global_Mode_Unknown);

   type Dependency_State is
     (Dependency_State_Not_Applicable,
      Dependency_State_Resolved,
      Dependency_State_Output_Missing_Source,
      Dependency_State_Source_Not_Global_Input,
      Dependency_State_Target_Not_Global_Output,
      Dependency_State_Cycle,
      Dependency_State_Duplicate,
      Dependency_State_Unresolved);

   type Dataflow_Legality_Status is
     (Dataflow_Legality_Not_Checked,
      Dataflow_Legality_Legal_Read,
      Dataflow_Legality_Legal_Write,
      Dataflow_Legality_Legal_Read_Write,
      Dataflow_Legality_Legal_Null_Effect,
      Dataflow_Legality_Legal_Depends_Edge,
      Dataflow_Legality_Legal_Refinement,
      Dataflow_Legality_Read_Not_In_Global,
      Dataflow_Legality_Write_Not_In_Global,
      Dataflow_Legality_Write_To_In_Global,
      Dataflow_Legality_Read_From_Out_Global,
      Dataflow_Legality_Effect_Violates_Null_Global,
      Dataflow_Legality_Depends_Missing_Source,
      Dataflow_Legality_Depends_Source_Not_Input,
      Dataflow_Legality_Depends_Target_Not_Output,
      Dataflow_Legality_Depends_Cycle,
      Dataflow_Legality_Depends_Duplicate,
      Dataflow_Legality_Refined_Global_Missing_Item,
      Dataflow_Legality_Refined_Depends_Missing_Edge,
      Dataflow_Legality_Duplicate_Effect,
      Dataflow_Legality_Mode_Mismatch,
      Dataflow_Legality_Read_Before_Write,
      Dataflow_Legality_Out_Parameter_Not_Assigned,
      Dataflow_Legality_In_Out_Parameter_Conditionally_Assigned,
      Dataflow_Legality_Use_After_Finalization,
      Dataflow_Legality_Unresolved_Object,
      Dataflow_Legality_Linked_Contract_Error,
      Dataflow_Legality_Linked_Initialization_Error,
      Dataflow_Legality_Indeterminate);

   type Dataflow_Context_Info is record
      Id                       : Dataflow_Context_Id := No_Dataflow_Context;
      Kind                     : Dataflow_Context_Kind := Dataflow_Context_Unknown;
      Effect                   : Dataflow_Effect_Kind := Dataflow_Effect_Unknown;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Declared_Global_Mode     : Global_Mode := Global_Mode_Not_Declared;
      Source_Global_Mode       : Global_Mode := Global_Mode_Not_Declared;
      Target_Global_Mode       : Global_Mode := Global_Mode_Not_Declared;
      Dependency               : Dependency_State := Dependency_State_Not_Applicable;
      Reads_Object             : Boolean := False;
      Writes_Object            : Boolean := False;
      Duplicate_Effect         : Boolean := False;
      Missing_Refined_Global   : Boolean := False;
      Missing_Refined_Depends  : Boolean := False;
      Object_Resolved          : Boolean := True;
      Before_State             : Object_State := Editor.Ada_Definite_Initialization_Flow_Legality.Object_State_Unknown;
      After_State              : Object_State := Editor.Ada_Definite_Initialization_Flow_Legality.Object_State_Unknown;
      Contract_Status          : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Flow_State               : Flow_Contract_State :=
        Editor.Ada_Contract_Aspect_Legality.Flow_Contract_Not_Applicable;
      Initialization_Status    : Initialization_Legality_Status :=
        Editor.Ada_Definite_Initialization_Flow_Legality.Initialization_Legality_Not_Checked;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Source_Fingerprint       : Natural := 0;
   end record;

   type Dataflow_Legality_Info is record
      Id                       : Dataflow_Legality_Id := No_Dataflow_Legality;
      Context                  : Dataflow_Context_Id := No_Dataflow_Context;
      Kind                     : Dataflow_Context_Kind := Dataflow_Context_Unknown;
      Effect                   : Dataflow_Effect_Kind := Dataflow_Effect_Unknown;
      Status                   : Dataflow_Legality_Status := Dataflow_Legality_Not_Checked;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
      Detail                   : Ada.Strings.Unbounded.Unbounded_String;
      Declared_Global_Mode     : Global_Mode := Global_Mode_Not_Declared;
      Source_Global_Mode       : Global_Mode := Global_Mode_Not_Declared;
      Target_Global_Mode       : Global_Mode := Global_Mode_Not_Declared;
      Dependency               : Dependency_State := Dependency_State_Not_Applicable;
      Contract_Status          : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Flow_State               : Flow_Contract_State :=
        Editor.Ada_Contract_Aspect_Legality.Flow_Contract_Not_Applicable;
      Initialization_Status    : Initialization_Legality_Status :=
        Editor.Ada_Definite_Initialization_Flow_Legality.Initialization_Legality_Not_Checked;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Source_Fingerprint       : Natural := 0;
      Fingerprint              : Natural := 0;
   end record;

   type Dataflow_Context_Model is private;
   type Dataflow_Result_Set is private;
   type Dataflow_Legality_Model is private;

   procedure Clear (Model : in out Dataflow_Context_Model);
   procedure Add_Context
     (Model : in out Dataflow_Context_Model;
      Info  : Dataflow_Context_Info);
   function Context_Count (Model : Dataflow_Context_Model) return Natural;
   function Context_At
     (Model : Dataflow_Context_Model;
      Index : Positive) return Dataflow_Context_Info;
   function Fingerprint (Model : Dataflow_Context_Model) return Natural;

   function Build (Contexts : Dataflow_Context_Model) return Dataflow_Legality_Model;

   function Row_Count (Model : Dataflow_Legality_Model) return Natural;
   function Row_At
     (Model : Dataflow_Legality_Model;
      Index : Positive) return Dataflow_Legality_Info;
   function First_For_Node
     (Model : Dataflow_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dataflow_Legality_Info;
   function First_For_Object
     (Model : Dataflow_Legality_Model;
      Name  : String) return Dataflow_Legality_Info;
   function Rows_For_Status
     (Model  : Dataflow_Legality_Model;
      Status : Dataflow_Legality_Status) return Dataflow_Result_Set;
   function Rows_For_Kind
     (Model : Dataflow_Legality_Model;
      Kind  : Dataflow_Context_Kind) return Dataflow_Result_Set;
   function Rows_For_Effect
     (Model  : Dataflow_Legality_Model;
      Effect : Dataflow_Effect_Kind) return Dataflow_Result_Set;

   function Result_Count (Results : Dataflow_Result_Set) return Natural;
   function Result_At
     (Results : Dataflow_Result_Set;
      Index   : Positive) return Dataflow_Legality_Info;

   function Count_Status
     (Model  : Dataflow_Legality_Model;
      Status : Dataflow_Legality_Status) return Natural;
   function Count_Kind
     (Model : Dataflow_Legality_Model;
      Kind  : Dataflow_Context_Kind) return Natural;
   function Count_Effect
     (Model  : Dataflow_Legality_Model;
      Effect : Dataflow_Effect_Kind) return Natural;
   function Legal_Count (Model : Dataflow_Legality_Model) return Natural;
   function Error_Count (Model : Dataflow_Legality_Model) return Natural;
   function Global_Error_Count (Model : Dataflow_Legality_Model) return Natural;
   function Depends_Error_Count (Model : Dataflow_Legality_Model) return Natural;
   function Initialization_Error_Count (Model : Dataflow_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Dataflow_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Dataflow_Legality_Model) return Natural;
   function Fingerprint (Model : Dataflow_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Dataflow_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Dataflow_Legality_Info);

   type Dataflow_Context_Model is record
      Contexts    : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Dataflow_Result_Set is record
      Rows : Row_Vectors.Vector;
   end record;

   type Dataflow_Legality_Model is record
      Rows                       : Row_Vectors.Vector;
      Legal_Total                : Natural := 0;
      Error_Total                : Natural := 0;
      Global_Error_Total         : Natural := 0;
      Depends_Error_Total        : Natural := 0;
      Initialization_Error_Total : Natural := 0;
      Linked_Error_Total         : Natural := 0;
      Indeterminate_Total        : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

end Editor.Ada_Dataflow_Global_Depends_Legality;
