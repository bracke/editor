with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.Commands;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.File_Open_Commands;
with Editor.Executor;
with Editor.Focus_Management;
with Editor.Render_Cache;
with Editor.Overlay_Focus;
with Editor.State;

package body Editor.Executor.Buffer_Switcher_Surface_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Kind;

   procedure Recompute_Buffer_Switcher
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher;

   procedure Normalize_Switcher_Preview_Target
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target;

   function Active_Buffer_Switcher_Overlay
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay)
        and then Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher);
   end Active_Buffer_Switcher_Overlay;

   function Selected_Row
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row
   is
   begin
      return Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer
        (S, Found);
   end Selected_Row;

   function Any_Pinned_Buffer return Boolean is
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
   begin
      for I in 1 .. Editor.Buffers.Count (Registry) loop
         if Editor.Buffers.Summary_At (Registry, I).Is_Pinned then
            return True;
         end if;
      end loop;
      return False;
   end Any_Pinned_Buffer;

   function Any_Labelled_Buffer return Boolean is
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
   begin
      for I in 1 .. Editor.Buffers.Count (Registry) loop
         if Editor.Buffers.Summary_At (Registry, I).Has_Label then
            return True;
         end if;
      end loop;
      return False;
   end Any_Labelled_Buffer;

   function Any_Noted_Buffer return Boolean is
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
   begin
      for I in 1 .. Editor.Buffers.Count (Registry) loop
         if Editor.Buffers.Summary_At (Registry, I).Has_Note then
            return True;
         end if;
      end loop;
      return False;
   end Any_Noted_Buffer;

   function Selected_Open_Buffer_Availability
     (S : Editor.State.State_Type) return Editor.Commands.Command_Availability
   is
      Found : Boolean := False;
      Row   : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      if not Active_Buffer_Switcher_Overlay (S) then
         return Editor.Commands.Unavailable ("No active overlay");
      end if;

      Row := Selected_Row (S, Found);
      if not Found then
         return Editor.Commands.Unavailable ("No buffer selected");
      elsif Row.Id = Editor.Buffers.No_Buffer then
         return Editor.Commands.Unavailable ("Selected row is not a buffer");
      elsif not Editor.Buffers.Global_Contains (Row.Id) then
         return Editor.Commands.Unavailable ("Selected buffer is no longer open");
      end if;

      return Editor.Commands.Available;
   end Selected_Open_Buffer_Availability;

   function Buffer_Switcher_Surface_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Open_Buffer_Switcher =>
            return Editor.Commands.Available;

         when Editor.Commands.Command_Close_Buffer_Switcher =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Accept_Buffer_Switcher =>
            return Selected_Open_Buffer_Availability (S);

         when Editor.Commands.Command_Buffer_Switcher_Next_Result
            | Editor.Commands.Command_Buffer_Switcher_Previous_Result =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
               return Editor.Commands.Unavailable ("No buffer selected");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Filter_Clear =>
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Filter_Pinned =>
            if not Any_Pinned_Buffer then
               return Editor.Commands.Unavailable ("No matching open buffers");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Filter_Group =>
            if not Editor.Buffers.Global_Has_Buffer_Groups then
               return Editor.Commands.Unavailable ("No buffer groups");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Filter_Label =>
            if not Any_Labelled_Buffer then
               return Editor.Commands.Unavailable ("No buffer labels");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Filter_Noted =>
            if not Any_Noted_Buffer then
               return Editor.Commands.Unavailable ("No matching open buffers");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Sort_Default
            | Editor.Commands.Command_Buffer_Switcher_Sort_Recent
            | Editor.Commands.Command_Buffer_Switcher_Sort_Name
            | Editor.Commands.Command_Buffer_Switcher_Sort_Pinned
            | Editor.Commands.Command_Buffer_Switcher_Sort_Group
            | Editor.Commands.Command_Buffer_Switcher_Sort_Label
            | Editor.Commands.Command_Buffer_Switcher_Sort_Next
            | Editor.Commands.Command_Buffer_Switcher_Sort_Previous =>
            if Editor.Buffers.Global_Count = 0
              and then not Editor.State.Has_Active_Buffer (S)
            then
               return Editor.Commands.Unavailable ("No open buffers");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Not a buffer switcher surface command");
      end case;
   end Buffer_Switcher_Surface_Command_Availability;

   procedure Report_Buffer_Switcher_Count
     (S : in out Editor.State.State_Type)
   is
      Count  : constant Natural :=
        Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher);
      Filter : constant String :=
        Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher);
      Metadata_Filter : constant String :=
        Editor.Buffer_Switcher.Metadata_Filter_Description (S.Buffer_Switcher);
   begin
      if Count = 0 then
         if Metadata_Filter'Length > 0 then
            Editor.Executor.Report_Info (S, "No matching open buffers");
         elsif Filter'Length = 0 then
            Editor.Executor.Report_Info (S, "Buffers: 0 open");
         else
            Editor.Executor.Report_Info (S, "Buffers: no matches");
         end if;
      elsif Metadata_Filter'Length > 0 then
         Editor.Executor.Report_Info (S, "Switcher filter: " & Metadata_Filter);
      elsif Filter'Length = 0 then
         Editor.Executor.Report_Info (S, "Buffers:" & Natural'Image (Count) & " open");
      elsif Count = 1 then
         Editor.Executor.Report_Info (S, "Buffers: 1 match");
      else
         Editor.Executor.Report_Info (S, "Buffers:" & Natural'Image (Count) & " matches");
      end if;
   end Report_Buffer_Switcher_Count;

   procedure Execute_Open_Buffer_Switcher
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Clear_Restore_Feedback_Current (S);
      Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Buffer_Switcher_Overlay);
      Recompute_Buffer_Switcher (S);
      Report_Buffer_Switcher_Count (S);
   end Execute_Open_Buffer_Switcher;

   procedure Execute_Close_Buffer_Switcher
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay
           (S, Editor.Overlay_Focus.Dismiss_Command);
      else
         Editor.Buffer_Switcher.Close (S.Buffer_Switcher);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Close_Buffer_Switcher;

   procedure Execute_Accept_Buffer_Switcher
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
   begin
      Editor.Executor.Clear_Restore_Feedback_Current (S);
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Editor.Executor.Report_Warning (S, "Buffer switcher: no buffer selected");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Buffers.Global_Contains (Row.Id) then
         Editor.Executor.Report_Warning (S, "Selected buffer is no longer open");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay
           (S, Editor.Overlay_Focus.Dismiss_Accept);
      else
         Editor.Buffer_Switcher.Close (S.Buffer_Switcher);
      end if;
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Row.Id, Emit_Feedback => False);
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Executor.Report_Info (S, "Buffer switched");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Accept_Buffer_Switcher;

   procedure Execute_Buffer_Switcher_Next_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Move_Selection_Down (S.Buffer_Switcher);
      Normalize_Switcher_Preview_Target (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Next_Result;

   procedure Execute_Buffer_Switcher_Previous_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Move_Selection_Up (S.Buffer_Switcher);
      Normalize_Switcher_Preview_Target (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Previous_Result;

   procedure Execute_Buffer_Switcher_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Editor.Buffer_Switcher.Insert_Text (S.Buffer_Switcher, Text);
         Recompute_Buffer_Switcher (S);
         Report_Buffer_Switcher_Count (S);
      end if;
   end Execute_Buffer_Switcher_Insert_Text;

   procedure Execute_Buffer_Switcher_Backspace
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Editor.Buffer_Switcher.Backspace (S.Buffer_Switcher);
         Recompute_Buffer_Switcher (S);
         Report_Buffer_Switcher_Count (S);
      end if;
   end Execute_Buffer_Switcher_Backspace;

   procedure Execute_Buffer_Switcher_Delete_Forward
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Editor.Buffer_Switcher.Delete_Forward (S.Buffer_Switcher);
         Recompute_Buffer_Switcher (S);
         Report_Buffer_Switcher_Count (S);
      end if;
   end Execute_Buffer_Switcher_Delete_Forward;

   procedure Execute_Buffer_Switcher_Filter_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Clear_Metadata_Filter (S.Buffer_Switcher);
      if Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Recompute_Buffer_Switcher (S);
      else
         Editor.Render_Cache.Invalidate_All;
      end if;
      Editor.Executor.Report_Success (S, "Switcher filter cleared");
   end Execute_Buffer_Switcher_Filter_Clear;

   procedure Execute_Buffer_Switcher_Filter_Pinned
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Set_Pinned_Filter (S.Buffer_Switcher);
      if not Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Editor.Executor.Clear_Restore_Feedback_Current (S);
         Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Buffer_Switcher_Overlay);
      end if;
      Recompute_Buffer_Switcher (S);
      Report_Buffer_Switcher_Count (S);
   end Execute_Buffer_Switcher_Filter_Pinned;

   procedure Execute_Buffer_Switcher_Filter_Group
     (S    : in out Editor.State.State_Type;
      Name : String)
   is
      Group : constant String := Editor.Executor.Trimmed_Command_Text (Name);
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      if not Editor.Buffers.Global_Has_Buffer_Groups then
         Editor.Executor.Report_Info (S, "No buffer groups");
      elsif Group'Length = 0 then
         Editor.Executor.Report_Info (S, "No group name");
      else
         Editor.Buffer_Switcher.Set_Group_Filter (S.Buffer_Switcher, Group);
         if not Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
            Editor.Executor.Clear_Restore_Feedback_Current (S);
            Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Buffer_Switcher_Overlay);
         end if;
         Recompute_Buffer_Switcher (S);
         Report_Buffer_Switcher_Count (S);
      end if;
   end Execute_Buffer_Switcher_Filter_Group;

   procedure Execute_Buffer_Switcher_Filter_Label
     (S     : in out Editor.State.State_Type;
      Label : String)
   is
      Text : constant String := Editor.Executor.Trimmed_Command_Text (Label);

      function Any_Labelled_Buffer return Boolean is
         Registry : constant Editor.Buffers.Buffer_Registry := Editor.Buffers.Global_Registry_For_UI;
      begin
         for I in 1 .. Editor.Buffers.Count (Registry) loop
            if Editor.Buffers.Summary_At (Registry, I).Has_Label then
               return True;
            end if;
         end loop;
         return False;
      end Any_Labelled_Buffer;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      if not Any_Labelled_Buffer then
         Editor.Executor.Report_Info (S, "No buffer labels");
      elsif Text'Length = 0 then
         Editor.Executor.Report_Info (S, "No buffer label");
      else
         Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, Text);
         if not Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
            Editor.Executor.Clear_Restore_Feedback_Current (S);
            Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Buffer_Switcher_Overlay);
         end if;
         Recompute_Buffer_Switcher (S);
         Report_Buffer_Switcher_Count (S);
      end if;
   end Execute_Buffer_Switcher_Filter_Label;

   procedure Execute_Buffer_Switcher_Filter_Noted
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Set_Noted_Filter (S.Buffer_Switcher);
      if not Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Editor.Executor.Clear_Restore_Feedback_Current (S);
         Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Buffer_Switcher_Overlay);
      end if;
      Recompute_Buffer_Switcher (S);
      Report_Buffer_Switcher_Count (S);
   end Execute_Buffer_Switcher_Filter_Noted;

   procedure Report_Buffer_Switcher_Sort
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Report_Info
        (S, "Switcher sort: " &
         Editor.Buffer_Switcher.Sort_Mode_Description (S.Buffer_Switcher));
   end Report_Buffer_Switcher_Sort;

   procedure Execute_Buffer_Switcher_Sort
     (S    : in out Editor.State.State_Type;
      Mode : Editor.Buffer_Switcher.Switcher_Sort_Mode)
   is
   begin
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Mode);
      if Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Recompute_Buffer_Switcher (S);
      else
         Editor.Render_Cache.Invalidate_All;
      end if;
      Report_Buffer_Switcher_Sort (S);
   end Execute_Buffer_Switcher_Sort;

   procedure Execute_Buffer_Switcher_Sort_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Next_Sort_Mode (S.Buffer_Switcher);
      if Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Recompute_Buffer_Switcher (S);
      else
         Editor.Render_Cache.Invalidate_All;
      end if;
      Report_Buffer_Switcher_Sort (S);
   end Execute_Buffer_Switcher_Sort_Next;

   procedure Execute_Buffer_Switcher_Sort_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Previous_Sort_Mode (S.Buffer_Switcher);
      if Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Recompute_Buffer_Switcher (S);
      else
         Editor.Render_Cache.Invalidate_All;
      end if;
      Report_Buffer_Switcher_Sort (S);
   end Execute_Buffer_Switcher_Sort_Previous;

   procedure Execute_Buffer_Switcher_Surface_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind;
      Text : String)
   is
   begin
      case Kind is
         when Editor.Commands.Open_Buffer_Switcher =>
            Execute_Open_Buffer_Switcher (S);
         when Editor.Commands.Close_Buffer_Switcher =>
            Execute_Close_Buffer_Switcher (S);
         when Editor.Commands.Accept_Buffer_Switcher =>
            Execute_Accept_Buffer_Switcher (S);
         when Editor.Commands.Buffer_Switcher_Next_Result =>
            Execute_Buffer_Switcher_Next_Result (S);
         when Editor.Commands.Buffer_Switcher_Previous_Result =>
            Execute_Buffer_Switcher_Previous_Result (S);
         when Editor.Commands.Buffer_Switcher_Insert_Text =>
            Execute_Buffer_Switcher_Insert_Text (S, Text);
         when Editor.Commands.Buffer_Switcher_Backspace =>
            Execute_Buffer_Switcher_Backspace (S);
         when Editor.Commands.Buffer_Switcher_Delete_Forward =>
            Execute_Buffer_Switcher_Delete_Forward (S);
         when Editor.Commands.Buffer_Switcher_Filter_Clear =>
            Execute_Buffer_Switcher_Filter_Clear (S);
         when Editor.Commands.Buffer_Switcher_Filter_Pinned =>
            Execute_Buffer_Switcher_Filter_Pinned (S);
         when Editor.Commands.Buffer_Switcher_Filter_Group =>
            Execute_Buffer_Switcher_Filter_Group (S, Text);
         when Editor.Commands.Buffer_Switcher_Filter_Label =>
            Execute_Buffer_Switcher_Filter_Label (S, Text);
         when Editor.Commands.Buffer_Switcher_Filter_Noted =>
            Execute_Buffer_Switcher_Filter_Noted (S);
         when Editor.Commands.Buffer_Switcher_Sort_Default =>
            Execute_Buffer_Switcher_Sort
              (S, Editor.Buffer_Switcher.Default_Sort);
         when Editor.Commands.Buffer_Switcher_Sort_Recent =>
            Execute_Buffer_Switcher_Sort
              (S, Editor.Buffer_Switcher.Recent_Sort);
         when Editor.Commands.Buffer_Switcher_Sort_Name =>
            Execute_Buffer_Switcher_Sort
              (S, Editor.Buffer_Switcher.Name_Sort);
         when Editor.Commands.Buffer_Switcher_Sort_Pinned =>
            Execute_Buffer_Switcher_Sort
              (S, Editor.Buffer_Switcher.Pinned_Sort);
         when Editor.Commands.Buffer_Switcher_Sort_Group =>
            Execute_Buffer_Switcher_Sort
              (S, Editor.Buffer_Switcher.Group_Sort);
         when Editor.Commands.Buffer_Switcher_Sort_Label =>
            Execute_Buffer_Switcher_Sort
              (S, Editor.Buffer_Switcher.Label_Sort);
         when Editor.Commands.Buffer_Switcher_Sort_Next =>
            Execute_Buffer_Switcher_Sort_Next (S);
         when Editor.Commands.Buffer_Switcher_Sort_Previous =>
            Execute_Buffer_Switcher_Sort_Previous (S);
         when others =>
            null;
      end case;
   end Execute_Buffer_Switcher_Surface_Kind;

end Editor.Executor.Buffer_Switcher_Surface_Commands;
