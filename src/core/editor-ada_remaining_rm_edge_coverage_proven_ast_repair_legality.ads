with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality is

   --  Case 1295 coverage-proven AST repair for remaining RM edge blockers.
   --
   --  This package is deliberately evidence-driven.  It does not speculate
   --  about parser gaps.  A repair row may be accepted only when a stabilized
   --  remaining-RM-edge search/provenance entry exists, that entry is a real
   --  downstream blocker, source/substitution fingerprints still match, and
   --  the caller supplies concrete evidence that the remaining RM edge is
   --  blocked by a parser node gap, structural AST gap, token-only parse,
   --  missing source span, missing semantic metadata, or missing consumer
   --  integration.

   package Search renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index;

   subtype Search_Entry is Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry;
   subtype Search_Status is Search.Remaining_RM_Edge_Stabilized_Closure_Provenance_Status;
   subtype Search_Blocker is Search.Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker;
   subtype Remaining_RM_Edge_Kind is Search.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Search.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_AST_Repair_Id is new Natural;
   No_Remaining_RM_Edge_AST_Repair : constant Remaining_RM_Edge_AST_Repair_Id := 0;

   type Remaining_RM_Edge_AST_Repair_Kind is
     (Remaining_RM_Edge_AST_Repair_Parser_Node,
      Remaining_RM_Edge_AST_Repair_Structural_AST,
      Remaining_RM_Edge_AST_Repair_Token_Only_Parse,
      Remaining_RM_Edge_AST_Repair_Source_Span,
      Remaining_RM_Edge_AST_Repair_Metadata,
      Remaining_RM_Edge_AST_Repair_Consumer_Integration,
      Remaining_RM_Edge_AST_Repair_Unknown);

   type Remaining_RM_Edge_AST_Repair_Blocker_Family is
     (Remaining_RM_Edge_AST_Repair_Blocker_None,
      Remaining_RM_Edge_AST_Repair_Blocker_No_Stabilized_Search_Evidence,
      Remaining_RM_Edge_AST_Repair_Blocker_Search_Evidence_Not_Blocking,
      Remaining_RM_Edge_AST_Repair_Blocker_Search_Evidence_Not_Remaining_Edge,
      Remaining_RM_Edge_AST_Repair_Blocker_No_Coverage_Proof,
      Remaining_RM_Edge_AST_Repair_Blocker_No_AST_Gap,
      Remaining_RM_Edge_AST_Repair_Blocker_Parser_Node,
      Remaining_RM_Edge_AST_Repair_Blocker_Structural_AST,
      Remaining_RM_Edge_AST_Repair_Blocker_Token_Only_Parse,
      Remaining_RM_Edge_AST_Repair_Blocker_Source_Span,
      Remaining_RM_Edge_AST_Repair_Blocker_Metadata,
      Remaining_RM_Edge_AST_Repair_Blocker_Consumer_Integration,
      Remaining_RM_Edge_AST_Repair_Blocker_Source_Fingerprint,
      Remaining_RM_Edge_AST_Repair_Blocker_Substitution_Fingerprint,
      Remaining_RM_Edge_AST_Repair_Blocker_Multiple,
      Remaining_RM_Edge_AST_Repair_Blocker_Indeterminate);

   type Remaining_RM_Edge_AST_Repair_Status is
     (Remaining_RM_Edge_AST_Repair_Not_Checked,
      Remaining_RM_Edge_AST_Repair_Not_Required,
      Remaining_RM_Edge_AST_Repair_Parser_Node_Repaired,
      Remaining_RM_Edge_AST_Repair_Structural_AST_Repaired,
      Remaining_RM_Edge_AST_Repair_Token_Only_Parse_Repaired,
      Remaining_RM_Edge_AST_Repair_Source_Span_Repaired,
      Remaining_RM_Edge_AST_Repair_Metadata_Repaired,
      Remaining_RM_Edge_AST_Repair_Consumer_Integration_Repaired,
      Remaining_RM_Edge_AST_Repair_Missing_Stabilized_Search_Evidence,
      Remaining_RM_Edge_AST_Repair_Search_Evidence_Not_Blocking,
      Remaining_RM_Edge_AST_Repair_Search_Evidence_Not_Remaining_Edge,
      Remaining_RM_Edge_AST_Repair_No_Coverage_Proof,
      Remaining_RM_Edge_AST_Repair_No_AST_Gap,
      Remaining_RM_Edge_AST_Repair_Parser_Node_Still_Missing,
      Remaining_RM_Edge_AST_Repair_Structural_AST_Still_Missing,
      Remaining_RM_Edge_AST_Repair_Token_Only_Parse_Still_Present,
      Remaining_RM_Edge_AST_Repair_Source_Span_Still_Missing,
      Remaining_RM_Edge_AST_Repair_Metadata_Still_Missing,
      Remaining_RM_Edge_AST_Repair_Consumer_Still_Not_Integrated,
      Remaining_RM_Edge_AST_Repair_Source_Fingerprint_Mismatch,
      Remaining_RM_Edge_AST_Repair_Substitution_Fingerprint_Mismatch,
      Remaining_RM_Edge_AST_Repair_Multiple_Blockers,
      Remaining_RM_Edge_AST_Repair_Indeterminate);

   type Remaining_RM_Edge_AST_Repair_Context is record
      Id                         : Remaining_RM_Edge_AST_Repair_Id := No_Remaining_RM_Edge_AST_Repair;
      Kind                       : Remaining_RM_Edge_AST_Repair_Kind := Remaining_RM_Edge_AST_Repair_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Has_Stabilized_Search_Evidence : Boolean := False;
      Stabilized_Search_Entry    : Search_Entry;
      Requires_Remaining_Edge_Blocker : Boolean := True;
      Coverage_Proves_Repair_Need : Boolean := False;
      Parser_Node_Still_Missing  : Boolean := False;
      Structural_AST_Still_Missing : Boolean := False;
      Token_Only_Parse_Still_Present : Boolean := False;
      Source_Span_Still_Missing  : Boolean := False;
      Metadata_Still_Missing     : Boolean := False;
      Consumer_Still_Not_Integrated : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Remaining_RM_Edge_AST_Repair_Row is record
      Id                         : Remaining_RM_Edge_AST_Repair_Id := No_Remaining_RM_Edge_AST_Repair;
      Context                    : Remaining_RM_Edge_AST_Repair_Id := No_Remaining_RM_Edge_AST_Repair;
      Kind                       : Remaining_RM_Edge_AST_Repair_Kind := Remaining_RM_Edge_AST_Repair_Unknown;
      Status                     : Remaining_RM_Edge_AST_Repair_Status := Remaining_RM_Edge_AST_Repair_Not_Checked;
      Blocker_Family             : Remaining_RM_Edge_AST_Repair_Blocker_Family := Remaining_RM_Edge_AST_Repair_Blocker_None;
      Remaining_Edge_Kind        : Remaining_RM_Edge_Kind := Search.Prov.Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker     : Remaining_RM_Edge_Blocker_Family := Search.Prov.Edge.Remaining_RM_Edge_Blocker_None;
      Search_Status_Value        : Search_Status := Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Not_Checked;
      Search_Blocker_Value       : Search_Blocker := Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Blocker_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Repaired                   : Boolean := False;
      Not_Required               : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Coverage_Proven            : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Search_Fingerprint         : Natural := 0;
      Row_Fingerprint            : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Remaining_RM_Edge_AST_Repair_Context_Model is private;
   type Remaining_RM_Edge_AST_Repair_Model is private;
   type Remaining_RM_Edge_AST_Repair_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_AST_Repair_Context_Model);
   procedure Add_Context
     (Model   : in out Remaining_RM_Edge_AST_Repair_Context_Model;
      Context : Remaining_RM_Edge_AST_Repair_Context);

   function Context_Count (Model : Remaining_RM_Edge_AST_Repair_Context_Model) return Natural;
   function Context_At
     (Model : Remaining_RM_Edge_AST_Repair_Context_Model;
      Index : Positive) return Remaining_RM_Edge_AST_Repair_Context;
   function Context_Fingerprint (Model : Remaining_RM_Edge_AST_Repair_Context_Model) return Natural;

   function Build
     (Contexts : Remaining_RM_Edge_AST_Repair_Context_Model)
      return Remaining_RM_Edge_AST_Repair_Model;

   function Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural;
   function Row_At
     (Model : Remaining_RM_Edge_AST_Repair_Model;
      Index : Positive) return Remaining_RM_Edge_AST_Repair_Row;

   function Query_Count (Set : Remaining_RM_Edge_AST_Repair_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_AST_Repair_Set;
      Index : Positive) return Remaining_RM_Edge_AST_Repair_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_AST_Repair_Model;
      Status : Remaining_RM_Edge_AST_Repair_Status)
      return Remaining_RM_Edge_AST_Repair_Set;
   function Query_Blocker_Family
     (Model  : Remaining_RM_Edge_AST_Repair_Model;
      Family : Remaining_RM_Edge_AST_Repair_Blocker_Family)
      return Remaining_RM_Edge_AST_Repair_Set;
   function Query_Remaining_Edge_Kind
     (Model : Remaining_RM_Edge_AST_Repair_Model;
      Kind  : Remaining_RM_Edge_Kind)
      return Remaining_RM_Edge_AST_Repair_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_AST_Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_AST_Repair_Set;

   function Count_By_Status
     (Model  : Remaining_RM_Edge_AST_Repair_Model;
      Status : Remaining_RM_Edge_AST_Repair_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Remaining_RM_Edge_AST_Repair_Model;
      Family : Remaining_RM_Edge_AST_Repair_Blocker_Family) return Natural;

   function Repaired_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural;
   function Not_Required_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural;
   function Withheld_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural;
   function Coverage_Proven_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural;
   function Stable_Fingerprint (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural;

   function Is_Repaired (Status : Remaining_RM_Edge_AST_Repair_Status) return Boolean;
   function Is_Blocked (Status : Remaining_RM_Edge_AST_Repair_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_AST_Repair_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_AST_Repair_Row);

   type Remaining_RM_Edge_AST_Repair_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_AST_Repair_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_AST_Repair_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality;
