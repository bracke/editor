with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality is

   --  Case 1190 compiler-grade nested generic replay closure legality.
   --
   --  This layer closes the remaining cross-unit generic replay gap left after
   --  source/instance backmapping and final RM overload consumers.  A nested
   --  generic replay conclusion is accepted only when the generic source/instance
   --  backmap, final overload/type consumer evidence, cross-unit dependency state,
   --  and cycle bookkeeping all agree.  Recursive or nested instantiation cycles
   --  are preserved as first-class blockers instead of being flattened into an
   --  indeterminate generic replay diagnostic.

   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   package Final_RM renames Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
   package Cross_Final renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;

   type Nested_Generic_Closure_Row_Id is new Natural;
   No_Nested_Generic_Closure_Row : constant Nested_Generic_Closure_Row_Id := 0;

   type Nested_Generic_Closure_Kind is
     (Nested_Generic_Local_Instance,
      Nested_Generic_Cross_Unit_Instance,
      Nested_Generic_Child_Instance,
      Nested_Generic_Private_Child_Instance,
      Nested_Generic_Formal_Package_Instance,
      Nested_Generic_Nested_Instance,
      Nested_Generic_Body_Replay,
      Nested_Generic_Subprogram_Replay,
      Nested_Generic_Representation_Replay,
      Nested_Generic_Task_Protected_Replay,
      Nested_Generic_Unknown);

   type Nested_Generic_Closure_Status is
     (Nested_Generic_Not_Checked,
      Nested_Generic_Legal_Local_Instance_Closed,
      Nested_Generic_Legal_Cross_Unit_Instance_Closed,
      Nested_Generic_Legal_Child_Instance_Closed,
      Nested_Generic_Legal_Private_Child_Instance_Closed,
      Nested_Generic_Legal_Formal_Package_Instance_Closed,
      Nested_Generic_Legal_Nested_Instance_Closed,
      Nested_Generic_Legal_Body_Replay_Closed,
      Nested_Generic_Legal_Subprogram_Replay_Closed,
      Nested_Generic_Legal_Representation_Replay_Closed,
      Nested_Generic_Legal_Task_Protected_Replay_Closed,
      Nested_Generic_Missing_Generic_Backmap,
      Nested_Generic_Backmap_Blocker,
      Nested_Generic_Backmap_Mapping_Blocker,
      Nested_Generic_Backmap_Overload_Blocker,
      Nested_Generic_Backmap_Indeterminate,
      Nested_Generic_Missing_Final_RM_Consumer,
      Nested_Generic_Final_RM_Blocker,
      Nested_Generic_Final_RM_Ambiguous,
      Nested_Generic_Final_RM_Indeterminate,
      Nested_Generic_Missing_Cross_Unit_Final_Closure,
      Nested_Generic_Cross_Unit_Dependency_Blocker,
      Nested_Generic_Private_View_Barrier,
      Nested_Generic_Limited_View_Barrier,
      Nested_Generic_Child_Visibility_Blocker,
      Nested_Generic_Generic_Body_Unavailable,
      Nested_Generic_Source_Instance_Fingerprint_Mismatch,
      Nested_Generic_Substitution_Fingerprint_Mismatch,
      Nested_Generic_Nested_Dependency_Cycle,
      Nested_Generic_Recursive_Instantiation_Cycle,
      Nested_Generic_Cycle_Depth_Overflow,
      Nested_Generic_Dependency_Overflow,
      Nested_Generic_Stale_Dependency,
      Nested_Generic_Multiple_Blockers,
      Nested_Generic_Indeterminate);

   type Nested_Generic_Closure_Context_Info is record
      Id                         : Nested_Generic_Closure_Row_Id := No_Nested_Generic_Closure_Row;
      Kind                       : Nested_Generic_Closure_Kind := Nested_Generic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Instance_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Backmap_Row                : Backmap.Generic_Backmap_Row_Id := Backmap.No_Generic_Backmap_Row;
      Backmap_Status             : Backmap.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Final_RM_Row               : Final_RM.Final_RM_Row_Id := Final_RM.No_Final_RM_Row;
      Final_RM_Status            : Final_RM.Final_RM_Status := Final_RM.Final_RM_Not_Checked;
      Cross_Unit_Row             : Cross_Final.Cross_Unit_Final_Row_Id := Cross_Final.No_Cross_Unit_Final_Row;
      Cross_Unit_Status          : Cross_Final.Cross_Unit_Final_Status := Cross_Final.Cross_Unit_Final_Not_Checked;
      Requires_Cross_Unit        : Boolean := False;
      Requires_Final_RM          : Boolean := False;
      Generic_Body_Available     : Boolean := True;
      Private_View_Barrier       : Boolean := False;
      Limited_View_Barrier       : Boolean := False;
      Child_Visibility_Blocked   : Boolean := False;
      Nested_Dependency_Cycle    : Boolean := False;
      Recursive_Instantiation_Cycle : Boolean := False;
      Cycle_Depth                : Natural := 0;
      Max_Cycle_Depth            : Natural := 32;
      Dependency_Count           : Natural := 0;
      Max_Dependency_Count       : Natural := 128;
      Stale_Dependency           : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Nested_Generic_Closure_Info is record
      Id                         : Nested_Generic_Closure_Row_Id := No_Nested_Generic_Closure_Row;
      Context                    : Nested_Generic_Closure_Row_Id := No_Nested_Generic_Closure_Row;
      Kind                       : Nested_Generic_Closure_Kind := Nested_Generic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                     : Nested_Generic_Closure_Status := Nested_Generic_Not_Checked;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Instance_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Backmap_Row                : Backmap.Generic_Backmap_Row_Id := Backmap.No_Generic_Backmap_Row;
      Backmap_Status             : Backmap.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Final_RM_Row               : Final_RM.Final_RM_Row_Id := Final_RM.No_Final_RM_Row;
      Final_RM_Status            : Final_RM.Final_RM_Status := Final_RM.Final_RM_Not_Checked;
      Cross_Unit_Row             : Cross_Final.Cross_Unit_Final_Row_Id := Cross_Final.No_Cross_Unit_Final_Row;
      Cross_Unit_Status          : Cross_Final.Cross_Unit_Final_Status := Cross_Final.Cross_Unit_Final_Not_Checked;
      Blocker_Count              : Natural := 0;
      Cycle_Depth                : Natural := 0;
      Dependency_Count           : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Nested_Generic_Closure_Context_Model is private;
   type Nested_Generic_Closure_Model is private;
   type Nested_Generic_Closure_Result_Set is private;

   procedure Clear (Model : in out Nested_Generic_Closure_Context_Model);
   procedure Add_Context
     (Model : in out Nested_Generic_Closure_Context_Model;
      Info  : Nested_Generic_Closure_Context_Info);

   function Context_Count (Model : Nested_Generic_Closure_Context_Model) return Natural;
   function Context_At
     (Model : Nested_Generic_Closure_Context_Model;
      Index : Positive) return Nested_Generic_Closure_Context_Info;
   function Fingerprint (Model : Nested_Generic_Closure_Context_Model) return Natural;

   function Build (Contexts : Nested_Generic_Closure_Context_Model) return Nested_Generic_Closure_Model;

   function Row_Count (Model : Nested_Generic_Closure_Model) return Natural;
   function Row_At
     (Model : Nested_Generic_Closure_Model;
      Index : Positive) return Nested_Generic_Closure_Info;
   function First_For_Node
     (Model : Nested_Generic_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Nested_Generic_Closure_Info;
   function Rows_For_Status
     (Model  : Nested_Generic_Closure_Model;
      Status : Nested_Generic_Closure_Status) return Nested_Generic_Closure_Result_Set;
   function Rows_For_Kind
     (Model : Nested_Generic_Closure_Model;
      Kind  : Nested_Generic_Closure_Kind) return Nested_Generic_Closure_Result_Set;
   function Rows_For_Instance
     (Model         : Nested_Generic_Closure_Model;
      Instance_Name : String) return Nested_Generic_Closure_Result_Set;

   function Result_Count (Results : Nested_Generic_Closure_Result_Set) return Natural;
   function Result_At
     (Results : Nested_Generic_Closure_Result_Set;
      Index   : Positive) return Nested_Generic_Closure_Info;

   function Count_Status
     (Model  : Nested_Generic_Closure_Model;
      Status : Nested_Generic_Closure_Status) return Natural;
   function Count_Kind
     (Model : Nested_Generic_Closure_Model;
      Kind  : Nested_Generic_Closure_Kind) return Natural;

   function Legal_Count (Model : Nested_Generic_Closure_Model) return Natural;
   function Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural;
   function Cycle_Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural;
   function Cross_Unit_Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural;
   function Backmap_Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural;
   function Final_RM_Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural;
   function Indeterminate_Count (Model : Nested_Generic_Closure_Model) return Natural;
   function Fingerprint (Model : Nested_Generic_Closure_Model) return Natural;

   function Is_Legal (Status : Nested_Generic_Closure_Status) return Boolean;
   function Is_Cycle_Blocker (Status : Nested_Generic_Closure_Status) return Boolean;
   function Has_Error (Info : Nested_Generic_Closure_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Nested_Generic_Closure_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Nested_Generic_Closure_Info);

   type Nested_Generic_Closure_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Nested_Generic_Closure_Result_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Nested_Generic_Closure_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Blocker_Total : Natural := 0;
      Cycle_Blocker_Total : Natural := 0;
      Cross_Unit_Blocker_Total : Natural := 0;
      Backmap_Blocker_Total : Natural := 0;
      Final_RM_Blocker_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
