with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality;

package Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality is

   --  Case 1159 compiler-grade representation/freezing consumer legality.
   --
   --  This layer connects tasking/protected elaboration contract-flow evidence
   --  into representation/freezing exact propagation.  Representation clauses,
   --  operational attributes, stream attributes, record layouts, generic-instance
   --  representation effects, private/full-view representation timing, and
   --  finalization/abortable tasking effects cannot remain confidently legal when
   --  task activation, protected operation, accept/requeue/select, or abortable
   --  elaboration contract-flow facts are missing, blocked, or indeterminate.

   package Freezing renames Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
   package Tasking_Flow renames Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality;

   type Representation_Tasking_Row_Id is new Natural;
   No_Representation_Tasking_Row : constant Representation_Tasking_Row_Id := 0;

   type Representation_Tasking_Context_Kind is
     (Representation_Tasking_Representation_Clause,
      Representation_Tasking_Operational_Attribute,
      Representation_Tasking_Stream_Attribute,
      Representation_Tasking_Record_Layout,
      Representation_Tasking_Generic_Instance_Effect,
      Representation_Tasking_Private_Full_View,
      Representation_Tasking_Task_Activation_Effect,
      Representation_Tasking_Task_Termination_Effect,
      Representation_Tasking_Protected_Read_Effect,
      Representation_Tasking_Protected_Write_Effect,
      Representation_Tasking_Protected_Call_Effect,
      Representation_Tasking_Entry_Barrier_Effect,
      Representation_Tasking_Accept_Body_Effect,
      Representation_Tasking_Requeue_Effect,
      Representation_Tasking_Select_Effect,
      Representation_Tasking_Abortable_Finalization_Effect,
      Representation_Tasking_Unknown);

   type Representation_Tasking_Status is
     (Representation_Tasking_Not_Checked,
      Representation_Tasking_Legal_Representation_Clause_Accepted,
      Representation_Tasking_Legal_Operational_Attribute_Accepted,
      Representation_Tasking_Legal_Stream_Attribute_Accepted,
      Representation_Tasking_Legal_Record_Layout_Accepted,
      Representation_Tasking_Legal_Generic_Instance_Effect_Accepted,
      Representation_Tasking_Legal_Private_Full_View_Accepted,
      Representation_Tasking_Legal_Task_Activation_Effect_Accepted,
      Representation_Tasking_Legal_Task_Termination_Effect_Accepted,
      Representation_Tasking_Legal_Protected_Read_Effect_Accepted,
      Representation_Tasking_Legal_Protected_Write_Effect_Accepted,
      Representation_Tasking_Legal_Protected_Call_Effect_Accepted,
      Representation_Tasking_Legal_Entry_Barrier_Effect_Accepted,
      Representation_Tasking_Legal_Accept_Body_Effect_Accepted,
      Representation_Tasking_Legal_Requeue_Effect_Accepted,
      Representation_Tasking_Legal_Select_Effect_Accepted,
      Representation_Tasking_Legal_Abortable_Finalization_Effect_Accepted,
      Representation_Tasking_Base_Freezing_Error,
      Representation_Tasking_Missing_Tasking_Flow_Row,
      Representation_Tasking_Refined_Global_Missing_Read,
      Representation_Tasking_Refined_Global_Missing_Write,
      Representation_Tasking_Refined_Global_Mode_Mismatch,
      Representation_Tasking_Refined_Global_Extra_Item,
      Representation_Tasking_Refined_Depends_Missing_Edge,
      Representation_Tasking_Refined_Depends_Extra_Edge,
      Representation_Tasking_Refined_Depends_Source_Mode_Error,
      Representation_Tasking_Refined_Depends_Target_Mode_Error,
      Representation_Tasking_Call_Effect_Not_Propagated,
      Representation_Tasking_Coverage_Feedback_Blocker,
      Representation_Tasking_Linked_Flow_Graph_Error,
      Representation_Tasking_Base_Contract_Flow_Error,
      Representation_Tasking_Base_Elaboration_Error,
      Representation_Tasking_Base_Tasking_Effect_Error,
      Representation_Tasking_Multiple_Tasking_Flow_Blockers,
      Representation_Tasking_Tasking_Flow_Indeterminate,
      Representation_Tasking_Indeterminate);

   type Representation_Tasking_Context_Info is record
      Id                    : Representation_Tasking_Row_Id := No_Representation_Tasking_Row;
      Kind                  : Representation_Tasking_Context_Kind := Representation_Tasking_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Select_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Freezing_Row          : Freezing.Freezing_Propagation_Id := Freezing.No_Freezing_Propagation;
      Freezing_Status       : Freezing.Freezing_Propagation_Status := Freezing.Freezing_Propagation_Not_Checked;
      Tasking_Flow_Row      : Tasking_Flow.Tasking_Elab_Contract_Row_Id := Tasking_Flow.No_Tasking_Elab_Contract_Row;
      Tasking_Flow_Status   : Tasking_Flow.Tasking_Elab_Contract_Status := Tasking_Flow.Tasking_Elab_Contract_Not_Checked;
      Tasking_Flow_Matches  : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Representation_Tasking_Info is record
      Id                    : Representation_Tasking_Row_Id := No_Representation_Tasking_Row;
      Context               : Representation_Tasking_Row_Id := No_Representation_Tasking_Row;
      Kind                  : Representation_Tasking_Context_Kind := Representation_Tasking_Unknown;
      Status                : Representation_Tasking_Status := Representation_Tasking_Not_Checked;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Select_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Freezing_Row          : Freezing.Freezing_Propagation_Id := Freezing.No_Freezing_Propagation;
      Freezing_Status       : Freezing.Freezing_Propagation_Status := Freezing.Freezing_Propagation_Not_Checked;
      Tasking_Flow_Row      : Tasking_Flow.Tasking_Elab_Contract_Row_Id := Tasking_Flow.No_Tasking_Elab_Contract_Row;
      Tasking_Flow_Status   : Tasking_Flow.Tasking_Elab_Contract_Status := Tasking_Flow.Tasking_Elab_Contract_Not_Checked;
      Tasking_Flow_Matches  : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Representation_Tasking_Context_Model is private;
   type Representation_Tasking_Set is private;
   type Representation_Tasking_Model is private;

   procedure Clear (Model : in out Representation_Tasking_Context_Model);
   procedure Add_Context
     (Model : in out Representation_Tasking_Context_Model;
      Info  : Representation_Tasking_Context_Info);

   function Context_Count (Model : Representation_Tasking_Context_Model) return Natural;
   function Context_At
     (Model : Representation_Tasking_Context_Model;
      Index : Positive) return Representation_Tasking_Context_Info;
   function Fingerprint (Model : Representation_Tasking_Context_Model) return Natural;

   function Build
     (Contexts : Representation_Tasking_Context_Model) return Representation_Tasking_Model;

   function Row_Count (Model : Representation_Tasking_Model) return Natural;
   function Row_At
     (Model : Representation_Tasking_Model;
      Index : Positive) return Representation_Tasking_Info;
   function First_For_Node
     (Model : Representation_Tasking_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Tasking_Info;
   function Rows_For_Status
     (Model  : Representation_Tasking_Model;
      Status : Representation_Tasking_Status) return Representation_Tasking_Set;
   function Rows_For_Kind
     (Model : Representation_Tasking_Model;
      Kind  : Representation_Tasking_Context_Kind) return Representation_Tasking_Set;

   function Set_Count (Set : Representation_Tasking_Set) return Natural;
   function Set_At
     (Set   : Representation_Tasking_Set;
      Index : Positive) return Representation_Tasking_Info;

   function Count_Status
     (Model  : Representation_Tasking_Model;
      Status : Representation_Tasking_Status) return Natural;
   function Count_Kind
     (Model : Representation_Tasking_Model;
      Kind  : Representation_Tasking_Context_Kind) return Natural;

   function Legal_Count (Model : Representation_Tasking_Model) return Natural;
   function Error_Count (Model : Representation_Tasking_Model) return Natural;
   function Freezing_Error_Count (Model : Representation_Tasking_Model) return Natural;
   function Global_Error_Count (Model : Representation_Tasking_Model) return Natural;
   function Depends_Error_Count (Model : Representation_Tasking_Model) return Natural;
   function Propagation_Error_Count (Model : Representation_Tasking_Model) return Natural;
   function Coverage_Error_Count (Model : Representation_Tasking_Model) return Natural;
   function Elaboration_Error_Count (Model : Representation_Tasking_Model) return Natural;
   function Tasking_Error_Count (Model : Representation_Tasking_Model) return Natural;
   function Indeterminate_Count (Model : Representation_Tasking_Model) return Natural;
   function Fingerprint (Model : Representation_Tasking_Model) return Natural;

   function Is_Legal (Status : Representation_Tasking_Status) return Boolean;
   function Is_Global_Error (Status : Representation_Tasking_Status) return Boolean;
   function Is_Depends_Error (Status : Representation_Tasking_Status) return Boolean;
   function Is_Propagation_Error (Status : Representation_Tasking_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Representation_Tasking_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Representation_Tasking_Info);

   type Representation_Tasking_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Representation_Tasking_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Representation_Tasking_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Freezing_Error_Total : Natural := 0;
      Global_Error_Total : Natural := 0;
      Depends_Error_Total : Natural := 0;
      Propagation_Error_Total : Natural := 0;
      Coverage_Error_Total : Natural := 0;
      Elaboration_Error_Total : Natural := 0;
      Tasking_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality;
