with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Recheck_Convergence_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Stabilization_Gate_Legality is

   --  Case 1208 final semantic stabilization gate legality.
   --
   --  This package consumes Case 1207 final recheck convergence rows and
   --  decides whether a semantic result may be promoted across the final
   --  closure/feed boundary.  Promotion is allowed only for convergence rows
   --  whose current/prerequisite fingerprints and blocker family are stable.
   --  Stable withheld rows remain explicitly blocked by their original
   --  prerequisite family, changed rows require another recheck, and
   --  indeterminate rows remain degraded instead of becoming confident legal
   --  conclusions.

   package Conv renames Editor.Ada_Final_Semantic_Recheck_Convergence_Legality;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Recheck_Convergence_Status is Conv.Final_Recheck_Convergence_Status;
   subtype Final_Recheck_Convergence_Action is Conv.Final_Recheck_Convergence_Action;

   type Final_Stabilization_Gate_Id is new Natural;
   No_Final_Stabilization_Gate : constant Final_Stabilization_Gate_Id := 0;

   type Final_Stabilization_Gate_Status is
     (Final_Stabilization_Gate_Not_Checked,
      Final_Stabilization_Gate_Promoted_Current,
      Final_Stabilization_Gate_Promoted_Not_Required,
      Final_Stabilization_Gate_Withheld_Stale,
      Final_Stabilization_Gate_Withheld_AST_Coverage,
      Final_Stabilization_Gate_Withheld_Cross_Unit,
      Final_Stabilization_Gate_Withheld_View_Barrier,
      Final_Stabilization_Gate_Withheld_Generic_Replay,
      Final_Stabilization_Gate_Withheld_Overload_Type,
      Final_Stabilization_Gate_Withheld_Representation_Freezing,
      Final_Stabilization_Gate_Withheld_Flow_Contract,
      Final_Stabilization_Gate_Withheld_Tasking_Protected,
      Final_Stabilization_Gate_Withheld_Elaboration,
      Final_Stabilization_Gate_Withheld_Accessibility,
      Final_Stabilization_Gate_Withheld_Discriminant_Variant,
      Final_Stabilization_Gate_Preserved_Semantic_Error,
      Final_Stabilization_Gate_Withheld_Multiple_Prerequisites,
      Final_Stabilization_Gate_Degraded_Indeterminate,
      Final_Stabilization_Gate_Recheck_Required);

   type Final_Stabilization_Gate_Action is
     (Final_Stabilization_Gate_Action_None,
      Final_Stabilization_Gate_Action_Promote_Current,
      Final_Stabilization_Gate_Action_Promote_Not_Required,
      Final_Stabilization_Gate_Action_Withhold_Prerequisite,
      Final_Stabilization_Gate_Action_Retain_Error,
      Final_Stabilization_Gate_Action_Split_Prerequisites,
      Final_Stabilization_Gate_Action_Degrade,
      Final_Stabilization_Gate_Action_Recheck);

   type Final_Stabilization_Gate_Row is record
      Id                       : Final_Stabilization_Gate_Id := No_Final_Stabilization_Gate;
      Convergence_Id           : Conv.Final_Recheck_Convergence_Id := Conv.No_Final_Recheck_Convergence;
      Convergence_Status       : Final_Recheck_Convergence_Status := Conv.Final_Recheck_Convergence_Not_Checked;
      Convergence_Action       : Final_Recheck_Convergence_Action := Conv.Final_Recheck_Convergence_Action_None;
      Status                   : Final_Stabilization_Gate_Status := Final_Stabilization_Gate_Not_Checked;
      Action                   : Final_Stabilization_Gate_Action := Final_Stabilization_Gate_Action_None;
      Blocker_Family           : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Priority                 : Natural := 0;
      Dependency_Depth         : Natural := 0;
      Prerequisite_Depth       : Natural := 0;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Source_Fingerprint       : Natural := 0;
      Application_Fingerprint  : Natural := 0;
      Convergence_Fingerprint  : Natural := 0;
      Stabilization_Fingerprint : Natural := 0;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Final_Stabilization_Gate_Model is private;
   type Final_Stabilization_Gate_Set is private;

   procedure Clear (Model : in out Final_Stabilization_Gate_Model);

   function Build
     (Convergence : Conv.Final_Recheck_Convergence_Model)
      return Final_Stabilization_Gate_Model;

   function Row_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Row_At
     (Model : Final_Stabilization_Gate_Model;
      Index : Positive) return Final_Stabilization_Gate_Row;

   function Query_Count (Set : Final_Stabilization_Gate_Set) return Natural;
   function Query_At
     (Set   : Final_Stabilization_Gate_Set;
      Index : Positive) return Final_Stabilization_Gate_Row;

   function Query_Status
     (Model  : Final_Stabilization_Gate_Model;
      Status : Final_Stabilization_Gate_Status) return Final_Stabilization_Gate_Set;
   function Query_Action
     (Model  : Final_Stabilization_Gate_Model;
      Action : Final_Stabilization_Gate_Action) return Final_Stabilization_Gate_Set;
   function Query_Blocker
     (Model   : Final_Stabilization_Gate_Model;
      Blocker : Final_Blocker_Family) return Final_Stabilization_Gate_Set;
   function Query_Node
     (Model : Final_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Stabilization_Gate_Set;

   function Count_Status
     (Model  : Final_Stabilization_Gate_Model;
      Status : Final_Stabilization_Gate_Status) return Natural;
   function Count_Action
     (Model  : Final_Stabilization_Gate_Model;
      Action : Final_Stabilization_Gate_Action) return Natural;
   function Count_Blocker
     (Model   : Final_Stabilization_Gate_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Promoted_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Withheld_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Recheck_Required_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Indeterminate_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Stale_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function AST_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Cross_Unit_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Generic_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Overload_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Representation_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Flow_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Tasking_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Elaboration_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Accessibility_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Discriminant_Count (Model : Final_Stabilization_Gate_Model) return Natural;
   function Fingerprint (Model : Final_Stabilization_Gate_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Stabilization_Gate_Row);

   type Final_Stabilization_Gate_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Stabilization_Gate_Model is record
      Rows                  : Row_Vectors.Vector;
      Promoted_Total        : Natural := 0;
      Withheld_Total        : Natural := 0;
      Recheck_Total         : Natural := 0;
      Preserved_Error_Total : Natural := 0;
      Indeterminate_Total   : Natural := 0;
      Stale_Total           : Natural := 0;
      AST_Total             : Natural := 0;
      Cross_Unit_Total      : Natural := 0;
      Generic_Total         : Natural := 0;
      Overload_Total        : Natural := 0;
      Representation_Total  : Natural := 0;
      Flow_Total            : Natural := 0;
      Tasking_Total         : Natural := 0;
      Elaboration_Total     : Natural := 0;
      Accessibility_Total   : Natural := 0;
      Discriminant_Total    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Stabilization_Gate_Legality;
