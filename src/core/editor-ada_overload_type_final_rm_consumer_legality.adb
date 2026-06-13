with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_Type_Final_RM_Consumer_Legality is
   use type Access_AST.Access_Definition_AST_Repair_Status;
   use type Backmap.Generic_Backmap_Status;
   use type Edge.Overload_Type_Edge_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 1) mod 2_147_483_647;
   end Mix;

   function Kind_Slot (Kind : Final_RM_Context_Kind) return Natural is
   begin
      return Final_RM_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Final_RM_Status) return Natural is
   begin
      return Final_RM_Status'Pos (Status) + 1;
   end Status_Slot;

   function Access_AST_Is_Blocker
     (Status : Access_AST.Access_Definition_AST_Repair_Status) return Boolean is
   begin
      return Status /= Access_AST.Access_Definition_AST_Not_Checked
        and then not Access_AST.Is_Accepted (Status)
        and then Status /= Access_AST.Access_Definition_AST_Indeterminate;
   end Access_AST_Is_Blocker;

   function Needs_Access_AST (Kind : Final_RM_Context_Kind) return Boolean is
   begin
      return Kind in
        Final_RM_Access_Subprogram_Profile |
        Final_RM_Access_Subprogram_Null_Exclusion |
        Final_RM_Access_Subprogram_Convention;
   end Needs_Access_AST;

   function Needs_Generic_Backmap (Kind : Final_RM_Context_Kind) return Boolean is
   begin
      return Kind in
        Final_RM_Generic_Formal_Subprogram_Instance |
        Final_RM_Nested_Generic_Prefixed_Call;
   end Needs_Generic_Backmap;

   function Backmap_Is_Blocker
     (Status : Backmap.Generic_Backmap_Status) return Boolean is
   begin
      return Status /= Backmap.Generic_Backmap_Not_Checked
        and then not Backmap.Is_Legal (Status)
        and then Status /= Backmap.Generic_Backmap_Indeterminate;
   end Backmap_Is_Blocker;

   function Classify (Info : Final_RM_Context_Info) return Final_RM_Status is
      Blockers : Natural := 0;
   begin
      if Info.Edge_Status = Edge.Overload_Type_Edge_Not_Checked then
         Blockers := Blockers + 1;
      elsif Edge.Is_Ambiguous (Info.Edge_Status) then
         Blockers := Blockers + 1;
      elsif not Edge.Is_Legal (Info.Edge_Status) then
         Blockers := Blockers + 1;
      end if;

      if Needs_Access_AST (Info.Kind)
        and then Info.Access_AST_Status = Access_AST.Access_Definition_AST_Not_Checked
      then
         Blockers := Blockers + 1;
      elsif Access_AST_Is_Blocker (Info.Access_AST_Status) then
         Blockers := Blockers + 1;
      end if;

      if Needs_Generic_Backmap (Info.Kind)
        and then Info.Generic_Backmap_Status = Backmap.Generic_Backmap_Not_Checked
      then
         Blockers := Blockers + 1;
      elsif Backmap_Is_Blocker (Info.Generic_Backmap_Status) then
         Blockers := Blockers + 1;
      elsif Info.Generic_Backmap_Status = Backmap.Generic_Backmap_Indeterminate then
         Blockers := Blockers + 1;
      end if;

      if not Info.Profile_Matched then
         Blockers := Blockers + 1;
      end if;
      if not Info.Null_Exclusion_Matched then
         Blockers := Blockers + 1;
      end if;
      if not Info.Convention_Matched then
         Blockers := Blockers + 1;
      end if;
      if not Info.Primitive_Visible then
         Blockers := Blockers + 1;
      end if;
      if Info.Prefixed_Call_Ambiguous
        or else Info.Class_Wide_Controlling_Count > 1
        or else Info.Inherited_Primitive_Hiding_Count > 1
        or else Info.Universal_Root_Tie_Count > 1
        or else Info.Dispatching_Inherited_Tie_Count > 1
      then
         Blockers := Blockers + 1;
      end if;
      if Info.Cross_Unit_View_Barrier then
         Blockers := Blockers + 1;
      end if;

      if Blockers > 1 then
         return Final_RM_Multiple_Blockers;
      end if;

      if Info.Edge_Status = Edge.Overload_Type_Edge_Not_Checked then
         return Final_RM_Missing_Overload_Type_Edge;
      elsif Edge.Is_Ambiguous (Info.Edge_Status) then
         return Final_RM_Overload_Type_Edge_Ambiguous;
      elsif not Edge.Is_Legal (Info.Edge_Status) then
         return Final_RM_Overload_Type_Edge_Blocker;
      end if;

      if Needs_Access_AST (Info.Kind)
        and then Info.Access_AST_Status = Access_AST.Access_Definition_AST_Not_Checked
      then
         return Final_RM_Missing_Access_Definition_AST;
      elsif Access_AST_Is_Blocker (Info.Access_AST_Status) then
         return Final_RM_Access_Definition_AST_Blocker;
      end if;

      if Needs_Generic_Backmap (Info.Kind)
        and then Info.Generic_Backmap_Status = Backmap.Generic_Backmap_Not_Checked
      then
         return Final_RM_Missing_Generic_Backmap;
      elsif Backmap.Is_Overload_Error (Info.Generic_Backmap_Status) then
         return Final_RM_Generic_Backmap_Overload_Blocker;
      elsif Backmap.Is_Mapping_Error (Info.Generic_Backmap_Status) then
         return Final_RM_Generic_Backmap_Mapping_Blocker;
      elsif Backmap_Is_Blocker (Info.Generic_Backmap_Status) then
         return Final_RM_Generic_Backmap_Blocker;
      elsif Info.Generic_Backmap_Status = Backmap.Generic_Backmap_Indeterminate then
         return Final_RM_Generic_Backmap_Indeterminate;
      end if;

      if not Info.Profile_Matched then
         return Final_RM_Access_Subprogram_Profile_Mismatch;
      elsif not Info.Null_Exclusion_Matched then
         return Final_RM_Access_Subprogram_Null_Exclusion_Mismatch;
      elsif not Info.Convention_Matched then
         return Final_RM_Access_Subprogram_Convention_Mismatch;
      elsif not Info.Primitive_Visible then
         return Final_RM_Prefixed_Call_Primitive_Not_Visible;
      elsif Info.Prefixed_Call_Ambiguous then
         return Final_RM_Prefixed_Call_Ambiguous;
      elsif Info.Class_Wide_Controlling_Count > 1 then
         return Final_RM_Class_Wide_Controlling_Result_Ambiguous;
      elsif Info.Inherited_Primitive_Hiding_Count > 1 then
         return Final_RM_Inherited_Private_Extension_Hiding_Ambiguous;
      elsif Info.Universal_Root_Tie_Count > 1 then
         return Final_RM_Universal_Fixed_Root_Numeric_Ambiguous;
      elsif Info.Dispatching_Inherited_Tie_Count > 1 then
         return Final_RM_Dispatching_Inherited_Operation_Ambiguous;
      elsif Info.Cross_Unit_View_Barrier then
         return Final_RM_Cross_Unit_View_Barrier;
      end if;

      case Info.Kind is
         when Final_RM_Prefixed_Call_Primitive =>
            return Final_RM_Legal_Prefixed_Call_Primitive_Selected;
         when Final_RM_Access_Subprogram_Profile =>
            return Final_RM_Legal_Access_Subprogram_Profile_Accepted;
         when Final_RM_Access_Subprogram_Null_Exclusion =>
            return Final_RM_Legal_Access_Subprogram_Null_Exclusion_Accepted;
         when Final_RM_Access_Subprogram_Convention =>
            return Final_RM_Legal_Access_Subprogram_Convention_Accepted;
         when Final_RM_Class_Wide_Controlling_Result =>
            return Final_RM_Legal_Class_Wide_Controlling_Result_Accepted;
         when Final_RM_Inherited_Private_Extension_Primitive =>
            return Final_RM_Legal_Inherited_Private_Extension_Primitive_Selected;
         when Final_RM_Universal_Fixed_Root_Numeric_Mixed_Mode =>
            return Final_RM_Legal_Universal_Fixed_Root_Numeric_Selected;
         when Final_RM_Dispatching_Inherited_Operation =>
            return Final_RM_Legal_Dispatching_Inherited_Operation_Selected;
         when Final_RM_Generic_Formal_Subprogram_Instance =>
            return Final_RM_Legal_Generic_Formal_Subprogram_Instance_Accepted;
         when Final_RM_Nested_Generic_Prefixed_Call =>
            return Final_RM_Legal_Nested_Generic_Prefixed_Call_Accepted;
         when Final_RM_Unknown =>
            return Final_RM_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Final_RM_Status) return String is
   begin
      case Status is
         when Final_RM_Legal_Prefixed_Call_Primitive_Selected =>
            return "prefixed-call primitive visibility accepted by final RM overload consumer";
         when Final_RM_Legal_Access_Subprogram_Profile_Accepted =>
            return "access-to-subprogram profile accepted by final RM overload consumer";
         when Final_RM_Legal_Access_Subprogram_Null_Exclusion_Accepted =>
            return "access-to-subprogram null-exclusion evidence accepted";
         when Final_RM_Legal_Access_Subprogram_Convention_Accepted =>
            return "access-to-subprogram convention evidence accepted";
         when Final_RM_Legal_Class_Wide_Controlling_Result_Accepted =>
            return "class-wide controlling-result overload evidence accepted";
         when Final_RM_Legal_Inherited_Private_Extension_Primitive_Selected =>
            return "inherited/private-extension primitive selected after hiding checks";
         when Final_RM_Legal_Universal_Fixed_Root_Numeric_Selected =>
            return "universal fixed/root numeric mixed-mode preference accepted";
         when Final_RM_Legal_Dispatching_Inherited_Operation_Selected =>
            return "dispatching inherited operation selected with final evidence";
         when Final_RM_Legal_Generic_Formal_Subprogram_Instance_Accepted =>
            return "generic formal subprogram instance overload accepted with backmapping";
         when Final_RM_Legal_Nested_Generic_Prefixed_Call_Accepted =>
            return "nested generic prefixed call accepted with replay backmapping";
         when Final_RM_Missing_Overload_Type_Edge =>
            return "overload/type edge precision evidence is missing";
         when Final_RM_Overload_Type_Edge_Blocker =>
            return "overload/type edge precision blocks final RM overload conclusion";
         when Final_RM_Overload_Type_Edge_Ambiguous =>
            return "overload/type edge precision remains ambiguous";
         when Final_RM_Missing_Access_Definition_AST =>
            return "access-definition AST repair evidence is missing";
         when Final_RM_Access_Definition_AST_Blocker =>
            return "access-definition AST repair blocks final RM overload conclusion";
         when Final_RM_Access_Subprogram_Null_Exclusion_Mismatch =>
            return "access-to-subprogram null-exclusion mismatch";
         when Final_RM_Access_Subprogram_Convention_Mismatch =>
            return "access-to-subprogram convention mismatch";
         when Final_RM_Access_Subprogram_Profile_Mismatch =>
            return "access-to-subprogram profile mismatch";
         when Final_RM_Prefixed_Call_Primitive_Not_Visible =>
            return "prefixed-call primitive is not visible";
         when Final_RM_Prefixed_Call_Ambiguous =>
            return "prefixed-call primitive selection is ambiguous";
         when Final_RM_Class_Wide_Controlling_Result_Ambiguous =>
            return "class-wide controlling-result overload remains ambiguous";
         when Final_RM_Inherited_Private_Extension_Hiding_Ambiguous =>
            return "inherited/private-extension primitive hiding remains ambiguous";
         when Final_RM_Universal_Fixed_Root_Numeric_Ambiguous =>
            return "universal fixed/root numeric mixed-mode overload remains ambiguous";
         when Final_RM_Dispatching_Inherited_Operation_Ambiguous =>
            return "dispatching inherited operation overload remains ambiguous";
         when Final_RM_Missing_Generic_Backmap =>
            return "generic source/instance backmapping evidence is missing";
         when Final_RM_Generic_Backmap_Blocker =>
            return "generic source/instance backmapping blocks final RM overload conclusion";
         when Final_RM_Generic_Backmap_Overload_Blocker =>
            return "generic backmapping preserves overload blocker";
         when Final_RM_Generic_Backmap_Mapping_Blocker =>
            return "generic source/instance mapping blocker preserved";
         when Final_RM_Generic_Backmap_Indeterminate =>
            return "generic source/instance backmapping is indeterminate";
         when Final_RM_Cross_Unit_View_Barrier =>
            return "cross-unit view barrier blocks final RM overload conclusion";
         when Final_RM_Multiple_Blockers =>
            return "multiple final RM overload/type blockers are present";
         when Final_RM_Indeterminate =>
            return "final RM overload/type consumer state is indeterminate";
         when Final_RM_Not_Checked =>
            return "final RM overload/type consumer not checked";
      end case;
   end Message_For;

   function Row_Fingerprint (Info : Final_RM_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Edge_Row) + 1);
      H := Mix (H, Edge.Overload_Type_Edge_Status'Pos (Info.Edge_Status) + 1);
      H := Mix (H, Natural (Info.Access_AST_Row) + 1);
      H := Mix (H, Access_AST.Access_Definition_AST_Repair_Status'Pos (Info.Access_AST_Status) + 1);
      H := Mix (H, Natural (Info.Generic_Backmap_Row) + 1);
      H := Mix (H, Backmap.Generic_Backmap_Status'Pos (Info.Generic_Backmap_Status) + 1);
      H := Mix (H, Info.Candidate_Count + 1);
      H := Mix (H, Info.Selected_Candidate_Count + 1);
      H := Mix (H, Info.Blocker_Count + 1);
      H := Mix (H, Length (Info.Designator) + 1);
      H := Mix (H, Length (Info.Prefix_Type_Name) + 1);
      H := Mix (H, Length (Info.Expected_Type_Name) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Make_Row (Info : Final_RM_Context_Info) return Final_RM_Info is
      Status : constant Final_RM_Status := Classify (Info);
      Row : Final_RM_Info;
   begin
      Row.Id := Info.Id;
      Row.Context := Info.Id;
      Row.Kind := Info.Kind;
      Row.Node := Info.Node;
      Row.Status := Status;
      Row.Designator := Info.Designator;
      Row.Prefix_Type_Name := Info.Prefix_Type_Name;
      Row.Expected_Type_Name := Info.Expected_Type_Name;
      Row.Selected_Profile := Info.Selected_Profile;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String ("Pass1189 final RM overload/type consumer row");
      Row.Edge_Row := Info.Edge_Row;
      Row.Edge_Status := Info.Edge_Status;
      Row.Access_AST_Row := Info.Access_AST_Row;
      Row.Access_AST_Status := Info.Access_AST_Status;
      Row.Generic_Backmap_Row := Info.Generic_Backmap_Row;
      Row.Generic_Backmap_Status := Info.Generic_Backmap_Status;
      Row.Candidate_Count := Info.Candidate_Count;
      Row.Selected_Candidate_Count := Info.Selected_Candidate_Count;
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      if not Is_Legal (Status) then
         Row.Blocker_Count := 1;
      end if;
      if Status = Final_RM_Multiple_Blockers then
         Row.Blocker_Count := 2;
      end if;
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Final_RM_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Final_RM_Context_Model;
      Info  : Final_RM_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Kind_Slot (Info.Kind) + Natural (Info.Node) + Info.Source_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Final_RM_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Final_RM_Context_Model;
      Index : Positive) return Final_RM_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Final_RM_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Is_Legal (Status : Final_RM_Status) return Boolean is
   begin
      return Status in
        Final_RM_Legal_Prefixed_Call_Primitive_Selected |
        Final_RM_Legal_Access_Subprogram_Profile_Accepted |
        Final_RM_Legal_Access_Subprogram_Null_Exclusion_Accepted |
        Final_RM_Legal_Access_Subprogram_Convention_Accepted |
        Final_RM_Legal_Class_Wide_Controlling_Result_Accepted |
        Final_RM_Legal_Inherited_Private_Extension_Primitive_Selected |
        Final_RM_Legal_Universal_Fixed_Root_Numeric_Selected |
        Final_RM_Legal_Dispatching_Inherited_Operation_Selected |
        Final_RM_Legal_Generic_Formal_Subprogram_Instance_Accepted |
        Final_RM_Legal_Nested_Generic_Prefixed_Call_Accepted;
   end Is_Legal;

   function Is_Ambiguous (Status : Final_RM_Status) return Boolean is
   begin
      return Status in
        Final_RM_Overload_Type_Edge_Ambiguous |
        Final_RM_Prefixed_Call_Ambiguous |
        Final_RM_Class_Wide_Controlling_Result_Ambiguous |
        Final_RM_Inherited_Private_Extension_Hiding_Ambiguous |
        Final_RM_Universal_Fixed_Root_Numeric_Ambiguous |
        Final_RM_Dispatching_Inherited_Operation_Ambiguous;
   end Is_Ambiguous;

   function Has_Error (Info : Final_RM_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status);
   end Has_Error;

   function Build (Contexts : Final_RM_Context_Model) return Final_RM_Model is
      Model : Final_RM_Model;
   begin
      for Index in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            Row : constant Final_RM_Info := Make_Row (Contexts.Contexts.Element (Index));
         begin
            Model.Items.Append (Row);
            if Is_Legal (Row.Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            else
               Model.Blocker_Total := Model.Blocker_Total + 1;
            end if;
            if Is_Ambiguous (Row.Status) then
               Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
            end if;
            if Row.Status in Final_RM_Missing_Access_Definition_AST | Final_RM_Access_Definition_AST_Blocker then
               Model.Access_AST_Blocker_Total := Model.Access_AST_Blocker_Total + 1;
            end if;
            if Row.Status in
              Final_RM_Missing_Generic_Backmap |
              Final_RM_Generic_Backmap_Blocker |
              Final_RM_Generic_Backmap_Overload_Blocker |
              Final_RM_Generic_Backmap_Mapping_Blocker |
              Final_RM_Generic_Backmap_Indeterminate
            then
               Model.Generic_Backmap_Blocker_Total := Model.Generic_Backmap_Blocker_Total + 1;
            end if;
            if Row.Status = Final_RM_Cross_Unit_View_Barrier then
               Model.Cross_Unit_Barrier_Total := Model.Cross_Unit_Barrier_Total + 1;
            end if;
            if Row.Status in Final_RM_Indeterminate | Final_RM_Generic_Backmap_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint + 1);
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Final_RM_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Final_RM_Model;
      Index : Positive) return Final_RM_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Final_RM_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_RM_Info is
   begin
      for Index in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (Index).Node = Node then
            return Model.Items.Element (Index);
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Final_RM_Model;
      Status : Final_RM_Status) return Final_RM_Result_Set is
      Results : Final_RM_Result_Set;
   begin
      for Index in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (Index).Status = Status then
            Results.Items.Append (Model.Items.Element (Index));
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Model.Items.Element (Index).Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Final_RM_Model;
      Kind  : Final_RM_Context_Kind) return Final_RM_Result_Set is
      Results : Final_RM_Result_Set;
   begin
      for Index in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (Index).Kind = Kind then
            Results.Items.Append (Model.Items.Element (Index));
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Model.Items.Element (Index).Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Designator
     (Model      : Final_RM_Model;
      Designator : String) return Final_RM_Result_Set is
      Results : Final_RM_Result_Set;
   begin
      for Index in 1 .. Natural (Model.Items.Length) loop
         if To_String (Model.Items.Element (Index).Designator) = Designator then
            Results.Items.Append (Model.Items.Element (Index));
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Model.Items.Element (Index).Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Designator;

   function Result_Count (Results : Final_RM_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Final_RM_Result_Set;
      Index   : Positive) return Final_RM_Info is
   begin
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Final_RM_Model;
      Status : Final_RM_Status) return Natural is
      Count : Natural := 0;
   begin
      for Index in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (Index).Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Final_RM_Model;
      Kind  : Final_RM_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Index in 1 .. Natural (Model.Items.Length) loop
         if Model.Items.Element (Index).Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Final_RM_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Blocker_Count (Model : Final_RM_Model) return Natural is
   begin
      return Model.Blocker_Total;
   end Blocker_Count;

   function Ambiguous_Count (Model : Final_RM_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Count;

   function Access_AST_Blocker_Count (Model : Final_RM_Model) return Natural is
   begin
      return Model.Access_AST_Blocker_Total;
   end Access_AST_Blocker_Count;

   function Generic_Backmap_Blocker_Count (Model : Final_RM_Model) return Natural is
   begin
      return Model.Generic_Backmap_Blocker_Total;
   end Generic_Backmap_Blocker_Count;

   function Cross_Unit_Barrier_Count (Model : Final_RM_Model) return Natural is
   begin
      return Model.Cross_Unit_Barrier_Total;
   end Cross_Unit_Barrier_Count;

   function Indeterminate_Count (Model : Final_RM_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Final_RM_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
