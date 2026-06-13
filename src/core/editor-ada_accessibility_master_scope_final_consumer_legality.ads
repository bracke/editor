with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Scope_Consumer_Legality;
with Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality is

   --  Pass1183 compiler-grade accessibility master/scope final consumer legality.
   --
   --  This layer closes the remaining hard accessibility consumer gaps by making
   --  exact master/scope, object-flow, discriminant/variant, and generic replay
   --  backmapping evidence mandatory for contexts that are easy to accept too
   --  early: anonymous access function results, access discriminants, allocators,
   --  aggregate-contained access values, generic access escapes, renamings, and
   --  controlled return-object/finalization paths.  It performs no parsing, no
   --  editor mutation, no command registration, and no render-side analysis.

   package Scope_Consumer renames Editor.Ada_Accessibility_Scope_Consumer_Legality;
   package Object_Flow renames Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
   package Disc_Consumer renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;

   type Master_Scope_Final_Row_Id is new Natural;
   No_Master_Scope_Final_Row : constant Master_Scope_Final_Row_Id := 0;

   type Master_Scope_Final_Context_Kind is
     (Master_Scope_Final_Anonymous_Access_Result,
      Master_Scope_Final_Anonymous_Access_Parameter,
      Master_Scope_Final_Access_Discriminant,
      Master_Scope_Final_Allocator_Master,
      Master_Scope_Final_Aggregate_Access_Component,
      Master_Scope_Final_Access_Conversion,
      Master_Scope_Final_Return_Object,
      Master_Scope_Final_Return_Access,
      Master_Scope_Final_Generic_Access_Actual,
      Master_Scope_Final_Generic_Replay_Escape,
      Master_Scope_Final_Renaming,
      Master_Scope_Final_Controlled_Finalization,
      Master_Scope_Final_Private_Full_View,
      Master_Scope_Final_Cross_Unit_Lifetime,
      Master_Scope_Final_Unknown);

   type Master_Scope_Final_Status is
     (Master_Scope_Final_Not_Checked,
      Master_Scope_Final_Legal_Anonymous_Access_Result_Accepted,
      Master_Scope_Final_Legal_Anonymous_Access_Parameter_Accepted,
      Master_Scope_Final_Legal_Access_Discriminant_Accepted,
      Master_Scope_Final_Legal_Allocator_Master_Accepted,
      Master_Scope_Final_Legal_Aggregate_Access_Component_Accepted,
      Master_Scope_Final_Legal_Access_Conversion_Accepted,
      Master_Scope_Final_Legal_Return_Object_Accepted,
      Master_Scope_Final_Legal_Return_Access_Accepted,
      Master_Scope_Final_Legal_Generic_Access_Actual_Accepted,
      Master_Scope_Final_Legal_Generic_Replay_Escape_Accepted,
      Master_Scope_Final_Legal_Renaming_Accepted,
      Master_Scope_Final_Legal_Controlled_Finalization_Accepted,
      Master_Scope_Final_Legal_Private_Full_View_Accepted,
      Master_Scope_Final_Legal_Cross_Unit_Lifetime_Accepted,
      Master_Scope_Final_Missing_Scope_Consumer_Row,
      Master_Scope_Final_Scope_Consumer_Blocker,
      Master_Scope_Final_Scope_Consumer_Indeterminate,
      Master_Scope_Final_Missing_Object_Flow_Row,
      Master_Scope_Final_Object_Flow_Blocker,
      Master_Scope_Final_Object_Flow_Indeterminate,
      Master_Scope_Final_Missing_Discriminant_Consumer_Row,
      Master_Scope_Final_Discriminant_Consumer_Blocker,
      Master_Scope_Final_Discriminant_Consumer_Indeterminate,
      Master_Scope_Final_Missing_Generic_Backmap_Row,
      Master_Scope_Final_Generic_Backmap_Blocker,
      Master_Scope_Final_Generic_Backmap_Indeterminate,
      Master_Scope_Final_Anonymous_Access_Result_Escapes,
      Master_Scope_Final_Access_Parameter_Escapes,
      Master_Scope_Final_Access_Discriminant_Master_Blocker,
      Master_Scope_Final_Allocator_Master_Blocker,
      Master_Scope_Final_Aggregate_Access_Master_Blocker,
      Master_Scope_Final_Access_Conversion_Level_Blocker,
      Master_Scope_Final_Return_Object_Master_Blocker,
      Master_Scope_Final_Return_Access_Master_Blocker,
      Master_Scope_Final_Generic_Access_Escape_Blocker,
      Master_Scope_Final_Renaming_Dangling_Blocker,
      Master_Scope_Final_Finalization_Master_Blocker,
      Master_Scope_Final_Private_Full_View_Lifetime_Blocker,
      Master_Scope_Final_Cross_Unit_Lifetime_Blocker,
      Master_Scope_Final_Discriminant_Variant_Blocker,
      Master_Scope_Final_Representation_Freezing_Blocker,
      Master_Scope_Final_Coverage_Blocker,
      Master_Scope_Final_Multiple_Scope_Consumer_Blockers,
      Master_Scope_Final_Multiple_Object_Flow_Blockers,
      Master_Scope_Final_Multiple_Discriminant_Consumer_Blockers,
      Master_Scope_Final_Multiple_Generic_Backmap_Blockers,
      Master_Scope_Final_Indeterminate);

   type Master_Scope_Final_Context_Info is record
      Id                         : Master_Scope_Final_Row_Id := No_Master_Scope_Final_Row;
      Kind                       : Master_Scope_Final_Context_Kind := Master_Scope_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Scope_Consumer_Row         : Scope_Consumer.Accessibility_Consumer_Row_Id := Scope_Consumer.No_Accessibility_Consumer_Row;
      Scope_Consumer_Status      : Scope_Consumer.Accessibility_Consumer_Status := Scope_Consumer.Accessibility_Consumer_Not_Checked;
      Scope_Consumer_Matches     : Natural := 0;
      Object_Flow_Row            : Object_Flow.Object_Flow_Row_Id := Object_Flow.No_Object_Flow_Row;
      Object_Flow_Status         : Object_Flow.Object_Flow_Status := Object_Flow.Object_Flow_Not_Checked;
      Object_Flow_Matches        : Natural := 0;
      Discriminant_Row           : Disc_Consumer.Discriminant_Consumer_Row_Id := Disc_Consumer.No_Discriminant_Consumer_Row;
      Discriminant_Status        : Disc_Consumer.Discriminant_Consumer_Status := Disc_Consumer.Discriminant_Consumer_Not_Checked;
      Discriminant_Matches       : Natural := 0;
      Generic_Backmap_Row        : Backmap.Generic_Backmap_Row_Id := Backmap.No_Generic_Backmap_Row;
      Generic_Backmap_Status     : Backmap.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Generic_Backmap_Matches    : Natural := 0;
      Requires_Object_Flow       : Boolean := True;
      Requires_Discriminant      : Boolean := False;
      Requires_Generic_Backmap   : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Scope_Fingerprint          : Natural := 0;
      Object_Flow_Fingerprint    : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
   end record;

   type Master_Scope_Final_Info is record
      Id                         : Master_Scope_Final_Row_Id := No_Master_Scope_Final_Row;
      Context                    : Master_Scope_Final_Row_Id := No_Master_Scope_Final_Row;
      Kind                       : Master_Scope_Final_Context_Kind := Master_Scope_Final_Unknown;
      Status                     : Master_Scope_Final_Status := Master_Scope_Final_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Scope_Consumer_Row         : Scope_Consumer.Accessibility_Consumer_Row_Id := Scope_Consumer.No_Accessibility_Consumer_Row;
      Scope_Consumer_Status      : Scope_Consumer.Accessibility_Consumer_Status := Scope_Consumer.Accessibility_Consumer_Not_Checked;
      Object_Flow_Row            : Object_Flow.Object_Flow_Row_Id := Object_Flow.No_Object_Flow_Row;
      Object_Flow_Status         : Object_Flow.Object_Flow_Status := Object_Flow.Object_Flow_Not_Checked;
      Discriminant_Row           : Disc_Consumer.Discriminant_Consumer_Row_Id := Disc_Consumer.No_Discriminant_Consumer_Row;
      Discriminant_Status        : Disc_Consumer.Discriminant_Consumer_Status := Disc_Consumer.Discriminant_Consumer_Not_Checked;
      Generic_Backmap_Row        : Backmap.Generic_Backmap_Row_Id := Backmap.No_Generic_Backmap_Row;
      Generic_Backmap_Status     : Backmap.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Source_Fingerprint         : Natural := 0;
      Scope_Fingerprint          : Natural := 0;
      Object_Flow_Fingerprint    : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Master_Scope_Final_Context_Model is private;
   type Master_Scope_Final_Set is private;
   type Master_Scope_Final_Model is private;

   procedure Clear (Model : in out Master_Scope_Final_Context_Model);
   procedure Add_Context
     (Model : in out Master_Scope_Final_Context_Model;
      Info  : Master_Scope_Final_Context_Info);

   function Context_Count (Model : Master_Scope_Final_Context_Model) return Natural;
   function Context_At
     (Model : Master_Scope_Final_Context_Model;
      Index : Positive) return Master_Scope_Final_Context_Info;
   function Fingerprint (Model : Master_Scope_Final_Context_Model) return Natural;

   function Build
     (Contexts : Master_Scope_Final_Context_Model) return Master_Scope_Final_Model;

   function Row_Count (Model : Master_Scope_Final_Model) return Natural;
   function Row_At
     (Model : Master_Scope_Final_Model;
      Index : Positive) return Master_Scope_Final_Info;
   function First_For_Node
     (Model : Master_Scope_Final_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Master_Scope_Final_Info;
   function Rows_For_Status
     (Model  : Master_Scope_Final_Model;
      Status : Master_Scope_Final_Status) return Master_Scope_Final_Set;
   function Rows_For_Kind
     (Model : Master_Scope_Final_Model;
      Kind  : Master_Scope_Final_Context_Kind) return Master_Scope_Final_Set;
   function Rows_For_Object
     (Model       : Master_Scope_Final_Model;
      Object_Name : String) return Master_Scope_Final_Set;

   function Set_Count (Set : Master_Scope_Final_Set) return Natural;
   function Set_At
     (Set   : Master_Scope_Final_Set;
      Index : Positive) return Master_Scope_Final_Info;

   function Count_Status
     (Model  : Master_Scope_Final_Model;
      Status : Master_Scope_Final_Status) return Natural;
   function Count_Kind
     (Model : Master_Scope_Final_Model;
      Kind  : Master_Scope_Final_Context_Kind) return Natural;

   function Legal_Count (Model : Master_Scope_Final_Model) return Natural;
   function Error_Count (Model : Master_Scope_Final_Model) return Natural;
   function Scope_Error_Count (Model : Master_Scope_Final_Model) return Natural;
   function Object_Flow_Error_Count (Model : Master_Scope_Final_Model) return Natural;
   function Discriminant_Error_Count (Model : Master_Scope_Final_Model) return Natural;
   function Generic_Backmap_Error_Count (Model : Master_Scope_Final_Model) return Natural;
   function Lifetime_Error_Count (Model : Master_Scope_Final_Model) return Natural;
   function Indeterminate_Count (Model : Master_Scope_Final_Model) return Natural;
   function Fingerprint (Model : Master_Scope_Final_Model) return Natural;

   function Is_Legal (Status : Master_Scope_Final_Status) return Boolean;
   function Is_Scope_Error (Status : Master_Scope_Final_Status) return Boolean;
   function Is_Object_Flow_Error (Status : Master_Scope_Final_Status) return Boolean;
   function Is_Discriminant_Error (Status : Master_Scope_Final_Status) return Boolean;
   function Is_Generic_Backmap_Error (Status : Master_Scope_Final_Status) return Boolean;
   function Is_Lifetime_Error (Status : Master_Scope_Final_Status) return Boolean;
   function Is_Indeterminate (Status : Master_Scope_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Master_Scope_Final_Context_Info);

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Master_Scope_Final_Info);

   type Master_Scope_Final_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Master_Scope_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

   type Master_Scope_Final_Model is record
      Rows : Row_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
