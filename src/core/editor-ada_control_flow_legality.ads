with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Return_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Control_Flow_Legality is

   --  Wide compiler-grade semantic legality building block for Case 1102.
   --  This package covers statement/control-flow legality that sits above
   --  expression and return legality: Boolean-only conditions, case-choice
   --  coverage/staticness, exit/goto target legality, exception choices,
   --  raise target resolution, select/accept/requeue target checks, and
   --  return-path completeness.  It is fixture-friendly and snapshot-owned;
   --  callers provide already-resolved semantic facts and no render-side
   --  parsing, file IO, editor mutation, or command/workspace/render mutation
   --  is performed.

   type Flow_Context_Id is new Natural;
   No_Flow_Context : constant Flow_Context_Id := 0;

   type Flow_Legality_Id is new Natural;
   No_Flow_Legality : constant Flow_Legality_Id := 0;

   type Flow_Context_Kind is
     (Flow_Context_If_Statement,
      Flow_Context_Elsif_Condition,
      Flow_Context_While_Loop,
      Flow_Context_Case_Statement,
      Flow_Context_Exit_Statement,
      Flow_Context_Goto_Statement,
      Flow_Context_Label,
      Flow_Context_Exception_Handler,
      Flow_Context_Raise_Statement,
      Flow_Context_Select_Statement,
      Flow_Context_Accept_Statement,
      Flow_Context_Requeue_Statement,
      Flow_Context_Subprogram_Body,
      Flow_Context_Block,
      Flow_Context_Unknown);

   type Flow_Legality_Status is
     (Flow_Legality_Not_Checked,
      Flow_Legality_Legal_Boolean_Condition,
      Flow_Legality_Legal_Case_Statement,
      Flow_Legality_Legal_Exit,
      Flow_Legality_Legal_Goto,
      Flow_Legality_Legal_Label,
      Flow_Legality_Legal_Exception_Handler,
      Flow_Legality_Legal_Raise,
      Flow_Legality_Legal_Select,
      Flow_Legality_Legal_Accept,
      Flow_Legality_Legal_Requeue,
      Flow_Legality_Legal_Return_Path,
      Flow_Legality_Condition_Unresolved,
      Flow_Legality_Condition_Not_Boolean,
      Flow_Legality_Case_Expression_Unresolved,
      Flow_Legality_Case_Choice_Non_Static,
      Flow_Legality_Case_Choice_Duplicate,
      Flow_Legality_Case_Choice_Missing,
      Flow_Legality_Case_Choice_Type_Mismatch,
      Flow_Legality_Exit_Target_Missing,
      Flow_Legality_Exit_Target_Not_Loop,
      Flow_Legality_Exit_From_Non_Loop,
      Flow_Legality_Goto_Target_Missing,
      Flow_Legality_Goto_Into_Deeper_Scope,
      Flow_Legality_Goto_Out_Of_Handler,
      Flow_Legality_Duplicate_Label,
      Flow_Legality_Exception_Choice_Unresolved,
      Flow_Legality_Exception_Choice_Duplicate,
      Flow_Legality_Exception_Choice_Others_Not_Last,
      Flow_Legality_Raise_Exception_Unresolved,
      Flow_Legality_Select_Alternative_Error,
      Flow_Legality_Accept_Entry_Missing,
      Flow_Legality_Requeue_Target_Unresolved,
      Flow_Legality_Missing_Return_Path,
      Flow_Legality_Return_Path_Contains_Illegal_Return,
      Flow_Legality_No_Return_Path_Indeterminate,
      Flow_Legality_Indeterminate);

   type Flow_Context_Info is record
      Id                  : Flow_Context_Id := No_Flow_Context;
      Kind                : Flow_Context_Kind := Flow_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Condition_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Condition_Subtype   : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Condition_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Case_Expression_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Case_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Condition_Type_Resolved : Boolean := False;
      Condition_Is_Boolean    : Boolean := False;
      Case_Expression_Resolved : Boolean := False;
      Case_Choices_Static      : Boolean := True;
      Case_Choices_Complete    : Boolean := True;
      Case_Has_Duplicate_Choice : Boolean := False;
      Case_Choice_Type_Mismatch : Boolean := False;
      Exit_Has_Target          : Boolean := False;
      Exit_Target_Resolved     : Boolean := True;
      Exit_Target_Is_Loop      : Boolean := True;
      Exit_Is_Inside_Loop      : Boolean := True;
      Goto_Target_Resolved     : Boolean := True;
      Goto_Into_Deeper_Scope   : Boolean := False;
      Goto_Out_Of_Handler      : Boolean := False;
      Label_Is_Duplicate       : Boolean := False;
      Exception_Choice_Resolved : Boolean := True;
      Exception_Choice_Duplicate : Boolean := False;
      Exception_Others_Is_Last : Boolean := True;
      Raise_Exception_Resolved : Boolean := True;
      Select_Has_Illegal_Alternative : Boolean := False;
      Accept_Entry_Resolved    : Boolean := True;
      Requeue_Target_Resolved  : Boolean := True;
      Subprogram_Requires_Return : Boolean := False;
      Subprogram_Has_Complete_Return_Path : Boolean := True;
      Return_Legality          : Editor.Ada_Return_Legality.Return_Legality_Id :=
        Editor.Ada_Return_Legality.No_Return_Legality;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Flow_Legality_Info is record
      Id                  : Flow_Legality_Id := No_Flow_Legality;
      Context             : Flow_Context_Id := No_Flow_Context;
      Kind                : Flow_Context_Kind := Flow_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Condition_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status              : Flow_Legality_Status := Flow_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Condition_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Case_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Return_Legality     : Editor.Ada_Return_Legality.Return_Legality_Id :=
        Editor.Ada_Return_Legality.No_Return_Legality;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Flow_Context_Model is private;
   type Flow_Legality_Result_Set is private;
   type Flow_Legality_Model is private;

   procedure Clear (Model : in out Flow_Context_Model);
   procedure Add_Context
     (Model   : in out Flow_Context_Model;
      Context : Flow_Context_Info);

   function Context_Count (Model : Flow_Context_Model) return Natural;
   function Context_At
     (Model : Flow_Context_Model;
      Index : Positive) return Flow_Context_Info;
   function Fingerprint (Model : Flow_Context_Model) return Natural;

   function Build_Contexts_From_Returns
     (Returns : Editor.Ada_Return_Legality.Return_Legality_Model)
      return Flow_Context_Model;

   function Build
     (Contexts : Flow_Context_Model;
      Returns  : Editor.Ada_Return_Legality.Return_Legality_Model)
      return Flow_Legality_Model;

   function Legality_Count (Model : Flow_Legality_Model) return Natural;
   function Legality_At
     (Model : Flow_Legality_Model;
      Index : Positive) return Flow_Legality_Info;

   function First_For_Context
     (Model   : Flow_Legality_Model;
      Context : Flow_Context_Id) return Flow_Legality_Info;
   function First_For_Node
     (Model : Flow_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Flow_Legality_Info;
   function Results_For_Status
     (Model  : Flow_Legality_Model;
      Status : Flow_Legality_Status) return Flow_Legality_Result_Set;
   function Rows_For_Kind
     (Model : Flow_Legality_Model;
      Kind  : Flow_Context_Kind) return Flow_Legality_Result_Set;
   function Rows_For_Target
     (Model  : Flow_Legality_Model;
      Target : Ada.Strings.Unbounded.Unbounded_String) return Flow_Legality_Result_Set;

   function Result_Count (Results : Flow_Legality_Result_Set) return Natural;
   function Result_At
     (Results : Flow_Legality_Result_Set;
      Index   : Positive) return Flow_Legality_Info;

   function Count_Status
     (Model  : Flow_Legality_Model;
      Status : Flow_Legality_Status) return Natural;
   function Count_Kind
     (Model : Flow_Legality_Model;
      Kind  : Flow_Context_Kind) return Natural;

   function Compatible_Count (Model : Flow_Legality_Model) return Natural;
   function Error_Count (Model : Flow_Legality_Model) return Natural;
   function Warning_Count (Model : Flow_Legality_Model) return Natural;
   function Boolean_Context_Error_Count (Model : Flow_Legality_Model) return Natural;
   function Case_Error_Count (Model : Flow_Legality_Model) return Natural;
   function Exit_Goto_Error_Count (Model : Flow_Legality_Model) return Natural;
   function Exception_Error_Count (Model : Flow_Legality_Model) return Natural;
   function Tasking_Error_Count (Model : Flow_Legality_Model) return Natural;
   function Return_Path_Error_Count (Model : Flow_Legality_Model) return Natural;
   function Fingerprint (Model : Flow_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Flow_Context_Info);

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Flow_Legality_Info);

   type Flow_Context_Model is record
      Contexts    : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Flow_Legality_Result_Set is record
      Results : Result_Vectors.Vector;
   end record;

   type Flow_Legality_Model is record
      Results     : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Control_Flow_Legality;
