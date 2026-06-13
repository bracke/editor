with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Scope_Graph_Legality;
with Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Accessibility_Scope_Consumer_Legality is

   --  Pass1162 compiler-grade accessibility scope consumer legality.
   --
   --  This layer feeds the exact master/scope graph into assignment, return,
   --  conversion/access, allocator, access-discriminant, renaming, generic
   --  replay, representation/freezing, and finalization consumers.  These
   --  consumers may no longer keep a confident local legality result when the
   --  matching scope graph row is missing, blocked, or indeterminate.  The
   --  package also preserves discriminant/generic/representation blockers for
   --  access discriminants and represented generic contexts so lifetime errors
   --  do not disappear behind aggregate or representation consumers.

   package Scope renames Editor.Ada_Accessibility_Scope_Graph_Legality;
   package Disc_Gen renames Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;

   type Accessibility_Consumer_Row_Id is new Natural;
   No_Accessibility_Consumer_Row : constant Accessibility_Consumer_Row_Id := 0;

   type Accessibility_Consumer_Context_Kind is
     (Accessibility_Consumer_Assignment,
      Accessibility_Consumer_Return_Object,
      Accessibility_Consumer_Return_Access,
      Accessibility_Consumer_Conversion,
      Accessibility_Consumer_Access_Conversion,
      Accessibility_Consumer_Allocator,
      Accessibility_Consumer_Access_Discriminant,
      Accessibility_Consumer_Access_Parameter,
      Accessibility_Consumer_Renaming,
      Accessibility_Consumer_Generic_Replay,
      Accessibility_Consumer_Generic_Actual,
      Accessibility_Consumer_Record_Aggregate,
      Accessibility_Consumer_Representation_Clause,
      Accessibility_Consumer_Record_Layout,
      Accessibility_Consumer_Freezing_Effect,
      Accessibility_Consumer_Finalization,
      Accessibility_Consumer_Unknown);

   type Accessibility_Consumer_Status is
     (Accessibility_Consumer_Not_Checked,
      Accessibility_Consumer_Legal_Assignment_Accepted,
      Accessibility_Consumer_Legal_Return_Object_Accepted,
      Accessibility_Consumer_Legal_Return_Access_Accepted,
      Accessibility_Consumer_Legal_Conversion_Accepted,
      Accessibility_Consumer_Legal_Access_Conversion_Accepted,
      Accessibility_Consumer_Legal_Allocator_Accepted,
      Accessibility_Consumer_Legal_Access_Discriminant_Accepted,
      Accessibility_Consumer_Legal_Access_Parameter_Accepted,
      Accessibility_Consumer_Legal_Renaming_Accepted,
      Accessibility_Consumer_Legal_Generic_Replay_Accepted,
      Accessibility_Consumer_Legal_Generic_Actual_Accepted,
      Accessibility_Consumer_Legal_Record_Aggregate_Accepted,
      Accessibility_Consumer_Legal_Representation_Clause_Accepted,
      Accessibility_Consumer_Legal_Record_Layout_Accepted,
      Accessibility_Consumer_Legal_Freezing_Effect_Accepted,
      Accessibility_Consumer_Legal_Finalization_Accepted,
      Accessibility_Consumer_Missing_Scope_Row,
      Accessibility_Consumer_Missing_Discriminant_Generic_Row,
      Accessibility_Consumer_Missing_Master,
      Accessibility_Consumer_Master_Too_Short,
      Accessibility_Consumer_Static_Level_Too_Deep,
      Accessibility_Consumer_Dynamic_Level_Unresolved,
      Accessibility_Consumer_Anonymous_Access_Level_Unresolved,
      Accessibility_Consumer_Anonymous_Access_Level_Too_Deep,
      Accessibility_Consumer_Access_Parameter_Escapes,
      Accessibility_Consumer_Allocator_Master_Unresolved,
      Accessibility_Consumer_Allocator_Master_Too_Short,
      Accessibility_Consumer_Allocator_Designated_Subtype_Mismatch,
      Accessibility_Consumer_Return_Object_Master_Too_Short,
      Accessibility_Consumer_Return_Access_Master_Too_Short,
      Accessibility_Consumer_Return_Master_Unresolved,
      Accessibility_Consumer_Access_Discriminant_Master_Unresolved,
      Accessibility_Consumer_Access_Discriminant_Master_Too_Short,
      Accessibility_Consumer_Access_Conversion_Level_Too_Deep,
      Accessibility_Consumer_Generic_Substitution_Master_Mismatch,
      Accessibility_Consumer_Generic_Substitution_Master_Unresolved,
      Accessibility_Consumer_Dangling_Renaming_Risk,
      Accessibility_Consumer_Finalization_Master_Unresolved,
      Accessibility_Consumer_Finalization_Uses_Expired_Master,
      Accessibility_Consumer_Linked_Accessibility_Precision_Error,
      Accessibility_Consumer_Linked_Generic_Replay_Error,
      Accessibility_Consumer_Linked_Discriminant_Error,
      Accessibility_Consumer_Scope_Coverage_Gate_Blocker,
      Accessibility_Consumer_Multiple_Scope_Blockers,
      Accessibility_Consumer_Discriminant_Generic_Error,
      Accessibility_Consumer_Discriminant_Variant_Error,
      Accessibility_Consumer_Generic_Representation_Error,
      Accessibility_Consumer_Representation_Flow_Error,
      Accessibility_Consumer_Multiple_Discriminant_Generic_Blockers,
      Accessibility_Consumer_Indeterminate);

   type Accessibility_Consumer_Context_Info is record
      Id                              : Accessibility_Consumer_Row_Id := No_Accessibility_Consumer_Row;
      Kind                            : Accessibility_Consumer_Context_Kind := Accessibility_Consumer_Unknown;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                     : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                       : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      Scope_Row                       : Scope.Scope_Legality_Id := Scope.No_Scope_Legality;
      Scope_Status                    : Scope.Scope_Legality_Status := Scope.Scope_Legality_Not_Checked;
      Scope_Matches                   : Natural := 0;
      Discriminant_Generic_Row        : Disc_Gen.Discriminant_Generic_Row_Id := Disc_Gen.No_Discriminant_Generic_Row;
      Discriminant_Generic_Status     : Disc_Gen.Discriminant_Generic_Status := Disc_Gen.Discriminant_Generic_Not_Checked;
      Discriminant_Generic_Matches    : Natural := 0;
      Start_Line                      : Positive := 1;
      Start_Column                    : Positive := 1;
      End_Line                        : Positive := 1;
      End_Column                      : Positive := 1;
      Source_Fingerprint              : Natural := 0;
      Scope_Fingerprint               : Natural := 0;
      Consumer_Fingerprint            : Natural := 0;
   end record;

   type Accessibility_Consumer_Info is record
      Id                              : Accessibility_Consumer_Row_Id := No_Accessibility_Consumer_Row;
      Context                         : Accessibility_Consumer_Row_Id := No_Accessibility_Consumer_Row;
      Kind                            : Accessibility_Consumer_Context_Kind := Accessibility_Consumer_Unknown;
      Status                          : Accessibility_Consumer_Status := Accessibility_Consumer_Not_Checked;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                     : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                       : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      Message                         : Ada.Strings.Unbounded.Unbounded_String;
      Detail                          : Ada.Strings.Unbounded.Unbounded_String;
      Scope_Row                       : Scope.Scope_Legality_Id := Scope.No_Scope_Legality;
      Scope_Status                    : Scope.Scope_Legality_Status := Scope.Scope_Legality_Not_Checked;
      Scope_Matches                   : Natural := 0;
      Discriminant_Generic_Row        : Disc_Gen.Discriminant_Generic_Row_Id := Disc_Gen.No_Discriminant_Generic_Row;
      Discriminant_Generic_Status     : Disc_Gen.Discriminant_Generic_Status := Disc_Gen.Discriminant_Generic_Not_Checked;
      Discriminant_Generic_Matches    : Natural := 0;
      Start_Line                      : Positive := 1;
      Start_Column                    : Positive := 1;
      End_Line                        : Positive := 1;
      End_Column                      : Positive := 1;
      Source_Fingerprint              : Natural := 0;
      Scope_Fingerprint               : Natural := 0;
      Consumer_Fingerprint            : Natural := 0;
      Fingerprint                     : Natural := 0;
   end record;

   type Accessibility_Consumer_Context_Model is private;
   type Accessibility_Consumer_Set is private;
   type Accessibility_Consumer_Model is private;

   procedure Clear (Model : in out Accessibility_Consumer_Context_Model);
   procedure Add_Context
     (Model : in out Accessibility_Consumer_Context_Model;
      Info  : Accessibility_Consumer_Context_Info);

   function Context_Count (Model : Accessibility_Consumer_Context_Model) return Natural;
   function Context_At
     (Model : Accessibility_Consumer_Context_Model;
      Index : Positive) return Accessibility_Consumer_Context_Info;
   function Fingerprint (Model : Accessibility_Consumer_Context_Model) return Natural;

   function Build
     (Contexts : Accessibility_Consumer_Context_Model) return Accessibility_Consumer_Model;

   function Row_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Row_At
     (Model : Accessibility_Consumer_Model;
      Index : Positive) return Accessibility_Consumer_Info;
   function First_For_Node
     (Model : Accessibility_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_Consumer_Info;
   function Rows_For_Status
     (Model  : Accessibility_Consumer_Model;
      Status : Accessibility_Consumer_Status) return Accessibility_Consumer_Set;
   function Rows_For_Kind
     (Model : Accessibility_Consumer_Model;
      Kind  : Accessibility_Consumer_Context_Kind) return Accessibility_Consumer_Set;
   function Rows_For_Object
     (Model       : Accessibility_Consumer_Model;
      Object_Name : String) return Accessibility_Consumer_Set;
   function Rows_For_Instance
     (Model         : Accessibility_Consumer_Model;
      Instance_Name : String) return Accessibility_Consumer_Set;

   function Set_Count (Results : Accessibility_Consumer_Set) return Natural;
   function Set_At
     (Results : Accessibility_Consumer_Set;
      Index   : Positive) return Accessibility_Consumer_Info;

   function Count_Status
     (Model  : Accessibility_Consumer_Model;
      Status : Accessibility_Consumer_Status) return Natural;
   function Count_Kind
     (Model : Accessibility_Consumer_Model;
      Kind  : Accessibility_Consumer_Context_Kind) return Natural;

   function Legal_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Error_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Scope_Error_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Return_Error_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Allocator_Error_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Access_Discriminant_Error_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Generic_Error_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Representation_Error_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Accessibility_Consumer_Model) return Natural;
   function Fingerprint (Model : Accessibility_Consumer_Model) return Natural;

   function Has_Confident_Consumer (Info : Accessibility_Consumer_Info) return Boolean;
   function Is_Scope_Error (Status : Accessibility_Consumer_Status) return Boolean;
   function Is_Return_Error (Status : Accessibility_Consumer_Status) return Boolean;
   function Is_Allocator_Error (Status : Accessibility_Consumer_Status) return Boolean;
   function Is_Access_Discriminant_Error (Status : Accessibility_Consumer_Status) return Boolean;
   function Is_Generic_Error (Status : Accessibility_Consumer_Status) return Boolean;
   function Is_Representation_Error (Status : Accessibility_Consumer_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Accessibility_Consumer_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Accessibility_Consumer_Info);

   type Accessibility_Consumer_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Accessibility_Consumer_Set is record
      Items : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Accessibility_Consumer_Model is record
      Rows : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Accessibility_Scope_Consumer_Legality;
