with Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Commands;
with Editor.State;

package Editor.Executor.File_Open_Commands is

   function File_Open_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Open_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_New_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Switch_Buffer
     (S                : in out Editor.State.State_Type;
      Id               : Editor.Buffers.Buffer_Id;
      Recent_Traversal : Boolean := False;
      Emit_Feedback    : Boolean := True);

   procedure Clear_Reopen_Candidate
     (S : in out Editor.State.State_Type);

   procedure Register_Reopen_Candidate_After_Close
     (S     : in out Editor.State.State_Type;
      Path  : String;
      Label : String);

   procedure Candidate_For_Closed_Associated_Buffer
     (Id       : Editor.Buffers.Buffer_Id;
      Has_Path : out Boolean;
      Path     : out Ada.Strings.Unbounded.Unbounded_String;
      Label    : out Ada.Strings.Unbounded.Unbounded_String);

   procedure Execute_Reopen_Closed_Buffer
     (S : in out Editor.State.State_Type);

end Editor.Executor.File_Open_Commands;
