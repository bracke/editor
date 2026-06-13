with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_AST_Coverage_Repair_Legality is

   --  Pass1147 compiler-grade parser/AST coverage repair legality.
   --
   --  Pass1132 through Pass1136 made parser/AST coverage visible, gated, and
   --  diagnosable.  This package is the repair-side semantic model: it records
   --  concrete Ada 2022 grammar/AST/metadata/consumer repairs and proves which
   --  formerly gated constructs can now feed widened legality engines safely.
   --  It remains snapshot-owned and deterministic.  It performs no file IO, no
   --  rendering-side parsing, no dirty-state mutation, no command/keybinding/
   --  workspace/render mutation, no compiler invocation, and no external parser
   --  generation.

   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;
   package Gates renames Editor.Ada_Semantic_Coverage_Gates;

   type Repair_Item_Id is new Natural;
   No_Repair_Item : constant Repair_Item_Id := 0;

   type Repair_Kind is
     (Repair_Parser_Node,
      Repair_Structural_AST,
      Repair_Source_Span,
      Repair_Name_Binding_Metadata,
      Repair_Type_Metadata,
      Repair_Staticness_Metadata,
      Repair_Contract_Metadata,
      Repair_Flow_Metadata,
      Repair_Representation_Metadata,
      Repair_Cross_Unit_Metadata,
      Repair_Semantic_Consumer,
      Repair_Consumer_Integration,
      Repair_Token_Only_Replacement,
      Repair_Degradation_Replacement,
      Repair_Combined_Construct_Coverage,
      Repair_Unknown);

   type Repair_Status is
     (Repair_Not_Checked,
      Repair_Complete,
      Repair_Parser_Node_Repaired,
      Repair_Structural_AST_Repaired,
      Repair_Source_Span_Repaired,
      Repair_Metadata_Repaired,
      Repair_Cross_Unit_Metadata_Repaired,
      Repair_Consumer_Repaired,
      Repair_Consumer_Integrated,
      Repair_Token_Only_Replaced,
      Repair_Degradation_Replaced,
      Repair_Gate_Cleared,
      Repair_Audit_Already_Complete,
      Repair_Parser_Node_Still_Missing,
      Repair_Structural_AST_Still_Missing,
      Repair_Source_Span_Still_Missing,
      Repair_Metadata_Still_Missing,
      Repair_Cross_Unit_Metadata_Still_Missing,
      Repair_Consumer_Still_Missing,
      Repair_Consumer_Still_Not_Integrated,
      Repair_Token_Only_Still_Present,
      Repair_Degradation_Still_Only_Path,
      Repair_Gate_Still_Blocking,
      Repair_Inconsistent_Repair,
      Repair_Indeterminate);

   type Repair_Context_Info is record
      Id                         : Repair_Item_Id := No_Repair_Item;
      Kind                       : Repair_Kind := Repair_Unknown;
      Construct                  : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer                   : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Construct_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Before_Coverage            : Audit.Coverage_Status := Audit.Coverage_Not_Checked;
      Before_Gate                : Gates.Gate_Status := Gates.Gate_Not_Checked;
      Parser_Node_Repaired       : Boolean := False;
      Structural_AST_Repaired    : Boolean := False;
      Source_Span_Repaired       : Boolean := False;
      Name_Binding_Repaired      : Boolean := False;
      Type_Metadata_Repaired     : Boolean := False;
      Staticness_Metadata_Repaired : Boolean := False;
      Contract_Metadata_Repaired : Boolean := False;
      Flow_Metadata_Repaired     : Boolean := False;
      Representation_Metadata_Repaired : Boolean := False;
      Cross_Unit_Metadata_Repaired : Boolean := False;
      Consumer_Repaired          : Boolean := False;
      Consumer_Integrated        : Boolean := False;
      Token_Only_Replaced        : Boolean := False;
      Degradation_Replaced       : Boolean := False;
      Gate_Cleared               : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Repair_Info is record
      Id                         : Repair_Item_Id := No_Repair_Item;
      Kind                       : Repair_Kind := Repair_Unknown;
      Construct                  : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer                   : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                     : Repair_Status := Repair_Not_Checked;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Construct_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Repair_Context_Model is private;
   type Repair_Model is private;
   type Repair_Result_Set is private;

   procedure Clear (Model : in out Repair_Context_Model);
   procedure Add_Context
     (Model   : in out Repair_Context_Model;
      Context : Repair_Context_Info);

   procedure Add_From_Audit
     (Model     : in out Repair_Context_Model;
      Coverage  : Audit.Coverage_Info;
      Gate      : Gates.Gate_Info;
      Kind      : Repair_Kind);

   function Build (Contexts : Repair_Context_Model) return Repair_Model;
   function Build_From_Audit
     (Coverage : Audit.Coverage_Model;
      Gate_Data : Gates.Gate_Model) return Repair_Model;

   function Context_Count (Model : Repair_Context_Model) return Natural;
   function Repair_Count (Model : Repair_Model) return Natural;
   function Repair_At (Model : Repair_Model; Index : Positive) return Repair_Info;

   function First_For_Node
     (Model : Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Repair_Info;
   function Rows_For_Status
     (Model  : Repair_Model;
      Status : Repair_Status) return Repair_Result_Set;
   function Rows_For_Construct
     (Model     : Repair_Model;
      Construct : Audit.Ada_Construct_Kind) return Repair_Result_Set;
   function Rows_For_Consumer
     (Model    : Repair_Model;
      Consumer : Audit.Semantic_Consumer_Family) return Repair_Result_Set;
   function Rows_For_Kind
     (Model : Repair_Model;
      Kind  : Repair_Kind) return Repair_Result_Set;

   function Result_Count (Results : Repair_Result_Set) return Natural;
   function Result_At
     (Results : Repair_Result_Set;
      Index   : Positive) return Repair_Info;

   function Count_Status (Model : Repair_Model; Status : Repair_Status) return Natural;
   function Count_Kind (Model : Repair_Model; Kind : Repair_Kind) return Natural;
   function Count_Construct
     (Model : Repair_Model; Construct : Audit.Ada_Construct_Kind) return Natural;
   function Count_Consumer
     (Model : Repair_Model; Consumer : Audit.Semantic_Consumer_Family) return Natural;

   function Repaired_Count (Model : Repair_Model) return Natural;
   function Still_Missing_Count (Model : Repair_Model) return Natural;
   function Metadata_Repair_Count (Model : Repair_Model) return Natural;
   function Consumer_Repair_Count (Model : Repair_Model) return Natural;
   function Gate_Cleared_Count (Model : Repair_Model) return Natural;
   function Indeterminate_Count (Model : Repair_Model) return Natural;
   function Fingerprint (Model : Repair_Model) return Natural;

   function Is_Repaired (Status : Repair_Status) return Boolean;
   function Has_Error (Info : Repair_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Repair_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Repair_Info);

   type Repair_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Repair_Result_Set is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Repair_Model is record
      Items : Result_Vectors.Vector;
      Repaired_Total : Natural := 0;
      Still_Missing_Total : Natural := 0;
      Metadata_Repair_Total : Natural := 0;
      Consumer_Repair_Total : Natural := 0;
      Gate_Cleared_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_AST_Coverage_Repair_Legality;
