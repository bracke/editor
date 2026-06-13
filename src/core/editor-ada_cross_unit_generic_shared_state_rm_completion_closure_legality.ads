with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
with Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;

package Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality is

   --  Pass1250 cross-unit closure for the completed generic/shared-state RM chain.
   --
   --  This package consumes the earlier cross-unit generic/shared-state final
   --  closure together with the stabilized generic/shared-state closure and the
   --  completed overload/type, representation/freezing, tasking/protected, and
   --  coverage-proven AST repair RM evidence.  A cross-unit conclusion is current
   --  only when the unit dependency is visible, fingerprints still match, and all
   --  required completed RM families agree.  Dependency, view, generic-body,
   --  source/instance backmapping, state-visibility, AST repair, and family-specific
   --  blockers are preserved as first-class downstream blockers.

   package Prior_Cross renames Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
   package Stabilized renames Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;
   package Overload_RM renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Representation_RM renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Tasking_RM renames Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package AST_Repair renames Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;

   type Cross_Unit_RM_Completion_Closure_Id is new Natural;
   No_Cross_Unit_RM_Completion_Closure : constant Cross_Unit_RM_Completion_Closure_Id := 0;

   type Cross_Unit_RM_Completion_Kind is
     (Cross_Unit_RM_Completion_Local,
      Cross_Unit_RM_Completion_Spec_Body,
      Cross_Unit_RM_Completion_With_Use,
      Cross_Unit_RM_Completion_Parent_Child,
      Cross_Unit_RM_Completion_Private_Child,
      Cross_Unit_RM_Completion_Separate_Body,
      Cross_Unit_RM_Completion_Generic_Instance,
      Cross_Unit_RM_Completion_Generic_Body,
      Cross_Unit_RM_Completion_Abstract_State,
      Cross_Unit_RM_Completion_Volatile_Atomic,
      Cross_Unit_RM_Completion_Overload_Type,
      Cross_Unit_RM_Completion_Representation,
      Cross_Unit_RM_Completion_Tasking_Protected,
      Cross_Unit_RM_Completion_AST_Repair,
      Cross_Unit_RM_Completion_Unknown);

   type Cross_Unit_RM_Dependency_State is
     (RM_Dependency_Local,
      RM_Dependency_Spec_Body_Closed,
      RM_Dependency_With_Visible,
      RM_Dependency_Use_Visible,
      RM_Dependency_Parent_Visible,
      RM_Dependency_Child_Visible,
      RM_Dependency_Private_Child_Visible,
      RM_Dependency_Separate_Body_Linked,
      RM_Dependency_Generic_Instance_Visible,
      RM_Dependency_Generic_Body_Visible,
      RM_Dependency_Missing,
      RM_Dependency_Ambiguous,
      RM_Dependency_Overflow,
      RM_Dependency_Stale,
      RM_Dependency_Unknown);

   type Cross_Unit_RM_Completion_Blocker_Family is
     (Cross_Unit_RM_Completion_Blocker_None,
      Cross_Unit_RM_Completion_Blocker_Prior_Cross_Unit_Generic_Shared_State,
      Cross_Unit_RM_Completion_Blocker_Stabilized_Generic_Shared_State,
      Cross_Unit_RM_Completion_Blocker_Overload_RM_Completion,
      Cross_Unit_RM_Completion_Blocker_Representation_RM_Completion,
      Cross_Unit_RM_Completion_Blocker_Tasking_RM_Completion,
      Cross_Unit_RM_Completion_Blocker_AST_Repair,
      Cross_Unit_RM_Completion_Blocker_Dependency,
      Cross_Unit_RM_Completion_Blocker_View_Barrier,
      Cross_Unit_RM_Completion_Blocker_Generic_Backmapping,
      Cross_Unit_RM_Completion_Blocker_Generic_Body,
      Cross_Unit_RM_Completion_Blocker_State_Visibility,
      Cross_Unit_RM_Completion_Blocker_Separate_Body,
      Cross_Unit_RM_Completion_Blocker_Private_Child,
      Cross_Unit_RM_Completion_Blocker_Source_Fingerprint,
      Cross_Unit_RM_Completion_Blocker_Substitution_Fingerprint,
      Cross_Unit_RM_Completion_Blocker_Multiple,
      Cross_Unit_RM_Completion_Blocker_Indeterminate);

   type Cross_Unit_RM_Completion_Status is
     (Cross_Unit_RM_Completion_Not_Checked,
      Cross_Unit_RM_Completion_Legal_Local_Accepted,
      Cross_Unit_RM_Completion_Legal_Spec_Body_Accepted,
      Cross_Unit_RM_Completion_Legal_With_Use_Accepted,
      Cross_Unit_RM_Completion_Legal_Parent_Child_Accepted,
      Cross_Unit_RM_Completion_Legal_Private_Child_Accepted,
      Cross_Unit_RM_Completion_Legal_Separate_Body_Accepted,
      Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted,
      Cross_Unit_RM_Completion_Legal_Generic_Body_Accepted,
      Cross_Unit_RM_Completion_Legal_Abstract_State_Accepted,
      Cross_Unit_RM_Completion_Legal_Volatile_Atomic_Accepted,
      Cross_Unit_RM_Completion_Legal_Overload_Type_Accepted,
      Cross_Unit_RM_Completion_Legal_Representation_Accepted,
      Cross_Unit_RM_Completion_Legal_Tasking_Protected_Accepted,
      Cross_Unit_RM_Completion_Legal_AST_Repair_Accepted,
      Cross_Unit_RM_Completion_Missing_Prior_Cross_Row,
      Cross_Unit_RM_Completion_Prior_Cross_Blocker,
      Cross_Unit_RM_Completion_Missing_Stabilized_Row,
      Cross_Unit_RM_Completion_Stabilized_Blocker,
      Cross_Unit_RM_Completion_Missing_Overload_RM_Row,
      Cross_Unit_RM_Completion_Overload_RM_Blocker,
      Cross_Unit_RM_Completion_Missing_Representation_RM_Row,
      Cross_Unit_RM_Completion_Representation_RM_Blocker,
      Cross_Unit_RM_Completion_Missing_Tasking_RM_Row,
      Cross_Unit_RM_Completion_Tasking_RM_Blocker,
      Cross_Unit_RM_Completion_Missing_AST_Repair_Row,
      Cross_Unit_RM_Completion_AST_Repair_Blocker,
      Cross_Unit_RM_Completion_Missing_Dependency,
      Cross_Unit_RM_Completion_Ambiguous_Dependency,
      Cross_Unit_RM_Completion_Dependency_Overflow,
      Cross_Unit_RM_Completion_Stale_Dependency,
      Cross_Unit_RM_Completion_Limited_View_Barrier,
      Cross_Unit_RM_Completion_Private_View_Barrier,
      Cross_Unit_RM_Completion_Private_Child_Visibility_Blocker,
      Cross_Unit_RM_Completion_Separate_Body_Blocker,
      Cross_Unit_RM_Completion_Generic_Body_Unavailable,
      Cross_Unit_RM_Completion_Generic_Backmapping_Blocker,
      Cross_Unit_RM_Completion_State_Visibility_Blocker,
      Cross_Unit_RM_Completion_Source_Fingerprint_Mismatch,
      Cross_Unit_RM_Completion_Substitution_Fingerprint_Mismatch,
      Cross_Unit_RM_Completion_Multiple_Blockers,
      Cross_Unit_RM_Completion_Indeterminate);

   type Cross_Unit_RM_Completion_Context is record
      Id                         : Cross_Unit_RM_Completion_Closure_Id := No_Cross_Unit_RM_Completion_Closure;
      Kind                       : Cross_Unit_RM_Completion_Kind := Cross_Unit_RM_Completion_Unknown;
      Dependency                 : Cross_Unit_RM_Dependency_State := RM_Dependency_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Prior_Cross_Row            : Prior_Cross.Cross_Unit_Generic_Final_Row_Id := Prior_Cross.No_Cross_Unit_Generic_Final_Row;
      Prior_Cross_Status         : Prior_Cross.Cross_Unit_Generic_Final_Status := Prior_Cross.Cross_Unit_Generic_Final_Not_Checked;
      Stabilized_Row             : Stabilized.Generic_Shared_State_Final_Stabilized_Closure_Id := Stabilized.No_Generic_Shared_State_Final_Stabilized_Closure;
      Stabilized_Status          : Stabilized.Generic_Shared_State_Final_Stabilized_Closure_Status := Stabilized.Generic_Shared_State_Final_Stabilized_Closure_Not_Checked;
      Overload_RM_Row            : Overload_RM.Overload_Generic_RM_Edge_Completion_Id := Overload_RM.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Status         : Overload_RM.Overload_Generic_RM_Edge_Status := Overload_RM.Overload_Generic_RM_Edge_Not_Checked;
      Representation_RM_Row      : Representation_RM.Representation_Generic_RM_Hard_Case_Id := Representation_RM.No_Representation_Generic_RM_Hard_Case;
      Representation_RM_Status   : Representation_RM.Representation_Generic_RM_Hard_Case_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Not_Checked;
      Tasking_RM_Row             : Tasking_RM.Tasking_Generic_RM_Hard_Case_Id := Tasking_RM.No_Tasking_Generic_RM_Hard_Case;
      Tasking_RM_Status          : Tasking_RM.Tasking_Generic_RM_Hard_Case_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Not_Checked;
      AST_Repair_Row             : AST_Repair.Coverage_Proven_AST_Repair_Id := AST_Repair.No_Coverage_Proven_AST_Repair;
      AST_Repair_Status          : AST_Repair.Coverage_Proven_AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Not_Checked;
      Requires_Prior_Cross       : Boolean := True;
      Requires_Stabilized        : Boolean := True;
      Requires_Overload_RM       : Boolean := True;
      Requires_Representation_RM : Boolean := True;
      Requires_Tasking_RM        : Boolean := True;
      Requires_AST_Repair        : Boolean := False;
      Limited_View_Barrier       : Boolean := False;
      Private_View_Barrier       : Boolean := False;
      Private_Child_Visibility_Blocker : Boolean := False;
      Separate_Body_Blocker      : Boolean := False;
      Generic_Body_Unavailable   : Boolean := False;
      Generic_Backmapping_Blocker : Boolean := False;
      State_Visibility_Blocker   : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Cross_Unit_RM_Completion_Row is record
      Id                         : Cross_Unit_RM_Completion_Closure_Id := No_Cross_Unit_RM_Completion_Closure;
      Context                    : Cross_Unit_RM_Completion_Closure_Id := No_Cross_Unit_RM_Completion_Closure;
      Kind                       : Cross_Unit_RM_Completion_Kind := Cross_Unit_RM_Completion_Unknown;
      Dependency                 : Cross_Unit_RM_Dependency_State := RM_Dependency_Unknown;
      Status                     : Cross_Unit_RM_Completion_Status := Cross_Unit_RM_Completion_Not_Checked;
      Blocker_Family             : Cross_Unit_RM_Completion_Blocker_Family := Cross_Unit_RM_Completion_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Cross_Unit_RM_Completion_Context_Model is private;
   type Cross_Unit_RM_Completion_Model is private;
   type Cross_Unit_RM_Completion_Set is private;

   procedure Clear (Model : in out Cross_Unit_RM_Completion_Context_Model);
   procedure Add_Context (Model : in out Cross_Unit_RM_Completion_Context_Model; Info : Cross_Unit_RM_Completion_Context);
   function Context_Count (Model : Cross_Unit_RM_Completion_Context_Model) return Natural;
   function Context_At (Model : Cross_Unit_RM_Completion_Context_Model; Index : Positive) return Cross_Unit_RM_Completion_Context;
   function Context_Fingerprint (Model : Cross_Unit_RM_Completion_Context_Model) return Natural;

   function Build (Contexts : Cross_Unit_RM_Completion_Context_Model) return Cross_Unit_RM_Completion_Model;
   function Count (Model : Cross_Unit_RM_Completion_Model) return Natural;
   function Row_Count (Model : Cross_Unit_RM_Completion_Model) return Natural renames Count;
   function Row_At (Model : Cross_Unit_RM_Completion_Model; Index : Positive) return Cross_Unit_RM_Completion_Row;
   function Query_Count (Set : Cross_Unit_RM_Completion_Set) return Natural;
   function Query_At (Set : Cross_Unit_RM_Completion_Set; Index : Positive) return Cross_Unit_RM_Completion_Row;
   function Query_Status (Model : Cross_Unit_RM_Completion_Model; Status : Cross_Unit_RM_Completion_Status) return Cross_Unit_RM_Completion_Set;
   function Query_Blocker_Family (Model : Cross_Unit_RM_Completion_Model; Family : Cross_Unit_RM_Completion_Blocker_Family) return Cross_Unit_RM_Completion_Set;
   function Find_By_Node (Model : Cross_Unit_RM_Completion_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_RM_Completion_Set;
   function Find_By_Source_Fingerprint (Model : Cross_Unit_RM_Completion_Model; Source_Fingerprint : Natural) return Cross_Unit_RM_Completion_Set;
   function Count_By_Status (Model : Cross_Unit_RM_Completion_Model; Status : Cross_Unit_RM_Completion_Status) return Natural;
   function Count_By_Blocker_Family (Model : Cross_Unit_RM_Completion_Model; Family : Cross_Unit_RM_Completion_Blocker_Family) return Natural;
   function Accepted_Count (Model : Cross_Unit_RM_Completion_Model) return Natural;
   function Blocked_Count (Model : Cross_Unit_RM_Completion_Model) return Natural;
   function Indeterminate_Count (Model : Cross_Unit_RM_Completion_Model) return Natural;
   function Stable_Fingerprint (Model : Cross_Unit_RM_Completion_Model) return Natural;

   function Is_Accepted (Status : Cross_Unit_RM_Completion_Status) return Boolean;
   function Is_Blocked (Status : Cross_Unit_RM_Completion_Status) return Boolean;
   function Is_Indeterminate (Status : Cross_Unit_RM_Completion_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Cross_Unit_RM_Completion_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Cross_Unit_RM_Completion_Row);

   type Cross_Unit_RM_Completion_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Cross_Unit_RM_Completion_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Cross_Unit_RM_Completion_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
