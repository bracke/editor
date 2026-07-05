with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Bookmarks;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Commands;
with Editor.Cursors;
with Editor.Diagnostics;
with Editor.Executor;
with Editor.Executor.File_Open_Commands;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Layout;
with Editor.Messages;
with Editor.Navigation; use Editor.Navigation;
with Editor.Navigation_History;
with Editor.Project;
with Editor.Render_Cache;
with Editor.State;
with Editor.View;

package body Editor.Executor.Bookmark_Commands is

   use Editor.Commands;

   function Bookmark_Command_Availability
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
         when Command_Clear_Bookmarks =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers) then
               return Editor.Commands.Unavailable ("No bookmarks");
            end if;
            return Editor.Commands.Available;

         when Command_Next_Bookmark
            | Command_Previous_Bookmark
            | Command_Clear_All_Bookmarks =>
            if Editor.Buffers.Global_Count = 0 then
               if not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers) then
                  return Editor.Commands.Unavailable ("No bookmarks");
               end if;
            elsif not Editor.Buffers.Global_Has_Bookmarks
              and then not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers)
            then
               return Editor.Commands.Unavailable ("No bookmarks");
            end if;
            return Editor.Commands.Available;

         when Command_Bookmark_Toggle_Current_Location =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not S.File_Info.Has_Path then
               return Editor.Commands.Unavailable ("No bookmarkable location");
            end if;
            return Editor.Commands.Available;

         when Command_Bookmark_Clear_All =>
            return Editor.Commands.Available;

         when Command_Bookmark_Next
            | Command_Bookmark_Previous
            | Command_Bookmark_Goto_Next
            | Command_Bookmark_Goto_Previous =>
            if not Editor.Bookmarks.Has_Bookmarks (S.Bookmarks) then
               return Editor.Commands.Unavailable ("No bookmarks");
            end if;
            return Editor.Commands.Available;

         when Command_Bookmark_Open_Selected
            | Command_Bookmark_Remove_Selected =>
            if not Editor.Bookmarks.Has_Selected (S.Bookmarks) then
               return Editor.Commands.Unavailable ("No selected bookmark");
            end if;
            return Editor.Commands.Available;

         when Command_Bookmark_Reveal_Current =>
            if not Editor.State.Has_Active_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Editor.Bookmarks.Has_Bookmarks (S.Bookmarks) then
               return Editor.Commands.Unavailable ("No bookmarks");
            elsif not S.File_Info.Has_Path then
               return Editor.Commands.Unavailable ("No bookmarkable location");
            end if;
            return Editor.Commands.Available;

         when Command_Bookmark_Show | Command_Bookmark_Toggle =>
            return Editor.Commands.Available;

         when Command_Bookmark_Hide =>
            if not Editor.Bookmarks.Is_Visible (S.Bookmarks) then
               return Editor.Commands.Unavailable ("Bookmarks hidden");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a bookmark command");
      end case;
   end Bookmark_Command_Availability;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Info;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Warning;

   function Safe_Caret
     (S : Editor.State.State_Type) return Editor.Cursors.Cursor_Index
      renames Editor.Executor.Safe_Caret;

   procedure Execute_Open_File
     (S    : in out Editor.State.State_Type;
      Path : String) renames Editor.Executor.File_Open_Commands.Execute_Open_File;

   function Active_Feature_Buffer_Token
     (S : Editor.State.State_Type) return Natural
      renames Editor.Executor.Active_Feature_Buffer_Token;

   function Current_Navigation_Location
     (S      : Editor.State.State_Type;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location
      renames Editor.Executor.Current_Navigation_Location;

   procedure Record_Navigation_If_Target_Changed
     (S        : in out Editor.State.State_Type;
      Previous : Editor.Navigation_History.Navigation_Location;
      Target   : Editor.Navigation_History.Navigation_Location)
      renames Editor.Executor.Record_Navigation_If_Target_Changed;

   function Structured_File_Navigation_Target
     (Path   : String;
      Line   : Natural := 1;
      Column : Natural := 0;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location
      renames Editor.Executor.Structured_File_Navigation_Target;

   subtype Navigation_Apply_Status is Editor.Executor.Navigation_Apply_Status;
   Navigation_Target_Missing : constant Navigation_Apply_Status :=
     Editor.Executor.Navigation_Target_Missing;

   function Apply_Navigation_Location
     (S        : in out Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location;
      Status   : out Navigation_Apply_Status) return Boolean
      renames Editor.Executor.Apply_Navigation_Location;

   function Same_Navigation_Place
     (S        : Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location) return Boolean
      renames Editor.Executor.Same_Navigation_Place;

   procedure Jump_To_Bookmark_Row
     (S   : in out Editor.State.State_Type;
      Row : Natural)
   is
      Target_Index       : Editor.Cursors.Cursor_Index := 0;
      Viewport_Rows      : Natural := 1;
      Desired            : Natural := 0;
      Visible_Target_Row : Natural := 0;
      Visible_Found      : Boolean := False;
      Visible_Count      : Natural := 1;
      Layout             : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.Folding.Expand_To_Reveal_Row (S.Folding, Row);

      Target_Index := Editor.Cursors.Cursor_Index
        (Index_For_Line_Column (S, Row, 0));

      Visible_Target_Row := Editor.Folding.Document_Row_To_Visible_Row
        (S.Folding, Row, Visible_Found);
      if not Visible_Found then
         Visible_Target_Row := Row;
      end if;

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => Target_Index,
          Anchor                => Target_Index,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Preferred_Column := 0;
      S.Active_Diagnostic := (Has_Active => False, Index => Editor.Diagnostics.No_Diagnostic);

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
   end Jump_To_Bookmark_Row;


   function Trim_Natural_Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Trim_Natural_Image;

   function Current_Bookmark_Display_Path
     (S : Editor.State.State_Type) return String
   is
      Path : constant String := To_String (S.File_Info.Path);
   begin
      if Editor.Project.Has_Project (S.Project)
        and then Editor.Project.Is_Under_Project (S.Project, Path)
      then
         return Editor.Project.Relative_Path (S.Project, Path);
      else
         return Path;
      end if;
   end Current_Bookmark_Display_Path;

   procedure Execute_Bookmark_Toggle_Current_Location
     (S : in out Editor.State.State_Type)
   is
      Row   : Natural := 0;
      Col   : Natural := 0;
      Line  : Natural := 0;
      Added : Boolean := False;
      Path  : Unbounded_String;
      Display : Unbounded_String;
      Project_Relative : Unbounded_String := Null_Unbounded_String;
      Has_Project_Relative : Boolean := False;
   begin
      if not Editor.State.Has_Active_Buffer (S) then
         Report_Info (S, "No active buffer.");
         return;
      elsif not S.File_Info.Has_Path then
         Report_Info (S, "No bookmarkable location");
         return;
      end if;

      Editor.State.Row_Col_For_Index (S, Safe_Caret (S), Row, Col);
      Line := Row + 1;
      Path := S.File_Info.Path;
      Display := To_Unbounded_String (Current_Bookmark_Display_Path (S));
      if Editor.Project.Has_Project (S.Project)
        and then Editor.Project.Is_Under_Project (S.Project, To_String (Path))
      then
         Project_Relative := To_Unbounded_String
           (Editor.Project.Relative_Path (S.Project, To_String (Path)));
         Has_Project_Relative := True;
      end if;

      Editor.Bookmarks.Toggle
        (S.Bookmarks,
         File_Path    => To_String (Path),
         Display_Path => To_String (Display),
         Line_Number  => Line,
         Column       => Col + 1,
         Has_Column   => True,
         Added        => Added,
         Project_Relative_Path     => To_String (Project_Relative),
         Has_Project_Relative_Path => Has_Project_Relative);

      if Added then
         Report_Info (S, "Bookmark added: " & To_String (Display) & ":" & Trim_Natural_Image (Line));
      else
         Report_Info (S, "Bookmark removed: " & To_String (Display) & ":" & Trim_Natural_Image (Line));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Bookmark_Toggle_Current_Location;

   procedure Execute_Bookmark_Show
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Bookmarks.Show (S.Bookmarks);
      Report_Info (S, "Bookmarks shown");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Bookmark_Show;

   procedure Execute_Bookmark_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Bookmarks.Hide (S.Bookmarks);
      Report_Info (S, "Bookmarks hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Bookmark_Hide;

   procedure Execute_Bookmark_Toggle_Surface
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Bookmarks.Toggle_Visible (S.Bookmarks);
      if Editor.Bookmarks.Is_Visible (S.Bookmarks) then
         Report_Info (S, "Bookmarks shown");
      else
         Report_Info (S, "Bookmarks hidden");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Bookmark_Toggle_Surface;

   procedure Execute_Bookmark_Clear_All
     (S : in out Editor.State.State_Type)
   is
      Count : constant Natural := Editor.Bookmarks.Count (S.Bookmarks);
   begin
      if Count = 0 then
         Report_Info (S, "No bookmarks");
      else
         Editor.Bookmarks.Clear_Bookmarks (S.Bookmarks);
         Report_Info (S, "Cleared " & Trim_Natural_Image (Count) & " bookmarks");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Bookmark_Clear_All;

   procedure Execute_Bookmark_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Bookmarks.Has_Bookmarks (S.Bookmarks) then
         Report_Info (S, "No bookmarks");
      else
         Editor.Bookmarks.Select_Next (S.Bookmarks);
         Report_Info (S, "Selected next bookmark");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Bookmark_Next;

   procedure Execute_Bookmark_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Bookmarks.Has_Bookmarks (S.Bookmarks) then
         Report_Info (S, "No bookmarks");
      else
         Editor.Bookmarks.Select_Previous (S.Bookmarks);
         Report_Info (S, "Selected previous bookmark");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Bookmark_Previous;


   procedure Execute_Bookmark_Reveal_Current
     (S : in out Editor.State.State_Type)
   is
      Row    : Natural := 0;
      Col    : Natural := 0;
      Line   : Natural := 0;
      Status : Editor.Bookmarks.Reveal_Current_Status;
      Item  : Editor.Bookmarks.Bookmark_Entry;
   begin
      if not Editor.State.Has_Active_Buffer (S) then
         Report_Info (S, "No active buffer.");
         return;
      elsif not Editor.Bookmarks.Has_Bookmarks (S.Bookmarks) then
         Report_Info (S, "No bookmarks");
         return;
      elsif not S.File_Info.Has_Path then
         Report_Info (S, "No bookmarkable location");
         return;
      end if;

      Editor.State.Row_Col_For_Index (S, Safe_Caret (S), Row, Col);
      Line := Row + 1;
      Editor.Bookmarks.Reveal_Current
        (S.Bookmarks,
         File_Path   => To_String (S.File_Info.Path),
         Line_Number => Line,
         Status      => Status,
         Item       => Item);

      case Status is
         when Editor.Bookmarks.Reveal_Selected_Exact =>
            Editor.Bookmarks.Show (S.Bookmarks);
            Report_Info
              (S, "Selected bookmark at current location: "
               & To_String (Item.Display_Path) & ":"
               & Trim_Natural_Image (Item.Line_Number));
         when Editor.Bookmarks.Reveal_Selected_Nearest_In_File =>
            Editor.Bookmarks.Show (S.Bookmarks);
            Report_Info
              (S, "Selected bookmark in active file: "
               & To_String (Item.Display_Path) & ":"
               & Trim_Natural_Image (Item.Line_Number));
         when Editor.Bookmarks.Reveal_No_Bookmarks =>
            Report_Info (S, "No bookmarks");
         when Editor.Bookmarks.Reveal_No_Bookmark_In_Active_File =>
            Report_Info (S, "No bookmark in active file");
      end case;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Bookmark_Reveal_Current;

   procedure Execute_Bookmark_Remove_Selected
     (S : in out Editor.State.State_Type)
   is
      Removed : Boolean := False;
      Item   : Editor.Bookmarks.Bookmark_Entry;
   begin
      if not Editor.Bookmarks.Has_Bookmarks (S.Bookmarks) then
         Report_Info (S, "No bookmarks");
         return;
      elsif not Editor.Bookmarks.Has_Selected (S.Bookmarks) then
         Report_Info (S, "No selected bookmark");
         return;
      end if;

      Editor.Bookmarks.Remove_Selected (S.Bookmarks, Removed, Item);
      if Removed then
         Editor.Bookmarks.Show (S.Bookmarks);
         Report_Info
           (S, "Bookmark removed: " & To_String (Item.Display_Path) & ":"
            & Trim_Natural_Image (Item.Line_Number));
      else
         Report_Info (S, "No selected bookmark");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Bookmark_Remove_Selected;

   procedure Open_Bookmark_Target
     (S                : in out Editor.State.State_Type;
      Item            : Editor.Bookmarks.Bookmark_Entry;
      Bookmark_Message : Boolean;
      Show_On_Failure  : Boolean)
   is
      Target_Path : constant String := To_String (Item.File_Path);
      Display     : constant String := To_String (Item.Display_Path);
      Was_Open    : Boolean := False;
      Target_Row  : Natural := (if Item.Line_Number = 0 then 0 else Item.Line_Number - 1);
      Target_Col  : Natural := (if Item.Has_Column and then Item.Column > 0 then Item.Column - 1 else 0);
      Target_Index : Editor.Cursors.Cursor_Index := 0;
      Viewport_Rows : Natural := 1;
      Desired       : Natural := 0;
      Visible_Row   : Natural := 0;
      Visible_Found : Boolean := False;
      Visible_Count : Natural := 1;
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Before_Location : constant Editor.Navigation_History.Navigation_Location :=
        Current_Navigation_Location
          (S, Editor.Navigation_History.Navigation_Reason_Unknown);
   begin
      declare
         Found_Open : Boolean := False;
         Found_Id   : constant Editor.Buffers.Buffer_Id :=
           Editor.Buffers.Global_Find_By_Path (Target_Path, Found_Open);
      begin
         Was_Open := Found_Open and then Found_Id /= Editor.Buffers.No_Buffer;
      end;

      --  A bookmark target that is already represented by an open buffer must be
      --  activated through the existing open-buffer path even if the backing file
      --  has disappeared from disk.  Only unopened targets use the cheap stale
      --  file preflight so failed bookmark navigation emits one bookmark-specific
      --  primary message and does not create a new buffer or reopen entry.
      if Target_Path'Length = 0
        or else (not Was_Open and then not Ada.Directories.Exists (Target_Path))
      then
         if Show_On_Failure then
            Editor.Bookmarks.Show (S.Bookmarks);
         end if;
         Report_Warning (S, "Could not open " & Display & ": file not found");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Execute_Open_File (S, Target_Path);
      Editor.Messages.Dismiss_Latest (S.Messages);

      if not S.File_Info.Has_Path or else To_String (S.File_Info.Path) /= Target_Path then
         if Show_On_Failure then
            Editor.Bookmarks.Show (S.Bookmarks);
         end if;
         Report_Warning (S, "Could not open " & Display);
         return;
      end if;

      if Editor.State.Line_Count (S) > 0 then
         Target_Row := Natural'Min (Target_Row, Editor.State.Line_Count (S) - 1);
      else
         Target_Row := 0;
      end if;
      Target_Col := Natural'Min (Target_Col, Editor.Navigation.Line_Length (S, Target_Row));
      Editor.Folding.Expand_To_Reveal_Row (S.Folding, Target_Row);
      Target_Index := Editor.Cursors.Cursor_Index (Index_For_Line_Column (S, Target_Row, Target_Col));
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => Target_Index,
          Anchor                => Target_Index,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Preferred_Column := Target_Col;

      Record_Navigation_If_Target_Changed
        (S, Before_Location,
         Structured_File_Navigation_Target
           (Target_Path, Item.Line_Number, Target_Col));

      Visible_Row := Editor.Folding.Document_Row_To_Visible_Row (S.Folding, Target_Row, Visible_Found);
      if not Visible_Found then
         Visible_Row := Target_Row;
      end if;
      Viewport_Rows := Natural'Max (1, Editor.Layout.Visible_Row_Count (Layout, Editor.View.Viewport_Height));
      Visible_Count := Natural'Max (1, Editor.Folding.Visible_Row_Count (S.Folding, Editor.State.Line_Count (S)));
      if Visible_Row > Viewport_Rows / 2 then
         Desired := Visible_Row - Viewport_Rows / 2;
      else
         Desired := 0;
      end if;
      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Visible_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired);
      Editor.View.Clear_User_Scroll_Override;

      if Bookmark_Message then
         Report_Info
           (S,
            (if Was_Open then "Activated bookmark: " else "Opened bookmark: ")
            & Display & ":" & Trim_Natural_Image (Item.Line_Number));
      else
         Report_Info
           (S,
            (if Was_Open then "Activated " else "Opened ")
            & Display & ":" & Trim_Natural_Image (Item.Line_Number));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Open_Bookmark_Target;

   procedure Current_Bookmark_Navigation_Location
     (S            : Editor.State.State_Type;
      Has_Location : out Boolean;
      File_Path    : out Unbounded_String;
      Line_Number  : out Natural;
      Column       : out Natural;
      Has_Column   : out Boolean)
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Has_Location := False;
      File_Path := Null_Unbounded_String;
      Line_Number := 0;
      Column := 0;
      Has_Column := False;

      if Editor.State.Has_Active_Buffer (S) and then S.File_Info.Has_Path then
         Editor.State.Row_Col_For_Index (S, Safe_Caret (S), Row, Col);
         Has_Location := True;
         File_Path := S.File_Info.Path;
         Line_Number := Row + 1;
         Column := Col + 1;
         Has_Column := True;
      end if;
   end Current_Bookmark_Navigation_Location;

   procedure Execute_Bookmark_Goto_Next
     (S : in out Editor.State.State_Type)
   is
      Has_Location : Boolean := False;
      File_Path    : Unbounded_String;
      Line_Number  : Natural := 0;
      Column       : Natural := 0;
      Has_Column   : Boolean := False;
      Status       : Editor.Bookmarks.Bookmark_Goto_Status;
      Item        : Editor.Bookmarks.Bookmark_Entry;
   begin
      Current_Bookmark_Navigation_Location
        (S, Has_Location, File_Path, Line_Number, Column, Has_Column);
      Editor.Bookmarks.Select_Next_From_Location
        (S.Bookmarks,
         Has_Location => Has_Location,
         File_Path    => To_String (File_Path),
         Line_Number  => Line_Number,
         Column       => Column,
         Has_Column   => Has_Column,
         Status       => Status,
         Item        => Item);

      case Status is
         when Editor.Bookmarks.Bookmark_Goto_No_Bookmarks =>
            Report_Info (S, "No bookmarks");
            Editor.Render_Cache.Invalidate_All;
         when Editor.Bookmarks.Bookmark_Goto_Target_Found =>
            Open_Bookmark_Target
              (S, Item, Bookmark_Message => True, Show_On_Failure => False);
      end case;
   end Execute_Bookmark_Goto_Next;

   procedure Execute_Bookmark_Goto_Previous
     (S : in out Editor.State.State_Type)
   is
      Has_Location : Boolean := False;
      File_Path    : Unbounded_String;
      Line_Number  : Natural := 0;
      Column       : Natural := 0;
      Has_Column   : Boolean := False;
      Status       : Editor.Bookmarks.Bookmark_Goto_Status;
      Item        : Editor.Bookmarks.Bookmark_Entry;
   begin
      Current_Bookmark_Navigation_Location
        (S, Has_Location, File_Path, Line_Number, Column, Has_Column);
      Editor.Bookmarks.Select_Previous_From_Location
        (S.Bookmarks,
         Has_Location => Has_Location,
         File_Path    => To_String (File_Path),
         Line_Number  => Line_Number,
         Column       => Column,
         Has_Column   => Has_Column,
         Status       => Status,
         Item        => Item);

      case Status is
         when Editor.Bookmarks.Bookmark_Goto_No_Bookmarks =>
            Report_Info (S, "No bookmarks");
            Editor.Render_Cache.Invalidate_All;
         when Editor.Bookmarks.Bookmark_Goto_Target_Found =>
            Open_Bookmark_Target
              (S, Item, Bookmark_Message => True, Show_On_Failure => False);
      end case;
   end Execute_Bookmark_Goto_Previous;

   procedure Execute_Bookmark_Open_Selected
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Item : constant Editor.Bookmarks.Bookmark_Entry :=
        Editor.Bookmarks.Selected (S.Bookmarks, Found);
   begin
      if not Found then
         Report_Info (S, "No selected bookmark");
         return;
      end if;

      Open_Bookmark_Target
        (S, Item, Bookmark_Message => False, Show_On_Failure => True);
   end Execute_Bookmark_Open_Selected;

   procedure Execute_Toggle_Bookmark_At_Row
     (S   : in out Editor.State.State_Type;
      Row : Natural)
   is
      Had_Bookmark : constant Boolean :=
        Editor.Gutter_Markers.Has_Marker
          (S.Gutter_Markers, Row, Editor.Gutter_Markers.Bookmark_Marker);
   begin
      if not Editor.State.Has_Active_Buffer (S)
        or else Row >= Editor.State.Line_Count (S)
      then
         Report_Info (S, "Bookmark unavailable: no active buffer");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Gutter_Markers.Toggle_Bookmark (S.Gutter_Markers, Row);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if Had_Bookmark then
         Report_Info (S, "Bookmark removed");
      else
         Report_Info (S, "Bookmark added");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Toggle_Bookmark_At_Row;

   procedure Execute_Toggle_Bookmark
     (S : in out Editor.State.State_Type)
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Editor.State.Row_Col_For_Index (S, Safe_Caret (S), Row, Col);
      Execute_Toggle_Bookmark_At_Row (S, Row);
   end Execute_Toggle_Bookmark;

   function Buffer_Order_Index
     (Id : Editor.Buffers.Buffer_Id) return Natural
   is
      Summary : Editor.Buffers.Buffer_Summary;
   begin
      for I in 1 .. Editor.Buffers.Global_Count loop
         Summary := Editor.Buffers.Global_Summary_At (I);
         if Summary.Id = Id then
            return I;
         end if;
      end loop;
      return 0;
   end Buffer_Order_Index;

   function Bookmark_Target_Is_Valid
     (Target_Buffer : Editor.Buffers.Buffer_Id;
      Row           : Natural) return Boolean
   is
      Target_State : Editor.State.State_Type;
   begin
      if Target_Buffer = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Target_Buffer)
      then
         return False;
      end if;

      Target_State := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, Target_Buffer);
      return Row < Editor.State.Line_Count (Target_State);
   end Bookmark_Target_Is_Valid;

   function Buffer_Has_Bookmark_Row
     (Target_Buffer : Editor.Buffers.Buffer_Id;
      Row           : Natural) return Boolean
   is
      Target_State : Editor.State.State_Type;
   begin
      if Target_Buffer = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Target_Buffer)
      then
         return False;
      end if;

      Target_State := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, Target_Buffer);
      return Row < Editor.State.Line_Count (Target_State)
        and then Editor.Gutter_Markers.Has_Marker
          (Target_State.Gutter_Markers, Row, Editor.Gutter_Markers.Bookmark_Marker);
   end Buffer_Has_Bookmark_Row;

   function Find_Bookmark_Target
     (S        : Editor.State.State_Type;
      Forward  : Boolean;
      Target   : out Editor.Navigation_History.Navigation_Location) return Boolean
   is
      Current_Buffer : constant Editor.Buffers.Buffer_Id :=
        Editor.Buffers.Buffer_Id (Active_Feature_Buffer_Token (S));
      Current_Row    : Natural := 0;
      Current_Col    : Natural := 0;
      Count          : constant Natural := Editor.Buffers.Global_Count;
      Current_Order  : Natural := 0;
      Summary        : Editor.Buffers.Buffer_Summary;
      Target_State   : Editor.State.State_Type;
      Candidate_Row  : Natural := 0;
      Order          : Natural := 0;
   begin
      Target := (others => <>);

      if Count = 0 then
         return False;
      end if;

      Editor.State.Row_Col_For_Index (S, Safe_Caret (S), Current_Row, Current_Col);
      Current_Order := Buffer_Order_Index (Current_Buffer);
      if Current_Order = 0 then
         Current_Order := 1;
      end if;

      for Step in 0 .. Count - 1 loop
         if Forward then
            Order := ((Current_Order - 1 + Step) mod Count) + 1;
         else
            Order := ((Current_Order - 1 + Count - Step) mod Count) + 1;
         end if;

         Summary := Editor.Buffers.Global_Summary_At (Order);
         if Summary.Id /= Editor.Buffers.No_Buffer then
            Target_State := Editor.Buffers.Buffer
              (Editor.Buffers.Global_Registry_For_UI, Summary.Id);

            if Forward then
               declare
                  Target_Line_Count : constant Natural :=
                    Editor.State.Line_Count (Target_State);
               begin
                  if Target_Line_Count > 0 then
                     for Row in 0 .. Target_Line_Count - 1 loop
                        if (Step > 0 or else Row > Current_Row)
                          and then Editor.Gutter_Markers.Has_Marker
                            (Target_State.Gutter_Markers, Row, Editor.Gutter_Markers.Bookmark_Marker)
                        then
                           Target :=
                             (Buffer_Id    => Natural (Summary.Id),
                              Line         => Row + 1,
                              Column       => 0,
                              Viewport_Row => 0,
                              Reason       => Editor.Navigation_History.Navigation_Reason_Bookmark_Next,
                              others       => <>);
                           return True;
                        end if;
                     end loop;
                  end if;
               end;
            else
               Candidate_Row := Editor.State.Line_Count (Target_State);
               while Candidate_Row > 0 loop
                  Candidate_Row := Candidate_Row - 1;
                  if (Step > 0 or else Candidate_Row < Current_Row)
                    and then Editor.Gutter_Markers.Has_Marker
                      (Target_State.Gutter_Markers, Candidate_Row, Editor.Gutter_Markers.Bookmark_Marker)
                  then
                     Target :=
                       (Buffer_Id    => Natural (Summary.Id),
                        Line         => Candidate_Row + 1,
                        Column       => 0,
                        Viewport_Row => 0,
                        Reason       => Editor.Navigation_History.Navigation_Reason_Bookmark_Previous,
                        others       => <>);
                     return True;
                  end if;
               end loop;
            end if;
         end if;
      end loop;

      --  Finally scan the wrap segment of the current buffer.  This covers
      --  normal one-buffer wraparound and the single-bookmark current-line case.
      if Editor.Buffers.Global_Contains (Current_Buffer) then
         Target_State := Editor.Buffers.Buffer
           (Editor.Buffers.Global_Registry_For_UI, Current_Buffer);

         if Forward then
            for Row in 0 .. Current_Row loop
               if Row < Editor.State.Line_Count (Target_State)
                 and then Editor.Gutter_Markers.Has_Marker
                   (Target_State.Gutter_Markers, Row, Editor.Gutter_Markers.Bookmark_Marker)
               then
                  Target :=
                    (Buffer_Id    => Natural (Current_Buffer),
                     Line         => Row + 1,
                     Column       => 0,
                     Viewport_Row => 0,
                     Reason       => Editor.Navigation_History.Navigation_Reason_Bookmark_Next,
                              others       => <>);
                  return True;
               end if;
            end loop;
         else
            Candidate_Row := Editor.State.Line_Count (Target_State);
            while Candidate_Row > 0 loop
               Candidate_Row := Candidate_Row - 1;
               if Candidate_Row >= Current_Row
                 and then Editor.Gutter_Markers.Has_Marker
                   (Target_State.Gutter_Markers, Candidate_Row, Editor.Gutter_Markers.Bookmark_Marker)
               then
                  Target :=
                    (Buffer_Id    => Natural (Current_Buffer),
                     Line         => Candidate_Row + 1,
                     Column       => 0,
                     Viewport_Row => 0,
                     Reason       => Editor.Navigation_History.Navigation_Reason_Bookmark_Previous,
                        others       => <>);
                  return True;
               end if;
            end loop;
         end if;
      end if;

      return False;
   end Find_Bookmark_Target;

   procedure Execute_Next_Bookmark
     (S : in out Editor.State.State_Type)
   is
      Target          : Editor.Navigation_History.Navigation_Location;
      Before_Location : constant Editor.Navigation_History.Navigation_Location :=
        Current_Navigation_Location
          (S, Editor.Navigation_History.Navigation_Reason_Bookmark_Next);
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Gutter_Markers.Prune_Bookmarks_At_Or_After
        (S.Gutter_Markers, Editor.State.Line_Count (S));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Prune_Stale_Bookmarks;
      Editor.Buffers.Load_Global_Active_Into_State (S);

      if not Find_Bookmark_Target (S, True, Target) then
         Report_Info (S, "Bookmark: no bookmarks");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Same_Navigation_Place (S, Target) then
         Report_Info (S, "Bookmark: next");
      else
         declare
            Status : Navigation_Apply_Status := Navigation_Target_Missing;
         begin
            if not Apply_Navigation_Location (S, Target, Status) then
               Report_Info (S, "Bookmark: no valid bookmarks");
               Editor.Render_Cache.Invalidate_All;
               return;
            end if;
         end;
         Record_Navigation_If_Target_Changed (S, Before_Location, Target);
         Report_Info (S, "Bookmark: next");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Next_Bookmark;

   procedure Execute_Previous_Bookmark
     (S : in out Editor.State.State_Type)
   is
      Target          : Editor.Navigation_History.Navigation_Location;
      Before_Location : constant Editor.Navigation_History.Navigation_Location :=
        Current_Navigation_Location
          (S, Editor.Navigation_History.Navigation_Reason_Bookmark_Previous);
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Gutter_Markers.Prune_Bookmarks_At_Or_After
        (S.Gutter_Markers, Editor.State.Line_Count (S));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Prune_Stale_Bookmarks;
      Editor.Buffers.Load_Global_Active_Into_State (S);

      if not Find_Bookmark_Target (S, False, Target) then
         Report_Info (S, "Bookmark: no bookmarks");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Same_Navigation_Place (S, Target) then
         Report_Info (S, "Bookmark: previous");
      else
         declare
            Status : Navigation_Apply_Status := Navigation_Target_Missing;
         begin
            if not Apply_Navigation_Location (S, Target, Status) then
               Report_Info (S, "Bookmark: no valid bookmarks");
               Editor.Render_Cache.Invalidate_All;
               return;
            end if;
         end;
         Record_Navigation_If_Target_Changed (S, Before_Location, Target);
         Report_Info (S, "Bookmark: previous");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Previous_Bookmark;

   procedure Execute_Clear_Bookmarks
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.State.Has_Active_Buffer (S) then
         Report_Info (S, "Bookmark unavailable: no active buffer");
      elsif not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers) then
         Report_Info (S, "No bookmarks to clear");
      else
         Editor.Gutter_Markers.Clear_Bookmarks (S.Gutter_Markers);
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Report_Info (S, "Bookmarks cleared for buffer");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Clear_Bookmarks;

   procedure Execute_Clear_All_Bookmarks
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      if not Editor.Buffers.Global_Has_Bookmarks then
         Report_Info (S, "No bookmarks to clear");
      else
         Editor.Buffers.Global_Clear_All_Bookmarks;
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Report_Info (S, "Bookmarks cleared");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Clear_All_Bookmarks;

   procedure Execute_Bookmark_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
   begin
      case Kind is
         when Toggle_Bookmark =>
            Execute_Toggle_Bookmark (S);

         when Next_Bookmark =>
            Execute_Next_Bookmark (S);

         when Previous_Bookmark =>
            Execute_Previous_Bookmark (S);

         when Clear_Bookmarks =>
            Execute_Clear_Bookmarks (S);

         when Clear_All_Bookmarks =>
            Execute_Clear_All_Bookmarks (S);

         when Bookmark_Toggle_Current_Location =>
            Execute_Bookmark_Toggle_Current_Location (S);

         when Bookmark_Clear_All =>
            Execute_Bookmark_Clear_All (S);

         when Bookmark_Next =>
            Execute_Bookmark_Next (S);

         when Bookmark_Previous =>
            Execute_Bookmark_Previous (S);

         when Bookmark_Goto_Next =>
            Execute_Bookmark_Goto_Next (S);

         when Bookmark_Goto_Previous =>
            Execute_Bookmark_Goto_Previous (S);

         when Bookmark_Open_Selected =>
            Execute_Bookmark_Open_Selected (S);

         when Bookmark_Reveal_Current =>
            Execute_Bookmark_Reveal_Current (S);

         when Bookmark_Remove_Selected =>
            Execute_Bookmark_Remove_Selected (S);

         when Bookmark_Show =>
            Execute_Bookmark_Show (S);

         when Bookmark_Hide =>
            Execute_Bookmark_Hide (S);

         when Bookmark_Toggle =>
            Execute_Bookmark_Toggle_Surface (S);

         when others =>
            raise Program_Error with "unsupported bookmark command kind";
      end case;
   end Execute_Bookmark_Kind;


end Editor.Executor.Bookmark_Commands;
