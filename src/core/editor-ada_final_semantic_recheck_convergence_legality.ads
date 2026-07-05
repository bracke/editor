with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Recheck_Convergence_Legality is

   --  Case 1207 final semantic recheck convergence legality.
   --
   --  This package consumes Case 1206 final recheck application rows and
   --  classifies whether the current recheck boundary has converged, is
   --  stably withheld by a prerequisite blocker, preserved a real semantic
   --  error, remains indeterminate, or changed relative to a caller supplied
   --  prior application fingerprint.  It lets the final closure/feed boundary
   --  stop cycling on unchanged prerequisite evidence while still rejecting
   --  stale or changed semantic inputs.

   package Apply renames Editor.Ada_Final_Semantic_Recheck_Application_Legality;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Recheck_Application_Status is Apply.Final_Recheck_Application_Status;
   subtype Final_Recheck_Application_Action is Apply.Final_Recheck_Application_Action;

   type Final_Recheck_Convergence_Id is new Natural;
   No_Final_Recheck_Convergence : constant Final_Recheck_Convergence_Id := 0;

   type Final_Recheck_Convergence_Status is
     (Final_Recheck_Convergence_Not_Checked,
      Final_Recheck_Converged_Current,
      Final_Recheck_Converged_Not_Required,
      Final_Recheck_Stable_Withheld_Stale,
      Final_Recheck_Stable_Withheld_AST_Coverage,
      Final_Recheck_Stable_Withheld_Cross_Unit,
      Final_Recheck_Stable_Withheld_View_Barrier,
      Final_Recheck_Stable_Withheld_Generic_Replay,
      Final_Recheck_Stable_Withheld_Overload_Type,
      Final_Recheck_Stable_Withheld_Representation_Freezing,
      Final_Recheck_Stable_Withheld_Flow_Contract,
      Final_Recheck_Stable_Withheld_Tasking_Protected,
      Final_Recheck_Stable_Withheld_Elaboration,
      Final_Recheck_Stable_Withheld_Accessibility,
      Final_Recheck_Stable_Withheld_Discriminant_Variant,
      Final_Recheck_Stable_Preserved_Semantic_Error,
      Final_Recheck_Stable_Multiple_Prerequisites,
      Final_Recheck_Stable_Indeterminate,
      Final_Recheck_Changed_Since_Previous);

   type Final_Recheck_Convergence_Action is
     (Final_Recheck_Convergence_Action_None,
      Final_Recheck_Convergence_Action_Accept_Current,
      Final_Recheck_Convergence_Action_Skip_Not_Required,
      Final_Recheck_Convergence_Action_Retain_Stable_Withheld,
      Final_Recheck_Convergence_Action_Retain_Error,
      Final_Recheck_Convergence_Action_Split_Prerequisites,
      Final_Recheck_Convergence_Action_Degrade,
      Final_Recheck_Convergence_Action_Recheck_Again);

   type Final_Recheck_Convergence_Row is record
      Id                       : Final_Recheck_Convergence_Id := No_Final_Recheck_Convergence;
      Application_Id           : Apply.Final_Recheck_Application_Id := Apply.No_Final_Recheck_Application;
      Application_Status       : Final_Recheck_Application_Status := Apply.Final_Recheck_Application_Not_Checked;
      Application_Action       : Final_Recheck_Application_Action := Apply.Final_Recheck_Application_Action_None;
      Status                   : Final_Recheck_Convergence_Status := Final_Recheck_Convergence_Not_Checked;
      Action                   : Final_Recheck_Convergence_Action := Final_Recheck_Convergence_Action_None;
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
      Previous_Model_Fingerprint : Natural := 0;
      Convergence_Fingerprint  : Natural := 0;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Final_Recheck_Convergence_Model is private;
   type Final_Recheck_Convergence_Set is private;

   procedure Clear (Model : in out Final_Recheck_Convergence_Model);

   function Build
     (Applications : Apply.Final_Recheck_Application_Model;
      Previous_Model_Fingerprint : Natural := 0)
      return Final_Recheck_Convergence_Model;

   function Row_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Row_At
     (Model : Final_Recheck_Convergence_Model;
      Index : Positive) return Final_Recheck_Convergence_Row;

   function Query_Count (Set : Final_Recheck_Convergence_Set) return Natural;
   function Query_At
     (Set   : Final_Recheck_Convergence_Set;
      Index : Positive) return Final_Recheck_Convergence_Row;

   function Query_Status
     (Model  : Final_Recheck_Convergence_Model;
      Status : Final_Recheck_Convergence_Status) return Final_Recheck_Convergence_Set;
   function Query_Action
     (Model  : Final_Recheck_Convergence_Model;
      Action : Final_Recheck_Convergence_Action) return Final_Recheck_Convergence_Set;
   function Query_Blocker
     (Model   : Final_Recheck_Convergence_Model;
      Blocker : Final_Blocker_Family) return Final_Recheck_Convergence_Set;
   function Query_Node
     (Model : Final_Recheck_Convergence_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Recheck_Convergence_Set;

   function Count_Status
     (Model  : Final_Recheck_Convergence_Model;
      Status : Final_Recheck_Convergence_Status) return Natural;
   function Count_Action
     (Model  : Final_Recheck_Convergence_Model;
      Action : Final_Recheck_Convergence_Action) return Natural;
   function Count_Blocker
     (Model   : Final_Recheck_Convergence_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Converged_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Stable_Withheld_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Changed_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Stale_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function AST_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Cross_Unit_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Generic_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Overload_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Representation_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Flow_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Tasking_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Elaboration_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Accessibility_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Discriminant_Stable_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Multiple_Prerequisite_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Indeterminate_Count (Model : Final_Recheck_Convergence_Model) return Natural;
   function Fingerprint (Model : Final_Recheck_Convergence_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Recheck_Convergence_Row);

   type Final_Recheck_Convergence_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Recheck_Convergence_Model is record
      Rows                         : Row_Vectors.Vector;
      Converged_Total              : Natural := 0;
      Stable_Withheld_Total        : Natural := 0;
      Changed_Total                : Natural := 0;
      Stale_Total                  : Natural := 0;
      AST_Total                    : Natural := 0;
      Cross_Unit_Total             : Natural := 0;
      Generic_Total                : Natural := 0;
      Overload_Total               : Natural := 0;
      Representation_Total         : Natural := 0;
      Flow_Total                   : Natural := 0;
      Tasking_Total                : Natural := 0;
      Elaboration_Total            : Natural := 0;
      Accessibility_Total          : Natural := 0;
      Discriminant_Total           : Natural := 0;
      Preserved_Error_Total        : Natural := 0;
      Multiple_Prerequisite_Total  : Natural := 0;
      Indeterminate_Total          : Natural := 0;
      Fingerprint                  : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Recheck_Convergence_Legality;
