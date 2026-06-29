with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Tasking_Protected_Legality is

   --  Wide compiler-grade semantic legality building block for Pass1103.
   --  This package covers Ada tasking/protected declaration and body
   --  semantics above the statement-flow layer: task/protected body-to-spec
   --  matching, entry declaration/body/accept/requeue resolution, entry family
   --  index compatibility, protected barrier Boolean/static legality,
   --  protected operation restrictions, protected private data visibility,
   --  and select/accept/requeue flow legality integration.  It is
   --  snapshot-owned and fixture-friendly; callers provide resolved semantic
   --  facts and this package performs no parsing, file IO, editor mutation, or
   --  command/workspace/render mutation.

   type Tasking_Context_Id is new Natural;
   No_Tasking_Context : constant Tasking_Context_Id := 0;

   type Tasking_Legality_Id is new Natural;
   No_Tasking_Legality : constant Tasking_Legality_Id := 0;

   type Tasking_Context_Kind is
     (Tasking_Context_Task_Type,
      Tasking_Context_Task_Body,
      Tasking_Context_Protected_Type,
      Tasking_Context_Protected_Body,
      Tasking_Context_Entry_Declaration,
      Tasking_Context_Entry_Body,
      Tasking_Context_Entry_Family,
      Tasking_Context_Accept_Statement,
      Tasking_Context_Requeue_Statement,
      Tasking_Context_Protected_Function,
      Tasking_Context_Protected_Procedure,
      Tasking_Context_Protected_Entry,
      Tasking_Context_Select_Statement,
      Tasking_Context_Unknown);

   type Tasking_Legality_Status is
     (Tasking_Legality_Not_Checked,
      Tasking_Legality_Legal_Task_Type,
      Tasking_Legality_Legal_Task_Body,
      Tasking_Legality_Legal_Protected_Type,
      Tasking_Legality_Legal_Protected_Body,
      Tasking_Legality_Legal_Entry_Declaration,
      Tasking_Legality_Legal_Entry_Body,
      Tasking_Legality_Legal_Entry_Family,
      Tasking_Legality_Legal_Accept,
      Tasking_Legality_Legal_Requeue,
      Tasking_Legality_Legal_Protected_Function,
      Tasking_Legality_Legal_Protected_Procedure,
      Tasking_Legality_Legal_Protected_Entry,
      Tasking_Legality_Legal_Select,
      Tasking_Legality_Missing_Spec,
      Tasking_Legality_Missing_Body,
      Tasking_Legality_Duplicate_Body,
      Tasking_Legality_Kind_Mismatch,
      Tasking_Legality_Profile_Mismatch,
      Tasking_Legality_Entry_Missing,
      Tasking_Legality_Entry_Duplicate,
      Tasking_Legality_Entry_Family_Index_Mismatch,
      Tasking_Legality_Entry_Family_Index_Unresolved,
      Tasking_Legality_Barrier_Unresolved,
      Tasking_Legality_Barrier_Not_Boolean,
      Tasking_Legality_Barrier_Non_Static_Family_Index,
      Tasking_Legality_Accept_Entry_Missing,
      Tasking_Legality_Accept_Not_In_Task_Body,
      Tasking_Legality_Accept_Profile_Mismatch,
      Tasking_Legality_Requeue_Target_Unresolved,
      Tasking_Legality_Requeue_To_Non_Entry,
      Tasking_Legality_Requeue_With_Abort_Not_Allowed,
      Tasking_Legality_Protected_Function_Modifies_State,
      Tasking_Legality_Protected_Function_Calls_Entry,
      Tasking_Legality_Protected_Procedure_Barrier,
      Tasking_Legality_Protected_Entry_Barrier_Missing,
      Tasking_Legality_Protected_Private_Data_Unresolved,
      Tasking_Legality_Select_Alternative_Error,
      Tasking_Legality_Flow_Legality_Error,
      Tasking_Legality_Indeterminate);

   type Tasking_Context_Info is record
      Id                  : Tasking_Context_Id := No_Tasking_Context;
      Kind                : Tasking_Context_Kind := Tasking_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Spec_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Barrier_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Entry_Name : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Resolved       : Boolean := True;
      Body_Resolved       : Boolean := True;
      Has_Body            : Boolean := True;
      Duplicate_Body      : Boolean := False;
      Kind_Matches        : Boolean := True;
      Profile_Matches     : Boolean := True;
      Entry_Resolved      : Boolean := True;
      Entry_Duplicate     : Boolean := False;
      Entry_Is_Family     : Boolean := False;
      Entry_Family_Index_Resolved : Boolean := True;
      Entry_Family_Index_Compatible : Boolean := True;
      Entry_Family_Index_Static : Boolean := True;
      Barrier_Present     : Boolean := True;
      Barrier_Type_Resolved : Boolean := True;
      Barrier_Is_Boolean  : Boolean := True;
      Accept_Is_In_Task_Body : Boolean := True;
      Requeue_Target_Resolved : Boolean := True;
      Requeue_Target_Is_Entry : Boolean := True;
      Requeue_With_Abort_Allowed : Boolean := True;
      Protected_Function_Modifies_State : Boolean := False;
      Protected_Function_Calls_Entry : Boolean := False;
      Protected_Procedure_Has_Barrier : Boolean := False;
      Protected_Private_Data_Resolved : Boolean := True;
      Select_Has_Illegal_Alternative : Boolean := False;
      Flow_Legality       : Editor.Ada_Control_Flow_Legality.Flow_Legality_Id :=
        Editor.Ada_Control_Flow_Legality.No_Flow_Legality;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Tasking_Legality_Info is record
      Id                  : Tasking_Legality_Id := No_Tasking_Legality;
      Context             : Tasking_Context_Id := No_Tasking_Context;
      Kind                : Tasking_Context_Kind := Tasking_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Spec_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Barrier_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status              : Tasking_Legality_Status := Tasking_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Entry_Name : Ada.Strings.Unbounded.Unbounded_String;
      Flow_Legality       : Editor.Ada_Control_Flow_Legality.Flow_Legality_Id :=
        Editor.Ada_Control_Flow_Legality.No_Flow_Legality;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Tasking_Context_Model is private;
   type Tasking_Result_Set is private;
   type Tasking_Legality_Model is private;

   procedure Clear (Model : in out Tasking_Context_Model);
   procedure Add_Context
     (Model   : in out Tasking_Context_Model;
      Context : Tasking_Context_Info);

   function Context_Count (Model : Tasking_Context_Model) return Natural;
   function Context_At
     (Model : Tasking_Context_Model;
      Index : Positive) return Tasking_Context_Info;
   function Fingerprint (Model : Tasking_Context_Model) return Natural;

   function Build_Contexts_From_Syntax
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Flow : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model)
      return Tasking_Context_Model;

   function Build
     (Contexts : Tasking_Context_Model;
      Flow     : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model)
      return Tasking_Legality_Model;

   function Legality_Count (Model : Tasking_Legality_Model) return Natural;
   function Legality_At
     (Model : Tasking_Legality_Model;
      Index : Positive) return Tasking_Legality_Info;

   function First_For_Context
     (Model   : Tasking_Legality_Model;
      Context : Tasking_Context_Id) return Tasking_Legality_Info;
   function First_For_Node
     (Model : Tasking_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Legality_Info;
   function Rows_For_Status
     (Model  : Tasking_Legality_Model;
      Status : Tasking_Legality_Status) return Tasking_Result_Set;
   function Rows_For_Kind
     (Model : Tasking_Legality_Model;
      Kind  : Tasking_Context_Kind) return Tasking_Result_Set;
   function Rows_For_Unit
     (Model : Tasking_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Tasking_Result_Set;
   function Rows_For_Entry
     (Model : Tasking_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Tasking_Result_Set;

   function Result_Count (Results : Tasking_Result_Set) return Natural;
   function Result_At
     (Results : Tasking_Result_Set;
      Index   : Positive) return Tasking_Legality_Info;

   function Count_Status
     (Model  : Tasking_Legality_Model;
      Status : Tasking_Legality_Status) return Natural;
   function Count_Kind
     (Model : Tasking_Legality_Model;
      Kind  : Tasking_Context_Kind) return Natural;

   function Compatible_Count (Model : Tasking_Legality_Model) return Natural;
   function Error_Count (Model : Tasking_Legality_Model) return Natural;
   function Warning_Count (Model : Tasking_Legality_Model) return Natural;
   function Spec_Body_Error_Count (Model : Tasking_Legality_Model) return Natural;
   function Entry_Error_Count (Model : Tasking_Legality_Model) return Natural;
   function Barrier_Error_Count (Model : Tasking_Legality_Model) return Natural;
   function Accept_Requeue_Error_Count (Model : Tasking_Legality_Model) return Natural;
   function Protected_Operation_Error_Count (Model : Tasking_Legality_Model) return Natural;
   function Flow_Error_Count (Model : Tasking_Legality_Model) return Natural;
   function Fingerprint (Model : Tasking_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_Context_Info);

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_Legality_Info);

   type Tasking_Context_Model is record
      Contexts    : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Tasking_Result_Set is record
      Results : Result_Vectors.Vector;
   end record;

   type Tasking_Legality_Model is record
      Results     : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tasking_Protected_Legality;
