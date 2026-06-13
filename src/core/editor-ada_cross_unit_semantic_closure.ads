with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Cross_Unit_Lookup_Integration;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Tasking_Protected_Legality;

package Editor.Ada_Cross_Unit_Semantic_Closure is

   --  Wide compiler-grade semantic legality building block for Pass1106.
   --  This package connects cross-unit dependency and lookup state to the
   --  assignment, return, conversion/access/aggregate, control-flow,
   --  tasking/protected, tagged/derived, and generic-instance legality layers.
   --  It is snapshot-owned and fixture-friendly: callers provide already-built
   --  semantic models and cross-unit dependency facts.  The package performs no
   --  parsing, file IO, save/reload, buffer mutation, command/keybinding/
   --  workspace mutation, or render-side work.

   type Cross_Unit_Semantic_Context_Id is new Natural;
   No_Cross_Unit_Semantic_Context : constant Cross_Unit_Semantic_Context_Id := 0;

   type Cross_Unit_Semantic_Id is new Natural;
   No_Cross_Unit_Semantic : constant Cross_Unit_Semantic_Id := 0;

   type Cross_Unit_Semantic_Context_Kind is
     (Cross_Unit_Semantic_Assignment,
      Cross_Unit_Semantic_Return,
      Cross_Unit_Semantic_Expression,
      Cross_Unit_Semantic_Control_Flow,
      Cross_Unit_Semantic_Tasking_Protected,
      Cross_Unit_Semantic_Tagged_Derived,
      Cross_Unit_Semantic_Generic_Instance,
      Cross_Unit_Semantic_Representation,
      Cross_Unit_Semantic_Visibility,
      Cross_Unit_Semantic_Unknown);

   type Cross_Unit_Semantic_Status is
     (Cross_Unit_Semantic_Not_Checked,
      Cross_Unit_Semantic_Closed,
      Cross_Unit_Semantic_Local_Only,
      Cross_Unit_Semantic_With_Visible,
      Cross_Unit_Semantic_Use_Visible,
      Cross_Unit_Semantic_Limited_View_Barrier,
      Cross_Unit_Semantic_Private_View_Barrier,
      Cross_Unit_Semantic_Missing_Dependency,
      Cross_Unit_Semantic_Ambiguous_Dependency,
      Cross_Unit_Semantic_Dependency_Overflow,
      Cross_Unit_Semantic_Missing_Lookup,
      Cross_Unit_Semantic_Ambiguous_Lookup,
      Cross_Unit_Semantic_Lookup_Overflow,
      Cross_Unit_Semantic_Assignment_Error,
      Cross_Unit_Semantic_Return_Error,
      Cross_Unit_Semantic_Expression_Error,
      Cross_Unit_Semantic_Control_Flow_Error,
      Cross_Unit_Semantic_Tasking_Error,
      Cross_Unit_Semantic_Tagged_Derived_Error,
      Cross_Unit_Semantic_Generic_Instance_Error,
      Cross_Unit_Semantic_Representation_Error,
      Cross_Unit_Semantic_Indeterminate);

   type Cross_Unit_Semantic_Context_Info is record
      Id                  : Cross_Unit_Semantic_Context_Id := No_Cross_Unit_Semantic_Context;
      Kind                : Cross_Unit_Semantic_Context_Kind := Cross_Unit_Semantic_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Lookup_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Source_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Lookup_Name : Ada.Strings.Unbounded.Unbounded_String;
      Requires_Cross_Unit_Dependency : Boolean := False;
      Requires_Cross_Unit_Lookup     : Boolean := False;
      Dependency_Status  : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Status :=
        Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Not_Applicable;
      Lookup_Status      : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Status :=
        Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Not_Found;
      Dependency_Fingerprint : Natural := 0;
      Lookup_Fingerprint : Natural := 0;
      Linked_Assignment  : Editor.Ada_Assignment_Legality.Assignment_Context_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Context;
      Linked_Return      : Editor.Ada_Return_Legality.Return_Context_Id :=
        Editor.Ada_Return_Legality.No_Return_Context;
      Linked_Expression  : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Context_Id :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.No_Semantic_Context;
      Linked_Flow        : Editor.Ada_Control_Flow_Legality.Flow_Context_Id :=
        Editor.Ada_Control_Flow_Legality.No_Flow_Context;
      Linked_Tasking     : Editor.Ada_Tasking_Protected_Legality.Tasking_Context_Id :=
        Editor.Ada_Tasking_Protected_Legality.No_Tasking_Context;
      Linked_Tagged      : Editor.Ada_Tagged_Derived_Legality.Tagged_Context_Id :=
        Editor.Ada_Tagged_Derived_Legality.No_Tagged_Context;
      Linked_Instance    : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Context_Id :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.No_Instance_Context;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Cross_Unit_Semantic_Info is record
      Id                  : Cross_Unit_Semantic_Id := No_Cross_Unit_Semantic;
      Context             : Cross_Unit_Semantic_Context_Id := No_Cross_Unit_Semantic_Context;
      Kind                : Cross_Unit_Semantic_Context_Kind := Cross_Unit_Semantic_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status              : Cross_Unit_Semantic_Status := Cross_Unit_Semantic_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Source_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Lookup_Name : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Status  : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Status :=
        Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Not_Applicable;
      Lookup_Status      : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Status :=
        Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Not_Found;
      Linked_Assignment_Status : Editor.Ada_Assignment_Legality.Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Linked_Return_Status : Editor.Ada_Return_Legality.Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Linked_Expression_Status : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Linked_Flow_Status : Editor.Ada_Control_Flow_Legality.Flow_Legality_Status :=
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Not_Checked;
      Linked_Tasking_Status : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Status :=
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Not_Checked;
      Linked_Tagged_Status : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Status :=
        Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Not_Checked;
      Linked_Instance_Status : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Cross_Unit_Semantic_Context_Model is private;
   type Cross_Unit_Semantic_Result_Set is private;
   type Cross_Unit_Semantic_Model is private;

   procedure Clear (Model : in out Cross_Unit_Semantic_Context_Model);
   procedure Add_Context
     (Model   : in out Cross_Unit_Semantic_Context_Model;
      Context : Cross_Unit_Semantic_Context_Info);

   function Context_Count (Model : Cross_Unit_Semantic_Context_Model) return Natural;
   function Context_At
     (Model : Cross_Unit_Semantic_Context_Model;
      Index : Positive) return Cross_Unit_Semantic_Context_Info;
   function Fingerprint (Model : Cross_Unit_Semantic_Context_Model) return Natural;

   function Build
     (Contexts    : Cross_Unit_Semantic_Context_Model;
      Closure     : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Lookup      : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Expressions : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model;
      Flow        : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model;
      Tasking     : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Model;
      Tagged_Model      : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model;
      Instances   : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Model)
      return Cross_Unit_Semantic_Model;

   function Semantic_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Semantic_At
     (Model : Cross_Unit_Semantic_Model;
      Index : Positive) return Cross_Unit_Semantic_Info;

   function First_For_Context
     (Model   : Cross_Unit_Semantic_Model;
      Context : Cross_Unit_Semantic_Context_Id) return Cross_Unit_Semantic_Info;
   function First_For_Node
     (Model : Cross_Unit_Semantic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_Semantic_Info;
   function Rows_For_Status
     (Model  : Cross_Unit_Semantic_Model;
      Status : Cross_Unit_Semantic_Status) return Cross_Unit_Semantic_Result_Set;
   function Rows_For_Kind
     (Model : Cross_Unit_Semantic_Model;
      Kind  : Cross_Unit_Semantic_Context_Kind) return Cross_Unit_Semantic_Result_Set;
   function Rows_For_Source_Unit
     (Model : Cross_Unit_Semantic_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Cross_Unit_Semantic_Result_Set;
   function Rows_For_Target_Unit
     (Model : Cross_Unit_Semantic_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Cross_Unit_Semantic_Result_Set;
   function Rows_For_Lookup_Name
     (Model : Cross_Unit_Semantic_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Cross_Unit_Semantic_Result_Set;

   function Result_Count (Results : Cross_Unit_Semantic_Result_Set) return Natural;
   function Result_At
     (Results : Cross_Unit_Semantic_Result_Set;
      Index   : Positive) return Cross_Unit_Semantic_Info;

   function Count_Status
     (Model  : Cross_Unit_Semantic_Model;
      Status : Cross_Unit_Semantic_Status) return Natural;
   function Count_Kind
     (Model : Cross_Unit_Semantic_Model;
      Kind  : Cross_Unit_Semantic_Context_Kind) return Natural;

   function Closed_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Local_Only_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Cross_Unit_Visible_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Limited_View_Barrier_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Private_View_Barrier_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Dependency_Error_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Lookup_Error_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Linked_Semantic_Error_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Error_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Warning_Count (Model : Cross_Unit_Semantic_Model) return Natural;
   function Fingerprint (Model : Cross_Unit_Semantic_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cross_Unit_Semantic_Context_Info);

   package Semantic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cross_Unit_Semantic_Info);

   type Cross_Unit_Semantic_Context_Model is record
      Entries           : Context_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

   type Cross_Unit_Semantic_Result_Set is record
      Entries : Semantic_Vectors.Vector;
   end record;

   type Cross_Unit_Semantic_Model is record
      Entries                    : Semantic_Vectors.Vector;
      Closed_Total               : Natural := 0;
      Local_Only_Total           : Natural := 0;
      Cross_Unit_Visible_Total   : Natural := 0;
      Limited_View_Barrier_Total : Natural := 0;
      Private_View_Barrier_Total : Natural := 0;
      Dependency_Error_Total     : Natural := 0;
      Lookup_Error_Total         : Natural := 0;
      Linked_Semantic_Error_Total : Natural := 0;
      Error_Total                : Natural := 0;
      Warning_Total              : Natural := 0;
      Model_Fingerprint          : Natural := 0;
   end record;

end Editor.Ada_Cross_Unit_Semantic_Closure;
