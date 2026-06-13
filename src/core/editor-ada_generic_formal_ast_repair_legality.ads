with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Formal_AST_Repair_Legality is

   --  Pass1174 generic formal parser-AST repair legality.
   --
   --  This package turns the generic repaired-coverage facts from Pass1147
   --  into concrete generic-formal declaration repair facts.  Generic formal
   --  objects, types, subprograms, and packages are not treated as restored
   --  until parser nodes, structural AST, spans, name/type/staticness/contract
   --  metadata, cross-unit metadata, and integrated generic consumers are all
   --  present as required by the formal kind.

   package Repair renames Editor.Ada_AST_Coverage_Repair_Legality;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   type Generic_Formal_AST_Repair_Row_Id is new Natural;
   No_Generic_Formal_AST_Repair_Row : constant Generic_Formal_AST_Repair_Row_Id := 0;

   type Generic_Formal_AST_Construct_Kind is
     (Generic_Formal_AST_Object,
      Generic_Formal_AST_Type,
      Generic_Formal_AST_Subprogram,
      Generic_Formal_AST_Package,
      Generic_Formal_AST_Unknown);

   type Generic_Formal_AST_Repair_Status is
     (Generic_Formal_AST_Not_Checked,
      Generic_Formal_AST_Legal_Object_Repaired,
      Generic_Formal_AST_Legal_Type_Repaired,
      Generic_Formal_AST_Legal_Subprogram_Repaired,
      Generic_Formal_AST_Legal_Package_Repaired,
      Generic_Formal_AST_Parser_Node_Still_Missing,
      Generic_Formal_AST_Structural_AST_Still_Missing,
      Generic_Formal_AST_Source_Span_Still_Missing,
      Generic_Formal_AST_Name_Binding_Still_Missing,
      Generic_Formal_AST_Type_Metadata_Still_Missing,
      Generic_Formal_AST_Staticness_Metadata_Still_Missing,
      Generic_Formal_AST_Contract_Metadata_Still_Missing,
      Generic_Formal_AST_Cross_Unit_Metadata_Still_Missing,
      Generic_Formal_AST_Consumer_Still_Missing,
      Generic_Formal_AST_Consumer_Still_Not_Integrated,
      Generic_Formal_AST_Token_Only_Parse_Still_Present,
      Generic_Formal_AST_Degradation_Only_Path_Still_Present,
      Generic_Formal_AST_Repair_Mismatch,
      Generic_Formal_AST_Multiple_Repair_Blockers,
      Generic_Formal_AST_Indeterminate);

   type Generic_Formal_AST_Repair_Context_Info is record
      Id                            : Generic_Formal_AST_Repair_Row_Id := No_Generic_Formal_AST_Repair_Row;
      Construct                     : Generic_Formal_AST_Construct_Kind := Generic_Formal_AST_Unknown;
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

   type Generic_Formal_AST_Repair_Info is record
      Id                            : Generic_Formal_AST_Repair_Row_Id := No_Generic_Formal_AST_Repair_Row;
      Construct                     : Generic_Formal_AST_Construct_Kind := Generic_Formal_AST_Unknown;
      Audit_Construct               : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer                      : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                        : Generic_Formal_AST_Repair_Status := Generic_Formal_AST_Not_Checked;
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

   type Generic_Formal_AST_Repair_Context_Model is private;
   type Generic_Formal_AST_Repair_Model is private;
   type Generic_Formal_AST_Repair_Result_Set is private;

   procedure Clear (Model : in out Generic_Formal_AST_Repair_Context_Model);
   procedure Add_Context
     (Model   : in out Generic_Formal_AST_Repair_Context_Model;
      Context : Generic_Formal_AST_Repair_Context_Info);

   function Build
     (Contexts : Generic_Formal_AST_Repair_Context_Model)
      return Generic_Formal_AST_Repair_Model;
   function Build_From_Repairs
     (Repairs : Repair.Repair_Model) return Generic_Formal_AST_Repair_Model;

   function Context_Count (Model : Generic_Formal_AST_Repair_Context_Model) return Natural;
   function Row_Count (Model : Generic_Formal_AST_Repair_Model) return Natural;
   function Row_At
     (Model : Generic_Formal_AST_Repair_Model;
      Index : Positive) return Generic_Formal_AST_Repair_Info;

   function First_For_Node
     (Model : Generic_Formal_AST_Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Formal_AST_Repair_Info;
   function Rows_For_Status
     (Model  : Generic_Formal_AST_Repair_Model;
      Status : Generic_Formal_AST_Repair_Status) return Generic_Formal_AST_Repair_Result_Set;
   function Rows_For_Construct
     (Model     : Generic_Formal_AST_Repair_Model;
      Construct : Generic_Formal_AST_Construct_Kind) return Generic_Formal_AST_Repair_Result_Set;

   function Result_Count (Results : Generic_Formal_AST_Repair_Result_Set) return Natural;
   function Result_At
     (Results : Generic_Formal_AST_Repair_Result_Set;
      Index   : Positive) return Generic_Formal_AST_Repair_Info;

   function Count_Status
     (Model : Generic_Formal_AST_Repair_Model;
      Status : Generic_Formal_AST_Repair_Status) return Natural;
   function Count_Construct
     (Model : Generic_Formal_AST_Repair_Model;
      Construct : Generic_Formal_AST_Construct_Kind) return Natural;

   function Accepted_Count (Model : Generic_Formal_AST_Repair_Model) return Natural;
   function Blocker_Count (Model : Generic_Formal_AST_Repair_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Formal_AST_Repair_Model) return Natural;
   function Fingerprint (Model : Generic_Formal_AST_Repair_Model) return Natural;

   function Is_Generic_Formal_Construct
     (Construct : Audit.Ada_Construct_Kind) return Boolean;
   function Is_Accepted (Status : Generic_Formal_AST_Repair_Status) return Boolean;
   function Has_Error (Info : Generic_Formal_AST_Repair_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Formal_AST_Repair_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Formal_AST_Repair_Info);

   type Generic_Formal_AST_Repair_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Generic_Formal_AST_Repair_Result_Set is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Generic_Formal_AST_Repair_Model is record
      Items : Result_Vectors.Vector;
      Accepted_Total : Natural := 0;
      Blocker_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Formal_AST_Repair_Legality;
