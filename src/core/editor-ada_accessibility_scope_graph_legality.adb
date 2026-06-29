with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Accessibility_Scope_Graph_Legality is

   pragma Suppress (Overflow_Check);

   package Precision renames Editor.Ada_Accessibility_Precision_Legality;
   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   package Discriminants renames Editor.Ada_Discriminant_Dependent_Legality;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Precision.Accessibility_Precision_Status;
   use type Replay.Replay_Status;
   use type Discriminants.Discriminant_Legality_Status;
   use type Gates.Enforcement_Status;
   use type Scope_Level;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 313) + (B * 59) + 1143) mod 1_000_000_007;
   end Mix;

   function Lower (S : String) return String is
      R : String := S;
   begin
      for I in R'Range loop
         R (I) := Ada.Characters.Handling.To_Lower (R (I));
      end loop;
      return R;
   end Lower;

   function Kind_Slot (Kind : Scope_Context_Kind) return Natural is
   begin
      return Scope_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Scope_Legality_Status) return Natural is
   begin
      return Scope_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Level_Slot (Level : Scope_Level) return Natural is
   begin
      return Natural (Level) + 1;
   end Level_Slot;

   function Level_Known (Level : Scope_Level) return Boolean is
   begin
      return Level /= Unknown_Scope_Level;
   end Level_Known;

   function Level_Compatible (Source_Level, Target_Level : Scope_Level) return Boolean is
   begin
      return Level_Known (Source_Level)
        and then Level_Known (Target_Level)
        and then Natural (Source_Level) <= Natural (Target_Level);
   end Level_Compatible;

   function Gate_Is_Blocker (Status : Gates.Enforcement_Status) return Boolean is
   begin
      return Status in
        Gates.Enforcement_Degraded_To_Indeterminate |
        Gates.Enforcement_Cross_Unit_Closure_Required |
        Gates.Enforcement_Legal_Result_Suppressed |
        Gates.Enforcement_Derived_Result_Suppressed |
        Gates.Enforcement_Parser_AST_Blocker |
        Gates.Enforcement_Metadata_Blocker |
        Gates.Enforcement_Consumer_Integration_Blocker |
        Gates.Enforcement_Unsafe_Result_Blocked;
   end Gate_Is_Blocker;

   function Precision_Is_Error (Status : Precision.Accessibility_Precision_Status) return Boolean is
   begin
      return Status in
        Precision.Accessibility_Precision_Anonymous_Access_Level_Too_Deep |
        Precision.Accessibility_Precision_Anonymous_Access_Level_Unresolved |
        Precision.Accessibility_Precision_Access_Parameter_Escapes |
        Precision.Accessibility_Precision_Allocator_Master_Too_Short |
        Precision.Accessibility_Precision_Allocator_Designated_Subtype_Mismatch |
        Precision.Accessibility_Precision_Return_Access_Too_Short_Lived |
        Precision.Accessibility_Precision_Return_Object_Too_Short_Lived |
        Precision.Accessibility_Precision_Access_Discriminant_Too_Short_Lived |
        Precision.Accessibility_Precision_Access_Discriminant_Unresolved |
        Precision.Accessibility_Precision_Access_Conversion_Level_Too_Deep |
        Precision.Accessibility_Precision_Renaming_Dangling_Risk |
        Precision.Accessibility_Precision_Generic_Actual_Too_Short_Lived |
        Precision.Accessibility_Precision_Generic_Actual_Unresolved |
        Precision.Accessibility_Precision_Aggregate_Discriminant_Lifetime_Error |
        Precision.Accessibility_Precision_Aggregate_Discriminant_Unresolved |
        Precision.Accessibility_Precision_Private_View_Barrier |
        Precision.Accessibility_Precision_Limited_View_Barrier |
        Precision.Accessibility_Precision_Cross_Unit_Unresolved_View |
        Precision.Accessibility_Precision_Linked_Accessibility_Error |
        Precision.Accessibility_Precision_Linked_Generic_Body_Error |
        Precision.Accessibility_Precision_Linked_Record_Aggregate_Error |
        Precision.Accessibility_Precision_Indeterminate;
   end Precision_Is_Error;

   function Replay_Is_Error (Status : Replay.Replay_Status) return Boolean is
   begin
      return Status in
        Replay.Replay_Generic_Expansion_Error |
        Replay.Replay_Overload_Preference_Error |
        Replay.Replay_Flow_Effect_Error |
        Replay.Replay_Predicate_Propagation_Error |
        Replay.Replay_Accessibility_Precision_Error |
        Replay.Replay_Representation_Freezing_Error |
        Replay.Replay_Coverage_Gate_Blocker |
        Replay.Replay_Source_Instance_Mapping_Missing |
        Replay.Replay_Formal_Actual_Mapping_Missing |
        Replay.Replay_Diagnostic_Backmap_Missing |
        Replay.Replay_Multiple_Blockers |
        Replay.Replay_Indeterminate;
   end Replay_Is_Error;

   function Discriminant_Is_Error (Status : Discriminants.Discriminant_Legality_Status) return Boolean is
   begin
      return Status in
        Discriminants.Discriminant_Legality_Missing_Discriminant_Constraint |
        Discriminants.Discriminant_Legality_Duplicate_Discriminant_Constraint |
        Discriminants.Discriminant_Legality_Discriminant_Type_Mismatch |
        Discriminants.Discriminant_Legality_Default_Not_Static |
        Discriminants.Discriminant_Legality_Default_Out_Of_Range |
        Discriminants.Discriminant_Legality_Default_Depends_On_Later_Discriminant |
        Discriminants.Discriminant_Legality_Unconstrained_Record_Without_Defaults |
        Discriminants.Discriminant_Legality_Constrained_Object_Discriminant_Changed |
        Discriminants.Discriminant_Legality_Assignment_Discriminant_Mismatch |
        Discriminants.Discriminant_Legality_Conversion_Discriminant_Mismatch |
        Discriminants.Discriminant_Legality_Return_Discriminant_Mismatch |
        Discriminants.Discriminant_Legality_Allocator_Discriminant_Mismatch |
        Discriminants.Discriminant_Legality_Generic_Actual_Discriminant_Mismatch |
        Discriminants.Discriminant_Legality_Variant_Missing_For_Value |
        Discriminants.Discriminant_Legality_Variant_Forbidden_For_Value |
        Discriminants.Discriminant_Legality_Variant_Choice_Overlap |
        Discriminants.Discriminant_Legality_Variant_Choice_Coverage_Gap |
        Discriminants.Discriminant_Legality_Linked_Record_Aggregate_Error |
        Discriminants.Discriminant_Legality_Linked_Assignment_Error |
        Discriminants.Discriminant_Legality_Linked_Conversion_Error |
        Discriminants.Discriminant_Legality_Linked_Return_Error |
        Discriminants.Discriminant_Legality_Linked_Generic_Replay_Error |
        Discriminants.Discriminant_Legality_Private_Full_View_Mismatch |
        Discriminants.Discriminant_Legality_Coverage_Gate_Blocker |
        Discriminants.Discriminant_Legality_Multiple_Blockers |
        Discriminants.Discriminant_Legality_Indeterminate;
   end Discriminant_Is_Error;

   function Is_Legal (Status : Scope_Legality_Status) return Boolean is
   begin
      return Status in
        Scope_Legality_Legal_Master_Hierarchy |
        Scope_Legality_Legal_Static_Level |
        Scope_Legality_Legal_Dynamic_Check |
        Scope_Legality_Legal_Allocator_Master |
        Scope_Legality_Legal_Return_Object_Master |
        Scope_Legality_Legal_Return_Access_Master |
        Scope_Legality_Legal_Access_Discriminant_Master |
        Scope_Legality_Legal_Access_Conversion |
        Scope_Legality_Legal_Generic_Substitution |
        Scope_Legality_Legal_Discriminant_Aggregate;
   end Is_Legal;

   function Context_Fingerprint (Info : Scope_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Level_Slot (Info.Source_Level));
      H := Mix (H, Level_Slot (Info.Target_Level));
      H := Mix (H, Level_Slot (Info.Master_Level));
      H := Mix (H, Level_Slot (Info.Required_Master_Level));
      H := Mix (H, Level_Slot (Info.Return_Master_Level));
      H := Mix (H, Level_Slot (Info.Allocator_Master_Level));
      H := Mix (H, Level_Slot (Info.Designated_Object_Level));
      H := Mix (H, Level_Slot (Info.Parent_Master_Level));
      H := Mix (H, Natural (Boolean'Pos (Info.Has_Master)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Static_Level)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Dynamic_Check)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Anonymous_Access_Parameter)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Access_Parameter_Escapes)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Allocator_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Return_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Access_Discriminant_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Generic_Substitution_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Discriminant_Aggregate_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Finalization_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Designated_Subtype_Mismatch)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Finalization_Uses_Expired_Master)) + 1);
      H := Mix (H, Precision.Accessibility_Precision_Status'Pos (Info.Precision_Status) + 1);
      H := Mix (H, Replay.Replay_Status'Pos (Info.Replay_Status) + 1);
      H := Mix (H, Discriminants.Discriminant_Legality_Status'Pos (Info.Discriminant_Status) + 1);
      H := Mix (H, Gates.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Scope_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Level_Slot (Info.Source_Level));
      H := Mix (H, Level_Slot (Info.Target_Level));
      H := Mix (H, Level_Slot (Info.Master_Level));
      H := Mix (H, Level_Slot (Info.Required_Master_Level));
      H := Mix (H, Info.Blocker_Count + 1);
      H := Mix (H, Precision.Accessibility_Precision_Status'Pos (Info.Precision_Status) + 1);
      H := Mix (H, Replay.Replay_Status'Pos (Info.Replay_Status) + 1);
      H := Mix (H, Discriminants.Discriminant_Legality_Status'Pos (Info.Discriminant_Status) + 1);
      H := Mix (H, Gates.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Choose_Status (Info : Scope_Context_Info; Blockers : Natural) return Scope_Legality_Status is
   begin
      if Blockers > 1 then
         return Scope_Legality_Multiple_Blockers;
      elsif Gate_Is_Blocker (Info.Gate_Status) then
         return Scope_Legality_Coverage_Gate_Blocker;
      elsif Precision_Is_Error (Info.Precision_Status) then
         return Scope_Legality_Linked_Accessibility_Precision_Error;
      elsif Replay_Is_Error (Info.Replay_Status) then
         return Scope_Legality_Linked_Generic_Replay_Error;
      elsif Discriminant_Is_Error (Info.Discriminant_Status) then
         return Scope_Legality_Linked_Discriminant_Error;
      elsif not Info.Has_Master and then Info.Kind /= Scope_Context_Unknown then
         return Scope_Legality_Missing_Master;
      elsif Info.Finalization_Uses_Expired_Master then
         return Scope_Legality_Finalization_Uses_Expired_Master;
      elsif Info.Designated_Subtype_Mismatch then
         return Scope_Legality_Allocator_Designated_Subtype_Mismatch;
      elsif Info.Access_Parameter_Escapes then
         return Scope_Legality_Access_Parameter_Escapes;
      elsif Info.Requires_Static_Level and then not Level_Known (Info.Source_Level) then
         return Scope_Legality_Anonymous_Access_Level_Unresolved;
      elsif Info.Requires_Static_Level and then not Level_Compatible (Info.Source_Level, Info.Target_Level) then
         if Info.Anonymous_Access_Parameter then
            return Scope_Legality_Anonymous_Access_Level_Too_Deep;
         elsif Info.Return_Context and then Info.Kind = Scope_Context_Return_Object then
            return Scope_Legality_Return_Object_Master_Too_Short;
         elsif Info.Return_Context then
            return Scope_Legality_Return_Access_Master_Too_Short;
         elsif Info.Access_Discriminant_Context then
            return Scope_Legality_Access_Discriminant_Master_Too_Short;
         elsif Info.Allocator_Context then
            return Scope_Legality_Allocator_Master_Too_Short;
         elsif Info.Generic_Substitution_Context then
            return Scope_Legality_Generic_Substitution_Master_Mismatch;
         else
            return Scope_Legality_Static_Level_Too_Deep;
         end if;
      elsif Info.Requires_Dynamic_Check and then
        (not Level_Known (Info.Source_Level) or else not Level_Known (Info.Target_Level))
      then
         return Scope_Legality_Dynamic_Level_Unresolved;
      elsif Info.Allocator_Context and then not Level_Known (Info.Allocator_Master_Level) then
         return Scope_Legality_Allocator_Master_Unresolved;
      elsif Info.Return_Context and then not Level_Known (Info.Return_Master_Level) then
         return Scope_Legality_Return_Master_Unresolved;
      elsif Info.Access_Discriminant_Context and then not Level_Known (Info.Required_Master_Level) then
         return Scope_Legality_Access_Discriminant_Master_Unresolved;
      elsif Info.Finalization_Context and then not Level_Known (Info.Master_Level) then
         return Scope_Legality_Finalization_Master_Unresolved;
      elsif Info.Kind = Scope_Context_Master or else Info.Kind = Scope_Context_Nested_Scope then
         return Scope_Legality_Legal_Master_Hierarchy;
      elsif Info.Allocator_Context then
         return Scope_Legality_Legal_Allocator_Master;
      elsif Info.Return_Context and then Info.Kind = Scope_Context_Return_Object then
         return Scope_Legality_Legal_Return_Object_Master;
      elsif Info.Return_Context then
         return Scope_Legality_Legal_Return_Access_Master;
      elsif Info.Access_Discriminant_Context then
         return Scope_Legality_Legal_Access_Discriminant_Master;
      elsif Info.Kind = Scope_Context_Access_Conversion then
         return Scope_Legality_Legal_Access_Conversion;
      elsif Info.Generic_Substitution_Context then
         return Scope_Legality_Legal_Generic_Substitution;
      elsif Info.Discriminant_Aggregate_Context then
         return Scope_Legality_Legal_Discriminant_Aggregate;
      elsif Info.Requires_Dynamic_Check then
         return Scope_Legality_Legal_Dynamic_Check;
      elsif Info.Requires_Static_Level then
         return Scope_Legality_Legal_Static_Level;
      else
         return Scope_Legality_Indeterminate;
      end if;
   end Choose_Status;

   function Blocker_Count (Info : Scope_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if Gate_Is_Blocker (Info.Gate_Status) then Count := Count + 1; end if;
      if Precision_Is_Error (Info.Precision_Status) then Count := Count + 1; end if;
      if Replay_Is_Error (Info.Replay_Status) then Count := Count + 1; end if;
      if Discriminant_Is_Error (Info.Discriminant_Status) then Count := Count + 1; end if;
      if not Info.Has_Master and then Info.Kind /= Scope_Context_Unknown then Count := Count + 1; end if;
      if Info.Designated_Subtype_Mismatch then Count := Count + 1; end if;
      if Info.Access_Parameter_Escapes then Count := Count + 1; end if;
      if Info.Finalization_Uses_Expired_Master then Count := Count + 1; end if;
      if Info.Requires_Static_Level and then Level_Known (Info.Source_Level)
        and then Level_Known (Info.Target_Level)
        and then not Level_Compatible (Info.Source_Level, Info.Target_Level)
      then
         Count := Count + 1;
      end if;
      return Count;
   end Blocker_Count;

   function Message_For (Status : Scope_Legality_Status) return String is
   begin
      case Status is
         when Scope_Legality_Legal_Master_Hierarchy => return "accessibility master hierarchy is legal";
         when Scope_Legality_Legal_Static_Level => return "static accessibility level is compatible";
         when Scope_Legality_Legal_Dynamic_Check => return "dynamic accessibility check is required and preserved";
         when Scope_Legality_Legal_Allocator_Master => return "allocator master is sufficiently long lived";
         when Scope_Legality_Legal_Return_Object_Master => return "return object master is sufficiently long lived";
         when Scope_Legality_Legal_Return_Access_Master => return "return access value master is sufficiently long lived";
         when Scope_Legality_Legal_Access_Discriminant_Master => return "access discriminant master is sufficiently long lived";
         when Scope_Legality_Legal_Access_Conversion => return "access conversion preserves accessibility";
         when Scope_Legality_Legal_Generic_Substitution => return "generic actual accessibility substitution is legal";
         when Scope_Legality_Legal_Discriminant_Aggregate => return "discriminant aggregate accessibility is legal";
         when Scope_Legality_Missing_Master => return "scope graph is missing a required master";
         when Scope_Legality_Master_Too_Short => return "master is too short lived";
         when Scope_Legality_Static_Level_Too_Deep => return "static accessibility level is too deep";
         when Scope_Legality_Dynamic_Level_Unresolved => return "dynamic accessibility level is unresolved";
         when Scope_Legality_Anonymous_Access_Level_Unresolved => return "anonymous access parameter level is unresolved";
         when Scope_Legality_Anonymous_Access_Level_Too_Deep => return "anonymous access parameter level is too deep";
         when Scope_Legality_Access_Parameter_Escapes => return "access parameter escapes its master";
         when Scope_Legality_Allocator_Master_Unresolved => return "allocator master is unresolved";
         when Scope_Legality_Allocator_Master_Too_Short => return "allocator master is too short lived";
         when Scope_Legality_Allocator_Designated_Subtype_Mismatch => return "allocator designated subtype does not match";
         when Scope_Legality_Return_Object_Master_Too_Short => return "return object master is too short lived";
         when Scope_Legality_Return_Access_Master_Too_Short => return "return access value master is too short lived";
         when Scope_Legality_Return_Master_Unresolved => return "return master is unresolved";
         when Scope_Legality_Access_Discriminant_Master_Unresolved => return "access discriminant master is unresolved";
         when Scope_Legality_Access_Discriminant_Master_Too_Short => return "access discriminant master is too short lived";
         when Scope_Legality_Access_Conversion_Level_Too_Deep => return "access conversion level is too deep";
         when Scope_Legality_Generic_Substitution_Master_Mismatch => return "generic actual master is too short lived";
         when Scope_Legality_Generic_Substitution_Master_Unresolved => return "generic actual master is unresolved";
         when Scope_Legality_Dangling_Renaming_Risk => return "renaming may dangle";
         when Scope_Legality_Finalization_Master_Unresolved => return "finalization master is unresolved";
         when Scope_Legality_Finalization_Uses_Expired_Master => return "finalization uses an expired master";
         when Scope_Legality_Linked_Accessibility_Precision_Error => return "linked accessibility precision legality failed";
         when Scope_Legality_Linked_Generic_Replay_Error => return "linked generic replay legality failed";
         when Scope_Legality_Linked_Discriminant_Error => return "linked discriminant legality failed";
         when Scope_Legality_Coverage_Gate_Blocker => return "coverage gate blocks accessibility scope conclusion";
         when Scope_Legality_Multiple_Blockers => return "multiple accessibility scope blockers apply";
         when Scope_Legality_Indeterminate => return "accessibility scope legality is indeterminate";
         when Scope_Legality_Not_Checked => return "accessibility scope legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Info : Scope_Context_Info; Status : Scope_Legality_Status) return String is
      pragma Unreferenced (Status);
   begin
      return "source_level=" & Natural'Image (Natural (Info.Source_Level))
        & ", target_level=" & Natural'Image (Natural (Info.Target_Level))
        & ", master_level=" & Natural'Image (Natural (Info.Master_Level))
        & ", required_master=" & Natural'Image (Natural (Info.Required_Master_Level));
   end Detail_For;

   procedure Clear (Model : in out Scope_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Scope_Context_Model;
      Info  : Scope_Context_Info)
   is
      Copy : Scope_Context_Info := Info;
   begin
      Model.Contexts.Append (Copy);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context_Fingerprint (Copy));
   end Add_Context;

   function Context_Count (Model : Scope_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Scope_Context_Model;
      Index : Positive) return Scope_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Scope_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Scope_Context_Model) return Scope_Legality_Model is
      Model : Scope_Legality_Model;
      Row_Id : Scope_Legality_Id := No_Scope_Legality;
   begin
      for C of Contexts.Contexts loop
         declare
            Count : constant Natural := Blocker_Count (C);
            Status : constant Scope_Legality_Status := Choose_Status (C, Count);
            Row : Scope_Legality_Info;
         begin
            Row_Id := Row_Id + 1;
            Row.Id := Row_Id;
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Node := C.Node;
            Row.Status := Status;
            Row.Object_Name := C.Object_Name;
            Row.Scope_Name := C.Scope_Name;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String (Detail_For (C, Status));
            Row.Source_Level := C.Source_Level;
            Row.Target_Level := C.Target_Level;
            Row.Master_Level := C.Master_Level;
            Row.Required_Master_Level := C.Required_Master_Level;
            Row.Blocker_Count := Count;
            Row.Precision_Status := C.Precision_Status;
            Row.Replay_Status := C.Replay_Status;
            Row.Discriminant_Status := C.Discriminant_Status;
            Row.Gate_Status := C.Gate_Status;
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Fingerprint := Row_Fingerprint (Row);
            Model.Rows.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Scope_Legality_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At (Model : Scope_Legality_Model; Index : Positive) return Scope_Legality_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Scope_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Scope_Legality_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Scope_Legality_Model;
      Status : Scope_Legality_Status) return Scope_Result_Set
   is
      Results : Scope_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Scope_Legality_Model;
      Kind  : Scope_Context_Kind) return Scope_Result_Set
   is
      Results : Scope_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Object
     (Model       : Scope_Legality_Model;
      Object_Name : String) return Scope_Result_Set
   is
      Results : Scope_Result_Set;
      Wanted  : constant String := Lower (Object_Name);
   begin
      for Row of Model.Rows loop
         if Lower (To_String (Row.Object_Name)) = Wanted then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Object;

   function Result_Count (Results : Scope_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At (Results : Scope_Result_Set; Index : Positive) return Scope_Legality_Info is
   begin
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Scope_Legality_Model; Status : Scope_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Scope_Legality_Model; Kind : Scope_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Scope_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Scope_Legality_Model) return Natural is
   begin
      return Row_Count (Model) - Legal_Count (Model) - Indeterminate_Count (Model);
   end Error_Count;

   function Master_Error_Count (Model : Scope_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Scope_Legality_Missing_Master | Scope_Legality_Master_Too_Short |
           Scope_Legality_Static_Level_Too_Deep | Scope_Legality_Dynamic_Level_Unresolved |
           Scope_Legality_Allocator_Master_Unresolved |
           Scope_Legality_Allocator_Master_Too_Short |
           Scope_Legality_Return_Object_Master_Too_Short |
           Scope_Legality_Return_Access_Master_Too_Short |
           Scope_Legality_Return_Master_Unresolved |
           Scope_Legality_Access_Discriminant_Master_Unresolved |
           Scope_Legality_Access_Discriminant_Master_Too_Short |
           Scope_Legality_Generic_Substitution_Master_Mismatch |
           Scope_Legality_Generic_Substitution_Master_Unresolved |
           Scope_Legality_Finalization_Master_Unresolved |
           Scope_Legality_Finalization_Uses_Expired_Master
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Master_Error_Count;

   function Return_Error_Count (Model : Scope_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Scope_Legality_Return_Object_Master_Too_Short |
           Scope_Legality_Return_Access_Master_Too_Short | Scope_Legality_Return_Master_Unresolved
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Return_Error_Count;

   function Allocator_Error_Count (Model : Scope_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Scope_Legality_Allocator_Master_Unresolved |
           Scope_Legality_Allocator_Master_Too_Short |
           Scope_Legality_Allocator_Designated_Subtype_Mismatch
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Allocator_Error_Count;

   function Access_Discriminant_Error_Count (Model : Scope_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Scope_Legality_Access_Discriminant_Master_Unresolved |
           Scope_Legality_Access_Discriminant_Master_Too_Short |
           Scope_Legality_Linked_Discriminant_Error
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Access_Discriminant_Error_Count;

   function Generic_Error_Count (Model : Scope_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Scope_Legality_Generic_Substitution_Master_Mismatch |
           Scope_Legality_Generic_Substitution_Master_Unresolved |
           Scope_Legality_Linked_Generic_Replay_Error
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Error_Count;

   function Linked_Error_Count (Model : Scope_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Scope_Legality_Linked_Accessibility_Precision_Error |
           Scope_Legality_Linked_Generic_Replay_Error |
           Scope_Legality_Linked_Discriminant_Error |
           Scope_Legality_Multiple_Blockers
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Linked_Error_Count;

   function Coverage_Gate_Error_Count (Model : Scope_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Scope_Legality_Coverage_Gate_Blocker | Scope_Legality_Multiple_Blockers then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Coverage_Gate_Error_Count;

   function Indeterminate_Count (Model : Scope_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Scope_Legality_Indeterminate then Count := Count + 1; end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Fingerprint (Model : Scope_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Scope_Legality_Info) return Boolean is
   begin
      return Info.Status /= Scope_Legality_Not_Checked;
   end Has_Legality;

end Editor.Ada_Accessibility_Scope_Graph_Legality;
