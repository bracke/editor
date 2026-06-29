with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Dispatching_Call_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Tagged_Derived_Legality is

   --  Wide compiler-grade semantic legality building block for Pass1104.
   --  This package covers tagged, derived, private-extension, interface,
   --  overriding, inherited primitive, class-wide conversion, and dispatching
   --  legality above the expression/assignment/return/dispatching layers.  It
   --  is snapshot-owned and fixture-friendly: callers provide resolved semantic
   --  facts and this package performs no parsing, file IO, editor mutation,
   --  command/keybinding/workspace mutation, or render-side work.

   type Tagged_Context_Id is new Natural;
   No_Tagged_Context : constant Tagged_Context_Id := 0;

   type Tagged_Legality_Id is new Natural;
   No_Tagged_Legality : constant Tagged_Legality_Id := 0;

   type Tagged_Context_Kind is
     (Tagged_Context_Type_Derivation,
      Tagged_Context_Private_Extension,
      Tagged_Context_Interface_Derivation,
      Tagged_Context_Primitive_Operation,
      Tagged_Context_Overriding_Declaration,
      Tagged_Context_Abstract_Type,
      Tagged_Context_Dispatching_Call,
      Tagged_Context_Class_Wide_Conversion,
      Tagged_Context_Interface_Operation,
      Tagged_Context_Unknown);

   type Tagged_Legality_Status is
     (Tagged_Legality_Not_Checked,
      Tagged_Legality_Legal_Derivation,
      Tagged_Legality_Legal_Private_Extension,
      Tagged_Legality_Legal_Interface_Derivation,
      Tagged_Legality_Legal_Primitive_Operation,
      Tagged_Legality_Legal_Override,
      Tagged_Legality_Legal_Abstract_Type,
      Tagged_Legality_Legal_Dispatching_Call,
      Tagged_Legality_Legal_Class_Wide_Conversion,
      Tagged_Legality_Parent_Unresolved,
      Tagged_Legality_Parent_Not_Tagged,
      Tagged_Legality_Parent_Limited_Mismatch,
      Tagged_Legality_Private_View_Barrier,
      Tagged_Legality_Limited_View_Barrier,
      Tagged_Legality_Interface_Missing_Operation,
      Tagged_Legality_Interface_Profile_Mismatch,
      Tagged_Legality_Duplicate_Inherited_Primitive,
      Tagged_Legality_Overriding_Missing,
      Tagged_Legality_Override_Not_Primitive,
      Tagged_Legality_Override_Profile_Mismatch,
      Tagged_Legality_Override_Mode_Mismatch,
      Tagged_Legality_Override_Result_Mismatch,
      Tagged_Legality_Abstract_Operation_Not_Overridden,
      Tagged_Legality_Nonabstract_Type_Has_Abstract_Operation,
      Tagged_Legality_Dispatching_Target_Unresolved,
      Tagged_Legality_Dispatching_Target_Ambiguous,
      Tagged_Legality_Dispatching_Target_Not_Dispatching,
      Tagged_Legality_Controlling_Operand_Missing,
      Tagged_Legality_Controlling_Result_Ambiguous,
      Tagged_Legality_Class_Wide_Conversion_Incompatible,
      Tagged_Legality_Assignment_Legality_Error,
      Tagged_Legality_Return_Legality_Error,
      Tagged_Legality_Indeterminate);

   type Tagged_Context_Info is record
      Id                  : Tagged_Context_Id := No_Tagged_Context;
      Kind                : Tagged_Context_Kind := Tagged_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dispatch_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Type_Name : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Parent_Name : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Operation_Name : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Resolved     : Boolean := True;
      Parent_Is_Tagged    : Boolean := True;
      Parent_Is_Limited   : Boolean := False;
      Derived_Is_Limited  : Boolean := False;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Interface_Operation_Present : Boolean := True;
      Interface_Profile_Matches : Boolean := True;
      Duplicate_Inherited_Primitive : Boolean := False;
      Requires_Overriding : Boolean := False;
      Overriding_Present  : Boolean := True;
      Override_Is_Primitive : Boolean := True;
      Override_Profile_Matches : Boolean := True;
      Override_Mode_Matches : Boolean := True;
      Override_Result_Matches : Boolean := True;
      Type_Is_Abstract    : Boolean := False;
      Operation_Is_Abstract : Boolean := False;
      Abstract_Operation_Overridden : Boolean := True;
      Controlling_Operand_Present : Boolean := True;
      Controlling_Result_Ambiguous : Boolean := False;
      Class_Wide_Conversion_Compatible : Boolean := True;
      Linked_Assignment   : Editor.Ada_Assignment_Legality.Assignment_Context_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Context;
      Linked_Return       : Editor.Ada_Return_Legality.Return_Context_Id :=
        Editor.Ada_Return_Legality.No_Return_Context;
      Linked_Dispatch_Expression : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Id :=
        Editor.Ada_Dispatching_Call_Legality.No_Dispatching_Legality;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Tagged_Legality_Info is record
      Id                  : Tagged_Legality_Id := No_Tagged_Legality;
      Context             : Tagged_Context_Id := No_Tagged_Context;
      Kind                : Tagged_Context_Kind := Tagged_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dispatch_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status              : Tagged_Legality_Status := Tagged_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Type_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Parent_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Operation_Name : Ada.Strings.Unbounded.Unbounded_String;
      Linked_Assignment   : Editor.Ada_Assignment_Legality.Assignment_Context_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Context;
      Linked_Return       : Editor.Ada_Return_Legality.Return_Context_Id :=
        Editor.Ada_Return_Legality.No_Return_Context;
      Linked_Dispatch_Expression : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Id :=
        Editor.Ada_Dispatching_Call_Legality.No_Dispatching_Legality;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Tagged_Context_Model is private;
   type Tagged_Result_Set is private;
   type Tagged_Legality_Model is private;

   procedure Clear (Model : in out Tagged_Context_Model);
   procedure Add_Context
     (Model   : in out Tagged_Context_Model;
      Context : Tagged_Context_Info);

   function Context_Count (Model : Tagged_Context_Model) return Natural;
   function Context_At
     (Model : Tagged_Context_Model;
      Index : Positive) return Tagged_Context_Info;
   function Fingerprint (Model : Tagged_Context_Model) return Natural;

   function Build_Contexts_From_Syntax
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Dispatching : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model)
      return Tagged_Context_Model;

   function Build
     (Contexts    : Tagged_Context_Model;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Dispatching : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model)
      return Tagged_Legality_Model;

   function Legality_Count (Model : Tagged_Legality_Model) return Natural;
   function Legality_At
     (Model : Tagged_Legality_Model;
      Index : Positive) return Tagged_Legality_Info;

   function First_For_Context
     (Model   : Tagged_Legality_Model;
      Context : Tagged_Context_Id) return Tagged_Legality_Info;
   function First_For_Node
     (Model : Tagged_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tagged_Legality_Info;
   function Rows_For_Status
     (Model  : Tagged_Legality_Model;
      Status : Tagged_Legality_Status) return Tagged_Result_Set;
   function Rows_For_Kind
     (Model : Tagged_Legality_Model;
      Kind  : Tagged_Context_Kind) return Tagged_Result_Set;
   function Rows_For_Type
     (Model : Tagged_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Tagged_Result_Set;
   function Rows_For_Operation
     (Model : Tagged_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Tagged_Result_Set;

   function Result_Count (Results : Tagged_Result_Set) return Natural;
   function Result_At
     (Results : Tagged_Result_Set;
      Index   : Positive) return Tagged_Legality_Info;

   function Count_Status
     (Model  : Tagged_Legality_Model;
      Status : Tagged_Legality_Status) return Natural;
   function Count_Kind
     (Model : Tagged_Legality_Model;
      Kind  : Tagged_Context_Kind) return Natural;

   function Compatible_Count (Model : Tagged_Legality_Model) return Natural;
   function Error_Count (Model : Tagged_Legality_Model) return Natural;
   function Warning_Count (Model : Tagged_Legality_Model) return Natural;
   function Info_Count (Model : Tagged_Legality_Model) return Natural;
   function Parent_Error_Count (Model : Tagged_Legality_Model) return Natural;
   function Override_Error_Count (Model : Tagged_Legality_Model) return Natural;
   function Interface_Error_Count (Model : Tagged_Legality_Model) return Natural;
   function Dispatching_Error_Count (Model : Tagged_Legality_Model) return Natural;
   function Abstract_Error_Count (Model : Tagged_Legality_Model) return Natural;
   function Linked_Semantic_Error_Count (Model : Tagged_Legality_Model) return Natural;
   function Has_Legality (Info : Tagged_Legality_Info) return Boolean;
   function Fingerprint (Model : Tagged_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tagged_Context_Info);

   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tagged_Legality_Info);

   type Tagged_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Tagged_Result_Set is record
      Items       : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Tagged_Legality_Model is record
      Items             : Legality_Vectors.Vector;
      Compatible_Total  : Natural := 0;
      Error_Total       : Natural := 0;
      Warning_Total     : Natural := 0;
      Info_Total        : Natural := 0;
      Parent_Error_Total : Natural := 0;
      Override_Error_Total : Natural := 0;
      Interface_Error_Total : Natural := 0;
      Dispatching_Error_Total : Natural := 0;
      Abstract_Error_Total : Natural := 0;
      Linked_Semantic_Error_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tagged_Derived_Legality;
