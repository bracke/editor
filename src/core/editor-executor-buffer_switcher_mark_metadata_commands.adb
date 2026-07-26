with Editor.Command_Kinds;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffer_Switcher;
with Editor.Buffer_Switcher.Rows;
with Editor.Buffers;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Messages;
with Editor.Overlay_Focus;
with Editor.Render_Cache;

package body Editor.Executor.Buffer_Switcher_Mark_Metadata_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Commands.Command_Id;
   use type Editor.Messages.Message_Severity;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   function Selected_Switcher_Buffer
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Rows.Buffer_Switcher_Row
      renames Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer;

   procedure Normalize_Switcher_Preview_Target
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target;

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

   function Has_Marked_Open_Buffers
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher)
        and then Marked_Open_Count (S) > 0;
   end Has_Marked_Open_Buffers;

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
         Report_Info (S, "No pinned buffers");
      else
         Recompute_Buffer_Switcher_After_Marked_Action (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Marked " & Switcher_Image (Count) & " pinned buffers");
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
         Report_Info (S, "No group name");
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
         Report_Info (S, "No buffer groups");
      elsif Count = 0 then
         Report_Info (S, "No matching open buffers");
      else
         Recompute_Buffer_Switcher_After_Marked_Action (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Marked " & Switcher_Image (Count) & " buffers in group " & Group);
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
         Report_Info (S, "No label text");
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
         Report_Info (S, "No buffer labels");
      elsif Count = 0 then
         Report_Info (S, "No matching open buffers");
      else
         Recompute_Buffer_Switcher_After_Marked_Action (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Marked " & Switcher_Image (Count) & " buffers with label " & Text);
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
         Report_Info (S, "No noted buffers");
      else
         Recompute_Buffer_Switcher_After_Marked_Action (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Marked " & Switcher_Image (Count) & " noted buffers");
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
         Report_Info (S, "No marked buffers");
         return;
      end if;
      for I in 1 .. Count loop
         Editor.Buffers.Global_Pin_Buffer (Marked_Open_Id_At (S, I));
      end loop;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Pinned " & Switcher_Image (Count) & " marked buffers");
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
         Report_Info (S, "No marked buffers");
         return;
      end if;
      for I in 1 .. Count loop
         Editor.Buffers.Global_Unpin_Buffer (Marked_Open_Id_At (S, I));
      end loop;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Unpinned " & Switcher_Image (Count) & " marked buffers");
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
         Report_Info (S, "No marked buffers");
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
      Editor.Executor.Shared_Services.Report_Success (S, "Cleared metadata for " & Switcher_Image (Count) & " marked buffers");
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
         Report_Info (S, "No group name");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Report_Info (S, "No marked buffers");
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
         Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Assigned " & Switcher_Image (Applied) & " marked buffers to group " & Group);
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
         Report_Info (S, "No marked buffers");
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
         Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Cleared group from " & Switcher_Image (Applied) & " marked buffers");
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
         Report_Info (S, "Label too long");
         return;
      elsif not Editor.Executor.Valid_Buffer_Label_Text (Text) then
         Report_Info (S, "Invalid label");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Report_Info (S, "No marked buffers");
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
         Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      if Text'Length = 0 then
         Editor.Executor.Shared_Services.Report_Success (S, "Cleared label from " & Switcher_Image (Applied) & " marked buffers");
      else
         Editor.Executor.Shared_Services.Report_Success (S, "Label set on " & Switcher_Image (Applied) & " marked buffers: " & Text);
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
         Report_Info (S, "No marked buffers");
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
         Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Cleared label from " & Switcher_Image (Applied) & " marked buffers");
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
         Report_Info (S, "Note too long");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Marked_Open_Count (S);
      if Count = 0 then
         Report_Info (S, "No marked buffers");
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
         Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      if Text'Length = 0 then
         Editor.Executor.Shared_Services.Report_Success (S, "Cleared note from " & Switcher_Image (Applied) & " marked buffers");
      else
         Editor.Executor.Shared_Services.Report_Success (S, "Note set on " & Switcher_Image (Applied) & " marked buffers");
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
         Report_Info (S, "No marked buffers");
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
         Report_Info (S, "No marked buffers");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Cleared note from " & Switcher_Image (Applied) & " marked buffers");
   end Execute_Buffer_Switcher_Mark_Note_Clear;

   procedure Execute_Buffer_Switcher_Mark_Metadata_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind;
      Text : String)
   is
   begin
      case Kind is
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Pinned =>
            Execute_Buffer_Switcher_Mark_Pinned (S);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Group =>
            Execute_Buffer_Switcher_Mark_Group (S, Text);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Label =>
            Execute_Buffer_Switcher_Mark_Label (S, Text);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Noted =>
            Execute_Buffer_Switcher_Mark_Noted (S);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Pin_Marked =>
            Execute_Buffer_Switcher_Mark_Pin_Marked (S);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Unpin_Marked =>
            Execute_Buffer_Switcher_Mark_Unpin_Marked (S);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Clear_Metadata =>
            Execute_Buffer_Switcher_Mark_Clear_Metadata (S);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Group_Assign =>
            Execute_Buffer_Switcher_Mark_Group_Assign (S, Text);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Group_Clear =>
            Execute_Buffer_Switcher_Mark_Group_Clear (S);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Label_Set =>
            Execute_Buffer_Switcher_Mark_Label_Set (S, Text);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Label_Clear =>
            Execute_Buffer_Switcher_Mark_Label_Clear (S);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Note_Set =>
            Execute_Buffer_Switcher_Mark_Note_Set (S, Text);
         when Editor.Command_Kinds.Buffer_Switcher_Mark_Note_Clear =>
            Execute_Buffer_Switcher_Mark_Note_Clear (S);
         when others =>
            null;
      end case;
   end Execute_Buffer_Switcher_Mark_Metadata_Kind;

end Editor.Executor.Buffer_Switcher_Mark_Metadata_Commands;
