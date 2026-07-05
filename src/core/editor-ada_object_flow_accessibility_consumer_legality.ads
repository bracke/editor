with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Scope_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Object_Flow_Accessibility_Consumer_Legality is

   --  Case 1163 compiler-grade object-flow accessibility consumer legality.
   --
   --  This layer feeds the exact accessibility-scope consumer result from
   --  Case 1162 into the concrete object-flow consumers that previously could
   --  remain confident after a broad assignment, return, conversion, allocator,
   --  aggregate, renaming, or generic-replay conclusion.  The result is a
   --  deterministic, snapshot-owned legality row that says whether object-flow
   --  legality may be kept confident, must be blocked by a precise lifetime or
   --  discriminant/representation error, or must degrade to indeterminate.

   package Access_Consumers renames Editor.Ada_Accessibility_Scope_Consumer_Legality;

   type Object_Flow_Row_Id is new Natural;
   No_Object_Flow_Row : constant Object_Flow_Row_Id := 0;

   type Object_Flow_Context_Kind is
     (Object_Flow_Assignment,
      Object_Flow_Object_Initialization,
      Object_Flow_Component_Initialization,
      Object_Flow_Return_Object,
      Object_Flow_Return_Access,
      Object_Flow_Conversion,
      Object_Flow_Access_Conversion,
      Object_Flow_Qualified_Expression,
      Object_Flow_Allocator,
      Object_Flow_Access_Discriminant,
      Object_Flow_Record_Aggregate,
      Object_Flow_Array_Aggregate,
      Object_Flow_Renaming,
      Object_Flow_Generic_Actual,
      Object_Flow_Generic_Replay,
      Object_Flow_Finalization,
      Object_Flow_Unknown);

   type Object_Flow_Status is
     (Object_Flow_Not_Checked,
      Object_Flow_Legal_Assignment_Accepted,
      Object_Flow_Legal_Initialization_Accepted,
      Object_Flow_Legal_Return_Object_Accepted,
      Object_Flow_Legal_Return_Access_Accepted,
      Object_Flow_Legal_Conversion_Accepted,
      Object_Flow_Legal_Access_Conversion_Accepted,
      Object_Flow_Legal_Qualified_Expression_Accepted,
      Object_Flow_Legal_Allocator_Accepted,
      Object_Flow_Legal_Access_Discriminant_Accepted,
      Object_Flow_Legal_Aggregate_Accepted,
      Object_Flow_Legal_Renaming_Accepted,
      Object_Flow_Legal_Generic_Actual_Accepted,
      Object_Flow_Legal_Generic_Replay_Accepted,
      Object_Flow_Legal_Finalization_Accepted,
      Object_Flow_Missing_Accessibility_Consumer_Row,
      Object_Flow_Mismatched_Accessibility_Consumer_Kind,
      Object_Flow_Return_Access_Master_Too_Short,
      Object_Flow_Return_Object_Master_Too_Short,
      Object_Flow_Return_Master_Unresolved,
      Object_Flow_Allocator_Master_Too_Short,
      Object_Flow_Allocator_Master_Unresolved,
      Object_Flow_Allocator_Designated_Subtype_Mismatch,
      Object_Flow_Access_Conversion_Level_Too_Deep,
      Object_Flow_Access_Discriminant_Master_Too_Short,
      Object_Flow_Access_Discriminant_Master_Unresolved,
      Object_Flow_Access_Parameter_Escapes,
      Object_Flow_Anonymous_Access_Level_Too_Deep,
      Object_Flow_Anonymous_Access_Level_Unresolved,
      Object_Flow_Static_Level_Too_Deep,
      Object_Flow_Dynamic_Level_Unresolved,
      Object_Flow_Generic_Substitution_Master_Mismatch,
      Object_Flow_Generic_Substitution_Master_Unresolved,
      Object_Flow_Dangling_Renaming_Risk,
      Object_Flow_Finalization_Master_Unresolved,
      Object_Flow_Finalization_Uses_Expired_Master,
      Object_Flow_Discriminant_Variant_Blocker,
      Object_Flow_Generic_Representation_Blocker,
      Object_Flow_Representation_Flow_Blocker,
      Object_Flow_Coverage_Gate_Blocker,
      Object_Flow_Linked_Accessibility_Error,
      Object_Flow_Linked_Generic_Replay_Error,
      Object_Flow_Multiple_Accessibility_Blockers,
      Object_Flow_Preserved_Object_Flow_Error,
      Object_Flow_Indeterminate);

   type Object_Flow_Context_Info is record
      Id                              : Object_Flow_Row_Id := No_Object_Flow_Row;
      Kind                            : Object_Flow_Context_Kind := Object_Flow_Unknown;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                     : Ada.Strings.Unbounded.Unbounded_String;
      Target_Type                     : Ada.Strings.Unbounded.Unbounded_String;
      Source_Type                     : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      Accessibility_Row               : Access_Consumers.Accessibility_Consumer_Row_Id := Access_Consumers.No_Accessibility_Consumer_Row;
      Accessibility_Status            : Access_Consumers.Accessibility_Consumer_Status := Access_Consumers.Accessibility_Consumer_Not_Checked;
      Accessibility_Kind              : Access_Consumers.Accessibility_Consumer_Context_Kind := Access_Consumers.Accessibility_Consumer_Unknown;
      Accessibility_Matches           : Natural := 0;
      Original_Object_Flow_Error      : Boolean := False;
      Start_Line                      : Positive := 1;
      Start_Column                    : Positive := 1;
      End_Line                        : Positive := 1;
      End_Column                      : Positive := 1;
      Source_Fingerprint              : Natural := 0;
      Accessibility_Fingerprint       : Natural := 0;
      Object_Flow_Fingerprint         : Natural := 0;
   end record;

   type Object_Flow_Info is record
      Id                              : Object_Flow_Row_Id := No_Object_Flow_Row;
      Context                         : Object_Flow_Row_Id := No_Object_Flow_Row;
      Kind                            : Object_Flow_Context_Kind := Object_Flow_Unknown;
      Status                          : Object_Flow_Status := Object_Flow_Not_Checked;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                     : Ada.Strings.Unbounded.Unbounded_String;
      Target_Type                     : Ada.Strings.Unbounded.Unbounded_String;
      Source_Type                     : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      Message                         : Ada.Strings.Unbounded.Unbounded_String;
      Detail                          : Ada.Strings.Unbounded.Unbounded_String;
      Accessibility_Row               : Access_Consumers.Accessibility_Consumer_Row_Id := Access_Consumers.No_Accessibility_Consumer_Row;
      Accessibility_Status            : Access_Consumers.Accessibility_Consumer_Status := Access_Consumers.Accessibility_Consumer_Not_Checked;
      Accessibility_Kind              : Access_Consumers.Accessibility_Consumer_Context_Kind := Access_Consumers.Accessibility_Consumer_Unknown;
      Accessibility_Matches           : Natural := 0;
      Original_Object_Flow_Error      : Boolean := False;
      Start_Line                      : Positive := 1;
      Start_Column                    : Positive := 1;
      End_Line                        : Positive := 1;
      End_Column                      : Positive := 1;
      Source_Fingerprint              : Natural := 0;
      Accessibility_Fingerprint       : Natural := 0;
      Object_Flow_Fingerprint         : Natural := 0;
      Fingerprint                     : Natural := 0;
   end record;

   type Object_Flow_Context_Model is private;
   type Object_Flow_Set is private;
   type Object_Flow_Model is private;

   procedure Clear (Model : in out Object_Flow_Context_Model);
   procedure Add_Context
     (Model : in out Object_Flow_Context_Model;
      Info  : Object_Flow_Context_Info);

   function Context_Count (Model : Object_Flow_Context_Model) return Natural;
   function Context_At
     (Model : Object_Flow_Context_Model;
      Index : Positive) return Object_Flow_Context_Info;
   function Fingerprint (Model : Object_Flow_Context_Model) return Natural;

   function Build
     (Contexts : Object_Flow_Context_Model) return Object_Flow_Model;

   function Row_Count (Model : Object_Flow_Model) return Natural;
   function Row_At
     (Model : Object_Flow_Model;
      Index : Positive) return Object_Flow_Info;
   function First_For_Node
     (Model : Object_Flow_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Object_Flow_Info;
   function Rows_For_Status
     (Model  : Object_Flow_Model;
      Status : Object_Flow_Status) return Object_Flow_Set;
   function Rows_For_Kind
     (Model : Object_Flow_Model;
      Kind  : Object_Flow_Context_Kind) return Object_Flow_Set;
   function Rows_For_Object
     (Model : Object_Flow_Model;
      Name  : String) return Object_Flow_Set;
   function Rows_For_Instance
     (Model : Object_Flow_Model;
      Name  : String) return Object_Flow_Set;

   function Set_Count (Results : Object_Flow_Set) return Natural;
   function Set_At
     (Results : Object_Flow_Set;
      Index   : Positive) return Object_Flow_Info;

   function Count_Status
     (Model  : Object_Flow_Model;
      Status : Object_Flow_Status) return Natural;
   function Count_Kind
     (Model : Object_Flow_Model;
      Kind  : Object_Flow_Context_Kind) return Natural;

   function Legal_Count (Model : Object_Flow_Model) return Natural;
   function Error_Count (Model : Object_Flow_Model) return Natural;
   function Return_Error_Count (Model : Object_Flow_Model) return Natural;
   function Allocator_Error_Count (Model : Object_Flow_Model) return Natural;
   function Access_Error_Count (Model : Object_Flow_Model) return Natural;
   function Generic_Error_Count (Model : Object_Flow_Model) return Natural;
   function Representation_Error_Count (Model : Object_Flow_Model) return Natural;
   function Coverage_Error_Count (Model : Object_Flow_Model) return Natural;
   function Indeterminate_Count (Model : Object_Flow_Model) return Natural;
   function Fingerprint (Model : Object_Flow_Model) return Natural;

   function Has_Confident_Object_Flow (Info : Object_Flow_Info) return Boolean;
   function Is_Return_Error (Status : Object_Flow_Status) return Boolean;
   function Is_Allocator_Error (Status : Object_Flow_Status) return Boolean;
   function Is_Access_Error (Status : Object_Flow_Status) return Boolean;
   function Is_Generic_Error (Status : Object_Flow_Status) return Boolean;
   function Is_Representation_Error (Status : Object_Flow_Status) return Boolean;
   function Is_Coverage_Error (Status : Object_Flow_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Object_Flow_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Object_Flow_Info);

   type Object_Flow_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Object_Flow_Set is record
      Items : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Object_Flow_Model is record
      Rows : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
