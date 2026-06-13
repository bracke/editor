with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Elaboration_Dependence_Legality is

   --  Pass1113 compiler-grade elaboration/dependence legality layer.
   --  This package models Ada elaboration-order and semantic dependence
   --  legality for snapshot-owned analysis.  It is intentionally parser-free
   --  and projection-free: callers provide bounded semantic contexts derived
   --  from immutable snapshots, and this package classifies elaboration risks,
   --  pragma/aspect effects, body-before-use requirements, circularity, and
   --  linked legality blockers from existing semantic layers.

   subtype Cross_Unit_Semantic_Status is
     Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Status;
   subtype Contract_Legality_Status is
     Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Status;
   subtype Overload_Legality_Status is
     Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status;

   type Elaboration_Context_Id is new Natural;
   No_Elaboration_Context : constant Elaboration_Context_Id := 0;

   type Elaboration_Legality_Id is new Natural;
   No_Elaboration_Legality : constant Elaboration_Legality_Id := 0;

   type Elaboration_Context_Kind is
     (Elaboration_Context_With_Dependency,
      Elaboration_Context_Elaborate_Pragma,
      Elaboration_Context_Elaborate_All_Pragma,
      Elaboration_Context_Elaborate_Body_Pragma,
      Elaboration_Context_Preelaborate_Unit,
      Elaboration_Context_Pure_Unit,
      Elaboration_Context_Remote_Types_Unit,
      Elaboration_Context_Shared_Passive_Unit,
      Elaboration_Context_Call_During_Elaboration,
      Elaboration_Context_Access_Before_Elaboration,
      Elaboration_Context_Generic_Instance,
      Elaboration_Context_Body_Before_Use,
      Elaboration_Context_Circular_Dependence,
      Elaboration_Context_Library_Level_Object,
      Elaboration_Context_Unknown);

   type Elaboration_Dependence_Kind is
     (Elaboration_Dependence_None,
      Elaboration_Dependence_With,
      Elaboration_Dependence_Use,
      Elaboration_Dependence_Body,
      Elaboration_Dependence_Subprogram_Call,
      Elaboration_Dependence_Dispatching_Call,
      Elaboration_Dependence_Generic_Instance,
      Elaboration_Dependence_Default_Expression,
      Elaboration_Dependence_Aspect_Expression,
      Elaboration_Dependence_Representation_Item,
      Elaboration_Dependence_Unknown);

   type Elaboration_Pragma_State is
     (Elaboration_Pragma_None,
      Elaboration_Pragma_Elaborate,
      Elaboration_Pragma_Elaborate_All,
      Elaboration_Pragma_Elaborate_Body,
      Elaboration_Pragma_Preelaborate,
      Elaboration_Pragma_Pure,
      Elaboration_Pragma_Remote_Types,
      Elaboration_Pragma_Shared_Passive,
      Elaboration_Pragma_Duplicate,
      Elaboration_Pragma_Conflicting,
      Elaboration_Pragma_Unresolved);

   type Elaboration_Order_State is
     (Elaboration_Order_Known_Before,
      Elaboration_Order_Known_After,
      Elaboration_Order_Same_Unit,
      Elaboration_Order_Circular,
      Elaboration_Order_Missing_Dependency,
      Elaboration_Order_Ambiguous_Dependency,
      Elaboration_Order_Unknown);

   type Elaboration_Policy_State is
     (Elaboration_Policy_Normal,
      Elaboration_Policy_Preelaborated,
      Elaboration_Policy_Pure,
      Elaboration_Policy_Remote_Types,
      Elaboration_Policy_Shared_Passive,
      Elaboration_Policy_Unresolved);

   type Elaboration_Legality_Status is
     (Elaboration_Legality_Not_Checked,
      Elaboration_Legality_Legal_Dependency,
      Elaboration_Legality_Legal_Elaborate_Pragma,
      Elaboration_Legality_Legal_Elaborate_All_Pragma,
      Elaboration_Legality_Legal_Elaborate_Body_Pragma,
      Elaboration_Legality_Legal_Preelaborate,
      Elaboration_Legality_Legal_Pure,
      Elaboration_Legality_Legal_Body_Before_Use,
      Elaboration_Legality_Legal_Generic_Instance,
      Elaboration_Legality_Call_Before_Body_Elaboration,
      Elaboration_Legality_Access_Before_Elaboration,
      Elaboration_Legality_Missing_Elaborate_All,
      Elaboration_Legality_Missing_Elaborate_Body,
      Elaboration_Legality_Duplicate_Pragma,
      Elaboration_Legality_Conflicting_Pragma,
      Elaboration_Legality_Pragma_Target_Unresolved,
      Elaboration_Legality_Pragma_Target_Ambiguous,
      Elaboration_Legality_Circular_Elaboration_Dependence,
      Elaboration_Legality_Missing_Dependency,
      Elaboration_Legality_Ambiguous_Dependency,
      Elaboration_Legality_Preelaborate_Illegal_Construct,
      Elaboration_Legality_Pure_Illegal_State,
      Elaboration_Legality_Remote_Types_Illegal_Dependency,
      Elaboration_Legality_Shared_Passive_Illegal_Dependency,
      Elaboration_Legality_Body_Required_But_Missing,
      Elaboration_Legality_Generic_Instance_Body_Not_Elaborated,
      Elaboration_Legality_Linked_Cross_Unit_Error,
      Elaboration_Legality_Linked_Contract_Error,
      Elaboration_Legality_Linked_Overload_Error,
      Elaboration_Legality_Indeterminate);

   type Elaboration_Context_Info is record
      Id                    : Elaboration_Context_Id := No_Elaboration_Context;
      Kind                  : Elaboration_Context_Kind := Elaboration_Context_Unknown;
      Dependence            : Elaboration_Dependence_Kind := Elaboration_Dependence_Unknown;
      Pragma_State          : Elaboration_Pragma_State := Elaboration_Pragma_None;
      Order_State           : Elaboration_Order_State := Elaboration_Order_Unknown;
      Policy_State          : Elaboration_Policy_State := Elaboration_Policy_Normal;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Call_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Requires_Elaborate_All : Boolean := False;
      Has_Elaborate_All     : Boolean := False;
      Requires_Body         : Boolean := False;
      Body_Available        : Boolean := True;
      Call_During_Elaboration : Boolean := False;
      Access_During_Elaboration : Boolean := False;
      Duplicate_Pragma      : Boolean := False;
      Conflicting_Pragma    : Boolean := False;
      Illegal_Preelaborate_Construct : Boolean := False;
      Illegal_Pure_State    : Boolean := False;
      Illegal_Remote_Types_Dependency : Boolean := False;
      Illegal_Shared_Passive_Dependency : Boolean := False;
      Cross_Unit_Status     : Cross_Unit_Semantic_Status :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked;
      Contract_Status       : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Overload_Status       : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Elaboration_Legality_Info is record
      Id                    : Elaboration_Legality_Id := No_Elaboration_Legality;
      Context               : Elaboration_Context_Id := No_Elaboration_Context;
      Kind                  : Elaboration_Context_Kind := Elaboration_Context_Unknown;
      Dependence            : Elaboration_Dependence_Kind := Elaboration_Dependence_Unknown;
      Pragma_State          : Elaboration_Pragma_State := Elaboration_Pragma_None;
      Order_State           : Elaboration_Order_State := Elaboration_Order_Unknown;
      Policy_State          : Elaboration_Policy_State := Elaboration_Policy_Normal;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                : Elaboration_Legality_Status := Elaboration_Legality_Not_Checked;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Status     : Cross_Unit_Semantic_Status :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked;
      Contract_Status       : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Overload_Status       : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Elaboration_Context_Model is private;
   type Elaboration_Result_Set is private;
   type Elaboration_Legality_Model is private;

   procedure Clear (Model : in out Elaboration_Context_Model);
   procedure Add_Context
     (Model : in out Elaboration_Context_Model;
      Info  : Elaboration_Context_Info);

   function Context_Count (Model : Elaboration_Context_Model) return Natural;
   function Context_At
     (Model : Elaboration_Context_Model;
      Index : Positive) return Elaboration_Context_Info;
   function Fingerprint (Model : Elaboration_Context_Model) return Natural;

   function Build (Contexts : Elaboration_Context_Model) return Elaboration_Legality_Model;

   function Legality_Count (Model : Elaboration_Legality_Model) return Natural;
   function Legality_At
     (Model : Elaboration_Legality_Model;
      Index : Positive) return Elaboration_Legality_Info;

   function First_For_Node
     (Model : Elaboration_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Legality_Info;
   function Rows_For_Status
     (Model  : Elaboration_Legality_Model;
      Status : Elaboration_Legality_Status) return Elaboration_Result_Set;
   function Rows_For_Kind
     (Model : Elaboration_Legality_Model;
      Kind  : Elaboration_Context_Kind) return Elaboration_Result_Set;
   function Rows_For_Dependence
     (Model      : Elaboration_Legality_Model;
      Dependence : Elaboration_Dependence_Kind) return Elaboration_Result_Set;
   function Rows_For_Pragma_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Pragma_State) return Elaboration_Result_Set;
   function Rows_For_Order_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Order_State) return Elaboration_Result_Set;
   function Rows_For_Policy_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Policy_State) return Elaboration_Result_Set;

   function Result_Count (Results : Elaboration_Result_Set) return Natural;
   function Result_At
     (Results : Elaboration_Result_Set;
      Index   : Positive) return Elaboration_Legality_Info;

   function Count_Status
     (Model  : Elaboration_Legality_Model;
      Status : Elaboration_Legality_Status) return Natural;
   function Count_Kind
     (Model : Elaboration_Legality_Model;
      Kind  : Elaboration_Context_Kind) return Natural;
   function Count_Dependence
     (Model      : Elaboration_Legality_Model;
      Dependence : Elaboration_Dependence_Kind) return Natural;
   function Count_Pragma_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Pragma_State) return Natural;
   function Count_Order_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Order_State) return Natural;
   function Count_Policy_State
     (Model : Elaboration_Legality_Model;
      State : Elaboration_Policy_State) return Natural;

   function Legal_Count (Model : Elaboration_Legality_Model) return Natural;
   function Error_Count (Model : Elaboration_Legality_Model) return Natural;
   function Pragma_Error_Count (Model : Elaboration_Legality_Model) return Natural;
   function Order_Error_Count (Model : Elaboration_Legality_Model) return Natural;
   function Policy_Error_Count (Model : Elaboration_Legality_Model) return Natural;
   function Body_Error_Count (Model : Elaboration_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Elaboration_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Elaboration_Legality_Model) return Natural;
   function Fingerprint (Model : Elaboration_Legality_Model) return Natural;

   function Has_Legality (Info : Elaboration_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_Legality_Info);

   type Elaboration_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Elaboration_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Elaboration_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Pragma_Error_Total : Natural := 0;
      Order_Error_Total : Natural := 0;
      Policy_Error_Total : Natural := 0;
      Body_Error_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Elaboration_Dependence_Legality;
