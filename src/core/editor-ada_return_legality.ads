with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Expected_Type_Contexts;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Return_Legality is

   --  Compiler-grade return-statement legality building block.  This package
   --  consumes snapshot-owned assignment/object-initialization legality rows
   --  and classifies Ada return statement contexts without parsing, file IO,
   --  buffer mutation, command/keybinding/workspace mutation, or render-side
   --  work.

   subtype Assignment_Context_Id is
     Editor.Ada_Assignment_Legality.Assignment_Context_Id;
   subtype Assignment_Legality_Status is
     Editor.Ada_Assignment_Legality.Assignment_Legality_Status;

   type Return_Context_Id is new Natural;
   No_Return_Context : constant Return_Context_Id := 0;

   type Return_Legality_Id is new Natural;
   No_Return_Legality : constant Return_Legality_Id := 0;

   type Return_Context_Kind is
     (Return_Context_Procedure_Return,
      Return_Context_Function_Return,
      Return_Context_Extended_Return,
      Return_Context_No_Return_Subprogram,
      Return_Context_Unknown);

   type Return_Legality_Status is
     (Return_Legality_Not_Checked,
      Return_Legality_Procedure_Return_Compatible,
      Return_Legality_Function_Return_Compatible,
      Return_Legality_Extended_Return_Compatible,
      Return_Legality_Procedure_Return_With_Expression,
      Return_Legality_Function_Return_Missing_Expression,
      Return_Legality_Result_Incompatible_Subtype,
      Return_Legality_Result_Class_Wide_Incompatible,
      Return_Legality_Result_Private_View_Barrier,
      Return_Legality_Result_Limited_View_Barrier,
      Return_Legality_Result_Cross_Unit_Unresolved_View,
      Return_Legality_Result_Target_Unresolved,
      Return_Legality_Result_Source_Unresolved,
      Return_Legality_Result_Static_Range_Violation,
      Return_Legality_Result_Universal_Numeric_Unresolved,
      Return_Legality_No_Return_Subprogram_Return,
      Return_Legality_Indeterminate);

   type Return_Context_Info is record
      Id                     : Return_Context_Id := No_Return_Context;
      Kind                   : Return_Context_Kind := Return_Context_Unknown;
      Unit_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Return_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Assignment_Context     : Assignment_Context_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Context;
      Expected_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Has_Expression         : Boolean := False;
      Is_Function_Context    : Boolean := False;
      Is_Procedure_Context   : Boolean := False;
      Is_Extended_Return     : Boolean := False;
      Is_No_Return_Subprogram : Boolean := False;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Fingerprint            : Natural := 0;
   end record;

   type Return_Legality_Info is record
      Id                     : Return_Legality_Id := No_Return_Legality;
      Context                : Return_Context_Id := No_Return_Context;
      Kind                   : Return_Context_Kind := Return_Context_Unknown;
      Unit_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Return_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Assignment_Context     : Assignment_Context_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Context;
      Assignment_Status      : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Status                 : Return_Legality_Status := Return_Legality_Not_Checked;
      Message                : Ada.Strings.Unbounded.Unbounded_String;
      Detail                 : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Has_Expression         : Boolean := False;
      Is_Function_Context    : Boolean := False;
      Is_Procedure_Context   : Boolean := False;
      Is_Extended_Return     : Boolean := False;
      Is_No_Return_Subprogram : Boolean := False;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Source_Fingerprint     : Natural := 0;
      Assignment_Fingerprint : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

   type Return_Context_Model is private;
   type Return_Legality_Result_Set is private;
   type Return_Legality_Model is private;

   procedure Clear (Model : in out Return_Context_Model);

   procedure Add_Context
     (Model   : in out Return_Context_Model;
      Context : Return_Context_Info);

   function Context_Count (Model : Return_Context_Model) return Natural;
   function Context_At
     (Model : Return_Context_Model;
      Index : Positive) return Return_Context_Info;
   function Fingerprint (Model : Return_Context_Model) return Natural;

   function Build_Contexts_From_Expected_Types
     (Expected    : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model)
      return Return_Context_Model;

   function Build
     (Contexts    : Return_Context_Model;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model)
      return Return_Legality_Model;

   function Legality_Count (Model : Return_Legality_Model) return Natural;
   function Legality_At
     (Model : Return_Legality_Model;
      Index : Positive) return Return_Legality_Info;

   function First_For_Context
     (Model   : Return_Legality_Model;
      Context : Return_Context_Id) return Return_Legality_Info;

   function First_For_Return_Node
     (Model : Return_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Return_Legality_Info;

   function First_For_Assignment_Context
     (Model   : Return_Legality_Model;
      Context : Assignment_Context_Id) return Return_Legality_Info;

   function Results_For_Status
     (Model  : Return_Legality_Model;
      Status : Return_Legality_Status) return Return_Legality_Result_Set;

   function Result_Count (Results : Return_Legality_Result_Set) return Natural;
   function Result_At
     (Results : Return_Legality_Result_Set;
      Index   : Positive) return Return_Legality_Info;

   function Count_Status
     (Model  : Return_Legality_Model;
      Status : Return_Legality_Status) return Natural;

   function Compatible_Count (Model : Return_Legality_Model) return Natural;
   function Error_Count (Model : Return_Legality_Model) return Natural;
   function Warning_Count (Model : Return_Legality_Model) return Natural;
   function Procedure_With_Expression_Count (Model : Return_Legality_Model) return Natural;
   function Function_Missing_Expression_Count (Model : Return_Legality_Model) return Natural;
   function No_Return_Subprogram_Return_Count (Model : Return_Legality_Model) return Natural;
   function Incompatible_Result_Count (Model : Return_Legality_Model) return Natural;
   function Private_View_Barrier_Count (Model : Return_Legality_Model) return Natural;
   function Limited_View_Barrier_Count (Model : Return_Legality_Model) return Natural;
   function Static_Range_Violation_Count (Model : Return_Legality_Model) return Natural;
   function Universal_Numeric_Unresolved_Count (Model : Return_Legality_Model) return Natural;

   function Has_Legality (Info : Return_Legality_Info) return Boolean;
   function Fingerprint (Model : Return_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Return_Context_Info);

   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Return_Legality_Info);

   type Return_Context_Model is record
      Items             : Context_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

   type Return_Legality_Result_Set is record
      Items       : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Return_Legality_Model is record
      Items                         : Legality_Vectors.Vector;
      Compatible_Total              : Natural := 0;
      Error_Total                   : Natural := 0;
      Warning_Total                 : Natural := 0;
      Procedure_With_Expression_Total : Natural := 0;
      Function_Missing_Expression_Total : Natural := 0;
      No_Return_Subprogram_Return_Total : Natural := 0;
      Incompatible_Result_Total     : Natural := 0;
      Private_View_Barrier_Total    : Natural := 0;
      Limited_View_Barrier_Total    : Natural := 0;
      Static_Range_Violation_Total  : Natural := 0;
      Universal_Numeric_Unresolved_Total : Natural := 0;
      Model_Fingerprint             : Natural := 0;
   end record;

end Editor.Ada_Return_Legality;
