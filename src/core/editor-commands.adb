with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Classification;
with Editor.Commands.Availability_Metadata;
with Editor.Commands.Descriptor_Metadata;
with Editor.Commands.Audits;
with Editor.Commands.Reference_Metadata;
with Editor.Commands.Name_Metadata;
with Editor.Commands.Workflow_Messages;
package body Editor.Commands is

   use Position_Vectors;
   use Delete_Count_Vectors;
   use Text_Vectors;
   function "=" (L, R : Command) return Boolean is
   begin
      return L.Kind = R.Kind
        and then L.Pos = R.Pos
        and then L.Has_Position = R.Has_Position
        and then L.Ch = R.Ch
        and then L.Code = R.Code
        and then L.Shift = R.Shift
        and then L.Ctrl = R.Ctrl
        and then L.Alt = R.Alt
        and then L.Click_X = R.Click_X
        and then L.Click_Y = R.Click_Y
        and then L.Positions = R.Positions
        and then L.Delete_Counts = R.Delete_Counts
        and then L.Insert_Texts = R.Insert_Texts
        and then L.Text = R.Text
        and then L.Path = R.Path
        and then L.Query = R.Query
        and then L.Buffer_Id = R.Buffer_Id;
   end "=";




   function Available return Command_Availability
   is
   begin
      return Availability_Metadata.Available;
   end Available;


   function Unavailable
     (Reason : String) return Command_Availability
   is
   begin
      return
        (Status => Command_Unavailable,
         Reason => To_Unbounded_String (Editor.Commands.Workflow_Messages.Normalize_Workflow_Message (Reason)));
   end Unavailable;

   function Is_Available
     (Availability : Command_Availability) return Boolean
   is
   begin
      return Availability_Metadata.Is_Available (Availability);
   end Is_Available;

   function Is_Concrete_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Availability_Metadata.Is_Concrete_Command;

   function Unavailable_Reason
     (Availability : Command_Availability) return String
   is
   begin
      return Editor.Commands.Workflow_Messages.Normalize_Workflow_Message (To_String (Availability.Reason));
   end Unavailable_Reason;

   function Normalize_Workflow_Message
     (Text : String) return String
     renames Editor.Commands.Workflow_Messages.Normalize_Workflow_Message;

   function Requires_Context
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Availability_Metadata.Requires_Context;

   function Has_Availability_Handler
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Availability_Metadata.Has_Availability_Handler;

   function Command_For_Id
     (Id    : Command_Id;
      Shift : Boolean := False) return Command
   is
      Cmd : Command;
   begin
      Cmd.Shift := Shift;

      case Id is
         when Command_Move_Left =>
            Cmd.Kind := Move_Left;
         when Command_Move_Right =>
            Cmd.Kind := Move_Right;
         when Command_Move_Up =>
            Cmd.Kind := Move_Up;
         when Command_Move_Down =>
            Cmd.Kind := Move_Down;
         when Command_Move_Line_Start =>
            Cmd.Kind := Move_Line_Start;
         when Command_Move_Line_End =>
            Cmd.Kind := Move_Line_End;
         when Command_Move_Document_Start =>
            Cmd.Kind := Move_Document_Start;
         when Command_Move_Document_End =>
            Cmd.Kind := Move_Document_End;
         when Command_Move_Word_Left =>
            Cmd.Kind := Move_Word_Left;
         when Command_Move_Word_Right =>
            Cmd.Kind := Move_Word_Right;
         when Command_Page_Up =>
            Cmd.Kind := Move_Page_Up;
         when Command_Page_Down =>
            Cmd.Kind := Move_Page_Down;
         when Command_Select_Left =>
            Cmd.Kind := Move_Left;
            Cmd.Shift := True;
         when Command_Select_Right =>
            Cmd.Kind := Move_Right;
            Cmd.Shift := True;
         when Command_Select_Up =>
            Cmd.Kind := Move_Up;
            Cmd.Shift := True;
         when Command_Select_Down =>
            Cmd.Kind := Move_Down;
            Cmd.Shift := True;
         when Command_Select_Word_Left =>
            Cmd.Kind := Select_Word_Left;
            Cmd.Shift := True;
         when Command_Select_Word_Right =>
            Cmd.Kind := Select_Word_Right;
            Cmd.Shift := True;
         when Command_Select_Word =>
            Cmd.Kind := Select_Word;
         when Command_Select_Line =>
            Cmd.Kind := Select_Line;
         when Command_Start_Rectangular_Selection =>
            Cmd.Kind := Start_Rectangle_At_Caret;
         when Command_Clear_Rectangular_Selection =>
            Cmd.Kind := Clear_Rectangle_Selection;
         when Command_Extend_Selection_Line_Up =>
            Cmd.Kind := Extend_Selection_Line_Up;
            Cmd.Shift := True;
         when Command_Extend_Selection_Line_Down =>
            Cmd.Kind := Extend_Selection_Line_Down;
            Cmd.Shift := True;
         when Command_Select_Line_Start =>
            Cmd.Kind := Select_Line_Start;
            Cmd.Shift := True;
         when Command_Select_Line_End =>
            Cmd.Kind := Select_Line_End;
            Cmd.Shift := True;
         when Command_Select_Document_Start =>
            Cmd.Kind := Select_Document_Start;
            Cmd.Shift := True;
         when Command_Select_Document_End =>
            Cmd.Kind := Select_Document_End;
            Cmd.Shift := True;
         when Command_Select_Page_Up =>
            Cmd.Kind := Select_Page_Up;
            Cmd.Shift := True;
         when Command_Select_Page_Down =>
            Cmd.Kind := Select_Page_Down;
            Cmd.Shift := True;
         when Command_Insert_Newline =>
            Cmd.Kind := Insert_Text_Input;
            Cmd.Ch := ASCII.LF;
            Cmd.Code := Wide_Wide_Character'Val (Character'Pos (ASCII.LF));
            Cmd.Text := To_Unbounded_String (String'(1 => ASCII.LF));
         when Command_Undo =>
            Cmd.Kind := Undo;
         when Command_Redo =>
            Cmd.Kind := Redo;
         when Command_Edit_History_Clear =>
            Cmd.Kind := Break_Group;
         when Command_Copy =>
            Cmd.Kind := Copy_Selection;
         when Command_Cut =>
            Cmd.Kind := Cut_Selection;
         when Command_Paste =>
            Cmd.Kind := Paste_Clipboard;
         when Command_Clipboard_Clear =>
            Cmd.Kind := Clear_Clipboard;
         when Command_Selection_Delete =>
            Cmd.Kind := Delete_Selection_Range;
         when Command_Line_Delete =>
            Cmd.Kind := Delete_Current_Line;
         when Command_Line_Duplicate =>
            Cmd.Kind := Duplicate_Current_Line;
         when Command_Line_Move_Up =>
            Cmd.Kind := Move_Current_Line_Up;
         when Command_Line_Move_Down =>
            Cmd.Kind := Move_Current_Line_Down;
         when Command_Indent_Increase =>
            Cmd.Kind := Indent_Current_Line;
         when Command_Indent_Decrease =>
            Cmd.Kind := Outdent_Current_Line;
         when Command_Comment_Line =>
            Cmd.Kind := Comment_Current_Line;
         when Command_Uncomment_Line =>
            Cmd.Kind := Uncomment_Current_Line;
         when Command_Toggle_Line_Comment =>
            Cmd.Kind := Toggle_Current_Line_Comment;
         when Command_Line_Join_Next =>
            Cmd.Kind := Join_Current_Line_With_Next;
         when Command_Line_Split_At_Caret =>
            Cmd.Kind := Split_Current_Line_At_Caret;
         when Command_Trim_Trailing_Whitespace =>
            Cmd.Kind := Trim_Trailing_Whitespace;
         when Command_Format_Buffer =>
            Cmd.Kind := Trim_Trailing_Whitespace;
         when Command_Format_Selected_Text =>
            Cmd.Kind := Trim_Trailing_Whitespace;
         when Command_Toggle_Format_On_Save =>
            Cmd.Kind := Toggle_Format_On_Save;
         when Command_Char_Delete_Previous =>
            Cmd.Kind := Delete_Previous_Character;
         when Command_Char_Delete_Next =>
            Cmd.Kind := Delete_Next_Character;
         when Command_Word_Delete_Previous =>
            Cmd.Kind := Delete_Previous_Word;
         when Command_Word_Delete_Next =>
            Cmd.Kind := Delete_Next_Word;
         when Command_Save_File =>
            Cmd.Kind := Save_File;
         when Command_Save_File_As =>
            Cmd.Kind := Save_File_As;
         when Command_Reload_Active_Buffer =>
            Cmd.Kind := Reload_Active_Buffer;
         when Command_Revert_Active_Buffer =>
            Cmd.Kind := Revert_Active_Buffer;
         when Command_File_Conflict_Keep_Buffer =>
            Cmd.Kind := File_Conflict_Keep_Buffer;
         when Command_File_Conflict_Reload_From_Disk =>
            Cmd.Kind := File_Conflict_Reload_From_Disk;
         when Command_File_Conflict_Overwrite_Disk =>
            Cmd.Kind := File_Conflict_Overwrite_Disk;
         when Command_File_Conflict_Cancel =>
            Cmd.Kind := File_Conflict_Cancel;
         when Command_Rename_Buffer_File =>
            Cmd.Kind := Rename_Buffer_File;
         when Command_Delete_Buffer_File =>
            Cmd.Kind := Delete_Buffer_File;
         when Command_Copy_Buffer_File =>
            Cmd.Kind := Copy_Buffer_File;
         when Command_Move_Buffer_File =>
            Cmd.Kind := Move_Buffer_File;
         when Command_Save_All =>
            Cmd.Kind := Save_All;
         when Command_Open_Quick_Open =>
            Cmd.Kind := Open_Quick_Open;
         when Command_Close_Quick_Open =>
            Cmd.Kind := Close_Quick_Open;
         when Command_Toggle_Quick_Open =>
            Cmd.Kind := Toggle_Quick_Open;
         when Command_Accept_Quick_Open =>
            Cmd.Kind := Accept_Quick_Open;
         when Command_Quick_Open_Next_Result =>
            Cmd.Kind := Quick_Open_Next_Result;
         when Command_Quick_Open_Previous_Result =>
            Cmd.Kind := Quick_Open_Previous_Result;
         when Command_Quick_Open_Query_Set =>
            Cmd.Kind := Quick_Open_Query_Set;
         when Command_Quick_Open_Query_Clear =>
            Cmd.Kind := Quick_Open_Query_Clear;
         when Command_Quick_Open_Kind_Next =>
            Cmd.Kind := Quick_Open_Kind_Next;
         when Command_Quick_Open_Kind_Previous =>
            Cmd.Kind := Quick_Open_Kind_Previous;
         when Command_Quick_Open_Kind_Clear =>
            Cmd.Kind := Quick_Open_Kind_Clear;
         when Command_Quick_Open_Scope_Set =>
            Cmd.Kind := Quick_Open_Scope_Set;
         when Command_Quick_Open_Scope_Clear =>
            Cmd.Kind := Quick_Open_Scope_Clear;
         when Command_Quick_Open_Scope_From_Selected =>
            Cmd.Kind := Quick_Open_Scope_From_Selected;
         when Command_Quick_Open_Scope_Parent =>
            Cmd.Kind := Quick_Open_Scope_Parent;
         when Command_Quick_Open_Reveal_Active =>
            Cmd.Kind := Quick_Open_Reveal_Active;
         when Command_Quick_Open_Scope_Active_Directory =>
            Cmd.Kind := Quick_Open_Scope_Active_Directory;
         when Command_Quick_Open_Create_From_Query =>
            Cmd.Kind := Quick_Open_Create_From_Query;
         when Command_Quick_Open_Create_With_Parents_From_Query =>
            Cmd.Kind := Quick_Open_Create_With_Parents_From_Query;
         when Command_Quick_Open_Priority_Toggle =>
            Cmd.Kind := Quick_Open_Priority_Toggle;
         when Command_Quick_Open_Priority_Clear =>
            Cmd.Kind := Quick_Open_Priority_Clear;
         when Command_Open_Buffer_Switcher =>
            Cmd.Kind := Open_Buffer_Switcher;
         when Command_Close_Buffer_Switcher =>
            Cmd.Kind := Close_Buffer_Switcher;
         when Command_Accept_Buffer_Switcher =>
            Cmd.Kind := Accept_Buffer_Switcher;
         when Command_Buffer_Switcher_Next_Result =>
            Cmd.Kind := Buffer_Switcher_Next_Result;
         when Command_Buffer_Switcher_Previous_Result =>
            Cmd.Kind := Buffer_Switcher_Previous_Result;
         when Command_Buffer_Switcher_Filter_Clear =>
            Cmd.Kind := Buffer_Switcher_Filter_Clear;
         when Command_Buffer_Switcher_Filter_Pinned =>
            Cmd.Kind := Buffer_Switcher_Filter_Pinned;
         when Command_Buffer_Switcher_Filter_Group =>
            Cmd.Kind := Buffer_Switcher_Filter_Group;
         when Command_Buffer_Switcher_Filter_Label =>
            Cmd.Kind := Buffer_Switcher_Filter_Label;
         when Command_Buffer_Switcher_Filter_Noted =>
            Cmd.Kind := Buffer_Switcher_Filter_Noted;
         when Command_Buffer_Switcher_Sort_Default =>
            Cmd.Kind := Buffer_Switcher_Sort_Default;
         when Command_Buffer_Switcher_Sort_Recent =>
            Cmd.Kind := Buffer_Switcher_Sort_Recent;
         when Command_Buffer_Switcher_Sort_Name =>
            Cmd.Kind := Buffer_Switcher_Sort_Name;
         when Command_Buffer_Switcher_Sort_Pinned =>
            Cmd.Kind := Buffer_Switcher_Sort_Pinned;
         when Command_Buffer_Switcher_Sort_Group =>
            Cmd.Kind := Buffer_Switcher_Sort_Group;
         when Command_Buffer_Switcher_Sort_Label =>
            Cmd.Kind := Buffer_Switcher_Sort_Label;
         when Command_Buffer_Switcher_Sort_Next =>
            Cmd.Kind := Buffer_Switcher_Sort_Next;
         when Command_Buffer_Switcher_Sort_Previous =>
            Cmd.Kind := Buffer_Switcher_Sort_Previous;
         when Command_Buffer_Switcher_Selected_Close =>
            Cmd.Kind := Buffer_Switcher_Selected_Close;
         when Command_Buffer_Switcher_Selected_Pin =>
            Cmd.Kind := Buffer_Switcher_Selected_Pin;
         when Command_Buffer_Switcher_Selected_Unpin =>
            Cmd.Kind := Buffer_Switcher_Selected_Unpin;
         when Command_Buffer_Switcher_Selected_Toggle_Pin =>
            Cmd.Kind := Buffer_Switcher_Selected_Toggle_Pin;
         when Command_Buffer_Switcher_Selected_Group_Assign =>
            Cmd.Kind := Buffer_Switcher_Selected_Group_Assign;
         when Command_Buffer_Switcher_Selected_Group_Clear =>
            Cmd.Kind := Buffer_Switcher_Selected_Group_Clear;
         when Command_Buffer_Switcher_Selected_Label_Set =>
            Cmd.Kind := Buffer_Switcher_Selected_Label_Set;
         when Command_Buffer_Switcher_Selected_Label_Clear =>
            Cmd.Kind := Buffer_Switcher_Selected_Label_Clear;
         when Command_Buffer_Switcher_Selected_Note_Set =>
            Cmd.Kind := Buffer_Switcher_Selected_Note_Set;
         when Command_Buffer_Switcher_Selected_Note_Clear =>
            Cmd.Kind := Buffer_Switcher_Selected_Note_Clear;
         when Command_Buffer_Switcher_Preview_Toggle =>
            Cmd.Kind := Buffer_Switcher_Preview_Toggle;
         when Command_Buffer_Switcher_Preview_Show =>
            Cmd.Kind := Buffer_Switcher_Preview_Show;
         when Command_Buffer_Switcher_Preview_Hide =>
            Cmd.Kind := Buffer_Switcher_Preview_Hide;
         when Command_Buffer_Switcher_Preview_Next_Line =>
            Cmd.Kind := Buffer_Switcher_Preview_Next_Line;
         when Command_Buffer_Switcher_Preview_Previous_Line =>
            Cmd.Kind := Buffer_Switcher_Preview_Previous_Line;
         when Command_Buffer_Switcher_Preview_Center_Cursor =>
            Cmd.Kind := Buffer_Switcher_Preview_Center_Cursor;
         when Command_Buffer_Switcher_Mark_Toggle =>
            Cmd.Kind := Buffer_Switcher_Mark_Toggle;
         when Command_Buffer_Switcher_Mark_Set =>
            Cmd.Kind := Buffer_Switcher_Mark_Set;
         when Command_Buffer_Switcher_Mark_Clear =>
            Cmd.Kind := Buffer_Switcher_Mark_Clear;
         when Command_Buffer_Switcher_Mark_Clear_All =>
            Cmd.Kind := Buffer_Switcher_Mark_Clear_All;
         when Command_Buffer_Switcher_Mark_Invert_Visible =>
            Cmd.Kind := Buffer_Switcher_Mark_Invert_Visible;
         when Command_Buffer_Switcher_Mark_Visible =>
            Cmd.Kind := Buffer_Switcher_Mark_Visible;
         when Command_Buffer_Switcher_Mark_Clear_Visible =>
            Cmd.Kind := Buffer_Switcher_Mark_Clear_Visible;
         when Command_Buffer_Switcher_Mark_Pinned =>
            Cmd.Kind := Buffer_Switcher_Mark_Pinned;
         when Command_Buffer_Switcher_Mark_Group =>
            Cmd.Kind := Buffer_Switcher_Mark_Group;
         when Command_Buffer_Switcher_Mark_Label =>
            Cmd.Kind := Buffer_Switcher_Mark_Label;
         when Command_Buffer_Switcher_Mark_Noted =>
            Cmd.Kind := Buffer_Switcher_Mark_Noted;
         when Command_Buffer_Switcher_Mark_Close_Marked =>
            Cmd.Kind := Buffer_Switcher_Mark_Close_Marked;
         when Command_Buffer_Switcher_Mark_Confirm =>
            Cmd.Kind := Buffer_Switcher_Mark_Confirm;
         when Command_Buffer_Switcher_Mark_Cancel =>
            Cmd.Kind := Buffer_Switcher_Mark_Cancel;
         when Command_Buffer_Switcher_Mark_Pin_Marked =>
            Cmd.Kind := Buffer_Switcher_Mark_Pin_Marked;
         when Command_Buffer_Switcher_Mark_Unpin_Marked =>
            Cmd.Kind := Buffer_Switcher_Mark_Unpin_Marked;
         when Command_Buffer_Switcher_Mark_Clear_Metadata =>
            Cmd.Kind := Buffer_Switcher_Mark_Clear_Metadata;
         when Command_Buffer_Switcher_Mark_Group_Assign =>
            Cmd.Kind := Buffer_Switcher_Mark_Group_Assign;
         when Command_Buffer_Switcher_Mark_Group_Clear =>
            Cmd.Kind := Buffer_Switcher_Mark_Group_Clear;
         when Command_Buffer_Switcher_Mark_Label_Set =>
            Cmd.Kind := Buffer_Switcher_Mark_Label_Set;
         when Command_Buffer_Switcher_Mark_Label_Clear =>
            Cmd.Kind := Buffer_Switcher_Mark_Label_Clear;
         when Command_Buffer_Switcher_Mark_Note_Set =>
            Cmd.Kind := Buffer_Switcher_Mark_Note_Set;
         when Command_Buffer_Switcher_Mark_Note_Clear =>
            Cmd.Kind := Buffer_Switcher_Mark_Note_Clear;
         when Command_Buffer_Switcher_Mark_Review_Toggle =>
            Cmd.Kind := Buffer_Switcher_Mark_Review_Toggle;
         when Command_Buffer_Switcher_Mark_Review_Show =>
            Cmd.Kind := Buffer_Switcher_Mark_Review_Show;
         when Command_Buffer_Switcher_Mark_Review_Hide =>
            Cmd.Kind := Buffer_Switcher_Mark_Review_Hide;
         when Command_Buffer_Switcher_Pending_Mark_Review_Toggle =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Review_Toggle;
         when Command_Buffer_Switcher_Pending_Mark_Review_Show =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Review_Show;
         when Command_Buffer_Switcher_Pending_Mark_Review_Hide =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Review_Hide;
         when Command_Buffer_Switcher_Pending_Mark_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Next;
         when Command_Buffer_Switcher_Pending_Mark_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Remove_Selected =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Remove_Selected;
         when Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Restore_Last_Pruned;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Next;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Review_Show;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Review_Hide;
         when Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Next;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Next;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary;
         when Command_Buffer_Switcher_Mark_Next =>
            Cmd.Kind := Buffer_Switcher_Mark_Next;
         when Command_Buffer_Switcher_Mark_Previous =>
            Cmd.Kind := Buffer_Switcher_Mark_Previous;
         when Command_Buffer_Switcher_Mark_Summary =>
            Cmd.Kind := Buffer_Switcher_Mark_Summary;
         when Command_Open_Project =>
            Cmd.Kind := Open_Project;
         when Command_Switch_Project =>
            Cmd.Kind := Switch_Project;
         when Command_Show_Recent_Projects =>
            Cmd.Kind := Show_Recent_Projects;
         when Command_Open_Selected_Recent_Project =>
            Cmd.Kind := Open_Selected_Recent_Project;
         when Command_Clear_Recent_Projects =>
            Cmd.Kind := Clear_Recent_Projects;
         when Command_Remove_Selected_Recent_Project =>
            Cmd.Kind := Remove_Selected_Recent_Project;
         when Command_Remove_Missing_Recent_Projects =>
            Cmd.Kind := Remove_Missing_Recent_Projects;
         when Command_Select_Next_Recent_Project =>
            Cmd.Kind := Select_Next_Recent_Project;
         when Command_Select_Previous_Recent_Project =>
            Cmd.Kind := Select_Previous_Recent_Project;
         when Command_Close_Project =>
            Cmd.Kind := Close_Project;
         when Command_Clear_Project =>
            Cmd.Kind := Clear_Project;
         when Command_Refresh_File_Tree =>
            Cmd.Kind := Refresh_File_Tree;
         when Command_Refresh_Project_Files =>
            Cmd.Kind := Refresh_Project_Files;
         when Command_Project_Files_Summary =>
            Cmd.Kind := Project_Files_Summary;
         when Command_Reveal_Active_File_In_Tree =>
            Cmd.Kind := Reveal_Active_File_In_Tree;
         when Command_Open_Command_Palette =>
            Cmd.Kind := Open_Command_Palette;
         when Command_Palette_Show_Command_Help =>
            Cmd.Kind := Palette_Show_Command_Help;
         when Command_New_Buffer =>
            Cmd.Kind := New_Buffer;
         when Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close =>
            Cmd.Kind := Close_Buffer;
         when Command_Reopen_Closed_Buffer =>
            Cmd.Kind := Reopen_Closed_Buffer;
         when Command_Close_Other_Buffers =>
            Cmd.Kind := Close_Other_Buffers;
         when Command_Close_All_Buffers =>
            Cmd.Kind := Close_All_Clean_Buffers;
         when Command_Close_All_Clean_Buffers =>
            Cmd.Kind := Close_All_Clean_Buffers;
         when Command_Pin_Buffer =>
            Cmd.Kind := Pin_Buffer;
         when Command_Unpin_Buffer =>
            Cmd.Kind := Unpin_Buffer;
         when Command_Toggle_Buffer_Pin =>
            Cmd.Kind := Toggle_Buffer_Pin;
         when Command_Set_Buffer_Label =>
            Cmd.Kind := Set_Buffer_Label;
         when Command_Clear_Buffer_Label =>
            Cmd.Kind := Clear_Buffer_Label;
         when Command_Edit_Buffer_Label =>
            Cmd.Kind := Edit_Buffer_Label;
         when Command_Show_Buffer_Label =>
            Cmd.Kind := Show_Buffer_Label;
         when Command_Set_Buffer_Note =>
            Cmd.Kind := Set_Buffer_Note;
         when Command_Clear_Buffer_Note =>
            Cmd.Kind := Clear_Buffer_Note;
         when Command_Edit_Buffer_Note =>
            Cmd.Kind := Edit_Buffer_Note;
         when Command_Show_Buffer_Note =>
            Cmd.Kind := Show_Buffer_Note;
         when Command_Assign_Buffer_Group =>
            Cmd.Kind := Assign_Buffer_Group;
         when Command_Clear_Buffer_Group =>
            Cmd.Kind := Clear_Buffer_Group;
         when Command_Switch_Buffer_Group =>
            Cmd.Kind := Switch_Buffer_Group;
         when Command_Next_Buffer_Group =>
            Cmd.Kind := Next_Buffer_Group;
         when Command_Previous_Buffer_Group =>
            Cmd.Kind := Previous_Buffer_Group;
         when Command_Show_All_Buffer_Groups =>
            Cmd.Kind := Show_All_Buffer_Groups;
         when Command_Cancel_Pending_Transition =>
            Cmd.Kind := Cancel_Pending_Transition;
         when Command_Retry_Pending_Transition =>
            Cmd.Kind := Retry_Pending_Transition;
         when Command_Discard_Pending_Transition =>
            Cmd.Kind := Discard_Pending_Transition;
         when Command_Next_Buffer =>
            Cmd.Kind := Next_Buffer;
         when Command_Previous_Buffer =>
            Cmd.Kind := Previous_Buffer;
         when Command_Previous_Recent_Buffer =>
            Cmd.Kind := Previous_Recent_Buffer;
         when Command_Next_Recent_Buffer =>
            Cmd.Kind := Next_Recent_Buffer;
         when Command_Switch_Buffer =>
            Cmd.Kind := Switch_Buffer;
         when Command_Toggle_Problems_Panel =>
            Cmd.Kind := Toggle_Problems_Panel;
         when Command_Next_Diagnostic =>
            Cmd.Kind := Next_Diagnostic;
         when Command_Previous_Diagnostic =>
            Cmd.Kind := Previous_Diagnostic;
         when Command_Toggle_Bookmark =>
            Cmd.Kind := Toggle_Bookmark;
         when Command_Next_Bookmark =>
            Cmd.Kind := Next_Bookmark;
         when Command_Previous_Bookmark =>
            Cmd.Kind := Previous_Bookmark;
         when Command_Clear_Bookmarks =>
            Cmd.Kind := Clear_Bookmarks;
         when Command_Clear_All_Bookmarks =>
            Cmd.Kind := Clear_All_Bookmarks;
         when Command_Bookmark_Toggle_Current_Location =>
            Cmd.Kind := Bookmark_Toggle_Current_Location;
         when Command_Bookmark_Clear_All =>
            Cmd.Kind := Bookmark_Clear_All;
         when Command_Bookmark_Next =>
            Cmd.Kind := Bookmark_Next;
         when Command_Bookmark_Previous =>
            Cmd.Kind := Bookmark_Previous;
         when Command_Bookmark_Goto_Next =>
            Cmd.Kind := Bookmark_Goto_Next;
         when Command_Bookmark_Goto_Previous =>
            Cmd.Kind := Bookmark_Goto_Previous;
         when Command_Bookmark_Open_Selected =>
            Cmd.Kind := Bookmark_Open_Selected;
         when Command_Bookmark_Reveal_Current =>
            Cmd.Kind := Bookmark_Reveal_Current;
         when Command_Bookmark_Remove_Selected =>
            Cmd.Kind := Bookmark_Remove_Selected;
         when Command_Bookmark_Show =>
            Cmd.Kind := Bookmark_Show;
         when Command_Bookmark_Hide =>
            Cmd.Kind := Bookmark_Hide;
         when Command_Bookmark_Toggle =>
            Cmd.Kind := Bookmark_Toggle;
         when Command_Cancel =>
            Cmd.Kind := Clear_Extra_Carets;
         when Command_Goto_Start =>
            Cmd.Kind := Move_Document_Start;
         when Command_Goto_End =>
            Cmd.Kind := Move_Document_End;
         when Command_Goto_Line =>
            Cmd.Kind := Open_Goto_Line;
         when Command_Goto_Line_Toggle =>
            Cmd.Kind := Toggle_Goto_Line;
         when Command_Goto_Line_Prefill_Current =>
            Cmd.Kind := Prefill_Goto_Line_Current;
         when Command_Goto_Line_Query_Set =>
            Cmd.Kind := Goto_Line_Query_Set;
         when Command_Goto_Line_Query_Clear =>
            Cmd.Kind := Goto_Line_Query_Clear;
         when Command_Navigation_Back =>
            Cmd.Kind := Navigation_Back;
         when Command_Navigation_Forward =>
            Cmd.Kind := Navigation_Forward;
         when Command_Navigation_History_Clear =>
            Cmd.Kind := Navigation_History_Clear;
         when Command_Close_Goto_Line =>
            Cmd.Kind := Close_Goto_Line;
         when Command_Accept_Goto_Line =>
            Cmd.Kind := Accept_Goto_Line;
         when Command_Find_Show =>
            Cmd.Kind := Active_Find_Show;
         when Command_Find_Hide =>
            Cmd.Kind := Active_Find_Hide;
         when Command_Find_Toggle =>
            Cmd.Kind := Active_Find_Toggle;
         when Command_Find_Query_Set =>
            Cmd.Kind := Active_Find_Query_Set;
         when Command_Find_Query_Clear =>
            Cmd.Kind := Active_Find_Query_Clear;
         when Command_Find_Case_Toggle =>
            Cmd.Kind := Active_Find_Case_Toggle;
         when Command_Find_Case_Clear =>
            Cmd.Kind := Active_Find_Case_Clear;
         when Command_Find_Whole_Word_Toggle =>
            Cmd.Kind := Active_Find_Whole_Word_Toggle;
         when Command_Find_Whole_Word_Clear =>
            Cmd.Kind := Active_Find_Whole_Word_Clear;
         when Command_Find_From_Selection =>
            Cmd.Kind := Active_Find_From_Selection;
         when Command_Find_From_Active_Word =>
            Cmd.Kind := Active_Find_From_Active_Word;
         when Command_Active_Find_Next =>
            Cmd.Kind := Active_Find_Next;
         when Command_Active_Find_Previous =>
            Cmd.Kind := Active_Find_Previous;
         when Command_Find_First =>
            Cmd.Kind := Active_Find_First;
         when Command_Find_Last =>
            Cmd.Kind := Active_Find_Last;
         when Command_Find_Reveal_Current =>
            Cmd.Kind := Active_Find_Reveal_Current;
         when Command_Replace_Show =>
            Cmd.Kind := Active_Replace_Show;
         when Command_Replace_Hide =>
            Cmd.Kind := Active_Replace_Hide;
         when Command_Replace_Toggle =>
            Cmd.Kind := Active_Replace_Toggle;
         when Command_Replace_Text_Set =>
            Cmd.Kind := Active_Replace_Text_Set;
         when Command_Replace_Text_Clear =>
            Cmd.Kind := Active_Replace_Text_Clear;
         when Command_Replace_Current =>
            Cmd.Kind := Active_Replace_Current;
         when Command_Replace_All =>
            Cmd.Kind := Active_Replace_All;
         when Command_Run_Project_Search =>
            Cmd.Kind := Run_Project_Search;
         when Command_Rerun_Project_Search =>
            Cmd.Kind := Rerun_Project_Search;
         when Command_Open_Project_Search_Bar =>
            Cmd.Kind := Open_Project_Search_Bar;
         when Command_Toggle_Project_Search_Bar =>
            Cmd.Kind := Toggle_Project_Search_Bar;
         when Command_Close_Project_Search_Bar =>
            Cmd.Kind := Close_Project_Search_Bar;
         when Command_Run_Project_Search_From_Bar =>
            Cmd.Kind := Run_Project_Search_From_Bar;
         when Command_Project_Search_From_Selection =>
            Cmd.Kind := Project_Search_From_Selection;
         when Command_Project_Search_From_Active_Word =>
            Cmd.Kind := Project_Search_From_Active_Word;
         when Command_Project_Search_Active_Directory =>
            Cmd.Kind := Project_Search_Active_Directory;
         when Command_Clear_Project_Search =>
            Cmd.Kind := Clear_Project_Search;
         when Command_Open_Selected_Project_Search_Result =>
            Cmd.Kind := Open_Selected_Project_Search_Result;
         when Command_Move_Project_Search_Selection_Up =>
            Cmd.Kind := Move_Project_Search_Selection_Up;
         when Command_Move_Project_Search_Selection_Down =>
            Cmd.Kind := Move_Project_Search_Selection_Down;
         when Command_Next_Project_Search_Result =>
            Cmd.Kind := Next_Project_Search_Result;
         when Command_Previous_Project_Search_Result =>
            Cmd.Kind := Previous_Project_Search_Result;
         when Command_First_Project_Search_Result =>
            Cmd.Kind := First_Project_Search_Result;
         when Command_Last_Project_Search_Result =>
            Cmd.Kind := Last_Project_Search_Result;
         when Command_Reveal_Active_Project_Search_Result =>
            Cmd.Kind := Reveal_Active_Project_Search_Result;
         when Command_Project_Search_Scope_Selected_Directory =>
            Cmd.Kind := Project_Search_Scope_Selected_Directory;
         when Command_Project_Search_Kind_Next =>
            Cmd.Kind := Project_Search_Kind_Next;
         when Command_Project_Search_Kind_Previous =>
            Cmd.Kind := Project_Search_Kind_Previous;
         when Command_Project_Search_Kind_Clear =>
            Cmd.Kind := Project_Search_Kind_Clear;
         when Command_Project_Search_Scope_Set =>
            Cmd.Kind := Project_Search_Scope_Set;
         when Command_Project_Search_Scope_Clear =>
            Cmd.Kind := Project_Search_Scope_Clear;
         when Command_Project_Search_Case_Toggle =>
            Cmd.Kind := Project_Search_Case_Toggle;
         when Command_Project_Search_Case_Clear =>
            Cmd.Kind := Project_Search_Case_Clear;
         when Command_Project_Search_Whole_Word_Toggle =>
            Cmd.Kind := Project_Search_Whole_Word_Toggle;
         when Command_Project_Search_Whole_Word_Clear =>
            Cmd.Kind := Project_Search_Whole_Word_Clear;
         when Command_Project_Search_Regex_Toggle =>
            Cmd.Kind := Project_Search_Regex_Toggle;
         when Command_Project_Search_Regex_Clear =>
            Cmd.Kind := Project_Search_Regex_Clear;
         when Command_Project_Search_Include_Filter_Set =>
            Cmd.Kind := Project_Search_Include_Filter_Set;
         when Command_Project_Search_Exclude_Filter_Set =>
            Cmd.Kind := Project_Search_Exclude_Filter_Set;
         when Command_Project_Search_Include_Filter_Clear =>
            Cmd.Kind := Project_Search_Include_Filter_Clear;
         when Command_Project_Search_Exclude_Filter_Clear =>
            Cmd.Kind := Project_Search_Exclude_Filter_Clear;
         when Command_Project_Search_Replace_Preview =>
            Cmd.Kind := Project_Search_Replace_Preview;
         when Command_Project_Search_Replace_Toggle_Selected =>
            Cmd.Kind := Project_Search_Replace_Toggle_Selected;
         when Command_Project_Search_Replace_Include_Selected =>
            Cmd.Kind := Project_Search_Replace_Include_Selected;
         when Command_Project_Search_Replace_Exclude_Selected =>
            Cmd.Kind := Project_Search_Replace_Exclude_Selected;
         when Command_Project_Search_Replace_Include_File =>
            Cmd.Kind := Project_Search_Replace_Include_File;
         when Command_Project_Search_Replace_Exclude_File =>
            Cmd.Kind := Project_Search_Replace_Exclude_File;
         when Command_Project_Search_Replace_Include_All =>
            Cmd.Kind := Project_Search_Replace_Include_All;
         when Command_Project_Search_Replace_Exclude_All =>
            Cmd.Kind := Project_Search_Replace_Exclude_All;
         when Command_Project_Search_Replace_Selected =>
            Cmd.Kind := Project_Search_Replace_Selected;
         when Command_Project_Search_Replace_All_Included =>
            Cmd.Kind := Project_Search_Replace_All_Included;
         when Command_Project_Search_Replace_Clear_Preview =>
            Cmd.Kind := Project_Search_Replace_Clear_Preview;
         when Command_Show_Search_Results_Panel =>
            Cmd.Kind := Show_Search_Results_Panel;
         when Command_Focus_Editor_Text =>
            Cmd.Kind := Focus_Editor_Text;
         when Command_Focus_Search_Results =>
            Cmd.Kind := Focus_Search_Results;
         when Command_Focus_Problems =>
            Cmd.Kind := Focus_Problems;
         when Command_Toggle_Bottom_Panel_Focus =>
            Cmd.Kind := Toggle_Bottom_Panel_Focus;
         when Command_Search_Results_Move_Up =>
            Cmd.Kind := Search_Results_Move_Up;
         when Command_Search_Results_Move_Down =>
            Cmd.Kind := Search_Results_Move_Down;
         when Command_Search_Results_Page_Up =>
            Cmd.Kind := Search_Results_Page_Up;
         when Command_Search_Results_Page_Down =>
            Cmd.Kind := Search_Results_Page_Down;
         when Command_Search_Results_Open_Selected =>
            Cmd.Kind := Search_Results_Open_Selected;
         when Command_Problems_Move_Up =>
            Cmd.Kind := Problems_Move_Up;
         when Command_Problems_Move_Down =>
            Cmd.Kind := Problems_Move_Down;
         when Command_Problems_Page_Up =>
            Cmd.Kind := Problems_Page_Up;
         when Command_Problems_Page_Down =>
            Cmd.Kind := Problems_Page_Down;
         when Command_Problems_Open_Selected =>
            Cmd.Kind := Problems_Open_Selected;
         when Command_Problems_Filter_All =>
            Cmd.Kind := Problems_Filter_All;
         when Command_Problems_Filter_Errors =>
            Cmd.Kind := Problems_Filter_Errors;
         when Command_Problems_Filter_Warnings =>
            Cmd.Kind := Problems_Filter_Warnings;
         when Command_Problems_Filter_Info =>
            Cmd.Kind := Problems_Filter_Info;
         when Command_Problems_Filter_Hints =>
            Cmd.Kind := Problems_Filter_Hints;
         when Command_Problems_Sort_By_Location =>
            Cmd.Kind := Problems_Sort_By_Location;
         when Command_Problems_Sort_By_Severity =>
            Cmd.Kind := Problems_Sort_By_Severity;
         when Command_Problems_Sort_By_Source =>
            Cmd.Kind := Problems_Sort_By_Source;
         when Command_Problems_Group_By_Severity =>
            Cmd.Kind := Problems_Group_By_Severity;
         when Command_Problems_Group_By_Source =>
            Cmd.Kind := Problems_Group_By_Source;
         when Command_Problems_Focus_Editor =>
            Cmd.Kind := Problems_Focus_Editor;
         when Command_Focus_File_Tree =>
            Cmd.Kind := Focus_File_Tree;
         when Command_File_Tree_Move_Up =>
            Cmd.Kind := File_Tree_Move_Up;
         when Command_File_Tree_Move_Down =>
            Cmd.Kind := File_Tree_Move_Down;
         when Command_File_Tree_Page_Up =>
            Cmd.Kind := File_Tree_Page_Up;
         when Command_File_Tree_Page_Down =>
            Cmd.Kind := File_Tree_Page_Down;
         when Command_File_Tree_Open_Selected =>
            Cmd.Kind := File_Tree_Open_Selected;
         when Command_File_Tree_Create_File =>
            Cmd.Kind := File_Tree_Create_File;
         when Command_File_Tree_Create_Directory =>
            Cmd.Kind := File_Tree_Create_Directory;
         when Command_File_Tree_Rename_Selected =>
            Cmd.Kind := File_Tree_Rename_Selected;
         when Command_File_Tree_Delete_Selected =>
            Cmd.Kind := File_Tree_Delete_Selected;
         when Command_File_Tree_Expand_Selected =>
            Cmd.Kind := File_Tree_Expand_Selected;
         when Command_File_Tree_Collapse_Selected =>
            Cmd.Kind := File_Tree_Collapse_Selected;
         when Command_File_Tree_Toggle_Selected =>
            Cmd.Kind := File_Tree_Toggle_Selected;
         when Command_File_Tree_Collapse_All =>
            Cmd.Kind := File_Tree_Collapse_All;
         when Command_File_Tree_Expand_To_Active_File =>
            Cmd.Kind := File_Tree_Expand_To_Active_File;
         when Command_Toggle_Theme =>
            Cmd.Kind := Toggle_Theme;
         when Command_Set_Theme_Light =>
            Cmd.Kind := Set_Theme_Light;
         when Command_Set_Theme_Dark =>
            Cmd.Kind := Set_Theme_Dark;
         when Command_Toggle_Minimap =>
            Cmd.Kind := Toggle_Minimap;
         when Command_Toggle_Scrollbars =>
            Cmd.Kind := Toggle_Scrollbars;
         when Command_Toggle_Line_Number_Mode =>
            Cmd.Kind := Toggle_Line_Number_Mode;
         when Command_Toggle_Cursor_Blink =>
            Cmd.Kind := Toggle_Cursor_Blink;
         when Command_Save_Settings =>
            Cmd.Kind := Save_Settings;
         when Command_Reload_Settings =>
            Cmd.Kind := Reload_Settings;
         when Command_Reset_Settings_To_Defaults =>
            Cmd.Kind := Reset_Settings_To_Defaults;
         when Command_Save_Keybindings =>
            Cmd.Kind := Save_Keybindings;
         when Command_Reload_Keybindings =>
            Cmd.Kind := Reload_Keybindings;
         when Command_Validate_Keybindings =>
            Cmd.Kind := Validate_Keybindings;
         when Command_Keybindings_Show =>
            Cmd.Kind := Keybindings_Show;
         when Command_Keybindings_Focus =>
            Cmd.Kind := Keybindings_Focus;
         when Command_Keybindings_Assign_Selected =>
            Cmd.Kind := Keybindings_Assign_Selected;
         when Command_Keybindings_Remove_Selected =>
            Cmd.Kind := Keybindings_Remove_Selected;
         when Command_Keybindings_Reset_To_Defaults =>
            Cmd.Kind := Keybindings_Reset_To_Defaults;
         when Command_Keybindings_Filter_Conflicts =>
            Cmd.Kind := Keybindings_Filter_Conflicts;
         when Command_Keybindings_Filter_Unbound =>
            Cmd.Kind := Keybindings_Filter_Unbound;
         when Command_Keybindings_Clear_Filter =>
            Cmd.Kind := Keybindings_Clear_Filter;
         when Command_Keybindings_Cancel_Capture =>
            Cmd.Kind := Keybindings_Cancel_Capture;
         when Command_Startup_Show_Summary =>
            Cmd.Kind := Startup_Show_Summary;
         when Command_Configuration_Recover_Show =>
            Cmd.Kind := Configuration_Recover_Show;
         when Command_Configuration_Audit =>
            Cmd.Kind := Configuration_Audit;
         when Command_Configuration_Reset_Settings =>
            Cmd.Kind := Configuration_Reset_Settings;
         when Command_Configuration_Reset_Keybindings =>
            Cmd.Kind := Configuration_Reset_Keybindings;
         when Command_Configuration_Reset_Workspace =>
            Cmd.Kind := Configuration_Reset_Workspace;
         when Command_Configuration_Reset_Recent_Projects =>
            Cmd.Kind := Configuration_Reset_Recent_Projects;
         when Command_Configuration_Reset_All =>
            Cmd.Kind := Configuration_Reset_All;
         when Command_Configuration_Reset_All_Confirm =>
            Cmd.Kind := Configuration_Reset_All_Confirm;
         when Command_Configuration_Reset_All_Cancel =>
            Cmd.Kind := Configuration_Reset_All_Cancel;
         when Command_Configuration_Save_Clean_Settings =>
            Cmd.Kind := Configuration_Save_Clean_Settings;
         when Command_Configuration_Save_Clean_Keybindings =>
            Cmd.Kind := Configuration_Save_Clean_Keybindings;
         when Command_Configuration_Save_Clean_Workspace =>
            Cmd.Kind := Configuration_Save_Clean_Workspace;
         when Command_Configuration_Save_Clean_Recent_Projects =>
            Cmd.Kind := Configuration_Save_Clean_Recent_Projects;
         when Command_Save_Workspace_State =>
            Cmd.Kind := Save_Workspace_State;
         when Command_Restore_Workspace_State =>
            Cmd.Kind := Restore_Workspace_State;
         when Command_Clear_Workspace_State =>
            Cmd.Kind := Clear_Workspace_State;
         when Command_Toggle_Feature_Panel =>
            Cmd.Kind := Toggle_Feature_Panel;
         when Command_Show_Feature_Panel =>
            Cmd.Kind := Show_Feature_Panel;
         when Command_Hide_Feature_Panel =>
            Cmd.Kind := Hide_Feature_Panel;
         when Command_Focus_Feature_Panel =>
            Cmd.Kind := Focus_Feature_Panel;
         when Command_Clear_Feature_Panel =>
            Cmd.Kind := Clear_Feature_Panel;
         when Command_Feature_Panel_Select_Next =>
            Cmd.Kind := Feature_Panel_Select_Next;
         when Command_Feature_Panel_Select_Previous =>
            Cmd.Kind := Feature_Panel_Select_Previous;
         when Command_Feature_Panel_Open_Selected =>
            Cmd.Kind := Feature_Panel_Open_Selected;
         when Command_Build_UI_Toggle =>
            Cmd.Kind := Build_UI_Toggle;
         when Command_Build_UI_Show =>
            Cmd.Kind := Build_UI_Show;
         when Command_Build_UI_Hide =>
            Cmd.Kind := Build_UI_Hide;
         when Command_Build_UI_Focus =>
            Cmd.Kind := Build_UI_Focus;
         when Command_Build_Result_Focus =>
            Cmd.Kind := Build_Result_Focus;
         when Command_Build_Output_Details_Focus =>
            Cmd.Kind := Build_Output_Details_Focus;
         when Command_Build_Output_Details_Select_Stdout =>
            Cmd.Kind := Build_Output_Details_Select_Stdout;
         when Command_Build_Output_Details_Select_Stderr =>
            Cmd.Kind := Build_Output_Details_Select_Stderr;
         when Command_Build_Output_Details_Select_Merged =>
            Cmd.Kind := Build_Output_Details_Select_Merged;
         when Command_Build_Refresh_Candidates =>
            Cmd.Kind := Build_Refresh_Candidates;
         when Command_Build_Select_First_Candidate =>
            Cmd.Kind := Build_Select_First_Candidate;
         when Command_Build_Select_Next_Candidate =>
            Cmd.Kind := Build_Select_Next_Candidate;
         when Command_Build_Select_Previous_Candidate =>
            Cmd.Kind := Build_Select_Previous_Candidate;
         when Command_Build_Clear_Selected_Candidate =>
            Cmd.Kind := Build_Clear_Selected_Candidate;
         when Command_Build_Set_Mode_Default =>
            Cmd.Kind := Build_Set_Mode_Default;
         when Command_Build_Set_Mode_Debug =>
            Cmd.Kind := Build_Set_Mode_Debug;
         when Command_Build_Set_Mode_Release =>
            Cmd.Kind := Build_Set_Mode_Release;
         when Command_Build_Set_Mode_Validation =>
            Cmd.Kind := Build_Set_Mode_Validation;
         when Command_Build_Toggle_Diagnostics_Ingestion =>
            Cmd.Kind := Build_Toggle_Diagnostics_Ingestion;
         when Command_Build_Cycle_Output_Limit =>
            Cmd.Kind := Build_Cycle_Output_Limit;
         when Command_Build_Toggle_Option_Verbose =>
            Cmd.Kind := Build_Toggle_Option_Verbose;
         when Command_Build_Toggle_Option_Keep_Going =>
            Cmd.Kind := Build_Toggle_Option_Keep_Going;
         when Command_Build_Acknowledge_Consent =>
            Cmd.Kind := Build_Acknowledge_Consent;
         when Command_Build_Clear_Consent =>
            Cmd.Kind := Build_Clear_Consent;
         when Command_Build_Cancel =>
            Cmd.Kind := Build_Cancel;
         when Command_Refresh_Outline =>
            Cmd.Kind := Refresh_Outline;
         when Command_Refresh_Outline_Project_Index =>
            Cmd.Kind := Refresh_Outline_Project_Index;
         when Command_Goto_Declaration =>
            Cmd.Kind := Goto_Declaration;
         when Command_Goto_Body =>
            Cmd.Kind := Goto_Body;
         when Command_Goto_Spec =>
            Cmd.Kind := Goto_Spec;
         when Command_Find_References =>
            Cmd.Kind := Find_References;
         when Command_Workspace_Symbols =>
            Cmd.Kind := Workspace_Symbols;
         when Command_Show_Hover =>
            Cmd.Kind := Show_Hover;
         when Command_Show_Completions =>
            Cmd.Kind := Show_Completions;
         when Command_Semantic_Completion_Select_Next =>
            Cmd.Kind := Semantic_Completion_Select_Next;
         when Command_Semantic_Completion_Select_Previous =>
            Cmd.Kind := Semantic_Completion_Select_Previous;
         when Command_Semantic_Completion_Accept =>
            Cmd.Kind := Semantic_Completion_Accept;
         when Command_Semantic_Popup_Dismiss =>
            Cmd.Kind := Semantic_Popup_Dismiss;
         when Command_Rename_Symbol_Preview =>
            Cmd.Kind := Rename_Symbol_Preview;
         when Command_Rename_Symbol_Apply =>
            Cmd.Kind := Rename_Symbol_Apply;
         when Command_Semantic_Refresh_Buffer =>
            Cmd.Kind := Semantic_Refresh_Buffer;
         when Command_Semantic_Refresh_Project_Index =>
            Cmd.Kind := Semantic_Refresh_Project_Index;
         when Command_Language_Index_Clear =>
            Cmd.Kind := Language_Index_Clear;
         when Command_Language_Index_Status =>
            Cmd.Kind := Language_Index_Status;
         when Command_Clear_Outline =>
            Cmd.Kind := Clear_Outline;
         when Command_Show_Outline =>
            Cmd.Kind := Show_Outline;
         when Command_Focus_Outline =>
            Cmd.Kind := Focus_Outline;
         when Command_Open_Selected_Outline_Item =>
            Cmd.Kind := Open_Selected_Outline_Item;
         when Command_Select_Current_Outline_Symbol =>
            Cmd.Kind := Select_Current_Outline_Symbol;
         when Command_Reveal_Current_Outline_Symbol =>
            Cmd.Kind := Reveal_Current_Outline_Symbol;
         when Command_Next_Outline_Symbol =>
            Cmd.Kind := Next_Outline_Symbol;
         when Command_Previous_Outline_Symbol =>
            Cmd.Kind := Previous_Outline_Symbol;
         when Command_Select_Next_Outline_Item =>
            Cmd.Kind := Select_Next_Outline_Item;
         when Command_Select_Previous_Outline_Item =>
            Cmd.Kind := Select_Previous_Outline_Item;
         when Command_Focus_Outline_Filter =>
            Cmd.Kind := Focus_Outline_Filter;
         when Command_Filter_Outline =>
            Cmd.Kind := Filter_Outline;
         when Command_Clear_Outline_Filter =>
            Cmd.Kind := Clear_Outline_Filter;
         when Command_Toggle_Outline_Filter =>
            Cmd.Kind := Toggle_Outline_Filter;
         when Command_Outline_Filter_History_Previous =>
            Cmd.Kind := Outline_Filter_History_Previous;
         when Command_Outline_Filter_History_Next =>
            Cmd.Kind := Outline_Filter_History_Next;
         when Command_Clear_Outline_Filter_History =>
            Cmd.Kind := Clear_Outline_Filter_History;
         when Command_Show_Messages =>
            Cmd.Kind := Show_Messages;
         when Command_Clear_Messages =>
            Cmd.Kind := Clear_Messages;
         when Command_Search_Results_Search_Active_Buffer =>
            Cmd.Kind := Search_Results_Search_Active_Buffer;
         when Command_Search_Results_Focus_Query =>
            Cmd.Kind := Search_Results_Focus_Query;
         when Command_Search_Results_Repeat_Active_Buffer =>
            Cmd.Kind := Search_Results_Repeat_Active_Buffer;
         when Command_Search_Results_Query_History_Previous =>
            Cmd.Kind := Search_Results_Query_History_Previous;
         when Command_Search_Results_Query_History_Next =>
            Cmd.Kind := Search_Results_Query_History_Next;
         when Command_Search_Results_Toggle_Case_Sensitive =>
            Cmd.Kind := Search_Results_Toggle_Case_Sensitive;
         when Command_Show_Search_Results_Feature =>
            Cmd.Kind := Show_Search_Results_Feature;
         when Command_Clear_Search_Results_Feature =>
            Cmd.Kind := Clear_Search_Results_Feature;
         when Command_Diagnostics_Show =>
            Cmd.Kind := Diagnostics_Show;
         when Command_Diagnostics_Clear =>
            Cmd.Kind := Diagnostics_Clear;
         when Command_Diagnostics_Toggle_Info =>
            Cmd.Kind := Diagnostics_Toggle_Info;
         when Command_Diagnostics_Toggle_Warnings =>
            Cmd.Kind := Diagnostics_Toggle_Warnings;
         when Command_Diagnostics_Toggle_Errors =>
            Cmd.Kind := Diagnostics_Toggle_Errors;
         when Command_Diagnostics_Show_All =>
            Cmd.Kind := Diagnostics_Show_All;
         when Command_Diagnostics_Clear_Filter =>
            Cmd.Kind := Diagnostics_Clear_Filter;
         when Command_Diagnostics_Filter_Errors =>
            Cmd.Kind := Diagnostics_Filter_Errors;
         when Command_Diagnostics_Filter_Warnings =>
            Cmd.Kind := Diagnostics_Filter_Warnings;
         when Command_Diagnostics_Filter_Info_Notes =>
            Cmd.Kind := Diagnostics_Filter_Info_Notes;
         when Command_Diagnostics_Filter_Source =>
            Cmd.Kind := Diagnostics_Filter_Source;
         when Command_Diagnostics_Filter_Build =>
            Cmd.Kind := Diagnostics_Filter_Build;
         when Command_Diagnostics_Clear_Build =>
            Cmd.Kind := Diagnostics_Clear_Build;
         when Command_Diagnostics_Open_Selected =>
            Cmd.Kind := Diagnostics_Open_Selected;
         when Command_Diagnostic_Open_Source =>
            Cmd.Kind := Diagnostic_Open_Source;
         when Command_Diagnostic_Suppress_Selected =>
            Cmd.Kind := Diagnostic_Suppress_Selected;
         when Command_Diagnostic_Show_Suppressed =>
            Cmd.Kind := Diagnostic_Show_Suppressed;
         when Command_Diagnostic_Restore_Last_Suppressed =>
            Cmd.Kind := Diagnostic_Restore_Last_Suppressed;
         when Command_Diagnostic_Restore_Selected_Suppressed =>
            Cmd.Kind := Diagnostic_Restore_Selected_Suppressed;
         when Command_Diagnostic_Clear_Suppressed =>
            Cmd.Kind := Diagnostic_Clear_Suppressed;
         when Command_Diagnostic_Apply_Quick_Fix =>
            Cmd.Kind := Diagnostic_Apply_Quick_Fix;
         when Command_Diagnostics_Execute_Selected_Action =>
            Cmd.Kind := Diagnostics_Execute_Selected_Action;
         when Command_Diagnostics_Select_Next =>
            Cmd.Kind := Diagnostics_Select_Next;
         when Command_Diagnostics_Select_Previous =>
            Cmd.Kind := Diagnostics_Select_Previous;
         when Command_Diagnostics_Clear_Selected =>
            Cmd.Kind := Diagnostics_Clear_Selected;
         when Command_Diagnostics_Copy_Selected_Text =>
            Cmd.Kind := Diagnostics_Copy_Selected_Text;
         when Command_Diagnostics_Clear_Info =>
            Cmd.Kind := Diagnostics_Clear_Info;
         when Command_Diagnostics_Clear_Warnings =>
            Cmd.Kind := Diagnostics_Clear_Warnings;
         when Command_Diagnostics_Clear_Errors =>
            Cmd.Kind := Diagnostics_Clear_Errors;
         when Command_Diagnostics_Toggle_Editor_Source =>
            Cmd.Kind := Diagnostics_Toggle_Editor_Source;
         when Command_Diagnostics_Toggle_File_Source =>
            Cmd.Kind := Diagnostics_Toggle_File_Source;
         when Command_Diagnostics_Toggle_Project_Source =>
            Cmd.Kind := Diagnostics_Toggle_Project_Source;
         when Command_Diagnostics_Toggle_External_Source =>
            Cmd.Kind := Diagnostics_Toggle_External_Source;
         when Command_Diagnostics_Toggle_Unknown_Source =>
            Cmd.Kind := Diagnostics_Toggle_Unknown_Source;
         when Command_Run_Project =>
            Cmd.Kind := Run_Project;
         when Command_Run_Tests =>
            Cmd.Kind := Run_Tests;
         when Command_Terminal_Toggle =>
            Cmd.Kind := Terminal_Toggle;
         when Command_Terminal_Show =>
            Cmd.Kind := Terminal_Show;
         when Command_Terminal_Hide =>
            Cmd.Kind := Terminal_Hide;
         when Command_Terminal_Focus =>
            Cmd.Kind := Terminal_Focus;
         when Command_Terminal_Clear =>
            Cmd.Kind := Terminal_Clear;
         when Command_Terminal_Clear_Output =>
            Cmd.Kind := Terminal_Clear_Output;
         when Command_Terminal_Select_Next_Task =>
            Cmd.Kind := Terminal_Select_Next_Task;
         when Command_Terminal_Select_Previous_Task =>
            Cmd.Kind := Terminal_Select_Previous_Task;
         when Command_Terminal_Run_Selected_Task =>
            Cmd.Kind := Terminal_Run_Selected_Task;
         when Command_Terminal_Rerun_Last_Task =>
            Cmd.Kind := Terminal_Rerun_Last_Task;
         when Command_Terminal_Cancel_Task =>
            Cmd.Kind := Terminal_Cancel_Task;
         when Command_Clear_Selected_Message =>
            Cmd.Kind := Clear_Selected_Message;
         when Command_Copy_Selected_Message_Text =>
            Cmd.Kind := Copy_Selected_Message_Text;
         when Command_Clear_Info_Messages =>
            Cmd.Kind := Clear_Info_Messages;
         when Command_Clear_Warning_Messages =>
            Cmd.Kind := Clear_Warning_Messages;
         when Command_Clear_Error_Messages =>
            Cmd.Kind := Clear_Error_Messages;
         when Command_Toggle_Message_Info =>
            Cmd.Kind := Toggle_Message_Info;
         when Command_Toggle_Message_Warnings =>
            Cmd.Kind := Toggle_Message_Warnings;
         when Command_Toggle_Message_Errors =>
            Cmd.Kind := Toggle_Message_Errors;
         when Command_Show_All_Messages =>
            Cmd.Kind := Show_All_Messages;
         when Command_Clear_Message_Filter =>
            Cmd.Kind := Clear_Message_Filter;
         when others =>
            Cmd.Kind := Break_Group;
      end case;

      return Cmd;
   end Command_For_Id;


   function Is_File_Lifecycle_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_File
            | Command_Save_File_As
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close
            | Command_Reopen_Closed_Buffer
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File =>
            return True;
         when others =>
            return False;
      end case;
   end Is_File_Lifecycle_Command;

   function Reference_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Reference_Summary;

   function Reference_Availability_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Reference_Availability_Summary;

   function Reference_Mutation_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Reference_Mutation_Summary;

   function Reference_Filesystem_Effect_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Reference_Filesystem_Effect_Summary;

   function Reference_State_Preservation_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Reference_State_Preservation_Summary;

   function Reference_Non_Goal_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Reference_Non_Goal_Summary;

   function Reference_Command_Family
     (Id : Command_Id) return Command_Family_Id
     renames Editor.Commands.Reference_Metadata.Reference_Command_Family;

   function Reference_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id
     renames Editor.Commands.Reference_Metadata.Reference_Effect_Classification;

   function Command_Requires_Explicit_Target
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Reference_Metadata.Command_Requires_Explicit_Target;

   function Command_Is_Target_Prompt_Capable
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Reference_Metadata.Command_Is_Target_Prompt_Capable;

   function Command_Target_Prompt_Label
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Command_Target_Prompt_Label;

   function Command_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Command_Summary;

   function Command_Availability_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Command_Availability_Summary;

   function Command_Mutation_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Command_Mutation_Summary;

   function Command_Filesystem_Effect_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Command_Filesystem_Effect_Summary;

   function Command_State_Preservation_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Command_State_Preservation_Summary;

   function Command_Non_Goal_Summary
     (Id : Command_Id) return String
     renames Editor.Commands.Reference_Metadata.Command_Non_Goal_Summary;

   function Command_Family
     (Id : Command_Id) return Command_Family_Id
     renames Editor.Commands.Reference_Metadata.Command_Family;

   function Command_Family_Label
     (Family : Command_Family_Id) return String
     renames Editor.Commands.Reference_Metadata.Command_Family_Label;

   function Command_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id
     renames Editor.Commands.Reference_Metadata.Command_Effect_Classification;

   function Command_Effect_Classification_Label
     (Effect : Command_Effect_Classification_Id) return String
     renames Editor.Commands.Reference_Metadata.Command_Effect_Classification_Label;

   function File_Lifecycle_Target_Prompt_Metadata_Minimal return Boolean
     renames Editor.Commands.Reference_Metadata.File_Lifecycle_Target_Prompt_Metadata_Minimal;

   function File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal
     return Boolean
     renames Editor.Commands.Reference_Metadata.File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal;

   function File_Lifecycle_Target_Prompt_Metadata_Frozen return Boolean
     renames Editor.Commands.Reference_Metadata.File_Lifecycle_Target_Prompt_Metadata_Frozen;

   function Has_Command_Reference
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_File
            | Command_Save_File_As
            | Command_Close_Active_Buffer
            | Command_Reopen_Closed_Buffer
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File =>
            null;
         when others =>
            return False;
      end case;

      return Is_File_Lifecycle_Command (Id)
        and then Command_Family (Id) = File_Lifecycle_Family
        and then Command_Effect_Classification (Id) /= No_Command_Effect
        and then Command_Summary (Id)'Length > 0
        and then Command_Availability_Summary (Id)'Length > 0
        and then Command_Mutation_Summary (Id)'Length > 0
        and then Command_Filesystem_Effect_Summary (Id)'Length > 0
        and then Command_State_Preservation_Summary (Id)'Length > 0
        and then Command_Non_Goal_Summary (Id)'Length > 0;
   end Has_Command_Reference;

   function File_Lifecycle_Command_Reference_Coherent return Boolean
   is
      Covered : constant array (Positive range 1 .. 10) of Command_Id :=
        (Command_Save_File,
         Command_Save_File_As,
         Command_Close_Active_Buffer,
         Command_Reopen_Closed_Buffer,
         Command_Reload_Active_Buffer,
         Command_Revert_Active_Buffer,
         Command_Rename_Buffer_File,
         Command_Delete_Buffer_File,
         Command_Copy_Buffer_File,
         Command_Move_Buffer_File);
      Seen : array (Command_Effect_Classification_Id) of Boolean :=
        (others => False);
      D : Command_Descriptor;
   begin
      for Id of Covered loop
         D := Descriptor (Id);
         if D.Id /= Id
           or else D.Category /= File_Category
           or else D.Family /= File_Lifecycle_Family
           or else D.Effect_Classification /= Command_Effect_Classification (Id)
           or else not Has_Command_Reference (Id)
           or else To_String (D.Summary) /= Command_Summary (Id)
           or else To_String (D.Availability_Summary) /= Command_Availability_Summary (Id)
           or else To_String (D.Mutation_Summary) /= Command_Mutation_Summary (Id)
           or else To_String (D.Filesystem_Effect_Summary) /= Command_Filesystem_Effect_Summary (Id)
           or else To_String (D.State_Preservation_Summary) /= Command_State_Preservation_Summary (Id)
           or else To_String (D.Non_Goal_Summary) /= Command_Non_Goal_Summary (Id)
         then
            return False;
         end if;

         if Seen (D.Effect_Classification) then
            return False;
         end if;
         Seen (D.Effect_Classification) := True;
      end loop;

      return True;
   end File_Lifecycle_Command_Reference_Coherent;

   function Make_Command_Descriptor
     (Id             : Command_Id;
      Stable_Name    : String;
      Label          : String;
      Description    : String;
      Category       : Command_Category;
      Visible        : Boolean;
      Bindable       : Boolean;
      Destructive    : Boolean := False;
      Lifecycle      : Boolean := False;
      Configuration  : Boolean := False)
      return Command_Descriptor
   is
   begin
      return Descriptor_Metadata.Make_Command_Descriptor
        (Id            => Id,
         Stable_Name   => Stable_Name,
         Label         => Label,
         Description   => Description,
         Category      => Category,
         Visible       => Visible,
         Bindable      => Bindable,
         Destructive   => Destructive,
         Lifecycle     => Lifecycle,
         Configuration => Configuration);
   end Make_Command_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor
   is
   begin
      return Descriptor_Metadata.Descriptor (Id);
   end Descriptor;

   function Label
     (Id : Command_Id) return String
   is
   begin
      return To_String (Descriptor (Id).Name);
   end Label;

   function Category
     (Id : Command_Id) return Command_Category
   is
   begin
      return Descriptor (Id).Category;
   end Category;

   function Category_Label
     (Category : Command_Category) return String
   is
   begin
      case Category is
         when File_Category =>
            return "File";
         when Project_Category =>
            return "Project";
         when Edit_Category =>
            return "Edit";
         when Selection_Category =>
            return "Selection";
         when Navigation_Category =>
            return "Navigation";
         when Search_Category =>
            return "Search";
         when Panel_Category =>
            return "Panels";
         when View_Category =>
            return "View";
         when Diagnostics_Category =>
            return "Diagnostics";
         when Bookmarks_Category =>
            return "Bookmarks";
         when Overlay_Category =>
            return "Overlays";
         when Message_Category =>
            return "Messages";
         when Theme_Category =>
            return "Theme";
         when Settings_Category =>
            return "Settings";
         when Workspace_Category =>
            return "Workspace";
         when Internal_Category =>
            return "Internal";
      end case;
   end Category_Label;

   function Discoverability_Category_Label
     (Id : Command_Id) return String
   is
      Stable : constant String := Stable_Command_Name (Id);
   begin
      if Ada.Strings.Fixed.Index (Stable, "build.") = Stable'First then
         return "Build";
      elsif Ada.Strings.Fixed.Index (Stable, "recent-projects.") = Stable'First then
         return "Recent Projects";
      elsif Ada.Strings.Fixed.Index (Stable, "file-tree.") = Stable'First then
         return "File Tree";
      elsif Ada.Strings.Fixed.Index (Stable, "outline.") = Stable'First then
         return "Outline";
      elsif Ada.Strings.Fixed.Index (Stable, "semantic.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "language.index.") = Stable'First
      then
         return "Language";
      elsif Ada.Strings.Fixed.Index (Stable, "buffer-switcher.") = Stable'First
        or else Stable = "switch-buffer"
      then
         return "Buffers";
      elsif Ada.Strings.Fixed.Index (Stable, "keybindings.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "keybinding.") = Stable'First
      then
         return "Keybindings";
      elsif Ada.Strings.Fixed.Index (Stable, "command-palette.") = Stable'First
        or else Stable = "open-command-palette"
      then
         return "Command Palette";
      else
         return Category_Label (Descriptor (Id).Category);
      end if;
   end Discoverability_Category_Label;

   function Classification_Label
     (Id : Command_Id) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Add (Text : String) is
      begin
         if Length (Result) > 0 then
            Result := Result & ", ";
         end if;
         Result := Result & Text;
      end Add;
   begin
      if Is_Destructive_Command (Id) then
         Add ("destructive");
      end if;
      if Is_Lifecycle_Command (Id) then
         Add ("lifecycle");
      end if;
      if Is_Configuration_Command (Id) then
         Add ("configuration");
      end if;
      if Is_Navigation_Command (Id) then
         Add ("navigation");
      end if;
      if Is_Search_Command (Id) then
         Add ("search");
      end if;
      if Is_Panel_Focus_Command (Id) then
         Add ("panel");
      end if;
      if Is_Text_Editing_Command (Id) then
         Add ("editing");
      end if;
      if Descriptor (Id).Visibility = Hidden_Command
        or else Descriptor (Id).Category = Internal_Category
      then
         Add ("internal");
      end if;
      if not Is_Bindable_Command (Id) then
         Add ("non-bindable");
      end if;
      if Length (Result) = 0 then
         Add ("command");
      end if;
      return To_String (Result);
   end Classification_Label;

   function Surface_Relevance_Label
     (Id : Command_Id) return String
   is
      Stable : constant String := Stable_Command_Name (Id);
   begin
      if Stable'Length = 0 then
         return "";
      elsif Ada.Strings.Fixed.Index (Stable, "file-tree.") = Stable'First then
         return "File Tree";
      elsif Ada.Strings.Fixed.Index (Stable, "diagnostics.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "problems.") = Stable'First
      then
         return "Diagnostics";
      elsif Ada.Strings.Fixed.Index (Stable, "build.") = Stable'First then
         return "Build";
      elsif Ada.Strings.Fixed.Index (Stable, "project-search.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "search-results.") = Stable'First
      then
         return "Project Search";
      elsif Ada.Strings.Fixed.Index (Stable, "outline.") = Stable'First then
         return "Outline";
      elsif Ada.Strings.Fixed.Index (Stable, "semantic.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "language.index.") = Stable'First
      then
         return "Language";
      elsif Ada.Strings.Fixed.Index (Stable, "quick-open.") = Stable'First then
         return "Quick Open";
      elsif Ada.Strings.Fixed.Index (Stable, "recent-projects.") = Stable'First then
         return "Recent Projects";
      elsif Ada.Strings.Fixed.Index (Stable, "buffer-switcher.") = Stable'First
        or else Stable = "switch-buffer"
      then
         return "Buffers";
      elsif Ada.Strings.Fixed.Index (Stable, "command-palette.") = Stable'First
        or else Stable = "open-command-palette"
      then
         return "Command Palette";
      elsif Ada.Strings.Fixed.Index (Stable, "keybindings.") = Stable'First
        or else Stable = "keybinding.validate"
      then
         return "Keybindings";
      else
         return "";
      end if;
   end Surface_Relevance_Label;

   function Guard_Label
     (Id : Command_Id) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Add (Text : String) is
      begin
         if Length (Result) > 0 then
            Result := Result & ", ";
         end if;
         Result := Result & Text;
      end Add;
   begin
      if Is_Destructive_Command (Id) then
         Add ("confirmation and dirty-file protection retained");
      end if;
      if Is_Lifecycle_Command (Id) then
         Add ("project/file safety protection retained");
      end if;
      if Is_Configuration_Command (Id) then
         Add ("configuration safety check retained");
      end if;
      if not Is_Bindable_Command (Id) then
         Add ("not keybindable");
      end if;
      if Length (Result) = 0 then
         Add ("no special safety check");
      end if;
      return To_String (Result);
   end Guard_Label;

   function Has_Discoverability_Metadata
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Audits.Has_Discoverability_Metadata;

   function Command_Discoverability_Coherent return Boolean
     renames Editor.Commands.Audits.Command_Discoverability_Coherent;

   function First_Command return Command_Id
   is
   begin
      return Command_Id'First;
   end First_Command;

   function Last_Command return Command_Id
   is
   begin
      return Command_Id'Last;
   end Last_Command;

   function Next_Command
     (Id    : Command_Id;
      Found : out Boolean) return Command_Id
   is
   begin
      if Id = Command_Id'Last then
         Found := False;
         return No_Command;
      end if;

      Found := True;
      return Command_Id'Succ (Id);
   end Next_Command;

   function First_Concrete_Command return Command_Id
   is
   begin
      return Command_Id'Succ (No_Command);
   end First_Concrete_Command;

   function Concrete_Command_Count return Natural
   is
   begin
      return Command_Count - 1;
   end Concrete_Command_Count;

   procedure For_Each_Command
     (Process : not null access procedure (Id : Command_Id))
   is
   begin
      for Id in Command_Id loop
         if Is_Concrete_Command (Id) then
            Process (Id);
         end if;
      end loop;
   end For_Each_Command;

   function Is_Valid_Command
     (Id : Command_Id) return Boolean
   is
      pragma Unreferenced (Id);
   begin
      return True;
   end Is_Valid_Command;

   function Trimmed
     (Text : String) return String
   is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Is_Placeholder_Label
     (Text : String) return Boolean
   is
      T : constant String := Trimmed (Text);
   begin
      return T = "TODO"
        or else T = "Command"
        or else T = "Unnamed";
   end Is_Placeholder_Label;

   function Has_Stable_User_Label
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
      L : constant String := To_String (D.Name);
   begin
      return Id /= No_Command
        and then D.Id = Id
        and then L'Length > 0
        and then Trimmed (L) = L
        and then not Is_Placeholder_Label (L);
   end Has_Stable_User_Label;

   function Is_Public_Build_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id in Command_Build_Run
        | Command_Build_Cancel
        | Command_Build_Result_Focus
        | Command_Build_Output_Details_Focus
        | Command_Build_Output_Details_Select_Stdout
        | Command_Build_Output_Details_Select_Stderr
        | Command_Build_Output_Details_Select_Merged
        | Command_Build_Refresh_Candidates
        | Command_Build_Select_First_Candidate
        | Command_Build_Select_Next_Candidate
        | Command_Build_Select_Previous_Candidate
        | Command_Build_Clear_Selected_Candidate
        | Command_Build_Set_Mode_Default
        | Command_Build_Set_Mode_Debug
        | Command_Build_Set_Mode_Release
        | Command_Build_Set_Mode_Validation
        | Command_Build_Toggle_Diagnostics_Ingestion
        | Command_Build_Cycle_Output_Limit
        | Command_Build_Toggle_Option_Verbose
        | Command_Build_Toggle_Option_Keep_Going
        | Command_Build_Acknowledge_Consent
        | Command_Build_Clear_Consent;
   end Is_Public_Build_Command;

   function Is_Internal_Build_Test_Seam_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Build_Run_User_Opt_In_Test_Seam;
   end Is_Internal_Build_Test_Seam_Command;

   function Is_Test_Only_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Internal_Build_Test_Seam_Command (Id);
   end Is_Test_Only_Command;

   function Is_Destructive_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Clear_Workspace_State
            | Command_Clear_Recent_Projects
            | Command_Remove_Selected_Recent_Project
            | Command_Remove_Missing_Recent_Projects
            | Command_Reset_Settings_To_Defaults
            | Command_Keybindings_Reset_To_Defaults
            | Command_Close_Project
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Revert_Active_Buffer
            | Command_Delete_Buffer_File
            | Command_File_Tree_Delete_Selected
            | Command_Close_Other_Buffers
            | Command_Close_All_Buffers
            | Command_Close_All_Clean_Buffers
            | Command_Clear_Project
            | Command_Clear_Bookmarks
            | Command_Clear_All_Bookmarks
            | Command_Bookmark_Clear_All
            | Command_Clear_Project_Search
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_Buffer_Switcher_Selected_Close =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Destructive_Command;

   function Is_Lifecycle_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Open_Project
            | Command_Switch_Project
            | Command_Open_Selected_Recent_Project
            | Command_Close_Project
            | Command_Clear_Project
            | Command_Save_Workspace_State
            | Command_Restore_Workspace_State
            | Command_Clear_Workspace_State
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close
            | Command_Reopen_Closed_Buffer
            | Command_Close_Other_Buffers
            | Command_Close_All_Buffers
            | Command_Close_All_Clean_Buffers
            | Command_Pin_Buffer
            | Command_Unpin_Buffer
            | Command_Toggle_Buffer_Pin
            | Command_Set_Buffer_Label
            | Command_Clear_Buffer_Label
            | Command_Edit_Buffer_Label
            | Command_Show_Buffer_Label
            | Command_Set_Buffer_Note
            | Command_Clear_Buffer_Note
            | Command_Edit_Buffer_Note
            | Command_Show_Buffer_Note
            | Command_Assign_Buffer_Group
            | Command_Clear_Buffer_Group
            | Command_Switch_Buffer_Group
            | Command_Next_Buffer_Group
            | Command_Previous_Buffer_Group
            | Command_Show_All_Buffer_Groups
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File
            | Command_File_Tree_Create_File
            | Command_File_Tree_Create_Directory
            | Command_File_Tree_Rename_Selected
            | Command_File_Tree_Delete_Selected
            | Command_New_Buffer
            | Command_Switch_Buffer
            | Command_Next_Buffer
            | Command_Previous_Buffer
            | Command_Previous_Recent_Buffer
            | Command_Next_Recent_Buffer
            | Command_Cancel_Pending_Transition
            | Command_Retry_Pending_Transition
            | Command_Discard_Pending_Transition
            | Command_Show_Recent_Projects
            | Command_Clear_Recent_Projects
            | Command_Remove_Selected_Recent_Project
            | Command_Remove_Missing_Recent_Projects
            | Command_Select_Next_Recent_Project
            | Command_Select_Previous_Recent_Project
            | Command_Buffer_Switcher_Selected_Close
            | Command_Buffer_Switcher_Selected_Pin
            | Command_Buffer_Switcher_Selected_Unpin
            | Command_Buffer_Switcher_Selected_Toggle_Pin
            | Command_Buffer_Switcher_Selected_Group_Assign
            | Command_Buffer_Switcher_Selected_Group_Clear
            | Command_Buffer_Switcher_Selected_Label_Set
            | Command_Buffer_Switcher_Selected_Label_Clear
            | Command_Buffer_Switcher_Selected_Note_Set
            | Command_Buffer_Switcher_Selected_Note_Clear
            | Command_Buffer_Switcher_Mark_Confirm
            | Command_Accept_Quick_Open
            | Command_Quick_Open_Create_From_Query
            | Command_Quick_Open_Create_With_Parents_From_Query =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Lifecycle_Command;

   function Is_Configuration_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_Settings
            | Command_Reload_Settings
            | Command_Reset_Settings_To_Defaults
            | Command_Save_Keybindings
            | Command_Reload_Keybindings
            | Command_Validate_Keybindings
            | Command_Keybindings_Show
            | Command_Keybindings_Focus
            | Command_Keybindings_Assign_Selected
            | Command_Keybindings_Remove_Selected
            | Command_Keybindings_Reset_To_Defaults
            | Command_Keybindings_Filter_Conflicts
            | Command_Keybindings_Filter_Unbound
            | Command_Keybindings_Clear_Filter
            | Command_Keybindings_Cancel_Capture
            | Command_Startup_Show_Summary
            | Command_Configuration_Recover_Show
            | Command_Configuration_Audit
            | Command_Configuration_Reset_Settings
            | Command_Configuration_Reset_Keybindings
            | Command_Configuration_Reset_Workspace
            | Command_Configuration_Reset_Recent_Projects
            | Command_Configuration_Reset_All
            | Command_Configuration_Reset_All_Confirm
            | Command_Configuration_Reset_All_Cancel
            | Command_Configuration_Save_Clean_Settings
            | Command_Configuration_Save_Clean_Keybindings
            | Command_Configuration_Save_Clean_Workspace
            | Command_Configuration_Save_Clean_Recent_Projects
            | Command_Toggle_Theme
            | Command_Set_Theme_Light
            | Command_Set_Theme_Dark
            | Command_Toggle_Minimap
            | Command_Toggle_Scrollbars
            | Command_Toggle_Line_Numbers
            | Command_Toggle_Line_Number_Mode
            | Command_Set_Absolute_Line_Numbers
            | Command_Set_Relative_Line_Numbers
            | Command_Set_Hybrid_Line_Numbers
            | Command_Toggle_Current_Line_Highlight
            | Command_Toggle_Cursor_Blink
            | Command_Toggle_Syntax_Colouring
            | Command_Toggle_Diagnostics
            | Command_Toggle_Cursor_Style =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Configuration_Command;

   function Is_File_Content_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_File
            | Command_Save_File_As
            | Command_Save_All =>
            return True;
         when others =>
            return False;
      end case;
   end Is_File_Content_Save_Command;

   function Is_Workspace_Structural_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Save_Workspace_State;
   end Is_Workspace_Structural_Save_Command;

   function Is_Global_Settings_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Save_Settings;
   end Is_Global_Settings_Save_Command;

   function Is_Global_Keybindings_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Save_Keybindings;
   end Is_Global_Keybindings_Save_Command;

   function Is_Navigation_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Classification.Is_Navigation_Command;

   function Is_Search_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Classification.Is_Search_Command;

   function Is_Panel_Focus_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Classification.Is_Panel_Focus_Command;

   function Is_Text_Editing_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Classification.Is_Text_Editing_Command;

   function Has_Descriptor
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
   begin
      return D.Id = Id;
   end Has_Descriptor;

   function Stable_Command_Name
     (Id : Command_Id) return String
   is
   begin
      return Name_Metadata.Stable_Command_Name (Id);
   end Stable_Command_Name;

   function Command_Id_From_Stable_Name
     (Name  : String;
      Found : out Boolean) return Command_Id
   is
   begin
      return Name_Metadata.Command_Id_From_Stable_Name (Name, Found);
   end Command_Id_From_Stable_Name;

   function Has_Stable_Name
     (Id : Command_Id) return Boolean
   is
      Name : constant String := Stable_Command_Name (Id);
   begin
      return Is_Bindable_Command (Id)
        and then Name'Length > 0
        and then Ada.Strings.Fixed.Index (Name, " ") = 0
        and then Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both) = Name;
   end Has_Stable_Name;

   function Is_Bindable_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Concrete_Command (Id)
        and then not Is_Test_Only_Command (Id)
        and then Descriptor (Id).Bindable;
   end Is_Bindable_Command;

   function Is_Internal_Command
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
   begin
      return D.Category = Internal_Category
        or else D.Visibility = Hidden_Command;
   end Is_Internal_Command;

   function Descriptor_Is_Complete
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Audits.Descriptor_Is_Complete;

   procedure Audit_Command
     (Id      : Command_Id;
      Failure : out Command_Audit_Failure;
      Found   : out Boolean)
     renames Editor.Commands.Audits.Audit_Command;

   function Audit_Command_Registry
      return Command_Audit_Failure_Vectors.Vector
     renames Editor.Commands.Audits.Audit_Command_Registry;

   function Command_Audit_Summary
     (Failures : Command_Audit_Failure_Vectors.Vector) return String
     renames Editor.Commands.Audits.Command_Audit_Summary;


   function Is_Visible_In_Palette
     (Id : Command_Id) return Boolean
   is
   begin
      return Descriptor (Id).Visibility = Palette_Command;
   end Is_Visible_In_Palette;

   function Visible_In_Command_Palette
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Visible_In_Palette (Id);
   end Visible_In_Command_Palette;

   function Palette_Command_Count return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Command_Count loop
         if Visible_In_Command_Palette (Command_At (I)) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Palette_Command_Count;

   function Palette_Command_At
     (Index : Positive) return Command_Id
   is
      Count : Natural := 0;
      Id    : Command_Id;
   begin
      pragma Assert
        (Index <= Palette_Command_Count,
         "Editor.Commands.Palette_Command_At index out of range");

      for I in 1 .. Command_Count loop
         Id := Command_At (I);
         if Visible_In_Command_Palette (Id) then
            Count := Count + 1;
            if Count = Index then
               return Id;
            end if;
         end if;
      end loop;

      return No_Command;
   end Palette_Command_At;

   function Command_Count return Natural
   is
   begin
      return Command_Id'Pos (Command_Id'Last) - Command_Id'Pos (Command_Id'First) + 1;
   end Command_Count;

   function Command_At
     (Index : Positive) return Command_Id
   is
   begin
      pragma Assert (Index <= Command_Count, "Editor.Commands.Command_At index out of range");
      return Command_Id'Val (Command_Id'Pos (Command_Id'First) + Index - 1);
   end Command_At;

   function Palette_Commands return Command_Descriptor_Vectors.Vector is
      Result : Command_Descriptor_Vectors.Vector;
      D      : Command_Descriptor;
   begin
      for I in 1 .. Command_Count loop
         D := Descriptor (Command_At (I));
         if D.Visibility = Palette_Command then
            Result.Append (D);
         end if;
      end loop;

      return Result;
   end Palette_Commands;

end Editor.Commands;
