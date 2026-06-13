with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Coverage_Gated_Semantic_Results;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_AST_Coverage_Repair_Gate_Application is

   --  Pass1148 coverage-repair gate application.
   --
   --  Pass1147 records concrete parser/AST/metadata/consumer repairs.  This
   --  package applies those repair facts to widened legality coverage-gate
   --  enforcement rows so repaired constructs can regain confident semantic
   --  conclusions while still preserving unrepaired, partial, cross-unit, and
   --  unsafe blockers.  It is the semantic follow-through after repair: repair
   --  rows are not merely counted; they are consumed by the same safety gate
   --  path that suppresses unsafe legality conclusions.
   --
   --  The model is deterministic and snapshot-owned.  It performs no parsing,
   --  no file IO, no save/reload, no dirty-state mutation, no render-side
   --  parsing, no command/keybinding/workspace/render mutation, no compiler
   --  invocation, and no external parser generation.

   package Repair renames Editor.Ada_AST_Coverage_Repair_Legality;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;
   package Gates renames Editor.Ada_Semantic_Coverage_Gates;
   package Gated renames Editor.Ada_Coverage_Gated_Semantic_Results;
   package Enforce renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   type Application_Row_Id is new Natural;
   No_Application_Row : constant Application_Row_Id := 0;

   type Application_Status is
     (Application_Not_Checked,
      Application_Already_Confident,
      Application_Repair_Clears_Parser_AST_Blocker,
      Application_Repair_Clears_Metadata_Blocker,
      Application_Repair_Clears_Consumer_Blocker,
      Application_Repair_Clears_Suppressed_Legal,
      Application_Repair_Clears_Suppressed_Derived,
      Application_Repair_Clears_Unsafe_Blocker,
      Application_Cross_Unit_Still_Required,
      Application_Original_Error_Preserved,
      Application_Repair_Missing,
      Application_Repair_Partial,
      Application_Repair_Indeterminate,
      Application_Repair_Mismatch,
      Application_Enforcement_Still_Blocking);

   type Application_Context_Info is record
      Id                  : Application_Row_Id := No_Application_Row;
      Repair_Id           : Repair.Repair_Item_Id := Repair.No_Repair_Item;
      Enforcement_Id      : Enforce.Enforcement_Row_Id := Enforce.No_Enforcement_Row;
      Engine              : Enforce.Widened_Legality_Engine := Enforce.Engine_Unknown;
      Enforcement_Status  : Enforce.Enforcement_Status := Enforce.Enforcement_Not_Checked;
      Repair_Status       : Repair.Repair_Status := Repair.Repair_Not_Checked;
      Repair_Kind         : Repair.Repair_Kind := Repair.Repair_Unknown;
      Conclusion          : Gates.Semantic_Conclusion_Kind := Gates.Conclusion_Unknown;
      Construct           : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer            : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Original_State      : Gated.Original_Result_State := Gated.Original_Result_Not_Checked;
      Gate_Status         : Gates.Gate_Status := Gates.Gate_Not_Checked;
      Gate_Action         : Gates.Gate_Action := Gates.Gate_Block_Unsafe_Result;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Semantic_Row_Id     : Natural := 0;
      Construct_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Repair_Message      : Ada.Strings.Unbounded.Unbounded_String;
      Enforcement_Message : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint  : Natural := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
   end record;

   type Application_Info is record
      Id                  : Application_Row_Id := No_Application_Row;
      Repair_Id           : Repair.Repair_Item_Id := Repair.No_Repair_Item;
      Enforcement_Id      : Enforce.Enforcement_Row_Id := Enforce.No_Enforcement_Row;
      Engine              : Enforce.Widened_Legality_Engine := Enforce.Engine_Unknown;
      Status              : Application_Status := Application_Not_Checked;
      Enforcement_Status  : Enforce.Enforcement_Status := Enforce.Enforcement_Not_Checked;
      Repair_Status       : Repair.Repair_Status := Repair.Repair_Not_Checked;
      Repair_Kind         : Repair.Repair_Kind := Repair.Repair_Unknown;
      Conclusion          : Gates.Semantic_Conclusion_Kind := Gates.Conclusion_Unknown;
      Construct           : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer            : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Original_State      : Gated.Original_Result_State := Gated.Original_Result_Not_Checked;
      Gate_Status         : Gates.Gate_Status := Gates.Gate_Not_Checked;
      Gate_Action         : Gates.Gate_Action := Gates.Gate_Block_Unsafe_Result;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Semantic_Row_Id     : Natural := 0;
      Construct_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint  : Natural := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Application_Context_Model is private;
   type Application_Model is private;
   type Application_Set is private;

   function Classify
     (Enforcement_Status : Enforce.Enforcement_Status;
      Repair_Status      : Repair.Repair_Status;
      Repair_Kind        : Repair.Repair_Kind) return Application_Status;

   procedure Clear (Model : in out Application_Context_Model);
   procedure Add_Context
     (Model   : in out Application_Context_Model;
      Context : Application_Context_Info);

   procedure Add_From_Repair_And_Enforcement
     (Model       : in out Application_Context_Model;
      Repair_Row  : Repair.Repair_Info;
      Enforced_Row : Enforce.Enforcement_Info);

   function Build (Contexts : Application_Context_Model) return Application_Model;
   function Build_From_Repair_And_Enforcement
     (Repairs      : Repair.Repair_Model;
      Enforcement  : Enforce.Enforcement_Model) return Application_Model;

   function Row_Count (Model : Application_Model) return Natural;
   function Row_At
     (Model : Application_Model;
      Index : Positive) return Application_Info;

   function First_For_Node
     (Model : Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Application_Info;

   function Rows_For_Status
     (Model  : Application_Model;
      Status : Application_Status) return Application_Set;
   function Rows_For_Engine
     (Model  : Application_Model;
      Engine : Enforce.Widened_Legality_Engine) return Application_Set;
   function Rows_For_Construct
     (Model     : Application_Model;
      Construct : Audit.Ada_Construct_Kind) return Application_Set;

   function Set_Count (Set : Application_Set) return Natural;
   function Set_At
     (Set   : Application_Set;
      Index : Positive) return Application_Info;

   function Count_Status
     (Model  : Application_Model;
      Status : Application_Status) return Natural;
   function Count_Engine
     (Model  : Application_Model;
      Engine : Enforce.Widened_Legality_Engine) return Natural;
   function Count_Construct
     (Model     : Application_Model;
      Construct : Audit.Ada_Construct_Kind) return Natural;

   function Cleared_Count (Model : Application_Model) return Natural;
   function Still_Blocking_Count (Model : Application_Model) return Natural;
   function Missing_Repair_Count (Model : Application_Model) return Natural;
   function Partial_Repair_Count (Model : Application_Model) return Natural;
   function Cross_Unit_Required_Count (Model : Application_Model) return Natural;
   function Original_Error_Count (Model : Application_Model) return Natural;
   function Fingerprint (Model : Application_Model) return Natural;

   function Clears_Gate (Status : Application_Status) return Boolean;
   function Has_Blocker (Info : Application_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Application_Context_Info);
   package Info_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Application_Info);

   type Application_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Application_Set is record
      Items       : Info_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Application_Model is record
      Items                 : Info_Vectors.Vector;
      Cleared_Total         : Natural := 0;
      Still_Blocking_Total  : Natural := 0;
      Missing_Repair_Total  : Natural := 0;
      Partial_Repair_Total  : Natural := 0;
      Cross_Unit_Total      : Natural := 0;
      Original_Error_Total  : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

end Editor.Ada_AST_Coverage_Repair_Gate_Application;
