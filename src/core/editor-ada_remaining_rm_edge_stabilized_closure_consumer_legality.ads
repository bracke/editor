with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Precision_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Search_Index;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality is

   --  Pass1284 remaining RM edge stabilized-closure consumer legality.
   --
   --  This package consumes Pass1277 remaining Ada RM edge precision rows,
   --  Pass1280 stabilized direct RM-completion closure-consumer rows, and the
   --  Pass1283 stabilized diagnostic/provenance search index.  A remaining RM
   --  edge is accepted only when the local RM edge evidence is accepted, the
   --  matching direct-consumer stabilized closure row is current/not-required,
   --  and source/substitution fingerprints agree.  Blocked rows preserve the
   --  original remaining-edge blocker family and the stabilized closure family
   --  instead of flattening them into a generic expression blocker.

   package Edge renames Editor.Ada_Remaining_RM_Edge_Precision_Legality;
   package Closure renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
   package Search renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Search_Index;

   type Remaining_RM_Edge_Stabilized_Consumer_Id is new Natural;
   No_Remaining_RM_Edge_Stabilized_Consumer : constant Remaining_RM_Edge_Stabilized_Consumer_Id := 0;

   type Remaining_RM_Edge_Stabilized_Consumer_Status is
     (Remaining_RM_Edge_Stabilized_Consumer_Not_Checked,
      Remaining_RM_Edge_Stabilized_Consumer_Accepted_Current,
      Remaining_RM_Edge_Stabilized_Consumer_Accepted_Not_Required,
      Remaining_RM_Edge_Stabilized_Consumer_Remaining_Edge_Blocker,
      Remaining_RM_Edge_Stabilized_Consumer_Missing_Stabilized_Closure,
      Remaining_RM_Edge_Stabilized_Consumer_Stabilized_Closure_Blocker,
      Remaining_RM_Edge_Stabilized_Consumer_Stabilized_Closure_Recheck_Required,
      Remaining_RM_Edge_Stabilized_Consumer_Source_Fingerprint_Mismatch,
      Remaining_RM_Edge_Stabilized_Consumer_Substitution_Fingerprint_Mismatch,
      Remaining_RM_Edge_Stabilized_Consumer_Multiple_Blockers,
      Remaining_RM_Edge_Stabilized_Consumer_Indeterminate);

   type Remaining_RM_Edge_Stabilized_Consumer_Blocker is
     (Remaining_RM_Edge_Stabilized_Blocker_None,
      Remaining_RM_Edge_Stabilized_Blocker_Remaining_Edge,
      Remaining_RM_Edge_Stabilized_Blocker_Stabilized_Closure,
      Remaining_RM_Edge_Stabilized_Blocker_Source_Fingerprint,
      Remaining_RM_Edge_Stabilized_Blocker_Substitution_Fingerprint,
      Remaining_RM_Edge_Stabilized_Blocker_Multiple,
      Remaining_RM_Edge_Stabilized_Blocker_Indeterminate);

   type Remaining_RM_Edge_Stabilized_Consumer_Row is record
      Id                       : Remaining_RM_Edge_Stabilized_Consumer_Id := No_Remaining_RM_Edge_Stabilized_Consumer;
      Remaining_Edge_Row       : Edge.Remaining_RM_Edge_Precision_Id := Edge.No_Remaining_RM_Edge_Precision;
      Remaining_Edge_Kind      : Edge.Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Status    : Edge.Remaining_RM_Edge_Status := Edge.Remaining_RM_Edge_Not_Checked;
      Remaining_Edge_Blocker   : Edge.Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
      Stabilized_Closure_Row   : Closure.RM_Closure_Consumer_Stabilized_Closure_Id := Closure.No_RM_Closure_Consumer_Stabilized_Closure;
      Stabilized_Closure_Status : Closure.RM_Closure_Consumer_Stabilized_Closure_Status := Closure.RM_Closure_Consumer_Stabilized_Closure_Not_Checked;
      Stabilized_Closure_Family : Closure.RM_Closure_Consumer_Closure_Family := Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Unknown;
      Status                   : Remaining_RM_Edge_Stabilized_Consumer_Status := Remaining_RM_Edge_Stabilized_Consumer_Not_Checked;
      Blocker                  : Remaining_RM_Edge_Stabilized_Consumer_Blocker := Remaining_RM_Edge_Stabilized_Blocker_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Accepted                 : Boolean := False;
      Current                  : Boolean := False;
      Blocked                  : Boolean := False;
      Blocks_Downstream        : Boolean := False;
      Search_Linked            : Boolean := False;
      Search_Link_Count        : Natural := 0;
      Blocker_Count            : Natural := 0;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Edge_Fingerprint         : Natural := 0;
      Closure_Fingerprint      : Natural := 0;
      Search_Fingerprint       : Natural := 0;
      Row_Fingerprint          : Natural := 0;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Remaining_RM_Edge_Stabilized_Consumer_Model is private;
   type Remaining_RM_Edge_Stabilized_Consumer_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Consumer_Model);

   function Build
     (Edges   : Edge.Remaining_RM_Edge_Model;
      Stable  : Closure.RM_Closure_Consumer_Stabilized_Closure_Model;
      Index   : Search.RM_Closure_Consumer_Stabilized_Search_Index_Model)
      return Remaining_RM_Edge_Stabilized_Consumer_Model;

   function Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural;
   function Row_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural renames Count;
   function Row_At
     (Model : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Consumer_Row;

   function Query_Count (Set : Remaining_RM_Edge_Stabilized_Consumer_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Stabilized_Consumer_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Consumer_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Status : Remaining_RM_Edge_Stabilized_Consumer_Status)
      return Remaining_RM_Edge_Stabilized_Consumer_Set;
   function Query_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Consumer_Blocker)
      return Remaining_RM_Edge_Stabilized_Consumer_Set;
   function Query_Edge_Kind
     (Model : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Kind  : Edge.Remaining_RM_Edge_Kind)
      return Remaining_RM_Edge_Stabilized_Consumer_Set;
   function Find_By_Node
     (Model : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_Stabilized_Consumer_Set;
   function Find_By_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Consumer_Set;

   function Count_By_Status
     (Model  : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Status : Remaining_RM_Edge_Stabilized_Consumer_Status) return Natural;
   function Count_By_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Consumer_Blocker) return Natural;
   function Count_By_Edge_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Blocker : Edge.Remaining_RM_Edge_Blocker_Family) return Natural;
   function Accepted_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural;
   function Blocked_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural;
   function Search_Linked_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural;
   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural;
   function Stable_Fingerprint (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Stabilized_Consumer_Row);

   type Remaining_RM_Edge_Stabilized_Consumer_Model is record
      Rows                   : Row_Vectors.Vector;
      Accepted_Total         : Natural := 0;
      Blocked_Total          : Natural := 0;
      Search_Linked_Total    : Natural := 0;
      Recheck_Required_Total : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

   type Remaining_RM_Edge_Stabilized_Consumer_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality;
