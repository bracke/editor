with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.External_Producers;

package Editor.Terminal_Tasks is

   package Text_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String,
      "="          => Ada.Strings.Unbounded."=");

   subtype Text_Vector is Text_Vectors.Vector;

   type Terminal_Task_Profile is
     (Task_Profile_Default,
      Task_Profile_Build,
      Task_Profile_Run,
      Task_Profile_Development,
      Task_Profile_Release,
      Task_Profile_Validation,
      Task_Profile_Test,
      Task_Profile_Custom);

   type Terminal_Task_Status is
     (Task_Not_Run,
      Task_Running,
      Task_Succeeded,
      Task_Failed,
      Task_Not_Available,
      Task_Rejected,
      Task_Timed_Out,
      Task_Cancelled);

   type Terminal_Task_Row is record
      Id : Natural := 0;
      Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Program_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Working_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Profile_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Arguments : Text_Vector := Text_Vectors.Empty_Vector;
      Profile : Terminal_Task_Profile := Task_Profile_Default;
      Status : Terminal_Task_Status := Task_Not_Run;
      Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("not run");
      Last_Output : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Exit_Code : Boolean := False;
      Exit_Code : Integer := 0;
      Selected : Boolean := False;
      Rerunnable : Boolean := False;
   end record;

   package Terminal_Task_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Terminal_Task_Row);

   subtype Terminal_Task_Row_Vector is Terminal_Task_Row_Vectors.Vector;

   type Terminal_Task_Render_Snapshot is record
      Visible : Boolean := False;
      Focused : Boolean := False;
      Row_Count : Natural := 0;
      Selected_Index : Natural := 0;
      Has_Selected : Boolean := False;
      Can_Run_Selected : Boolean := False;
      Can_Rerun_Last : Boolean := False;
      Can_Clear : Boolean := False;
      Can_Cancel : Boolean := False;
      Rows : Terminal_Task_Row_Vector :=
        Terminal_Task_Row_Vectors.Empty_Vector;
      Output_Row_Count : Natural := 0;
      Output_Rows : Text_Vector := Text_Vectors.Empty_Vector;
      Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("No terminal tasks");
      Active_Command_Line : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Working_Directory : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Empty_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("No tasks configured");
   end record;

   type Terminal_Task_State is private;

   function Empty_State return Terminal_Task_State;

   procedure Show (State : in out Terminal_Task_State);
   procedure Focus (State : in out Terminal_Task_State);
   procedure Unfocus (State : in out Terminal_Task_State);
   procedure Hide (State : in out Terminal_Task_State);
   procedure Toggle (State : in out Terminal_Task_State);
   procedure Clear (State : in out Terminal_Task_State);
   procedure Clear_Output (State : in out Terminal_Task_State);

   procedure Ensure_Project_Default_Tasks
     (State      : in out Terminal_Task_State;
      Project_Root : String);

   procedure Select_Next (State : in out Terminal_Task_State);
   procedure Select_Previous (State : in out Terminal_Task_State);

   function Select_First_Profile
     (State   : in out Terminal_Task_State;
      Profile : Terminal_Task_Profile) return Boolean;

   function Register_Task
     (State         : in out Terminal_Task_State;
      Label         : String;
      Program_Label : String;
      Working_Label : String := "";
      Profile       : Terminal_Task_Profile := Task_Profile_Custom)
      return Natural;

   procedure Append_Argument
     (State : in out Terminal_Task_State;
      Id    : Natural;
      Value : String);

   procedure Run_Selected_With_Result
     (State  : in out Terminal_Task_State;
      Result : Editor.External_Producers.Process_Run_Result);

   procedure Rerun_Last_With_Result
     (State  : in out Terminal_Task_State;
      Result : Editor.External_Producers.Process_Run_Result);

   function Has_Selected_Task (State : Terminal_Task_State) return Boolean;
   function Can_Rerun_Last (State : Terminal_Task_State) return Boolean;

   function Selected_Task_Request
     (State : Terminal_Task_State)
      return Editor.External_Producers.Process_Run_Request;

   function Last_Task_Request
     (State : Terminal_Task_State)
      return Editor.External_Producers.Process_Run_Request;

   function Build_Render_Snapshot
     (State : Terminal_Task_State) return Terminal_Task_Render_Snapshot;

private
   type Terminal_Task_State is record
      Visible : Boolean := False;
      Focused : Boolean := False;
      Next_Id : Natural := 1;
      Rows : Terminal_Task_Row_Vector :=
        Terminal_Task_Row_Vectors.Empty_Vector;
      Selected_Index : Natural := 0;
      Has_Last_Run : Boolean := False;
      Last_Run_Id : Natural := 0;
      Output_Rows : Text_Vector := Text_Vectors.Empty_Vector;
      Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("No terminal tasks");
      Active_Command_Line : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Working_Directory : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

end Editor.Terminal_Tasks;
