with Editor.Cursors;
with Editor.Diagnostics;
with Editor.Dirty_Lines;
with Editor.Executor.Bookmark_Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Navigation;
with Editor.Folding;
with Editor.Gutter;
with Editor.Gutter_Markers;
with Editor.Input_Bridge.Pointer_Routing;
with Editor.Input_Bridge.Pointer_State;
with Editor.Layout;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Gutter_Pointer_Handlers is

   use type Editor.Commands.Command_Kind;
   use type Editor.Gutter.Gutter_Zone;

   function Is_Gutter_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Pointer_Routing.Is_Gutter_Pointer_Command (Kind);
   end Is_Gutter_Pointer_Command;

   function Is_Gutter_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Pointer_Routing.Is_Gutter_Drag_Command (Kind);
   end Is_Gutter_Drag_Command;

   procedure Select_Gutter_Line_Range
     (S          : in out Editor.State.State_Type;
      Anchor_Row : Natural;
      Target_Row : Natural)
   is
      New_Caret : Editor.Cursors.Cursor_Index := 0;
      New_Preferred_Column : Natural := 0;
   begin
      Editor.Executor.Navigation.Select_Line_Range
        (S                    => S,
         Anchor_Row           => Anchor_Row,
         Target_Row           => Target_Row,
         New_Caret            => New_Caret,
         New_Preferred_Column => New_Preferred_Column);
      S.Preferred_Column := New_Preferred_Column;
      Editor.Render_Cache.Invalidate_All;
   end Select_Gutter_Line_Range;

   procedure Execute_Gutter_Marker_Action
     (S      : in out Editor.State.State_Type;
      Row    : Natural;
      Action : Editor.Gutter_Markers.Gutter_Marker_Action)
   is
   begin
      case Action is
         when Editor.Gutter_Markers.No_Marker_Action =>
            null;

         when Editor.Gutter_Markers.Toggle_Bookmark_Action =>
            Editor.Executor.Bookmark_Commands.Execute_Toggle_Bookmark_At_Row
              (S, Row);

         when Editor.Gutter_Markers.Select_Diagnostic_Action =>
            Editor.Executor.Diagnostics_Commands.Execute_Jump_To_Diagnostic_On_Row
              (S, Row);

         when Editor.Gutter_Markers.Acknowledge_Dirty_Line_Action =>
            null;
      end case;
   end Execute_Gutter_Marker_Action;

   procedure Add_Effective_Dirty_Marker
     (S       : Editor.State.State_Type;
      Markers : in out Editor.Gutter_Markers.Gutter_Marker_State;
      Row     : Natural)
   is
   begin
      case Editor.Dirty_Lines.Kind_For_Row (S.Dirty_Lines, Row) is
         when Editor.Dirty_Lines.Added_Line =>
            Editor.Gutter_Markers.Add_Marker
              (Markers, Row, Editor.Gutter_Markers.Added_Line_Marker);
         when Editor.Dirty_Lines.Modified_Line =>
            Editor.Gutter_Markers.Add_Marker
              (Markers, Row, Editor.Gutter_Markers.Modified_Line_Marker);
         when Editor.Dirty_Lines.Clean_Line =>
            null;
      end case;
   end Add_Effective_Dirty_Marker;

   procedure Add_Diagnostic_Markers
     (S       : Editor.State.State_Type;
      Markers : in out Editor.Gutter_Markers.Gutter_Marker_State;
      Row     : Natural)
   is
   begin
      for D of S.Diagnostics loop
         if Editor.State.Row_For_Index (S, D.Start_Index) = Row then
            case D.Severity is
               when Editor.Diagnostics.Error =>
                  Editor.Gutter_Markers.Add_Marker
                    (Markers, Row,
                     Editor.Gutter_Markers.Diagnostic_Error_Marker);
               when Editor.Diagnostics.Warning =>
                  Editor.Gutter_Markers.Add_Marker
                    (Markers, Row,
                     Editor.Gutter_Markers.Diagnostic_Warning_Marker);
               when others =>
                  null;
            end case;
         end if;
      end loop;
   end Add_Diagnostic_Markers;

   procedure Refresh_Gutter_Marker_Hover
     (S   : in out Editor.State.State_Type;
      Row : Natural)
   is
      Effective_Markers : Editor.Gutter_Markers.Gutter_Marker_State :=
        S.Gutter_Markers;
      Still_Found : Boolean := False;
      Still_Kind  : Editor.Gutter_Markers.Gutter_Marker_Kind;
   begin
      Add_Effective_Dirty_Marker (S, Effective_Markers, Row);
      Add_Diagnostic_Markers (S, Effective_Markers, Row);

      Still_Kind := Editor.Gutter_Markers.Dominant_Marker_For_Row
        (State => Effective_Markers,
         Row   => Row,
         Found => Still_Found);

      if Still_Found then
         Editor.State.Set_Gutter_Marker_Hover
           (S, Row, Still_Kind);
      else
         Editor.State.Clear_Gutter_Marker_Hover (S);
      end if;
   end Refresh_Gutter_Marker_Hover;

   function Handle_Gutter_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
      Layout    : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Doc_Count : constant Natural := Editor.State.Line_Count (S);
      Hit       : Editor.Gutter.Gutter_Hit_Result;
      Zone      : Editor.Gutter.Gutter_Zone;
      Doc_Row   : Natural := 0;
      Found     : Boolean := False;
      Kind      : Editor.Gutter_Markers.Gutter_Marker_Kind;
      Action    : Editor.Gutter_Markers.Gutter_Marker_Action :=
        Editor.Gutter_Markers.No_Marker_Action;
   begin
      if not Is_Gutter_Pointer_Command (Cmd.Kind) then
         Pointer_State.Clear_Gutter_Line_Selection;
         Editor.State.Clear_Gutter_Marker_Hover (S);
         return False;
      end if;

      if Is_Gutter_Drag_Command (Cmd.Kind) and then Pointer_State.Gutter_Line_Selection_Active then
         Doc_Row := Editor.Gutter.Document_Row_For_Y
           (Y             => Cmd.Click_Y,
            Layout        => Layout,
            Scroll_Y      => Editor.View.Scroll_Y,
            Folding       => S.Folding,
            Document_Rows => Doc_Count);
         Select_Gutter_Line_Range
           (S, Pointer_State.Gutter_Line_Selection_Anchor_Row, Doc_Row);
         return True;
      end if;

      Pointer_State.Clear_Gutter_Line_Selection;

      Hit := Editor.Gutter.Hit_Test_Result
        (X               => Cmd.Click_X,
         Y               => Cmd.Click_Y,
         Layout          => Layout,
         Line_Count      => Doc_Count,
         Viewport_Height => Editor.View.Viewport_Height,
         Scroll_Y        => Editor.View.Scroll_Y,
         Folding         => S.Folding);
      Zone := Hit.Zone;
      Doc_Row := Hit.Row;

      if Zone = Editor.Gutter.Marker_Zone then

         declare
            Effective_Markers : Editor.Gutter_Markers.Gutter_Marker_State :=
              S.Gutter_Markers;
         begin
            Add_Effective_Dirty_Marker (S, Effective_Markers, Doc_Row);
            Add_Diagnostic_Markers (S, Effective_Markers, Doc_Row);

            Kind := Editor.Gutter_Markers.Dominant_Marker_For_Row
              (State => Effective_Markers,
               Row   => Doc_Row,
               Found => Found);
         end;

         if Found then
            Editor.State.Set_Gutter_Marker_Hover (S, Doc_Row, Kind);
         else
            Editor.State.Clear_Gutter_Marker_Hover (S);
         end if;

         if Cmd.Kind = Editor.Commands.Pointer_Hover then
            return True;
         end if;
      else
         Editor.State.Clear_Gutter_Marker_Hover (S);

         if Cmd.Kind = Editor.Commands.Pointer_Hover then
            return True;
         end if;
      end if;

      case Zone is
         when Editor.Gutter.Outside_Gutter =>
            return False;

         when Editor.Gutter.Marker_Zone =>
            if Cmd.Kind /= Editor.Commands.Move_To_Point then
               return True;
            end if;

            if Found then
               Action := Editor.Gutter_Markers.Action_For_Marker (Kind);
            else
               Action := Editor.Gutter_Markers.Toggle_Bookmark_Action;
            end if;

            Execute_Gutter_Marker_Action (S, Doc_Row, Action);
            Refresh_Gutter_Marker_Hover (S, Doc_Row);

            Pointer_State.Clear_Gutter_Line_Selection;
            return True;

         when Editor.Gutter.Fold_Marker_Zone =>
            if Cmd.Kind = Editor.Commands.Move_To_Point
              and then Editor.Folding.Has_Fold_Start (S.Folding, Doc_Row)
            then
               Editor.Folding.Toggle_Fold_At_Row (S.Folding, Doc_Row);
               Editor.Render_Cache.Invalidate_All;
               return True;
            end if;

            if Cmd.Kind /= Editor.Commands.Move_To_Point then
               return True;
            end if;

            Pointer_State.Start_Gutter_Line_Selection (Doc_Row);
            Select_Gutter_Line_Range (S, Doc_Row, Doc_Row);
            return True;

         when Editor.Gutter.Line_Number_Zone =>
            if Cmd.Kind /= Editor.Commands.Move_To_Point
              and then Cmd.Kind /= Editor.Commands.Select_Line_At_Point
            then
               return True;
            end if;

            Pointer_State.Start_Gutter_Line_Selection (Doc_Row);
            Select_Gutter_Line_Range (S, Doc_Row, Doc_Row);
            return True;
      end case;
   end Handle_Gutter_Pointer;

end Editor.Input_Bridge.Gutter_Pointer_Handlers;
