with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Messages;
with Editor.Overlay_Focus;
with Editor.Render_Cache;

package body Editor.Executor.Buffer_Switcher_Mark_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
   use type Editor.Commands.Command_Id;
   use type Editor.Messages.Message_Severity;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Info;

   function Selected_Switcher_Buffer
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row
      renames Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer;

   procedure Normalize_Switcher_Preview_Target
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target;

   procedure Recompute_Buffer_Switcher_After_Selected_Action
     (S              : in out Editor.State.State_Type;
      Preferred_Id   : Editor.Buffers.Buffer_Id;
      Fallback_Index : Natural)
      renames Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher_After_Selected_Action;

   procedure Recompute_Buffer_Switcher_After_Marked_Action
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher_After_Marked_Action;

   function Marked_Open_Count
     (S : Editor.State.State_Type) return Natural
      renames Editor.Executor.Buffer_Switcher_Shared.Marked_Open_Count;

   procedure Report_No_Selected_Switcher_Buffer
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Buffer_Switcher_Shared.Report_No_Selected_Switcher_Buffer;

   function Active_Buffer_Switcher_Overlay
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay)
        and then Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher);
   end Active_Buffer_Switcher_Overlay;

   function Selected_Open_Buffer_Availability
     (S : Editor.State.State_Type) return Editor.Commands.Command_Availability
   is
      Found : Boolean := False;
      Row   : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      if not Active_Buffer_Switcher_Overlay (S) then
         return Editor.Commands.Unavailable ("No active overlay");
      end if;

      Row := Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer
        (S, Found);
      if not Found then
         return Editor.Commands.Unavailable ("No buffer selected");
      elsif Row.Id = Editor.Buffers.No_Buffer then
         return Editor.Commands.Unavailable ("Selected row is not a buffer");
      elsif not Editor.Buffers.Global_Contains (Row.Id) then
         return Editor.Commands.Unavailable ("Selected buffer is no longer open");
      end if;

      return Editor.Commands.Available;
   end Selected_Open_Buffer_Availability;

   function Has_Marked_Open_Buffers
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher)
        and then Editor.Executor.Buffer_Switcher_Shared.Marked_Open_Count (S) > 0;
   end Has_Marked_Open_Buffers;

   function Buffer_Switcher_Mark_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Buffer_Switcher_Mark_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Mark_Set
            | Editor.Commands.Command_Buffer_Switcher_Mark_Clear =>
            return Selected_Open_Buffer_Availability (S);

         when Editor.Commands.Command_Buffer_Switcher_Mark_Clear_All
            | Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked
            | Editor.Commands.Command_Buffer_Switcher_Mark_Pin_Marked
            | Editor.Commands.Command_Buffer_Switcher_Mark_Unpin_Marked
            | Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Metadata
            | Editor.Commands.Command_Buffer_Switcher_Mark_Group_Assign
            | Editor.Commands.Command_Buffer_Switcher_Mark_Group_Clear
            | Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set
            | Editor.Commands.Command_Buffer_Switcher_Mark_Label_Clear
            | Editor.Commands.Command_Buffer_Switcher_Mark_Note_Set
            | Editor.Commands.Command_Buffer_Switcher_Mark_Note_Clear =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Has_Marked_Open_Buffers (S) then
               return Editor.Commands.Unavailable ("No marked buffers");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Mark_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Mark_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Mark_Summary =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Mark_Confirm =>
            if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
              Editor.Buffer_Switcher.No_Pending_Marked_Action
            then
               return Editor.Commands.Unavailable ("No pending marked action");
            elsif Editor.Buffer_Switcher.Pending_Marked_Open_Count
              (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 0
            then
               return Editor.Commands.Unavailable
                 ("No pending marked buffers remain open");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Mark_Cancel =>
            if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
              Editor.Buffer_Switcher.No_Pending_Marked_Action
            then
               return Editor.Commands.Unavailable ("No pending marked action");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Mark_Next
            | Editor.Commands.Command_Buffer_Switcher_Mark_Previous =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
               return Editor.Commands.Unavailable ("No marked buffers");
            end if;
            for I in 1 .. Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) loop
               if Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, I).Is_Marked
               then
                  return Editor.Commands.Available;
               end if;
            end loop;
            return Editor.Commands.Unavailable ("No marked buffers");

         when Editor.Commands.Command_Buffer_Switcher_Mark_Invert_Visible
            | Editor.Commands.Command_Buffer_Switcher_Mark_Visible =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
               return Editor.Commands.Unavailable ("No visible buffers");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Visible =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
               return Editor.Commands.Unavailable ("No visible buffers");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Mark_Pinned =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            for I in 1 .. Editor.Buffers.Global_Count loop
               if Editor.Buffers.Global_Summary_At (I).Is_Pinned then
                  return Editor.Commands.Available;
               end if;
            end loop;
            return Editor.Commands.Unavailable ("No pinned buffers");

         when Editor.Commands.Command_Buffer_Switcher_Mark_Group =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffers.Global_Has_Buffer_Groups then
               return Editor.Commands.Unavailable ("No buffer groups");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Mark_Label =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            for I in 1 .. Editor.Buffers.Global_Count loop
               if Editor.Buffers.Global_Summary_At (I).Has_Label then
                  return Editor.Commands.Available;
               end if;
            end loop;
            return Editor.Commands.Unavailable ("No buffer labels");

         when Editor.Commands.Command_Buffer_Switcher_Mark_Noted =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            for I in 1 .. Editor.Buffers.Global_Count loop
               if Editor.Buffers.Global_Summary_At (I).Has_Note then
                  return Editor.Commands.Available;
               end if;
            end loop;
            return Editor.Commands.Unavailable ("No noted buffers");

         when others =>
            return Editor.Commands.Unavailable
              ("Not a buffer switcher mark command");
      end case;
   end Buffer_Switcher_Mark_Command_Availability;

   function Switcher_Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Switcher_Image;

   function Marked_Open_Id_At
     (S     : Editor.State.State_Type;
      Index : Positive) return Editor.Buffers.Buffer_Id
   is
      Seen : Natural := 0;
      Registry : constant Editor.Buffers.Buffer_Registry := Editor.Buffers.Global_Registry_For_UI;
   begin
      for I in 1 .. Editor.Buffers.Count (Registry) loop
         declare
            Id : constant Editor.Buffers.Buffer_Id := Editor.Buffers.Summary_At (Registry, I).Id;
         begin
            if Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, Id) then
               Seen := Seen + 1;
               if Seen = Index then
                  return Id;
               end if;
            end if;
         end;
      end loop;
      return Editor.Buffers.No_Buffer;
   end Marked_Open_Id_At;

   type Marked_Target_Array is array (Positive range <>) of Editor.Buffers.Buffer_Id;

   procedure Capture_Marked_Open_Targets
     (S        : Editor.State.State_Type;
      Targets  : out Marked_Target_Array;
      Captured : out Natural)
   is
      Count : constant Natural := Marked_Open_Count (S);
   begin
      Captured := 0;
      for I in 1 .. Count loop
         declare
            Id : constant Editor.Buffers.Buffer_Id := Marked_Open_Id_At (S, I);
         begin
            if Id /= Editor.Buffers.No_Buffer then
               Captured := Captured + 1;
               Targets (Captured) := Id;
            end if;
         end;
      end loop;
   end Capture_Marked_Open_Targets;

   procedure Execute_Buffer_Switcher_Mark_Toggle
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Switcher_Buffer (S, Found);
   begin
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Report_No_Selected_Switcher_Buffer (S);
         return;
      end if;
      Editor.Buffer_Switcher.Toggle_Mark (S.Buffer_Switcher, Row.Id);
      if Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, Row.Id) then
         Editor.Executor.Report_Success (S, "Marked " & To_String (Row.Display_Label));
      else
         Editor.Executor.Report_Success (S, "Unmarked " & To_String (Row.Display_Label));
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Toggle;

   procedure Execute_Buffer_Switcher_Mark_Set
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Switcher_Buffer (S, Found);
   begin
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Report_No_Selected_Switcher_Buffer (S);
         return;
      end if;
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Row.Id);
      Editor.Executor.Report_Success (S, "Marked " & To_String (Row.Display_Label));
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Set;

   procedure Execute_Buffer_Switcher_Mark_Clear
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Switcher_Buffer (S, Found);
   begin
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Report_No_Selected_Switcher_Buffer (S);
         return;
      end if;
      Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, Row.Id);
      Editor.Executor.Report_Success (S, "Unmarked " & To_String (Row.Display_Label));
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Clear;

   procedure Execute_Buffer_Switcher_Mark_Clear_All
     (S : in out Editor.State.State_Type)
   is
      Count : constant Natural := Editor.Buffer_Switcher.Marked_Count (S.Buffer_Switcher);
   begin
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
      else
         Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
         Editor.Executor.Report_Success (S, "Cleared " & Switcher_Image (Count) & " marks");
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Clear_All;

   procedure Execute_Buffer_Switcher_Mark_Invert_Visible
     (S : in out Editor.State.State_Type)
   is
      Marked   : Natural := 0;
      Unmarked : Natural := 0;
   begin
      if Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
         Editor.Executor.Report_Info (S, "No visible buffers");
      else
         Editor.Buffer_Switcher.Invert_Visible_Marks (S.Buffer_Switcher, Marked, Unmarked);
         Editor.Executor.Report_Success
           (S, "Marked " & Switcher_Image (Marked) & " visible buffers; unmarked "
            & Switcher_Image (Unmarked) & " visible buffers");
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Invert_Visible;


   procedure Execute_Buffer_Switcher_Mark_Visible
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
   begin
      if Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
         Editor.Executor.Report_Info (S, "No visible buffers");
      else
         Editor.Buffer_Switcher.Mark_Visible_Marks (S.Buffer_Switcher, Count);
         Editor.Executor.Report_Success (S, "Marked " & Switcher_Image (Count) & " visible buffers");
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Visible;

   procedure Execute_Buffer_Switcher_Mark_Clear_Visible
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
   begin
      if Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
         Editor.Executor.Report_Info (S, "No visible buffers");
      else
         Editor.Buffer_Switcher.Clear_Visible_Marks (S.Buffer_Switcher, Count);
         if Count = 0 then
            Editor.Executor.Report_Info (S, "No visible marked buffers");
         else
            Editor.Executor.Report_Success (S, "Cleared marks from " & Switcher_Image (Count) & " visible buffers");
         end if;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Clear_Visible;

   procedure Execute_Buffer_Switcher_Mark_Review_Show
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Show_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      if Editor.Buffer_Switcher.Marked_Count (S.Buffer_Switcher) = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
      else
         Editor.Executor.Report_Success (S, "Marked review shown");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Review_Show;

   procedure Execute_Buffer_Switcher_Mark_Review_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Hide_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Report_Success (S, "Marked review hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Review_Hide;

   procedure Execute_Buffer_Switcher_Mark_Review_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher) then
         Execute_Buffer_Switcher_Mark_Review_Hide (S);
      else
         Execute_Buffer_Switcher_Mark_Review_Show (S);
      end if;
   end Execute_Buffer_Switcher_Mark_Review_Toggle;

   procedure Execute_Buffer_Switcher_Mark_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Select_Next_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Report_Success (S, "Selected next marked buffer");
      else
         Editor.Executor.Report_Info (S, "No marked buffers");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Next;

   procedure Execute_Buffer_Switcher_Mark_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Select_Previous_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Report_Success (S, "Selected previous marked buffer");
      else
         Editor.Executor.Report_Info (S, "No marked buffers");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Previous;

   procedure Execute_Buffer_Switcher_Mark_Summary
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
      else
         Editor.Executor.Report_Info (S, "Marked buffers:" & Natural'Image (Count));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Summary;

   procedure Execute_Buffer_Switcher_Mark_Pinned
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      for I in 1 .. Editor.Buffers.Global_Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary := Editor.Buffers.Global_Summary_At (I);
         begin
            if Summary.Is_Pinned then
               Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Summary.Id);
               Count := Count + 1;
            end if;
         end;
      end loop;
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No pinned buffers");
      else
         Recompute_Buffer_Switcher_After_Marked_Action (S);
         Editor.Executor.Report_Success (S, "Marked " & Switcher_Image (Count) & " pinned buffers");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Pinned;

   procedure Execute_Buffer_Switcher_Mark_Group
     (S    : in out Editor.State.State_Type;
      Name : String)
   is
      Group : constant String := Editor.Executor.Trimmed_Command_Text (Name);
      Has_Groups : Boolean := False;
      Count : Natural := 0;
   begin
      if Group'Length = 0 then
         Editor.Executor.Report_Info (S, "No group name");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      for I in 1 .. Editor.Buffers.Global_Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary := Editor.Buffers.Global_Summary_At (I);
         begin
            if Summary.Has_Group then
               Has_Groups := True;
               if To_String (Summary.Group_Name) = Group then
                  Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Summary.Id);
                  Count := Count + 1;
               end if;
            end if;
         end;
      end loop;
      if not Has_Groups then
         Editor.Executor.Report_Info (S, "No buffer groups");
      elsif Count = 0 then
         Editor.Executor.Report_Info (S, "No matching open buffers");
      else
         Recompute_Buffer_Switcher_After_Marked_Action (S);
         Editor.Executor.Report_Success (S, "Marked " & Switcher_Image (Count) & " buffers in group " & Group);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Group;

   procedure Execute_Buffer_Switcher_Mark_Label
     (S     : in out Editor.State.State_Type;
      Label : String)
   is
      Text : constant String := Editor.Executor.Trimmed_Command_Text (Label);
      Has_Labels : Boolean := False;
      Count : Natural := 0;
   begin
      if Text'Length = 0 then
         Editor.Executor.Report_Info (S, "No label text");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      for I in 1 .. Editor.Buffers.Global_Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary := Editor.Buffers.Global_Summary_At (I);
         begin
            if Summary.Has_Label then
               Has_Labels := True;
               if To_String (Summary.Label_Text) = Text then
                  Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Summary.Id);
                  Count := Count + 1;
               end if;
            end if;
         end;
      end loop;
      if not Has_Labels then
         Editor.Executor.Report_Info (S, "No buffer labels");
      elsif Count = 0 then
         Editor.Executor.Report_Info (S, "No matching open buffers");
      else
         Recompute_Buffer_Switcher_After_Marked_Action (S);
         Editor.Executor.Report_Success (S, "Marked " & Switcher_Image (Count) & " buffers with label " & Text);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Label;

   procedure Execute_Buffer_Switcher_Mark_Noted
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      for I in 1 .. Editor.Buffers.Global_Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary := Editor.Buffers.Global_Summary_At (I);
         begin
            if Summary.Has_Note then
               Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Summary.Id);
               Count := Count + 1;
            end if;
         end;
      end loop;
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No noted buffers");
      else
         Recompute_Buffer_Switcher_After_Marked_Action (S);
         Editor.Executor.Report_Success (S, "Marked " & Switcher_Image (Count) & " noted buffers");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Mark_Noted;

   procedure Execute_Buffer_Switcher_Mark_Pin_Marked
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      for I in 1 .. Count loop
         Editor.Buffers.Global_Pin_Buffer (Marked_Open_Id_At (S, I));
      end loop;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Report_Success (S, "Pinned " & Switcher_Image (Count) & " marked buffers");
   end Execute_Buffer_Switcher_Mark_Pin_Marked;

   procedure Execute_Buffer_Switcher_Mark_Unpin_Marked
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      for I in 1 .. Count loop
         Editor.Buffers.Global_Unpin_Buffer (Marked_Open_Id_At (S, I));
      end loop;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Report_Success (S, "Unpinned " & Switcher_Image (Count) & " marked buffers");
   end Execute_Buffer_Switcher_Mark_Unpin_Marked;

   procedure Execute_Buffer_Switcher_Mark_Clear_Metadata
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      for I in 1 .. Count loop
         declare
            Id : constant Editor.Buffers.Buffer_Id := Marked_Open_Id_At (S, I);
         begin
            Editor.Buffers.Global_Clear_Buffer_Group (Id);
            Editor.Buffers.Global_Clear_Buffer_Label (Id);
            Editor.Buffers.Global_Clear_Buffer_Note (Id);
         end;
      end loop;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Report_Success (S, "Cleared metadata for " & Switcher_Image (Count) & " marked buffers");
   end Execute_Buffer_Switcher_Mark_Clear_Metadata;

   procedure Execute_Buffer_Switcher_Mark_Group_Assign
     (S    : in out Editor.State.State_Type;
      Name : String)
   is
      Group : constant String := Editor.Executor.Trimmed_Command_Text (Name);
      Count : Natural := 0;
      Applied : Natural := 0;
   begin
      if Group'Length = 0 then
         Editor.Executor.Report_Info (S, "No group name");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      declare
         Targets  : Marked_Target_Array (1 .. Count);
         Captured : Natural := 0;
      begin
         Capture_Marked_Open_Targets (S, Targets, Captured);
         for I in 1 .. Captured loop
            if Editor.Buffers.Global_Contains (Targets (I)) then
               Editor.Buffers.Global_Assign_Buffer_Group (Targets (I), Group);
               Applied := Applied + 1;
            else
               Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, Targets (I));
            end if;
         end loop;
      end;
      if Applied = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Report_Success (S, "Assigned " & Switcher_Image (Applied) & " marked buffers to group " & Group);
   end Execute_Buffer_Switcher_Mark_Group_Assign;

   procedure Execute_Buffer_Switcher_Mark_Group_Clear
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
      Applied : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      declare
         Targets  : Marked_Target_Array (1 .. Count);
         Captured : Natural := 0;
      begin
         Capture_Marked_Open_Targets (S, Targets, Captured);
         for I in 1 .. Captured loop
            if Editor.Buffers.Global_Contains (Targets (I)) then
               Editor.Buffers.Global_Clear_Buffer_Group (Targets (I));
               Applied := Applied + 1;
            else
               Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, Targets (I));
            end if;
         end loop;
      end;
      if Applied = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Report_Success (S, "Cleared group from " & Switcher_Image (Applied) & " marked buffers");
   end Execute_Buffer_Switcher_Mark_Group_Clear;

   procedure Execute_Buffer_Switcher_Mark_Label_Set
     (S     : in out Editor.State.State_Type;
      Label : String)
   is
      Text : constant String := Editor.Executor.Trimmed_Command_Text (Label);
      Count : Natural := 0;
      Applied : Natural := 0;
   begin
      if Text'Length > Editor.Buffers.Max_Buffer_Label_Length then
         Editor.Executor.Report_Info (S, "Label too long");
         return;
      elsif not Editor.Executor.Valid_Buffer_Label_Text (Text) then
         Editor.Executor.Report_Info (S, "Invalid label");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      declare
         Targets  : Marked_Target_Array (1 .. Count);
         Captured : Natural := 0;
      begin
         Capture_Marked_Open_Targets (S, Targets, Captured);
         for I in 1 .. Captured loop
            if Editor.Buffers.Global_Contains (Targets (I)) then
               if Text'Length = 0 then
                  Editor.Buffers.Global_Clear_Buffer_Label (Targets (I));
               else
                  Editor.Buffers.Global_Set_Buffer_Label (Targets (I), Text);
               end if;
               Applied := Applied + 1;
            else
               Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, Targets (I));
            end if;
         end loop;
      end;
      if Applied = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      if Text'Length = 0 then
         Editor.Executor.Report_Success (S, "Cleared label from " & Switcher_Image (Applied) & " marked buffers");
      else
         Editor.Executor.Report_Success (S, "Label set on " & Switcher_Image (Applied) & " marked buffers: " & Text);
      end if;
   end Execute_Buffer_Switcher_Mark_Label_Set;

   procedure Execute_Buffer_Switcher_Mark_Label_Clear
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
      Applied : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      declare
         Targets  : Marked_Target_Array (1 .. Count);
         Captured : Natural := 0;
      begin
         Capture_Marked_Open_Targets (S, Targets, Captured);
         for I in 1 .. Captured loop
            if Editor.Buffers.Global_Contains (Targets (I)) then
               Editor.Buffers.Global_Clear_Buffer_Label (Targets (I));
               Applied := Applied + 1;
            else
               Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, Targets (I));
            end if;
         end loop;
      end;
      if Applied = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Report_Success (S, "Cleared label from " & Switcher_Image (Applied) & " marked buffers");
   end Execute_Buffer_Switcher_Mark_Label_Clear;

   procedure Execute_Buffer_Switcher_Mark_Note_Set
     (S    : in out Editor.State.State_Type;
      Note : String)
   is
      Text : constant String := Editor.Executor.Trimmed_Command_Text (Note);
      Count : Natural := 0;
      Applied : Natural := 0;
   begin
      if Text'Length > Editor.Buffers.Max_Buffer_Note_Length then
         Editor.Executor.Report_Info (S, "Note too long");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      declare
         Targets  : Marked_Target_Array (1 .. Count);
         Captured : Natural := 0;
      begin
         Capture_Marked_Open_Targets (S, Targets, Captured);
         for I in 1 .. Captured loop
            if Editor.Buffers.Global_Contains (Targets (I)) then
               if Text'Length = 0 then
                  Editor.Buffers.Global_Clear_Buffer_Note (Targets (I));
               else
                  Editor.Buffers.Global_Set_Buffer_Note (Targets (I), Text);
               end if;
               Applied := Applied + 1;
            else
               Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, Targets (I));
            end if;
         end loop;
      end;
      if Applied = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      if Text'Length = 0 then
         Editor.Executor.Report_Success (S, "Cleared note from " & Switcher_Image (Applied) & " marked buffers");
      else
         Editor.Executor.Report_Success (S, "Note set on " & Switcher_Image (Applied) & " marked buffers");
      end if;
   end Execute_Buffer_Switcher_Mark_Note_Set;

   procedure Execute_Buffer_Switcher_Mark_Note_Clear
     (S : in out Editor.State.State_Type)
   is
      Count : Natural := 0;
      Applied : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      declare
         Targets  : Marked_Target_Array (1 .. Count);
         Captured : Natural := 0;
      begin
         Capture_Marked_Open_Targets (S, Targets, Captured);
         for I in 1 .. Captured loop
            if Editor.Buffers.Global_Contains (Targets (I)) then
               Editor.Buffers.Global_Clear_Buffer_Note (Targets (I));
               Applied := Applied + 1;
            else
               Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, Targets (I));
            end if;
         end loop;
      end;
      if Applied = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Report_Success (S, "Cleared note from " & Switcher_Image (Applied) & " marked buffers");
   end Execute_Buffer_Switcher_Mark_Note_Clear;

   procedure Execute_Buffer_Switcher_Mark_Close_Marked
     (S : in out Editor.State.State_Type)
   is
      Count       : Natural := 0;
      Dirty_Count : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         Count,
         Dirty_Count);
      if Count = 0 then
         Editor.Executor.Report_Info (S, "No marked buffers");
         return;
      end if;
      if Dirty_Count = 0 then
         Editor.Executor.Report_Info (S, "Confirm close " & Switcher_Image (Count) & " marked buffers");
      else
         Editor.Executor.Report_Info
           (S, "Confirm close " & Switcher_Image (Count) & " marked buffers; "
            & Switcher_Image (Dirty_Count) & " dirty buffer may be blocked");
      end if;
   end Execute_Buffer_Switcher_Mark_Close_Marked;

   procedure Execute_Buffer_Switcher_Mark_Cancel
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Editor.Executor.Report_Info (S, "No pending marked action");
         return;
      end if;
      Editor.Buffer_Switcher.Clear_Pending_Marked_Action (S.Buffer_Switcher);
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Report_Info (S, "Marked close cancelled");
   end Execute_Buffer_Switcher_Mark_Cancel;

   procedure Execute_Buffer_Switcher_Mark_Confirm
     (S : in out Editor.State.State_Type)
   is
      Target_Count : constant Natural :=
        Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher);
      Closed_Count    : Natural := 0;
      Kept_Count      : Natural := 0;
      Seen_Open_Count : Natural := 0;
      Fallback        : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Preferred       : constant Editor.Buffers.Buffer_Id := Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher);
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) /=
        Editor.Buffer_Switcher.Pending_Marked_Close
      then
         Editor.Executor.Report_Info (S, "No pending marked action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      for I in 1 .. Target_Count loop
         declare
            Id : constant Editor.Buffers.Buffer_Id :=
              Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, I);
            Closed  : Boolean := False;
            Summary : Editor.Buffers.Buffer_Summary;
         begin
            if Id /= Editor.Buffers.No_Buffer
              and then Editor.Buffers.Global_Contains (Id)
            then
               Seen_Open_Count := Seen_Open_Count + 1;
               Summary := Editor.Buffers.Global_Summary_For (Id);
               if Summary.Is_Dirty then
                  Editor.Buffers.Global_Set_Blocked_Close_Surfaced (Id);
                  if Summary.Is_Active then
                     S.File_Info.Blocked_Close_Surfaced := True;
                     Editor.Buffers.Sync_Global_Active_From_State (S);
                  end if;
                  Kept_Count := Kept_Count + 1;
               else
                  Editor.Buffers.Global_Close_Buffer (Id, Closed);
                  if Closed then
                     Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, Id);
                     Closed_Count := Closed_Count + 1;
                     Editor.Executor.Finalize_Cleanup_Buffer_Close (S, Id, Summary.Is_Active);
                  else
                     Kept_Count := Kept_Count + 1;
                  end if;
               end if;
            end if;
         end;
      end loop;

      Editor.Buffer_Switcher.Clear_Pending_Marked_Action (S.Buffer_Switcher);

      if Seen_Open_Count = 0 then
         Recompute_Buffer_Switcher_After_Selected_Action (S, Preferred, Fallback);
         Editor.Executor.Report_Info (S, "No pending marked buffers remain open");
         return;
      end if;

      Recompute_Buffer_Switcher_After_Selected_Action (S, Preferred, Fallback);
      if Closed_Count = 0 and then Kept_Count > 0 then
         Editor.Executor.Report_Info (S, "Close blocked for " & Switcher_Image (Kept_Count) & " dirty buffers");
      elsif Kept_Count = 0 then
         Editor.Executor.Report_Success (S, "Closed " & Switcher_Image (Closed_Count) & " marked buffers");
      else
         Editor.Executor.Report_Success
           (S, "Closed " & Switcher_Image (Closed_Count) & " marked buffers; "
            & Switcher_Image (Kept_Count) & " dirty buffer kept");
      end if;
   end Execute_Buffer_Switcher_Mark_Confirm;

   function Execute_Buffer_Switcher_Mark_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);

      function Result_After_Command
        (Command : Editor.Commands.Command_Id)
         return Editor.Command_Execution.Command_Execution_Result
      is
         Found : Boolean := False;
         Msg   : Editor.Messages.Editor_Message;
      begin
         if Editor.Messages.Count (S.Messages) > Before_Messages then
            Msg := Editor.Messages.Active_Message (S.Messages, Found);
            if Found then
               if Editor.Messages.Severity (Msg) =
                 Editor.Messages.Error_Message
               then
                  return Editor.Command_Execution.Failed (Command);
               elsif Editor.Messages.Severity (Msg) =
                 Editor.Messages.Warning_Message
               then
                  return Editor.Command_Execution.Unavailable (Command);
               end if;
            end if;
         end if;

         return Editor.Command_Execution.Executed (Command);
      end Result_After_Command;
   begin
      case Id is
         when Editor.Commands.Command_Buffer_Switcher_Mark_Toggle =>
            Execute_Buffer_Switcher_Mark_Toggle (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Set =>
            Execute_Buffer_Switcher_Mark_Set (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Clear =>
            Execute_Buffer_Switcher_Mark_Clear (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Clear_All =>
            Execute_Buffer_Switcher_Mark_Clear_All (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Invert_Visible =>
            Execute_Buffer_Switcher_Mark_Invert_Visible (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Visible =>
            Execute_Buffer_Switcher_Mark_Visible (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Visible =>
            Execute_Buffer_Switcher_Mark_Clear_Visible (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Pinned =>
            Execute_Buffer_Switcher_Mark_Pinned (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Group =>
            Report_Info (S, "No group name");
         when Editor.Commands.Command_Buffer_Switcher_Mark_Label =>
            Report_Info (S, "No label text");
         when Editor.Commands.Command_Buffer_Switcher_Mark_Noted =>
            Execute_Buffer_Switcher_Mark_Noted (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked =>
            Execute_Buffer_Switcher_Mark_Close_Marked (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Pin_Marked =>
            Execute_Buffer_Switcher_Mark_Pin_Marked (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Unpin_Marked =>
            Execute_Buffer_Switcher_Mark_Unpin_Marked (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Metadata =>
            Execute_Buffer_Switcher_Mark_Clear_Metadata (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Group_Assign =>
            Report_Info (S, "No group name");
         when Editor.Commands.Command_Buffer_Switcher_Mark_Group_Clear =>
            Execute_Buffer_Switcher_Mark_Group_Clear (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set =>
            Report_Info (S, "No label text");
         when Editor.Commands.Command_Buffer_Switcher_Mark_Label_Clear =>
            Execute_Buffer_Switcher_Mark_Label_Clear (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Note_Set =>
            Report_Info (S, "No note text");
         when Editor.Commands.Command_Buffer_Switcher_Mark_Note_Clear =>
            Execute_Buffer_Switcher_Mark_Note_Clear (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Review_Toggle =>
            Execute_Buffer_Switcher_Mark_Review_Toggle (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show =>
            Execute_Buffer_Switcher_Mark_Review_Show (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Review_Hide =>
            Execute_Buffer_Switcher_Mark_Review_Hide (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Next =>
            Execute_Buffer_Switcher_Mark_Next (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Previous =>
            Execute_Buffer_Switcher_Mark_Previous (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Summary =>
            Execute_Buffer_Switcher_Mark_Summary (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Confirm =>
            Execute_Buffer_Switcher_Mark_Confirm (S);
         when Editor.Commands.Command_Buffer_Switcher_Mark_Cancel =>
            Execute_Buffer_Switcher_Mark_Cancel (S);
         when others =>
            return Editor.Command_Execution.No_Op (Id);
      end case;

      Editor.Render_Cache.Invalidate_All;
      return Result_After_Command (Id);
   end Execute_Buffer_Switcher_Mark_Command;

   procedure Execute_Buffer_Switcher_Mark_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind;
      Text : String)
   is
   begin
      case Kind is
         when Editor.Commands.Buffer_Switcher_Mark_Toggle =>
            Execute_Buffer_Switcher_Mark_Toggle (S);
         when Editor.Commands.Buffer_Switcher_Mark_Set =>
            Execute_Buffer_Switcher_Mark_Set (S);
         when Editor.Commands.Buffer_Switcher_Mark_Clear =>
            Execute_Buffer_Switcher_Mark_Clear (S);
         when Editor.Commands.Buffer_Switcher_Mark_Clear_All =>
            Execute_Buffer_Switcher_Mark_Clear_All (S);
         when Editor.Commands.Buffer_Switcher_Mark_Invert_Visible =>
            Execute_Buffer_Switcher_Mark_Invert_Visible (S);
         when Editor.Commands.Buffer_Switcher_Mark_Visible =>
            Execute_Buffer_Switcher_Mark_Visible (S);
         when Editor.Commands.Buffer_Switcher_Mark_Clear_Visible =>
            Execute_Buffer_Switcher_Mark_Clear_Visible (S);
         when Editor.Commands.Buffer_Switcher_Mark_Pinned =>
            Execute_Buffer_Switcher_Mark_Pinned (S);
         when Editor.Commands.Buffer_Switcher_Mark_Group =>
            Execute_Buffer_Switcher_Mark_Group (S, Text);
         when Editor.Commands.Buffer_Switcher_Mark_Label =>
            Execute_Buffer_Switcher_Mark_Label (S, Text);
         when Editor.Commands.Buffer_Switcher_Mark_Noted =>
            Execute_Buffer_Switcher_Mark_Noted (S);
         when Editor.Commands.Buffer_Switcher_Mark_Close_Marked =>
            Execute_Buffer_Switcher_Mark_Close_Marked (S);
         when Editor.Commands.Buffer_Switcher_Mark_Confirm =>
            Execute_Buffer_Switcher_Mark_Confirm (S);
         when Editor.Commands.Buffer_Switcher_Mark_Cancel =>
            Execute_Buffer_Switcher_Mark_Cancel (S);
         when Editor.Commands.Buffer_Switcher_Mark_Pin_Marked =>
            Execute_Buffer_Switcher_Mark_Pin_Marked (S);
         when Editor.Commands.Buffer_Switcher_Mark_Unpin_Marked =>
            Execute_Buffer_Switcher_Mark_Unpin_Marked (S);
         when Editor.Commands.Buffer_Switcher_Mark_Clear_Metadata =>
            Execute_Buffer_Switcher_Mark_Clear_Metadata (S);
         when Editor.Commands.Buffer_Switcher_Mark_Group_Assign =>
            Execute_Buffer_Switcher_Mark_Group_Assign (S, Text);
         when Editor.Commands.Buffer_Switcher_Mark_Group_Clear =>
            Execute_Buffer_Switcher_Mark_Group_Clear (S);
         when Editor.Commands.Buffer_Switcher_Mark_Label_Set =>
            Execute_Buffer_Switcher_Mark_Label_Set (S, Text);
         when Editor.Commands.Buffer_Switcher_Mark_Label_Clear =>
            Execute_Buffer_Switcher_Mark_Label_Clear (S);
         when Editor.Commands.Buffer_Switcher_Mark_Note_Set =>
            Execute_Buffer_Switcher_Mark_Note_Set (S, Text);
         when Editor.Commands.Buffer_Switcher_Mark_Note_Clear =>
            Execute_Buffer_Switcher_Mark_Note_Clear (S);
         when Editor.Commands.Buffer_Switcher_Mark_Review_Toggle =>
            Execute_Buffer_Switcher_Mark_Review_Toggle (S);
         when Editor.Commands.Buffer_Switcher_Mark_Review_Show =>
            Execute_Buffer_Switcher_Mark_Review_Show (S);
         when Editor.Commands.Buffer_Switcher_Mark_Review_Hide =>
            Execute_Buffer_Switcher_Mark_Review_Hide (S);
         when Editor.Commands.Buffer_Switcher_Mark_Next =>
            Execute_Buffer_Switcher_Mark_Next (S);
         when Editor.Commands.Buffer_Switcher_Mark_Previous =>
            Execute_Buffer_Switcher_Mark_Previous (S);
         when Editor.Commands.Buffer_Switcher_Mark_Summary =>
            Execute_Buffer_Switcher_Mark_Summary (S);
         when others =>
            null;
      end case;
   end Execute_Buffer_Switcher_Mark_Kind;

end Editor.Executor.Buffer_Switcher_Mark_Commands;
