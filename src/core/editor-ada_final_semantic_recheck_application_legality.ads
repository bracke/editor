with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Recheck_Application_Legality is

   --  Pass1206 final semantic recheck application legality.
   --
   --  This package consumes Pass1205 recheck eligibility rows and applies
   --  them back into the final semantic closure/feed boundary.  A semantic
   --  result becomes current only when its recheck prerequisite chain is
   --  eligible now.  Stale snapshots, AST/coverage gaps, cross-unit closure
   --  failures, view barriers, generic replay gaps, overload/type blockers,
   --  representation/freezing blockers, flow/contract proof blockers,
   --  tasking/protected blockers, elaboration blockers, accessibility
   --  blockers, discriminant/variant blockers, multiple prerequisites, and
   --  indeterminate rows are preserved as explicit withheld-current rows.

   package Recheck renames Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Recheck_Eligibility_Status is Recheck.Final_Recheck_Eligibility_Status;
   subtype Final_Recheck_Action is Recheck.Final_Recheck_Action;

   type Final_Recheck_Application_Id is new Natural;
   No_Final_Recheck_Application : constant Final_Recheck_Application_Id := 0;

   type Final_Recheck_Application_Status is
     (Final_Recheck_Application_Not_Checked,
      Final_Recheck_Application_Current,
      Final_Recheck_Application_Not_Required,
      Final_Recheck_Application_Withheld_Stale,
      Final_Recheck_Application_Withheld_AST_Coverage,
      Final_Recheck_Application_Withheld_Cross_Unit,
      Final_Recheck_Application_Withheld_View_Barrier,
      Final_Recheck_Application_Withheld_Generic_Replay,
      Final_Recheck_Application_Withheld_Overload_Type,
      Final_Recheck_Application_Withheld_Representation_Freezing,
      Final_Recheck_Application_Withheld_Flow_Contract,
      Final_Recheck_Application_Withheld_Tasking_Protected,
      Final_Recheck_Application_Withheld_Elaboration,
      Final_Recheck_Application_Withheld_Accessibility,
      Final_Recheck_Application_Withheld_Discriminant_Variant,
      Final_Recheck_Application_Preserved_Semantic_Error,
      Final_Recheck_Application_Withheld_Multiple_Prerequisites,
      Final_Recheck_Application_Indeterminate);

   type Final_Recheck_Application_Action is
     (Final_Recheck_Application_Action_None,
      Final_Recheck_Application_Action_Expose_Current,
      Final_Recheck_Application_Action_Skip_Not_Required,
      Final_Recheck_Application_Action_Withhold_For_Stale,
      Final_Recheck_Application_Action_Withhold_For_AST_Coverage,
      Final_Recheck_Application_Action_Withhold_For_Cross_Unit,
      Final_Recheck_Application_Action_Withhold_For_View_Barrier,
      Final_Recheck_Application_Action_Withhold_For_Generic_Replay,
      Final_Recheck_Application_Action_Withhold_For_Overload_Type,
      Final_Recheck_Application_Action_Withhold_For_Representation,
      Final_Recheck_Application_Action_Withhold_For_Flow_Contract,
      Final_Recheck_Application_Action_Withhold_For_Tasking,
      Final_Recheck_Application_Action_Withhold_For_Elaboration,
      Final_Recheck_Application_Action_Withhold_For_Accessibility,
      Final_Recheck_Application_Action_Withhold_For_Discriminants,
      Final_Recheck_Application_Action_Preserve_Error,
      Final_Recheck_Application_Action_Split_Prerequisites,
      Final_Recheck_Application_Action_Degrade);

   type Final_Recheck_Application_Row is record
      Id                         : Final_Recheck_Application_Id := No_Final_Recheck_Application;
      Eligibility_Id             : Recheck.Final_Recheck_Eligibility_Id := Recheck.No_Final_Recheck_Eligibility;
      Eligibility_Status         : Final_Recheck_Eligibility_Status := Recheck.Final_Recheck_Not_Checked;
      Eligibility_Action         : Final_Recheck_Action := Recheck.Final_Recheck_Action_None;
      Status                     : Final_Recheck_Application_Status := Final_Recheck_Application_Not_Checked;
      Action                     : Final_Recheck_Application_Action := Final_Recheck_Application_Action_None;
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
      Eligibility_Fingerprint    : Natural := 0;
      Application_Fingerprint    : Natural := 0;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Final_Recheck_Application_Model is private;
   type Final_Recheck_Application_Set is private;

   procedure Clear (Model : in out Final_Recheck_Application_Model);

   function Build
     (Eligibility : Recheck.Final_Recheck_Eligibility_Model)
      return Final_Recheck_Application_Model;

   function Row_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Row_At
     (Model : Final_Recheck_Application_Model;
      Index : Positive) return Final_Recheck_Application_Row;

   function Query_Count (Set : Final_Recheck_Application_Set) return Natural;
   function Query_At
     (Set   : Final_Recheck_Application_Set;
      Index : Positive) return Final_Recheck_Application_Row;

   function Query_Status
     (Model  : Final_Recheck_Application_Model;
      Status : Final_Recheck_Application_Status) return Final_Recheck_Application_Set;
   function Query_Action
     (Model  : Final_Recheck_Application_Model;
      Action : Final_Recheck_Application_Action) return Final_Recheck_Application_Set;
   function Query_Blocker
     (Model   : Final_Recheck_Application_Model;
      Blocker : Final_Blocker_Family) return Final_Recheck_Application_Set;
   function Query_Node
     (Model : Final_Recheck_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Recheck_Application_Set;

   function Count_Status
     (Model  : Final_Recheck_Application_Model;
      Status : Final_Recheck_Application_Status) return Natural;
   function Count_Action
     (Model  : Final_Recheck_Application_Model;
      Action : Final_Recheck_Application_Action) return Natural;
   function Count_Blocker
     (Model   : Final_Recheck_Application_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Current_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Stale_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function AST_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Cross_Unit_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Generic_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Overload_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Representation_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Flow_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Tasking_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Elaboration_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Accessibility_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Discriminant_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Multiple_Prerequisite_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Indeterminate_Count (Model : Final_Recheck_Application_Model) return Natural;
   function Fingerprint (Model : Final_Recheck_Application_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Recheck_Application_Row);

   type Final_Recheck_Application_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Recheck_Application_Model is record
      Rows                         : Row_Vectors.Vector;
      Current_Total                : Natural := 0;
      Withheld_Total               : Natural := 0;
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

end Editor.Ada_Final_Semantic_Recheck_Application_Legality;
