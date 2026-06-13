with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality is

   --  Pass1247 representation/freezing RM hard-case completion legality.
   --
   --  This package consumes the stabilized generic/shared-state final closure
   --  from Pass1245, the representation/generic/shared-state final legality
   --  from Pass1229, and the overload/generic/shared-state RM edge completion
   --  from Pass1246.  It deepens remaining Ada representation and freezing
   --  hard cases where accepted representation conclusions are still unsafe
   --  unless volatile/atomic representation clauses, independent components,
   --  limited/private stream views, inherited operational attributes, generic
   --  formal/instance freezing, discriminant-dependent layout, controlled or
   --  finalized components, and protected/task representation effects agree
   --  with the stabilized generic/shared-state closure evidence.

   package Previous renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Overload_Edges renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Closure renames Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;

   type Representation_Generic_RM_Hard_Case_Id is new Natural;
   No_Representation_Generic_RM_Hard_Case : constant Representation_Generic_RM_Hard_Case_Id := 0;

   type Representation_Generic_RM_Hard_Case_Kind is
     (Representation_Generic_RM_Hard_Case_Volatile_Atomic_Representation_Clause,
      Representation_Generic_RM_Hard_Case_Independent_Component,
      Representation_Generic_RM_Hard_Case_Limited_Private_Stream_Attribute,
      Representation_Generic_RM_Hard_Case_Inherited_Operational_Attribute,
      Representation_Generic_RM_Hard_Case_Generic_Formal_Instance_Freezing,
      Representation_Generic_RM_Hard_Case_Discriminant_Dependent_Layout,
      Representation_Generic_RM_Hard_Case_Controlled_Finalized_Component,
      Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Effect,
      Representation_Generic_RM_Hard_Case_Unknown);

   type Representation_Generic_RM_Hard_Case_Blocker_Family is
     (Representation_Generic_RM_Hard_Case_Blocker_None,
      Representation_Generic_RM_Hard_Case_Blocker_Previous_Representation,
      Representation_Generic_RM_Hard_Case_Blocker_Overload_RM_Edge,
      Representation_Generic_RM_Hard_Case_Blocker_Stabilized_Closure,
      Representation_Generic_RM_Hard_Case_Blocker_Volatile_Atomic_Clause,
      Representation_Generic_RM_Hard_Case_Blocker_Independent_Component,
      Representation_Generic_RM_Hard_Case_Blocker_Limited_Private_View,
      Representation_Generic_RM_Hard_Case_Blocker_Inherited_Operational_Attribute,
      Representation_Generic_RM_Hard_Case_Blocker_Generic_Freezing,
      Representation_Generic_RM_Hard_Case_Blocker_Discriminant_Layout,
      Representation_Generic_RM_Hard_Case_Blocker_Controlled_Finalization,
      Representation_Generic_RM_Hard_Case_Blocker_Protected_Task_Representation,
      Representation_Generic_RM_Hard_Case_Blocker_Source_Fingerprint,
      Representation_Generic_RM_Hard_Case_Blocker_Substitution_Fingerprint,
      Representation_Generic_RM_Hard_Case_Blocker_Multiple,
      Representation_Generic_RM_Hard_Case_Blocker_Indeterminate);

   type Representation_Generic_RM_Hard_Case_Status is
     (Representation_Generic_RM_Hard_Case_Not_Checked,
      Representation_Generic_RM_Hard_Case_Legal_Volatile_Atomic_Representation_Clause_Accepted,
      Representation_Generic_RM_Hard_Case_Legal_Independent_Component_Accepted,
      Representation_Generic_RM_Hard_Case_Legal_Limited_Private_Stream_Attribute_Accepted,
      Representation_Generic_RM_Hard_Case_Legal_Inherited_Operational_Attribute_Accepted,
      Representation_Generic_RM_Hard_Case_Legal_Generic_Formal_Instance_Freezing_Accepted,
      Representation_Generic_RM_Hard_Case_Legal_Discriminant_Dependent_Layout_Accepted,
      Representation_Generic_RM_Hard_Case_Legal_Controlled_Finalized_Component_Accepted,
      Representation_Generic_RM_Hard_Case_Legal_Protected_Task_Representation_Effect_Accepted,
      Representation_Generic_RM_Hard_Case_Missing_Previous_Representation_Row,
      Representation_Generic_RM_Hard_Case_Previous_Representation_Blocker,
      Representation_Generic_RM_Hard_Case_Missing_Overload_RM_Edge_Row,
      Representation_Generic_RM_Hard_Case_Overload_RM_Edge_Blocker,
      Representation_Generic_RM_Hard_Case_Missing_Stabilized_Closure_Row,
      Representation_Generic_RM_Hard_Case_Stabilized_Closure_Blocker,
      Representation_Generic_RM_Hard_Case_Volatile_Atomic_Clause_Blocker,
      Representation_Generic_RM_Hard_Case_Independent_Component_Blocker,
      Representation_Generic_RM_Hard_Case_Limited_Private_View_Blocker,
      Representation_Generic_RM_Hard_Case_Inherited_Operational_Attribute_Blocker,
      Representation_Generic_RM_Hard_Case_Generic_Freezing_Blocker,
      Representation_Generic_RM_Hard_Case_Discriminant_Layout_Blocker,
      Representation_Generic_RM_Hard_Case_Controlled_Finalization_Blocker,
      Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Blocker,
      Representation_Generic_RM_Hard_Case_Source_Fingerprint_Mismatch,
      Representation_Generic_RM_Hard_Case_Substitution_Fingerprint_Mismatch,
      Representation_Generic_RM_Hard_Case_Multiple_Blockers,
      Representation_Generic_RM_Hard_Case_Indeterminate);

   type Representation_Generic_RM_Hard_Case_Context is record
      Id                         : Representation_Generic_RM_Hard_Case_Id := No_Representation_Generic_RM_Hard_Case;
      Kind                       : Representation_Generic_RM_Hard_Case_Kind := Representation_Generic_RM_Hard_Case_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Previous_Representation_Row : Previous.Representation_Generic_Final_Row_Id := Previous.No_Representation_Generic_Final_Row;
      Previous_Representation_Status : Previous.Representation_Generic_Final_Status := Previous.Representation_Generic_Final_Not_Checked;
      Overload_RM_Edge_Row       : Overload_Edges.Overload_Generic_RM_Edge_Completion_Id := Overload_Edges.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Edge_Status    : Overload_Edges.Overload_Generic_RM_Edge_Status := Overload_Edges.Overload_Generic_RM_Edge_Not_Checked;
      Stabilized_Closure_Row     : Closure.Generic_Shared_State_Final_Stabilized_Closure_Id := Closure.No_Generic_Shared_State_Final_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Generic_Shared_State_Final_Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Not_Checked;
      Requires_Previous_Representation : Boolean := True;
      Requires_Overload_RM_Edge : Boolean := True;
      Requires_Stabilized_Closure : Boolean := True;
      Volatile_Atomic_Clause_Blocker : Boolean := False;
      Independent_Component_Blocker : Boolean := False;
      Limited_Private_View_Blocker : Boolean := False;
      Inherited_Operational_Attribute_Blocker : Boolean := False;
      Generic_Freezing_Blocker   : Boolean := False;
      Discriminant_Layout_Blocker : Boolean := False;
      Controlled_Finalization_Blocker : Boolean := False;
      Protected_Task_Representation_Blocker : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Representation_Generic_RM_Hard_Case_Row is record
      Id                         : Representation_Generic_RM_Hard_Case_Id := No_Representation_Generic_RM_Hard_Case;
      Context                    : Representation_Generic_RM_Hard_Case_Id := No_Representation_Generic_RM_Hard_Case;
      Kind                       : Representation_Generic_RM_Hard_Case_Kind := Representation_Generic_RM_Hard_Case_Unknown;
      Status                     : Representation_Generic_RM_Hard_Case_Status := Representation_Generic_RM_Hard_Case_Not_Checked;
      Blocker_Family             : Representation_Generic_RM_Hard_Case_Blocker_Family := Representation_Generic_RM_Hard_Case_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Row_Fingerprint            : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Representation_Generic_RM_Hard_Case_Context_Model is private;
   type Representation_Generic_RM_Hard_Case_Model is private;
   type Representation_Generic_RM_Hard_Case_Set is private;

   procedure Clear (Model : in out Representation_Generic_RM_Hard_Case_Context_Model);
   procedure Add_Context
     (Model   : in out Representation_Generic_RM_Hard_Case_Context_Model;
      Context : Representation_Generic_RM_Hard_Case_Context);
   function Context_Count (Model : Representation_Generic_RM_Hard_Case_Context_Model) return Natural;
   function Context_At
     (Model : Representation_Generic_RM_Hard_Case_Context_Model;
      Index : Positive) return Representation_Generic_RM_Hard_Case_Context;
   function Context_Fingerprint (Model : Representation_Generic_RM_Hard_Case_Context_Model) return Natural;

   function Build (Contexts : Representation_Generic_RM_Hard_Case_Context_Model) return Representation_Generic_RM_Hard_Case_Model;
   function Count (Model : Representation_Generic_RM_Hard_Case_Model) return Natural;
   function Row_Count (Model : Representation_Generic_RM_Hard_Case_Model) return Natural renames Count;
   function Row_At
     (Model : Representation_Generic_RM_Hard_Case_Model;
      Index : Positive) return Representation_Generic_RM_Hard_Case_Row;

   function Query_Count (Set : Representation_Generic_RM_Hard_Case_Set) return Natural;
   function Query_At
     (Set   : Representation_Generic_RM_Hard_Case_Set;
      Index : Positive) return Representation_Generic_RM_Hard_Case_Row;
   function Query_Status
     (Model  : Representation_Generic_RM_Hard_Case_Model;
      Status : Representation_Generic_RM_Hard_Case_Status) return Representation_Generic_RM_Hard_Case_Set;
   function Query_Blocker_Family
     (Model  : Representation_Generic_RM_Hard_Case_Model;
      Family : Representation_Generic_RM_Hard_Case_Blocker_Family) return Representation_Generic_RM_Hard_Case_Set;
   function Find_By_Node
     (Model : Representation_Generic_RM_Hard_Case_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Generic_RM_Hard_Case_Set;
   function Find_By_Source_Fingerprint
     (Model              : Representation_Generic_RM_Hard_Case_Model;
      Source_Fingerprint : Natural) return Representation_Generic_RM_Hard_Case_Set;

   function Count_By_Status
     (Model  : Representation_Generic_RM_Hard_Case_Model;
      Status : Representation_Generic_RM_Hard_Case_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Representation_Generic_RM_Hard_Case_Model;
      Family : Representation_Generic_RM_Hard_Case_Blocker_Family) return Natural;
   function Accepted_Count (Model : Representation_Generic_RM_Hard_Case_Model) return Natural;
   function Blocked_Count (Model : Representation_Generic_RM_Hard_Case_Model) return Natural;
   function Indeterminate_Count (Model : Representation_Generic_RM_Hard_Case_Model) return Natural;
   function Stable_Fingerprint (Model : Representation_Generic_RM_Hard_Case_Model) return Natural;

   function Is_Accepted (Status : Representation_Generic_RM_Hard_Case_Status) return Boolean;
   function Is_Blocked (Status : Representation_Generic_RM_Hard_Case_Status) return Boolean;
   function Is_Indeterminate (Status : Representation_Generic_RM_Hard_Case_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Generic_RM_Hard_Case_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Generic_RM_Hard_Case_Row);

   type Representation_Generic_RM_Hard_Case_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Representation_Generic_RM_Hard_Case_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Representation_Generic_RM_Hard_Case_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
