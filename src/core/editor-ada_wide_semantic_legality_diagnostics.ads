with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Tasking_Protected_Legality;

package Editor.Ada_Wide_Semantic_Legality_Diagnostics is

   --  Pass1107 compiler-grade semantic diagnostic bridge for the widened
   --  legality layers introduced in Pass1099 through Pass1106.  This package
   --  consumes already-built, snapshot-owned legality models and exposes their
   --  failing states as one deterministic diagnostic model.  It performs no
   --  parsing, file IO, buffer mutation, command/keybinding/workspace mutation,
   --  or render-side work.

   type Wide_Semantic_Diagnostic_Id is new Natural;
   No_Wide_Semantic_Diagnostic : constant Wide_Semantic_Diagnostic_Id := 0;

   type Wide_Semantic_Diagnostic_Family is
     (Wide_Semantic_Diagnostic_Assignment,
      Wide_Semantic_Diagnostic_Return,
      Wide_Semantic_Diagnostic_Conversion_Access_Aggregate,
      Wide_Semantic_Diagnostic_Control_Flow,
      Wide_Semantic_Diagnostic_Tasking_Protected,
      Wide_Semantic_Diagnostic_Tagged_Derived,
      Wide_Semantic_Diagnostic_Generic_Instance,
      Wide_Semantic_Diagnostic_Cross_Unit,
      Wide_Semantic_Diagnostic_Accessibility_Lifetime,
      Wide_Semantic_Diagnostic_Unknown);

   type Wide_Semantic_Diagnostic_Severity is
     (Wide_Semantic_Diagnostic_Severity_Info,
      Wide_Semantic_Diagnostic_Warning,
      Wide_Semantic_Diagnostic_Error);

   type Wide_Semantic_Diagnostic_Kind is
     (Wide_Semantic_Diagnostic_Assignment_Legality_Error,
      Wide_Semantic_Diagnostic_Return_Legality_Error,
      Wide_Semantic_Diagnostic_Conversion_Access_Aggregate_Error,
      Wide_Semantic_Diagnostic_Control_Flow_Error,
      Wide_Semantic_Diagnostic_Tasking_Protected_Error,
      Wide_Semantic_Diagnostic_Tagged_Derived_Error,
      Wide_Semantic_Diagnostic_Generic_Instance_Error,
      Wide_Semantic_Diagnostic_Cross_Unit_Error,
      Wide_Semantic_Diagnostic_Accessibility_Lifetime_Error,
      Wide_Semantic_Diagnostic_View_Barrier,
      Wide_Semantic_Diagnostic_Static_Range_Error,
      Wide_Semantic_Diagnostic_Unresolved_Semantic_State,
      Wide_Semantic_Diagnostic_Indeterminate_State,
      Wide_Semantic_Diagnostic_Unknown);

   type Wide_Semantic_Diagnostic_Info is record
      Id       : Wide_Semantic_Diagnostic_Id := No_Wide_Semantic_Diagnostic;
      Family   : Wide_Semantic_Diagnostic_Family := Wide_Semantic_Diagnostic_Unknown;
      Kind     : Wide_Semantic_Diagnostic_Kind := Wide_Semantic_Diagnostic_Unknown;
      Severity : Wide_Semantic_Diagnostic_Severity := Wide_Semantic_Diagnostic_Warning;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      Assignment : Editor.Ada_Assignment_Legality.Assignment_Legality_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Legality;
      Assignment_Status : Editor.Ada_Assignment_Legality.Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Legality : Editor.Ada_Return_Legality.Return_Legality_Id :=
        Editor.Ada_Return_Legality.No_Return_Legality;
      Return_Status : Editor.Ada_Return_Legality.Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Expression_Legality : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Id :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.No_Semantic_Legality;
      Expression_Status : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Flow_Legality : Editor.Ada_Control_Flow_Legality.Flow_Legality_Id :=
        Editor.Ada_Control_Flow_Legality.No_Flow_Legality;
      Flow_Status : Editor.Ada_Control_Flow_Legality.Flow_Legality_Status :=
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Not_Checked;
      Tasking_Legality : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Id :=
        Editor.Ada_Tasking_Protected_Legality.No_Tasking_Legality;
      Tasking_Status : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Status :=
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Not_Checked;
      Tagged_Legality : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Id :=
        Editor.Ada_Tagged_Derived_Legality.No_Tagged_Legality;
      Tagged_Status : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Status :=
        Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Not_Checked;
      Instance_Legality : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Id :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.No_Instance_Legality;
      Instance_Status : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Cross_Unit_Semantic : Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Id :=
        Editor.Ada_Cross_Unit_Semantic_Closure.No_Cross_Unit_Semantic;
      Cross_Unit_Status : Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Status :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint        : Natural := 0;
   end record;

   type Wide_Semantic_Diagnostic_Result_Set is private;
   type Wide_Semantic_Diagnostic_Model is private;

   procedure Clear (Model : in out Wide_Semantic_Diagnostic_Model);

   function Build
     (Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Expressions : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model;
      Flow        : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model;
      Tasking     : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Model;
      Tagged_Model      : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model;
      Instances   : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Model;
      Cross_Unit  : Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Model)
      return Wide_Semantic_Diagnostic_Model;

   function Diagnostic_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Diagnostic_At
     (Model : Wide_Semantic_Diagnostic_Model;
      Index : Positive) return Wide_Semantic_Diagnostic_Info;

   function First_For_Node
     (Model : Wide_Semantic_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Wide_Semantic_Diagnostic_Info;
   function Rows_For_Family
     (Model  : Wide_Semantic_Diagnostic_Model;
      Family : Wide_Semantic_Diagnostic_Family) return Wide_Semantic_Diagnostic_Result_Set;
   function Rows_For_Kind
     (Model : Wide_Semantic_Diagnostic_Model;
      Kind  : Wide_Semantic_Diagnostic_Kind) return Wide_Semantic_Diagnostic_Result_Set;
   function Rows_For_Severity
     (Model    : Wide_Semantic_Diagnostic_Model;
      Severity : Wide_Semantic_Diagnostic_Severity) return Wide_Semantic_Diagnostic_Result_Set;

   function Result_Count (Results : Wide_Semantic_Diagnostic_Result_Set) return Natural;
   function Result_At
     (Results : Wide_Semantic_Diagnostic_Result_Set;
      Index   : Positive) return Wide_Semantic_Diagnostic_Info;

   function Count_Family
     (Model  : Wide_Semantic_Diagnostic_Model;
      Family : Wide_Semantic_Diagnostic_Family) return Natural;
   function Count_Kind
     (Model : Wide_Semantic_Diagnostic_Model;
      Kind  : Wide_Semantic_Diagnostic_Kind) return Natural;
   function Count_Severity
     (Model    : Wide_Semantic_Diagnostic_Model;
      Severity : Wide_Semantic_Diagnostic_Severity) return Natural;

   function Error_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Info_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Assignment_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Return_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Expression_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Control_Flow_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Tasking_Protected_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Tagged_Derived_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Generic_Instance_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Cross_Unit_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function View_Barrier_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Static_Range_Error_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Unresolved_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Wide_Semantic_Diagnostic_Model) return Natural;

private
   package Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Wide_Semantic_Diagnostic_Info);

   type Wide_Semantic_Diagnostic_Result_Set is record
      Items       : Diagnostic_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Wide_Semantic_Diagnostic_Model is record
      Diagnostics        : Diagnostic_Vectors.Vector;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Wide_Semantic_Legality_Diagnostics;
