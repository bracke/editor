with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Precision_Legality;
with Editor.Ada_Discriminant_Dependent_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Accessibility_Scope_Graph_Legality is

   --  Pass1143 accessibility/lifetime full scope graph legality.
   --
   --  This package deepens the accessibility precision layer into an explicit
   --  master/scope graph.  It connects nested masters, anonymous access
   --  parameter levels, allocator masters, return-object masters, access
   --  discriminant lifetimes, access conversions, generic replay substitution,
   --  and discriminant-dependent aggregate use sites.  It performs no parsing,
   --  file IO, command registration, editor mutation, compiler invocation, or
   --  render-side analysis.

   type Scope_Context_Id is new Natural;
   No_Scope_Context : constant Scope_Context_Id := 0;

   type Scope_Legality_Id is new Natural;
   No_Scope_Legality : constant Scope_Legality_Id := 0;

   type Scope_Level is new Natural;
   Unknown_Scope_Level : constant Scope_Level := 0;

   type Scope_Context_Kind is
     (Scope_Context_Master,
      Scope_Context_Nested_Scope,
      Scope_Context_Anonymous_Access_Parameter,
      Scope_Context_Access_Parameter_Escape,
      Scope_Context_Allocator,
      Scope_Context_Return_Object,
      Scope_Context_Return_Access,
      Scope_Context_Access_Discriminant,
      Scope_Context_Access_Conversion,
      Scope_Context_Generic_Substitution,
      Scope_Context_Renaming,
      Scope_Context_Discriminant_Aggregate,
      Scope_Context_Finalization_Master,
      Scope_Context_Unknown);

   type Scope_Legality_Status is
     (Scope_Legality_Not_Checked,
      Scope_Legality_Legal_Master_Hierarchy,
      Scope_Legality_Legal_Static_Level,
      Scope_Legality_Legal_Dynamic_Check,
      Scope_Legality_Legal_Allocator_Master,
      Scope_Legality_Legal_Return_Object_Master,
      Scope_Legality_Legal_Return_Access_Master,
      Scope_Legality_Legal_Access_Discriminant_Master,
      Scope_Legality_Legal_Access_Conversion,
      Scope_Legality_Legal_Generic_Substitution,
      Scope_Legality_Legal_Discriminant_Aggregate,
      Scope_Legality_Missing_Master,
      Scope_Legality_Master_Too_Short,
      Scope_Legality_Static_Level_Too_Deep,
      Scope_Legality_Dynamic_Level_Unresolved,
      Scope_Legality_Anonymous_Access_Level_Unresolved,
      Scope_Legality_Anonymous_Access_Level_Too_Deep,
      Scope_Legality_Access_Parameter_Escapes,
      Scope_Legality_Allocator_Master_Unresolved,
      Scope_Legality_Allocator_Master_Too_Short,
      Scope_Legality_Allocator_Designated_Subtype_Mismatch,
      Scope_Legality_Return_Object_Master_Too_Short,
      Scope_Legality_Return_Access_Master_Too_Short,
      Scope_Legality_Return_Master_Unresolved,
      Scope_Legality_Access_Discriminant_Master_Unresolved,
      Scope_Legality_Access_Discriminant_Master_Too_Short,
      Scope_Legality_Access_Conversion_Level_Too_Deep,
      Scope_Legality_Generic_Substitution_Master_Mismatch,
      Scope_Legality_Generic_Substitution_Master_Unresolved,
      Scope_Legality_Dangling_Renaming_Risk,
      Scope_Legality_Finalization_Master_Unresolved,
      Scope_Legality_Finalization_Uses_Expired_Master,
      Scope_Legality_Linked_Accessibility_Precision_Error,
      Scope_Legality_Linked_Generic_Replay_Error,
      Scope_Legality_Linked_Discriminant_Error,
      Scope_Legality_Coverage_Gate_Blocker,
      Scope_Legality_Multiple_Blockers,
      Scope_Legality_Indeterminate);

   type Scope_Context_Info is record
      Id       : Scope_Context_Id := No_Scope_Context;
      Kind     : Scope_Context_Kind := Scope_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name : Ada.Strings.Unbounded.Unbounded_String;
      Scope_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Source_Level : Scope_Level := Unknown_Scope_Level;
      Target_Level : Scope_Level := Unknown_Scope_Level;
      Master_Level : Scope_Level := Unknown_Scope_Level;
      Required_Master_Level : Scope_Level := Unknown_Scope_Level;
      Return_Master_Level : Scope_Level := Unknown_Scope_Level;
      Allocator_Master_Level : Scope_Level := Unknown_Scope_Level;
      Designated_Object_Level : Scope_Level := Unknown_Scope_Level;
      Parent_Master_Level : Scope_Level := Unknown_Scope_Level;
      Has_Master : Boolean := False;
      Requires_Static_Level : Boolean := False;
      Requires_Dynamic_Check : Boolean := False;
      Anonymous_Access_Parameter : Boolean := False;
      Access_Parameter_Escapes : Boolean := False;
      Allocator_Context : Boolean := False;
      Return_Context : Boolean := False;
      Access_Discriminant_Context : Boolean := False;
      Generic_Substitution_Context : Boolean := False;
      Discriminant_Aggregate_Context : Boolean := False;
      Finalization_Context : Boolean := False;
      Designated_Subtype_Mismatch : Boolean := False;
      Finalization_Uses_Expired_Master : Boolean := False;
      Precision_Status : Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Status :=
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Not_Checked;
      Replay_Status : Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Status :=
        Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Not_Checked;
      Discriminant_Status : Editor.Ada_Discriminant_Dependent_Legality.Discriminant_Legality_Status :=
        Editor.Ada_Discriminant_Dependent_Legality.Discriminant_Legality_Not_Checked;
      Gate_Status : Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Status :=
        Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Not_Checked;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
   end record;

   type Scope_Legality_Info is record
      Id       : Scope_Legality_Id := No_Scope_Legality;
      Context  : Scope_Context_Id := No_Scope_Context;
      Kind     : Scope_Context_Kind := Scope_Context_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Scope_Legality_Status := Scope_Legality_Not_Checked;
      Object_Name : Ada.Strings.Unbounded.Unbounded_String;
      Scope_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      Source_Level : Scope_Level := Unknown_Scope_Level;
      Target_Level : Scope_Level := Unknown_Scope_Level;
      Master_Level : Scope_Level := Unknown_Scope_Level;
      Required_Master_Level : Scope_Level := Unknown_Scope_Level;
      Blocker_Count : Natural := 0;
      Precision_Status : Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Status :=
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Not_Checked;
      Replay_Status : Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Status :=
        Editor.Ada_Generic_Instance_Body_Semantic_Replay.Replay_Not_Checked;
      Discriminant_Status : Editor.Ada_Discriminant_Dependent_Legality.Discriminant_Legality_Status :=
        Editor.Ada_Discriminant_Dependent_Legality.Discriminant_Legality_Not_Checked;
      Gate_Status : Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Status :=
        Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Not_Checked;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Scope_Context_Model is private;
   type Scope_Result_Set is private;
   type Scope_Legality_Model is private;

   procedure Clear (Model : in out Scope_Context_Model);
   procedure Add_Context
     (Model : in out Scope_Context_Model;
      Info  : Scope_Context_Info);

   function Context_Count (Model : Scope_Context_Model) return Natural;
   function Context_At
     (Model : Scope_Context_Model;
      Index : Positive) return Scope_Context_Info;
   function Fingerprint (Model : Scope_Context_Model) return Natural;

   function Build (Contexts : Scope_Context_Model) return Scope_Legality_Model;

   function Row_Count (Model : Scope_Legality_Model) return Natural;
   function Row_At
     (Model : Scope_Legality_Model;
      Index : Positive) return Scope_Legality_Info;
   function First_For_Node
     (Model : Scope_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Scope_Legality_Info;
   function Rows_For_Status
     (Model  : Scope_Legality_Model;
      Status : Scope_Legality_Status) return Scope_Result_Set;
   function Rows_For_Kind
     (Model : Scope_Legality_Model;
      Kind  : Scope_Context_Kind) return Scope_Result_Set;
   function Rows_For_Object
     (Model       : Scope_Legality_Model;
      Object_Name : String) return Scope_Result_Set;

   function Result_Count (Results : Scope_Result_Set) return Natural;
   function Result_At
     (Results : Scope_Result_Set;
      Index   : Positive) return Scope_Legality_Info;

   function Count_Status
     (Model  : Scope_Legality_Model;
      Status : Scope_Legality_Status) return Natural;
   function Count_Kind
     (Model : Scope_Legality_Model;
      Kind  : Scope_Context_Kind) return Natural;

   function Legal_Count (Model : Scope_Legality_Model) return Natural;
   function Error_Count (Model : Scope_Legality_Model) return Natural;
   function Master_Error_Count (Model : Scope_Legality_Model) return Natural;
   function Return_Error_Count (Model : Scope_Legality_Model) return Natural;
   function Allocator_Error_Count (Model : Scope_Legality_Model) return Natural;
   function Access_Discriminant_Error_Count (Model : Scope_Legality_Model) return Natural;
   function Generic_Error_Count (Model : Scope_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Scope_Legality_Model) return Natural;
   function Coverage_Gate_Error_Count (Model : Scope_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Scope_Legality_Model) return Natural;
   function Fingerprint (Model : Scope_Legality_Model) return Natural;

   function Has_Legality (Info : Scope_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Scope_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Scope_Legality_Info);

   type Scope_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Scope_Result_Set is record
      Items : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Scope_Legality_Model is record
      Rows : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Accessibility_Scope_Graph_Legality;
