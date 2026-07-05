with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Discriminant_Variant_AST_Repair_Legality is

   --  Case 1177 discriminant/variant parser-AST repair legality.
   --
   --  This package turns the repaired-coverage facts from Case 1147 into
   --  concrete discriminant/variant repair facts.  Discriminant specifications,
   --  variant parts, discriminant-dependent aggregates, and private/full-view
   --  discriminant views are not treated as restored until parser nodes,
   --  structural AST, spans, name/type/flow/representation metadata,
   --  cross-unit metadata,
   --  and integrated discriminant/aggregate/accessibility/representation consumers are all present.

   package Repair renames Editor.Ada_AST_Coverage_Repair_Legality;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   type Discriminant_Variant_AST_Repair_Row_Id is new Natural;
   No_Discriminant_Variant_AST_Repair_Row : constant Discriminant_Variant_AST_Repair_Row_Id := 0;

   type Discriminant_Variant_AST_Construct_Kind is
     (Discriminant_Variant_AST_Discriminant_Specification,
      Discriminant_Variant_AST_Variant_Part,
      Discriminant_Variant_AST_Discriminant_Dependent_Aggregate,
      Discriminant_Variant_AST_Private_Full_View,
      Discriminant_Variant_AST_Unknown);

   type Discriminant_Variant_AST_Repair_Status is
     (Discriminant_Variant_AST_Not_Checked,
      Discriminant_Variant_AST_Legal_Discriminant_Specification_Repaired,
      Discriminant_Variant_AST_Legal_Variant_Part_Repaired,
      Discriminant_Variant_AST_Legal_Discriminant_Dependent_Aggregate_Repaired,
      Discriminant_Variant_AST_Legal_Private_Full_View_Repaired,
      Discriminant_Variant_AST_Parser_Node_Still_Missing,
      Discriminant_Variant_AST_Structural_AST_Still_Missing,
      Discriminant_Variant_AST_Source_Span_Still_Missing,
      Discriminant_Variant_AST_Name_Binding_Still_Missing,
      Discriminant_Variant_AST_Type_Metadata_Still_Missing,
      Discriminant_Variant_AST_Staticness_Metadata_Still_Missing,
      Discriminant_Variant_AST_Contract_Metadata_Still_Missing,
      Discriminant_Variant_AST_Flow_Metadata_Still_Missing,
      Discriminant_Variant_AST_Representation_Metadata_Still_Missing,
      Discriminant_Variant_AST_Cross_Unit_Metadata_Still_Missing,
      Discriminant_Variant_AST_Consumer_Still_Missing,
      Discriminant_Variant_AST_Consumer_Still_Not_Integrated,
      Discriminant_Variant_AST_Token_Only_Parse_Still_Present,
      Discriminant_Variant_AST_Degradation_Only_Path_Still_Present,
      Discriminant_Variant_AST_Repair_Mismatch,
      Discriminant_Variant_AST_Multiple_Repair_Blockers,
      Discriminant_Variant_AST_Indeterminate);

   type Discriminant_Variant_AST_Repair_Context_Info is record
      Id                            : Discriminant_Variant_AST_Repair_Row_Id := No_Discriminant_Variant_AST_Repair_Row;
      Construct                     : Discriminant_Variant_AST_Construct_Kind := Discriminant_Variant_AST_Unknown;
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

   type Discriminant_Variant_AST_Repair_Info is record
      Id                            : Discriminant_Variant_AST_Repair_Row_Id := No_Discriminant_Variant_AST_Repair_Row;
      Construct                     : Discriminant_Variant_AST_Construct_Kind := Discriminant_Variant_AST_Unknown;
      Audit_Construct               : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer                      : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                        : Discriminant_Variant_AST_Repair_Status := Discriminant_Variant_AST_Not_Checked;
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

   type Discriminant_Variant_AST_Repair_Context_Model is private;
   type Discriminant_Variant_AST_Repair_Model is private;
   type Discriminant_Variant_AST_Repair_Result_Set is private;

   procedure Clear (Model : in out Discriminant_Variant_AST_Repair_Context_Model);
   procedure Add_Context
     (Model   : in out Discriminant_Variant_AST_Repair_Context_Model;
      Context : Discriminant_Variant_AST_Repair_Context_Info);

   function Build
     (Contexts : Discriminant_Variant_AST_Repair_Context_Model)
      return Discriminant_Variant_AST_Repair_Model;
   function Build_From_Repairs
     (Repairs : Repair.Repair_Model) return Discriminant_Variant_AST_Repair_Model;

   function Context_Count (Model : Discriminant_Variant_AST_Repair_Context_Model) return Natural;
   function Row_Count (Model : Discriminant_Variant_AST_Repair_Model) return Natural;
   function Row_At
     (Model : Discriminant_Variant_AST_Repair_Model;
      Index : Positive) return Discriminant_Variant_AST_Repair_Info;

   function First_For_Node
     (Model : Discriminant_Variant_AST_Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Variant_AST_Repair_Info;
   function Rows_For_Status
     (Model  : Discriminant_Variant_AST_Repair_Model;
      Status : Discriminant_Variant_AST_Repair_Status) return Discriminant_Variant_AST_Repair_Result_Set;
   function Rows_For_Construct
     (Model     : Discriminant_Variant_AST_Repair_Model;
      Construct : Discriminant_Variant_AST_Construct_Kind) return Discriminant_Variant_AST_Repair_Result_Set;

   function Result_Count (Results : Discriminant_Variant_AST_Repair_Result_Set) return Natural;
   function Result_At
     (Results : Discriminant_Variant_AST_Repair_Result_Set;
      Index   : Positive) return Discriminant_Variant_AST_Repair_Info;

   function Count_Status
     (Model : Discriminant_Variant_AST_Repair_Model;
      Status : Discriminant_Variant_AST_Repair_Status) return Natural;
   function Count_Construct
     (Model : Discriminant_Variant_AST_Repair_Model;
      Construct : Discriminant_Variant_AST_Construct_Kind) return Natural;

   function Accepted_Count (Model : Discriminant_Variant_AST_Repair_Model) return Natural;
   function Blocker_Count (Model : Discriminant_Variant_AST_Repair_Model) return Natural;
   function Indeterminate_Count (Model : Discriminant_Variant_AST_Repair_Model) return Natural;
   function Fingerprint (Model : Discriminant_Variant_AST_Repair_Model) return Natural;

   function Is_Discriminant_Variant_Construct
     (Construct : Audit.Ada_Construct_Kind) return Boolean;
   function Is_Accepted (Status : Discriminant_Variant_AST_Repair_Status) return Boolean;
   function Has_Error (Info : Discriminant_Variant_AST_Repair_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Discriminant_Variant_AST_Repair_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Discriminant_Variant_AST_Repair_Info);

   type Discriminant_Variant_AST_Repair_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Discriminant_Variant_AST_Repair_Result_Set is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Discriminant_Variant_AST_Repair_Model is record
      Items : Result_Vectors.Vector;
      Accepted_Total : Natural := 0;
      Blocker_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Discriminant_Variant_AST_Repair_Legality;
