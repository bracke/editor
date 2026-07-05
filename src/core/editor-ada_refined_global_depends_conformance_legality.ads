with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Repaired_Coverage_Semantic_Feedback;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Refined_Global_Depends_Conformance_Legality is

   --  Case 1153 compiler-grade Refined_Global / Refined_Depends conformance.
   --
   --  This package deepens Global / Depends legality by checking body/spec
   --  refinement conformance directly.  It consumes explicit flow-effect graph
   --  rows and repaired coverage semantic feedback before allowing a body
   --  Global effect, Refined_Global item, or Refined_Depends edge to become a
   --  confident legality result.
   --
   --  The layer checks missing and extra body effects, mode refinement,
   --  Refined_Global coverage of body reads/writes, Refined_Depends coverage of
   --  body dependency edges, source/target mode consistency, linked flow graph
   --  errors, and repaired coverage blockers.  It is deterministic, bounded,
   --  snapshot-owned, and performs no parsing, file IO, dirty-state mutation,
   --  command/keybinding/workspace/render mutation, compiler invocation, or
   --  external parser generation.

   package DGL renames Editor.Ada_Dataflow_Global_Depends_Legality;
   package Flow renames Editor.Ada_Flow_Effect_Graph_Legality;
   package Feedback renames Editor.Ada_Repaired_Coverage_Semantic_Feedback;

   type Refined_Conformance_Id is new Natural;
   No_Refined_Conformance : constant Refined_Conformance_Id := 0;

   type Refined_Context_Kind is
     (Refined_Context_Subprogram_Body,
      Refined_Context_Refined_Global_Item,
      Refined_Context_Refined_Depends_Edge,
      Refined_Context_Call_Propagation,
      Refined_Context_Generic_Instance_Body,
      Refined_Context_Task_Protected_Body,
      Refined_Context_Package_Body,
      Refined_Context_Unknown);

   type Refined_Effect_Kind is
     (Refined_Effect_Read,
      Refined_Effect_Write,
      Refined_Effect_Read_Write,
      Refined_Effect_Null,
      Refined_Effect_Depends_Edge,
      Refined_Effect_Call_Propagation,
      Refined_Effect_Generic_Substitution,
      Refined_Effect_Task_Protected_State,
      Refined_Effect_Unknown);

   type Refined_Conformance_Status is
     (Refined_Conformance_Not_Checked,
      Refined_Conformance_Legal_Global_Refinement,
      Refined_Conformance_Legal_Depends_Refinement,
      Refined_Conformance_Legal_Null_Refinement,
      Refined_Conformance_Legal_Call_Effect_Propagation,
      Refined_Conformance_Body_Read_Missing_From_Spec_Global,
      Refined_Conformance_Body_Write_Missing_From_Spec_Global,
      Refined_Conformance_Body_Read_Missing_From_Refined_Global,
      Refined_Conformance_Body_Write_Missing_From_Refined_Global,
      Refined_Conformance_Refined_Global_Extra_Item,
      Refined_Conformance_Refined_Global_Mode_Mismatch,
      Refined_Conformance_Refined_Depends_Missing_Edge,
      Refined_Conformance_Refined_Depends_Extra_Edge,
      Refined_Conformance_Refined_Depends_Source_Not_Spec_Input,
      Refined_Conformance_Refined_Depends_Target_Not_Spec_Output,
      Refined_Conformance_Body_Depends_Not_Refined,
      Refined_Conformance_Call_Effect_Not_Propagated,
      Refined_Conformance_Linked_Flow_Graph_Error,
      Refined_Conformance_Coverage_Feedback_Blocker,
      Refined_Conformance_Indeterminate);

   type Refined_Context_Info is record
      Id                       : Refined_Conformance_Id := No_Refined_Conformance;
      Kind                     : Refined_Context_Kind := Refined_Context_Unknown;
      Effect                   : Refined_Effect_Kind := Refined_Effect_Unknown;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Spec_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subprogram_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Global_Mode         : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Body_Effect_Mode         : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Refined_Global_Mode      : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Source_Global_Mode       : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Target_Global_Mode       : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Reads_Object             : Boolean := False;
      Writes_Object            : Boolean := False;
      Spec_Global_Present      : Boolean := True;
      Body_Effect_Present      : Boolean := True;
      Refined_Global_Present   : Boolean := True;
      Spec_Depends_Present     : Boolean := True;
      Body_Depends_Present     : Boolean := True;
      Refined_Depends_Present  : Boolean := True;
      Refined_Item_Is_Extra    : Boolean := False;
      Refined_Depends_Is_Extra : Boolean := False;
      Effect_Propagated        : Boolean := True;
      Flow_Status              : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Coverage_Feedback        : Feedback.Feedback_Status := Feedback.Feedback_Not_Checked;
      Coverage_Eligible        : Boolean := True;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Source_Fingerprint       : Natural := 0;
   end record;

   type Refined_Conformance_Info is record
      Id                       : Refined_Conformance_Id := No_Refined_Conformance;
      Context                  : Refined_Conformance_Id := No_Refined_Conformance;
      Kind                     : Refined_Context_Kind := Refined_Context_Unknown;
      Effect                   : Refined_Effect_Kind := Refined_Effect_Unknown;
      Status                   : Refined_Conformance_Status := Refined_Conformance_Not_Checked;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Spec_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subprogram_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Source_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
      Detail                   : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Global_Mode         : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Body_Effect_Mode         : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Refined_Global_Mode      : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Source_Global_Mode       : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Target_Global_Mode       : DGL.Global_Mode := DGL.Global_Mode_Not_Declared;
      Flow_Status              : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Coverage_Feedback        : Feedback.Feedback_Status := Feedback.Feedback_Not_Checked;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Source_Fingerprint       : Natural := 0;
      Fingerprint              : Natural := 0;
   end record;

   type Refined_Context_Model is private;
   type Refined_Conformance_Set is private;
   type Refined_Conformance_Model is private;

   procedure Clear (Model : in out Refined_Context_Model);
   procedure Add_Context
     (Model : in out Refined_Context_Model;
      Info  : Refined_Context_Info);

   procedure Add_From_Flow_Row
     (Model    : in out Refined_Context_Model;
      Row      : Flow.Flow_Effect_Info;
      Feedback : Editor.Ada_Repaired_Coverage_Semantic_Feedback.Feedback_Model);

   function Context_Count (Model : Refined_Context_Model) return Natural;
   function Context_At
     (Model : Refined_Context_Model;
      Index : Positive) return Refined_Context_Info;
   function Fingerprint (Model : Refined_Context_Model) return Natural;

   function Build (Contexts : Refined_Context_Model) return Refined_Conformance_Model;
   function Build_From_Flow_Graph
     (Graph    : Flow.Flow_Effect_Graph_Model;
      Feedback : Editor.Ada_Repaired_Coverage_Semantic_Feedback.Feedback_Model)
      return Refined_Conformance_Model;

   function Row_Count (Model : Refined_Conformance_Model) return Natural;
   function Row_At
     (Model : Refined_Conformance_Model;
      Index : Positive) return Refined_Conformance_Info;
   function First_For_Node
     (Model : Refined_Conformance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Refined_Conformance_Info;

   function Rows_For_Status
     (Model  : Refined_Conformance_Model;
      Status : Refined_Conformance_Status) return Refined_Conformance_Set;
   function Rows_For_Kind
     (Model : Refined_Conformance_Model;
      Kind  : Refined_Context_Kind) return Refined_Conformance_Set;
   function Rows_For_Object
     (Model : Refined_Conformance_Model;
      Name  : String) return Refined_Conformance_Set;

   function Set_Count (Set : Refined_Conformance_Set) return Natural;
   function Set_At
     (Set   : Refined_Conformance_Set;
      Index : Positive) return Refined_Conformance_Info;

   function Count_Status
     (Model  : Refined_Conformance_Model;
      Status : Refined_Conformance_Status) return Natural;
   function Count_Kind
     (Model : Refined_Conformance_Model;
      Kind  : Refined_Context_Kind) return Natural;

   function Legal_Count (Model : Refined_Conformance_Model) return Natural;
   function Error_Count (Model : Refined_Conformance_Model) return Natural;
   function Global_Error_Count (Model : Refined_Conformance_Model) return Natural;
   function Depends_Error_Count (Model : Refined_Conformance_Model) return Natural;
   function Flow_Linked_Error_Count (Model : Refined_Conformance_Model) return Natural;
   function Coverage_Feedback_Error_Count (Model : Refined_Conformance_Model) return Natural;
   function Indeterminate_Count (Model : Refined_Conformance_Model) return Natural;
   function Fingerprint (Model : Refined_Conformance_Model) return Natural;

   function Is_Legal (Status : Refined_Conformance_Status) return Boolean;
   function Is_Global_Error (Status : Refined_Conformance_Status) return Boolean;
   function Is_Depends_Error (Status : Refined_Conformance_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Refined_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Refined_Conformance_Info);

   type Refined_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Refined_Conformance_Set is record
      Items : Row_Vectors.Vector;
   end record;

   type Refined_Conformance_Model is record
      Items                         : Row_Vectors.Vector;
      Legal_Total                   : Natural := 0;
      Error_Total                   : Natural := 0;
      Global_Error_Total            : Natural := 0;
      Depends_Error_Total           : Natural := 0;
      Flow_Linked_Error_Total       : Natural := 0;
      Coverage_Feedback_Error_Total : Natural := 0;
      Indeterminate_Total           : Natural := 0;
      Fingerprint                   : Natural := 0;
   end record;

end Editor.Ada_Refined_Global_Depends_Conformance_Legality;
