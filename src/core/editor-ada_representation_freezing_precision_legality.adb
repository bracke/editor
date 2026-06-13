with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Freezing_Precision_Legality is
   use type Freezing_Status;
   use type Representation_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Seed, Value : Natural) return Natural is
      Hash : constant Long_Long_Integer :=
        (Long_Long_Integer (Seed) * 131 + Long_Long_Integer (Value) * 17 + 113)
        mod 2_147_483_647;
   begin
      return Natural (Hash);
   end Mix;

   function Node_Slot (Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural is
   begin
      return Natural (Node);
   exception
      when Constraint_Error => return 0;
   end Node_Slot;

   function Kind_Slot (Kind : Representation_Freezing_Precision_Context_Kind) return Natural is
   begin
      return Representation_Freezing_Precision_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Cause_Slot (Cause : Freezing_Cause_Kind) return Natural is
   begin
      return Freezing_Cause_Kind'Pos (Cause) + 1;
   end Cause_Slot;

   function Status_Slot (Status : Representation_Freezing_Precision_Status) return Natural is
   begin
      return Representation_Freezing_Precision_Status'Pos (Status) + 1;
   end Status_Slot;

   function Is_Legal_Status (Status : Representation_Freezing_Precision_Status) return Boolean is
   begin
      return Status in
        Representation_Freezing_Precision_Legal_Representation_Item |
        Representation_Freezing_Precision_Legal_Aspect |
        Representation_Freezing_Precision_Legal_Operational_Item |
        Representation_Freezing_Precision_Legal_Stream_Attribute |
        Representation_Freezing_Precision_Legal_Record_Layout |
        Representation_Freezing_Precision_Legal_Generic_Instance_Effect |
        Representation_Freezing_Precision_Legal_Private_Full_View |
        Representation_Freezing_Precision_Legal_Implicit_Freezing;
   end Is_Legal_Status;

   function Representation_Error (Status : Representation_Status) return Boolean is
   begin
      return Status /= Editor.Ada_Representation_Legality.Representation_Legality_Ok;
   end Representation_Error;

   function Integration_Error (Status : Representation_Integration_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Not_Checked |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Representation_Item |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Record_Layout |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Stream_Attribute |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Operational_Attribute |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Convention |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Generic_Instance_Effect |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Legal_Finalization_Effect;
   end Integration_Error;

   function Generic_Error (Status : Generic_Instance_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Instance |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Body_Substitution |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Default_Substitution |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Formal_Package_Substitution |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Boxed_Formal_Package |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Instance_Freezing |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Legal_Representation_Item;
   end Generic_Error;

   function Elaboration_Error (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Not_Checked |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Dependency_Order |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Call_Order |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Access_Order |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Generic_Instance_Order |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Body_Before_Use |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Preelaborated_Unit |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Pure_Unit |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Remote_Types_Unit |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Shared_Passive_Unit;
   end Elaboration_Error;

   function Tasking_Error (Status : Tasking_Precision_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Not_Checked |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Task_Activation |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Task_Body |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Protected_Function |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Protected_Procedure |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Protected_Entry |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Entry_Barrier |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Entry_Family_Index |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Accept |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Requeue |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Select_Alternative |
        Editor.Ada_Tasking_Protected_Precision_Legality.Tasking_Precision_Legal_Queued_Entry_Call;
   end Tasking_Error;

   function Is_Freezing_Error (Status : Representation_Freezing_Precision_Status) return Boolean is
   begin
      return Status in
        Representation_Freezing_Precision_Representation_After_Explicit_Freezing |
        Representation_Freezing_Precision_Representation_After_Implicit_Freezing |
        Representation_Freezing_Precision_Representation_After_Generic_Instance_Freezing |
        Representation_Freezing_Precision_Representation_After_Private_Full_View_Freezing |
        Representation_Freezing_Precision_Representation_At_Freezing_Point;
   end Is_Freezing_Error;

   function Is_View_Error (Status : Representation_Freezing_Precision_Status) return Boolean is
   begin
      return Status in
        Representation_Freezing_Precision_Private_View_Barrier |
        Representation_Freezing_Precision_Full_View_Completion_Missing;
   end Is_View_Error;

   function Is_Representation_Error (Status : Representation_Freezing_Precision_Status) return Boolean is
   begin
      return Status in
        Representation_Freezing_Precision_Target_Unresolved |
        Representation_Freezing_Precision_Target_Ambiguous |
        Representation_Freezing_Precision_Target_Not_Freezable |
        Representation_Freezing_Precision_Target_Kind_Mismatch |
        Representation_Freezing_Precision_Static_Value_Error |
        Representation_Freezing_Precision_Profile_Error |
        Representation_Freezing_Precision_Operational_Error |
        Representation_Freezing_Precision_Linked_Representation_Error;
   end Is_Representation_Error;

   function Is_Integration_Error (Status : Representation_Freezing_Precision_Status) return Boolean is
   begin
      return Status in
        Representation_Freezing_Precision_Record_Layout_Error |
        Representation_Freezing_Precision_Stream_Profile_Error |
        Representation_Freezing_Precision_Linked_Integration_Error;
   end Is_Integration_Error;

   function Is_Generic_Error (Status : Representation_Freezing_Precision_Status) return Boolean is
   begin
      return Status in
        Representation_Freezing_Precision_Generic_Instance_Freezing_Error |
        Representation_Freezing_Precision_Generic_Instance_Representation_Error;
   end Is_Generic_Error;

   function Is_Elab_Tasking_Error (Status : Representation_Freezing_Precision_Status) return Boolean is
   begin
      return Status in
        Representation_Freezing_Precision_Elaboration_Freezing_Error |
        Representation_Freezing_Precision_Tasking_Protected_Freezing_Error;
   end Is_Elab_Tasking_Error;

   function Classify (Info : Representation_Freezing_Precision_Context_Info)
      return Representation_Freezing_Precision_Status is
   begin
      if Info.Freezing = Editor.Ada_Freezing_Points.Freezing_Target_Unresolved then
         return Representation_Freezing_Precision_Target_Unresolved;
      elsif Info.Freezing = Editor.Ada_Freezing_Points.Freezing_Target_Ambiguous then
         return Representation_Freezing_Precision_Target_Ambiguous;
      elsif Info.Private_View_Barrier then
         return Representation_Freezing_Precision_Private_View_Barrier;
      elsif not Info.Full_View_Completed then
         return Representation_Freezing_Precision_Full_View_Completion_Missing;
      elsif Info.Representation_After_Private_Full_View_Freezing then
         return Representation_Freezing_Precision_Representation_After_Private_Full_View_Freezing;
      elsif Info.Representation_After_Generic_Instance_Freezing then
         return Representation_Freezing_Precision_Representation_After_Generic_Instance_Freezing;
      elsif Info.Representation_After_Implicit_Freezing then
         return Representation_Freezing_Precision_Representation_After_Implicit_Freezing;
      elsif Info.Representation = Editor.Ada_Representation_Legality.Representation_Legality_Target_Unresolved then
         return Representation_Freezing_Precision_Target_Unresolved;
      elsif Info.Representation = Editor.Ada_Representation_Legality.Representation_Legality_Target_Ambiguous then
         return Representation_Freezing_Precision_Target_Ambiguous;
      elsif Info.Representation = Editor.Ada_Representation_Legality.Representation_Legality_Target_Not_Freezable then
         return Representation_Freezing_Precision_Target_Not_Freezable;
      elsif Info.Representation = Editor.Ada_Representation_Legality.Representation_Legality_Target_Kind_Mismatch then
         return Representation_Freezing_Precision_Target_Kind_Mismatch;
      elsif Info.Representation = Editor.Ada_Representation_Legality.Representation_Legality_After_Freezing then
         return Representation_Freezing_Precision_Representation_After_Explicit_Freezing;
      elsif Info.Representation = Editor.Ada_Representation_Legality.Representation_Legality_At_Freezing_Point then
         return Representation_Freezing_Precision_Representation_At_Freezing_Point;
      elsif Info.Representation in
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Malformed |
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Division_By_Zero |
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Not_Positive |
        Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Static_Value_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Value_Static_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Not_Integer then
         return Representation_Freezing_Precision_Static_Value_Error;
      elsif Info.Representation in
        Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Malformed |
        Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Profile_Unknown |
        Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Profile_Mismatch then
         return Representation_Freezing_Precision_Profile_Error;
      elsif Info.Representation in
        Editor.Ada_Representation_Legality.Representation_Legality_Operational_Target_Incompatible |
        Editor.Ada_Representation_Legality.Representation_Legality_Operational_Boolean_Value_Required |
        Editor.Ada_Representation_Legality.Representation_Legality_Operational_Order_Value_Required then
         return Representation_Freezing_Precision_Operational_Error;
      elsif Representation_Error (Info.Representation) then
         return Representation_Freezing_Precision_Linked_Representation_Error;
      elsif Info.Integration in
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Record_Size_Exceeded |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Record_Padded |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Record_Alignment_Error |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Record_Component_Error |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Variant_Layout_Hole |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Variant_Layout_Overlap |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Discriminant_Layout_Error then
         return Representation_Freezing_Precision_Record_Layout_Error;
      elsif Info.Integration in
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Stream_Handler_Missing |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Stream_Handler_Malformed |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Stream_Handler_Ambiguous |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Stream_Profile_Mismatch |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Stream_Result_Mismatch |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Stream_Mode_Mismatch |
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Stream_Profile_Unknown then
         return Representation_Freezing_Precision_Stream_Profile_Error;
      elsif Integration_Error (Info.Integration) then
         return Representation_Freezing_Precision_Linked_Integration_Error;
      elsif Info.Generic_Instance in
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Instance_Freezes_Target |
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Representation_After_Instance_Freezing then
         return Representation_Freezing_Precision_Generic_Instance_Freezing_Error;
      elsif Generic_Error (Info.Generic_Instance) then
         return Representation_Freezing_Precision_Generic_Instance_Representation_Error;
      elsif Elaboration_Error (Info.Elaboration) then
         return Representation_Freezing_Precision_Elaboration_Freezing_Error;
      elsif Tasking_Error (Info.Tasking) then
         return Representation_Freezing_Precision_Tasking_Protected_Freezing_Error;
      elsif Info.Implicit_Use_Freezes_Target then
         return Representation_Freezing_Precision_Legal_Implicit_Freezing;
      else
         case Info.Kind is
            when Representation_Freezing_Context_Representation_Aspect =>
               return Representation_Freezing_Precision_Legal_Aspect;
            when Representation_Freezing_Context_Operational_Item =>
               return Representation_Freezing_Precision_Legal_Operational_Item;
            when Representation_Freezing_Context_Stream_Attribute =>
               return Representation_Freezing_Precision_Legal_Stream_Attribute;
            when Representation_Freezing_Context_Record_Layout =>
               return Representation_Freezing_Precision_Legal_Record_Layout;
            when Representation_Freezing_Context_Generic_Instance =>
               return Representation_Freezing_Precision_Legal_Generic_Instance_Effect;
            when Representation_Freezing_Context_Private_Full_View =>
               return Representation_Freezing_Precision_Legal_Private_Full_View;
            when Representation_Freezing_Context_Implicit_Semantic_Use =>
               return Representation_Freezing_Precision_Legal_Implicit_Freezing;
            when Representation_Freezing_Context_Task_Protected_Effect =>
               return Representation_Freezing_Precision_Legal_Implicit_Freezing;
            when Representation_Freezing_Context_Representation_Clause |
                 Representation_Freezing_Context_Unknown =>
               return Representation_Freezing_Precision_Legal_Representation_Item;
         end case;
      end if;
   end Classify;

   function Message_For (Status : Representation_Freezing_Precision_Status) return String is
   begin
      case Status is
         when Representation_Freezing_Precision_Legal_Representation_Item => return "representation item is legal before freezing";
         when Representation_Freezing_Precision_Legal_Aspect => return "representation aspect is legal before freezing";
         when Representation_Freezing_Precision_Legal_Operational_Item => return "operational item is legal before freezing";
         when Representation_Freezing_Precision_Legal_Stream_Attribute => return "stream attribute is legal before freezing";
         when Representation_Freezing_Precision_Legal_Record_Layout => return "record layout is legal before freezing";
         when Representation_Freezing_Precision_Legal_Generic_Instance_Effect => return "generic instance freezing effect is legal";
         when Representation_Freezing_Precision_Legal_Private_Full_View => return "private/full view representation timing is legal";
         when Representation_Freezing_Precision_Legal_Implicit_Freezing => return "implicit semantic use freezing is legal";
         when Representation_Freezing_Precision_Target_Unresolved => return "representation freezing target is unresolved";
         when Representation_Freezing_Precision_Target_Ambiguous => return "representation freezing target is ambiguous";
         when Representation_Freezing_Precision_Target_Not_Freezable => return "target is not freezable";
         when Representation_Freezing_Precision_Target_Kind_Mismatch => return "representation target kind does not match item";
         when Representation_Freezing_Precision_Representation_After_Explicit_Freezing => return "representation item appears after explicit freezing";
         when Representation_Freezing_Precision_Representation_After_Implicit_Freezing => return "representation item appears after implicit semantic-use freezing";
         when Representation_Freezing_Precision_Representation_After_Generic_Instance_Freezing => return "representation item appears after generic instance freezing";
         when Representation_Freezing_Precision_Representation_After_Private_Full_View_Freezing => return "representation item appears after private/full-view freezing";
         when Representation_Freezing_Precision_Representation_At_Freezing_Point => return "representation item occurs at the freezing point";
         when Representation_Freezing_Precision_Private_View_Barrier => return "private view blocks representation/freezing proof";
         when Representation_Freezing_Precision_Full_View_Completion_Missing => return "full view completion is missing before representation use";
         when Representation_Freezing_Precision_Static_Value_Error => return "representation static value is illegal";
         when Representation_Freezing_Precision_Profile_Error => return "representation profile is illegal";
         when Representation_Freezing_Precision_Operational_Error => return "operational representation item is illegal";
         when Representation_Freezing_Precision_Record_Layout_Error => return "record layout representation is illegal";
         when Representation_Freezing_Precision_Stream_Profile_Error => return "stream attribute profile is illegal";
         when Representation_Freezing_Precision_Generic_Instance_Freezing_Error => return "generic instance freezes representation target illegally";
         when Representation_Freezing_Precision_Generic_Instance_Representation_Error => return "generic instance representation effect is illegal";
         when Representation_Freezing_Precision_Elaboration_Freezing_Error => return "elaboration effect freezes representation target illegally";
         when Representation_Freezing_Precision_Tasking_Protected_Freezing_Error => return "tasking/protected effect freezes representation target illegally";
         when Representation_Freezing_Precision_Linked_Representation_Error => return "linked representation legality failed";
         when Representation_Freezing_Precision_Linked_Integration_Error => return "linked representation integration legality failed";
         when Representation_Freezing_Precision_Indeterminate => return "representation/freezing legality is indeterminate";
         when Representation_Freezing_Precision_Not_Checked => return "representation/freezing precision not checked";
      end case;
   end Message_For;

   function Detail_For (Info : Representation_Freezing_Precision_Context_Info) return String is
   begin
      return "target=" & To_String (Info.Normalized_Target_Name) &
        ", representation_line=" & Positive'Image (Info.Representation_Line) &
        ", freeze_line=" & Positive'Image (Info.Freeze_Line);
   end Detail_For;

   function Make_Info
     (Index  : Positive;
      C      : Representation_Freezing_Precision_Context_Info)
      return Representation_Freezing_Precision_Info
   is
      Status : constant Representation_Freezing_Precision_Status := Classify (C);
      Hash   : Natural := C.Source_Fingerprint;
   begin
      Hash := Mix (Hash, Natural (Index));
      Hash := Mix (Hash, Natural (C.Id));
      Hash := Mix (Hash, Kind_Slot (C.Kind));
      Hash := Mix (Hash, Status_Slot (Status));
      Hash := Mix (Hash, Cause_Slot (C.Cause));
      Hash := Mix (Hash, Node_Slot (C.Node));
      Hash := Mix (Hash, Node_Slot (C.Target_Node));
      Hash := Mix (Hash, C.Representation_Line);
      Hash := Mix (Hash, C.Freeze_Line);

      return
        (Id                     => Representation_Freezing_Precision_Id (Index),
         Context                => C.Id,
         Kind                   => C.Kind,
         Node                   => C.Node,
         Target_Node            => C.Target_Node,
         Freeze_Node            => C.Freeze_Node,
         Clause_Node            => C.Clause_Node,
         Status                 => Status,
         Target_Name            => C.Target_Name,
         Normalized_Target_Name => C.Normalized_Target_Name,
         Cause                  => C.Cause,
         Message                => To_Unbounded_String (Message_For (Status)),
         Detail                 => To_Unbounded_String (Detail_For (C)),
         Freezing               => C.Freezing,
         Representation         => C.Representation,
         Integration            => C.Integration,
         Generic_Instance       => C.Generic_Instance,
         Elaboration            => C.Elaboration,
         Tasking                => C.Tasking,
         Representation_Line    => C.Representation_Line,
         Freeze_Line            => C.Freeze_Line,
         Start_Line             => C.Start_Line,
         Start_Column           => C.Start_Column,
         End_Line               => C.End_Line,
         End_Column             => C.End_Column,
         Source_Fingerprint     => C.Source_Fingerprint,
         Fingerprint            => Hash);
   end Make_Info;

   procedure Clear (Model : in out Representation_Freezing_Precision_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Representation_Freezing_Precision_Context_Model;
      Context : Representation_Freezing_Precision_Context_Info) is
   begin
      Model.Items.Append (Context);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Context.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Kind_Slot (Context.Kind));
      Model.Fingerprint := Mix (Model.Fingerprint, Node_Slot (Context.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Source_Fingerprint);
   end Add_Context;

   function Context_Count
     (Model : Representation_Freezing_Precision_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Representation_Freezing_Precision_Context_Model;
      Index : Positive) return Representation_Freezing_Precision_Context_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items (Index);
   end Context_At;

   function Build
     (Contexts : Representation_Freezing_Precision_Context_Model)
      return Representation_Freezing_Precision_Model
   is
      Result : Representation_Freezing_Precision_Model;
      Index  : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare
            Info : constant Representation_Freezing_Precision_Info := Make_Info (Index, C);
         begin
            Result.Items.Append (Info);
            Result.Fingerprint := Mix (Result.Fingerprint, Info.Fingerprint);
            Result.Fingerprint := Mix (Result.Fingerprint, Status_Slot (Info.Status));
            Index := Index + 1;
         end;
      end loop;
      return Result;
   end Build;

   function Legality_Count
     (Model : Representation_Freezing_Precision_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Representation_Freezing_Precision_Model;
      Index : Positive) return Representation_Freezing_Precision_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items (Index);
   end Legality_At;

   function First_For_Node
     (Model : Representation_Freezing_Precision_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Freezing_Precision_Info is
   begin
      for Info of Model.Items loop
         if Info.Node = Node or else Info.Target_Node = Node or else Info.Clause_Node = Node then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function First_For_Context
     (Model   : Representation_Freezing_Precision_Model;
      Context : Representation_Freezing_Precision_Context_Id)
      return Representation_Freezing_Precision_Info is
   begin
      for Info of Model.Items loop
         if Info.Context = Context then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function Rows_For_Status
     (Model  : Representation_Freezing_Precision_Model;
      Status : Representation_Freezing_Precision_Status)
      return Representation_Freezing_Precision_Result_Set
   is
      Results : Representation_Freezing_Precision_Result_Set;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Results.Items.Append (Info);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Representation_Freezing_Precision_Model;
      Kind  : Representation_Freezing_Precision_Context_Kind)
      return Representation_Freezing_Precision_Result_Set
   is
      Results : Representation_Freezing_Precision_Result_Set;
   begin
      for Info of Model.Items loop
         if Info.Kind = Kind then
            Results.Items.Append (Info);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Target
     (Model : Representation_Freezing_Precision_Model;
      Name  : String) return Representation_Freezing_Precision_Result_Set
   is
      Results : Representation_Freezing_Precision_Result_Set;
   begin
      for Info of Model.Items loop
         if To_String (Info.Normalized_Target_Name) = Name
           or else To_String (Info.Target_Name) = Name
         then
            Results.Items.Append (Info);
         end if;
      end loop;
      return Results;
   end Rows_For_Target;

   function Result_Count
     (Results : Representation_Freezing_Precision_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Representation_Freezing_Precision_Result_Set;
      Index   : Positive) return Representation_Freezing_Precision_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items (Index);
   end Result_At;

   function Count_Status
     (Model  : Representation_Freezing_Precision_Model;
      Status : Representation_Freezing_Precision_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Representation_Freezing_Precision_Model;
      Kind  : Representation_Freezing_Precision_Context_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Representation_Freezing_Precision_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Is_Legal_Status (Info.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Representation_Freezing_Precision_Model) return Natural is
   begin
      return Legality_Count (Model) - Legal_Count (Model);
   end Error_Count;

   function Freezing_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Is_Freezing_Error (Info.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Freezing_Error_Count;

   function View_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Is_View_Error (Info.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end View_Error_Count;

   function Representation_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Is_Representation_Error (Info.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Representation_Error_Count;

   function Integration_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Is_Integration_Error (Info.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Integration_Error_Count;

   function Generic_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Is_Generic_Error (Info.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Generic_Error_Count;

   function Elaboration_Tasking_Error_Count (Model : Representation_Freezing_Precision_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Is_Elab_Tasking_Error (Info.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Elaboration_Tasking_Error_Count;

   function Fingerprint (Model : Representation_Freezing_Precision_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Representation_Freezing_Precision_Legality;
