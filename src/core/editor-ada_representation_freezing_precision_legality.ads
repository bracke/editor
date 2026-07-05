with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Elaboration_Precision_Legality;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Representation_Layout_Stream_Integration_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Precision_Legality;

package Editor.Ada_Representation_Freezing_Precision_Legality is

   --  Case 1131 compiler-grade representation/freezing precision layer.
   --
   --  This package deepens representation/freezing legality by connecting
   --  explicit representation clauses/aspects, implicit semantic-use freezing,
   --  private/full-view timing, generic-instance freezing effects,
   --  representation/layout/stream integration, elaboration precision, and
   --  tasking/protected precision.  Inputs are snapshot-owned facts supplied by
   --  callers.  The package performs no parsing, file IO, dirty-state mutation,
   --  command/keybinding/workspace/render mutation, or compiler invocation.

   subtype Freezing_Status is Editor.Ada_Freezing_Points.Freezing_Status;
   subtype Representation_Status is
     Editor.Ada_Representation_Legality.Representation_Legality_Status;
   subtype Representation_Integration_Status is
     Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Status;
   subtype Generic_Instance_Status is
     Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Status;
   subtype Elaboration_Precision_Status is
     Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Status;
   subtype Tasking_Precision_Status is
     Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Status;

   type Representation_Freezing_Precision_Context_Id is new Natural;
   No_Representation_Freezing_Precision_Context : constant Representation_Freezing_Precision_Context_Id := 0;

   type Representation_Freezing_Precision_Id is new Natural;
   No_Representation_Freezing_Precision : constant Representation_Freezing_Precision_Id := 0;

   type Representation_Freezing_Precision_Context_Kind is
     (Representation_Freezing_Context_Representation_Clause,
      Representation_Freezing_Context_Representation_Aspect,
      Representation_Freezing_Context_Operational_Item,
      Representation_Freezing_Context_Stream_Attribute,
      Representation_Freezing_Context_Record_Layout,
      Representation_Freezing_Context_Generic_Instance,
      Representation_Freezing_Context_Private_Full_View,
      Representation_Freezing_Context_Implicit_Semantic_Use,
      Representation_Freezing_Context_Task_Protected_Effect,
      Representation_Freezing_Context_Unknown);

   type Freezing_Cause_Kind is
     (Freezing_Cause_None,
      Freezing_Cause_Explicit_Representation,
      Freezing_Cause_Implicit_Object_Declaration,
      Freezing_Cause_Implicit_Subprogram_Body,
      Freezing_Cause_Implicit_Expression_Use,
      Freezing_Cause_Implicit_Call_Use,
      Freezing_Cause_Generic_Instance,
      Freezing_Cause_Private_Full_View,
      Freezing_Cause_Elaboration,
      Freezing_Cause_Task_Activation,
      Freezing_Cause_Unknown);

   type Representation_Freezing_Precision_Status is
     (Representation_Freezing_Precision_Not_Checked,
      Representation_Freezing_Precision_Legal_Representation_Item,
      Representation_Freezing_Precision_Legal_Aspect,
      Representation_Freezing_Precision_Legal_Operational_Item,
      Representation_Freezing_Precision_Legal_Stream_Attribute,
      Representation_Freezing_Precision_Legal_Record_Layout,
      Representation_Freezing_Precision_Legal_Generic_Instance_Effect,
      Representation_Freezing_Precision_Legal_Private_Full_View,
      Representation_Freezing_Precision_Legal_Implicit_Freezing,
      Representation_Freezing_Precision_Target_Unresolved,
      Representation_Freezing_Precision_Target_Ambiguous,
      Representation_Freezing_Precision_Target_Not_Freezable,
      Representation_Freezing_Precision_Target_Kind_Mismatch,
      Representation_Freezing_Precision_Representation_After_Explicit_Freezing,
      Representation_Freezing_Precision_Representation_After_Implicit_Freezing,
      Representation_Freezing_Precision_Representation_After_Generic_Instance_Freezing,
      Representation_Freezing_Precision_Representation_After_Private_Full_View_Freezing,
      Representation_Freezing_Precision_Representation_At_Freezing_Point,
      Representation_Freezing_Precision_Private_View_Barrier,
      Representation_Freezing_Precision_Full_View_Completion_Missing,
      Representation_Freezing_Precision_Static_Value_Error,
      Representation_Freezing_Precision_Profile_Error,
      Representation_Freezing_Precision_Operational_Error,
      Representation_Freezing_Precision_Record_Layout_Error,
      Representation_Freezing_Precision_Stream_Profile_Error,
      Representation_Freezing_Precision_Generic_Instance_Freezing_Error,
      Representation_Freezing_Precision_Generic_Instance_Representation_Error,
      Representation_Freezing_Precision_Elaboration_Freezing_Error,
      Representation_Freezing_Precision_Tasking_Protected_Freezing_Error,
      Representation_Freezing_Precision_Linked_Representation_Error,
      Representation_Freezing_Precision_Linked_Integration_Error,
      Representation_Freezing_Precision_Indeterminate);

   type Representation_Freezing_Precision_Context_Info is record
      Id                    : Representation_Freezing_Precision_Context_Id :=
        No_Representation_Freezing_Precision_Context;
      Kind                  : Representation_Freezing_Precision_Context_Kind :=
        Representation_Freezing_Context_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Freeze_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Clause_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Cause                 : Freezing_Cause_Kind := Freezing_Cause_None;
      Freezing              : Freezing_Status := Editor.Ada_Freezing_Points.Freezing_Not_Frozen;
      Representation        : Representation_Status :=
        Editor.Ada_Representation_Legality.Representation_Legality_Ok;
      Integration           : Representation_Integration_Status :=
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Not_Checked;
      Generic_Instance      : Generic_Instance_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Elaboration           : Elaboration_Precision_Status :=
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Not_Checked;
      Tasking               : Tasking_Precision_Status :=
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Not_Checked;
      Representation_Line   : Positive := 1;
      Freeze_Line           : Positive := 1;
      Private_View_Barrier  : Boolean := False;
      Full_View_Completed   : Boolean := True;
      Implicit_Use_Freezes_Target : Boolean := False;
      Representation_After_Implicit_Freezing : Boolean := False;
      Representation_After_Generic_Instance_Freezing : Boolean := False;
      Representation_After_Private_Full_View_Freezing : Boolean := False;
      Source_Fingerprint    : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
   end record;

   type Representation_Freezing_Precision_Info is record
      Id                    : Representation_Freezing_Precision_Id :=
        No_Representation_Freezing_Precision;
      Context               : Representation_Freezing_Precision_Context_Id :=
        No_Representation_Freezing_Precision_Context;
      Kind                  : Representation_Freezing_Precision_Context_Kind :=
        Representation_Freezing_Context_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Freeze_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Clause_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                : Representation_Freezing_Precision_Status :=
        Representation_Freezing_Precision_Not_Checked;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Cause                 : Freezing_Cause_Kind := Freezing_Cause_None;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Freezing              : Freezing_Status := Editor.Ada_Freezing_Points.Freezing_Not_Frozen;
      Representation        : Representation_Status :=
        Editor.Ada_Representation_Legality.Representation_Legality_Ok;
      Integration           : Representation_Integration_Status :=
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Not_Checked;
      Generic_Instance      : Generic_Instance_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Elaboration           : Elaboration_Precision_Status :=
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Not_Checked;
      Tasking               : Tasking_Precision_Status :=
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Not_Checked;
      Representation_Line   : Positive := 1;
      Freeze_Line           : Positive := 1;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Representation_Freezing_Precision_Context_Model is private;
   type Representation_Freezing_Precision_Result_Set is private;
   type Representation_Freezing_Precision_Model is private;

   procedure Clear (Model : in out Representation_Freezing_Precision_Context_Model);
   procedure Add_Context
     (Model   : in out Representation_Freezing_Precision_Context_Model;
      Context : Representation_Freezing_Precision_Context_Info);

   function Context_Count
     (Model : Representation_Freezing_Precision_Context_Model) return Natural;
   function Context_At
     (Model : Representation_Freezing_Precision_Context_Model;
      Index : Positive) return Representation_Freezing_Precision_Context_Info;

   function Build
     (Contexts : Representation_Freezing_Precision_Context_Model)
      return Representation_Freezing_Precision_Model;

   function Legality_Count
     (Model : Representation_Freezing_Precision_Model) return Natural;
   function Legality_At
     (Model : Representation_Freezing_Precision_Model;
      Index : Positive) return Representation_Freezing_Precision_Info;

   function First_For_Node
     (Model : Representation_Freezing_Precision_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Freezing_Precision_Info;
   function First_For_Context
     (Model   : Representation_Freezing_Precision_Model;
      Context : Representation_Freezing_Precision_Context_Id)
      return Representation_Freezing_Precision_Info;
   function Rows_For_Status
     (Model  : Representation_Freezing_Precision_Model;
      Status : Representation_Freezing_Precision_Status)
      return Representation_Freezing_Precision_Result_Set;
   function Rows_For_Kind
     (Model : Representation_Freezing_Precision_Model;
      Kind  : Representation_Freezing_Precision_Context_Kind)
      return Representation_Freezing_Precision_Result_Set;
   function Rows_For_Target
     (Model : Representation_Freezing_Precision_Model;
      Name  : String) return Representation_Freezing_Precision_Result_Set;

   function Result_Count
     (Results : Representation_Freezing_Precision_Result_Set) return Natural;
   function Result_At
     (Results : Representation_Freezing_Precision_Result_Set;
      Index   : Positive) return Representation_Freezing_Precision_Info;

   function Count_Status
     (Model  : Representation_Freezing_Precision_Model;
      Status : Representation_Freezing_Precision_Status) return Natural;
   function Count_Kind
     (Model : Representation_Freezing_Precision_Model;
      Kind  : Representation_Freezing_Precision_Context_Kind) return Natural;

   function Legal_Count (Model : Representation_Freezing_Precision_Model) return Natural;
   function Error_Count (Model : Representation_Freezing_Precision_Model) return Natural;
   function Freezing_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural;
   function View_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural;
   function Representation_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural;
   function Integration_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural;
   function Generic_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural;
   function Elaboration_Tasking_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural;
   function Fingerprint (Model : Representation_Freezing_Precision_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Freezing_Precision_Context_Info);

   package Info_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Freezing_Precision_Info);

   type Representation_Freezing_Precision_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Representation_Freezing_Precision_Result_Set is record
      Items : Info_Vectors.Vector;
   end record;

   type Representation_Freezing_Precision_Model is record
      Items       : Info_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Representation_Freezing_Precision_Legality;
