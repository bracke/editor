with Ada.Strings.Unbounded;

with Editor.State;
with Editor.Commands;

package Editor.Executor.Clipboard is

   type Clipboard_Execution_Status is
     (Clipboard_Copied,
      Clipboard_Cut,
      Clipboard_Pasted,
      Clipboard_Cleared,
      Clipboard_No_Active_Buffer,
      Clipboard_No_Selected_Text,
      Clipboard_Invalid_Selection,
      Clipboard_Selection_Not_Supported,
      Clipboard_Text_Not_Supported,
      Clipboard_No_Text,
      Clipboard_Copy_Failed,
      Clipboard_Cut_Failed,
      Clipboard_Paste_Failed,
      Clipboard_Nothing_To_Clear);

   function Copy_Cut_Availability
     (S : Editor.State.State_Type)
      return Editor.Commands.Command_Availability;

   function Last_Status return Clipboard_Execution_Status;

   function Text_For_Local_Input return Ada.Strings.Unbounded.Unbounded_String;

   procedure Clear_Status;


   procedure Execute
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Clipboard;
