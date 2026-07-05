with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality is

   --  Case 1246 overload/generic/shared-state RM edge completion legality.
   --
   --  This package consumes the stabilized generic/shared-state final closure
   --  from Case 1245 together with the earlier overload/generic/shared-state
   --  final legality from Case 1228.  It deepens the remaining Ada overload and
   --  type-resolution RM edge cases where accepted overload conclusions are
   --  still unsafe unless renamed primitive visibility, inherited/private
   --  extension hiding, dispatching abstract-state effects, prefixed-call
   --  side-effect contracts, access-to-subprogram effect profiles, generic
   --  formal subprogram effects, universal numeric expected-context effects,
   --  and class-wide controlling-result state joins all agree with stabilized
   --  generic/shared-state closure evidence.

   package Previous renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   package Closure renames Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;

   type Overload_Generic_RM_Edge_Completion_Id is new Natural;
   No_Overload_Generic_RM_Edge_Completion : constant Overload_Generic_RM_Edge_Completion_Id := 0;

   type Overload_Generic_RM_Edge_Kind is
     (Overload_Generic_RM_Edge_Renamed_Primitive,
      Overload_Generic_RM_Edge_Inherited_Private_Extension_Primitive,
      Overload_Generic_RM_Edge_Dispatching_Abstract_State_Effect,
      Overload_Generic_RM_Edge_Prefixed_Call_Side_Effect_Contract,
      Overload_Generic_RM_Edge_Access_Subprogram_Effect_Profile,
      Overload_Generic_RM_Edge_Generic_Formal_Subprogram_Effect,
      Overload_Generic_RM_Edge_Universal_Numeric_Expected_State,
      Overload_Generic_RM_Edge_Class_Wide_Controlling_Result_State,
      Overload_Generic_RM_Edge_Unknown);

   type Overload_Generic_RM_Edge_Blocker_Family is
     (Overload_Generic_RM_Edge_Blocker_None,
      Overload_Generic_RM_Edge_Blocker_Previous_Overload,
      Overload_Generic_RM_Edge_Blocker_Stabilized_Closure,
      Overload_Generic_RM_Edge_Blocker_Renaming_Visibility,
      Overload_Generic_RM_Edge_Blocker_Inherited_Primitive_Hiding,
      Overload_Generic_RM_Edge_Blocker_Dispatching_Abstract_State,
      Overload_Generic_RM_Edge_Blocker_Prefixed_Call_Effect,
      Overload_Generic_RM_Edge_Blocker_Access_Profile_Effect,
      Overload_Generic_RM_Edge_Blocker_Generic_Formal_Effect,
      Overload_Generic_RM_Edge_Blocker_Universal_Numeric_State,
      Overload_Generic_RM_Edge_Blocker_Class_Wide_Result_State,
      Overload_Generic_RM_Edge_Blocker_Source_Fingerprint,
      Overload_Generic_RM_Edge_Blocker_Substitution_Fingerprint,
      Overload_Generic_RM_Edge_Blocker_Multiple,
      Overload_Generic_RM_Edge_Blocker_Indeterminate);

   type Overload_Generic_RM_Edge_Status is
     (Overload_Generic_RM_Edge_Not_Checked,
      Overload_Generic_RM_Edge_Legal_Renamed_Primitive_Accepted,
      Overload_Generic_RM_Edge_Legal_Inherited_Private_Extension_Primitive_Accepted,
      Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted,
      Overload_Generic_RM_Edge_Legal_Prefixed_Call_Side_Effect_Contract_Accepted,
      Overload_Generic_RM_Edge_Legal_Access_Subprogram_Effect_Profile_Accepted,
      Overload_Generic_RM_Edge_Legal_Generic_Formal_Subprogram_Effect_Accepted,
      Overload_Generic_RM_Edge_Legal_Universal_Numeric_Expected_State_Accepted,
      Overload_Generic_RM_Edge_Legal_Class_Wide_Controlling_Result_State_Accepted,
      Overload_Generic_RM_Edge_Missing_Previous_Overload_Row,
      Overload_Generic_RM_Edge_Previous_Overload_Blocker,
      Overload_Generic_RM_Edge_Missing_Stabilized_Closure_Row,
      Overload_Generic_RM_Edge_Stabilized_Closure_Blocker,
      Overload_Generic_RM_Edge_Renamed_Primitive_Visibility_Mismatch,
      Overload_Generic_RM_Edge_Inherited_Primitive_Private_Extension_Hidden,
      Overload_Generic_RM_Edge_Dispatching_Abstract_State_Mismatch,
      Overload_Generic_RM_Edge_Prefixed_Call_Effect_Contract_Mismatch,
      Overload_Generic_RM_Edge_Access_Profile_Effect_Mismatch,
      Overload_Generic_RM_Edge_Generic_Formal_Effect_Mismatch,
      Overload_Generic_RM_Edge_Universal_Numeric_State_Ambiguous,
      Overload_Generic_RM_Edge_Class_Wide_Result_State_Mismatch,
      Overload_Generic_RM_Edge_Source_Fingerprint_Mismatch,
      Overload_Generic_RM_Edge_Substitution_Fingerprint_Mismatch,
      Overload_Generic_RM_Edge_Multiple_Blockers,
      Overload_Generic_RM_Edge_Indeterminate);

   type Overload_Generic_RM_Edge_Context is record
      Id                                : Overload_Generic_RM_Edge_Completion_Id := No_Overload_Generic_RM_Edge_Completion;
      Kind                              : Overload_Generic_RM_Edge_Kind := Overload_Generic_RM_Edge_Unknown;
      Node                              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name                    : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                         : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                        : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                     : Ada.Strings.Unbounded.Unbounded_String;
      Previous_Overload_Row             : Previous.Overload_Generic_Final_Row_Id := Previous.No_Overload_Generic_Final_Row;
      Previous_Overload_Status          : Previous.Overload_Generic_Final_Status := Previous.Overload_Generic_Final_Not_Checked;
      Stabilized_Closure_Row            : Closure.Generic_Shared_State_Final_Stabilized_Closure_Id := Closure.No_Generic_Shared_State_Final_Stabilized_Closure;
      Stabilized_Closure_Status         : Closure.Generic_Shared_State_Final_Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Not_Checked;
      Requires_Previous_Overload        : Boolean := True;
      Requires_Stabilized_Closure       : Boolean := True;
      Renamed_Primitive_Visibility_Mismatch : Boolean := False;
      Inherited_Primitive_Hidden_By_Private_Extension : Boolean := False;
      Dispatching_Abstract_State_Mismatch : Boolean := False;
      Prefixed_Call_Effect_Contract_Mismatch : Boolean := False;
      Access_Profile_Effect_Mismatch    : Boolean := False;
      Generic_Formal_Effect_Mismatch    : Boolean := False;
      Universal_Numeric_State_Ambiguous : Boolean := False;
      Class_Wide_Result_State_Mismatch  : Boolean := False;
      Source_Fingerprint                : Natural := 0;
      Expected_Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint          : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                        : Positive := 1;
      Start_Column                      : Positive := 1;
      End_Line                          : Positive := 1;
      End_Column                        : Positive := 1;
   end record;

   type Overload_Generic_RM_Edge_Row is record
      Id                         : Overload_Generic_RM_Edge_Completion_Id := No_Overload_Generic_RM_Edge_Completion;
      Context                    : Overload_Generic_RM_Edge_Completion_Id := No_Overload_Generic_RM_Edge_Completion;
      Kind                       : Overload_Generic_RM_Edge_Kind := Overload_Generic_RM_Edge_Unknown;
      Status                     : Overload_Generic_RM_Edge_Status := Overload_Generic_RM_Edge_Not_Checked;
      Blocker_Family             : Overload_Generic_RM_Edge_Blocker_Family := Overload_Generic_RM_Edge_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
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

   type Overload_Generic_RM_Edge_Context_Model is private;
   type Overload_Generic_RM_Edge_Model is private;
   type Overload_Generic_RM_Edge_Set is private;

   procedure Clear (Model : in out Overload_Generic_RM_Edge_Context_Model);
   procedure Add_Context
     (Model   : in out Overload_Generic_RM_Edge_Context_Model;
      Context : Overload_Generic_RM_Edge_Context);

   function Build (Contexts : Overload_Generic_RM_Edge_Context_Model) return Overload_Generic_RM_Edge_Model;
   function Count (Model : Overload_Generic_RM_Edge_Model) return Natural;
   function Row_Count (Model : Overload_Generic_RM_Edge_Model) return Natural renames Count;
   function Row_At
     (Model : Overload_Generic_RM_Edge_Model;
      Index : Positive) return Overload_Generic_RM_Edge_Row;

   function Query_Count (Set : Overload_Generic_RM_Edge_Set) return Natural;
   function Query_At
     (Set   : Overload_Generic_RM_Edge_Set;
      Index : Positive) return Overload_Generic_RM_Edge_Row;

   function Query_Status
     (Model  : Overload_Generic_RM_Edge_Model;
      Status : Overload_Generic_RM_Edge_Status) return Overload_Generic_RM_Edge_Set;
   function Query_Blocker_Family
     (Model  : Overload_Generic_RM_Edge_Model;
      Family : Overload_Generic_RM_Edge_Blocker_Family) return Overload_Generic_RM_Edge_Set;
   function Find_By_Node
     (Model : Overload_Generic_RM_Edge_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Generic_RM_Edge_Set;
   function Find_By_Source_Fingerprint
     (Model       : Overload_Generic_RM_Edge_Model;
      Fingerprint : Natural) return Overload_Generic_RM_Edge_Set;

   function Count_By_Status
     (Model  : Overload_Generic_RM_Edge_Model;
      Status : Overload_Generic_RM_Edge_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Overload_Generic_RM_Edge_Model;
      Family : Overload_Generic_RM_Edge_Blocker_Family) return Natural;
   function Accepted_Count (Model : Overload_Generic_RM_Edge_Model) return Natural;
   function Blocked_Count (Model : Overload_Generic_RM_Edge_Model) return Natural;
   function Indeterminate_Count (Model : Overload_Generic_RM_Edge_Model) return Natural;
   function Stable_Fingerprint (Model : Overload_Generic_RM_Edge_Model) return Natural;

   function Is_Accepted (Status : Overload_Generic_RM_Edge_Status) return Boolean;
   function Is_Blocked (Status : Overload_Generic_RM_Edge_Status) return Boolean;
   function Is_Indeterminate (Status : Overload_Generic_RM_Edge_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Generic_RM_Edge_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Generic_RM_Edge_Row);

   type Overload_Generic_RM_Edge_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Generic_RM_Edge_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Overload_Generic_RM_Edge_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
