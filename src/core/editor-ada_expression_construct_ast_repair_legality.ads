with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Expression_Construct_AST_Repair_Legality is

   --  Case 1178 expression construct parser-AST repair legality.
   --
   --  This package turns the repaired-coverage facts from Case 1147 into
   --  concrete expression construct repair facts.  Container aggregates, delta aggregates, reduction expressions, and quantified expressions are not treated as restored until parser nodes,
   --  structural AST, spans, name/type/flow/representation metadata,
   --  cross-unit metadata,
   --  and integrated expression typing, overload, predicate, contract, flow, and aggregate consumers are all present.

   package Repair renames Editor.Ada_AST_Coverage_Repair_Legality;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   type Expression_Construct_AST_Repair_Row_Id is new Natural;
   No_Expression_Construct_AST_Repair_Row : constant Expression_Construct_AST_Repair_Row_Id := 0;

   type Expression_Construct_AST_Construct_Kind is
     (Expression_Construct_AST_Container_Aggregate,
      Expression_Construct_AST_Delta_Aggregate,
      Expression_Construct_AST_Reduction_Expression,
      Expression_Construct_AST_Quantified_Expression,
      Expression_Construct_AST_Unknown);

   type Expression_Construct_AST_Repair_Status is
     (Expression_Construct_AST_Not_Checked,
      Expression_Construct_AST_Legal_Container_Aggregate_Repaired,
      Expression_Construct_AST_Legal_Delta_Aggregate_Repaired,
      Expression_Construct_AST_Legal_Reduction_Expression_Repaired,
      Expression_Construct_AST_Legal_Quantified_Expression_Repaired,
      Expression_Construct_AST_Parser_Node_Still_Missing,
      Expression_Construct_AST_Structural_AST_Still_Missing,
      Expression_Construct_AST_Source_Span_Still_Missing,
      Expression_Construct_AST_Name_Binding_Still_Missing,
      Expression_Construct_AST_Type_Metadata_Still_Missing,
      Expression_Construct_AST_Staticness_Metadata_Still_Missing,
      Expression_Construct_AST_Contract_Metadata_Still_Missing,
      Expression_Construct_AST_Flow_Metadata_Still_Missing,
      Expression_Construct_AST_Representation_Metadata_Still_Missing,
      Expression_Construct_AST_Cross_Unit_Metadata_Still_Missing,
      Expression_Construct_AST_Consumer_Still_Missing,
      Expression_Construct_AST_Consumer_Still_Not_Integrated,
      Expression_Construct_AST_Token_Only_Parse_Still_Present,
      Expression_Construct_AST_Degradation_Only_Path_Still_Present,
      Expression_Construct_AST_Repair_Mismatch,
      Expression_Construct_AST_Multiple_Repair_Blockers,
      Expression_Construct_AST_Indeterminate);

   type Expression_Construct_AST_Repair_Context_Info is record
      Id                            : Expression_Construct_AST_Repair_Row_Id := No_Expression_Construct_AST_Repair_Row;
      Construct                     : Expression_Construct_AST_Construct_Kind := Expression_Construct_AST_Unknown;
      Audit_Construct               : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer                      : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Construct_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Parser_Node_Repaired          : Boolean := False;
      Structural_AST_Repaired       : Boolean := False;
      Source_Span_Repaired          : Boolean := False;
      Name_Binding_Repaired         : Boolean := False;
      Type_Metadata_Repaired        : Boolean := False;
      Staticness_Metadata_Repaired  : Boolean := False;
      Contract_Metadata_Repaired    : Boolean := False;
      Flow_Metadata_Repaired        : Boolean := False;
      Representation_Metadata_Repaired : Boolean := False;
      Cross_Unit_Metadata_Repaired  : Boolean := False;
      Consumer_Repaired             : Boolean := False;
      Consumer_Integrated           : Boolean := False;
      Token_Only_Replaced           : Boolean := False;
      Degradation_Replaced          : Boolean := False;
      Source_Fingerprint            : Natural := 0;
      Start_Line                    : Positive := 1;
      Start_Column                  : Positive := 1;
      End_Line                      : Positive := 1;
      End_Column                    : Positive := 1;
   end record;

   type Expression_Construct_AST_Repair_Info is record
      Id                            : Expression_Construct_AST_Repair_Row_Id := No_Expression_Construct_AST_Repair_Row;
      Construct                     : Expression_Construct_AST_Construct_Kind := Expression_Construct_AST_Unknown;
      Audit_Construct               : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer                      : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                        : Expression_Construct_AST_Repair_Status := Expression_Construct_AST_Not_Checked;
      Construct_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Construct_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Message                       : Ada.Strings.Unbounded.Unbounded_String;
      Detail                        : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint            : Natural := 0;
      Fingerprint                   : Natural := 0;
      Start_Line                    : Positive := 1;
      Start_Column                  : Positive := 1;
      End_Line                      : Positive := 1;
      End_Column                    : Positive := 1;
   end record;

   type Expression_Construct_AST_Repair_Context_Model is private;
   type Expression_Construct_AST_Repair_Model is private;
   type Expression_Construct_AST_Repair_Result_Set is private;

   procedure Clear (Model : in out Expression_Construct_AST_Repair_Context_Model);
   procedure Add_Context
     (Model   : in out Expression_Construct_AST_Repair_Context_Model;
      Context : Expression_Construct_AST_Repair_Context_Info);

   function Build
     (Contexts : Expression_Construct_AST_Repair_Context_Model)
      return Expression_Construct_AST_Repair_Model;
   function Build_From_Repairs
     (Repairs : Repair.Repair_Model) return Expression_Construct_AST_Repair_Model;

   function Context_Count (Model : Expression_Construct_AST_Repair_Context_Model) return Natural;
   function Row_Count (Model : Expression_Construct_AST_Repair_Model) return Natural;
   function Row_At
     (Model : Expression_Construct_AST_Repair_Model;
      Index : Positive) return Expression_Construct_AST_Repair_Info;

   function First_For_Node
     (Model : Expression_Construct_AST_Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expression_Construct_AST_Repair_Info;
   function Rows_For_Status
     (Model  : Expression_Construct_AST_Repair_Model;
      Status : Expression_Construct_AST_Repair_Status) return Expression_Construct_AST_Repair_Result_Set;
   function Rows_For_Construct
     (Model     : Expression_Construct_AST_Repair_Model;
      Construct : Expression_Construct_AST_Construct_Kind) return Expression_Construct_AST_Repair_Result_Set;

   function Result_Count (Results : Expression_Construct_AST_Repair_Result_Set) return Natural;
   function Result_At
     (Results : Expression_Construct_AST_Repair_Result_Set;
      Index   : Positive) return Expression_Construct_AST_Repair_Info;

   function Count_Status
     (Model : Expression_Construct_AST_Repair_Model;
      Status : Expression_Construct_AST_Repair_Status) return Natural;
   function Count_Construct
     (Model : Expression_Construct_AST_Repair_Model;
      Construct : Expression_Construct_AST_Construct_Kind) return Natural;

   function Accepted_Count (Model : Expression_Construct_AST_Repair_Model) return Natural;
   function Blocker_Count (Model : Expression_Construct_AST_Repair_Model) return Natural;
   function Indeterminate_Count (Model : Expression_Construct_AST_Repair_Model) return Natural;
   function Fingerprint (Model : Expression_Construct_AST_Repair_Model) return Natural;

   function Is_Expression_Construct_Construct
     (Construct : Audit.Ada_Construct_Kind) return Boolean;
   function Is_Accepted (Status : Expression_Construct_AST_Repair_Status) return Boolean;
   function Has_Error (Info : Expression_Construct_AST_Repair_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Expression_Construct_AST_Repair_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Expression_Construct_AST_Repair_Info);

   type Expression_Construct_AST_Repair_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Expression_Construct_AST_Repair_Result_Set is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Expression_Construct_AST_Repair_Model is record
      Items : Result_Vectors.Vector;
      Accepted_Total : Natural := 0;
      Blocker_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Expression_Construct_AST_Repair_Legality;
