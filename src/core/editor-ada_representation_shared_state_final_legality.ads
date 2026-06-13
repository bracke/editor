with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package Editor.Ada_Representation_Shared_State_Final_Legality is

   --  Pass1214 representation/shared-state final legality.
   --
   --  This package connects final representation/freezing hard-case evidence
   --  to abstract/refined-state, volatile/atomic/shared-variable, and
   --  overload shared-state RM evidence.  It prevents representation,
   --  operational attribute, stream attribute, layout, and freezing
   --  conclusions from remaining confidently legal when shared state or
   --  abstract-state prerequisites are missing, blocked, stale, or mismatched.

   package Abstract_States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   package Overload_State renames Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
   package Rep_Final renames Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
   package Shared_State renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;

   type Representation_Shared_State_Row_Id is new Natural;
   No_Representation_Shared_State_Row : constant Representation_Shared_State_Row_Id := 0;

   type Representation_Shared_State_Context_Kind is
     (Representation_Shared_State_Volatile_Object_Clause,
      Representation_Shared_State_Atomic_Object_Clause,
      Representation_Shared_State_Independent_Component_Clause,
      Representation_Shared_State_Shared_Record_Layout,
      Representation_Shared_State_Abstract_State_View,
      Representation_Shared_State_Stream_Attribute,
      Representation_Shared_State_Operational_Attribute,
      Representation_Shared_State_Private_Full_View_Freezing,
      Representation_Shared_State_Generic_Formal_Freezing,
      Representation_Shared_State_Protected_Object_Representation,
      Representation_Shared_State_Task_Object_Representation,
      Representation_Shared_State_Unknown);

   type Representation_Shared_State_Status is
     (Representation_Shared_State_Not_Checked,
      Representation_Shared_State_Legal_Volatile_Object_Clause_Accepted,
      Representation_Shared_State_Legal_Atomic_Object_Clause_Accepted,
      Representation_Shared_State_Legal_Independent_Component_Clause_Accepted,
      Representation_Shared_State_Legal_Shared_Record_Layout_Accepted,
      Representation_Shared_State_Legal_Abstract_State_View_Accepted,
      Representation_Shared_State_Legal_Stream_Attribute_Accepted,
      Representation_Shared_State_Legal_Operational_Attribute_Accepted,
      Representation_Shared_State_Legal_Private_Full_View_Freezing_Accepted,
      Representation_Shared_State_Legal_Generic_Formal_Freezing_Accepted,
      Representation_Shared_State_Legal_Protected_Object_Representation_Accepted,
      Representation_Shared_State_Legal_Task_Object_Representation_Accepted,
      Representation_Shared_State_Missing_Final_Representation_Row,
      Representation_Shared_State_Final_Representation_Blocker,
      Representation_Shared_State_Final_Representation_Indeterminate,
      Representation_Shared_State_Missing_Shared_State_Row,
      Representation_Shared_State_Shared_State_Blocker,
      Representation_Shared_State_Missing_Abstract_State_Row,
      Representation_Shared_State_Abstract_State_Blocker,
      Representation_Shared_State_Missing_Overload_State_Row,
      Representation_Shared_State_Overload_State_Blocker,
      Representation_Shared_State_Volatile_Representation_Blocker,
      Representation_Shared_State_Atomic_Representation_Blocker,
      Representation_Shared_State_Independent_Component_Blocker,
      Representation_Shared_State_Shared_Record_Layout_Blocker,
      Representation_Shared_State_Stream_Attribute_Blocker,
      Representation_Shared_State_Operational_Attribute_Blocker,
      Representation_Shared_State_Private_View_Freezing_Blocker,
      Representation_Shared_State_Generic_Formal_Freezing_Blocker,
      Representation_Shared_State_Protected_Representation_Blocker,
      Representation_Shared_State_Task_Representation_Blocker,
      Representation_Shared_State_Source_Fingerprint_Mismatch,
      Representation_Shared_State_Multiple_Blockers,
      Representation_Shared_State_Indeterminate);

   type Representation_Shared_State_Context_Info is record
      Id                         : Representation_Shared_State_Row_Id := No_Representation_Shared_State_Row;
      Kind                       : Representation_Shared_State_Context_Kind := Representation_Shared_State_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Final_Representation_Row   : Rep_Final.Final_Representation_Row_Id := Rep_Final.No_Final_Representation_Row;
      Final_Representation_Status : Rep_Final.Final_Representation_Status := Rep_Final.Final_Representation_Not_Checked;
      Shared_State_Row           : Shared_State.Shared_State_Row_Id := Shared_State.No_Shared_State_Row;
      Shared_State_Status        : Shared_State.Shared_State_Status := Shared_State.Shared_State_Not_Checked;
      Abstract_State_Row         : Abstract_States.Abstract_State_Row_Id := Abstract_States.No_Abstract_State_Row;
      Abstract_State_Status      : Abstract_States.Abstract_State_Status := Abstract_States.Abstract_State_Not_Checked;
      Overload_State_Row         : Overload_State.Overload_Shared_State_Row_Id := Overload_State.No_Overload_Shared_State_Row;
      Overload_State_Status      : Overload_State.Overload_Shared_State_Status := Overload_State.Overload_Shared_State_Not_Checked;
      Requires_Final_Representation : Boolean := True;
      Requires_Shared_State      : Boolean := True;
      Requires_Abstract_State    : Boolean := False;
      Requires_Overload_State    : Boolean := False;
      Volatile_Representation_Error : Boolean := False;
      Atomic_Representation_Error : Boolean := False;
      Independent_Component_Error : Boolean := False;
      Shared_Record_Layout_Error : Boolean := False;
      Stream_Attribute_Error     : Boolean := False;
      Operational_Attribute_Error : Boolean := False;
      Private_View_Freezing_Error : Boolean := False;
      Generic_Formal_Freezing_Error : Boolean := False;
      Protected_Representation_Error : Boolean := False;
      Task_Representation_Error  : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Representation_Shared_State_Info is record
      Id                         : Representation_Shared_State_Row_Id := No_Representation_Shared_State_Row;
      Context                    : Representation_Shared_State_Row_Id := No_Representation_Shared_State_Row;
      Kind                       : Representation_Shared_State_Context_Kind := Representation_Shared_State_Unknown;
      Status                     : Representation_Shared_State_Status := Representation_Shared_State_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
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

   type Representation_Shared_State_Context_Model is private;
   type Representation_Shared_State_Model is private;
   type Representation_Shared_State_Set is private;

   procedure Clear (Model : in out Representation_Shared_State_Context_Model);
   procedure Add_Context (Model : in out Representation_Shared_State_Context_Model; Info : Representation_Shared_State_Context_Info);
   function Context_Count (Model : Representation_Shared_State_Context_Model) return Natural;
   function Context_At (Model : Representation_Shared_State_Context_Model; Index : Positive) return Representation_Shared_State_Context_Info;
   function Fingerprint (Model : Representation_Shared_State_Context_Model) return Natural;

   function Build (Contexts : Representation_Shared_State_Context_Model) return Representation_Shared_State_Model;
   function Row_Count (Model : Representation_Shared_State_Model) return Natural;
   function Row_At (Model : Representation_Shared_State_Model; Index : Positive) return Representation_Shared_State_Info;
   function First_For_Node (Model : Representation_Shared_State_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Shared_State_Info;
   function Rows_For_Status (Model : Representation_Shared_State_Model; Status : Representation_Shared_State_Status) return Representation_Shared_State_Set;
   function Rows_For_Kind (Model : Representation_Shared_State_Model; Kind : Representation_Shared_State_Context_Kind) return Representation_Shared_State_Set;
   function Set_Count (Set : Representation_Shared_State_Set) return Natural;
   function Set_At (Set : Representation_Shared_State_Set; Index : Positive) return Representation_Shared_State_Info;
   function Count_Status (Model : Representation_Shared_State_Model; Status : Representation_Shared_State_Status) return Natural;
   function Count_Kind (Model : Representation_Shared_State_Model; Kind : Representation_Shared_State_Context_Kind) return Natural;
   function Legal_Count (Model : Representation_Shared_State_Model) return Natural;
   function Error_Count (Model : Representation_Shared_State_Model) return Natural;
   function Dependency_Error_Count (Model : Representation_Shared_State_Model) return Natural;
   function Shared_State_Error_Count (Model : Representation_Shared_State_Model) return Natural;
   function Representation_Error_Count (Model : Representation_Shared_State_Model) return Natural;
   function Indeterminate_Count (Model : Representation_Shared_State_Model) return Natural;
   function Fingerprint (Model : Representation_Shared_State_Model) return Natural;

   function Is_Legal (Status : Representation_Shared_State_Status) return Boolean;
   function Is_Dependency_Error (Status : Representation_Shared_State_Status) return Boolean;
   function Is_Shared_State_Error (Status : Representation_Shared_State_Status) return Boolean;
   function Is_Representation_Error (Status : Representation_Shared_State_Status) return Boolean;
   function Is_Indeterminate (Status : Representation_Shared_State_Status) return Boolean;
   function Has_Error (Info : Representation_Shared_State_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Representation_Shared_State_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Representation_Shared_State_Info);

   type Representation_Shared_State_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Representation_Shared_State_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Representation_Shared_State_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Representation_Shared_State_Final_Legality;
