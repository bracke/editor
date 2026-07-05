with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality is

   --  Case 1180 compiler-grade generic replay source/instance backmapping legality.
   --
   --  This layer preserves the two-sided location model required for generic
   --  semantic replay diagnostics and downstream closure: the generic body source
   --  node where the rule is evaluated, and the instantiation/formal/actual
   --  context that caused the substituted legality result.  A replay row cannot
   --  remain confidently legal when the source-instance map, formal-actual map,
   --  substituted body node, instance node, diagnostic backmap, replay CPD row, or
   --  overload/type edge evidence is missing, blocked, ambiguous, or indeterminate.

   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   package Replay_CPD renames Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
   package Overload_Edge renames Editor.Ada_Overload_Type_Edge_Precision_Legality;

   type Generic_Backmap_Row_Id is new Natural;
   No_Generic_Backmap_Row : constant Generic_Backmap_Row_Id := 0;

   type Generic_Backmap_Context_Kind is
     (Generic_Backmap_Declaration_Replay,
      Generic_Backmap_Statement_Replay,
      Generic_Backmap_Expression_Replay,
      Generic_Backmap_Call_Replay,
      Generic_Backmap_Return_Replay,
      Generic_Backmap_Assignment_Replay,
      Generic_Backmap_Representation_Replay,
      Generic_Backmap_Flow_Replay,
      Generic_Backmap_Predicate_Replay,
      Generic_Backmap_Accessibility_Replay,
      Generic_Backmap_Nested_Instance_Replay,
      Generic_Backmap_Unknown);

   type Generic_Backmap_Status is
     (Generic_Backmap_Not_Checked,
      Generic_Backmap_Legal_Declaration_Backmapped,
      Generic_Backmap_Legal_Statement_Backmapped,
      Generic_Backmap_Legal_Expression_Backmapped,
      Generic_Backmap_Legal_Call_Backmapped,
      Generic_Backmap_Legal_Return_Backmapped,
      Generic_Backmap_Legal_Assignment_Backmapped,
      Generic_Backmap_Legal_Representation_Backmapped,
      Generic_Backmap_Legal_Flow_Backmapped,
      Generic_Backmap_Legal_Predicate_Backmapped,
      Generic_Backmap_Legal_Accessibility_Backmapped,
      Generic_Backmap_Legal_Nested_Instance_Backmapped,
      Generic_Backmap_Missing_Generic_Source_Node,
      Generic_Backmap_Missing_Instance_Node,
      Generic_Backmap_Missing_Formal_Node,
      Generic_Backmap_Missing_Actual_Node,
      Generic_Backmap_Missing_Body_Node,
      Generic_Backmap_Missing_Source_Instance_Map,
      Generic_Backmap_Missing_Formal_Actual_Map,
      Generic_Backmap_Missing_Diagnostic_Backmap,
      Generic_Backmap_Source_Instance_Fingerprint_Mismatch,
      Generic_Backmap_Substitution_Fingerprint_Mismatch,
      Generic_Backmap_Base_Replay_Error,
      Generic_Backmap_Replay_Mapping_Error,
      Generic_Backmap_Missing_Replay_CPD_Row,
      Generic_Backmap_Replay_CPD_Blocker,
      Generic_Backmap_Replay_CPD_Indeterminate,
      Generic_Backmap_Missing_Overload_Type_Edge_Row,
      Generic_Backmap_Overload_Type_Edge_Blocker,
      Generic_Backmap_Overload_Type_Edge_Ambiguous,
      Generic_Backmap_Overload_Type_Edge_Indeterminate,
      Generic_Backmap_Multiple_Matching_Replay_CPD_Rows,
      Generic_Backmap_Multiple_Matching_Overload_Rows,
      Generic_Backmap_Indeterminate);

   type Generic_Backmap_Context_Info is record
      Id                         : Generic_Backmap_Row_Id := No_Generic_Backmap_Row;
      Kind                       : Generic_Backmap_Context_Kind := Generic_Backmap_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Source_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Actual_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Substituted_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Replay_Row                 : Replay.Replay_Row_Id := Replay.No_Replay_Row;
      Replay_Status              : Replay.Replay_Status := Replay.Replay_Not_Checked;
      Replay_CPD_Row             : Replay_CPD.Generic_Replay_Representation_Row_Id := Replay_CPD.No_Generic_Replay_Representation_Row;
      Replay_CPD_Status          : Replay_CPD.Generic_Replay_Representation_Status := Replay_CPD.Generic_Replay_Representation_Not_Checked;
      Replay_CPD_Matches         : Natural := 0;
      Overload_Row               : Overload_Edge.Overload_Type_Edge_Row_Id := Overload_Edge.No_Overload_Type_Edge_Row;
      Overload_Status            : Overload_Edge.Overload_Type_Edge_Status := Overload_Edge.Overload_Type_Edge_Not_Checked;
      Overload_Matches           : Natural := 0;
      Source_Instance_Map_Present : Boolean := True;
      Formal_Actual_Map_Present  : Boolean := True;
      Diagnostic_Backmap_Present : Boolean := True;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Generic_Start_Line         : Positive := 1;
      Generic_Start_Column       : Positive := 1;
      Instance_Start_Line        : Positive := 1;
      Instance_Start_Column      : Positive := 1;
   end record;

   type Generic_Backmap_Info is record
      Id                         : Generic_Backmap_Row_Id := No_Generic_Backmap_Row;
      Context                    : Generic_Backmap_Row_Id := No_Generic_Backmap_Row;
      Kind                       : Generic_Backmap_Context_Kind := Generic_Backmap_Unknown;
      Status                     : Generic_Backmap_Status := Generic_Backmap_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Source_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Actual_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Substituted_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Replay_Row                 : Replay.Replay_Row_Id := Replay.No_Replay_Row;
      Replay_Status              : Replay.Replay_Status := Replay.Replay_Not_Checked;
      Replay_CPD_Row             : Replay_CPD.Generic_Replay_Representation_Row_Id := Replay_CPD.No_Generic_Replay_Representation_Row;
      Replay_CPD_Status          : Replay_CPD.Generic_Replay_Representation_Status := Replay_CPD.Generic_Replay_Representation_Not_Checked;
      Overload_Row               : Overload_Edge.Overload_Type_Edge_Row_Id := Overload_Edge.No_Overload_Type_Edge_Row;
      Overload_Status            : Overload_Edge.Overload_Type_Edge_Status := Overload_Edge.Overload_Type_Edge_Not_Checked;
      Fingerprint                : Natural := 0;
   end record;

   type Generic_Backmap_Context_Model is private;
   type Generic_Backmap_Set is private;
   type Generic_Backmap_Model is private;

   procedure Clear (Model : in out Generic_Backmap_Context_Model);
   procedure Add_Context
     (Model : in out Generic_Backmap_Context_Model;
      Info  : Generic_Backmap_Context_Info);

   function Context_Count (Model : Generic_Backmap_Context_Model) return Natural;
   function Context_At
     (Model : Generic_Backmap_Context_Model;
      Index : Positive) return Generic_Backmap_Context_Info;
   function Fingerprint (Model : Generic_Backmap_Context_Model) return Natural;

   function Build (Contexts : Generic_Backmap_Context_Model) return Generic_Backmap_Model;

   function Row_Count (Model : Generic_Backmap_Model) return Natural;
   function Row_At
     (Model : Generic_Backmap_Model;
      Index : Positive) return Generic_Backmap_Info;
   function First_For_Node
     (Model : Generic_Backmap_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Backmap_Info;
   function Rows_For_Status
     (Model  : Generic_Backmap_Model;
      Status : Generic_Backmap_Status) return Generic_Backmap_Set;
   function Rows_For_Instance
     (Model : Generic_Backmap_Model;
      Name  : String) return Generic_Backmap_Set;
   function Rows_For_Generic_Unit
     (Model : Generic_Backmap_Model;
      Name  : String) return Generic_Backmap_Set;

   function Set_Count (Set : Generic_Backmap_Set) return Natural;
   function Set_At
     (Set   : Generic_Backmap_Set;
      Index : Positive) return Generic_Backmap_Info;

   function Count_Status
     (Model  : Generic_Backmap_Model;
      Status : Generic_Backmap_Status) return Natural;
   function Legal_Count (Model : Generic_Backmap_Model) return Natural;
   function Error_Count (Model : Generic_Backmap_Model) return Natural;
   function Mapping_Error_Count (Model : Generic_Backmap_Model) return Natural;
   function Replay_Error_Count (Model : Generic_Backmap_Model) return Natural;
   function Replay_CPD_Error_Count (Model : Generic_Backmap_Model) return Natural;
   function Overload_Error_Count (Model : Generic_Backmap_Model) return Natural;
   function Ambiguous_Count (Model : Generic_Backmap_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Backmap_Model) return Natural;
   function Fingerprint (Model : Generic_Backmap_Model) return Natural;

   function Is_Legal (Status : Generic_Backmap_Status) return Boolean;
   function Is_Mapping_Error (Status : Generic_Backmap_Status) return Boolean;
   function Is_Replay_CPD_Error (Status : Generic_Backmap_Status) return Boolean;
   function Is_Overload_Error (Status : Generic_Backmap_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Generic_Backmap_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Generic_Backmap_Info);

   type Generic_Backmap_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Generic_Backmap_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Generic_Backmap_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Mapping_Error_Total : Natural := 0;
      Replay_Error_Total : Natural := 0;
      Replay_CPD_Error_Total : Natural := 0;
      Overload_Error_Total : Natural := 0;
      Ambiguous_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
