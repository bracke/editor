with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Dispatching_Call_Legality is

   --  Deterministic dispatching-call legality model over expression-type
   --  metadata.  This package classifies already-built dispatching-call
   --  inference records into compiler-grade legality reasons without parsing,
   --  file IO, editor mutation, command registration, workspace mutation, or
   --  rendering work.

   subtype Expression_Info is Editor.Ada_Expression_Types.Expression_Type_Info;

   type Dispatching_Legality_Id is new Natural;
   No_Dispatching_Legality : constant Dispatching_Legality_Id := 0;

   type Dispatching_Legality_Status is
     (Dispatching_Legality_Not_Checked,
      Dispatching_Legality_Not_Dispatching_Call,
      Dispatching_Legality_Static_Binding,
      Dispatching_Legality_Dynamic_Dispatch,
      Dispatching_Legality_Controlling_Result,
      Dispatching_Legality_Primitive_Target,
      Dispatching_Legality_Target_Unresolved,
      Dispatching_Legality_Target_Ambiguous,
      Dispatching_Legality_Controlling_Unknown,
      Dispatching_Legality_Abstract_Unknown,
      Dispatching_Legality_Indeterminate);

   type Dispatching_Legality_Info is record
      Id          : Dispatching_Legality_Id := No_Dispatching_Legality;
      Expression  : Editor.Ada_Expression_Types.Expression_Type_Id :=
        Editor.Ada_Expression_Types.No_Expression_Type;
      Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status      : Dispatching_Legality_Status := Dispatching_Legality_Not_Checked;
      Source_Status : Editor.Ada_Expression_Types.Dispatching_Call_Inference_Status :=
        Editor.Ada_Expression_Types.Dispatching_Call_Not_Checked;
      Message     : Ada.Strings.Unbounded.Unbounded_String;
      Detail      : Ada.Strings.Unbounded.Unbounded_String;
      Controlling_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Controlling_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Primitive_Count : Natural := 0;
      Controlling_Operand_Count : Natural := 0;
      Controlling_Result_Count  : Natural := 0;
      Ambiguous_Count : Natural := 0;
      Unknown_Count   : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint  : Natural := 0;
   end record;

   type Dispatching_Legality_Result_Set is private;
   type Dispatching_Legality_Model is private;

   procedure Clear (Model : in out Dispatching_Legality_Model);

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Dispatching_Legality_Model;

   function Legality_Count (Model : Dispatching_Legality_Model) return Natural;
   function Legality_At
     (Model : Dispatching_Legality_Model;
      Index : Positive) return Dispatching_Legality_Info;

   function First_For_Expression
     (Model      : Dispatching_Legality_Model;
      Expression : Editor.Ada_Expression_Types.Expression_Type_Id)
      return Dispatching_Legality_Info;

   function First_For_Node
     (Model : Dispatching_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dispatching_Legality_Info;

   function Results_For_Node
     (Model : Dispatching_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dispatching_Legality_Result_Set;

   function Result_Count (Results : Dispatching_Legality_Result_Set) return Natural;
   function Result_At
     (Results : Dispatching_Legality_Result_Set;
      Index   : Positive) return Dispatching_Legality_Info;

   function Count_Status
     (Model  : Dispatching_Legality_Model;
      Status : Dispatching_Legality_Status) return Natural;

   function Resolved_Count (Model : Dispatching_Legality_Model) return Natural;
   function Dynamic_Count (Model : Dispatching_Legality_Model) return Natural;
   function Static_Count (Model : Dispatching_Legality_Model) return Natural;
   function Controlling_Result_Count (Model : Dispatching_Legality_Model) return Natural;
   function Primitive_Target_Count (Model : Dispatching_Legality_Model) return Natural;
   function Ambiguous_Count (Model : Dispatching_Legality_Model) return Natural;
   function Unresolved_Count (Model : Dispatching_Legality_Model) return Natural;
   function Unknown_Count (Model : Dispatching_Legality_Model) return Natural;
   function Error_Count (Model : Dispatching_Legality_Model) return Natural;
   function Warning_Count (Model : Dispatching_Legality_Model) return Natural;
   function Info_Count (Model : Dispatching_Legality_Model) return Natural;

   function Has_Legality (Info : Dispatching_Legality_Info) return Boolean;
   function Fingerprint (Model : Dispatching_Legality_Model) return Natural;

private
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Dispatching_Legality_Info);

   type Dispatching_Legality_Result_Set is record
      Items       : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Dispatching_Legality_Model is record
      Items             : Legality_Vectors.Vector;
      Resolved_Total    : Natural := 0;
      Dynamic_Total     : Natural := 0;
      Static_Total      : Natural := 0;
      Controlling_Result_Total : Natural := 0;
      Primitive_Target_Total   : Natural := 0;
      Ambiguous_Total   : Natural := 0;
      Unresolved_Total  : Natural := 0;
      Unknown_Total     : Natural := 0;
      Error_Total       : Natural := 0;
      Warning_Total     : Natural := 0;
      Info_Total        : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Dispatching_Call_Legality;
