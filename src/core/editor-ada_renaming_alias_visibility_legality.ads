with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Unit_Completion_Order_Legality;

package Editor.Ada_Renaming_Alias_Visibility_Legality is

   --  Pass1115 compiler-grade renaming, aliasing, and visibility legality
   --  layer.  This package consumes bounded semantic metadata for Ada
   --  object/subprogram/package/exception/generic renamings, use/use type
   --  visibility, direct visibility, and aliasing hazards.  It performs no
   --  parsing, file IO, save/reload, dirty-state mutation, command routing,
   --  keybinding/workspace mutation, rendering, or compiler invocation.

   subtype Accessibility_Legality_Status is
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status;
   subtype Cross_Unit_Semantic_Status is
     Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Status;
   subtype Overload_Legality_Status is
     Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status;
   subtype Completion_Legality_Status is
     Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Status;

   type Renaming_Context_Id is new Natural;
   No_Renaming_Context : constant Renaming_Context_Id := 0;

   type Renaming_Legality_Id is new Natural;
   No_Renaming_Legality : constant Renaming_Legality_Id := 0;

   type Renaming_Context_Kind is
     (Renaming_Context_Object,
      Renaming_Context_Exception,
      Renaming_Context_Package,
      Renaming_Context_Subprogram,
      Renaming_Context_Generic_Package,
      Renaming_Context_Generic_Subprogram,
      Renaming_Context_Formal_Object,
      Renaming_Context_Use_Package,
      Renaming_Context_Use_Type,
      Renaming_Context_Selected_Name,
      Renaming_Context_Alias_View,
      Renaming_Context_Unknown);

   type Renamed_Entity_Kind is
     (Renamed_Entity_None,
      Renamed_Entity_Object,
      Renamed_Entity_Constant,
      Renamed_Entity_Exception,
      Renamed_Entity_Package,
      Renamed_Entity_Subprogram,
      Renamed_Entity_Generic_Package,
      Renamed_Entity_Generic_Subprogram,
      Renamed_Entity_Type,
      Renamed_Entity_Operator,
      Renamed_Entity_Selected_Component,
      Renamed_Entity_Unknown);

   type Visibility_State is
     (Visibility_Local_Direct,
      Visibility_Local_Use,
      Visibility_Use_Type_Operator,
      Visibility_Selected_Name,
      Visibility_With_Visible,
      Visibility_Private_View,
      Visibility_Limited_View,
      Visibility_Hidden_By_Homograph,
      Visibility_Ambiguous,
      Visibility_Missing,
      Visibility_Overflow,
      Visibility_Unknown);

   type Alias_State is
     (Alias_None,
      Alias_Object_View,
      Alias_Constant_View,
      Alias_Renamed_Object,
      Alias_Self_Rename,
      Alias_Circular_Rename,
      Alias_Dangling_Risk,
      Alias_Requires_Aliased_Target,
      Alias_Target_Not_Aliased,
      Alias_Unknown);

   type Use_Clause_State is
     (Use_Clause_None,
      Use_Clause_Package_Visible,
      Use_Clause_Type_Visible,
      Use_Clause_Duplicate,
      Use_Clause_Non_Package_Target,
      Use_Clause_Non_Type_Target,
      Use_Clause_Private_View_Barrier,
      Use_Clause_Limited_View_Barrier,
      Use_Clause_Ambiguous_Target,
      Use_Clause_Missing_Target,
      Use_Clause_Overflow,
      Use_Clause_Unknown);

   type Renaming_Legality_Status is
     (Renaming_Legality_Not_Checked,
      Renaming_Legality_Legal_Object_Renaming,
      Renaming_Legality_Legal_Exception_Renaming,
      Renaming_Legality_Legal_Package_Renaming,
      Renaming_Legality_Legal_Subprogram_Renaming,
      Renaming_Legality_Legal_Generic_Renaming,
      Renaming_Legality_Legal_Use_Package,
      Renaming_Legality_Legal_Use_Type,
      Renaming_Legality_Legal_Selected_Alias,
      Renaming_Legality_Missing_Target,
      Renaming_Legality_Ambiguous_Target,
      Renaming_Legality_Visibility_Overflow,
      Renaming_Legality_Target_Kind_Mismatch,
      Renaming_Legality_Subprogram_Profile_Mismatch,
      Renaming_Legality_Generic_Profile_Mismatch,
      Renaming_Legality_Object_Subtype_Mismatch,
      Renaming_Legality_Renames_Constant_As_Variable,
      Renaming_Legality_Self_Renaming,
      Renaming_Legality_Circular_Renaming,
      Renaming_Legality_Target_Not_Aliased,
      Renaming_Legality_Dangling_Rename_Risk,
      Renaming_Legality_Hidden_By_Homograph,
      Renaming_Legality_Use_Package_Target_Not_Package,
      Renaming_Legality_Use_Type_Target_Not_Type,
      Renaming_Legality_Duplicate_Use_Clause,
      Renaming_Legality_Private_View_Barrier,
      Renaming_Legality_Limited_View_Barrier,
      Renaming_Legality_Linked_Accessibility_Error,
      Renaming_Legality_Linked_Overload_Error,
      Renaming_Legality_Linked_Cross_Unit_Error,
      Renaming_Legality_Linked_Completion_Order_Error,
      Renaming_Legality_Indeterminate);

   type Renaming_Context_Info is record
      Id                       : Renaming_Context_Id := No_Renaming_Context;
      Kind                     : Renaming_Context_Kind := Renaming_Context_Unknown;
      Renamed_Kind             : Renamed_Entity_Kind := Renamed_Entity_Unknown;
      Visibility               : Visibility_State := Visibility_Unknown;
      Alias                    : Alias_State := Alias_Unknown;
      Use_State                : Use_Clause_State := Use_Clause_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Declaration_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Prefix_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Selector_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name                     : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Target_Present           : Boolean := True;
      Target_Ambiguous         : Boolean := False;
      Target_Kind_Mismatch     : Boolean := False;
      Profile_Mismatch         : Boolean := False;
      Generic_Profile_Mismatch : Boolean := False;
      Object_Subtype_Mismatch  : Boolean := False;
      Renames_Constant_As_Variable : Boolean := False;
      Requires_Aliased_Target  : Boolean := False;
      Target_Is_Aliased        : Boolean := True;
      Accessibility_Status     : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Overload_Status          : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Cross_Unit_Status        : Cross_Unit_Semantic_Status :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked;
      Completion_Status        : Completion_Legality_Status :=
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Not_Checked;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Source_Fingerprint       : Natural := 0;
   end record;

   type Renaming_Legality_Info is record
      Id                       : Renaming_Legality_Id := No_Renaming_Legality;
      Context                  : Renaming_Context_Id := No_Renaming_Context;
      Kind                     : Renaming_Context_Kind := Renaming_Context_Unknown;
      Renamed_Kind             : Renamed_Entity_Kind := Renamed_Entity_Unknown;
      Visibility               : Visibility_State := Visibility_Unknown;
      Alias                    : Alias_State := Alias_Unknown;
      Use_State                : Use_Clause_State := Use_Clause_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Declaration_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Prefix_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Selector_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name                     : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Status                   : Renaming_Legality_Status := Renaming_Legality_Not_Checked;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
      Detail                   : Ada.Strings.Unbounded.Unbounded_String;
      Accessibility_Status     : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Overload_Status          : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Cross_Unit_Status        : Cross_Unit_Semantic_Status :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked;
      Completion_Status        : Completion_Legality_Status :=
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Not_Checked;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Source_Fingerprint       : Natural := 0;
      Fingerprint              : Natural := 0;
   end record;

   type Renaming_Context_Model is private;
   type Renaming_Result_Set is private;
   type Renaming_Legality_Model is private;

   procedure Clear (Model : in out Renaming_Context_Model);
   procedure Add_Context
     (Model : in out Renaming_Context_Model;
      Info  : Renaming_Context_Info);

   function Context_Count (Model : Renaming_Context_Model) return Natural;
   function Context_At
     (Model : Renaming_Context_Model;
      Index : Positive) return Renaming_Context_Info;
   function Fingerprint (Model : Renaming_Context_Model) return Natural;

   function Build (Contexts : Renaming_Context_Model) return Renaming_Legality_Model;

   function Legality_Count (Model : Renaming_Legality_Model) return Natural;
   function Legality_At
     (Model : Renaming_Legality_Model;
      Index : Positive) return Renaming_Legality_Info;

   function First_For_Node
     (Model : Renaming_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Renaming_Legality_Info;
   function Rows_For_Status
     (Model  : Renaming_Legality_Model;
      Status : Renaming_Legality_Status) return Renaming_Result_Set;
   function Rows_For_Kind
     (Model : Renaming_Legality_Model;
      Kind  : Renaming_Context_Kind) return Renaming_Result_Set;
   function Rows_For_Renamed_Kind
     (Model : Renaming_Legality_Model;
      Kind  : Renamed_Entity_Kind) return Renaming_Result_Set;
   function Rows_For_Visibility
     (Model      : Renaming_Legality_Model;
      Visibility : Visibility_State) return Renaming_Result_Set;
   function Rows_For_Alias
     (Model : Renaming_Legality_Model;
      Alias : Alias_State) return Renaming_Result_Set;
   function Rows_For_Use_State
     (Model : Renaming_Legality_Model;
      State : Use_Clause_State) return Renaming_Result_Set;
   function Rows_For_Name
     (Model : Renaming_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Renaming_Result_Set;

   function Result_Count (Set : Renaming_Result_Set) return Natural;
   function Result_At
     (Set   : Renaming_Result_Set;
      Index : Positive) return Renaming_Legality_Info;

   function Legal_Count (Model : Renaming_Legality_Model) return Natural;
   function Error_Count (Model : Renaming_Legality_Model) return Natural;
   function Visibility_Error_Count (Model : Renaming_Legality_Model) return Natural;
   function Alias_Error_Count (Model : Renaming_Legality_Model) return Natural;
   function Use_Clause_Error_Count (Model : Renaming_Legality_Model) return Natural;
   function Profile_Error_Count (Model : Renaming_Legality_Model) return Natural;
   function View_Barrier_Count (Model : Renaming_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Renaming_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Renaming_Legality_Model) return Natural;
   function Count_Status
     (Model  : Renaming_Legality_Model;
      Status : Renaming_Legality_Status) return Natural;
   function Count_Kind
     (Model : Renaming_Legality_Model;
      Kind  : Renaming_Context_Kind) return Natural;
   function Count_Renamed_Kind
     (Model : Renaming_Legality_Model;
      Kind  : Renamed_Entity_Kind) return Natural;
   function Count_Visibility
     (Model      : Renaming_Legality_Model;
      Visibility : Visibility_State) return Natural;
   function Count_Alias
     (Model : Renaming_Legality_Model;
      Alias : Alias_State) return Natural;
   function Count_Use_State
     (Model : Renaming_Legality_Model;
      State : Use_Clause_State) return Natural;
   function Fingerprint (Model : Renaming_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Renaming_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Renaming_Legality_Info);

   type Renaming_Context_Model is record
      Contexts    : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Renaming_Result_Set is record
      Results : Result_Vectors.Vector;
   end record;

   type Renaming_Legality_Model is record
      Rows        : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Renaming_Alias_Visibility_Legality;
