with Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Focus_Management;
with Editor.Navigation;
with Editor.Outline;
with Editor.Outline_Extractor;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Outline_Commands is

   use Ada.Strings.Unbounded;
   use Editor.Commands;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Outline.Outline_Source_Class;

   function Outline_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;
   begin
      case Id is
         when Command_Refresh_Outline =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Active_Buffer);
            end if;
            return Editor.Commands.Available;

         when Command_Clear_Outline =>
            if not Editor.Outline.Has_Items (S.Outline) then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Outline_Items);
            end if;
            return Editor.Commands.Available;

         when Command_Show_Outline =>
            if Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
              and then Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Outline_Feature
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_Feature_Panel_Already_Shown);
            end if;
            return Editor.Commands.Available;

         when Command_Focus_Outline =>
            if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_Feature_Panel_Hidden);
            elsif Editor.Feature_Panel.Is_Focused (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_Feature_Panel_Already_Focused);
            end if;
            return Editor.Commands.Available;

         when Command_Open_Selected_Outline_Item =>
            if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_Feature_Panel_Hidden);
            elsif not Editor.Executor.Has_Selected_Outline_Activation_Target (S) then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Outline_Item_Selected);
            end if;
            return Editor.Commands.Available;

         when Command_Next_Outline_Symbol
            | Command_Previous_Outline_Symbol =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Active_Buffer);
            elsif Editor.Outline.Source_Class (S.Outline) /=
              Editor.Outline.Extracted_Outline
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Outline_Items);
            elsif Editor.Outline.Last_Extraction_Source_Class (S.Outline) =
              Editor.Outline.Stale_Extracted_Outline
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Message_Outline_Stale_Result_Discarded);
            else
               declare
                  Row    : Natural := 0;
                  Col    : Natural := 0;
                  Target : Natural := 0;
                  Buffer : constant Natural := Active_Feature_Buffer_Token (S);
               begin
                  if Buffer = 0 then
                     return Editor.Commands.Unavailable
                       (Editor.Outline.Reason_No_Active_Buffer);
                  elsif not Editor.Outline.Outline_Buffer_Identity_Matches
                    (S.Outline, Buffer)
                  then
                     return Editor.Commands.Unavailable
                       (Editor.Outline.Reason_Outline_Belongs_To_Another_Buffer);
                  end if;

                  Editor.Navigation.Line_Column_For_Index
                    (S, Natural (Safe_Caret (S)), Row, Col);
                  if Id = Command_Next_Outline_Symbol then
                     Target := Editor.Outline.Find_Next_Symbol_For_Position
                       (S.Outline, Buffer, Row + 1, Col + 1, True);
                  else
                     Target := Editor.Outline.Find_Previous_Symbol_For_Position
                       (S.Outline, Buffer, Row + 1, Col + 1, True);
                  end if;

                  if Target = 0 then
                     return Editor.Commands.Unavailable
                       (Editor.Outline.Reason_No_Outline_Items);
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_Select_Current_Outline_Symbol
            | Command_Reveal_Current_Outline_Symbol =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Active_Buffer);
            elsif Editor.Outline.Source_Class (S.Outline) /=
              Editor.Outline.Extracted_Outline
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Outline_Items);
            elsif Editor.Outline.Last_Extraction_Source_Class (S.Outline) =
              Editor.Outline.Stale_Extracted_Outline
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Message_Outline_Stale_Result_Discarded);
            else
               declare
                  Row    : Natural := 0;
                  Col    : Natural := 0;
                  Target : Natural := 0;
                  Buffer : constant Natural := Active_Feature_Buffer_Token (S);
               begin
                  if Buffer = 0 then
                     return Editor.Commands.Unavailable
                       (Editor.Outline.Reason_No_Active_Buffer);
                  elsif not Editor.Outline.Outline_Buffer_Identity_Matches
                    (S.Outline, Buffer)
                  then
                     return Editor.Commands.Unavailable
                       (Editor.Outline.Reason_Outline_Belongs_To_Another_Buffer);
                  end if;

                  Editor.Navigation.Line_Column_For_Index
                    (S, Natural (Safe_Caret (S)), Row, Col);
                  Target := Editor.Outline.Find_Current_Symbol_For_Cursor
                    (S.Outline, Buffer, Row + 1, Col + 1);

                  if Target = 0 then
                     return Editor.Commands.Unavailable
                       (Editor.Outline.Message_Outline_No_Current_Symbol);
                  elsif Editor.Outline.Visible_Row_For_Outline_Row
                    (S.Outline, Target) = 0
                  then
                     return Editor.Commands.Unavailable
                       (Editor.Outline.Message_Outline_No_Matching_Symbols);
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_Select_Next_Outline_Item
            | Command_Select_Previous_Outline_Item =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Active_Buffer);
            elsif Editor.Outline.Source_Class (S.Outline) /=
              Editor.Outline.Extracted_Outline
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Outline_Items);
            elsif Editor.Outline.Last_Extraction_Source_Class (S.Outline) =
              Editor.Outline.Stale_Extracted_Outline
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Message_Outline_Stale_Result_Discarded);
            elsif not Editor.Outline.Outline_Buffer_Identity_Matches
              (S.Outline, Active_Feature_Buffer_Token (S))
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_Outline_Belongs_To_Another_Buffer);
            elsif not Editor.Outline.Has_Selectable_Filter_Match (S.Outline) then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Message_Outline_No_Matching_Symbols);
            end if;
            return Editor.Commands.Available;

         when Command_Focus_Outline_Filter
            | Command_Filter_Outline
            | Command_Toggle_Outline_Filter
            | Command_Outline_Filter_History_Previous
            | Command_Outline_Filter_History_Next =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Active_Buffer);
            elsif Editor.Outline.Source_Class (S.Outline) /=
              Editor.Outline.Extracted_Outline
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Outline_Items);
            elsif Editor.Outline.Last_Extraction_Source_Class (S.Outline) =
              Editor.Outline.Stale_Extracted_Outline
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Message_Outline_Stale_Result_Discarded);
            elsif not Editor.Outline.Outline_Buffer_Identity_Matches
              (S.Outline, Active_Feature_Buffer_Token (S))
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_Outline_Belongs_To_Another_Buffer);
            end if;
            return Editor.Commands.Available;

         when Command_Clear_Outline_Filter
            | Command_Clear_Outline_Filter_History =>
            if Editor.Outline.Source_Class (S.Outline) /=
              Editor.Outline.Extracted_Outline
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Outline_Items);
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not an outline command");
      end case;
   end Outline_Command_Availability;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Info;

   function Active_Feature_Buffer_Token
     (S : Editor.State.State_Type) return Natural
      renames Editor.Executor.Active_Feature_Buffer_Token;

   function Safe_Caret
     (S : Editor.State.State_Type) return Editor.Cursors.Cursor_Index
      renames Editor.Executor.Safe_Caret;

   function Feature_Target_Position_Is_Valid
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return Boolean
      renames Editor.Executor.Feature_Target_Position_Is_Valid;

   function Focus_Feature_Target_Buffer
     (S             : in out Editor.State.State_Type;
      Target_Buffer : Natural) return Boolean
      renames Editor.Executor.Focus_Feature_Target_Buffer;

   procedure Apply_Feature_Target_Handoff
     (S             : in out Editor.State.State_Type;
      Target_Row    : Natural;
      Target_Column : Natural)
      renames Editor.Executor.Apply_Feature_Target_Handoff;

   procedure Sync_Current_Outline_Symbol_From_Caret
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Sync_Current_Outline_Symbol_From_Caret;

   function Executed
     (Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
      renames Editor.Command_Execution.Executed;

   function No_Op
     (Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
      renames Editor.Command_Execution.No_Op;

   procedure Report_Target_Unavailable
     (S : in out Editor.State.State_Type)
   is
   begin
      Report_Info (S, "Navigation target unavailable.");
   end Report_Target_Unavailable;

   function Execute_Refresh_Outline
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      declare
         Request_Token : constant Natural :=
           Editor.Outline.Next_Request_Token (S.Outline);
         Text : constant String := Editor.State.Current_Text (S);
         Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
           Editor.Outline_Extractor.Make_Snapshot
             (Text                 => Text,
              Buffer_Label         =>
                (if S.File_Info.Has_Path
                 then To_String (S.File_Info.Path)
                 else To_String (S.File_Info.Display_Name)),
              Active_Buffer_Token  => Active_Feature_Buffer_Token (S),
              Buffer_Revision      => Editor.State.Current_Buffer_Revision (S),
              Lifecycle_Generation =>
                Editor.State.Current_Lifecycle_Generation (S),
              Request_Token        => Request_Token);
         Extract_Result : Editor.Outline_Extractor.Extraction_Result;
      begin
         if Editor.Feature_Panel.Has_Selection (S.Feature_Panel) then
            declare
               Mapped_Selected : constant Natural :=
                 Editor.Outline.Map_Panel_Row_To_Outline_Row
                   (S.Outline, S.Feature_Panel,
                    Editor.Feature_Panel.Selected_Row (S.Feature_Panel));
            begin
               Editor.Outline.Select_Item (S.Outline, Mapped_Selected);
            end;
         else
            Editor.Outline.Select_Item (S.Outline, 0);
         end if;

         Editor.Outline.Begin_Extraction
           (S.Outline, Editor.Outline_Extractor.Identity (Snapshot));
         Extract_Result := Editor.Outline_Extractor.Extract (Snapshot);

         case Editor.Outline_Extractor.Status (Extract_Result) is
            when Editor.Outline_Extractor.Extraction_Ok =>
               Editor.Outline_Extractor.Apply_To_Outline
                 (Extract_Result, S.Outline);
               declare
                  Cursor_Row : Natural := 0;
                  Cursor_Col : Natural := 0;
               begin
                  Editor.Navigation.Line_Column_For_Index
                    (S, Natural (Safe_Caret (S)), Cursor_Row, Cursor_Col);
                  Editor.Outline.Update_Current_Symbol_For_Cursor
                    (S.Outline, Active_Feature_Buffer_Token (S),
                     Cursor_Row + 1, Cursor_Col + 1);
               end;
               Editor.Feature_Panel.Forget_Feature_View_State
                 (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
               Editor.Outline.Set_Rows_From_Outline
                 (S.Outline, S.Feature_Panel);
               Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
               Report_Info (S, Editor.Outline.Message_Outline_Refreshed);
               Editor.Render_Cache.Invalidate_All;
               return Executed (Id);

            when Editor.Outline_Extractor.Extraction_Unavailable =>
               Editor.Outline_Extractor.Apply_To_Outline
                 (Extract_Result, S.Outline);
               Editor.Outline.Clear_Current_Symbol (S.Outline);
               Editor.Feature_Panel.Forget_Feature_View_State
                 (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
               Editor.Outline.Set_Rows_From_Outline
                 (S.Outline, S.Feature_Panel);
               Report_Info (S, Editor.Outline.Message_Outline_Unsupported_Buffer);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);

            when Editor.Outline_Extractor.Extraction_Failed =>
               Editor.Outline_Extractor.Apply_To_Outline
                 (Extract_Result, S.Outline);
               Editor.Outline.Clear_Current_Symbol (S.Outline);
               Editor.Feature_Panel.Forget_Feature_View_State
                 (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
               Editor.Outline.Set_Rows_From_Outline
                 (S.Outline, S.Feature_Panel);
               Report_Info (S, Editor.Outline.Message_Outline_Refresh_Failed);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Failed (Id);
         end case;
      end;
   end Execute_Refresh_Outline;

   function Execute_Refresh_Outline_Project_Index
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Indexed_Files   : Natural;
      Indexed_Symbols : Natural;
      Skipped_Files   : Natural;
      Read_Errors     : Natural;
   begin
      Editor.Executor.Refresh_Project_Language_Index
        (S,
         Build_Semantics    => False,
         Indexed_File_Count => Indexed_Files,
         Indexed_Symbols    => Indexed_Symbols,
         Skipped_File_Count => Skipped_Files,
         Read_Error_Count   => Read_Errors);
      Report_Info
        (S,
         "Language project index refreshed: " &
         Natural'Image (Indexed_Files) & " files, " &
         Natural'Image (Indexed_Symbols) & " symbols, " &
         Natural'Image (Skipped_Files) & " skipped, " &
         Natural'Image (Read_Errors) & " read errors.");
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Refresh_Outline_Project_Index;

   function Execute_Clear_Outline
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      if not Editor.Outline.Has_Items (S.Outline) then
         return No_Op (Id);
      end if;
      Editor.Outline.Clear (S.Outline);
      Editor.Feature_Panel.Forget_Feature_View_State
        (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
      Editor.Feature_Panel.Clear_Rows (S.Feature_Panel);
      Report_Info (S, Editor.Outline.Message_Outline_Cleared);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Clear_Outline;

   function Execute_Show_Outline
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      if not Editor.State.Has_Active_Buffer (S) then
         Editor.Outline.Mark_No_Active_Buffer (S.Outline);
         Editor.Feature_Panel.Forget_Feature_View_State
           (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
      end if;
      if not Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Outline_Feature)
      then
         return No_Op (Id);
      end if;
      Report_Info (S, Editor.Outline.Message_Outline_Shown);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Show_Outline;

   function Execute_Focus_Outline
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Outline);
      Report_Info (S, Editor.Outline.Message_Outline_Focused);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Focus_Outline;

   function Execute_Open_Selected_Outline_Item
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      if Editor.Outline.Selected_Index (S.Outline) > 0
        and then
          (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) /=
             Editor.Feature_Panel.Outline_Feature
           or else not Editor.Feature_Panel.Has_Selection (S.Feature_Panel))
      then
         Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      end if;

      declare
         Row : constant Natural :=
           Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
         Outline_Row : constant Natural :=
           Editor.Outline.Map_Panel_Row_To_Outline_Row
             (S.Outline, S.Feature_Panel, Row);
      begin
         if Outline_Row = 0 then
            Report_Info (S, Editor.Outline.Message_Outline_Item_Has_No_Target);
            Editor.Render_Cache.Invalidate_All;
            return No_Op (Id);
         end if;

         declare
            Target_Buffer : constant Natural :=
              Editor.Outline.Item_Buffer_Token
                (S.Outline, Positive (Outline_Row));
            Target_Line : constant Natural :=
              Editor.Outline.Item_Line (S.Outline, Positive (Outline_Row));
            Target_Column_One_Based : constant Natural :=
              Editor.Outline.Item_Column (S.Outline, Positive (Outline_Row));
         begin
            if not Editor.Outline.Validate_Outline_Row_For_Activation
                (S.Outline, S.Feature_Panel, Row, Target_Buffer)
              or else not Feature_Target_Position_Is_Valid
                (S, Target_Buffer, Target_Line, Target_Column_One_Based)
            then
               Report_Info (S, Editor.Outline.Message_Outline_Item_Has_No_Target);
               Editor.Render_Cache.Invalidate_All;
               return No_Op (Id);
            end if;

            if not Focus_Feature_Target_Buffer (S, Target_Buffer) then
               Report_Info (S, Editor.Outline.Message_Outline_Item_Has_No_Target);
               Editor.Render_Cache.Invalidate_All;
               return No_Op (Id);
            end if;

            Apply_Feature_Target_Handoff
              (S, Target_Line - 1, Target_Column_One_Based - 1);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);
         end;
      end;
   end Execute_Open_Selected_Outline_Item;

   function Execute_Reveal_Current_Outline_Symbol
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Target : Natural := 0;
   begin
      if not Editor.State.Has_Active_Buffer (S)
        or else Active_Feature_Buffer_Token (S) = 0
      then
         Report_Info (S, Editor.Outline.Reason_No_Active_Buffer);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      elsif Editor.Outline.Source_Class (S.Outline) /=
        Editor.Outline.Extracted_Outline
      then
         Report_Info (S, Editor.Outline.Reason_No_Outline_Items);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      elsif Editor.Outline.Last_Extraction_Source_Class (S.Outline) =
        Editor.Outline.Stale_Extracted_Outline
      then
         Report_Info (S, Editor.Outline.Message_Outline_Stale_Result_Discarded);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      elsif not Editor.Outline.Outline_Buffer_Identity_Matches
        (S.Outline, Active_Feature_Buffer_Token (S))
      then
         Report_Info (S, Editor.Outline.Reason_Outline_Belongs_To_Another_Buffer);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      end if;

      Sync_Current_Outline_Symbol_From_Caret (S);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);

      if not Editor.Outline.Can_Reveal_Current_Symbol
        (S.Outline, S.Feature_Panel, Active_Feature_Buffer_Token (S))
      then
         Editor.Feature_Panel.Clear_Reveal_Request (S.Feature_Panel);
         Report_Info (S, Editor.Outline.Message_Outline_No_Current_Symbol);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      end if;

      Target := Editor.Outline.Visible_Row_For_Outline_Row
        (S.Outline, Editor.Outline.Current_Symbol_Index (S.Outline));
      Editor.Outline.Select_Item
        (S.Outline, Editor.Outline.Current_Symbol_Index (S.Outline));
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Target);
      Editor.Feature_Panel.Request_Reveal_Row (S.Feature_Panel, Target);
      Report_Info (S, Editor.Outline.Message_Outline_Current_Symbol_Revealed);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Reveal_Current_Outline_Symbol;

   function Outline_Source_Is_Current
     (S : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Boolean
   is
   begin
      if Editor.Outline.Last_Extraction_Source_Class (S.Outline) =
        Editor.Outline.Stale_Extracted_Outline
      then
         Report_Info (S, Editor.Outline.Message_Outline_Stale_Result_Discarded);
         Editor.Render_Cache.Invalidate_All;
         return False;
      elsif not Editor.Outline.Outline_Buffer_Identity_Matches
        (S.Outline, Active_Feature_Buffer_Token (S))
      then
         Report_Info (S, Editor.Outline.Reason_Outline_Belongs_To_Another_Buffer);
         Editor.Render_Cache.Invalidate_All;
         return False;
      else
         return True;
      end if;
   end Outline_Source_Is_Current;

   function Execute_Outline_Symbol_Navigation
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Row    : Natural := 0;
      Col    : Natural := 0;
      Target : Natural := 0;
      Buffer : constant Natural := Active_Feature_Buffer_Token (S);
   begin
      if Buffer = 0 or else Editor.Outline.Source_Class (S.Outline) /=
        Editor.Outline.Extracted_Outline
      then
         Report_Info (S, Editor.Outline.Message_Outline_No_Symbols);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      elsif not Outline_Source_Is_Current (S, Id) then
         return No_Op (Id);
      end if;

      Editor.Navigation.Line_Column_For_Index
        (S, Natural (Safe_Caret (S)), Row, Col);
      if Id = Editor.Commands.Command_Next_Outline_Symbol then
         Target := Editor.Outline.Find_Next_Symbol_For_Position
           (S.Outline, Buffer, Row + 1, Col + 1, True);
      else
         Target := Editor.Outline.Find_Previous_Symbol_For_Position
           (S.Outline, Buffer, Row + 1, Col + 1, True);
      end if;

      if Target = 0 then
         Report_Info (S, Editor.Outline.Message_Outline_No_Symbols);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      end if;

      declare
         Target_Buffer : constant Natural :=
           Editor.Outline.Item_Buffer_Token (S.Outline, Positive (Target));
         Target_Line : constant Natural :=
           Editor.Outline.Item_Line (S.Outline, Positive (Target));
         Target_Column_One_Based : constant Natural :=
           Editor.Outline.Item_Column (S.Outline, Positive (Target));
      begin
         if Target_Buffer /= Buffer
           or else not Feature_Target_Position_Is_Valid
             (S, Target_Buffer, Target_Line, Target_Column_One_Based)
         then
            Report_Info (S, Editor.Outline.Message_Outline_Item_Has_No_Target);
            Editor.Render_Cache.Invalidate_All;
            return No_Op (Id);
         end if;

         Editor.Outline.Select_Item (S.Outline, Target);
         Editor.Outline.Set_Current_Symbol_Index (S.Outline, Target);
         Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
         declare
            Visible_Target : constant Natural :=
              Editor.Outline.Visible_Row_For_Outline_Row (S.Outline, Target);
         begin
            if Visible_Target /= 0 then
               Editor.Feature_Panel.Select_Row (S.Feature_Panel, Visible_Target);
               Editor.Feature_Panel.Request_Reveal_Row
                 (S.Feature_Panel, Visible_Target);
            end if;
         end;

         Apply_Feature_Target_Handoff
           (S, Target_Line - 1, Target_Column_One_Based - 1);
         Editor.Render_Cache.Invalidate_All;
         return Executed (Id);
      end;
   end Execute_Outline_Symbol_Navigation;

   function Execute_Select_Current_Outline_Symbol
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Row    : Natural := 0;
      Col    : Natural := 0;
      Target : Natural := 0;
      Buffer : constant Natural := Active_Feature_Buffer_Token (S);
   begin
      if not Editor.State.Has_Active_Buffer (S) or else Buffer = 0 then
         Report_Info (S, Editor.Outline.Reason_No_Active_Buffer);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      elsif Editor.Outline.Source_Class (S.Outline) /=
        Editor.Outline.Extracted_Outline
      then
         Report_Info (S, Editor.Outline.Reason_No_Outline_Items);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      elsif not Outline_Source_Is_Current (S, Id) then
         return No_Op (Id);
      end if;

      Editor.Navigation.Line_Column_For_Index
        (S, Natural (Safe_Caret (S)), Row, Col);
      Target := Editor.Outline.Find_Current_Symbol_For_Cursor
        (S.Outline, Buffer, Row + 1, Col + 1);

      if Target = 0 then
         Report_Info (S, Editor.Outline.Message_Outline_No_Current_Symbol);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      end if;

      if Editor.Outline.Visible_Row_For_Outline_Row (S.Outline, Target) = 0 then
         Report_Info (S, Editor.Outline.Message_Outline_No_Matching_Symbols);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      end if;

      Editor.Outline.Update_Current_Symbol_For_Cursor
        (S.Outline, Buffer, Row + 1, Col + 1);
      Editor.Outline.Select_Item (S.Outline, Target);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      declare
         Visible_Target : constant Natural :=
           Editor.Outline.Visible_Row_For_Outline_Row (S.Outline, Target);
      begin
         Editor.Feature_Panel.Select_Row (S.Feature_Panel, Visible_Target);
         Editor.Feature_Panel.Request_Reveal_Row
           (S.Feature_Panel, Visible_Target);
      end;
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Select_Current_Outline_Symbol;

   function Execute_Select_Outline_Item
     (S    : in out Editor.State.State_Type;
      Id   : Editor.Commands.Command_Id;
      Next : Boolean)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      if not Editor.Outline.Outline_Buffer_Identity_Matches
        (S.Outline, Active_Feature_Buffer_Token (S))
      then
         Report_Info (S, Editor.Outline.Reason_Outline_Belongs_To_Another_Buffer);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Id);
      end if;

      if (if Next
          then Editor.Outline.Select_Next_Selectable (S.Outline)
          else Editor.Outline.Select_Previous_Selectable (S.Outline))
      then
         declare
            Visible_Target : constant Natural :=
              Editor.Outline.Visible_Row_For_Outline_Row
                (S.Outline, Editor.Outline.Selected_Index (S.Outline));
         begin
            Editor.Feature_Panel.Select_Row (S.Feature_Panel, Visible_Target);
            Editor.Feature_Panel.Request_Reveal_Row
              (S.Feature_Panel, Visible_Target);
         end;
         Editor.Render_Cache.Invalidate_All;
         return Executed (Id);
      end if;

      Report_Info (S, Editor.Outline.Message_Outline_Item_Has_No_Target);
      Editor.Render_Cache.Invalidate_All;
      return No_Op (Id);
   end Execute_Select_Outline_Item;

   function Execute_Focus_Outline_Filter
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      if not Outline_Source_Is_Current (S, Id) then
         return No_Op (Id);
      end if;

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Outline_Filter);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Focus_Outline_Filter;

   function Execute_Filter_Outline
     (S   : in out Editor.State.State_Type;
      Id  : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      if not Outline_Source_Is_Current (S, Id) then
         return No_Op (Id);
      end if;

      if Length (Cmd.Text) > 0 then
         Editor.Outline.Apply_Filter (S.Outline, To_String (Cmd.Text));
      else
         Editor.Outline.Apply_Filter (S.Outline, To_String (Cmd.Query));
      end if;
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Filter_Outline;

   function Execute_Clear_Outline_Filter
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      Editor.Outline.Clear_Filter (S.Outline);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Clear_Outline_Filter;

   function Execute_Toggle_Outline_Filter
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      if not Outline_Source_Is_Current (S, Id) then
         return No_Op (Id);
      end if;

      if Editor.Outline.Filter_Input_Is_Active (S.Outline) then
         Editor.Outline.Deactivate_Filter_Input (S.Outline);
      else
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Outline_Filter);
      end if;
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Toggle_Outline_Filter;

   function Execute_Outline_Filter_History
     (S    : in out Editor.State.State_Type;
      Id   : Editor.Commands.Command_Id;
      Next : Boolean)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Changed : Boolean := False;
   begin
      if not Outline_Source_Is_Current (S, Id) then
         return No_Op (Id);
      end if;

      Changed :=
        (if Next
         then Editor.Outline.Select_Next_Filter_History_Entry (S.Outline)
         else Editor.Outline.Select_Previous_Filter_History_Entry (S.Outline));
      if Changed then
         Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
         Editor.Render_Cache.Invalidate_All;
         return Executed (Id);
      end if;
      return No_Op (Id);
   end Execute_Outline_Filter_History;

   function Execute_Clear_Outline_Filter_History
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      Editor.Outline.Clear_Filter_History (S.Outline);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Id);
   end Execute_Clear_Outline_Filter_History;

   function Execute_Outline_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Editor.Commands.Command_Refresh_Outline =>
            return Execute_Refresh_Outline (S, Id);
         when Editor.Commands.Command_Refresh_Outline_Project_Index =>
            return Execute_Refresh_Outline_Project_Index (S, Id);
         when Editor.Commands.Command_Clear_Outline =>
            return Execute_Clear_Outline (S, Id);
         when Editor.Commands.Command_Show_Outline =>
            return Execute_Show_Outline (S, Id);
         when Editor.Commands.Command_Focus_Outline =>
            return Execute_Focus_Outline (S, Id);
         when Editor.Commands.Command_Open_Selected_Outline_Item =>
            return Execute_Open_Selected_Outline_Item (S, Id);
         when Editor.Commands.Command_Reveal_Current_Outline_Symbol =>
            return Execute_Reveal_Current_Outline_Symbol (S, Id);
         when Editor.Commands.Command_Next_Outline_Symbol =>
            return Execute_Outline_Symbol_Navigation (S, Id);
         when Editor.Commands.Command_Previous_Outline_Symbol =>
            return Execute_Outline_Symbol_Navigation (S, Id);
         when Editor.Commands.Command_Select_Current_Outline_Symbol =>
            return Execute_Select_Current_Outline_Symbol (S, Id);
         when Editor.Commands.Command_Select_Next_Outline_Item =>
            return Execute_Select_Outline_Item (S, Id, Next => True);
         when Editor.Commands.Command_Select_Previous_Outline_Item =>
            return Execute_Select_Outline_Item (S, Id, Next => False);
         when Editor.Commands.Command_Focus_Outline_Filter =>
            return Execute_Focus_Outline_Filter (S, Id);
         when Editor.Commands.Command_Filter_Outline =>
            return Execute_Filter_Outline (S, Id, Cmd);
         when Editor.Commands.Command_Toggle_Outline_Filter =>
            return Execute_Toggle_Outline_Filter (S, Id);
         when Editor.Commands.Command_Clear_Outline_Filter =>
            return Execute_Clear_Outline_Filter (S, Id);
         when Editor.Commands.Command_Outline_Filter_History_Previous =>
            return Execute_Outline_Filter_History (S, Id, Next => False);
         when Editor.Commands.Command_Outline_Filter_History_Next =>
            return Execute_Outline_Filter_History (S, Id, Next => True);
         when Editor.Commands.Command_Clear_Outline_Filter_History =>
            return Execute_Clear_Outline_Filter_History (S, Id);
         when others =>
            return No_Op (Id);
      end case;
   end Execute_Outline_Command;

   procedure Execute_Outline_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      procedure Run (Id : Editor.Commands.Command_Id);

      procedure Run (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Execute_Outline_Command (S, Id, Cmd);
         pragma Unreferenced (Result);
      begin
         null;
      end Run;
   begin
      case Cmd.Kind is
         when Refresh_Outline =>
            Run (Command_Refresh_Outline);

         when Refresh_Outline_Project_Index =>
            Run (Command_Refresh_Outline_Project_Index);

         when Clear_Outline =>
            Run (Command_Clear_Outline);

         when Show_Outline =>
            Run (Command_Show_Outline);

         when Focus_Outline =>
            Run (Command_Focus_Outline);

         when Open_Selected_Outline_Item =>
            Run (Command_Open_Selected_Outline_Item);

         when Select_Current_Outline_Symbol =>
            Run (Command_Select_Current_Outline_Symbol);

         when Reveal_Current_Outline_Symbol =>
            Run (Command_Reveal_Current_Outline_Symbol);

         when Next_Outline_Symbol =>
            Run (Command_Next_Outline_Symbol);

         when Previous_Outline_Symbol =>
            Run (Command_Previous_Outline_Symbol);

         when Select_Next_Outline_Item =>
            Run (Command_Select_Next_Outline_Item);

         when Select_Previous_Outline_Item =>
            Run (Command_Select_Previous_Outline_Item);

         when Focus_Outline_Filter =>
            Run (Command_Focus_Outline_Filter);

         when Filter_Outline =>
            Run (Command_Filter_Outline);

         when Clear_Outline_Filter =>
            Run (Command_Clear_Outline_Filter);

         when Toggle_Outline_Filter =>
            Run (Command_Toggle_Outline_Filter);

         when Outline_Filter_History_Previous =>
            Run (Command_Outline_Filter_History_Previous);

         when Outline_Filter_History_Next =>
            Run (Command_Outline_Filter_History_Next);

         when Clear_Outline_Filter_History =>
            Run (Command_Clear_Outline_Filter_History);

         when others =>
            raise Program_Error with "unsupported outline command kind";
      end case;
   end Execute_Outline_Kind;

   function Execute_Outline_Row_Click
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Mapped : constant Natural :=
        Editor.Outline.Map_Panel_Row_To_Outline_Row
          (S.Outline, S.Feature_Panel, Row, Expected_Panel_Generation);
   begin
      if Mapped = 0
        or else not Editor.Outline.Validate_Outline_Row_For_Selection
          (S.Outline, S.Feature_Panel, Row, Expected_Panel_Generation)
      then
         Report_Target_Unavailable (S);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Open_Selected_Outline_Item);
      end if;

      Editor.Outline.Select_Item (S.Outline, Mapped);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Row);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Editor.Commands.Command_Open_Selected_Outline_Item);
   end Execute_Outline_Row_Click;

   function Execute_Outline_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Mapped : constant Natural :=
        Editor.Outline.Map_Panel_Row_To_Outline_Row
          (S.Outline, S.Feature_Panel, Row, Expected_Panel_Generation);
      Click_Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      if Mapped = 0
        or else not Editor.Outline.Validate_Outline_Row_For_Activation
          (S.Outline, S.Feature_Panel, Row,
           Editor.Outline.Item_Buffer_Token (S.Outline, Positive (Mapped)),
           Expected_Panel_Generation)
      then
         Report_Target_Unavailable (S);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Open_Selected_Outline_Item);
      end if;

      Click_Result := Execute_Outline_Row_Click
        (S, Row, Expected_Panel_Generation);
      if Click_Result.Status /= Editor.Command_Execution.Command_Executed then
         return Click_Result;
      end if;

      return Execute_Open_Selected_Outline_Item
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
   end Execute_Outline_Row_Activation;

end Editor.Executor.Outline_Commands;
