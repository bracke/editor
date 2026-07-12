with Editor.Cursors;
with Editor.Commands;
with Editor.Diagnostics;
with Editor.Folding;
with Editor.Layout;
with Editor.Navigation;
with Editor.Executor;
with Editor.Executor.Shared_Services;
with Editor.Render_Cache;
with Editor.State;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.View;

package body Editor.Executor.Diagnostics_Navigation_Commands is

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Warning;

   procedure Execute_Jump_To_Diagnostic
     (S     : in out Editor.State.State_Type;
      Index : Editor.Diagnostics.Diagnostic_Index)
   is
      Target             : constant Editor.Diagnostics.Diagnostic_Target :=
        Editor.Diagnostics.Target_For_Diagnostic (S.Diagnostics, Index);
      Target_Index       : Editor.Cursors.Cursor_Index := 0;
      Viewport_Rows      : Natural := 1;
      Desired            : Natural := 0;
      Visible_Target_Row : Natural := 0;
      Visible_Found      : Boolean := False;
      Visible_Count      : Natural := 1;
      Layout             : constant Editor.Layout.Layout_Config :=
        Editor.Layout.Current;
   begin
      if not Target.Found then
         Report_Warning (S, "Diagnostic not found");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Folding.Expand_To_Reveal_Row (S.Folding, Target.Row);

      Target_Index := Editor.Cursors.Cursor_Index
        (Editor.Navigation.Index_For_Line_Column
           (S, Target.Row, Target.Column));

      Visible_Target_Row := Editor.Folding.Document_Row_To_Visible_Row
        (S.Folding, Target.Row, Visible_Found);
      if not Visible_Found then
         Visible_Target_Row := Target.Row;
      end if;

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => Target_Index,
           Anchor                => Target_Index,
           Virtual_Column        => 0,
           Anchor_Virtual_Column => 0));
      S.Preferred_Column := Target.Column;
      S.Active_Diagnostic := (Has_Active => True, Index => Index);

      Viewport_Rows := Natural'Max
        (1,
         Editor.Layout.Visible_Row_Count
           (Layout, Editor.View.Viewport_Height));
      Visible_Count := Natural'Max
        (1,
         Editor.Folding.Visible_Row_Count
           (S.Folding, Editor.State.Line_Count (S)));

      if Visible_Target_Row > Viewport_Rows / 2 then
         Desired := Visible_Target_Row - Viewport_Rows / 2;
      else
         Desired := 0;
      end if;

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Visible_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired);
      Editor.View.Clear_User_Scroll_Override;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Jump_To_Diagnostic;

   procedure Execute_Next_Diagnostic
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Row   : Natural := 0;
      Col   : Natural := 0;
      Index : Editor.Diagnostics.Diagnostic_Index :=
        Editor.Diagnostics.No_Diagnostic;
   begin
      if Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0 then
         Report_Info (S, "No diagnostics");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if S.Active_Diagnostic.Has_Active
        and then Editor.Diagnostics.Is_Valid_Diagnostic_Index
          (S.Diagnostics, S.Active_Diagnostic.Index)
      then
         declare
            Target : constant Editor.Diagnostics.Diagnostic_Target :=
              Editor.Diagnostics.Target_For_Diagnostic
                (S.Diagnostics, S.Active_Diagnostic.Index);
         begin
            Row := Target.Row;
            Col := Target.Column;
         end;
      else
         Editor.State.Row_Col_For_Index
           (S, Editor.Executor.Safe_Caret (S), Row, Col);
      end if;

      Index := Editor.Diagnostics.Next_Diagnostic_After
        (S.Diagnostics, Row, Col, True, Found);
      if Found then
         Execute_Jump_To_Diagnostic (S, Index);
      else
         Report_Info (S, "No diagnostics");
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Next_Diagnostic;

   procedure Execute_Previous_Diagnostic
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Row   : Natural := 0;
      Col   : Natural := 0;
      Index : Editor.Diagnostics.Diagnostic_Index :=
        Editor.Diagnostics.No_Diagnostic;
   begin
      if Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0 then
         Report_Info (S, "No diagnostics");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if S.Active_Diagnostic.Has_Active
        and then Editor.Diagnostics.Is_Valid_Diagnostic_Index
          (S.Diagnostics, S.Active_Diagnostic.Index)
      then
         declare
            Target : constant Editor.Diagnostics.Diagnostic_Target :=
              Editor.Diagnostics.Target_For_Diagnostic
                (S.Diagnostics, S.Active_Diagnostic.Index);
         begin
            Row := Target.Row;
            Col := Target.Column;
         end;
      else
         Editor.State.Row_Col_For_Index
           (S, Editor.Executor.Safe_Caret (S), Row, Col);
      end if;

      Index := Editor.Diagnostics.Previous_Diagnostic_Before
        (S.Diagnostics, Row, Col, True, Found);
      if Found then
         Execute_Jump_To_Diagnostic (S, Index);
      else
         Report_Info (S, "No diagnostics");
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Previous_Diagnostic;

   procedure Execute_Jump_To_Diagnostic_On_Row
     (S   : in out Editor.State.State_Type;
      Row : Natural)
   is
      Found : Boolean := False;
      Index : constant Editor.Diagnostics.Diagnostic_Index :=
        Editor.Diagnostics.Dominant_Diagnostic_On_Row
          (S.Diagnostics, Row, Found);
   begin
      if Found then
         Execute_Jump_To_Diagnostic (S, Index);
      else
         Report_Warning (S, "Diagnostic not found");
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Jump_To_Diagnostic_On_Row;

   function Execute_Mapped_Diagnostic_Activation
     (S          : in out Editor.State.State_Type;
      Mapped     : Natural;
      Row        : Natural := 0;
      Select_Row : Boolean := False)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Target_Buffer : Natural := 0;
      Target_Line   : Natural := 0;
      Target_Column_One_Based : Natural := 0;
      Effective_Target_Column_One_Based : Natural := 1;
      Target_Row    : Natural;
      Target_Column : Natural;
   begin
      if Mapped = 0 then
         Report_Info (S, "Navigation target unavailable.");
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.No_Op
           (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      Target_Buffer := Editor.Feature_Diagnostics.Item_Target_Buffer
        (S.Feature_Diagnostics, Positive (Mapped));
      Target_Line := Editor.Feature_Diagnostics.Item_Target_Line
        (S.Feature_Diagnostics, Positive (Mapped));
      Target_Column_One_Based := Editor.Feature_Diagnostics.Item_Target_Column
        (S.Feature_Diagnostics, Positive (Mapped));
      Effective_Target_Column_One_Based :=
        Natural'Max (1, Target_Column_One_Based);

      if Editor.Feature_Diagnostics.Item_Is_Stale
          (S.Feature_Diagnostics, Positive (Mapped))
      then
         Report_Info (S, Editor.Commands.Reason_Target_Stale);
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.No_Op
           (Editor.Commands.Command_Feature_Panel_Open_Selected);
      elsif not Editor.Feature_Diagnostics.Validate_Diagnostic_Target
          (S.Feature_Diagnostics, Positive (Mapped), Target_Buffer)
        or else not Editor.Executor.Feature_Target_Position_Is_Valid
          (S, Target_Buffer, Target_Line, Effective_Target_Column_One_Based)
      then
         Report_Info
           (S, Editor.Executor.Diagnostic_Availability_Reason
              (S, Mapped, Target_Buffer, Target_Line,
               Effective_Target_Column_One_Based));
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.No_Op
           (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      if not Editor.Executor.Focus_Feature_Target_Buffer
        (S, Target_Buffer)
      then
         Report_Info (S, "Diagnostic target file is unavailable.");
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.No_Op
           (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      Target_Row := Natural'Min
        (Target_Line - 1, Natural'Max (Editor.State.Line_Count (S), 1) - 1);
      Target_Column := Effective_Target_Column_One_Based - 1;
      if Select_Row and then Row /= 0 then
         Editor.Feature_Panel.Select_Row (S.Feature_Panel, Row);
      end if;
      Editor.Executor.Apply_Feature_Target_Handoff
        (S, Target_Row, Target_Column);
      Editor.Render_Cache.Invalidate_All;
      return Editor.Command_Execution.Executed
        (Editor.Commands.Command_Feature_Panel_Open_Selected);
   end Execute_Mapped_Diagnostic_Activation;

   function Execute_Diagnostic_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Mapped : constant Natural :=
        Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
          (S.Feature_Diagnostics, S.Feature_Panel, Row,
           Expected_Panel_Generation);
   begin
      if Row = 0 then
         Report_Info (S, "No selection");
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.No_Op
           (Editor.Commands.Command_Feature_Panel_Open_Selected);
      elsif Mapped = 0 then
         Report_Info (S, "Selected diagnostic is no longer available.");
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.No_Op
           (Editor.Commands.Command_Feature_Panel_Open_Selected);
      elsif not Editor.Feature_Diagnostics.Item_Has_Target
        (S.Feature_Diagnostics, Positive (Mapped))
      then
         declare
            Reason : constant String :=
              Editor.Feature_Diagnostics.Item_Target_Unavailable_Label
                (S.Feature_Diagnostics, Positive (Mapped));
         begin
            if Reason = "No source target" then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Target);
            elsif Reason = "Target file missing or unavailable"
              or else Reason = "Target file missing"
            then
               Report_Info (S, "Target no longer exists.");
            elsif Reason = "Target line unavailable" then
               Report_Info (S, "Target line is unavailable.");
            elsif Reason = Editor.Commands.Reason_Target_Stale then
               Report_Info (S, Editor.Commands.Reason_Target_Stale);
            elsif Reason'Length > 0 then
               Report_Info
                 (S, Reason & (if Reason (Reason'Last) = '.' then "" else "."));
            else
               Report_Info (S, "Navigation target unavailable.");
            end if;
         end;
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.No_Op
           (Editor.Commands.Command_Feature_Panel_Open_Selected);
      elsif not Editor.Feature_Panel.Row_Is_Activatable
        (S.Feature_Panel, Positive (Row))
      then
         Report_Info (S, "Navigation target unavailable.");
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.No_Op
           (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      return Execute_Mapped_Diagnostic_Activation
        (S, Mapped, Row, Select_Row => True);
   end Execute_Diagnostic_Row_Activation;

   function Execute_Diagnostic_Id_Activation
     (S  : in out Editor.State.State_Type;
      Id : Natural)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Mapped : constant Natural :=
        Editor.Feature_Diagnostics.Map_Diagnostic_Id_To_Item
          (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Id (Id));
   begin
      return Execute_Mapped_Diagnostic_Activation
        (S, Mapped, Row => 0, Select_Row => False);
   end Execute_Diagnostic_Id_Activation;

end Editor.Executor.Diagnostics_Navigation_Commands;
