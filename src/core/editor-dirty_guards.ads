with Ada.Strings.Unbounded;

package Editor.Dirty_Guards is

   type Dirty_Transition_Kind is
     (Close_Buffer_Transition,
      Close_All_Buffers_Transition,
      Close_Project_Transition,
      Open_Project_Transition,
      Switch_Project_Transition,
      Open_Recent_Project_Transition,
      Restore_Workspace_Transition,
      Clear_Project_Transition);

   type Dirty_Transition_Status is
     (Dirty_Transition_Allowed,
      Dirty_Transition_Blocked);

   type Dirty_Buffer_Summary is record
      Dirty_Count       : Natural := 0;
      Untitled_Count    : Natural := 0;
      File_Backed_Count : Natural := 0;
   end record;

   type Dirty_Transition_Result is record
      Status  : Dirty_Transition_Status := Dirty_Transition_Allowed;
      Summary : Dirty_Buffer_Summary;
      Reason  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   function Allowed
     (Summary : Dirty_Buffer_Summary) return Dirty_Transition_Result;

   function Blocked
     (Summary : Dirty_Buffer_Summary;
      Reason  : String) return Dirty_Transition_Result;

   function Is_Allowed
     (Result : Dirty_Transition_Result) return Boolean;

   function Reason
     (Result : Dirty_Transition_Result) return String;

   function Dirty_Buffer_Count_Text
     (Summary : Dirty_Buffer_Summary) return String;

   function No_Unsaved_Changes_Message return String;
   function No_Dirty_File_Backed_Buffers_Message return String;
   function No_Clean_Buffers_Message return String;
   function No_Pending_Transition_Message return String;
   function Save_Or_Resolve_Changes_First_Message return String;
   function Pending_Transition_Canceled_Message return String;
   function Pending_Transition_No_Longer_Valid_Message return String;
   function Workspace_State_Saved_Message return String;
   function Workspace_State_Restored_Message return String;

   function Guard_Transition
     (Kind    : Dirty_Transition_Kind;
      Summary : Dirty_Buffer_Summary) return Dirty_Transition_Result;

end Editor.Dirty_Guards;
