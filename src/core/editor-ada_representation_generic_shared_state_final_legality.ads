with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;

package Editor.Ada_Representation_Generic_Shared_State_Final_Legality is

   --  Case 1229 representation/generic/shared-state final legality.
   --
   --  This package consumes final representation/freezing evidence together
   --  with generic abstract-state replay, overload/generic shared-state
   --  evidence, volatile/atomic representation consumers, representation
   --  shared-state final evidence, and stabilized shared-state closure.  It
   --  prevents representation, operational attribute, stream attribute,
   --  layout, private/full-view freezing, generic formal freezing, generic
   --  instance representation, and task/protected representation conclusions
   --  from becoming confidently legal while their generic replay, overload,
   --  volatile/atomic, shared-state, closure, or fingerprint prerequisites are
   --  unresolved.

   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Overload_Generic renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   package Rep_Final renames Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
   package Rep_Shared renames Editor.Ada_Representation_Shared_State_Final_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;
   package Volatile_Rep renames Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;

   type Representation_Generic_Final_Row_Id is new Natural;
   No_Representation_Generic_Final_Row : constant Representation_Generic_Final_Row_Id := 0;

   type Representation_Generic_Final_Kind is
     (Representation_Generic_Final_Private_Full_View_Freezing,
      Representation_Generic_Final_Generic_Formal_Freezing,
      Representation_Generic_Final_Generic_Instance_Representation,
      Representation_Generic_Final_Stream_Attribute,
      Representation_Generic_Final_Operational_Attribute,
      Representation_Generic_Final_Variant_Record_Layout,
      Representation_Generic_Final_Volatile_Atomic_Record_Layout,
      Representation_Generic_Final_Independent_Component_Layout,
      Representation_Generic_Final_Protected_Object_Representation,
      Representation_Generic_Final_Task_Object_Representation,
      Representation_Generic_Final_Dispatching_Representation_Effect,
      Representation_Generic_Final_Unknown);

   type Representation_Generic_Final_Blocker_Family is
     (Representation_Generic_Final_Blocker_None,
      Representation_Generic_Final_Blocker_Final_Representation,
      Representation_Generic_Final_Blocker_Representation_Shared_State,
      Representation_Generic_Final_Blocker_Generic_Abstract_Replay,
      Representation_Generic_Final_Blocker_Overload_Generic_Shared_State,
      Representation_Generic_Final_Blocker_Volatile_Atomic_Representation,
      Representation_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Representation_Generic_Final_Blocker_Private_View_Freezing,
      Representation_Generic_Final_Blocker_Generic_Formal_Freezing,
      Representation_Generic_Final_Blocker_Stream_Attribute_Effect,
      Representation_Generic_Final_Blocker_Operational_Attribute_Effect,
      Representation_Generic_Final_Blocker_Variant_Layout,
      Representation_Generic_Final_Blocker_Independent_Component,
      Representation_Generic_Final_Blocker_Task_Protected_Representation,
      Representation_Generic_Final_Blocker_Source_Fingerprint,
      Representation_Generic_Final_Blocker_Substitution_Fingerprint,
      Representation_Generic_Final_Blocker_Multiple,
      Representation_Generic_Final_Blocker_Indeterminate);

   type Representation_Generic_Final_Status is
     (Representation_Generic_Final_Not_Checked,
      Representation_Generic_Final_Legal_Private_Full_View_Freezing_Accepted,
      Representation_Generic_Final_Legal_Generic_Formal_Freezing_Accepted,
      Representation_Generic_Final_Legal_Generic_Instance_Representation_Accepted,
      Representation_Generic_Final_Legal_Stream_Attribute_Accepted,
      Representation_Generic_Final_Legal_Operational_Attribute_Accepted,
      Representation_Generic_Final_Legal_Variant_Record_Layout_Accepted,
      Representation_Generic_Final_Legal_Volatile_Atomic_Record_Layout_Accepted,
      Representation_Generic_Final_Legal_Independent_Component_Layout_Accepted,
      Representation_Generic_Final_Legal_Protected_Object_Representation_Accepted,
      Representation_Generic_Final_Legal_Task_Object_Representation_Accepted,
      Representation_Generic_Final_Legal_Dispatching_Representation_Effect_Accepted,
      Representation_Generic_Final_Missing_Final_Representation_Row,
      Representation_Generic_Final_Final_Representation_Blocker,
      Representation_Generic_Final_Missing_Representation_Shared_State_Row,
      Representation_Generic_Final_Representation_Shared_State_Blocker,
      Representation_Generic_Final_Missing_Generic_Replay_Row,
      Representation_Generic_Final_Generic_Replay_Blocker,
      Representation_Generic_Final_Missing_Overload_Generic_Row,
      Representation_Generic_Final_Overload_Generic_Blocker,
      Representation_Generic_Final_Missing_Volatile_Representation_Row,
      Representation_Generic_Final_Volatile_Representation_Blocker,
      Representation_Generic_Final_Missing_Stabilized_Closure_Row,
      Representation_Generic_Final_Stabilized_Closure_Blocker,
      Representation_Generic_Final_Private_View_Freezing_Blocker,
      Representation_Generic_Final_Generic_Formal_Freezing_Blocker,
      Representation_Generic_Final_Stream_Attribute_Effect_Blocker,
      Representation_Generic_Final_Operational_Attribute_Effect_Blocker,
      Representation_Generic_Final_Variant_Layout_Blocker,
      Representation_Generic_Final_Independent_Component_Blocker,
      Representation_Generic_Final_Task_Protected_Representation_Blocker,
      Representation_Generic_Final_Source_Fingerprint_Mismatch,
      Representation_Generic_Final_Substitution_Fingerprint_Mismatch,
      Representation_Generic_Final_Multiple_Blockers,
      Representation_Generic_Final_Indeterminate);

   type Representation_Generic_Final_Context is record
      Id                         : Representation_Generic_Final_Row_Id := No_Representation_Generic_Final_Row;
      Kind                       : Representation_Generic_Final_Kind := Representation_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Final_Representation_Row   : Rep_Final.Final_Representation_Row_Id := Rep_Final.No_Final_Representation_Row;
      Final_Representation_Status : Rep_Final.Final_Representation_Status := Rep_Final.Final_Representation_Not_Checked;
      Representation_Shared_Row  : Rep_Shared.Representation_Shared_State_Row_Id := Rep_Shared.No_Representation_Shared_State_Row;
      Representation_Shared_Status : Rep_Shared.Representation_Shared_State_Status := Rep_Shared.Representation_Shared_State_Not_Checked;
      Generic_Replay_Row         : Generic_Replay.Generic_Abstract_Replay_Row_Id := Generic_Replay.No_Generic_Abstract_Replay_Row;
      Generic_Replay_Status      : Generic_Replay.Generic_Abstract_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Not_Checked;
      Overload_Generic_Row       : Overload_Generic.Overload_Generic_Final_Row_Id := Overload_Generic.No_Overload_Generic_Final_Row;
      Overload_Generic_Status    : Overload_Generic.Overload_Generic_Final_Status := Overload_Generic.Overload_Generic_Final_Not_Checked;
      Volatile_Representation_Row : Volatile_Rep.Volatile_Atomic_Representation_Row_Id := Volatile_Rep.No_Volatile_Atomic_Representation_Row;
      Volatile_Representation_Status : Volatile_Rep.Volatile_Atomic_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Final_Representation : Boolean := True;
      Requires_Representation_Shared : Boolean := True;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Overload_Generic  : Boolean := False;
      Requires_Volatile_Representation : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Private_View_Freezing_Blocker : Boolean := False;
      Generic_Formal_Freezing_Blocker : Boolean := False;
      Stream_Attribute_Effect_Blocker : Boolean := False;
      Operational_Attribute_Effect_Blocker : Boolean := False;
      Variant_Layout_Blocker     : Boolean := False;
      Independent_Component_Blocker : Boolean := False;
      Task_Protected_Representation_Blocker : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Representation_Generic_Final_Row is record
      Id                         : Representation_Generic_Final_Row_Id := No_Representation_Generic_Final_Row;
      Context                    : Representation_Generic_Final_Row_Id := No_Representation_Generic_Final_Row;
      Kind                       : Representation_Generic_Final_Kind := Representation_Generic_Final_Unknown;
      Status                     : Representation_Generic_Final_Status := Representation_Generic_Final_Not_Checked;
      Blocker_Family             : Representation_Generic_Final_Blocker_Family := Representation_Generic_Final_Blocker_None;
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
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Representation_Generic_Final_Context_Model is private;
   type Representation_Generic_Final_Model is private;
   type Representation_Generic_Final_Set is private;

   procedure Clear (Model : in out Representation_Generic_Final_Context_Model);
   procedure Add_Context
     (Model : in out Representation_Generic_Final_Context_Model;
      Info  : Representation_Generic_Final_Context);
   function Context_Count (Model : Representation_Generic_Final_Context_Model) return Natural;
   function Context_At
     (Model : Representation_Generic_Final_Context_Model;
      Index : Positive) return Representation_Generic_Final_Context;
   function Fingerprint (Model : Representation_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Representation_Generic_Final_Context_Model) return Representation_Generic_Final_Model;
   function Count (Model : Representation_Generic_Final_Model) return Natural;
   function Row_Count (Model : Representation_Generic_Final_Model) return Natural renames Count;
   function Row_At
     (Model : Representation_Generic_Final_Model;
      Index : Positive) return Representation_Generic_Final_Row;

   function Query_Count (Set : Representation_Generic_Final_Set) return Natural;
   function Query_At
     (Set   : Representation_Generic_Final_Set;
      Index : Positive) return Representation_Generic_Final_Row;
   function Query_Status
     (Model  : Representation_Generic_Final_Model;
      Status : Representation_Generic_Final_Status) return Representation_Generic_Final_Set;
   function Query_Blocker_Family
     (Model  : Representation_Generic_Final_Model;
      Family : Representation_Generic_Final_Blocker_Family) return Representation_Generic_Final_Set;
   function Find_By_Node
     (Model : Representation_Generic_Final_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Generic_Final_Set;
   function Find_By_Source_Fingerprint
     (Model              : Representation_Generic_Final_Model;
      Source_Fingerprint : Natural) return Representation_Generic_Final_Set;

   function Count_By_Status
     (Model  : Representation_Generic_Final_Model;
      Status : Representation_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Representation_Generic_Final_Model;
      Family : Representation_Generic_Final_Blocker_Family) return Natural;
   function Accepted_Count (Model : Representation_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Representation_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Representation_Generic_Final_Model) return Natural;
   function Stable_Fingerprint (Model : Representation_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Representation_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Representation_Generic_Final_Status) return Boolean;
   function Is_Indeterminate (Status : Representation_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Generic_Final_Row);

   type Representation_Generic_Final_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Representation_Generic_Final_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Representation_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
