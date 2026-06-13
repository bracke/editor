with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;

package Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality is

   --  Pass1249 coverage-proven AST repair legality.
   --
   --  This package is intentionally evidence driven: it only classifies parser
   --  or AST repair as a current semantic prerequisite when the coverage gates
   --  prove that a real generic/shared-state final consumer is blocked by
   --  token-only parsing, missing parser nodes, structural AST gaps, missing
   --  source spans, missing metadata, or missing consumer integration.  It then
   --  requires the stabilized generic/shared-state closure and the final
   --  overload, representation/freezing, and tasking/protected RM hard-case
   --  consumers to agree before the repaired conclusion can be trusted.

   package Gates renames Editor.Ada_Semantic_Coverage_Gates;
   package Closure renames Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;
   package Overload_Edges renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Representation_Hard_Cases renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Tasking_Hard_Cases renames Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;

   type Coverage_Proven_AST_Repair_Id is new Natural;
   No_Coverage_Proven_AST_Repair : constant Coverage_Proven_AST_Repair_Id := 0;

   type Coverage_Proven_AST_Repair_Kind is
     (Coverage_Proven_AST_Repair_Parser_Node,
      Coverage_Proven_AST_Repair_Structural_AST,
      Coverage_Proven_AST_Repair_Token_Only_Parse,
      Coverage_Proven_AST_Repair_Source_Span,
      Coverage_Proven_AST_Repair_Metadata,
      Coverage_Proven_AST_Repair_Consumer_Integration,
      Coverage_Proven_AST_Repair_Unknown);

   type Coverage_Proven_AST_Repair_Blocker_Family is
     (Coverage_Proven_AST_Repair_Blocker_None,
      Coverage_Proven_AST_Repair_Blocker_No_Coverage_Gate,
      Coverage_Proven_AST_Repair_Blocker_Gate_Not_Repairable,
      Coverage_Proven_AST_Repair_Blocker_Stabilized_Closure,
      Coverage_Proven_AST_Repair_Blocker_Overload_RM_Edge,
      Coverage_Proven_AST_Repair_Blocker_Representation_RM_Hard_Case,
      Coverage_Proven_AST_Repair_Blocker_Tasking_RM_Hard_Case,
      Coverage_Proven_AST_Repair_Blocker_Parser_Node,
      Coverage_Proven_AST_Repair_Blocker_Structural_AST,
      Coverage_Proven_AST_Repair_Blocker_Token_Only_Parse,
      Coverage_Proven_AST_Repair_Blocker_Source_Span,
      Coverage_Proven_AST_Repair_Blocker_Metadata,
      Coverage_Proven_AST_Repair_Blocker_Consumer_Integration,
      Coverage_Proven_AST_Repair_Blocker_Source_Fingerprint,
      Coverage_Proven_AST_Repair_Blocker_Multiple,
      Coverage_Proven_AST_Repair_Blocker_Indeterminate);

   type Coverage_Proven_AST_Repair_Status is
     (Coverage_Proven_AST_Repair_Not_Checked,
      Coverage_Proven_AST_Repair_Not_Required,
      Coverage_Proven_AST_Repair_Parser_Node_Repaired,
      Coverage_Proven_AST_Repair_Structural_AST_Repaired,
      Coverage_Proven_AST_Repair_Token_Only_Parse_Repaired,
      Coverage_Proven_AST_Repair_Source_Span_Repaired,
      Coverage_Proven_AST_Repair_Metadata_Repaired,
      Coverage_Proven_AST_Repair_Consumer_Integration_Repaired,
      Coverage_Proven_AST_Repair_Missing_Coverage_Gate,
      Coverage_Proven_AST_Repair_Gate_Does_Not_Prove_Repair_Need,
      Coverage_Proven_AST_Repair_Stabilized_Closure_Blocker,
      Coverage_Proven_AST_Repair_Overload_RM_Edge_Blocker,
      Coverage_Proven_AST_Repair_Representation_RM_Hard_Case_Blocker,
      Coverage_Proven_AST_Repair_Tasking_RM_Hard_Case_Blocker,
      Coverage_Proven_AST_Repair_Parser_Node_Still_Missing,
      Coverage_Proven_AST_Repair_Structural_AST_Still_Missing,
      Coverage_Proven_AST_Repair_Token_Only_Parse_Still_Present,
      Coverage_Proven_AST_Repair_Source_Span_Still_Missing,
      Coverage_Proven_AST_Repair_Metadata_Still_Missing,
      Coverage_Proven_AST_Repair_Consumer_Still_Not_Integrated,
      Coverage_Proven_AST_Repair_Source_Fingerprint_Mismatch,
      Coverage_Proven_AST_Repair_Multiple_Blockers,
      Coverage_Proven_AST_Repair_Indeterminate);

   type Coverage_Proven_AST_Repair_Context is record
      Id                         : Coverage_Proven_AST_Repair_Id := No_Coverage_Proven_AST_Repair;
      Kind                       : Coverage_Proven_AST_Repair_Kind := Coverage_Proven_AST_Repair_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Coverage_Gate_Status       : Gates.Gate_Status := Gates.Gate_Not_Checked;
      Coverage_Gate_Action       : Gates.Gate_Action := Gates.Gate_Block_Unsafe_Result;
      Has_Coverage_Gate          : Boolean := False;
      Stabilized_Closure_Row     : Closure.Generic_Shared_State_Final_Stabilized_Closure_Id := Closure.No_Generic_Shared_State_Final_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Generic_Shared_State_Final_Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Not_Checked;
      Overload_RM_Edge_Row       : Overload_Edges.Overload_Generic_RM_Edge_Completion_Id := Overload_Edges.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Edge_Status    : Overload_Edges.Overload_Generic_RM_Edge_Status := Overload_Edges.Overload_Generic_RM_Edge_Not_Checked;
      Representation_RM_Hard_Case_Row : Representation_Hard_Cases.Representation_Generic_RM_Hard_Case_Id := Representation_Hard_Cases.No_Representation_Generic_RM_Hard_Case;
      Representation_RM_Hard_Case_Status : Representation_Hard_Cases.Representation_Generic_RM_Hard_Case_Status := Representation_Hard_Cases.Representation_Generic_RM_Hard_Case_Not_Checked;
      Tasking_RM_Hard_Case_Row   : Tasking_Hard_Cases.Tasking_Generic_RM_Hard_Case_Id := Tasking_Hard_Cases.No_Tasking_Generic_RM_Hard_Case;
      Tasking_RM_Hard_Case_Status : Tasking_Hard_Cases.Tasking_Generic_RM_Hard_Case_Status := Tasking_Hard_Cases.Tasking_Generic_RM_Hard_Case_Not_Checked;
      Requires_Stabilized_Closure : Boolean := True;
      Requires_Overload_RM_Edge  : Boolean := True;
      Requires_Representation_RM_Hard_Case : Boolean := True;
      Requires_Tasking_RM_Hard_Case : Boolean := True;
      Parser_Node_Still_Missing  : Boolean := False;
      Structural_AST_Still_Missing : Boolean := False;
      Token_Only_Parse_Still_Present : Boolean := False;
      Source_Span_Still_Missing  : Boolean := False;
      Metadata_Still_Missing     : Boolean := False;
      Consumer_Still_Not_Integrated : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Coverage_Proven_AST_Repair_Row is record
      Id                         : Coverage_Proven_AST_Repair_Id := No_Coverage_Proven_AST_Repair;
      Context                    : Coverage_Proven_AST_Repair_Id := No_Coverage_Proven_AST_Repair;
      Kind                       : Coverage_Proven_AST_Repair_Kind := Coverage_Proven_AST_Repair_Unknown;
      Status                     : Coverage_Proven_AST_Repair_Status := Coverage_Proven_AST_Repair_Not_Checked;
      Blocker_Family             : Coverage_Proven_AST_Repair_Blocker_Family := Coverage_Proven_AST_Repair_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Repaired                   : Boolean := False;
      Not_Required               : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Row_Fingerprint            : Natural := 0;
   end record;

   type Coverage_Proven_AST_Repair_Context_Model is private;
   type Coverage_Proven_AST_Repair_Model is private;
   type Coverage_Proven_AST_Repair_Set is private;

   procedure Clear (Model : in out Coverage_Proven_AST_Repair_Context_Model);
   procedure Add_Context (Model : in out Coverage_Proven_AST_Repair_Context_Model; Context : Coverage_Proven_AST_Repair_Context);
   function Context_Count (Model : Coverage_Proven_AST_Repair_Context_Model) return Natural;
   function Context_At (Model : Coverage_Proven_AST_Repair_Context_Model; Index : Positive) return Coverage_Proven_AST_Repair_Context;
   function Context_Fingerprint (Model : Coverage_Proven_AST_Repair_Context_Model) return Natural;

   function Build (Contexts : Coverage_Proven_AST_Repair_Context_Model) return Coverage_Proven_AST_Repair_Model;
   function Count (Model : Coverage_Proven_AST_Repair_Model) return Natural;
   function Row_At (Model : Coverage_Proven_AST_Repair_Model; Index : Positive) return Coverage_Proven_AST_Repair_Row;
   function Query_Count (Set : Coverage_Proven_AST_Repair_Set) return Natural;
   function Query_At (Set : Coverage_Proven_AST_Repair_Set; Index : Positive) return Coverage_Proven_AST_Repair_Row;
   function Query_Status (Model : Coverage_Proven_AST_Repair_Model; Status : Coverage_Proven_AST_Repair_Status) return Coverage_Proven_AST_Repair_Set;
   function Query_Blocker_Family (Model : Coverage_Proven_AST_Repair_Model; Family : Coverage_Proven_AST_Repair_Blocker_Family) return Coverage_Proven_AST_Repair_Set;
   function Find_By_Node (Model : Coverage_Proven_AST_Repair_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Coverage_Proven_AST_Repair_Set;
   function Find_By_Source_Fingerprint (Model : Coverage_Proven_AST_Repair_Model; Source_Fingerprint : Natural) return Coverage_Proven_AST_Repair_Set;
   function Count_By_Status (Model : Coverage_Proven_AST_Repair_Model; Status : Coverage_Proven_AST_Repair_Status) return Natural;
   function Count_By_Blocker_Family (Model : Coverage_Proven_AST_Repair_Model; Family : Coverage_Proven_AST_Repair_Blocker_Family) return Natural;
   function Repaired_Count (Model : Coverage_Proven_AST_Repair_Model) return Natural;
   function Not_Required_Count (Model : Coverage_Proven_AST_Repair_Model) return Natural;
   function Withheld_Count (Model : Coverage_Proven_AST_Repair_Model) return Natural;
   function Indeterminate_Count (Model : Coverage_Proven_AST_Repair_Model) return Natural;
   function Stable_Fingerprint (Model : Coverage_Proven_AST_Repair_Model) return Natural;

   function Is_Repaired (Status : Coverage_Proven_AST_Repair_Status) return Boolean;
   function Is_Blocked (Status : Coverage_Proven_AST_Repair_Status) return Boolean;
   function Is_Indeterminate (Status : Coverage_Proven_AST_Repair_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors (Index_Type => Positive, Element_Type => Coverage_Proven_AST_Repair_Context);
   package Row_Vectors is new Ada.Containers.Vectors (Index_Type => Positive, Element_Type => Coverage_Proven_AST_Repair_Row);
   type Coverage_Proven_AST_Repair_Context_Model is record Items : Context_Vectors.Vector; Fingerprint : Natural := 0; end record;
   type Coverage_Proven_AST_Repair_Model is record Rows : Row_Vectors.Vector; Fingerprint : Natural := 0; end record;
   type Coverage_Proven_AST_Repair_Set is record Rows : Row_Vectors.Vector; end record;
end Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;
