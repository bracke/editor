with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Coverage_Gated_Semantic_Results is

   --  Pass1136 coverage-gated semantic conclusions.
   --
   --  This package attaches semantic coverage gate outcomes directly to the
   --  widened semantic result family that would otherwise have produced a
   --  confident legality result.  It preserves the original semantic family,
   --  construct, consumer, gate reason, source row, source span, and
   --  fingerprint so closure, diagnostics, and provenance can explain why a
   --  specific legality conclusion was allowed, degraded, suppressed, or
   --  blocked.
   --
   --  The model is deterministic and snapshot-owned.  It performs no parsing,
   --  file IO, save/reload, dirty-state mutation, command/keybinding/workspace
   --  mutation, render mutation, or compiler invocation.

   package Gates renames Editor.Ada_Semantic_Coverage_Gates;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   type Gated_Result_Id is new Natural;
   No_Gated_Result : constant Gated_Result_Id := 0;

   type Original_Result_State is
     (Original_Result_Not_Checked,
      Original_Result_Legal,
      Original_Result_Derived_Legal,
      Original_Result_Error,
      Original_Result_Indeterminate);

   type Gated_Result_Status is
     (Gated_Result_Not_Checked,
      Gated_Result_Confident,
      Gated_Result_Degraded_Indeterminate,
      Gated_Result_Legal_Suppressed,
      Gated_Result_Derived_Suppressed,
      Gated_Result_Cross_Unit_Required,
      Gated_Result_Parser_AST_Repair_Required,
      Gated_Result_Metadata_Repair_Required,
      Gated_Result_Consumer_Integration_Required,
      Gated_Result_Blocked_Unsafe,
      Gated_Result_Original_Error_Preserved);

   type Gated_Result_Context_Info is record
      Id                    : Gated_Result_Id := No_Gated_Result;
      Conclusion            : Gates.Semantic_Conclusion_Kind := Gates.Conclusion_Unknown;
      Original_State        : Original_Result_State := Original_Result_Legal;
      Construct             : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer              : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Gate_Status           : Gates.Gate_Status := Gates.Gate_Not_Checked;
      Gate_Action           : Gates.Gate_Action := Gates.Gate_Block_Unsafe_Result;
      Gate_Id               : Gates.Gate_Item_Id := Gates.No_Gate_Item;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Semantic_Row_Id       : Natural := 0;
      Construct_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Gate_Message          : Ada.Strings.Unbounded.Unbounded_String;
      Gate_Detail           : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint    : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
   end record;

   type Gated_Result_Info is record
      Id                    : Gated_Result_Id := No_Gated_Result;
      Conclusion            : Gates.Semantic_Conclusion_Kind := Gates.Conclusion_Unknown;
      Original_State        : Original_Result_State := Original_Result_Not_Checked;
      Construct             : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer              : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Status                : Gated_Result_Status := Gated_Result_Not_Checked;
      Gate_Status           : Gates.Gate_Status := Gates.Gate_Not_Checked;
      Gate_Action           : Gates.Gate_Action := Gates.Gate_Block_Unsafe_Result;
      Gate_Id               : Gates.Gate_Item_Id := Gates.No_Gate_Item;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Semantic_Row_Id       : Natural := 0;
      Construct_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint    : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Fingerprint           : Natural := 0;
   end record;

   type Gated_Result_Context_Model is private;
   type Gated_Result_Set is private;
   type Gated_Result_Model is private;

   procedure Clear (Model : in out Gated_Result_Context_Model);
   procedure Add_Context
     (Model   : in out Gated_Result_Context_Model;
      Context : Gated_Result_Context_Info);

   procedure Add_From_Gate
     (Model           : in out Gated_Result_Context_Model;
      Gate            : Gates.Gate_Info;
      Original_State  : Original_Result_State := Original_Result_Legal;
      Semantic_Row_Id : Natural := 0);

   function Build (Contexts : Gated_Result_Context_Model) return Gated_Result_Model;
   function Build_From_Gates
     (Gate_Model      : Gates.Gate_Model;
      Original_State  : Original_Result_State := Original_Result_Legal)
      return Gated_Result_Model;

   function Result_Count (Model : Gated_Result_Model) return Natural;
   function Result_At
     (Model : Gated_Result_Model;
      Index : Positive) return Gated_Result_Info;

   function First_For_Node
     (Model : Gated_Result_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Gated_Result_Info;
   function Rows_For_Status
     (Model  : Gated_Result_Model;
      Status : Gated_Result_Status) return Gated_Result_Set;
   function Rows_For_Conclusion
     (Model      : Gated_Result_Model;
      Conclusion : Gates.Semantic_Conclusion_Kind) return Gated_Result_Set;
   function Rows_For_Consumer
     (Model    : Gated_Result_Model;
      Consumer : Audit.Semantic_Consumer_Family) return Gated_Result_Set;

   function Set_Count (Set : Gated_Result_Set) return Natural;
   function Set_At
     (Set   : Gated_Result_Set;
      Index : Positive) return Gated_Result_Info;

   function Count_Status
     (Model  : Gated_Result_Model;
      Status : Gated_Result_Status) return Natural;
   function Count_Conclusion
     (Model      : Gated_Result_Model;
      Conclusion : Gates.Semantic_Conclusion_Kind) return Natural;
   function Count_Consumer
     (Model    : Gated_Result_Model;
      Consumer : Audit.Semantic_Consumer_Family) return Natural;

   function Confident_Count (Model : Gated_Result_Model) return Natural;
   function Suppressed_Count (Model : Gated_Result_Model) return Natural;
   function Degraded_Count (Model : Gated_Result_Model) return Natural;
   function Repair_Required_Count (Model : Gated_Result_Model) return Natural;
   function Cross_Unit_Required_Count (Model : Gated_Result_Model) return Natural;
   function Unsafe_Blocker_Count (Model : Gated_Result_Model) return Natural;
   function Original_Error_Count (Model : Gated_Result_Model) return Natural;
   function Fingerprint (Model : Gated_Result_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Gated_Result_Context_Info);
   package Info_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Gated_Result_Info);

   type Gated_Result_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Gated_Result_Set is record
      Items : Info_Vectors.Vector;
   end record;

   type Gated_Result_Model is record
      Items       : Info_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Coverage_Gated_Semantic_Results;
