with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Return_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Definite_Initialization_Flow_Legality is

   --  Case 1121 compiler-grade definite-initialization and flow legality.
   --  The model is snapshot-owned and projection-free.  It records Ada
   --  initialization, assignment-before-read, out/in out parameter, return,
   --  exception/finalization, and closure-blocker facts without parsing,
   --  command registration, file IO, save/reload, dirty-state mutation, or
   --  render-side analysis.

   subtype Assignment_Legality_Id is
     Editor.Ada_Assignment_Legality.Assignment_Legality_Id;
   subtype Assignment_Legality_Status is
     Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   subtype Return_Legality_Id is
     Editor.Ada_Return_Legality.Return_Legality_Id;
   subtype Return_Legality_Status is
     Editor.Ada_Return_Legality.Return_Legality_Status;
   subtype Control_Flow_Legality_Id is
     Editor.Ada_Control_Flow_Legality.Flow_Legality_Id;
   subtype Control_Flow_Legality_Status is
     Editor.Ada_Control_Flow_Legality.Flow_Legality_Status;
   subtype Exception_Finalization_Legality_Id is
     Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Id;
   subtype Exception_Finalization_Legality_Status is
     Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Status;
   subtype Integrated_Closure_Id is
     Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Id;
   subtype Integrated_Closure_Status is
     Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Status;

   type Initialization_Context_Id is new Natural;
   No_Initialization_Context : constant Initialization_Context_Id := 0;

   type Initialization_Legality_Id is new Natural;
   No_Initialization_Legality : constant Initialization_Legality_Id := 0;

   type Initialization_Context_Kind is
     (Initialization_Context_Object_Declaration,
      Initialization_Context_Assignment,
      Initialization_Context_Read,
      Initialization_Context_Parameter_In,
      Initialization_Context_Parameter_Out,
      Initialization_Context_Parameter_In_Out,
      Initialization_Context_Return,
      Initialization_Context_Extended_Return,
      Initialization_Context_Component,
      Initialization_Context_Aggregate,
      Initialization_Context_Exception_Path,
      Initialization_Context_Finalization_Path,
      Initialization_Context_Loop_Merge,
      Initialization_Context_Branch_Merge,
      Initialization_Context_Unknown);

   type Object_State is
     (Object_State_Unknown,
      Object_State_Uninitialized,
      Object_State_Partially_Initialized,
      Object_State_Definitely_Initialized,
      Object_State_Conditionally_Initialized,
      Object_State_Moved_Or_Finalized,
      Object_State_Invalidated_By_Exception);

   type Flow_State is
     (Flow_State_Unknown,
      Flow_State_Normal,
      Flow_State_Branch_Merge,
      Flow_State_Loop_Carried,
      Flow_State_Exceptional,
      Flow_State_Finalization,
      Flow_State_Unreachable);

   type Initialization_Legality_Status is
     (Initialization_Legality_Not_Checked,
      Initialization_Legality_Definitely_Initialized,
      Initialization_Legality_Default_Initialized,
      Initialization_Legality_Explicitly_Initialized,
      Initialization_Legality_Component_Initialized,
      Initialization_Legality_Out_Parameter_Assigned,
      Initialization_Legality_Return_Object_Initialized,
      Initialization_Legality_Exception_Path_Preserved,
      Initialization_Legality_Finalization_Path_Preserved,
      Initialization_Legality_Read_Before_Write,
      Initialization_Legality_Component_Read_Before_Write,
      Initialization_Legality_Partial_Component_Initialization,
      Initialization_Legality_Out_Parameter_Not_Assigned,
      Initialization_Legality_In_Out_Parameter_Conditionally_Assigned,
      Initialization_Legality_Return_Object_Not_Initialized,
      Initialization_Legality_Branch_Merge_Not_Definite,
      Initialization_Legality_Loop_Merge_Not_Definite,
      Initialization_Legality_Exception_Path_Loses_Initialization,
      Initialization_Legality_Finalization_Uses_Uninitialized_Object,
      Initialization_Legality_Use_After_Finalization,
      Initialization_Legality_Unreachable_Initialization,
      Initialization_Legality_Linked_Assignment_Error,
      Initialization_Legality_Linked_Return_Error,
      Initialization_Legality_Linked_Control_Flow_Error,
      Initialization_Legality_Linked_Exception_Finalization_Error,
      Initialization_Legality_Linked_Closure_Error,
      Initialization_Legality_Indeterminate);

   type Initialization_Context_Info is record
      Id                     : Initialization_Context_Id := No_Initialization_Context;
      Kind                   : Initialization_Context_Kind := Initialization_Context_Unknown;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Component_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Before_State           : Object_State := Object_State_Unknown;
      After_State            : Object_State := Object_State_Unknown;
      Flow                   : Flow_State := Flow_State_Unknown;
      Has_Default_Init       : Boolean := False;
      Has_Explicit_Init      : Boolean := False;
      Component_Covered      : Boolean := True;
      Reads_Object           : Boolean := False;
      Writes_Object          : Boolean := False;
      Requires_Definite_Init : Boolean := False;
      Must_Assign_Out        : Boolean := False;
      Path_Reaches_Exit      : Boolean := True;
      Assignment             : Assignment_Legality_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Legality;
      Assignment_Status      : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Item            : Return_Legality_Id :=
        Editor.Ada_Return_Legality.No_Return_Legality;
      Return_Status          : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Control_Item           : Control_Flow_Legality_Id :=
        Editor.Ada_Control_Flow_Legality.No_Flow_Legality;
      Control_Status         : Control_Flow_Legality_Status :=
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Not_Checked;
      Exception_Item         : Exception_Finalization_Legality_Id :=
        Editor.Ada_Exception_Finalization_Legality.No_Exception_Legality;
      Exception_Status       : Exception_Finalization_Legality_Status :=
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Not_Checked;
      Closure_Item           : Integrated_Closure_Id :=
        Editor.Ada_Integrated_Semantic_Closure.No_Integrated_Closure;
      Closure_Status         : Integrated_Closure_Status :=
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Not_Checked;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Source_Fingerprint     : Natural := 0;
   end record;

   type Initialization_Legality_Info is record
      Id                     : Initialization_Legality_Id := No_Initialization_Legality;
      Context                : Initialization_Context_Id := No_Initialization_Context;
      Kind                   : Initialization_Context_Kind := Initialization_Context_Unknown;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Component_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Status                 : Initialization_Legality_Status := Initialization_Legality_Not_Checked;
      Message                : Ada.Strings.Unbounded.Unbounded_String;
      Detail                 : Ada.Strings.Unbounded.Unbounded_String;
      Before_State           : Object_State := Object_State_Unknown;
      After_State            : Object_State := Object_State_Unknown;
      Flow                   : Flow_State := Flow_State_Unknown;
      Assignment_Status      : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Status          : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Control_Status         : Control_Flow_Legality_Status :=
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Not_Checked;
      Exception_Status       : Exception_Finalization_Legality_Status :=
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Not_Checked;
      Closure_Status         : Integrated_Closure_Status :=
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Not_Checked;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Source_Fingerprint     : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

   type Initialization_Context_Model is private;
   type Initialization_Legality_Model is private;

   procedure Clear (Model : in out Initialization_Context_Model);
   procedure Add_Context
     (Model : in out Initialization_Context_Model;
      Info  : Initialization_Context_Info);
   function Context_Count (Model : Initialization_Context_Model) return Natural;
   function Context_At
     (Model : Initialization_Context_Model;
      Index : Positive) return Initialization_Context_Info;
   function Fingerprint (Model : Initialization_Context_Model) return Natural;

   function Build
     (Contexts : Initialization_Context_Model) return Initialization_Legality_Model;

   function Row_Count (Model : Initialization_Legality_Model) return Natural;
   function Row_At
     (Model : Initialization_Legality_Model;
      Index : Positive) return Initialization_Legality_Info;
   function First_For_Object
     (Model : Initialization_Legality_Model;
      Name  : String) return Initialization_Legality_Info;
   function Rows_For_Status
     (Model  : Initialization_Legality_Model;
      Status : Initialization_Legality_Status) return Initialization_Legality_Model;
   function Rows_For_Kind
     (Model : Initialization_Legality_Model;
      Kind  : Initialization_Context_Kind) return Initialization_Legality_Model;
   function Rows_For_Node
     (Model : Initialization_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Initialization_Legality_Model;

   function Count_Status
     (Model  : Initialization_Legality_Model;
      Status : Initialization_Legality_Status) return Natural;
   function Count_Kind
     (Model : Initialization_Legality_Model;
      Kind  : Initialization_Context_Kind) return Natural;
   function Legal_Row_Count (Model : Initialization_Legality_Model) return Natural;
   function Error_Row_Count (Model : Initialization_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Initialization_Legality_Model) return Natural;
   function Indeterminate_Row_Count (Model : Initialization_Legality_Model) return Natural;
   function Fingerprint (Model : Initialization_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Initialization_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Initialization_Legality_Info);

   type Initialization_Context_Model is record
      Contexts    : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Initialization_Legality_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Definite_Initialization_Flow_Legality;
