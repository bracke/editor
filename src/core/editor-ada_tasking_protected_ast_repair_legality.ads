with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Tasking_Protected_AST_Repair_Legality is

   --  Case 1173 task/protected/select parser-AST repair legality.
   --
   --  This package turns the generic repaired-coverage facts from Case 1147
   --  into concrete tasking/protected/select construct repair facts.  It is a
   --  semantic gate-clearance model for task types and bodies, protected types
   --  and bodies, entry declarations and bodies, accept/requeue statements, and
   --  select statements.  A construct is not considered confidently restored
   --  until the parser node, structural AST shape, source span, required flow
   --  metadata, and integrated tasking/protected consumer evidence are present.

   package Repair renames Editor.Ada_AST_Coverage_Repair_Legality;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   type Tasking_AST_Repair_Row_Id is new Natural;
   No_Tasking_AST_Repair_Row : constant Tasking_AST_Repair_Row_Id := 0;

   type Tasking_AST_Construct_Kind is
     (Tasking_AST_Task_Type,
      Tasking_AST_Task_Body,
      Tasking_AST_Protected_Type,
      Tasking_AST_Protected_Body,
      Tasking_AST_Entry_Declaration,
      Tasking_AST_Entry_Body,
      Tasking_AST_Accept_Statement,
      Tasking_AST_Requeue_Statement,
      Tasking_AST_Select_Statement,
      Tasking_AST_Unknown);

   type Tasking_AST_Repair_Status is
     (Tasking_AST_Not_Checked,
      Tasking_AST_Legal_Task_Type_Repaired,
      Tasking_AST_Legal_Task_Body_Repaired,
      Tasking_AST_Legal_Protected_Type_Repaired,
      Tasking_AST_Legal_Protected_Body_Repaired,
      Tasking_AST_Legal_Entry_Declaration_Repaired,
      Tasking_AST_Legal_Entry_Body_Repaired,
      Tasking_AST_Legal_Accept_Statement_Repaired,
      Tasking_AST_Legal_Requeue_Statement_Repaired,
      Tasking_AST_Legal_Select_Statement_Repaired,
      Tasking_AST_Parser_Node_Still_Missing,
      Tasking_AST_Structural_AST_Still_Missing,
      Tasking_AST_Source_Span_Still_Missing,
      Tasking_AST_Flow_Metadata_Still_Missing,
      Tasking_AST_Contract_Metadata_Still_Missing,
      Tasking_AST_Representation_Metadata_Still_Missing,
      Tasking_AST_Cross_Unit_Metadata_Still_Missing,
      Tasking_AST_Consumer_Still_Missing,
      Tasking_AST_Consumer_Still_Not_Integrated,
      Tasking_AST_Token_Only_Parse_Still_Present,
      Tasking_AST_Degradation_Only_Path_Still_Present,
      Tasking_AST_Repair_Mismatch,
      Tasking_AST_Multiple_Repair_Blockers,
      Tasking_AST_Indeterminate);

   type Tasking_AST_Repair_Context_Info is record
      Id                         : Tasking_AST_Repair_Row_Id := No_Tasking_AST_Repair_Row;
      Construct                  : Tasking_AST_Construct_Kind := Tasking_AST_Unknown;
      Audit_Construct            : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer                   : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Construct_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Parser_Node_Repaired       : Boolean := False;
      Structural_AST_Repaired    : Boolean := False;
      Source_Span_Repaired       : Boolean := False;
      Contract_Metadata_Repaired : Boolean := False;
      Flow_Metadata_Repaired     : Boolean := False;
      Representation_Metadata_Repaired : Boolean := False;
      Cross_Unit_Metadata_Repaired : Boolean := False;
      Consumer_Repaired          : Boolean := False;
      Consumer_Integrated        : Boolean := False;
      Token_Only_Replaced        : Boolean := False;
      Degradation_Replaced       : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Tasking_AST_Repair_Info is record
      Id                         : Tasking_AST_Repair_Row_Id := No_Tasking_AST_Repair_Row;
      Construct                  : Tasking_AST_Construct_Kind := Tasking_AST_Unknown;
      Audit_Construct            : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer                   : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                     : Tasking_AST_Repair_Status := Tasking_AST_Not_Checked;
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

   type Tasking_AST_Repair_Context_Model is private;
   type Tasking_AST_Repair_Model is private;
   type Tasking_AST_Repair_Result_Set is private;

   procedure Clear (Model : in out Tasking_AST_Repair_Context_Model);
   procedure Add_Context
     (Model   : in out Tasking_AST_Repair_Context_Model;
      Context : Tasking_AST_Repair_Context_Info);

   function Build
     (Contexts : Tasking_AST_Repair_Context_Model)
      return Tasking_AST_Repair_Model;
   function Build_From_Repairs
     (Repairs : Repair.Repair_Model) return Tasking_AST_Repair_Model;

   function Context_Count (Model : Tasking_AST_Repair_Context_Model) return Natural;
   function Row_Count (Model : Tasking_AST_Repair_Model) return Natural;
   function Row_At
     (Model : Tasking_AST_Repair_Model;
      Index : Positive) return Tasking_AST_Repair_Info;

   function First_For_Node
     (Model : Tasking_AST_Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_AST_Repair_Info;
   function Rows_For_Status
     (Model  : Tasking_AST_Repair_Model;
      Status : Tasking_AST_Repair_Status) return Tasking_AST_Repair_Result_Set;
   function Rows_For_Construct
     (Model     : Tasking_AST_Repair_Model;
      Construct : Tasking_AST_Construct_Kind) return Tasking_AST_Repair_Result_Set;

   function Result_Count (Results : Tasking_AST_Repair_Result_Set) return Natural;
   function Result_At
     (Results : Tasking_AST_Repair_Result_Set;
      Index   : Positive) return Tasking_AST_Repair_Info;

   function Count_Status
     (Model : Tasking_AST_Repair_Model;
      Status : Tasking_AST_Repair_Status) return Natural;
   function Count_Construct
     (Model : Tasking_AST_Repair_Model;
      Construct : Tasking_AST_Construct_Kind) return Natural;

   function Accepted_Count (Model : Tasking_AST_Repair_Model) return Natural;
   function Blocker_Count (Model : Tasking_AST_Repair_Model) return Natural;
   function Indeterminate_Count (Model : Tasking_AST_Repair_Model) return Natural;
   function Fingerprint (Model : Tasking_AST_Repair_Model) return Natural;

   function Is_Tasking_Construct
     (Construct : Audit.Ada_Construct_Kind) return Boolean;
   function Is_Accepted (Status : Tasking_AST_Repair_Status) return Boolean;
   function Has_Error (Info : Tasking_AST_Repair_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_AST_Repair_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_AST_Repair_Info);

   type Tasking_AST_Repair_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Tasking_AST_Repair_Result_Set is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Tasking_AST_Repair_Model is record
      Items : Result_Vectors.Vector;
      Accepted_Total : Natural := 0;
      Blocker_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tasking_Protected_AST_Repair_Legality;
