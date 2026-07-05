with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Flow_Contract_Final_Proof_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;

package Editor.Ada_Dispatching_Global_Refinement_Legality is

   --  Case 1226 dispatching Global/Depends refinement legality.
   --
   --  This package connects dispatching-call Global/Depends proof to the
   --  shared-state semantic chain.  Class-wide controlling calls, inherited
   --  primitives, prefixed dispatching calls, interface dispatching calls,
   --  renamed dispatching primitives, access-to-class-wide dispatch, and
   --  generic formal dispatching operations are accepted only when final
   --  flow/contract proof, abstract/refined-state consumers, overload
   --  shared-state evidence, volatile/atomic representation consumers, and
   --  stabilized shared-state closure agree.  Original blocker families are
   --  preserved so downstream consumers cannot treat missing state proof as a
   --  confident dispatching effect conclusion.

   package Flow renames Editor.Ada_Flow_Contract_Final_Proof_Legality;
   package Abstract_State renames Editor.Ada_Abstract_State_Refined_State_Legality;
   package Abstract_Consumers renames Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
   package Overload_State renames Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
   package Volatile_Rep renames Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;

   type Dispatching_Global_Row_Id is new Natural;
   No_Dispatching_Global_Row : constant Dispatching_Global_Row_Id := 0;

   type Dispatching_Global_Kind is
     (Dispatching_Global_Class_Wide_Call,
      Dispatching_Global_Controlling_Operation,
      Dispatching_Global_Inherited_Primitive,
      Dispatching_Global_Prefixed_Call,
      Dispatching_Global_Interface_Dispatch,
      Dispatching_Global_Renamed_Primitive,
      Dispatching_Global_Access_To_Class_Wide_Call,
      Dispatching_Global_Generic_Formal_Dispatch,
      Dispatching_Global_Dynamic_Effect_Join,
      Dispatching_Global_Abstract_State_Join,
      Dispatching_Global_Unknown);

   type Dispatching_Global_Blocker_Family is
     (Dispatching_Global_Blocker_None,
      Dispatching_Global_Blocker_Flow_Contract,
      Dispatching_Global_Blocker_Abstract_State,
      Dispatching_Global_Blocker_Abstract_State_Consumer,
      Dispatching_Global_Blocker_Overload_Shared_State,
      Dispatching_Global_Blocker_Volatile_Atomic_Representation,
      Dispatching_Global_Blocker_Stabilized_Shared_State_Closure,
      Dispatching_Global_Blocker_Global_Mode,
      Dispatching_Global_Blocker_Depends_Edge,
      Dispatching_Global_Blocker_Dynamic_Effect_Join,
      Dispatching_Global_Blocker_Inherited_Primitive,
      Dispatching_Global_Blocker_Renaming,
      Dispatching_Global_Blocker_Generic_Formal,
      Dispatching_Global_Blocker_Source_Fingerprint,
      Dispatching_Global_Blocker_Multiple,
      Dispatching_Global_Blocker_Indeterminate);

   type Dispatching_Global_Status is
     (Dispatching_Global_Not_Checked,
      Dispatching_Global_Legal_Class_Wide_Call_Accepted,
      Dispatching_Global_Legal_Controlling_Operation_Accepted,
      Dispatching_Global_Legal_Inherited_Primitive_Accepted,
      Dispatching_Global_Legal_Prefixed_Call_Accepted,
      Dispatching_Global_Legal_Interface_Dispatch_Accepted,
      Dispatching_Global_Legal_Renamed_Primitive_Accepted,
      Dispatching_Global_Legal_Access_To_Class_Wide_Call_Accepted,
      Dispatching_Global_Legal_Generic_Formal_Dispatch_Accepted,
      Dispatching_Global_Legal_Dynamic_Effect_Join_Accepted,
      Dispatching_Global_Legal_Abstract_State_Join_Accepted,
      Dispatching_Global_Missing_Flow_Proof_Row,
      Dispatching_Global_Flow_Proof_Blocker,
      Dispatching_Global_Missing_Abstract_State_Row,
      Dispatching_Global_Abstract_State_Blocker,
      Dispatching_Global_Missing_Abstract_Consumer_Row,
      Dispatching_Global_Abstract_Consumer_Blocker,
      Dispatching_Global_Missing_Overload_Shared_State_Row,
      Dispatching_Global_Overload_Shared_State_Blocker,
      Dispatching_Global_Missing_Volatile_Representation_Row,
      Dispatching_Global_Volatile_Representation_Blocker,
      Dispatching_Global_Missing_Stabilized_Closure_Row,
      Dispatching_Global_Stabilized_Closure_Blocker,
      Dispatching_Global_Mode_Mismatch,
      Dispatching_Global_Depends_Edge_Missing,
      Dispatching_Global_Depends_Edge_Extra,
      Dispatching_Global_Dynamic_Effect_Join_Blocker,
      Dispatching_Global_Abstract_State_Mode_Mismatch,
      Dispatching_Global_Inherited_Primitive_Hiding_Blocker,
      Dispatching_Global_Renamed_Primitive_Effect_Blocker,
      Dispatching_Global_Generic_Formal_Effect_Blocker,
      Dispatching_Global_Source_Fingerprint_Mismatch,
      Dispatching_Global_Multiple_Blockers,
      Dispatching_Global_Indeterminate);

   type Dispatching_Global_Context is record
      Id                         : Dispatching_Global_Row_Id := No_Dispatching_Global_Row;
      Kind                       : Dispatching_Global_Kind := Dispatching_Global_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dispatching_Target_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Flow_Proof_Row             : Flow.Flow_Contract_Proof_Row_Id := Flow.No_Flow_Contract_Proof_Row;
      Flow_Proof_Status          : Flow.Flow_Contract_Proof_Status := Flow.Flow_Contract_Proof_Not_Checked;
      Abstract_State_Row         : Abstract_State.Abstract_State_Row_Id := Abstract_State.No_Abstract_State_Row;
      Abstract_State_Status      : Abstract_State.Abstract_State_Status := Abstract_State.Abstract_State_Not_Checked;
      Abstract_Consumer_Row      : Abstract_Consumers.Abstract_State_Consumer_Row_Id := Abstract_Consumers.No_Abstract_State_Consumer_Row;
      Abstract_Consumer_Status   : Abstract_Consumers.Abstract_State_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Not_Checked;
      Overload_Shared_Row        : Overload_State.Overload_Shared_State_Row_Id := Overload_State.No_Overload_Shared_State_Row;
      Overload_Shared_Status     : Overload_State.Overload_Shared_State_Status := Overload_State.Overload_Shared_State_Not_Checked;
      Volatile_Representation_Row : Volatile_Rep.Volatile_Atomic_Representation_Row_Id := Volatile_Rep.No_Volatile_Atomic_Representation_Row;
      Volatile_Representation_Status : Volatile_Rep.Volatile_Atomic_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Abstract_State    : Boolean := True;
      Requires_Abstract_Consumer : Boolean := True;
      Requires_Overload_Shared_State : Boolean := True;
      Requires_Volatile_Representation : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Global_Mode_Error          : Boolean := False;
      Depends_Edge_Missing       : Boolean := False;
      Depends_Edge_Extra         : Boolean := False;
      Dynamic_Effect_Join_Error  : Boolean := False;
      Abstract_State_Mode_Error  : Boolean := False;
      Inherited_Primitive_Hiding_Error : Boolean := False;
      Renamed_Primitive_Effect_Error : Boolean := False;
      Generic_Formal_Effect_Error : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Dispatching_Global_Row is record
      Id                         : Dispatching_Global_Row_Id := No_Dispatching_Global_Row;
      Context                    : Dispatching_Global_Row_Id := No_Dispatching_Global_Row;
      Kind                       : Dispatching_Global_Kind := Dispatching_Global_Unknown;
      Status                     : Dispatching_Global_Status := Dispatching_Global_Not_Checked;
      Blocker_Family             : Dispatching_Global_Blocker_Family := Dispatching_Global_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Dispatching_Global_Context_Model is private;
   type Dispatching_Global_Model is private;
   type Dispatching_Global_Set is private;

   procedure Clear (Model : in out Dispatching_Global_Context_Model);
   procedure Add_Context
     (Model : in out Dispatching_Global_Context_Model;
      Info  : Dispatching_Global_Context);
   function Context_Count (Model : Dispatching_Global_Context_Model) return Natural;
   function Context_At
     (Model : Dispatching_Global_Context_Model;
      Index : Positive) return Dispatching_Global_Context;
   function Fingerprint (Model : Dispatching_Global_Context_Model) return Natural;

   function Build (Contexts : Dispatching_Global_Context_Model) return Dispatching_Global_Model;
   function Count (Model : Dispatching_Global_Model) return Natural;
   function Row_Count (Model : Dispatching_Global_Model) return Natural renames Count;
   function Row_At
     (Model : Dispatching_Global_Model;
      Index : Positive) return Dispatching_Global_Row;

   function Query_Count (Set : Dispatching_Global_Set) return Natural;
   function Query_At
     (Set   : Dispatching_Global_Set;
      Index : Positive) return Dispatching_Global_Row;
   function Query_Status
     (Model  : Dispatching_Global_Model;
      Status : Dispatching_Global_Status) return Dispatching_Global_Set;
   function Query_Blocker_Family
     (Model  : Dispatching_Global_Model;
      Family : Dispatching_Global_Blocker_Family) return Dispatching_Global_Set;
   function Find_By_Node
     (Model : Dispatching_Global_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dispatching_Global_Set;
   function Find_By_Source_Fingerprint
     (Model              : Dispatching_Global_Model;
      Source_Fingerprint : Natural) return Dispatching_Global_Set;

   function Count_By_Status
     (Model  : Dispatching_Global_Model;
      Status : Dispatching_Global_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Dispatching_Global_Model;
      Family : Dispatching_Global_Blocker_Family) return Natural;
   function Accepted_Count (Model : Dispatching_Global_Model) return Natural;
   function Blocked_Count (Model : Dispatching_Global_Model) return Natural;
   function Indeterminate_Count (Model : Dispatching_Global_Model) return Natural;
   function Stable_Fingerprint (Model : Dispatching_Global_Model) return Natural;

   function Is_Accepted (Status : Dispatching_Global_Status) return Boolean;
   function Is_Blocked (Status : Dispatching_Global_Status) return Boolean;
   function Is_Indeterminate (Status : Dispatching_Global_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Dispatching_Global_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Dispatching_Global_Row);

   type Dispatching_Global_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Dispatching_Global_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Dispatching_Global_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Dispatching_Global_Refinement_Legality;
