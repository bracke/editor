with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Stabilization_Gate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Stabilized_Closure_Legality is

   --  Case 1209 final stabilized semantic closure legality.
   --
   --  This package consumes Case 1208 stabilization-gate rows and turns them
   --  into first-class integrated-closure inputs.  Stable accepted rows are
   --  promoted as closure-accepted rows; stable withheld rows are preserved as
   --  closure blockers with their original prerequisite blocker family; changed
   --  or indeterminate rows remain withheld rather than being exposed as
   --  confident diagnostics/feed results.

   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;
   package Gate renames Editor.Ada_Final_Semantic_Stabilization_Gate_Legality;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Stabilization_Gate_Status is Gate.Final_Stabilization_Gate_Status;
   subtype Final_Stabilization_Gate_Action is Gate.Final_Stabilization_Gate_Action;

   type Final_Stabilized_Closure_Id is new Natural;
   No_Final_Stabilized_Closure : constant Final_Stabilized_Closure_Id := 0;

   type Final_Stabilized_Closure_Status is
     (Final_Stabilized_Closure_Not_Checked,
      Final_Stabilized_Closure_Accepted_Current,
      Final_Stabilized_Closure_Accepted_Not_Required,
      Final_Stabilized_Closure_Blocker_Stale,
      Final_Stabilized_Closure_Blocker_AST_Coverage,
      Final_Stabilized_Closure_Blocker_Cross_Unit,
      Final_Stabilized_Closure_Blocker_View_Barrier,
      Final_Stabilized_Closure_Blocker_Generic_Replay,
      Final_Stabilized_Closure_Blocker_Overload_Type,
      Final_Stabilized_Closure_Blocker_Representation_Freezing,
      Final_Stabilized_Closure_Blocker_Flow_Contract,
      Final_Stabilized_Closure_Blocker_Tasking_Protected,
      Final_Stabilized_Closure_Blocker_Elaboration,
      Final_Stabilized_Closure_Blocker_Accessibility,
      Final_Stabilized_Closure_Blocker_Discriminant_Variant,
      Final_Stabilized_Closure_Blocker_Preserved_Semantic_Error,
      Final_Stabilized_Closure_Blocker_Multiple_Prerequisites,
      Final_Stabilized_Closure_Indeterminate,
      Final_Stabilized_Closure_Recheck_Required);

   type Final_Stabilized_Closure_Action is
     (Final_Stabilized_Closure_Action_None,
      Final_Stabilized_Closure_Action_Accept,
      Final_Stabilized_Closure_Action_Accept_Not_Required,
      Final_Stabilized_Closure_Action_Block_Prerequisite,
      Final_Stabilized_Closure_Action_Retain_Error,
      Final_Stabilized_Closure_Action_Split_Prerequisites,
      Final_Stabilized_Closure_Action_Degrade,
      Final_Stabilized_Closure_Action_Recheck);

   type Final_Stabilized_Closure_Row is record
      Id                         : Final_Stabilized_Closure_Id := No_Final_Stabilized_Closure;
      Stabilization_Id           : Gate.Final_Stabilization_Gate_Id := Gate.No_Final_Stabilization_Gate;
      Stabilization_Status       : Final_Stabilization_Gate_Status := Gate.Final_Stabilization_Gate_Not_Checked;
      Stabilization_Action       : Final_Stabilization_Gate_Action := Gate.Final_Stabilization_Gate_Action_None;
      Status                     : Final_Stabilized_Closure_Status := Final_Stabilized_Closure_Not_Checked;
      Action                     : Final_Stabilized_Closure_Action := Final_Stabilized_Closure_Action_None;
      Blocker_Family             : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Priority                   : Natural := 0;
      Dependency_Depth           : Natural := 0;
      Prerequisite_Depth         : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Application_Fingerprint    : Natural := 0;
      Convergence_Fingerprint    : Natural := 0;
      Stabilization_Fingerprint  : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Final_Stabilized_Closure_Model is private;
   type Final_Stabilized_Closure_Set is private;

   procedure Clear (Model : in out Final_Stabilized_Closure_Model);

   function Build
     (Stabilization : Gate.Final_Stabilization_Gate_Model)
      return Final_Stabilized_Closure_Model;

   function Row_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Row_At
     (Model : Final_Stabilized_Closure_Model;
      Index : Positive) return Final_Stabilized_Closure_Row;

   function Query_Count (Set : Final_Stabilized_Closure_Set) return Natural;
   function Query_At
     (Set   : Final_Stabilized_Closure_Set;
      Index : Positive) return Final_Stabilized_Closure_Row;

   function Query_Status
     (Model  : Final_Stabilized_Closure_Model;
      Status : Final_Stabilized_Closure_Status) return Final_Stabilized_Closure_Set;
   function Query_Action
     (Model  : Final_Stabilized_Closure_Model;
      Action : Final_Stabilized_Closure_Action) return Final_Stabilized_Closure_Set;
   function Query_Blocker
     (Model   : Final_Stabilized_Closure_Model;
      Blocker : Final_Blocker_Family) return Final_Stabilized_Closure_Set;
   function Query_Node
     (Model : Final_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Stabilized_Closure_Set;

   function Count_Status
     (Model  : Final_Stabilized_Closure_Model;
      Status : Final_Stabilized_Closure_Status) return Natural;
   function Count_Action
     (Model  : Final_Stabilized_Closure_Model;
      Action : Final_Stabilized_Closure_Action) return Natural;
   function Count_Blocker
     (Model   : Final_Stabilized_Closure_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Accepted_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Blocked_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Recheck_Required_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Indeterminate_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Stale_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function AST_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Cross_Unit_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Generic_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Overload_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Representation_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Flow_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Tasking_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Elaboration_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Accessibility_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Discriminant_Count (Model : Final_Stabilized_Closure_Model) return Natural;
   function Fingerprint (Model : Final_Stabilized_Closure_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Stabilized_Closure_Row);

   type Final_Stabilized_Closure_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Stabilized_Closure_Model is record
      Rows                  : Row_Vectors.Vector;
      Accepted_Total        : Natural := 0;
      Blocked_Total         : Natural := 0;
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

end Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
