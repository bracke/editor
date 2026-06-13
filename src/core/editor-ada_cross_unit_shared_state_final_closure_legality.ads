with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality is

   --  Pass1216 cross-unit shared-state final closure legality.
   --
   --  This package closes the cross-unit boundary for the shared-state semantic
   --  chain.  Abstract/refined state, volatile/atomic/shared-variable effects,
   --  overload/type shared-state evidence, representation/freezing shared-state
   --  evidence, and tasking/protected shared-state evidence are all required to
   --  agree with final cross-unit closure before a result may remain confidently
   --  legal.  Dependency, view, fingerprint, and family-specific blockers are
   --  preserved instead of flattened into generic cross-unit errors.

   package Abstract_States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   package Cross_Unit renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
   package Overload_State renames Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
   package Rep_State renames Editor.Ada_Representation_Shared_State_Final_Legality;
   package Shared_State renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;
   package Tasking_State renames Editor.Ada_Tasking_Shared_State_Final_Legality;

   type Cross_Unit_Shared_State_Row_Id is new Natural;
   No_Cross_Unit_Shared_State_Row : constant Cross_Unit_Shared_State_Row_Id := 0;

   type Cross_Unit_Shared_State_Context_Kind is
     (Cross_Unit_Shared_State_Local,
      Cross_Unit_Shared_State_With_Use,
      Cross_Unit_Shared_State_Private_Full_View,
      Cross_Unit_Shared_State_Limited_View,
      Cross_Unit_Shared_State_Child_Private_Child,
      Cross_Unit_Shared_State_Generic_Instance,
      Cross_Unit_Shared_State_Abstract_State,
      Cross_Unit_Shared_State_Volatile_Atomic,
      Cross_Unit_Shared_State_Overload_Type,
      Cross_Unit_Shared_State_Representation,
      Cross_Unit_Shared_State_Tasking_Protected,
      Cross_Unit_Shared_State_Unknown);

   type Cross_Unit_Shared_State_Dependency_State is
     (Shared_Dependency_Local,
      Shared_Dependency_With_Visible,
      Shared_Dependency_Use_Visible,
      Shared_Dependency_Private_Full_View,
      Shared_Dependency_Limited_View,
      Shared_Dependency_Child_Visible,
      Shared_Dependency_Private_Child_Visible,
      Shared_Dependency_Generic_Instance_Visible,
      Shared_Dependency_Missing,
      Shared_Dependency_Ambiguous,
      Shared_Dependency_Overflow,
      Shared_Dependency_Stale,
      Shared_Dependency_Unknown);

   type Cross_Unit_Shared_State_Status is
     (Cross_Unit_Shared_State_Not_Checked,
      Cross_Unit_Shared_State_Legal_Local_Accepted,
      Cross_Unit_Shared_State_Legal_With_Use_Accepted,
      Cross_Unit_Shared_State_Legal_Private_Full_View_Accepted,
      Cross_Unit_Shared_State_Legal_Limited_View_Accepted,
      Cross_Unit_Shared_State_Legal_Child_Private_Child_Accepted,
      Cross_Unit_Shared_State_Legal_Generic_Instance_Accepted,
      Cross_Unit_Shared_State_Legal_Abstract_State_Accepted,
      Cross_Unit_Shared_State_Legal_Volatile_Atomic_Accepted,
      Cross_Unit_Shared_State_Legal_Overload_Type_Accepted,
      Cross_Unit_Shared_State_Legal_Representation_Accepted,
      Cross_Unit_Shared_State_Legal_Tasking_Protected_Accepted,
      Cross_Unit_Shared_State_Missing_Cross_Unit_Row,
      Cross_Unit_Shared_State_Cross_Unit_Blocker,
      Cross_Unit_Shared_State_Missing_Abstract_State_Row,
      Cross_Unit_Shared_State_Abstract_State_Blocker,
      Cross_Unit_Shared_State_Missing_Shared_State_Row,
      Cross_Unit_Shared_State_Shared_State_Blocker,
      Cross_Unit_Shared_State_Missing_Overload_State_Row,
      Cross_Unit_Shared_State_Overload_State_Blocker,
      Cross_Unit_Shared_State_Missing_Representation_State_Row,
      Cross_Unit_Shared_State_Representation_State_Blocker,
      Cross_Unit_Shared_State_Missing_Tasking_State_Row,
      Cross_Unit_Shared_State_Tasking_State_Blocker,
      Cross_Unit_Shared_State_Missing_Dependency,
      Cross_Unit_Shared_State_Ambiguous_Dependency,
      Cross_Unit_Shared_State_Dependency_Overflow,
      Cross_Unit_Shared_State_Stale_Dependency,
      Cross_Unit_Shared_State_Limited_View_Barrier,
      Cross_Unit_Shared_State_Private_View_Barrier,
      Cross_Unit_Shared_State_Child_Visibility_Blocker,
      Cross_Unit_Shared_State_Generic_Body_Unavailable,
      Cross_Unit_Shared_State_Generic_Backmapping_Blocker,
      Cross_Unit_Shared_State_State_Visibility_Blocker,
      Cross_Unit_Shared_State_Abstract_Constituent_Blocker,
      Cross_Unit_Shared_State_Volatile_Atomic_Order_Blocker,
      Cross_Unit_Shared_State_Shared_Variable_Blocker,
      Cross_Unit_Shared_State_Representation_Effect_Blocker,
      Cross_Unit_Shared_State_Tasking_Effect_Blocker,
      Cross_Unit_Shared_State_Source_Fingerprint_Mismatch,
      Cross_Unit_Shared_State_Multiple_Blockers,
      Cross_Unit_Shared_State_Indeterminate);

   type Cross_Unit_Shared_State_Context_Info is record
      Id                         : Cross_Unit_Shared_State_Row_Id := No_Cross_Unit_Shared_State_Row;
      Kind                       : Cross_Unit_Shared_State_Context_Kind := Cross_Unit_Shared_State_Unknown;
      Dependency                 : Cross_Unit_Shared_State_Dependency_State := Shared_Dependency_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Row             : Cross_Unit.Cross_Unit_Final_Row_Id := Cross_Unit.No_Cross_Unit_Final_Row;
      Cross_Unit_Status          : Cross_Unit.Cross_Unit_Final_Status := Cross_Unit.Cross_Unit_Final_Not_Checked;
      Abstract_State_Row         : Abstract_States.Abstract_State_Row_Id := Abstract_States.No_Abstract_State_Row;
      Abstract_State_Status      : Abstract_States.Abstract_State_Status := Abstract_States.Abstract_State_Not_Checked;
      Shared_State_Row           : Shared_State.Shared_State_Row_Id := Shared_State.No_Shared_State_Row;
      Shared_State_Status        : Shared_State.Shared_State_Status := Shared_State.Shared_State_Not_Checked;
      Overload_State_Row         : Overload_State.Overload_Shared_State_Row_Id := Overload_State.No_Overload_Shared_State_Row;
      Overload_State_Status      : Overload_State.Overload_Shared_State_Status := Overload_State.Overload_Shared_State_Not_Checked;
      Representation_State_Row   : Rep_State.Representation_Shared_State_Row_Id := Rep_State.No_Representation_Shared_State_Row;
      Representation_State_Status : Rep_State.Representation_Shared_State_Status := Rep_State.Representation_Shared_State_Not_Checked;
      Tasking_State_Row          : Tasking_State.Tasking_Shared_State_Row_Id := Tasking_State.No_Tasking_Shared_State_Row;
      Tasking_State_Status       : Tasking_State.Tasking_Shared_State_Status := Tasking_State.Tasking_Shared_State_Not_Checked;
      Requires_Cross_Unit        : Boolean := True;
      Requires_Abstract_State    : Boolean := True;
      Requires_Shared_State      : Boolean := True;
      Requires_Overload_State    : Boolean := False;
      Requires_Representation_State : Boolean := False;
      Requires_Tasking_State     : Boolean := False;
      Limited_View_Barrier       : Boolean := False;
      Private_View_Barrier       : Boolean := False;
      Child_Visibility_Blocker   : Boolean := False;
      Generic_Body_Unavailable   : Boolean := False;
      Generic_Backmapping_Blocker : Boolean := False;
      State_Visibility_Blocker   : Boolean := False;
      Abstract_Constituent_Blocker : Boolean := False;
      Volatile_Atomic_Order_Blocker : Boolean := False;
      Shared_Variable_Blocker    : Boolean := False;
      Representation_Effect_Blocker : Boolean := False;
      Tasking_Effect_Blocker     : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Cross_Unit_Shared_State_Info is record
      Id                         : Cross_Unit_Shared_State_Row_Id := No_Cross_Unit_Shared_State_Row;
      Context                    : Cross_Unit_Shared_State_Row_Id := No_Cross_Unit_Shared_State_Row;
      Kind                       : Cross_Unit_Shared_State_Context_Kind := Cross_Unit_Shared_State_Unknown;
      Dependency                 : Cross_Unit_Shared_State_Dependency_State := Shared_Dependency_Unknown;
      Status                     : Cross_Unit_Shared_State_Status := Cross_Unit_Shared_State_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Cross_Unit_Shared_State_Context_Model is private;
   type Cross_Unit_Shared_State_Model is private;
   type Cross_Unit_Shared_State_Set is private;

   procedure Clear (Model : in out Cross_Unit_Shared_State_Context_Model);
   procedure Add_Context (Model : in out Cross_Unit_Shared_State_Context_Model; Info : Cross_Unit_Shared_State_Context_Info);
   function Context_Count (Model : Cross_Unit_Shared_State_Context_Model) return Natural;
   function Context_At (Model : Cross_Unit_Shared_State_Context_Model; Index : Positive) return Cross_Unit_Shared_State_Context_Info;
   function Fingerprint (Model : Cross_Unit_Shared_State_Context_Model) return Natural;

   function Build (Contexts : Cross_Unit_Shared_State_Context_Model) return Cross_Unit_Shared_State_Model;
   function Row_Count (Model : Cross_Unit_Shared_State_Model) return Natural;
   function Row_At (Model : Cross_Unit_Shared_State_Model; Index : Positive) return Cross_Unit_Shared_State_Info;
   function First_For_Node (Model : Cross_Unit_Shared_State_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_Shared_State_Info;
   function Rows_For_Status (Model : Cross_Unit_Shared_State_Model; Status : Cross_Unit_Shared_State_Status) return Cross_Unit_Shared_State_Set;
   function Rows_For_Kind (Model : Cross_Unit_Shared_State_Model; Kind : Cross_Unit_Shared_State_Context_Kind) return Cross_Unit_Shared_State_Set;
   function Set_Count (Set : Cross_Unit_Shared_State_Set) return Natural;
   function Set_At (Set : Cross_Unit_Shared_State_Set; Index : Positive) return Cross_Unit_Shared_State_Info;
   function Count_Status (Model : Cross_Unit_Shared_State_Model; Status : Cross_Unit_Shared_State_Status) return Natural;
   function Count_Kind (Model : Cross_Unit_Shared_State_Model; Kind : Cross_Unit_Shared_State_Context_Kind) return Natural;
   function Legal_Count (Model : Cross_Unit_Shared_State_Model) return Natural;
   function Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural;
   function Dependency_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural;
   function View_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural;
   function Shared_State_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural;
   function Representation_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural;
   function Tasking_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural;
   function Indeterminate_Count (Model : Cross_Unit_Shared_State_Model) return Natural;
   function Fingerprint (Model : Cross_Unit_Shared_State_Model) return Natural;

   function Is_Legal (Status : Cross_Unit_Shared_State_Status) return Boolean;
   function Is_Dependency_Error (Status : Cross_Unit_Shared_State_Status) return Boolean;
   function Is_View_Error (Status : Cross_Unit_Shared_State_Status) return Boolean;
   function Is_Shared_State_Error (Status : Cross_Unit_Shared_State_Status) return Boolean;
   function Is_Representation_Error (Status : Cross_Unit_Shared_State_Status) return Boolean;
   function Is_Tasking_Error (Status : Cross_Unit_Shared_State_Status) return Boolean;
   function Is_Indeterminate (Status : Cross_Unit_Shared_State_Status) return Boolean;
   function Has_Error (Info : Cross_Unit_Shared_State_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Cross_Unit_Shared_State_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Cross_Unit_Shared_State_Info);

   type Cross_Unit_Shared_State_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Cross_Unit_Shared_State_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Cross_Unit_Shared_State_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
