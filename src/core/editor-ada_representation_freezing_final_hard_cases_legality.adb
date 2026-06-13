with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality is

   use type Access_Final.Master_Scope_Final_Status;
   use type Cross_Final.Cross_Unit_Final_Status;
   use type Disc_Consumer.Discriminant_Consumer_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elab_Final.Final_Elaboration_Status;
   use type Generic_Cycles.Nested_Generic_Closure_Status;
   use type Rep_AST.Representation_Operational_AST_Repair_Status;
   use type Rep_CPD.Representation_Tasking_CPD_Status;
   use type Task_Final.Final_Tasking_Status;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 1) mod 2_147_483_647;
   end Mix;

   function Kind_Slot (Kind : Final_Representation_Context_Kind) return Natural is
   begin
      return Final_Representation_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Final_Representation_Status) return Natural is
   begin
      return Final_Representation_Status'Pos (Status) + 1;
   end Status_Slot;

   function Rep_Blocker (Status : Rep_CPD.Representation_Tasking_CPD_Status) return Boolean is
   begin
      return Status /= Rep_CPD.Representation_Tasking_CPD_Not_Checked
        and then not Rep_CPD.Is_Legal (Status)
        and then Status /= Rep_CPD.Representation_Tasking_CPD_Indeterminate
        and then Status /= Rep_CPD.Representation_Tasking_CPD_Tasking_CPD_Indeterminate;
   end Rep_Blocker;

   function Generic_Blocker (Status : Generic_Cycles.Nested_Generic_Closure_Status) return Boolean is
   begin
      return Status /= Generic_Cycles.Nested_Generic_Not_Checked
        and then not Generic_Cycles.Is_Legal (Status)
        and then Status /= Generic_Cycles.Nested_Generic_Indeterminate;
   end Generic_Blocker;

   function AST_Blocker (Status : Rep_AST.Representation_Operational_AST_Repair_Status) return Boolean is
   begin
      return Status /= Rep_AST.Representation_Operational_AST_Not_Checked
        and then not Rep_AST.Is_Accepted (Status)
        and then Status /= Rep_AST.Representation_Operational_AST_Indeterminate;
   end AST_Blocker;

   function Disc_Blocker (Status : Disc_Consumer.Discriminant_Consumer_Status) return Boolean is
   begin
      return Status /= Disc_Consumer.Discriminant_Consumer_Not_Checked
        and then not Disc_Consumer.Is_Legal (Status)
        and then Status /= Disc_Consumer.Discriminant_Consumer_Indeterminate;
   end Disc_Blocker;

   function Access_Blocker (Status : Access_Final.Master_Scope_Final_Status) return Boolean is
   begin
      return Status /= Access_Final.Master_Scope_Final_Not_Checked
        and then not Access_Final.Is_Legal (Status)
        and then not Access_Final.Is_Indeterminate (Status);
   end Access_Blocker;

   function Elab_Blocker (Status : Elab_Final.Final_Elaboration_Status) return Boolean is
   begin
      return Status /= Elab_Final.Final_Elaboration_Not_Checked
        and then not Elab_Final.Is_Legal (Status)
        and then not Elab_Final.Is_Indeterminate (Status);
   end Elab_Blocker;

   function Task_Blocker (Status : Task_Final.Final_Tasking_Status) return Boolean is
   begin
      return Status /= Task_Final.Final_Tasking_Not_Checked
        and then not Task_Final.Is_Legal (Status)
        and then not Task_Final.Is_Indeterminate (Status);
   end Task_Blocker;

   function Count_Blockers (Info : Final_Representation_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if Info.Representation_Status = Rep_CPD.Representation_Tasking_CPD_Not_Checked
        or else Rep_Blocker (Info.Representation_Status)
        or else Info.Representation_Status = Rep_CPD.Representation_Tasking_CPD_Indeterminate
        or else Info.Representation_Status = Rep_CPD.Representation_Tasking_CPD_Tasking_CPD_Indeterminate
      then
         Count := Count + 1;
      end if;
      if Info.Requires_Cross_Unit and then Info.Cross_Unit_Status = Cross_Final.Cross_Unit_Final_Not_Checked then
         Count := Count + 1;
      elsif Cross_Final.Is_View_Barrier (Info.Cross_Unit_Status)
        or else Cross_Final.Is_Dependency_Error (Info.Cross_Unit_Status)
        or else (Info.Cross_Unit_Status /= Cross_Final.Cross_Unit_Final_Not_Checked
                 and then not Cross_Final.Is_Legal (Info.Cross_Unit_Status)
                 and then not Cross_Final.Is_Indeterminate (Info.Cross_Unit_Status))
        or else Cross_Final.Is_Indeterminate (Info.Cross_Unit_Status)
      then
         Count := Count + 1;
      end if;
      if Info.Requires_Generic_Cycle and then Info.Generic_Cycle_Status = Generic_Cycles.Nested_Generic_Not_Checked then
         Count := Count + 1;
      elsif Generic_Blocker (Info.Generic_Cycle_Status)
        or else Info.Generic_Cycle_Status = Generic_Cycles.Nested_Generic_Indeterminate
      then
         Count := Count + 1;
      end if;
      if Info.Requires_AST_Repair and then Info.AST_Repair_Status = Rep_AST.Representation_Operational_AST_Not_Checked then
         Count := Count + 1;
      elsif AST_Blocker (Info.AST_Repair_Status)
        or else Info.AST_Repair_Status = Rep_AST.Representation_Operational_AST_Indeterminate
      then
         Count := Count + 1;
      end if;
      if Info.Requires_Discriminant and then Info.Discriminant_Status = Disc_Consumer.Discriminant_Consumer_Not_Checked then
         Count := Count + 1;
      elsif Disc_Blocker (Info.Discriminant_Status)
        or else Info.Discriminant_Status = Disc_Consumer.Discriminant_Consumer_Indeterminate
      then
         Count := Count + 1;
      end if;
      if Info.Requires_Accessibility and then Info.Accessibility_Status = Access_Final.Master_Scope_Final_Not_Checked then
         Count := Count + 1;
      elsif Access_Blocker (Info.Accessibility_Status) or else Access_Final.Is_Indeterminate (Info.Accessibility_Status) then
         Count := Count + 1;
      end if;
      if Info.Requires_Elaboration and then Info.Elaboration_Status = Elab_Final.Final_Elaboration_Not_Checked then
         Count := Count + 1;
      elsif Elab_Blocker (Info.Elaboration_Status) or else Elab_Final.Is_Indeterminate (Info.Elaboration_Status) then
         Count := Count + 1;
      end if;
      if Info.Requires_Tasking and then Info.Tasking_Status = Task_Final.Final_Tasking_Not_Checked then
         Count := Count + 1;
      elsif Task_Blocker (Info.Tasking_Status) or else Task_Final.Is_Indeterminate (Info.Tasking_Status) then
         Count := Count + 1;
      end if;
      if Info.Generic_Formal_Freezing_Error then Count := Count + 1; end if;
      if Info.Inherited_Operational_Attribute_Error then Count := Count + 1; end if;
      if Info.Stream_Attribute_View_Error then Count := Count + 1; end if;
      if Info.Private_Full_View_Freezing_Error then Count := Count + 1; end if;
      if Info.Implicit_Freezing_Order_Error then Count := Count + 1; end if;
      if Info.Record_Layout_Finalization_Error then Count := Count + 1; end if;
      if Info.Variant_Discriminant_Layout_Error then Count := Count + 1; end if;
      if Info.Source_Fingerprint /= 0 and then Info.Expected_Source_Fingerprint /= 0
        and then Info.Source_Fingerprint /= Info.Expected_Source_Fingerprint
      then
         Count := Count + 1;
      end if;
      return Count;
   end Count_Blockers;

   function Classify (Info : Final_Representation_Context_Info) return Final_Representation_Status is
      Blockers : constant Natural := Count_Blockers (Info);
   begin
      if Blockers > 1 then
         return Final_Representation_Multiple_Blockers;
      end if;

      if Info.Representation_Status = Rep_CPD.Representation_Tasking_CPD_Not_Checked then
         return Final_Representation_Missing_Representation_CPD_Row;
      elsif Rep_Blocker (Info.Representation_Status) then
         return Final_Representation_Representation_CPD_Blocker;
      elsif Info.Representation_Status = Rep_CPD.Representation_Tasking_CPD_Indeterminate
        or else Info.Representation_Status = Rep_CPD.Representation_Tasking_CPD_Tasking_CPD_Indeterminate
      then
         return Final_Representation_Representation_CPD_Indeterminate;
      end if;

      if Info.Requires_Cross_Unit and then Info.Cross_Unit_Status = Cross_Final.Cross_Unit_Final_Not_Checked then
         return Final_Representation_Missing_Cross_Unit_Final_Row;
      elsif Cross_Final.Is_View_Barrier (Info.Cross_Unit_Status) then
         if Info.Cross_Unit_Status = Cross_Final.Cross_Unit_Final_Private_View_Barrier then
            return Final_Representation_Private_View_Barrier;
         else
            return Final_Representation_Limited_View_Barrier;
         end if;
      elsif Cross_Final.Is_Dependency_Error (Info.Cross_Unit_Status)
        or else (Info.Cross_Unit_Status /= Cross_Final.Cross_Unit_Final_Not_Checked
                 and then not Cross_Final.Is_Legal (Info.Cross_Unit_Status)
                 and then not Cross_Final.Is_Indeterminate (Info.Cross_Unit_Status))
      then
         return Final_Representation_Cross_Unit_Dependency_Blocker;
      elsif Cross_Final.Is_Indeterminate (Info.Cross_Unit_Status) then
         return Final_Representation_Indeterminate;
      end if;

      if Info.Requires_Generic_Cycle and then Info.Generic_Cycle_Status = Generic_Cycles.Nested_Generic_Not_Checked then
         return Final_Representation_Missing_Generic_Cycle_Row;
      elsif Generic_Cycles.Is_Cycle_Blocker (Info.Generic_Cycle_Status) then
         return Final_Representation_Generic_Cycle_Blocker;
      elsif Generic_Blocker (Info.Generic_Cycle_Status) then
         return Final_Representation_Generic_Replay_Blocker;
      elsif Info.Generic_Cycle_Status = Generic_Cycles.Nested_Generic_Indeterminate then
         return Final_Representation_Indeterminate;
      end if;

      if Info.Requires_AST_Repair and then Info.AST_Repair_Status = Rep_AST.Representation_Operational_AST_Not_Checked then
         return Final_Representation_Missing_AST_Repair_Row;
      elsif AST_Blocker (Info.AST_Repair_Status) then
         return Final_Representation_AST_Repair_Blocker;
      elsif Info.AST_Repair_Status = Rep_AST.Representation_Operational_AST_Indeterminate then
         return Final_Representation_AST_Repair_Indeterminate;
      end if;

      if Info.Requires_Discriminant and then Info.Discriminant_Status = Disc_Consumer.Discriminant_Consumer_Not_Checked then
         return Final_Representation_Missing_Discriminant_Row;
      elsif Disc_Blocker (Info.Discriminant_Status) then
         return Final_Representation_Discriminant_Variant_Blocker;
      elsif Info.Discriminant_Status = Disc_Consumer.Discriminant_Consumer_Indeterminate then
         return Final_Representation_Indeterminate;
      end if;

      if Info.Requires_Accessibility and then Info.Accessibility_Status = Access_Final.Master_Scope_Final_Not_Checked then
         return Final_Representation_Missing_Accessibility_Row;
      elsif Access_Blocker (Info.Accessibility_Status) then
         return Final_Representation_Accessibility_Finalization_Blocker;
      elsif Access_Final.Is_Indeterminate (Info.Accessibility_Status) then
         return Final_Representation_Indeterminate;
      end if;

      if Info.Requires_Elaboration and then Info.Elaboration_Status = Elab_Final.Final_Elaboration_Not_Checked then
         return Final_Representation_Missing_Elaboration_Row;
      elsif Elab_Blocker (Info.Elaboration_Status) then
         return Final_Representation_Elaboration_Order_Blocker;
      elsif Elab_Final.Is_Indeterminate (Info.Elaboration_Status) then
         return Final_Representation_Indeterminate;
      end if;

      if Info.Requires_Tasking and then Info.Tasking_Status = Task_Final.Final_Tasking_Not_Checked then
         return Final_Representation_Missing_Tasking_Row;
      elsif Task_Blocker (Info.Tasking_Status) then
         return Final_Representation_Tasking_Final_Effect_Blocker;
      elsif Task_Final.Is_Indeterminate (Info.Tasking_Status) then
         return Final_Representation_Indeterminate;
      end if;

      if Info.Generic_Formal_Freezing_Error then
         return Final_Representation_Generic_Formal_Freezing_Blocker;
      elsif Info.Inherited_Operational_Attribute_Error then
         return Final_Representation_Inherited_Operational_Attribute_Blocker;
      elsif Info.Stream_Attribute_View_Error then
         return Final_Representation_Stream_Attribute_View_Blocker;
      elsif Info.Private_Full_View_Freezing_Error then
         return Final_Representation_Private_Full_View_Freezing_Blocker;
      elsif Info.Implicit_Freezing_Order_Error then
         return Final_Representation_Implicit_Freezing_Order_Blocker;
      elsif Info.Record_Layout_Finalization_Error then
         return Final_Representation_Record_Layout_Finalization_Blocker;
      elsif Info.Variant_Discriminant_Layout_Error then
         return Final_Representation_Variant_Discriminant_Layout_Blocker;
      elsif Info.Source_Fingerprint /= 0 and then Info.Expected_Source_Fingerprint /= 0
        and then Info.Source_Fingerprint /= Info.Expected_Source_Fingerprint
      then
         return Final_Representation_Source_Fingerprint_Mismatch;
      end if;

      case Info.Kind is
         when Final_Representation_Private_Full_View_Freezing => return Final_Representation_Legal_Private_Full_View_Freezing_Accepted;
         when Final_Representation_Limited_View_Stream_Attribute => return Final_Representation_Legal_Limited_View_Stream_Attribute_Accepted;
         when Final_Representation_Generic_Formal_Freezing => return Final_Representation_Legal_Generic_Formal_Freezing_Accepted;
         when Final_Representation_Inherited_Operational_Attribute => return Final_Representation_Legal_Inherited_Operational_Attribute_Accepted;
         when Final_Representation_Derived_Type_Operational_Attribute => return Final_Representation_Legal_Derived_Type_Operational_Attribute_Accepted;
         when Final_Representation_Record_Layout_Discriminant_Finalization => return Final_Representation_Legal_Record_Layout_Discriminant_Finalization_Accepted;
         when Final_Representation_Variant_Record_Layout => return Final_Representation_Legal_Variant_Record_Layout_Accepted;
         when Final_Representation_Stream_Attribute_Private_View => return Final_Representation_Legal_Stream_Attribute_Private_View_Accepted;
         when Final_Representation_Implicit_Freezing_Order => return Final_Representation_Legal_Implicit_Freezing_Order_Accepted;
         when Final_Representation_Generic_Instance_Representation => return Final_Representation_Legal_Generic_Instance_Representation_Accepted;
         when Final_Representation_Representation_Item => return Final_Representation_Legal_Representation_Item_Accepted;
         when Final_Representation_Operational_Item => return Final_Representation_Legal_Operational_Item_Accepted;
         when Final_Representation_Unknown => return Final_Representation_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Final_Representation_Status) return String is
   begin
      case Status is
         when Final_Representation_Legal_Private_Full_View_Freezing_Accepted => return "private/full-view freezing accepted";
         when Final_Representation_Legal_Limited_View_Stream_Attribute_Accepted => return "limited-view stream attribute accepted";
         when Final_Representation_Legal_Generic_Formal_Freezing_Accepted => return "generic formal freezing accepted";
         when Final_Representation_Legal_Inherited_Operational_Attribute_Accepted => return "inherited operational attribute accepted";
         when Final_Representation_Legal_Derived_Type_Operational_Attribute_Accepted => return "derived-type operational attribute accepted";
         when Final_Representation_Legal_Record_Layout_Discriminant_Finalization_Accepted => return "record layout with discriminants and finalization accepted";
         when Final_Representation_Legal_Variant_Record_Layout_Accepted => return "variant record layout accepted";
         when Final_Representation_Legal_Stream_Attribute_Private_View_Accepted => return "private-view stream attribute accepted";
         when Final_Representation_Legal_Implicit_Freezing_Order_Accepted => return "implicit freezing order accepted";
         when Final_Representation_Legal_Generic_Instance_Representation_Accepted => return "generic instance representation accepted";
         when Final_Representation_Legal_Representation_Item_Accepted => return "representation item accepted";
         when Final_Representation_Legal_Operational_Item_Accepted => return "operational item accepted";
         when Final_Representation_Missing_Representation_CPD_Row => return "representation/freezing CPD evidence is missing";
         when Final_Representation_Representation_CPD_Blocker => return "representation/freezing CPD evidence blocks final representation legality";
         when Final_Representation_Representation_CPD_Indeterminate => return "representation/freezing CPD evidence is indeterminate";
         when Final_Representation_Missing_Cross_Unit_Final_Row => return "cross-unit final closure evidence is missing";
         when Final_Representation_Cross_Unit_Dependency_Blocker => return "cross-unit dependency blocks final representation legality";
         when Final_Representation_Private_View_Barrier => return "private-view barrier blocks final representation legality";
         when Final_Representation_Limited_View_Barrier => return "limited-view barrier blocks final representation legality";
         when Final_Representation_Missing_Generic_Cycle_Row => return "nested generic replay cycle evidence is missing";
         when Final_Representation_Generic_Cycle_Blocker => return "nested generic replay cycle blocks final representation legality";
         when Final_Representation_Generic_Replay_Blocker => return "generic replay evidence blocks final representation legality";
         when Final_Representation_Missing_AST_Repair_Row => return "representation/operational AST repair evidence is missing";
         when Final_Representation_AST_Repair_Blocker => return "representation/operational AST repair blocks final representation legality";
         when Final_Representation_AST_Repair_Indeterminate => return "representation/operational AST repair is indeterminate";
         when Final_Representation_Missing_Discriminant_Row => return "discriminant/variant evidence is missing";
         when Final_Representation_Discriminant_Variant_Blocker => return "discriminant/variant evidence blocks final representation legality";
         when Final_Representation_Missing_Accessibility_Row => return "accessibility/finalization evidence is missing";
         when Final_Representation_Accessibility_Finalization_Blocker => return "accessibility/finalization evidence blocks final representation legality";
         when Final_Representation_Missing_Elaboration_Row => return "elaboration order evidence is missing";
         when Final_Representation_Elaboration_Order_Blocker => return "elaboration order evidence blocks final representation legality";
         when Final_Representation_Missing_Tasking_Row => return "tasking final-effect evidence is missing";
         when Final_Representation_Tasking_Final_Effect_Blocker => return "tasking final effects block final representation legality";
         when Final_Representation_Generic_Formal_Freezing_Blocker => return "generic formal freezing order blocks representation legality";
         when Final_Representation_Inherited_Operational_Attribute_Blocker => return "inherited operational attribute legality blocks representation legality";
         when Final_Representation_Stream_Attribute_View_Blocker => return "stream attribute view legality blocks representation legality";
         when Final_Representation_Private_Full_View_Freezing_Blocker => return "private/full-view freezing order blocks representation legality";
         when Final_Representation_Implicit_Freezing_Order_Blocker => return "implicit freezing order blocks representation legality";
         when Final_Representation_Record_Layout_Finalization_Blocker => return "record layout finalization blocks representation legality";
         when Final_Representation_Variant_Discriminant_Layout_Blocker => return "variant/discriminant layout blocks representation legality";
         when Final_Representation_Source_Fingerprint_Mismatch => return "representation source fingerprint mismatch";
         when Final_Representation_Multiple_Blockers => return "multiple final representation/freezing blockers preserved";
         when Final_Representation_Indeterminate => return "final representation/freezing legality is indeterminate";
         when Final_Representation_Not_Checked => return "final representation/freezing legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Info : Final_Representation_Context_Info; Status : Final_Representation_Status) return String is
      pragma Unreferenced (Status);
   begin
      return "target=" & To_String (Info.Target_Name)
        & "; unit=" & To_String (Info.Unit_Name)
        & "; component=" & To_String (Info.Component_Name);
   end Detail_For;

   procedure Clear (Model : in out Final_Representation_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Final_Representation_Context_Model; Info : Final_Representation_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Kind_Slot (Info.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Node));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Final_Representation_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Final_Representation_Context_Model; Index : Positive) return Final_Representation_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Final_Representation_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Final_Representation_Context_Model) return Final_Representation_Model is
      Model : Final_Representation_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         declare
            C : constant Final_Representation_Context_Info := Context_At (Contexts, I);
            Status : constant Final_Representation_Status := Classify (C);
            Row : Final_Representation_Info;
         begin
            Row.Id := Final_Representation_Row_Id (I);
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Node := C.Node;
            Row.Target_Node := C.Target_Node;
            Row.Freezing_Node := C.Freezing_Node;
            Row.Representation_Node := C.Representation_Node;
            Row.Status := Status;
            Row.Target_Name := C.Target_Name;
            Row.Unit_Name := C.Unit_Name;
            Row.Component_Name := C.Component_Name;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String (Detail_For (C, Status));
            Row.Blocker_Count := Count_Blockers (C);
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Fingerprint := Mix (Natural (Row.Id), Status_Slot (Status));
            Row.Fingerprint := Mix (Row.Fingerprint, Kind_Slot (Row.Kind));
            Row.Fingerprint := Mix (Row.Fingerprint, Natural (Row.Node));
            Row.Fingerprint := Mix (Row.Fingerprint, Row.Source_Fingerprint);
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
            if Is_Legal (Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;
            if Is_Cross_Unit_Error (Status) then Model.Cross_Unit_Error_Total := Model.Cross_Unit_Error_Total + 1; end if;
            if Is_Generic_Error (Status) then Model.Generic_Error_Total := Model.Generic_Error_Total + 1; end if;
            if Is_AST_Repair_Error (Status) then Model.AST_Repair_Error_Total := Model.AST_Repair_Error_Total + 1; end if;
            if Is_Discriminant_Error (Status) then Model.Discriminant_Error_Total := Model.Discriminant_Error_Total + 1; end if;
            if Is_Accessibility_Error (Status) then Model.Accessibility_Error_Total := Model.Accessibility_Error_Total + 1; end if;
            if Is_Elaboration_Error (Status) then Model.Elaboration_Error_Total := Model.Elaboration_Error_Total + 1; end if;
            if Is_Tasking_Error (Status) then Model.Tasking_Error_Total := Model.Tasking_Error_Total + 1; end if;
            if Is_Freezing_Order_Error (Status) then Model.Freezing_Order_Error_Total := Model.Freezing_Order_Error_Total + 1; end if;
            if Is_Indeterminate (Status) then Model.Indeterminate_Total := Model.Indeterminate_Total + 1; end if;
         end;
      end loop;
      if Model.Result_Fingerprint = 0 and then Row_Count (Model) > 0 then
         Model.Result_Fingerprint := Row_Count (Model) * 1191;
      end if;
      return Model;
   end Build;

   function Row_Count (Model : Final_Representation_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At (Model : Final_Representation_Model; Index : Positive) return Final_Representation_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node (Model : Final_Representation_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Final_Representation_Info is
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Node = Node then
            return Row_At (Model, I);
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Final_Representation_Model; Status : Final_Representation_Status) return Final_Representation_Set is
      Result : Final_Representation_Set;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Status = Status then
            Result.Items.Append (Row_At (Model, I));
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row_At (Model, I).Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Final_Representation_Model; Kind : Final_Representation_Context_Kind) return Final_Representation_Set is
      Result : Final_Representation_Set;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Kind = Kind then
            Result.Items.Append (Row_At (Model, I));
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row_At (Model, I).Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Final_Representation_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At (Set : Final_Representation_Set; Index : Positive) return Final_Representation_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status (Model : Final_Representation_Model; Status : Final_Representation_Status) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Status = Status then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Final_Representation_Model; Kind : Final_Representation_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Kind = Kind then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Final_Representation_Model) return Natural is begin return Model.Legal_Total; end Legal_Count;
   function Error_Count (Model : Final_Representation_Model) return Natural is begin return Model.Error_Total; end Error_Count;
   function Cross_Unit_Error_Count (Model : Final_Representation_Model) return Natural is begin return Model.Cross_Unit_Error_Total; end Cross_Unit_Error_Count;
   function Generic_Error_Count (Model : Final_Representation_Model) return Natural is begin return Model.Generic_Error_Total; end Generic_Error_Count;
   function AST_Repair_Error_Count (Model : Final_Representation_Model) return Natural is begin return Model.AST_Repair_Error_Total; end AST_Repair_Error_Count;
   function Discriminant_Error_Count (Model : Final_Representation_Model) return Natural is begin return Model.Discriminant_Error_Total; end Discriminant_Error_Count;
   function Accessibility_Error_Count (Model : Final_Representation_Model) return Natural is begin return Model.Accessibility_Error_Total; end Accessibility_Error_Count;
   function Elaboration_Error_Count (Model : Final_Representation_Model) return Natural is begin return Model.Elaboration_Error_Total; end Elaboration_Error_Count;
   function Tasking_Error_Count (Model : Final_Representation_Model) return Natural is begin return Model.Tasking_Error_Total; end Tasking_Error_Count;
   function Freezing_Order_Error_Count (Model : Final_Representation_Model) return Natural is begin return Model.Freezing_Order_Error_Total; end Freezing_Order_Error_Count;
   function Indeterminate_Count (Model : Final_Representation_Model) return Natural is begin return Model.Indeterminate_Total; end Indeterminate_Count;
   function Fingerprint (Model : Final_Representation_Model) return Natural is begin return Model.Result_Fingerprint; end Fingerprint;

   function Is_Legal (Status : Final_Representation_Status) return Boolean is
   begin
      return Status in Final_Representation_Legal_Private_Full_View_Freezing_Accepted .. Final_Representation_Legal_Operational_Item_Accepted;
   end Is_Legal;

   function Is_Cross_Unit_Error (Status : Final_Representation_Status) return Boolean is
   begin
      return Status in Final_Representation_Missing_Cross_Unit_Final_Row .. Final_Representation_Limited_View_Barrier;
   end Is_Cross_Unit_Error;

   function Is_Generic_Error (Status : Final_Representation_Status) return Boolean is
   begin
      return Status in Final_Representation_Missing_Generic_Cycle_Row .. Final_Representation_Generic_Replay_Blocker;
   end Is_Generic_Error;

   function Is_AST_Repair_Error (Status : Final_Representation_Status) return Boolean is
   begin
      return Status in Final_Representation_Missing_AST_Repair_Row .. Final_Representation_AST_Repair_Indeterminate;
   end Is_AST_Repair_Error;

   function Is_Discriminant_Error (Status : Final_Representation_Status) return Boolean is
   begin
      return Status in Final_Representation_Missing_Discriminant_Row .. Final_Representation_Discriminant_Variant_Blocker;
   end Is_Discriminant_Error;

   function Is_Accessibility_Error (Status : Final_Representation_Status) return Boolean is
   begin
      return Status in Final_Representation_Missing_Accessibility_Row .. Final_Representation_Accessibility_Finalization_Blocker;
   end Is_Accessibility_Error;

   function Is_Elaboration_Error (Status : Final_Representation_Status) return Boolean is
   begin
      return Status in Final_Representation_Missing_Elaboration_Row .. Final_Representation_Elaboration_Order_Blocker;
   end Is_Elaboration_Error;

   function Is_Tasking_Error (Status : Final_Representation_Status) return Boolean is
   begin
      return Status in Final_Representation_Missing_Tasking_Row .. Final_Representation_Tasking_Final_Effect_Blocker;
   end Is_Tasking_Error;

   function Is_Freezing_Order_Error (Status : Final_Representation_Status) return Boolean is
   begin
      return Status in Final_Representation_Generic_Formal_Freezing_Blocker .. Final_Representation_Source_Fingerprint_Mismatch;
   end Is_Freezing_Order_Error;

   function Is_Indeterminate (Status : Final_Representation_Status) return Boolean is
   begin
      return Status = Final_Representation_Indeterminate
        or else Status = Final_Representation_Representation_CPD_Indeterminate
        or else Status = Final_Representation_AST_Repair_Indeterminate;
   end Is_Indeterminate;

   function Has_Error (Info : Final_Representation_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status) and then Info.Status /= Final_Representation_Not_Checked;
   end Has_Error;

end Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
