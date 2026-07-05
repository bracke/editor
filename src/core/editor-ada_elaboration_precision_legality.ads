with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Precision_Legality;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
with Editor.Ada_Overload_Preference_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Elaboration_Precision_Legality is

   --  Case 1129 compiler-grade elaboration precision layer.
   --
   --  This package deepens the Case 1113 elaboration/dependence model by
   --  connecting elaboration-order graph closure, generic-instance
   --  elaboration, body-before-use requirements, preelaboration/purity policy,
   --  dataflow effects during elaboration, overload-selected calls, and
   --  accessibility-sensitive access-before-elaboration risks.  It remains
   --  snapshot-owned and projection-free: callers supply bounded semantic facts;
   --  this package performs no parsing, file IO, editor mutation, command
   --  registration, compiler invocation, or render-side analysis.

   subtype Elaboration_Legality_Status is
     Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Status;
   subtype Elaboration_Order_State is
     Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_State;
   subtype Elaboration_Policy_State is
     Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Policy_State;
   subtype Dataflow_Legality_Status is
     Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Status;
   subtype Generic_Body_Expansion_Status is
     Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Status;
   subtype Preference_Legality_Status is
     Editor.Ada_Overload_Preference_Legality.Preference_Legality_Status;
   subtype Accessibility_Precision_Status is
     Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Status;

   type Elaboration_Precision_Context_Id is new Natural;
   No_Elaboration_Precision_Context : constant Elaboration_Precision_Context_Id := 0;

   type Elaboration_Precision_Legality_Id is new Natural;
   No_Elaboration_Precision_Legality : constant Elaboration_Precision_Legality_Id := 0;

   type Elaboration_Precision_Context_Kind is
     (Elaboration_Precision_Context_Dependency_Edge,
      Elaboration_Precision_Context_Call_Edge,
      Elaboration_Precision_Context_Access_Edge,
      Elaboration_Precision_Context_Generic_Instance,
      Elaboration_Precision_Context_Body_Before_Use,
      Elaboration_Precision_Context_Preelaborated_Unit,
      Elaboration_Precision_Context_Pure_Unit,
      Elaboration_Precision_Context_Remote_Types_Unit,
      Elaboration_Precision_Context_Shared_Passive_Unit,
      Elaboration_Precision_Context_Library_Object,
      Elaboration_Precision_Context_Elaboration_Graph,
      Elaboration_Precision_Context_Unknown);

   type Elaboration_Precision_Status is
     (Elaboration_Precision_Not_Checked,
      Elaboration_Precision_Legal_Dependency_Order,
      Elaboration_Precision_Legal_Call_Order,
      Elaboration_Precision_Legal_Access_Order,
      Elaboration_Precision_Legal_Generic_Instance_Order,
      Elaboration_Precision_Legal_Body_Before_Use,
      Elaboration_Precision_Legal_Preelaborated_Unit,
      Elaboration_Precision_Legal_Pure_Unit,
      Elaboration_Precision_Legal_Remote_Types_Unit,
      Elaboration_Precision_Legal_Shared_Passive_Unit,
      Elaboration_Precision_Body_Elaborated_After_Call,
      Elaboration_Precision_Access_Before_Elaboration,
      Elaboration_Precision_Generic_Instance_Body_Not_Elaborated,
      Elaboration_Precision_Generic_Instance_Formal_Body_Unresolved,
      Elaboration_Precision_Missing_Elaborate_All,
      Elaboration_Precision_Missing_Elaborate_Body,
      Elaboration_Precision_Circular_Elaboration_Graph,
      Elaboration_Precision_Missing_Graph_Edge,
      Elaboration_Precision_Ambiguous_Graph_Edge,
      Elaboration_Precision_Preelaborate_Illegal_Call,
      Elaboration_Precision_Preelaborate_Illegal_Object,
      Elaboration_Precision_Pure_Illegal_State,
      Elaboration_Precision_Pure_Illegal_Dependency,
      Elaboration_Precision_Remote_Types_Illegal_Dependency,
      Elaboration_Precision_Shared_Passive_Illegal_Dependency,
      Elaboration_Precision_Elaboration_Dataflow_Write,
      Elaboration_Precision_Elaboration_Dataflow_Read_Before_Write,
      Elaboration_Precision_Elaboration_Dataflow_Use_After_Finalization,
      Elaboration_Precision_Call_Overload_Unresolved,
      Elaboration_Precision_Accessibility_Risk,
      Elaboration_Precision_Linked_Elaboration_Error,
      Elaboration_Precision_Linked_Generic_Body_Error,
      Elaboration_Precision_Linked_Dataflow_Error,
      Elaboration_Precision_Linked_Overload_Preference_Error,
      Elaboration_Precision_Linked_Accessibility_Error,
      Elaboration_Precision_Indeterminate);

   type Elaboration_Precision_Context_Info is record
      Id                      : Elaboration_Precision_Context_Id := No_Elaboration_Precision_Context;
      Kind                    : Elaboration_Precision_Context_Kind := Elaboration_Precision_Context_Unknown;
      Node                    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Order_State             : Elaboration_Order_State :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Unknown;
      Policy_State            : Elaboration_Policy_State :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Policy_Normal;
      Base_Elaboration_Status : Elaboration_Legality_Status :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked;
      Generic_Status          : Generic_Body_Expansion_Status :=
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Not_Checked;
      Dataflow_Status         : Dataflow_Legality_Status :=
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Not_Checked;
      Preference_Status       : Preference_Legality_Status :=
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Not_Checked;
      Accessibility_Status    : Accessibility_Precision_Status :=
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Not_Checked;
      Requires_Elaborate_All  : Boolean := False;
      Has_Elaborate_All       : Boolean := False;
      Requires_Elaborate_Body : Boolean := False;
      Has_Elaborate_Body      : Boolean := False;
      Body_Required           : Boolean := False;
      Body_Elaborated         : Boolean := True;
      Call_During_Elaboration : Boolean := False;
      Access_During_Elaboration : Boolean := False;
      Generic_Instance        : Boolean := False;
      Generic_Body_Elaborated : Boolean := True;
      Graph_Edge_Missing      : Boolean := False;
      Graph_Edge_Ambiguous    : Boolean := False;
      Graph_Cycle             : Boolean := False;
      Illegal_Preelaborate_Call : Boolean := False;
      Illegal_Preelaborate_Object : Boolean := False;
      Illegal_Pure_State      : Boolean := False;
      Illegal_Pure_Dependency : Boolean := False;
      Illegal_Remote_Types_Dependency : Boolean := False;
      Illegal_Shared_Passive_Dependency : Boolean := False;
      Start_Line              : Positive := 1;
      Start_Column            : Positive := 1;
      End_Line                : Positive := 1;
      End_Column              : Positive := 1;
      Source_Fingerprint      : Natural := 0;
   end record;

   type Elaboration_Precision_Legality_Info is record
      Id                      : Elaboration_Precision_Legality_Id := No_Elaboration_Precision_Legality;
      Context                 : Elaboration_Precision_Context_Id := No_Elaboration_Precision_Context;
      Kind                    : Elaboration_Precision_Context_Kind := Elaboration_Precision_Context_Unknown;
      Node                    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                  : Elaboration_Precision_Status := Elaboration_Precision_Not_Checked;
      Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Message                 : Ada.Strings.Unbounded.Unbounded_String;
      Detail                  : Ada.Strings.Unbounded.Unbounded_String;
      Order_State             : Elaboration_Order_State :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Order_Unknown;
      Policy_State            : Elaboration_Policy_State :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Policy_Normal;
      Base_Elaboration_Status : Elaboration_Legality_Status :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked;
      Generic_Status          : Generic_Body_Expansion_Status :=
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Not_Checked;
      Dataflow_Status         : Dataflow_Legality_Status :=
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Not_Checked;
      Preference_Status       : Preference_Legality_Status :=
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Not_Checked;
      Accessibility_Status    : Accessibility_Precision_Status :=
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Not_Checked;
      Start_Line              : Positive := 1;
      Start_Column            : Positive := 1;
      End_Line                : Positive := 1;
      End_Column              : Positive := 1;
      Source_Fingerprint      : Natural := 0;
      Fingerprint             : Natural := 0;
   end record;

   type Elaboration_Precision_Context_Model is private;
   type Elaboration_Precision_Result_Set is private;
   type Elaboration_Precision_Legality_Model is private;

   procedure Clear (Model : in out Elaboration_Precision_Context_Model);
   procedure Add_Context
     (Model : in out Elaboration_Precision_Context_Model;
      Info  : Elaboration_Precision_Context_Info);

   function Context_Count (Model : Elaboration_Precision_Context_Model) return Natural;
   function Context_At
     (Model : Elaboration_Precision_Context_Model;
      Index : Positive) return Elaboration_Precision_Context_Info;
   function Fingerprint (Model : Elaboration_Precision_Context_Model) return Natural;

   function Build
     (Contexts : Elaboration_Precision_Context_Model) return Elaboration_Precision_Legality_Model;

   function Legality_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Legality_At
     (Model : Elaboration_Precision_Legality_Model;
      Index : Positive) return Elaboration_Precision_Legality_Info;

   function First_For_Node
     (Model : Elaboration_Precision_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Precision_Legality_Info;
   function Rows_For_Status
     (Model  : Elaboration_Precision_Legality_Model;
      Status : Elaboration_Precision_Status) return Elaboration_Precision_Result_Set;
   function Rows_For_Kind
     (Model : Elaboration_Precision_Legality_Model;
      Kind  : Elaboration_Precision_Context_Kind) return Elaboration_Precision_Result_Set;
   function Rows_For_Unit
     (Model : Elaboration_Precision_Legality_Model;
      Name  : String) return Elaboration_Precision_Result_Set;

   function Result_Count (Results : Elaboration_Precision_Result_Set) return Natural;
   function Result_At
     (Results : Elaboration_Precision_Result_Set;
      Index   : Positive) return Elaboration_Precision_Legality_Info;

   function Count_Status
     (Model  : Elaboration_Precision_Legality_Model;
      Status : Elaboration_Precision_Status) return Natural;
   function Count_Kind
     (Model : Elaboration_Precision_Legality_Model;
      Kind  : Elaboration_Precision_Context_Kind) return Natural;

   function Legal_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Graph_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Policy_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Generic_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Dataflow_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Call_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Accessibility_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Elaboration_Precision_Legality_Model) return Natural;
   function Fingerprint (Model : Elaboration_Precision_Legality_Model) return Natural;

   function Has_Legality (Info : Elaboration_Precision_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_Precision_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_Precision_Legality_Info);

   type Elaboration_Precision_Context_Model is record
      Rows        : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Elaboration_Precision_Result_Set is record
      Rows : Legality_Vectors.Vector;
   end record;

   type Elaboration_Precision_Legality_Model is record
      Rows        : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Elaboration_Precision_Legality;
