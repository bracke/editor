with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.Buffer_Metadata_Commands is

   function Buffer_Metadata_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

   procedure Execute_Pin_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Unpin_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Buffer_Pin
     (S : in out Editor.State.State_Type);

   function Valid_Buffer_Label_Text (Text : String) return Boolean;

   procedure Execute_Set_Buffer_Label
     (S : in out Editor.State.State_Type; Label : String);

   procedure Execute_Clear_Buffer_Label
     (S : in out Editor.State.State_Type);

   procedure Execute_Show_Buffer_Label
     (S : in out Editor.State.State_Type);

   procedure Execute_Set_Buffer_Note
     (S : in out Editor.State.State_Type; Note : String);

   procedure Execute_Clear_Buffer_Note
     (S : in out Editor.State.State_Type);

   procedure Execute_Show_Buffer_Note
     (S : in out Editor.State.State_Type);

   procedure Execute_Assign_Buffer_Group
     (S : in out Editor.State.State_Type; Name : String);

   procedure Execute_Clear_Buffer_Group
     (S : in out Editor.State.State_Type);

   procedure Execute_Switch_Buffer_Group
     (S : in out Editor.State.State_Type; Name : String);

   procedure Execute_Show_All_Buffer_Groups
     (S : in out Editor.State.State_Type);

   function Execute_Buffer_Metadata_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Buffer_Metadata_Commands;
