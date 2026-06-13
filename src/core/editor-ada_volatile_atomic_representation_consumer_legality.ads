with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality is

   --  Pass1225 volatile/atomic representation consumer legality.
   --
   --  This package connects volatile/atomic/shared-state legality to the
   --  representation consumers that depend on it: volatile full-access
   --  objects, atomic components, independent components, representation
   --  clauses, stream and operational attributes, protected/task shared
   --  object representation, and shared-passive layout.  It preserves the
   --  original semantic blocker family instead of flattening representation
   --  and shared-state failures into a generic diagnostic state.

   package Shared renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;
   package Rep renames Editor.Ada_Representation_Shared_State_Final_Legality;
   package Abstract_Consumers renames Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;

   type Volatile_Atomic_Representation_Row_Id is new Natural;
   No_Volatile_Atomic_Representation_Row : constant Volatile_Atomic_Representation_Row_Id := 0;

   type Volatile_Atomic_Representation_Kind is
     (Volatile_Atomic_Representation_Volatile_Full_Access_Object,
      Volatile_Atomic_Representation_Atomic_Object_Clause,
      Volatile_Atomic_Representation_Atomic_Record_Component,
      Volatile_Atomic_Representation_Independent_Component_Clause,
      Volatile_Atomic_Representation_Record_Layout,
      Volatile_Atomic_Representation_Representation_Clause,
      Volatile_Atomic_Representation_Stream_Attribute,
      Volatile_Atomic_Representation_Operational_Attribute,
      Volatile_Atomic_Representation_Protected_Shared_Object,
      Volatile_Atomic_Representation_Task_Shared_Object,
      Volatile_Atomic_Representation_Shared_Passive_Package,
      Volatile_Atomic_Representation_Unknown);

   type Volatile_Atomic_Representation_Blocker_Family is
     (Volatile_Atomic_Representation_Blocker_None,
      Volatile_Atomic_Representation_Blocker_Volatile_Atomic_Shared_State,
      Volatile_Atomic_Representation_Blocker_Representation_Freezing,
      Volatile_Atomic_Representation_Blocker_Abstract_State_Consumer,
      Volatile_Atomic_Representation_Blocker_Stabilized_Closure,
      Volatile_Atomic_Representation_Blocker_Volatile_Full_Access,
      Volatile_Atomic_Representation_Blocker_Atomic_Component,
      Volatile_Atomic_Representation_Blocker_Independent_Component,
      Volatile_Atomic_Representation_Blocker_Stream_Attribute,
      Volatile_Atomic_Representation_Blocker_Operational_Attribute,
      Volatile_Atomic_Representation_Blocker_Protected_Tasking,
      Volatile_Atomic_Representation_Blocker_Source_Fingerprint,
      Volatile_Atomic_Representation_Blocker_Multiple,
      Volatile_Atomic_Representation_Blocker_Indeterminate);

   type Volatile_Atomic_Representation_Status is
     (Volatile_Atomic_Representation_Not_Checked,
      Volatile_Atomic_Representation_Legal_Volatile_Full_Access_Accepted,
      Volatile_Atomic_Representation_Legal_Atomic_Object_Clause_Accepted,
      Volatile_Atomic_Representation_Legal_Atomic_Record_Component_Accepted,
      Volatile_Atomic_Representation_Legal_Independent_Component_Accepted,
      Volatile_Atomic_Representation_Legal_Record_Layout_Accepted,
      Volatile_Atomic_Representation_Legal_Representation_Clause_Accepted,
      Volatile_Atomic_Representation_Legal_Stream_Attribute_Accepted,
      Volatile_Atomic_Representation_Legal_Operational_Attribute_Accepted,
      Volatile_Atomic_Representation_Legal_Protected_Shared_Object_Accepted,
      Volatile_Atomic_Representation_Legal_Task_Shared_Object_Accepted,
      Volatile_Atomic_Representation_Legal_Shared_Passive_Package_Accepted,
      Volatile_Atomic_Representation_Missing_Shared_State_Row,
      Volatile_Atomic_Representation_Shared_State_Blocker,
      Volatile_Atomic_Representation_Missing_Representation_Row,
      Volatile_Atomic_Representation_Representation_Blocker,
      Volatile_Atomic_Representation_Missing_Abstract_Consumer_Row,
      Volatile_Atomic_Representation_Abstract_Consumer_Blocker,
      Volatile_Atomic_Representation_Missing_Stabilized_Closure_Row,
      Volatile_Atomic_Representation_Stabilized_Closure_Blocker,
      Volatile_Atomic_Representation_Volatile_Full_Access_Blocker,
      Volatile_Atomic_Representation_Atomic_Component_Blocker,
      Volatile_Atomic_Representation_Atomic_Alignment_Blocker,
      Volatile_Atomic_Representation_Atomic_Record_Component_Blocker,
      Volatile_Atomic_Representation_Independent_Component_Overlap,
      Volatile_Atomic_Representation_Representation_Clause_Blocker,
      Volatile_Atomic_Representation_Record_Layout_Blocker,
      Volatile_Atomic_Representation_Stream_Attribute_Blocker,
      Volatile_Atomic_Representation_Operational_Attribute_Blocker,
      Volatile_Atomic_Representation_Protected_Shared_Object_Blocker,
      Volatile_Atomic_Representation_Task_Shared_Object_Blocker,
      Volatile_Atomic_Representation_Shared_Passive_Blocker,
      Volatile_Atomic_Representation_Source_Fingerprint_Mismatch,
      Volatile_Atomic_Representation_Multiple_Blockers,
      Volatile_Atomic_Representation_Indeterminate);

   type Volatile_Atomic_Representation_Context is record
      Id                         : Volatile_Atomic_Representation_Row_Id := No_Volatile_Atomic_Representation_Row;
      Kind                       : Volatile_Atomic_Representation_Kind := Volatile_Atomic_Representation_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Shared_State_Row           : Shared.Shared_State_Row_Id := Shared.No_Shared_State_Row;
      Shared_State_Status        : Shared.Shared_State_Status := Shared.Shared_State_Not_Checked;
      Representation_Row         : Rep.Representation_Shared_State_Row_Id := Rep.No_Representation_Shared_State_Row;
      Representation_Status      : Rep.Representation_Shared_State_Status := Rep.Representation_Shared_State_Not_Checked;
      Abstract_Consumer_Row      : Abstract_Consumers.Abstract_State_Consumer_Row_Id := Abstract_Consumers.No_Abstract_State_Consumer_Row;
      Abstract_Consumer_Status   : Abstract_Consumers.Abstract_State_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Shared_State      : Boolean := True;
      Requires_Representation    : Boolean := True;
      Requires_Abstract_Consumer : Boolean := False;
      Requires_Stabilized_Closure : Boolean := False;
      Volatile_Full_Access_Error : Boolean := False;
      Atomic_Component_Error     : Boolean := False;
      Atomic_Alignment_Error     : Boolean := False;
      Atomic_Record_Component_Error : Boolean := False;
      Independent_Component_Overlap : Boolean := False;
      Representation_Clause_Error : Boolean := False;
      Record_Layout_Error        : Boolean := False;
      Stream_Attribute_Error     : Boolean := False;
      Operational_Attribute_Error : Boolean := False;
      Protected_Shared_Object_Error : Boolean := False;
      Task_Shared_Object_Error   : Boolean := False;
      Shared_Passive_Error       : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Volatile_Atomic_Representation_Row is record
      Id                         : Volatile_Atomic_Representation_Row_Id := No_Volatile_Atomic_Representation_Row;
      Context                    : Volatile_Atomic_Representation_Row_Id := No_Volatile_Atomic_Representation_Row;
      Kind                       : Volatile_Atomic_Representation_Kind := Volatile_Atomic_Representation_Unknown;
      Status                     : Volatile_Atomic_Representation_Status := Volatile_Atomic_Representation_Not_Checked;
      Blocker_Family             : Volatile_Atomic_Representation_Blocker_Family := Volatile_Atomic_Representation_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
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

   type Volatile_Atomic_Representation_Context_Model is private;
   type Volatile_Atomic_Representation_Model is private;
   type Volatile_Atomic_Representation_Set is private;

   procedure Clear (Model : in out Volatile_Atomic_Representation_Context_Model);
   procedure Add_Context
     (Model : in out Volatile_Atomic_Representation_Context_Model;
      Info  : Volatile_Atomic_Representation_Context);
   function Context_Count (Model : Volatile_Atomic_Representation_Context_Model) return Natural;
   function Context_At
     (Model : Volatile_Atomic_Representation_Context_Model;
      Index : Positive) return Volatile_Atomic_Representation_Context;
   function Fingerprint (Model : Volatile_Atomic_Representation_Context_Model) return Natural;

   function Build (Contexts : Volatile_Atomic_Representation_Context_Model) return Volatile_Atomic_Representation_Model;
   function Count (Model : Volatile_Atomic_Representation_Model) return Natural;
   function Row_Count (Model : Volatile_Atomic_Representation_Model) return Natural renames Count;
   function Row_At
     (Model : Volatile_Atomic_Representation_Model;
      Index : Positive) return Volatile_Atomic_Representation_Row;

   function Query_Count (Set : Volatile_Atomic_Representation_Set) return Natural;
   function Query_At
     (Set   : Volatile_Atomic_Representation_Set;
      Index : Positive) return Volatile_Atomic_Representation_Row;
   function Query_Status
     (Model  : Volatile_Atomic_Representation_Model;
      Status : Volatile_Atomic_Representation_Status) return Volatile_Atomic_Representation_Set;
   function Query_Blocker_Family
     (Model  : Volatile_Atomic_Representation_Model;
      Family : Volatile_Atomic_Representation_Blocker_Family) return Volatile_Atomic_Representation_Set;
   function Find_By_Node
     (Model : Volatile_Atomic_Representation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Volatile_Atomic_Representation_Set;
   function Find_By_Source_Fingerprint
     (Model              : Volatile_Atomic_Representation_Model;
      Source_Fingerprint : Natural) return Volatile_Atomic_Representation_Set;

   function Count_By_Status
     (Model  : Volatile_Atomic_Representation_Model;
      Status : Volatile_Atomic_Representation_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Volatile_Atomic_Representation_Model;
      Family : Volatile_Atomic_Representation_Blocker_Family) return Natural;
   function Accepted_Count (Model : Volatile_Atomic_Representation_Model) return Natural;
   function Blocked_Count (Model : Volatile_Atomic_Representation_Model) return Natural;
   function Indeterminate_Count (Model : Volatile_Atomic_Representation_Model) return Natural;
   function Stable_Fingerprint (Model : Volatile_Atomic_Representation_Model) return Natural;

   function Is_Accepted (Status : Volatile_Atomic_Representation_Status) return Boolean;
   function Is_Blocked (Status : Volatile_Atomic_Representation_Status) return Boolean;
   function Is_Indeterminate (Status : Volatile_Atomic_Representation_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Volatile_Atomic_Representation_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Volatile_Atomic_Representation_Row);

   type Volatile_Atomic_Representation_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Volatile_Atomic_Representation_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Volatile_Atomic_Representation_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;
