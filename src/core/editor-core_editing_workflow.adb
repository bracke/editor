with Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Text_Buffer;
with Editor.Cursors;
with Editor.Selection;
with Editor.Pending_Transitions;
with Editor.Overlay_Focus;

package body Editor.Core_Editing_Workflow is

   use type Editor.Cursors.Cursor_Index;
   use type Ada.Containers.Count_Type;
   use type Editor.Commands.Command_Id;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;
   use type Editor.Overlay_Focus.Overlay_Target;

   function Has_Caret (S : Editor.State.State_Type) return Boolean is
   begin
      return S.Carets.Length > 0;
   end Has_Caret;

   function Has_File_Path (S : Editor.State.State_Type) return Boolean is
   begin
      return S.File_Info.Has_Path and then Length (S.File_Info.Path) > 0;
   end Has_File_Path;

   function Buffer_Dirty_Label
     (S : Editor.State.State_Type) return String is
   begin
      if S.File_Info.Dirty then
         if S.File_Info.Last_Save_Failed then
            return "Dirty - save failed";
         else
            return "Dirty";
         end if;
      elsif S.File_Info.Last_Save_Failed then
         --  A clean buffer can still surface a past lifecycle failure until the
         --  retained lifecycle cleanup path clears it.  Do not treat this as a
         --  dirty buffer and do not clear the flag here.
         return "Clean - previous save failed";
      else
         return "Clean";
      end if;
   end Buffer_Dirty_Label;

   function Buffer_File_State_Label
     (S : Editor.State.State_Type) return String is
   begin
      if Has_File_Path (S) then
         return "File-backed";
      else
         return "Unbacked buffer";
      end if;
   end Buffer_File_State_Label;


   function Is_Core_Editing_Command
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Open_File
            | Editor.Commands.Command_New_Buffer
            | Editor.Commands.Command_Close_Active_Buffer
            | Editor.Commands.Command_Reopen_Closed_Buffer
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Close_All_Clean_Buffers
            | Editor.Commands.Command_Next_Buffer
            | Editor.Commands.Command_Previous_Buffer
            | Editor.Commands.Command_Previous_Recent_Buffer
            | Editor.Commands.Command_Next_Recent_Buffer
            | Editor.Commands.Command_Switch_Buffer
            | Editor.Commands.Command_Save_File
            | Editor.Commands.Command_Save_File_As
            | Editor.Commands.Command_Save_All
            | Editor.Commands.Command_Reload_Active_Buffer
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_Rename_Buffer_File
            | Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Copy_Buffer_File
            | Editor.Commands.Command_Move_Buffer_File
            | Editor.Commands.Command_Move_Left
            | Editor.Commands.Command_Move_Right
            | Editor.Commands.Command_Move_Up
            | Editor.Commands.Command_Move_Down
            | Editor.Commands.Command_Move_Line_Start
            | Editor.Commands.Command_Move_Line_End
            | Editor.Commands.Command_Move_Document_Start
            | Editor.Commands.Command_Move_Document_End
            | Editor.Commands.Command_Goto_Start
            | Editor.Commands.Command_Goto_End
            | Editor.Commands.Command_Goto_Line
            | Editor.Commands.Command_Goto_Line_Toggle
            | Editor.Commands.Command_Goto_Line_Prefill_Current
            | Editor.Commands.Command_Goto_Line_Query_Set
            | Editor.Commands.Command_Goto_Line_Query_Clear
            | Editor.Commands.Command_Close_Goto_Line
            | Editor.Commands.Command_Accept_Goto_Line
            | Editor.Commands.Command_Move_Word_Left
            | Editor.Commands.Command_Move_Word_Right
            | Editor.Commands.Command_Page_Up
            | Editor.Commands.Command_Page_Down
            | Editor.Commands.Command_Select_Left
            | Editor.Commands.Command_Select_Right
            | Editor.Commands.Command_Select_Up
            | Editor.Commands.Command_Select_Down
            | Editor.Commands.Command_Start_Rectangular_Selection
            | Editor.Commands.Command_Clear_Rectangular_Selection
            | Editor.Commands.Command_Extend_Selection_Line_Up
            | Editor.Commands.Command_Extend_Selection_Line_Down
            | Editor.Commands.Command_Select_Word_Left
            | Editor.Commands.Command_Select_Word_Right
            | Editor.Commands.Command_Select_Word
            | Editor.Commands.Command_Select_Line
            | Editor.Commands.Command_Select_Line_Start
            | Editor.Commands.Command_Select_Line_End
            | Editor.Commands.Command_Select_Document_Start
            | Editor.Commands.Command_Select_Document_End
            | Editor.Commands.Command_Select_Page_Up
            | Editor.Commands.Command_Select_Page_Down
            | Editor.Commands.Command_Select_All
            | Editor.Commands.Command_Selection_Clear
            | Editor.Commands.Command_Selection_Delete
            | Editor.Commands.Command_Copy
            | Editor.Commands.Command_Cut
            | Editor.Commands.Command_Paste
            | Editor.Commands.Command_Undo
            | Editor.Commands.Command_Redo
            | Editor.Commands.Command_Edit_History_Clear
            | Editor.Commands.Command_Insert_Newline
            | Editor.Commands.Command_Line_Delete
            | Editor.Commands.Command_Line_Duplicate
            | Editor.Commands.Command_Line_Move_Up
            | Editor.Commands.Command_Line_Move_Down
            | Editor.Commands.Command_Indent_Increase
            | Editor.Commands.Command_Indent_Decrease
            | Editor.Commands.Command_Comment_Line
            | Editor.Commands.Command_Uncomment_Line
            | Editor.Commands.Command_Toggle_Line_Comment
            | Editor.Commands.Command_Line_Join_Next
            | Editor.Commands.Command_Line_Split_At_Caret
            | Editor.Commands.Command_Trim_Trailing_Whitespace
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Core_Editing_Command;

   function Is_Buffer_Lifecycle_Command
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Open_File
            | Editor.Commands.Command_New_Buffer
            | Editor.Commands.Command_Close_Active_Buffer
            | Editor.Commands.Command_Reopen_Closed_Buffer
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Close_All_Clean_Buffers
            | Editor.Commands.Command_Next_Buffer
            | Editor.Commands.Command_Previous_Buffer
            | Editor.Commands.Command_Previous_Recent_Buffer
            | Editor.Commands.Command_Next_Recent_Buffer
            | Editor.Commands.Command_Switch_Buffer =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Buffer_Lifecycle_Command;

   function Is_Caret_Navigation_Command
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Move_Left
            | Editor.Commands.Command_Move_Right
            | Editor.Commands.Command_Move_Up
            | Editor.Commands.Command_Move_Down
            | Editor.Commands.Command_Move_Line_Start
            | Editor.Commands.Command_Move_Line_End
            | Editor.Commands.Command_Move_Document_Start
            | Editor.Commands.Command_Move_Document_End
            | Editor.Commands.Command_Goto_Start
            | Editor.Commands.Command_Goto_End
            | Editor.Commands.Command_Goto_Line
            | Editor.Commands.Command_Goto_Line_Toggle
            | Editor.Commands.Command_Goto_Line_Prefill_Current
            | Editor.Commands.Command_Goto_Line_Query_Set
            | Editor.Commands.Command_Goto_Line_Query_Clear
            | Editor.Commands.Command_Close_Goto_Line
            | Editor.Commands.Command_Accept_Goto_Line
            | Editor.Commands.Command_Move_Word_Left
            | Editor.Commands.Command_Move_Word_Right
            | Editor.Commands.Command_Page_Up
            | Editor.Commands.Command_Page_Down =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Caret_Navigation_Command;

   function Is_Selection_Command
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Select_Left
            | Editor.Commands.Command_Select_Right
            | Editor.Commands.Command_Select_Up
            | Editor.Commands.Command_Select_Down
            | Editor.Commands.Command_Start_Rectangular_Selection
            | Editor.Commands.Command_Clear_Rectangular_Selection
            | Editor.Commands.Command_Extend_Selection_Line_Up
            | Editor.Commands.Command_Extend_Selection_Line_Down
            | Editor.Commands.Command_Select_Word_Left
            | Editor.Commands.Command_Select_Word_Right
            | Editor.Commands.Command_Select_Word
            | Editor.Commands.Command_Select_Line
            | Editor.Commands.Command_Select_Line_Start
            | Editor.Commands.Command_Select_Line_End
            | Editor.Commands.Command_Select_Document_Start
            | Editor.Commands.Command_Select_Document_End
            | Editor.Commands.Command_Select_Page_Up
            | Editor.Commands.Command_Select_Page_Down
            | Editor.Commands.Command_Select_All
            | Editor.Commands.Command_Selection_Clear
            | Editor.Commands.Command_Selection_Delete
            | Editor.Commands.Command_Copy
            | Editor.Commands.Command_Cut =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Selection_Command;

   function Is_Text_Editing_Command
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Selection_Delete
            | Editor.Commands.Command_Cut
            | Editor.Commands.Command_Paste
            | Editor.Commands.Command_Undo
            | Editor.Commands.Command_Redo
            | Editor.Commands.Command_Edit_History_Clear
            | Editor.Commands.Command_Insert_Newline
            | Editor.Commands.Command_Line_Delete
            | Editor.Commands.Command_Line_Duplicate
            | Editor.Commands.Command_Line_Move_Up
            | Editor.Commands.Command_Line_Move_Down
            | Editor.Commands.Command_Indent_Increase
            | Editor.Commands.Command_Indent_Decrease
            | Editor.Commands.Command_Comment_Line
            | Editor.Commands.Command_Uncomment_Line
            | Editor.Commands.Command_Toggle_Line_Comment
            | Editor.Commands.Command_Line_Join_Next
            | Editor.Commands.Command_Line_Split_At_Caret
            | Editor.Commands.Command_Trim_Trailing_Whitespace
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Text_Editing_Command;

   function Mutates_Or_Replaces_Buffer_Text
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Save_File
            | Editor.Commands.Command_Save_File_As
            | Editor.Commands.Command_Save_All
            | Editor.Commands.Command_Reload_Active_Buffer
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Selection_Delete
            | Editor.Commands.Command_Cut
            | Editor.Commands.Command_Paste
            | Editor.Commands.Command_Undo
            | Editor.Commands.Command_Redo
            | Editor.Commands.Command_Edit_History_Clear
            | Editor.Commands.Command_Insert_Newline
            | Editor.Commands.Command_Line_Delete
            | Editor.Commands.Command_Line_Duplicate
            | Editor.Commands.Command_Line_Move_Up
            | Editor.Commands.Command_Line_Move_Down
            | Editor.Commands.Command_Indent_Increase
            | Editor.Commands.Command_Indent_Decrease
            | Editor.Commands.Command_Comment_Line
            | Editor.Commands.Command_Uncomment_Line
            | Editor.Commands.Command_Toggle_Line_Comment
            | Editor.Commands.Command_Line_Join_Next
            | Editor.Commands.Command_Line_Split_At_Caret
            | Editor.Commands.Command_Trim_Trailing_Whitespace
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next =>
            return True;
         when others =>
            return False;
      end case;
   end Mutates_Or_Replaces_Buffer_Text;

   function Requires_File_Backed_Buffer
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Save_File
            | Editor.Commands.Command_Save_All
            | Editor.Commands.Command_Reload_Active_Buffer
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_Rename_Buffer_File
            | Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Copy_Buffer_File
            | Editor.Commands.Command_Move_Buffer_File =>
            return True;
         when others =>
            return False;
      end case;
   end Requires_File_Backed_Buffer;

   function Editing_Availability_Reason
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return String
   is
      Has_Buffer : constant Boolean := Has_Caret (S);
      Has_Selection : constant Boolean :=
        Editor.Selection.Has_Selection (S) or else S.Rect_Select_Active;
   begin
      case Id is
         when Editor.Commands.No_Command =>
            return "No command selected";

         when Editor.Commands.Command_Open_File
            | Editor.Commands.Command_New_Buffer
            | Editor.Commands.Command_Reopen_Closed_Buffer =>
            return "";

         when Editor.Commands.Command_Save_File
            | Editor.Commands.Command_Save_All
            | Editor.Commands.Command_Reload_Active_Buffer
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_Rename_Buffer_File
            | Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Copy_Buffer_File
            | Editor.Commands.Command_Move_Buffer_File =>
            if not Has_Buffer then
               return "No active buffer.";
            elsif not Has_File_Path (S) then
               return "No file path for active buffer";
            elsif Id = Editor.Commands.Command_Reload_Active_Buffer
              and then S.File_Info.Dirty
            then
               return "Dirty buffer cannot be reloaded";
            elsif Id = Editor.Commands.Command_Revert_Active_Buffer
              and then not S.File_Info.Dirty
            then
               return "No changes to revert";
            else
               return "";
            end if;

         when Editor.Commands.Command_Save_File_As =>
            if not Has_Buffer then
               return "No active buffer.";
            else
               return "";
            end if;

         when Editor.Commands.Command_Close_Active_Buffer
            | Editor.Commands.Command_Close_Other_Buffers =>
            if not Has_Buffer then
               return "No active buffer.";
            else
               --  Phase 575: dirty close commands are available at the
               --  command-surface level.  Execution opens an explicit
               --  save/discard/cancel dirty-close review before any close that
               --  could lose text, so the audit helper must not preserve the
               --  old hard-refusal reason.
               return "";
            end if;

         when Editor.Commands.Command_Close_All_Clean_Buffers =>
            if not Has_Buffer then
               return "No active buffer.";
            else
               return "";
            end if;

         when Editor.Commands.Command_Next_Buffer
            | Editor.Commands.Command_Previous_Buffer
            | Editor.Commands.Command_Previous_Recent_Buffer
            | Editor.Commands.Command_Next_Recent_Buffer
            | Editor.Commands.Command_Switch_Buffer =>
            if not Has_Buffer then
               return "No active buffer.";
            else
               return "";
            end if;

         when Editor.Commands.Command_Copy
            | Editor.Commands.Command_Cut =>
            if not Has_Buffer then
               return "No active buffer.";
            elsif not Has_Selection then
               return "No selection";
            else
               return "";
            end if;

         when Editor.Commands.Command_Selection_Clear
            | Editor.Commands.Command_Selection_Delete =>
            if not Has_Buffer then
               return "No active buffer.";
            elsif S.Carets.Length = 0 then
               return "No caret location";
            elsif not Has_Selection then
               return "No selection";
            else
               return "";
            end if;

         when Editor.Commands.Command_Move_Left
            | Editor.Commands.Command_Move_Right
            | Editor.Commands.Command_Move_Up
            | Editor.Commands.Command_Move_Down
            | Editor.Commands.Command_Move_Line_Start
            | Editor.Commands.Command_Move_Line_End
            | Editor.Commands.Command_Move_Document_Start
            | Editor.Commands.Command_Move_Document_End
            | Editor.Commands.Command_Goto_Start
            | Editor.Commands.Command_Goto_End
            | Editor.Commands.Command_Goto_Line
            | Editor.Commands.Command_Goto_Line_Toggle
            | Editor.Commands.Command_Goto_Line_Prefill_Current
            | Editor.Commands.Command_Goto_Line_Query_Set
            | Editor.Commands.Command_Goto_Line_Query_Clear
            | Editor.Commands.Command_Close_Goto_Line
            | Editor.Commands.Command_Accept_Goto_Line
            | Editor.Commands.Command_Move_Word_Left
            | Editor.Commands.Command_Move_Word_Right
            | Editor.Commands.Command_Page_Up
            | Editor.Commands.Command_Page_Down
            | Editor.Commands.Command_Select_Left
            | Editor.Commands.Command_Select_Right
            | Editor.Commands.Command_Select_Up
            | Editor.Commands.Command_Select_Down
            | Editor.Commands.Command_Start_Rectangular_Selection
            | Editor.Commands.Command_Clear_Rectangular_Selection
            | Editor.Commands.Command_Extend_Selection_Line_Up
            | Editor.Commands.Command_Extend_Selection_Line_Down
            | Editor.Commands.Command_Select_Word_Left
            | Editor.Commands.Command_Select_Word_Right
            | Editor.Commands.Command_Select_Word
            | Editor.Commands.Command_Select_Line
            | Editor.Commands.Command_Select_Line_Start
            | Editor.Commands.Command_Select_Line_End
            | Editor.Commands.Command_Select_Document_Start
            | Editor.Commands.Command_Select_Document_End
            | Editor.Commands.Command_Select_Page_Up
            | Editor.Commands.Command_Select_Page_Down
            | Editor.Commands.Command_Select_All
            | Editor.Commands.Command_Undo
            | Editor.Commands.Command_Redo
            | Editor.Commands.Command_Edit_History_Clear
            | Editor.Commands.Command_Insert_Newline
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next
            | Editor.Commands.Command_Line_Delete
            | Editor.Commands.Command_Line_Duplicate
            | Editor.Commands.Command_Line_Move_Up
            | Editor.Commands.Command_Line_Move_Down
            | Editor.Commands.Command_Indent_Increase
            | Editor.Commands.Command_Indent_Decrease
            | Editor.Commands.Command_Comment_Line
            | Editor.Commands.Command_Uncomment_Line
            | Editor.Commands.Command_Toggle_Line_Comment
            | Editor.Commands.Command_Line_Join_Next
            | Editor.Commands.Command_Line_Split_At_Caret
            | Editor.Commands.Command_Trim_Trailing_Whitespace
            | Editor.Commands.Command_Paste =>
            if not Has_Buffer then
               return "No active buffer.";
            elsif S.Carets.Length = 0 then
               return "No caret location";
            else
               return "";
            end if;

         when others =>
            return "";
      end case;
   end Editing_Availability_Reason;

   function Carets_In_Bounds (S : Editor.State.State_Type) return Boolean is
      Len : constant Editor.Cursors.Cursor_Index :=
        Editor.Cursors.Cursor_Index (Text_Buffer.Length (S.Buffer));
   begin
      if S.Carets.Length = 0 then
         return False;
      end if;

      for C of S.Carets loop
         if C.Pos > Len or else C.Anchor > Len then
            return False;
         end if;
      end loop;

      return True;
   end Carets_In_Bounds;

   function Selection_In_Bounds (S : Editor.State.State_Type) return Boolean is
      Selection_Range  : Editor.Selection.Active_Selection_Range;
      Status : constant Editor.Selection.Selection_Validation_Status :=
        Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      Len    : constant Editor.Cursors.Cursor_Index :=
        Editor.Cursors.Cursor_Index (Text_Buffer.Length (S.Buffer));
   begin
      case Status is
         when Editor.Selection.Selection_Ok =>
            return Selection_Range.Low <= Selection_Range.High and then Selection_Range.High <= Len;
         when Editor.Selection.Selection_Empty =>
            return True;
         when others =>
            return not Editor.Selection.Has_Selection (S)
              and then not S.Rect_Select_Active;
      end case;
   end Selection_In_Bounds;

   function File_State_Coherent (S : Editor.State.State_Type) return Boolean is
   begin
      if S.File_Info.Has_Path then
         return Length (S.File_Info.Path) > 0
           and then Length (S.File_Info.Display_Name) > 0;
      else
         --  Unbacked buffers must not retain a path payload.  A display name is
         --  still required so render/palette/switcher projections can identify
         --  the buffer without fabricating one.
         return Length (S.File_Info.Path) = 0
           and then Length (S.File_Info.Display_Name) > 0;
      end if;
   end File_State_Coherent;

   function Dirty_State_Coherent (S : Editor.State.State_Type) return Boolean is
   begin
      if not S.File_Info.Baseline_Valid then
         return S.File_Info.Saved_Generation = 0
           or else S.File_Info.Saved_Generation <= S.Buffer_Revision;
      end if;

      return S.File_Info.Saved_Generation <= S.Buffer_Revision;
   end Dirty_State_Coherent;


   function Prompt_Boundary_Coherent (S : Editor.State.State_Type) return Boolean is
      function Is_File_Target_Prompt_Command
        (Id : Editor.Commands.Command_Id) return Boolean is
      begin
         case Id is
            when Editor.Commands.Command_Save_File_As
               | Editor.Commands.Command_Rename_Buffer_File
               | Editor.Commands.Command_Copy_Buffer_File
               | Editor.Commands.Command_Move_Buffer_File
               | Editor.Commands.Command_Delete_Buffer_File =>
               return True;
            when others =>
               return False;
         end case;
      end Is_File_Target_Prompt_Command;

      Prompt_Command_Coherent : constant Boolean :=
        (not S.File_Target_Prompt_Active)
        or else Is_File_Target_Prompt_Command (S.File_Target_Prompt_Command);
      Pending_Coherent : constant Boolean :=
        (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions))
        or else Editor.Pending_Transitions.Target_Kind (S.Pending_Transitions) /=
          Editor.Pending_Transitions.No_Pending_Transition;
   begin
      --  Target prompts and dirty pending-transition guards are transient UI
      --  state.  They may block or parameterize a later Executor command, but
      --  they must not masquerade as a saved file path, saved baseline, dirty
      --  edit, or persisted editing payload.
      return Prompt_Command_Coherent and then Pending_Coherent;
   end Prompt_Boundary_Coherent;



   function Input_Bridge_Boundary_Coherent (S : Editor.State.State_Type) return Boolean is
      Active : constant Editor.Overlay_Focus.Overlay_Target :=
        Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
   begin
      --  A file target prompt owns typed path input while it is active.  It may
      --  be inspected without an active overlay in unit-level state fixtures,
      --  but it must never coexist underneath a different text-consuming
      --  overlay where ordinary typing could be misrouted into a buffer.
      if S.File_Target_Prompt_Active then
         return Active = Editor.Overlay_Focus.No_Overlay
           or else Active = Editor.Overlay_Focus.File_Target_Prompt_Overlay;
      end if;

      return True;
   end Input_Bridge_Boundary_Coherent;


   function Dirty_Close_Guard_Coherent (S : Editor.State.State_Type) return Boolean is
      Reason : constant String :=
        Editing_Availability_Reason
          (S, Editor.Commands.Command_Close_Active_Buffer);
   begin
      --  Phase 575 moved dirty-close safety from availability-time refusal to
      --  Executor-owned confirmation.  The coherent state is therefore:
      --  no active buffer still reports no active buffer, while a dirty active
      --  buffer remains command-available and is guarded only when execution
      --  starts a transient dirty-close prompt.
      if not Has_Caret (S) then
         return Reason = "No active buffer.";
      else
         return Reason /= "Pending confirmation required";
      end if;
   end Dirty_Close_Guard_Coherent;

   function Audit_Core_Editing_Workflow
     (S : Editor.State.State_Type) return Core_Editing_Workflow_Result
   is
      Result : Core_Editing_Workflow_Result;
   begin
      Result.Active_Buffer_State_Coherent := Has_Caret (S);
      Result.File_State_Coherent := File_State_Coherent (S);
      Result.Dirty_State_Coherent := Dirty_State_Coherent (S);
      Result.Caret_State_Coherent := Carets_In_Bounds (S);
      Result.Selection_State_Coherent := Selection_In_Bounds (S);

      --  Phase 532 persistence boundary audit is local and conservative: the
      --  core editor state must not encode transient input prompts as saved
      --  file identity or saved baseline data.  Persistence tests still own
      --  serialization-specific checks.
      Result.Persistence_Boundary_Coherent :=
        Result.File_State_Coherent and then Result.Dirty_State_Coherent;

      --  Editing coherence is independent of Outline/Diagnostics/Build
      --  contents.  The audit therefore checks only that editing state can be
      --  inspected without requiring those transient surfaces to be repaired,
      --  refreshed, or cleared.
      Result.Transient_Boundary_Coherent := True;

      Result.Command_Availability_Coherent :=
        (Editing_Availability_Reason
           (S, Editor.Commands.Command_Save_File)'Length = 0
         or else not Has_File_Path (S)
         or else not Has_Caret (S))
        and then
        (Editing_Availability_Reason
           (S, Editor.Commands.Command_Reload_Active_Buffer) /=
         "Dirty buffer cannot be reloaded"
         or else S.File_Info.Dirty)
        and then
        (not Requires_File_Backed_Buffer
           (Editor.Commands.Command_Save_File_As));

      Result.Prompt_Boundary_Coherent := Prompt_Boundary_Coherent (S);
      Result.Dirty_Close_Guard_Coherent := Dirty_Close_Guard_Coherent (S);
      Result.Caret_Command_Coverage_Coherent :=
        Is_Core_Editing_Command (Editor.Commands.Command_Goto_Line)
        and then Is_Caret_Navigation_Command (Editor.Commands.Command_Goto_Line)
        and then not Mutates_Or_Replaces_Buffer_Text (Editor.Commands.Command_Goto_Line);
      Result.Selection_Command_Coverage_Coherent :=
        Is_Selection_Command (Editor.Commands.Command_Select_All)
        and then Is_Selection_Command (Editor.Commands.Command_Selection_Delete)
        and then not Is_Caret_Navigation_Command (Editor.Commands.Command_Selection_Delete);
      Result.Text_Mutation_Command_Coverage_Coherent :=
        Is_Text_Editing_Command (Editor.Commands.Command_Insert_Newline)
        and then Is_Text_Editing_Command (Editor.Commands.Command_Indent_Increase)
        and then not Is_Text_Editing_Command (Editor.Commands.Command_Save_File)
        and then Mutates_Or_Replaces_Buffer_Text (Editor.Commands.Command_Revert_Active_Buffer);
      Result.Input_Bridge_Boundary_Coherent := Input_Bridge_Boundary_Coherent (S);

      Result.Coherent :=
        Result.Active_Buffer_State_Coherent
        and then Result.File_State_Coherent
        and then Result.Dirty_State_Coherent
        and then Result.Caret_State_Coherent
        and then Result.Selection_State_Coherent
        and then Result.Persistence_Boundary_Coherent
        and then Result.Transient_Boundary_Coherent
        and then Result.Command_Availability_Coherent
        and then Result.Prompt_Boundary_Coherent
        and then Result.Dirty_Close_Guard_Coherent
        and then Result.Caret_Command_Coverage_Coherent
        and then Result.Selection_Command_Coverage_Coherent
        and then Result.Text_Mutation_Command_Coverage_Coherent
        and then Result.Input_Bridge_Boundary_Coherent;

      return Result;
   end Audit_Core_Editing_Workflow;

   function Assert_Core_Editing_Workflow_Coherent
     (S : Editor.State.State_Type) return Boolean is
   begin
      return Audit_Core_Editing_Workflow (S).Coherent;
   end Assert_Core_Editing_Workflow_Coherent;

   function Assert_Text_Editing_Primitives_Coherent return Boolean is
      function User_Facing_Edit_Command
        (Id : Editor.Commands.Command_Id) return Boolean is
      begin
         return Editor.Commands.Has_Descriptor (Id)
           and then Editor.Commands.Descriptor_Is_Complete (Id)
           and then Editor.Commands.Is_Bindable_Command (Id)
           and then Editor.Commands.Visible_In_Command_Palette (Id);
      end User_Facing_Edit_Command;

      function User_Facing_Text_Mutation
        (Id : Editor.Commands.Command_Id) return Boolean is
      begin
         return User_Facing_Edit_Command (Id)
           and then Is_Core_Editing_Command (Id)
           and then Is_Text_Editing_Command (Id)
           and then Mutates_Or_Replaces_Buffer_Text (Id);
      end User_Facing_Text_Mutation;

      function User_Facing_Caret_Command
        (Id : Editor.Commands.Command_Id) return Boolean is
      begin
         return User_Facing_Edit_Command (Id)
           and then Is_Core_Editing_Command (Id)
           and then Is_Caret_Navigation_Command (Id)
           and then not Is_Text_Editing_Command (Id)
           and then not Mutates_Or_Replaces_Buffer_Text (Id);
      end User_Facing_Caret_Command;

      function User_Facing_Selection_Command
        (Id : Editor.Commands.Command_Id) return Boolean is
      begin
         return User_Facing_Edit_Command (Id)
           and then Is_Core_Editing_Command (Id)
           and then Is_Selection_Command (Id)
           and then not Mutates_Or_Replaces_Buffer_Text (Id);
      end User_Facing_Selection_Command;
   begin
      return
        --  Undo/redo and grouped text-edit commands.
        User_Facing_Text_Mutation (Editor.Commands.Command_Undo)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Redo)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Selection_Delete)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Line_Duplicate)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Line_Move_Up)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Line_Move_Down)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Line_Join_Next)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Line_Split_At_Caret)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Trim_Trailing_Whitespace)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Word_Delete_Previous)
        and then User_Facing_Text_Mutation (Editor.Commands.Command_Word_Delete_Next)

        --  Word movement and selection-only commands remain non-mutating.
        and then User_Facing_Caret_Command (Editor.Commands.Command_Move_Word_Left)
        and then User_Facing_Caret_Command (Editor.Commands.Command_Move_Word_Right)
        and then User_Facing_Selection_Command (Editor.Commands.Command_Select_Word_Left)
        and then User_Facing_Selection_Command (Editor.Commands.Command_Select_Word_Right)
        and then User_Facing_Selection_Command (Editor.Commands.Command_Select_Word)
        and then User_Facing_Selection_Command (Editor.Commands.Command_Select_Line);
   end Assert_Text_Editing_Primitives_Coherent;

end Editor.Core_Editing_Workflow;
