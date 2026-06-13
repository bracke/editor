with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Access_Definition_AST_Repair_Legality is

   --  Pass1175 access definition parser-AST repair legality.
   --
   --  This package turns the repaired-coverage facts from Pass1147 into
   --  concrete access-definition repair facts.  Object access definitions,
   --  anonymous access parameters, access-to-subprogram definitions, and access
   --  discriminants are not treated as restored until parser nodes, structural
   --  AST, spans, name/type/flow/representation metadata, cross-unit metadata,
   --  and integrated accessibility/access consumers are all present.

   package Repair renames Editor.Ada_AST_Coverage_Repair_Legality;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   type Access_Definition_AST_Repair_Row_Id is new Natural;
   No_Access_Definition_AST_Repair_Row : constant Access_Definition_AST_Repair_Row_Id := 0;

   type Access_Definition_AST_Construct_Kind is
     (Access_Definition_AST_Object_Access,
      Access_Definition_AST_Access_Parameter,
      Access_Definition_AST_Subprogram_Access,
      Access_Definition_AST_Access_Discriminant,
      Access_Definition_AST_Unknown);

   type Access_Definition_AST_Repair_Status is
     (Access_Definition_AST_Not_Checked,
      Access_Definition_AST_Legal_Object_Access_Repaired,
      Access_Definition_AST_Legal_Access_Parameter_Repaired,
      Access_Definition_AST_Legal_Subprogram_Access_Repaired,
      Access_Definition_AST_Legal_Access_Discriminant_Repaired,
      Access_Definition_AST_Parser_Node_Still_Missing,
      Access_Definition_AST_Structural_AST_Still_Missing,
      Access_Definition_AST_Source_Span_Still_Missing,
      Access_Definition_AST_Name_Binding_Still_Missing,
      Access_Definition_AST_Type_Metadata_Still_Missing,
      Access_Definition_AST_Staticness_Metadata_Still_Missing,
      Access_Definition_AST_Contract_Metadata_Still_Missing,
      Access_Definition_AST_Flow_Metadata_Still_Missing,
      Access_Definition_AST_Representation_Metadata_Still_Missing,
      Access_Definition_AST_Cross_Unit_Metadata_Still_Missing,
      Access_Definition_AST_Consumer_Still_Missing,
      Access_Definition_AST_Consumer_Still_Not_Integrated,
      Access_Definition_AST_Token_Only_Parse_Still_Present,
      Access_Definition_AST_Degradation_Only_Path_Still_Present,
      Access_Definition_AST_Repair_Mismatch,
      Access_Definition_AST_Multiple_Repair_Blockers,
      Access_Definition_AST_Indeterminate);

   type Access_Definition_AST_Repair_Context_Info is record
      Id                            : Access_Definition_AST_Repair_Row_Id := No_Access_Definition_AST_Repair_Row;
      Construct                     : Access_Definition_AST_Construct_Kind := Access_Definition_AST_Unknown;
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

   type Access_Definition_AST_Repair_Info is record
      Id                            : Access_Definition_AST_Repair_Row_Id := No_Access_Definition_AST_Repair_Row;
      Construct                     : Access_Definition_AST_Construct_Kind := Access_Definition_AST_Unknown;
      Audit_Construct               : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer                      : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                        : Access_Definition_AST_Repair_Status := Access_Definition_AST_Not_Checked;
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

   type Access_Definition_AST_Repair_Context_Model is private;
   type Access_Definition_AST_Repair_Model is private;
   type Access_Definition_AST_Repair_Result_Set is private;

   procedure Clear (Model : in out Access_Definition_AST_Repair_Context_Model);
   procedure Add_Context
     (Model   : in out Access_Definition_AST_Repair_Context_Model;
      Context : Access_Definition_AST_Repair_Context_Info);

   function Build
     (Contexts : Access_Definition_AST_Repair_Context_Model)
      return Access_Definition_AST_Repair_Model;
   function Build_From_Repairs
     (Repairs : Repair.Repair_Model) return Access_Definition_AST_Repair_Model;

   function Context_Count (Model : Access_Definition_AST_Repair_Context_Model) return Natural;
   function Row_Count (Model : Access_Definition_AST_Repair_Model) return Natural;
   function Row_At
     (Model : Access_Definition_AST_Repair_Model;
      Index : Positive) return Access_Definition_AST_Repair_Info;

   function First_For_Node
     (Model : Access_Definition_AST_Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Access_Definition_AST_Repair_Info;
   function Rows_For_Status
     (Model  : Access_Definition_AST_Repair_Model;
      Status : Access_Definition_AST_Repair_Status) return Access_Definition_AST_Repair_Result_Set;
   function Rows_For_Construct
     (Model     : Access_Definition_AST_Repair_Model;
      Construct : Access_Definition_AST_Construct_Kind) return Access_Definition_AST_Repair_Result_Set;

   function Result_Count (Results : Access_Definition_AST_Repair_Result_Set) return Natural;
   function Result_At
     (Results : Access_Definition_AST_Repair_Result_Set;
      Index   : Positive) return Access_Definition_AST_Repair_Info;

   function Count_Status
     (Model : Access_Definition_AST_Repair_Model;
      Status : Access_Definition_AST_Repair_Status) return Natural;
   function Count_Construct
     (Model : Access_Definition_AST_Repair_Model;
      Construct : Access_Definition_AST_Construct_Kind) return Natural;

   function Accepted_Count (Model : Access_Definition_AST_Repair_Model) return Natural;
   function Blocker_Count (Model : Access_Definition_AST_Repair_Model) return Natural;
   function Indeterminate_Count (Model : Access_Definition_AST_Repair_Model) return Natural;
   function Fingerprint (Model : Access_Definition_AST_Repair_Model) return Natural;

   function Is_Access_Definition_Construct
     (Construct : Audit.Ada_Construct_Kind) return Boolean;
   function Is_Accepted (Status : Access_Definition_AST_Repair_Status) return Boolean;
   function Has_Error (Info : Access_Definition_AST_Repair_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Access_Definition_AST_Repair_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Access_Definition_AST_Repair_Info);

   type Access_Definition_AST_Repair_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Access_Definition_AST_Repair_Result_Set is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Access_Definition_AST_Repair_Model is record
      Items : Result_Vectors.Vector;
      Accepted_Total : Natural := 0;
      Blocker_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Access_Definition_AST_Repair_Legality;
