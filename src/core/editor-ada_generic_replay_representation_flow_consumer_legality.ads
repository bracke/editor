with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality is

   --  Case 1160 compiler-grade generic replay representation-flow consumer legality.
   --
   --  This layer feeds representation/freezing tasking/elaboration/contract-flow
   --  evidence back into generic instance body semantic replay.  Instantiated
   --  generic body declarations, statements, nested instances, representation
   --  clauses, operational attributes, stream attributes, and record-layout replay
   --  rows cannot remain confidently legal when the representation/freezing facts
   --  they replay are missing, blocked, or indeterminate.

   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   package Rep_Flow renames Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality;

   type Generic_Replay_Representation_Row_Id is new Natural;
   No_Generic_Replay_Representation_Row : constant Generic_Replay_Representation_Row_Id := 0;

   type Generic_Replay_Representation_Context_Kind is
     (Generic_Replay_Representation_Formal_Substitution,
      Generic_Replay_Representation_Body_Declaration,
      Generic_Replay_Representation_Body_Statement,
      Generic_Replay_Representation_Body_Expression,
      Generic_Replay_Representation_Generic_Instance,
      Generic_Replay_Representation_Nested_Generic_Instance,
      Generic_Replay_Representation_Freezing_Effect,
      Generic_Replay_Representation_Representation_Clause,
      Generic_Replay_Representation_Operational_Attribute,
      Generic_Replay_Representation_Stream_Attribute,
      Generic_Replay_Representation_Record_Layout,
      Generic_Replay_Representation_Private_Full_View,
      Generic_Replay_Representation_Tasking_Effect,
      Generic_Replay_Representation_Unknown);

   type Generic_Replay_Representation_Status is
     (Generic_Replay_Representation_Not_Checked,
      Generic_Replay_Representation_Legal_Formal_Substitution_Accepted,
      Generic_Replay_Representation_Legal_Body_Declaration_Accepted,
      Generic_Replay_Representation_Legal_Body_Statement_Accepted,
      Generic_Replay_Representation_Legal_Body_Expression_Accepted,
      Generic_Replay_Representation_Legal_Generic_Instance_Accepted,
      Generic_Replay_Representation_Legal_Nested_Generic_Instance_Accepted,
      Generic_Replay_Representation_Legal_Freezing_Effect_Accepted,
      Generic_Replay_Representation_Legal_Representation_Clause_Accepted,
      Generic_Replay_Representation_Legal_Operational_Attribute_Accepted,
      Generic_Replay_Representation_Legal_Stream_Attribute_Accepted,
      Generic_Replay_Representation_Legal_Record_Layout_Accepted,
      Generic_Replay_Representation_Legal_Private_Full_View_Accepted,
      Generic_Replay_Representation_Legal_Tasking_Effect_Accepted,
      Generic_Replay_Representation_Base_Replay_Error,
      Generic_Replay_Representation_Replay_Mapping_Error,
      Generic_Replay_Representation_Replay_Expansion_Error,
      Generic_Replay_Representation_Replay_Overload_Error,
      Generic_Replay_Representation_Replay_Flow_Error,
      Generic_Replay_Representation_Replay_Predicate_Error,
      Generic_Replay_Representation_Replay_Accessibility_Error,
      Generic_Replay_Representation_Replay_Representation_Error,
      Generic_Replay_Representation_Replay_Coverage_Gate_Blocker,
      Generic_Replay_Representation_Missing_Representation_Flow_Row,
      Generic_Replay_Representation_Base_Representation_Flow_Error,
      Generic_Replay_Representation_Base_Freezing_Error,
      Generic_Replay_Representation_Refined_Global_Missing_Read,
      Generic_Replay_Representation_Refined_Global_Missing_Write,
      Generic_Replay_Representation_Refined_Global_Mode_Mismatch,
      Generic_Replay_Representation_Refined_Global_Extra_Item,
      Generic_Replay_Representation_Refined_Depends_Missing_Edge,
      Generic_Replay_Representation_Refined_Depends_Extra_Edge,
      Generic_Replay_Representation_Refined_Depends_Source_Mode_Error,
      Generic_Replay_Representation_Refined_Depends_Target_Mode_Error,
      Generic_Replay_Representation_Call_Effect_Not_Propagated,
      Generic_Replay_Representation_Coverage_Feedback_Blocker,
      Generic_Replay_Representation_Linked_Flow_Graph_Error,
      Generic_Replay_Representation_Base_Contract_Flow_Error,
      Generic_Replay_Representation_Base_Elaboration_Error,
      Generic_Replay_Representation_Base_Tasking_Effect_Error,
      Generic_Replay_Representation_Multiple_Representation_Flow_Blockers,
      Generic_Replay_Representation_Representation_Flow_Indeterminate,
      Generic_Replay_Representation_Indeterminate);

   type Generic_Replay_Representation_Context_Info is record
      Id                       : Generic_Replay_Representation_Row_Id := No_Generic_Replay_Representation_Row;
      Kind                     : Generic_Replay_Representation_Context_Kind := Generic_Replay_Representation_Unknown;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Source_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Replay_Row               : Replay.Replay_Row_Id := Replay.No_Replay_Row;
      Replay_Status            : Replay.Replay_Status := Replay.Replay_Not_Checked;
      Representation_Flow_Row  : Rep_Flow.Representation_Tasking_Row_Id := Rep_Flow.No_Representation_Tasking_Row;
      Representation_Flow_Status : Rep_Flow.Representation_Tasking_Status := Rep_Flow.Representation_Tasking_Not_Checked;
      Representation_Flow_Matches : Natural := 0;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Generic_Start_Line       : Positive := 1;
      Generic_Start_Column     : Positive := 1;
      Instance_Start_Line      : Positive := 1;
      Instance_Start_Column    : Positive := 1;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
   end record;

   type Generic_Replay_Representation_Info is record
      Id                       : Generic_Replay_Representation_Row_Id := No_Generic_Replay_Representation_Row;
      Context                  : Generic_Replay_Representation_Row_Id := No_Generic_Replay_Representation_Row;
      Kind                     : Generic_Replay_Representation_Context_Kind := Generic_Replay_Representation_Unknown;
      Status                   : Generic_Replay_Representation_Status := Generic_Replay_Representation_Not_Checked;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Source_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
      Detail                   : Ada.Strings.Unbounded.Unbounded_String;
      Replay_Row               : Replay.Replay_Row_Id := Replay.No_Replay_Row;
      Replay_Status            : Replay.Replay_Status := Replay.Replay_Not_Checked;
      Representation_Flow_Row  : Rep_Flow.Representation_Tasking_Row_Id := Rep_Flow.No_Representation_Tasking_Row;
      Representation_Flow_Status : Rep_Flow.Representation_Tasking_Status := Rep_Flow.Representation_Tasking_Not_Checked;
      Representation_Flow_Matches : Natural := 0;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Generic_Start_Line       : Positive := 1;
      Generic_Start_Column     : Positive := 1;
      Instance_Start_Line      : Positive := 1;
      Instance_Start_Column    : Positive := 1;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Fingerprint              : Natural := 0;
   end record;

   type Generic_Replay_Representation_Context_Model is private;
   type Generic_Replay_Representation_Set is private;
   type Generic_Replay_Representation_Model is private;

   procedure Clear (Model : in out Generic_Replay_Representation_Context_Model);
   procedure Add_Context
     (Model : in out Generic_Replay_Representation_Context_Model;
      Info  : Generic_Replay_Representation_Context_Info);

   function Context_Count (Model : Generic_Replay_Representation_Context_Model) return Natural;
   function Context_At
     (Model : Generic_Replay_Representation_Context_Model;
      Index : Positive) return Generic_Replay_Representation_Context_Info;
   function Fingerprint (Model : Generic_Replay_Representation_Context_Model) return Natural;

   function Build
     (Contexts : Generic_Replay_Representation_Context_Model) return Generic_Replay_Representation_Model;

   function Row_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Row_At
     (Model : Generic_Replay_Representation_Model;
      Index : Positive) return Generic_Replay_Representation_Info;
   function First_For_Node
     (Model : Generic_Replay_Representation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Replay_Representation_Info;
   function Rows_For_Status
     (Model  : Generic_Replay_Representation_Model;
      Status : Generic_Replay_Representation_Status) return Generic_Replay_Representation_Set;
   function Rows_For_Kind
     (Model : Generic_Replay_Representation_Model;
      Kind  : Generic_Replay_Representation_Context_Kind) return Generic_Replay_Representation_Set;
   function Rows_For_Instance
     (Model : Generic_Replay_Representation_Model;
      Name  : String) return Generic_Replay_Representation_Set;

   function Set_Count (Set : Generic_Replay_Representation_Set) return Natural;
   function Set_At
     (Set   : Generic_Replay_Representation_Set;
      Index : Positive) return Generic_Replay_Representation_Info;

   function Count_Status
     (Model  : Generic_Replay_Representation_Model;
      Status : Generic_Replay_Representation_Status) return Natural;
   function Count_Kind
     (Model : Generic_Replay_Representation_Model;
      Kind  : Generic_Replay_Representation_Context_Kind) return Natural;

   function Legal_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Error_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Replay_Error_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Representation_Error_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Global_Error_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Depends_Error_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Propagation_Error_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Coverage_Error_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Elaboration_Error_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Tasking_Error_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Replay_Representation_Model) return Natural;
   function Fingerprint (Model : Generic_Replay_Representation_Model) return Natural;

   function Is_Legal (Status : Generic_Replay_Representation_Status) return Boolean;
   function Is_Global_Error (Status : Generic_Replay_Representation_Status) return Boolean;
   function Is_Depends_Error (Status : Generic_Replay_Representation_Status) return Boolean;
   function Is_Propagation_Error (Status : Generic_Replay_Representation_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Generic_Replay_Representation_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Generic_Replay_Representation_Info);

   type Generic_Replay_Representation_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Generic_Replay_Representation_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Generic_Replay_Representation_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Replay_Error_Total : Natural := 0;
      Representation_Error_Total : Natural := 0;
      Global_Error_Total : Natural := 0;
      Depends_Error_Total : Natural := 0;
      Propagation_Error_Total : Natural := 0;
      Coverage_Error_Total : Natural := 0;
      Elaboration_Error_Total : Natural := 0;
      Tasking_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality;
